# Smart Parking RL Engine - Execution Guide

This folder contains a Reinforcement Learning (RL) based optimization system for a smart parking project.

## 🚀 Setup Instructions

### 1. Prerequisites
Ensure you have Python 3.8+ installed on your system.

### 2. Install Dependencies
Open your terminal (PowerShell or CMD) and navigate to the project root, then install the required AI libraries:
```powershell
cd C:\flutter_smart_park\flutter_smart_park\ai_engine
pip install -r requirements.txt
```

---

## 🛠️ Step-by-Step Execution

### Step 1: Understand the Environment
**File**: `parking_env.py`
This script defines the "Parking Simulation". It simulates users arriving, parking, and leaving. It also calculates revenue and congestion.
*   **Run a test scan (Optional)**:
    ```powershell
    python parking_env.py
    ```
    (This will print raw state data to show the simulation is working).

### Step 2: Train the AI Agent
**File**: `train_rl.py`
This is where the "learning" happens. The agent (PPO) will play through thousands of simulation steps to learn which pricing strategy maximizes profit without causing traffic jams.
*   **Command**:
    ```powershell
    python train_rl.py
    ```
*   **What happens?**: You will see training logs (loss, reward). When finished, it creates a `models/ppo_smart_parking.zip` file.

### Step 3: Evaluate Performance
**File**: `evaluate.py`
Once trained, use this script to see how the AI performs in a real scenario.
*   **Command**:
    ```powershell
    python evaluate.py
    ```
*   **Result**: It generates a file named **`parking_evaluation.png`**. Open this image to see how the AI adjusted prices during "peak hours" and how revenue increased.

---

## 🌐 Real-World Integration
**File**: `deploy_ai.py`
This is the "Bridge". In a production system, you would import this file into your `backend/main.py`.
1.  **Input**: Sensors send occupancy data to the backend.
2.  **AI Inference**: `deploy_ai.py` takes that data and "asks" the trained model for the best prices.
3.  **Output**: The new prices are sent to the App and Admin Panel.

## 📊 Evaluation Metrics to Watch
- **Revenue Improvement**: Should be 10-25% higher than static pricing.
- **Utilization**: Target 80-90% during peak (prevents empty slots or total gridlock).
- **Convergence**: Lower "Loss" in training logs indicates a stable AI brain.
