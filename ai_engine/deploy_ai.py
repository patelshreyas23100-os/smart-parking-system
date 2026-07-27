from stable_baselines3 import PPO
import numpy as np

class ParkingAI:
    def __init__(self, model_path="ai_engine/models/ppo_smart_parking"):
        try:
            self.model = PPO.load(model_path)
            print("RL Optimizer Loaded Successfully.")
        except:
            self.model = None
            print("RL Model not found. Falling back to static pricing.")

    def get_optimal_prices(self, zone_occupancy, current_time, traffic_level):
        """
        Inputs:
        - zone_occupancy: List of floats [0, 1] for zones. 
                         If less than 5, padding is used. If more, truncated.
        - current_time: Normalized float [0, 1] (current_hour / 24)
        - traffic_level: Normalized float [0, 1]
        
        Returns:
        - List of price multipliers for EACH zone passed in zone_occupancy.
        """
        if self.model is None:
            return [1.0] * len(zone_occupancy)
            
        # Ensure we have exactly 5 zones for the model (as trained in SmartParkingEnv)
        occ_5 = np.zeros(5)
        n = min(len(zone_occupancy), 5)
        occ_5[:n] = zone_occupancy[:n]
        
        # Construct state vector (8 elements): [Occ1..Occ5, Time, Traffic, MeanPrice]
        avg_price = 1.0 # Base multiplier
        state = np.concatenate([occ_5, [current_time], [traffic_level], [avg_price]]).astype(np.float32)
        
        # Predict optimal price adjustments
        # Action space is Box(5,)
        action, _ = self.model.predict(state, deterministic=True)
        
        # Map action [-1, 1] to multiplier change. 
        # In our env, multiplier = clip(prev + action*0.1, 0.5, 3.0)
        # For a single-shot view, we treat 1.0 as the 'prev'
        raw_multipliers = np.clip(1.0 + (action * 0.5), 0.5, 3.0)
        
        # Extract multipliers for the original requested zones
        # If user passed 1 zone, give them the first one.
        # If user passed 10, repeat the patterns or use default for others.
        final_multipliers = []
        for i in range(len(zone_occupancy)):
            idx = i % 5 # Wrap around if more than 5 zones
            final_multipliers.append(float(raw_multipliers[idx]))
            
        return final_multipliers

# Example integration in FastAPI
"""
@app.get("/admin/optimize-prices")
def optimize():
    # 1. Gather real-time stats from DB
    occupancy = [loc.available_slots / loc.total_slots for loc in db.query(ParkingLocation).all()]
    current_time = datetime.now().hour / 24.0
    traffic = 0.5 # Would come from external Traffic API
    
    # 2. Get AI recommendation
    ai = ParkingAI()
    prices = ai.get_optimal_prices(occupancy, current_time, traffic)
    
    # 3. Update DB
    # ...
    return {"recommended_prices": prices}
"""
