// Dynamically switch between Laptop (localhost) and Mobile (LAN IP) backends
const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const API_BASE_URL = isLocalhost ? 'http://127.0.0.1:8001' : 'http://' + window.location.hostname + ':8001';

const api = {
    async request(endpoint) {
        const token = localStorage.getItem('accessToken');
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        if (!response.ok) throw new Error('API Error');
        return response.json();
    },
    getStats: () => api.request('/admin/stats'),
    getUsers: () => api.request('/admin/users'),
    getBookings: () => api.request('/admin/bookings'),
    getSlots: () => api.request('/admin/slots'),
    getSubscriptions: () => api.request('/admin/subscriptions'),
    deleteUser: (id) => fetch(`${API_BASE_URL}/admin/users/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${localStorage.getItem('accessToken')}` }
    }).then(r => r.json()),
    updateAdminSlot: (id, data) => fetch(`${API_BASE_URL}/admin/slots/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
        },
        body: JSON.stringify(data)
    }).then(r => {
        if (!r.ok) throw new Error('API Error');
        return r.json();
    })
};

const views = {
    dashboard: async () => {
        const stats = await api.getStats();
        window.dashboardStats = stats; // Cache for chart

        let bookingsHTML = '<div style="padding: 2rem; text-align: center; color: var(--text-muted);">No recent activity</div>';
        try {
            const bookings = await api.getBookings();
            const recentBookings = bookings.slice(0, 5); // Get top 5 recent

            if (recentBookings.length > 0) {
                bookingsHTML = `
                    <table class="dashboard-table">
                        <thead>
                            <tr>
                                <th>Slot</th>
                                <th>Location</th>
                                <th>User</th>
                                <th>Entry Time</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${recentBookings.map(b => {
                    const slotNo = b.slot ? b.slot.slot_number : 'N/A';
                    const userName = b.user ? b.user.name : 'Unknown';
                    const status = b.status || 'Unknown';
                    return `
                                    <tr>
                                        <td class="text-primary">${slotNo}</td>
                                        <td>${b.location || 'General'}</td>
                                        <td>${userName}</td>
                                        <td>${new Date(b.start_time + (b.start_time.endsWith('Z') ? '' : 'Z')).toLocaleString()}</td>
                                        <td>
                                            <span class="badge badge-${status.toLowerCase()}">
                                                ${status}
                                            </span>
                                        </td>
                                    </tr>
                                `;
                }).join('')}
                        </tbody>
                    </table>
                    <style>
                        .dashboard-table {width: 100%; border-collapse: collapse; }
                        .dashboard-table th, .dashboard-table td {padding: 1rem; text-align: left; border-bottom: 1px solid var(--border); }
                        .dashboard-table th {background: #f8fafc; font-weight: 600; color: var(--text-muted); font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.5px; }
                    </style>
                `;
            }
        } catch (e) {
            console.error("Failed to load recent bookings for dashboard", e);
        }

        return `
            <div class="view-header">
                <h2>System Overview</h2>
            </div>
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Total Revenue</div>
                    <div class="stat-value text-primary">₹ ${stats.total_revenue.toFixed(2)}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Registered Users</div>
                    <div class="stat-value">${stats.total_users}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Active Bookings</div>
                    <div class="stat-value">${stats.active_bookings}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Available Slots</div>
                    <div class="stat-value" style="color:var(--success)">${stats.available_slots} / ${stats.total_slots}</div>
                </div>
            </div>
            
            <div class="dashboard-content" style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-top: 2rem;">
                <div class="card" style="margin-top: 0;">
                    <div class="table-header">
                        <h3>Revenue & Bookings Overview</h3>
                    </div>
                    <div style="padding: 1rem;">
                        <canvas id="dashboardChart"></canvas>
                    </div>
                </div>

                <div class="card" style="margin-top: 0;">
                    <div class="table-header">
                        <h3>Recent System Activity</h3>
                        <div class="status-indicator live">Real-time monitoring</div>
                    </div>
                    ${bookingsHTML}
                </div>
            </div>
        `;
    },

    users: async () => {
        const users = await api.getUsers();
        window.allUsersData = users; // Cache for modal
        return `
            <div class="view-header">
                <h2>User Management</h2>
            </div>
            <div class="card">
                <div class="table-header">
                    <h3>All Registered Users</h3>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Phone</th>
                            <th>Vehicles</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${users.map(u => `
                            <tr>
                                <td><strong>${u.name}</strong></td>
                                <td>${u.email}</td>
                                <td>${u.phone}</td>
                                <td>
                                    ${u.vehicles.map(v => `<span class="badge" style="background:#f1f5f9; margin-right:4px;">${v.plate_number}</span>`).join('')}
                                </td>
                                <td>
                                    <button class="nav-link manage-user-btn" data-user-id="${u.id}" style="padding:4px 8px; font-size:12px; border:1px solid var(--primary); background:white; cursor:pointer;">Manage</button>
                                    <button class="nav-link delete-user-btn" data-user-id="${u.id}" style="padding:4px 8px; font-size:12px; border:1px solid var(--error); background:white; color:var(--error); margin-left:4px; cursor:pointer;">Delete</button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    },

    bookings: async () => {
        const bookings = await api.getBookings();
        return `
            <div class="view-header">
                <h2>Booking Logs</h2>
            </div>
            <div class="card">
                <div class="table-header">
                    <h3>Live Transaction History</h3>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Slot</th>
                            <th>Location</th>
                            <th>User</th>
                            <th>Vehicle</th>
                            <th>Plate No.</th>
                            <th>Entry Time</th>
                            <th>Exit Time</th>
                            <th>Amount</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${bookings.map(b => {
            const slotNo = b.slot ? b.slot.slot_number : 'N/A';
            const userName = b.user ? b.user.name : 'Unknown';
            const vehicleName = b.vehicle ? b.vehicle.name : 'Unknown';
            const plateNo = b.vehicle ? b.vehicle.plate_number : 'N/A';
            const price = b.total_price || 0;
            const status = b.status || 'Unknown';

            return `
                                <tr>
                                    <td class="text-primary">${slotNo}</td>
                                    <td>${b.location || 'General'}</td>
                                    <td>${userName}</td>
                                    <td>${vehicleName}</td>
                                    <td class="text-mono">${plateNo}</td>
                                    <td>${new Date(b.start_time + (b.start_time.endsWith('Z') ? '' : 'Z')).toLocaleString()}</td>
                                    <td>${new Date(b.end_time + (b.end_time.endsWith('Z') ? '' : 'Z')).toLocaleString()}</td>
                                    <td class="text-primary">₹ ${price.toFixed(2)}</td>
                                    <td>
                                        <span class="badge badge-${status.toLowerCase()}">
                                            ${status}
                                        </span>
                                    </td>
                                </tr>
                            `;
        }).join('')}
                    </tbody>
                </table>
            </div>
        `;
    },

    slots: async () => {
        const slots = await api.getSlots();
        return `
            <div class="view-header">
                <h2>Slot Monitoring & Management</h2>
            </div>
            <div class="stats-grid">
                ${slots.map(s => `
                    <div class="stat-card" style="border-left: 4px solid ${s.is_available ? 'var(--success)' : 'var(--error)'}">
                        <div class="stat-label">Slot ${s.slot_number}</div>
                        <div class="stat-value" style="font-size: 1.25rem;">${s.type || 'Vehicle'}</div>
                        <div style="font-size: 0.75rem; color: ${s.is_available ? 'var(--success)' : 'var(--error)'}; font-weight: 800; margin-bottom: 0.5rem;">
                            ${s.is_available ? 'AVAILABLE' : 'OCCUPIED'}
                        </div>
                        <button class="nav-link toggle-slot-btn" data-slot-id="${s.id}" data-slot-number="${s.slot_number}" data-current-status="${s.is_available}" style="padding:4px 8px; font-size:11px; border:1px solid var(--border); background:white; cursor:pointer; width:100%; border-radius:4px; text-align:center;">Manage Status</button>
                    </div>
                `).join('')}
            </div>
        `;
    },

    subscriptions: async () => {
        const subs = await api.getSubscriptions();
        return `
            <div class="view-header">
                <h2>User Subscriptions</h2>
            </div>
            <div class="card">
                <div class="table-header">
                    <h3>Active & Historical Subscribers</h3>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>User Name</th>
                            <th>Vehicle Type</th>
                            <th>Plan</th>
                            <th>Valid Till</th>
                            <th>Price</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${subs.map(s => {
                            const userName = s.user ? s.user.name : 'Unknown';
                            const planName = s.plan ? s.plan.name : 'Unknown';
                            const vehicleType = s.plan ? s.plan.vehicle_type : 'N/A';
                            const price = s.plan ? s.plan.price : 0;
                            const status = s.status || 'Unknown';
                            const endDate = new Date(s.end_date + (s.end_date.endsWith('Z') ? '' : 'Z')).toLocaleDateString();

                            return `
                                <tr>
                                    <td><strong>${userName}</strong></td>
                                    <td>${vehicleType}</td>
                                    <td class="text-primary">${planName}</td>
                                    <td>${endDate}</td>
                                    <td>₹ ${price.toFixed(2)}</td>
                                    <td>
                                        <span class="badge badge-${status.toLowerCase() === 'active' ? 'active' : 'expired'}">
                                            ${status}
                                        </span>
                                    </td>
                                </tr>
                            `;
                        }).join('')}
                        ${subs.length === 0 ? '<tr><td colspan="6" style="text-align:center; padding: 2rem; color:var(--text-muted)">No subscriptions found.</td></tr>' : ''}
                    </tbody>
                </table>
            </div>
        `;
    },

    adminProfile: async () => {
        const adminUser = localStorage.getItem('adminUsername') || 'admin@parksmart.com';
        const adminEmail = localStorage.getItem('adminEmail') || 'admin@parksmart.com';
        return `
            <div class="view-header">
                <h2>Admin Profile Settings</h2>
            </div>
            <div class="card" style="max-width: 600px; margin: 0 auto; padding: 2rem;">
                <div style="margin-bottom: 1.5rem;">
                    <label style="display:block; margin-bottom:0.5rem; color:var(--text-muted); font-weight:600;">Admin Username</label>
                    <input type="text" id="profile-admin-username" value="${adminUser}" style="width:100%; padding:0.75rem; border:1px solid var(--border); border-radius:0.5rem; font-size:1rem;">
                </div>
                <div style="margin-bottom: 1.5rem;">
                    <label style="display:block; margin-bottom:0.5rem; color:var(--text-muted); font-weight:600;">Admin Email</label>
                    <input type="email" id="profile-admin-email" value="${adminEmail}" style="width:100%; padding:0.75rem; border:1px solid var(--border); border-radius:0.5rem; font-size:1rem;">
                </div>
                
                <h3 style="margin: 2rem 0 1rem; padding-bottom: 0.5rem; border-bottom: 1px solid var(--border);">Security Settings</h3>
                
                <div id="password-change-section">
                    <div style="margin-bottom: 1.5rem;">
                        <label style="display:block; margin-bottom:0.5rem; color:var(--text-muted); font-weight:600;">New Password</label>
                        <input type="password" id="profile-admin-new-password" placeholder="Enter new password" style="width:100%; padding:0.75rem; border:1px solid var(--border); border-radius:0.5rem; font-size:1rem;">
                    </div>
                    
                    <div id="otp-section" style="display: none; background: #f8fafc; padding: 1rem; border-radius: 0.5rem; margin-bottom: 1.5rem; border: 1px dashed var(--border);">
                        <p id="otp-sent-message" style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 0.5rem;">A verification code has been sent to your email.</p>
                        <div style="display: flex; gap: 0.5rem;">
                            <input type="text" id="profile-admin-otp" placeholder="Enter OTP (e.g. 1234)" style="flex: 1; padding:0.75rem; border:1px solid var(--border); border-radius:0.5rem;">
                            <button id="verify-otp-btn" class="btn-primary" style="background-color: var(--primary);">Verify & Update</button>
                        </div>
                    </div>

                    <button id="request-otp-btn" class="btn-primary" style="width: 100%; background-color: var(--secondary);">Request OTP to Change Password</button>
                </div>

                <div style="margin-top: 2rem;">
                    <button id="save-profile-btn" class="btn-primary" style="width: 100%;">Save Profile Details</button>
                </div>
            </div>
        `;
    }
};

let currentView = 'dashboard';
const contentArea = document.getElementById('content-area');
const loginOverlay = document.getElementById('admin-login-overlay');
const mainLayout = document.getElementById('main-layout');

async function renderView(viewName, isSilent = false) {
    currentView = viewName;
    if (!isSilent) {
        contentArea.innerHTML = '<div class="loader">Syncing...</div>';
    }

    // Update active nav link
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.toggle('active', link.dataset.view === viewName);
    });

    try {
        const html = await views[viewName]();
        if (currentView === viewName) {
            contentArea.innerHTML = html;
            document.getElementById('sync-time').textContent = new Date().toLocaleTimeString();

            // Chart Initialization for Dashboard
            if (viewName === 'dashboard' && window.dashboardStats) {
                const ctx = document.getElementById('dashboardChart');
                if (ctx) {
                    if (window.myDashboardChart) {
                        window.myDashboardChart.destroy();
                    }
                    window.myDashboardChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: ['Total Users', 'Total Bookings', 'Active Bookings', 'Total Slots', 'Available Slots'],
                            datasets: [{
                                label: 'System Metrics',
                                data: [
                                    window.dashboardStats.total_users,
                                    window.dashboardStats.total_bookings,
                                    window.dashboardStats.active_bookings,
                                    window.dashboardStats.total_slots,
                                    window.dashboardStats.available_slots
                                ],
                                backgroundColor: [
                                    'rgba(54, 162, 235, 0.6)',
                                    'rgba(75, 192, 192, 0.6)',
                                    'rgba(255, 206, 86, 0.6)',
                                    'rgba(153, 102, 255, 0.6)',
                                    'rgba(74, 222, 128, 0.6)'
                                ],
                                borderWidth: 0
                            }]
                        },
                        options: {
                            responsive: true,
                            scales: {
                                y: { beginAtZero: true }
                            }
                        }
                    });
                }
            }

            // Add Manage & Delete Button Handlers
            if (viewName === 'users') {
                document.querySelectorAll('.manage-user-btn').forEach(btn => {
                    btn.onclick = () => showUserDetails(btn.dataset.userId);
                });
                document.querySelectorAll('.delete-user-btn').forEach(btn => {
                    btn.onclick = () => confirmDeleteUser(btn.dataset.userId);
                });
            }
            if (viewName === 'slots') {
                document.querySelectorAll('.toggle-slot-btn').forEach(btn => {
                    btn.onclick = () => openSlotManagementModal(btn.dataset.slotId, btn.dataset.currentStatus === 'true', btn.dataset.slotNumber);
                });
            }

            // Admin Profile Handlers
            if (viewName === 'adminProfile') {
                const reqOtpBtn = document.getElementById('request-otp-btn');
                const verifyOtpBtn = document.getElementById('verify-otp-btn');
                const saveProfileBtn = document.getElementById('save-profile-btn');
                const otpSection = document.getElementById('otp-section');

                let simulatedOtp = null;

                reqOtpBtn.onclick = () => {
                    const newPw = document.getElementById('profile-admin-new-password').value.trim();
                    if (!newPw) {
                        alert("Please enter a new password first.");
                        return;
                    }
                    const currentEmail = document.getElementById('profile-admin-email').value.trim() || 'gunjanpatel266@gmail.com';
                    // Simulate sending OTP
                    simulatedOtp = Math.floor(1000 + Math.random() * 9000).toString();
                    console.log(`[SIMULATED EMAIL TO ${currentEmail}] Admin password reset OTP is: ${simulatedOtp}`);
                    alert(`An OTP has been sent to ${currentEmail}. Check the console for the simulated OTP. (${simulatedOtp})`);

                    document.getElementById('otp-sent-message').textContent = `A verification code has been sent to ${currentEmail}.`;
                    reqOtpBtn.style.display = 'none';
                    otpSection.style.display = 'block';
                };

                verifyOtpBtn.onclick = () => {
                    const enteredOtp = document.getElementById('profile-admin-otp').value.trim();
                    const newPw = document.getElementById('profile-admin-new-password').value.trim();

                    if (enteredOtp === simulatedOtp) {
                        localStorage.setItem('adminPassword', newPw);
                        alert("Password updated successfully!");
                        // Reset flow
                        document.getElementById('profile-admin-new-password').value = '';
                        document.getElementById('profile-admin-otp').value = '';
                        otpSection.style.display = 'none';
                        reqOtpBtn.style.display = 'block';
                        simulatedOtp = null;
                    } else {
                        alert("Invalid OTP. Please try again.");
                    }
                };

                saveProfileBtn.onclick = () => {
                    const newUser = document.getElementById('profile-admin-username').value.trim();
                    const newEmail = document.getElementById('profile-admin-email').value.trim();

                    if (!newUser || !newEmail) {
                        alert("Username and Email cannot be empty"); return;
                    }
                    localStorage.setItem('adminUsername', newUser);
                    localStorage.setItem('adminEmail', newEmail);

                    document.querySelector('.admin-profile .admin-avatar').textContent = newUser.charAt(0).toUpperCase();
                    alert("Profile details saved successfully.");
                };
            }
        }
    } catch (error) {
        contentArea.innerHTML = '<div style="color:var(--error); padding:2rem;">Failed to connect to backend. Please ensure the server is running on port 8001.</div>';
    }
}

async function showUserDetails(userId) {
    const user = window.allUsersData.find(u => u.id == userId);
    if (!user) return;

    const modal = document.getElementById('user-details-modal');
    const body = document.getElementById('modal-user-body');

    // Fetch user bookings
    const bookings = await api.getBookings();
    const userBookings = bookings.filter(b => b.user_id == userId);

    body.innerHTML = `
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem;">
            <div>
                <h3 style="margin-bottom: 1rem;">Personal Information</h3>
                <div class="m-detail-row">
                    <span class="m-label">Full Name</span>
                    <span class="m-value">${user.name}</span>
                </div>
                <div class="m-detail-row">
                    <span class="m-label">Email Address</span>
                    <span class="m-value">${user.email}</span>
                </div>
                <div class="m-detail-row">
                    <span class="m-label">Phone Number</span>
                    <span class="m-value">${user.phone}</span>
                </div>
            </div>
            <div>
                <h3 style="margin-bottom: 1rem;">Registered Vehicles</h3>
                <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                    ${user.vehicles.map(v => `
                        <div style="background: #f8fafc; padding: 1rem; border-radius: 12px; border: 1px solid var(--border);">
                            <div style="font-weight: 800;">${v.name}</div>
                            <div style="font-size: 0.85rem; color: var(--primary); font-weight: 700;">${v.plate_number}</div>
                            <div style="font-size: 0.75rem; color: var(--text-muted);">${v.type}</div>
                        </div>
                    `).join('')}
                    ${user.vehicles.length === 0 ? '<div style="color:var(--text-muted);">No vehicles registered</div>' : ''}
                </div>
            </div>
        </div>

        <div style="margin-top: 2rem; border-top: 1px solid var(--border); padding-top: 2rem;">
            <h3 style="margin-bottom: 1rem;">Recent Bookings</h3>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Slot</th>
                        <th>Amount</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    ${userBookings.map(b => `
                        <tr>
                            <td>${new Date(b.start_time + (b.start_time.endsWith('Z') ? '' : 'Z')).toLocaleDateString()}</td>
                            <td class="text-primary">${b.slot ? b.slot.slot_number : 'N/A'}</td>
                            <td>₹ ${b.total_price.toFixed(2)}</td>
                            <td>
                                <span class="badge badge-${b.status.toLowerCase()}">
                                    ${b.status}
                                </span>
                            </td>
                        </tr>
                    `).join('')}
                    ${userBookings.length === 0 ? '<tr><td colspan="4" style="text-align:center; color:var(--text-muted);">No bookings found</td></tr>' : ''}
                </tbody>
            </table>
        </div>
    `;

    modal.style.display = 'flex';
}

async function confirmDeleteUser(userId) {
    if (confirm("Are you sure you want to permanently delete this user and all their records? This action cannot be undone.")) {
        try {
            await api.deleteUser(userId);
            alert("User deleted successfully.");
            renderView('users'); // Refresh list
        } catch (error) {
            alert("Failed to delete user.");
        }
    }
}

let currentManageSlotId = null;

async function openSlotManagementModal(slotId, currentStatus, slotNumber) {
    currentManageSlotId = slotId;
    const modal = document.getElementById('slot-management-modal');
    document.getElementById('manage-slot-number').textContent = slotNumber || slotId;

    const statusText = document.getElementById('manage-slot-status');
    statusText.textContent = currentStatus ? 'AVAILABLE' : 'OCCUPIED';
    statusText.style.color = currentStatus ? 'var(--success)' : 'var(--error)';

    modal.style.display = 'flex';
}

async function executeSlotUpdate(makeAvailable) {
    if (!currentManageSlotId) return;

    try {
        await api.updateAdminSlot(currentManageSlotId, { is_available: makeAvailable });
        document.getElementById('slot-management-modal').style.display = 'none';
        renderView('slots');
    } catch (e) {
        alert("Failed to update slot status");
        console.error(e);
    }
}

// Global Polling
setInterval(() => {
    if (localStorage.getItem('adminToken') === 'gunjan-session-active' && currentView !== 'adminProfile') {
        renderView(currentView, true);
    }
}, 3000);

// Init
document.addEventListener('DOMContentLoaded', () => {
    // Check Admin Session
    const isAdminAuthenticated = localStorage.getItem('adminToken') === 'gunjan-session-active';
    if (!isAdminAuthenticated) {
        loginOverlay.style.display = 'flex';
        mainLayout.style.display = 'none';
    } else {
        loginOverlay.style.display = 'none';
        mainLayout.style.display = 'grid';
        renderView('dashboard');
    }

    // Admin Status Setup
    const adminUsername = localStorage.getItem('adminUsername') || 'admin@parksmart.com';
    const adminPassword = localStorage.getItem('adminPassword') || 'admin123';
    document.querySelector('.admin-profile .admin-avatar').textContent = adminUsername.charAt(0).toUpperCase();

    // Auth View Toggles
    const loginView = document.getElementById('admin-login-view');
    const signupView = document.getElementById('admin-signup-view');

    document.getElementById('show-admin-signup').addEventListener('click', (e) => {
        e.preventDefault();
        loginView.style.display = 'none';
        signupView.style.display = 'block';
    });

    document.getElementById('show-admin-login').addEventListener('click', (e) => {
        e.preventDefault();
        signupView.style.display = 'none';
        loginView.style.display = 'block';
    });

    // Signup Handler
    document.getElementById('admin-signup-btn').addEventListener('click', () => {
        const newUser = document.getElementById('signup-admin-username').value.trim();
        const newEmail = document.getElementById('signup-admin-email').value.trim();
        const newPass = document.getElementById('signup-admin-password').value.trim();
        const error = document.getElementById('signup-error');

        if (!newUser || !newEmail || !newPass) {
            error.textContent = 'All fields are required.';
            return;
        }

        localStorage.setItem('adminUsername', newUser);
        localStorage.setItem('adminEmail', newEmail);
        localStorage.setItem('adminPassword', newPass);

        // Auto login on signup
        localStorage.setItem('adminToken', 'gunjan-session-active');
        location.reload();
    });

    // Login Handler
    document.getElementById('admin-login-btn').addEventListener('click', () => {
        const user = document.getElementById('admin-username').value;
        const pass = document.getElementById('admin-password').value;
        const error = document.getElementById('login-error');

        const expectedUser = localStorage.getItem('adminUsername') || 'admin@parksmart.com';
        const expectedPass = localStorage.getItem('adminPassword') || 'admin123';

        if (user === expectedUser && pass === expectedPass) {
            localStorage.setItem('adminToken', 'gunjan-session-active');
            location.reload();
        } else {
            error.textContent = 'Invalid Admin Credentials';
        }
    });

    // Admin Profile Modal Handlers
    document.getElementById('admin-profile-btn').addEventListener('click', () => {
        renderView('adminProfile');
    });

    // Navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            renderView(e.currentTarget.dataset.view);
        });
    });

    // Modal Close
    document.getElementById('close-modal').onclick = () => {
        document.getElementById('user-details-modal').style.display = 'none';
    };

    // Global Search Handler
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const searchTerm = e.target.value.toLowerCase().trim();
                const currentTable = document.querySelector('.card table tbody');

                if (currentTable) {
                    const rows = currentTable.querySelectorAll('tr');
                    rows.forEach(row => {
                        const rowText = row.textContent.toLowerCase();
                        if (rowText.includes(searchTerm)) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                }
            }
        });
    }

    document.getElementById('logout-btn').addEventListener('click', () => {
        localStorage.removeItem('adminToken');
        location.reload();
    });

    // Slot Management Modal Handlers
    document.getElementById('close-slot-modal').onclick = () => {
        document.getElementById('slot-management-modal').style.display = 'none';
    };
    document.getElementById('btn-make-available').onclick = () => executeSlotUpdate(true);
    document.getElementById('btn-make-occupied').onclick = () => executeSlotUpdate(false);
});
