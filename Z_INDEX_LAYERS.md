# Z-Index Layer Management

## Layer Hierarchy (from highest to lowest)

### 9999 - StatusBar
- Always visible at the top
- Shows time and device status

### 9998 - BottomNavbar  
- Always visible at the bottom
- Main navigation component
- **MUST NEVER BE COVERED**

### 9997 - DevNavigation
- Development tools
- Floating button and menu

### 9996 - PageTransition
- Page transition overlay
- Temporary during navigation

### 9995 - Toast Notifications
- User feedback messages
- Temporary notifications

### 9990 - SearchModal
- Full-screen search interface
- Covers content but not navbar/statusbar

### 9980 - Map Modals
- Place detail modals in map view
- Should not cover navbar

### Default/Lower - Content
- All page content
- Modals within pages
- Regular UI elements

## Rules
1. StatusBar (9999) and BottomNavbar (9998) must ALWAYS be visible
2. No component should use z-index higher than 9999
3. Temporary overlays (transitions, toasts) use 9995-9996
4. Full-screen modals use 9990
5. Page-specific modals use 9980 or lower