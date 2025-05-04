/**
 * Simple configuration manager for Glance widgets
 */
document.addEventListener('DOMContentLoaded', function() {
  // Create configuration UI
  createConfigUI();
  
  // Setup event listeners for configuration button
  setupConfigListeners();
});

/**
 * Get configuration from localStorage
 */
function getConfig() {
  const configString = localStorage.getItem('glance_config');
  return configString ? JSON.parse(configString) : {
    commafeed: {
      token: '',
      apiUrl: ''
    }
  };
}

/**
 * Save configuration to localStorage
 */
function saveConfig(config) {
  localStorage.setItem('glance_config', JSON.stringify(config));
}

/**
 * Create the configuration UI elements
 */
function createConfigUI() {
  // Create the configuration button (gear icon)
  const configButton = document.createElement('div');
  configButton.id = 'config-button';
  configButton.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" 
      stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="3"></circle>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
    </svg>
  `;
  configButton.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 1000;
    opacity: 0.4;
    transition: opacity 0.2s;
    background-color: rgba(100, 100, 100, 0.2);
  `;
  
  // Create the configuration panel
  const configPanel = document.createElement('div');
  configPanel.id = 'config-panel';
  configPanel.style.cssText = `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background-color: var(--color-background);
    border: 1px solid var(--color-border);
    border-radius: 8px;
    padding: 20px;
    width: 400px;
    z-index: 1001;
    display: none;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  `;
  
  const config = getConfig();
  
  configPanel.innerHTML = `
    <h3 style="margin-top: 0; margin-bottom: 20px;">Configuration</h3>
    
    <div style="margin-bottom: 20px;">
      <label for="commafeed-token" style="display: block; margin-bottom: 5px;">CommaFeed Token</label>
      <input type="password" id="commafeed-token" value="${config.commafeed.token}" style="
        width: 100%;
        padding: 8px;
        box-sizing: border-box;
        background-color: rgba(255, 255, 255, 0.1);
        border: 1px solid var(--color-border);
        border-radius: 4px;
        color: inherit;
      ">
    </div>
    
    <div style="margin-bottom: 20px;">
      <label for="commafeed-api-url" style="display: block; margin-bottom: 5px;">CommaFeed API URL</label>
      <input type="text" id="commafeed-api-url" value="${config.commafeed.apiUrl}" style="
        width: 100%;
        padding: 8px;
        box-sizing: border-box;
        background-color: rgba(255, 255, 255, 0.1);
        border: 1px solid var(--color-border);
        border-radius: 4px;
        color: inherit;
      ">
    </div>
    
    <div style="display: flex; justify-content: flex-end; gap: 10px;">
      <button id="config-cancel" style="
        padding: 8px 12px;
        background-color: transparent;
        border: 1px solid var(--color-border);
        border-radius: 4px;
        cursor: pointer;
        color: inherit;
      ">Cancel</button>
      
      <button id="config-save" style="
        padding: 8px 12px;
        background-color: var(--color-positive);
        border: none;
        border-radius: 4px;
        cursor: pointer;
        color: #45475a;
      ">Save</button>
    </div>
  `;
  
  // Create overlay for background dimming
  const overlay = document.createElement('div');
  overlay.id = 'config-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 1000;
    display: none;
  `;
  
  // Add elements to the DOM
  document.body.appendChild(configButton);
  document.body.appendChild(overlay);
  document.body.appendChild(configPanel);
}

/**
 * Setup event listeners for the configuration UI
 */
function setupConfigListeners() {
  // Wait a bit to ensure DOM is fully loaded
  setTimeout(() => {
    const configButton = document.getElementById('config-button');
    const configPanel = document.getElementById('config-panel');
    const overlay = document.getElementById('config-overlay');
    const saveButton = document.getElementById('config-save');
    const cancelButton = document.getElementById('config-cancel');
    
    if (!configButton || !configPanel || !overlay || !saveButton || !cancelButton) {
      console.error('Configuration UI elements not found');
      return;
    }
    
    // Show configuration panel
    configButton.addEventListener('click', function() {
      overlay.style.display = 'block';
      configPanel.style.display = 'block';
      
      // Load current config
      const config = getConfig();
      document.getElementById('commafeed-token').value = config.commafeed.token || '';
      document.getElementById('commafeed-api-url').value = config.commafeed.apiUrl || '';
    });
    
    // Hide configuration panel when clicking overlay
    overlay.addEventListener('click', function() {
      overlay.style.display = 'none';
      configPanel.style.display = 'none';
    });
    
    // Cancel button
    cancelButton.addEventListener('click', function() {
      overlay.style.display = 'none';
      configPanel.style.display = 'none';
    });
    
    // Save button
    saveButton.addEventListener('click', function() {
      const config = getConfig();
      
      // Update config with form values
      config.commafeed.token = document.getElementById('commafeed-token').value;
      config.commafeed.apiUrl = document.getElementById('commafeed-api-url').value;
      
      // Save config
      saveConfig(config);
      
      // Hide the panel
      overlay.style.display = 'none';
      configPanel.style.display = 'none';
    });
    
    // Style hover effect
    configButton.addEventListener('mouseover', function() {
      this.style.opacity = '0.8';
    });
    
    configButton.addEventListener('mouseout', function() {
      this.style.opacity = '0.4';
    });
  }, 500);
}

// Global-scope accessor for other scripts
window.glanceConfig = {
  getConfig: getConfig,
  saveConfig: saveConfig
};
