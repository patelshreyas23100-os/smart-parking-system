import gymnasium as gym
from gymnasium import spaces
import numpy as np
import random

class SmartParkingEnv(gym.Env):
    """
    Custom Environment for Smart Parking Optimization
    Optimizes pricing and slot allocation dynamically.
    """
    def __init__(self, num_zones=5, slots_per_zone=20):
        super(SmartParkingEnv, self).__init__()
        
        self.num_zones = num_zones
        self.slots_per_zone = slots_per_zone
        self.total_slots = num_zones * slots_per_zone
        
        # State: [Occupancy_rate_per_zone, Normalized_Time, Traffic_Level, Current_Price_Mult]
        # Shape: num_zones (occupancy) + 1 (time) + 1 (traffic) + 1 (pricing)
        self.observation_space = spaces.Box(
            low=0, high=1, shape=(num_zones + 3,), dtype=np.float32
        )
        
        # Action: Adjust pricing multiplier for each zone (-0.5 to +0.5 change)
        self.action_space = spaces.Box(
            low=-1, high=1, shape=(num_zones,), dtype=np.float32
        )
        
        self.state = None
        self.base_price = 20.0
        self.pricing_multipliers = np.ones(num_zones)
        self.occupancy = np.zeros(num_zones)
        self.current_time = 0.0 # 0.0 to 1.0 (normalized day)
        
    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        
        # Initialize state
        self.occupancy = np.random.uniform(0.1, 0.4, self.num_zones)
        self.current_time = 0.0
        self.pricing_multipliers = np.ones(self.num_zones)
        
        traffic_level = np.random.uniform(0.1, 0.3)
        
        self.state = np.concatenate([
            self.occupancy, 
            [self.current_time], 
            [traffic_level], 
            [np.mean(self.pricing_multipliers)]
        ]).astype(np.float32)
        
        return self.state, {}

    def step(self, action):
        # 1. Update Pricing Multipliers based on agent action
        # Action is in [-1, 1], we map it to 0.5x to 2.5x
        self.pricing_multipliers = np.clip(self.pricing_multipliers + (action * 0.1), 0.5, 3.0)
        
        # 2. Simulate Demand based on Time of Day and Price
        # Peak hours are 0.4 (10 AM) to 0.8 (7 PM)
        is_peak = 0.4 < self.current_time < 0.8
        base_demand_rate = 0.5 if is_peak else 0.2
        
        # Traffic adds to demand
        traffic_level = self.state[-2]
        total_demand = base_demand_rate + (traffic_level * 0.5)
        
        revenue = 0
        total_utilization = 0
        congestion_penalty = 0
        
        # 3. Apply demand to each zone
        for i in range(self.num_zones):
            # Price elastic demand: Higher price -> Lower demand
            actual_demand = total_demand / (self.pricing_multipliers[i] ** 1.5)
            
            # Arrival process
            arrivals = np.random.poisson(actual_demand * 10) # Scaling for simulation
            
            # Update occupancy
            prev_occ = self.occupancy[i]
            occupied_slots = int(self.occupancy[i] * self.slots_per_zone)
            new_occupancy_count = min(self.slots_per_zone, occupied_slots + arrivals)
            self.occupancy[i] = new_occupancy_count / self.slots_per_zone
            
            # Revenue calculation
            arrivals_accepted = new_occupancy_count - occupied_slots
            revenue += arrivals_accepted * self.base_price * self.pricing_multipliers[i]
            
            # Congestion Penalty (high occupancy leads to search time)
            if self.occupancy[i] > 0.9:
                congestion_penalty += (self.occupancy[i] - 0.9) * 10
            
            # Departures (simple linear model)
            departures = np.random.randint(0, max(1, int(new_occupancy_count * 0.2) + 1))
            self.occupancy[i] = max(0, (new_occupancy_count - departures) / self.slots_per_zone)

        # 4. Advance time
        self.current_time += 0.05
        if self.current_time > 1.0:
            self.current_time = 0.0
            
        # 5. Calculate Reward
        # Reward = Revenue + Utilization_Bonus - Congestion - Price_Volatility_Penalty
        avg_utilization = np.mean(self.occupancy)
        reward = (revenue * 0.1) + (avg_utilization * 5) - congestion_penalty
        
        # 6. Update State
        new_traffic = np.clip(traffic_level + np.random.uniform(-0.1, 0.1), 0, 1)
        self.state = np.concatenate([
            self.occupancy, 
            [self.current_time], 
            [new_traffic], 
            [np.mean(self.pricing_multipliers)]
        ]).astype(np.float32)
        
        terminated = self.current_time == 0.0 # End of day
        truncated = False
        
        return self.state, reward, terminated, truncated, {"revenue": revenue, "utilization": avg_utilization}

if __name__ == "__main__":
    env = SmartParkingEnv()
    obs, _ = env.reset()
    print(f"Initial State: {obs}")
    for _ in range(5):
        random_action = env.action_space.sample()
        obs, reward, term, trunc, info = env.step(random_action)
        print(f"Action: {random_action} -> Reward: {reward:.2f}, Util: {info['utilization']:.2f}")
