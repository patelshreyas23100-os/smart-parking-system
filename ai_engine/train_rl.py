import os
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
from parking_env import SmartParkingEnv

def train():
    # 1. Create directory for models
    os.makedirs("models", exist_ok=True)
    
    # 2. Initialize Environment
    # We use a vectorized environment for faster training
    env = SmartParkingEnv(num_zones=5)
    
    # 3. Initialize PPO Agent
    # policy='MlpPolicy' since our state is a simple vector
    model = PPO(
        "MlpPolicy", 
        env, 
        verbose=1,
        learning_rate=0.0003,
        n_steps=2048,
        batch_size=64,
        n_epochs=10,
        gamma=0.99,
        gae_lambda=0.95,
        clip_range=0.2,
        tensorboard_log="./ppo_parking_tensorboard/"
    )
    
    # 4. Train the agent
    print("Starting training...")
    model.learn(total_timesteps=50000)
    
    # 5. Save the trained model
    model_path = "models/ppo_smart_parking"
    model.save(model_path)
    print(f"Model saved to {model_path}")

if __name__ == "__main__":
    train()
