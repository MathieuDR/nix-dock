document.addEventListener('DOMContentLoaded', function() {
  // Initial setup - may not work if content is loaded dynamically
  initialSetup();
  
  // Set up a mutation observer to detect when the content is actually loaded
  observeContentChanges();
});

/**
 * Run initial setup tasks
 */
function initialSetup() {
  // Format relative dates
  formatRelativeDates();
  
  // Set up click handlers for read status
  setupReadStatusHandlers();
  
  // Set up handlers for the discrete mark-as-read buttons
  setupMarkAsReadButtons();
}

/**
 * Observe DOM changes to handle dynamically loaded content
 */
function observeContentChanges() {
  // Create a mutation observer to watch for added content
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes && mutation.addedNodes.length > 0) {
        // Check if we've added any entry-date elements
        const hasDateElements = Array.from(mutation.addedNodes).some(node => {
          return node.querySelectorAll && node.querySelectorAll('.entry-date').length > 0;
        });
        
        if (hasDateElements) {
          // Run setup again when new content is added
          initialSetup();
        }
      }
    });
  });
  
  // Start observing the document body for changes
  observer.observe(document.body, { childList: true, subtree: true });
}

/**
 * Format all entry date elements with relative time
 */
function formatRelativeDates() {
  const dateElements = document.querySelectorAll('.entry-date');
  
  dateElements.forEach(element => {
    const timestamp = parseInt(element.getAttribute('data-timestamp'));
    if (isNaN(timestamp) || timestamp <= 0) return;
    
    const date = new Date(timestamp);
    const now = new Date();
    
    element.textContent = getRelativeTimeString(date, now);
  });
}

/**
 * Get a human-readable relative time string with simplified intervals
 */
function getRelativeTimeString(date, now) {
  const diffMs = now - date;
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);
  
  if (diffDay > 30) {
    return date.toLocaleDateString();
  } else if (diffDay > 1) {
    return `${diffDay} days ago`;
  } else if (diffDay === 1) {
    return 'Yesterday';
  } else if (diffHour >= 1) {
    return `${diffHour} hours ago`;
  } else if (diffMin >= 5) {
    return `${diffMin} minutes ago`;
  } else {
    return 'Just now';
  }
}

/**
 * Set up handlers to mark entries as read when clicked
 */
function setupReadStatusHandlers() {
  // Target all links with entry ID data attributes
  const entryLinks = document.querySelectorAll('a[data-entry-id]');
  
  entryLinks.forEach(link => {
    link.addEventListener('click', function(event) {
      const entryId = this.getAttribute('data-entry-id');
      
      // Check if this entry is already marked as read
      const parentLi = getListItemParent(this);
      
      if (parentLi && !parentLi.classList.contains('read') && !parentLi.classList.contains('read-error')) {
        // Mark as read in CommaFeed by making an API request
        markAsRead(entryId);
        
        // Visually indicate the entry has been read
        parentLi.classList.add('read');
        parentLi.style.opacity = '0.6';
      }
      
      // Don't prevent the default behavior - still follow the link
    });
  });
}

/**
 * Set up handlers for the discrete mark-as-read buttons
 */
function setupMarkAsReadButtons() {
  // Target all mark-read buttons with entry ID data attributes
  const markReadButtons = document.querySelectorAll('.mark-read-btn[data-entry-id]');
  
  markReadButtons.forEach(button => {
    // Show button on hover of parent list item
    const parentLi = getListItemParent(button);
    if (parentLi) {
      // Setup hover effect to make buttons more visible on hover
      parentLi.addEventListener('mouseenter', function() {
        const markBtn = this.querySelector('.mark-read-btn');
        if (markBtn) markBtn.style.opacity = '0.7';
      });
      
      parentLi.addEventListener('mouseleave', function() {
        const markBtn = this.querySelector('.mark-read-btn');
        if (markBtn) markBtn.style.opacity = '0.3';
      });
    }
    
    // Handle click on mark as read button
    button.addEventListener('click', function(event) {
      // Prevent event bubbling
      event.preventDefault();
      event.stopPropagation();
      
      const entryId = this.getAttribute('data-entry-id');
      
      // Check if this entry is already marked as read
      const parentLi = getListItemParent(this);
      
      if (parentLi && !parentLi.classList.contains('read') && !parentLi.classList.contains('read-error')) {
        // Mark as read in CommaFeed by making an API request
        markAsRead(entryId);
        
        // Visually indicate the entry has been read
        parentLi.classList.add('read');
        parentLi.style.opacity = '0.6';
        
        // Optionally, can hide the mark as read button now
        this.style.display = 'none';
      }
    });
  });
}

/**
 * Find the parent list item element
 */
