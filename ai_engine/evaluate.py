import matplotlib.pyplot as plt
import numpy as np
from stable_baselines3 import PPO
from parking_env import SmartParkingEnv

def evaluate():
    env = SmartParkingEnv()
    model_path = "models/ppo_smart_parking.zip"
    
    if not os.path.exists(model_path):
        print("Model not found! Training a quick demo model...")
        model = PPO("MlpPolicy", env, verbose=0)
        model.learn(total_timesteps=1000)
    else:
        model = PPO.load(model_path)

    obs, _ = env.reset()
    history = {"revenue": [], "utilization": [], "prices": []}
    
    # Run simulation for one "day" (20 steps)
    for _ in range(20):
        action, _states = model.predict(obs, deterministic=True)
        obs, reward, terminated, truncated, info = env.step(action)
        
        history["revenue"].append(info["revenue"])
        history["utilization"].append(info["utilization"])
        history["prices"].append(obs[-1]) # Mean price mult
        
    # Plotting
    plt.figure(figsize=(12, 6))
    
    plt.subplot(1, 2, 1)
    ax1 = plt.gca()
    ax1.plot(history["revenue"], color='tab:blue', label="Revenue")
    ax1.set_ylabel("Revenue", color='tab:blue')
    
    ax2 = ax1.twinx()
    ax2.plot(history["utilization"], color='tab:red', label="Utilization")
    ax2.set_ylabel("Utilization", color='tab:red')
    
    plt.title("Revenue & Utilization over Time")
    # Combine legends
    lines, labels = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax2.legend(lines + lines2, labels + labels2, loc='upper left')
    
    plt.subplot(1, 2, 2)
    plt.plot(history["prices"], label="Price Multiplier", color='orange')
    plt.title("Dynamic Pricing Strategy")
    plt.legend()
    
    plt.tight_layout()
    plt.savefig("parking_evaluation.png")
    print("Evaluation plot saved to parking_evaluation.png")

if __name__ == "__main__":
    import os
    evaluate()