function getListItemParent(element) {
  let current = element;
  while (current && current.tagName !== 'LI') {
    current = current.parentElement;
  }
  return current;
}

/**
 * Mark entry with error state visually - more discreetly
 */
function markEntryWithError(entryId) {
  // Find all list items containing this entry ID
  const entryItems = document.querySelectorAll(`li[data-entry-id="${entryId}"]`);
  
  if (entryItems.length === 0) {
    // Try to find the parent list item of links with this ID
    const links = document.querySelectorAll(`a[data-entry-id="${entryId}"]`);
    
    links.forEach(link => {
      const parentLi = getListItemParent(link);
      if (parentLi) {
        // Add error styling - only to specific elements
        parentLi.classList.add('read-error');
        
        // Apply error styling to the title, feedname, and timestamp
        const title = parentLi.querySelector('a[data-entry-id]');
        const feedName = parentLi.querySelector('.size-h6.color-dim');
        const timestamp = parentLi.querySelector('.entry-date');
        const markReadBtn = parentLi.querySelector('.mark-read-btn');
        
        if (title) {
          title.style.color = 'var(--color-negative, #f38ba8)';
        }
        
        if (feedName) {
          feedName.style.color = 'var(--color-negative, #f38ba8)';
          feedName.style.opacity = '0.8';
        }
        
        if (timestamp) {
          timestamp.style.color = 'var(--color-negative, #f38ba8)';
          timestamp.style.opacity = '0.8';
        }
        
        if (markReadBtn) {
          markReadBtn.style.color = 'var(--color-negative, #f38ba8)';
          markReadBtn.style.opacity = '0.8';
        }
      }
    });
  } else {
    // Apply error styling to found items
    entryItems.forEach(item => {
      item.classList.add('read-error');
      
      // Apply error styling to the title, feedname, and timestamp
      const title = item.querySelector('a[data-entry-id]');
      const feedName = item.querySelector('.size-h6.color-dim');
      const timestamp = item.querySelector('.entry-date');
      const markReadBtn = item.querySelector('.mark-read-btn');
      
      if (title) {
        title.style.color = 'var(--color-negative, #f38ba8)';
      }
      
      if (feedName) {
        feedName.style.color = 'var(--color-negative, #f38ba8)';
        feedName.style.opacity = '0.8';
      }
      
      if (timestamp) {
        timestamp.style.color = 'var(--color-negative, #f38ba8)';
        timestamp.style.opacity = '0.8';
      }
      
      if (markReadBtn) {
        markReadBtn.style.color = 'var(--color-negative, #f38ba8)';
        markReadBtn.style.opacity = '0.8';
      }
    });
  }
}

/**
 * Send API request to mark an entry as read
 */
function markAsRead(entryId) {
  if (!entryId) return;
  
  // Get the token and API URL from configuration
  let token = '';
  let apiUrl = '';
  
  try {
    if (window.glanceConfig && typeof window.glanceConfig.getConfig === 'function') {
      const config = window.glanceConfig.getConfig();
      token = config.commafeed.token;
      apiUrl = config.commafeed.apiUrl || '';
    }
  } catch (error) {
    console.error('Error getting CommaFeed configuration:', error);
    markEntryWithError(entryId);
    return;
  }
  
  if (!token) {
    console.error('Not authenticated: No CommaFeed token available. Please set it in the configuration.');
    markEntryWithError(entryId);
    return;
  }
  
  if (!apiUrl) {
    console.error('No API URL configured for CommaFeed. Please set it in the configuration.');
    markEntryWithError(entryId);
    return;
  }
  
  // Make the API request to mark entry as read
  fetch(`${apiUrl}/rest/entry/mark`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + token
    },
    body: JSON.stringify({
      id: entryId,
      read: true
    })
  })
  .then(response => {
    if (!response.ok) {
      console.error(`Failed to mark entry as read. Status: ${response.status}`);
      response.text().then(text => {
        console.error('Response:', text);
        markEntryWithError(entryId);
      });
      return Promise.reject(response);
    }
    return response.text();
  })
  .then(data => {
    console.log(`Entry ${entryId} marked as read successfully`);
  })
  .catch(error => {
    console.error('Error marking entry as read:', error);
    markEntryWithError(entryId);
  });
}

// Add a function to periodically refresh the relative timestamps
function refreshTimestamps() {
  setInterval(() => {
    formatRelativeDates();
  }, 60000); // Update every minute
}

// Initialize the timestamp refresh
setTimeout(() => {
  // Run one more time after a short delay to catch any late-loaded content
  formatRelativeDates();
  setupReadStatusHandlers();
  setupMarkAsReadButtons();
  
  // Then set up the regular refresh interval
  refreshTimestamps();
}, 1000);
