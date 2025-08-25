# Production Hash Routing Test Guide

This guide provides step-by-step instructions to manually test hash routing functionality in the production build.

## Prerequisites

1. Production build must be completed: `npm run build`
2. Built files should be available in the `dist/` directory
3. A local web server to serve the built files

## Testing Procedure

### Step 1: Serve the Production Build

Since the production build files are in the `dist/` directory, you need to serve them with a local web server. You can use any of these methods:

**Option A: Using Python (if available)**
```bash
cd dist
python -m http.server 8000
```
Then open: http://localhost:8000

**Option B: Using Node.js serve (if installed globally)**
```bash
npx serve dist
```

**Option C: Using any other local web server**
Point your web server to serve files from the `dist/` directory.

### Step 2: Test Direct Hash URL Access

Test each of these URLs by typing them directly into your browser address bar:

#### Requirement 1.1 & 1.2: Landing Page Access
- [ ] `http://localhost:8000/` → Should display landing page
- [ ] `http://localhost:8000/#/` → Should display landing page  
- [ ] `http://localhost:8000/#/landing` → Should display landing page

#### Requirement 1.3: Tic-Tac-Toe Page Access
- [ ] `http://localhost:8000/#/tic-tac-toe` → Should display tic-tac-toe game
- [ ] Game should be fully functional (can make moves, AI responds)
- [ ] Theme toggle should work
- [ ] Back navigation should work

#### Requirement 1.4: Robot Game Page Access
- [ ] `http://localhost:8000/#/robot-game` → Should display robot grid game
- [ ] Robot should be visible on the grid
- [ ] Arrow key controls should work
- [ ] Button controls should work
- [ ] Theme toggle should work

#### Requirement 1.5: Style Guide Page Access
- [ ] `http://localhost:8000/#/style-guide` → Should display style guide
- [ ] All theme colors should be visible
- [ ] Back to landing navigation should work
- [ ] Theme toggle should work

### Step 3: Test Bookmark and Refresh Functionality

#### Requirement 3.4: Page State Preservation on Refresh

1. **Bookmark Test:**
   - Navigate to `http://localhost:8000/#/tic-tac-toe`
   - Bookmark the page
   - Close the browser
   - Open the bookmark → Should load tic-tac-toe game directly

2. **Refresh Test:**
   - Navigate to `http://localhost:8000/#/robot-game`
   - Press F5 or Ctrl+R to refresh
   - Page should reload and still show robot game

3. **Direct URL Test:**
   - Copy `http://localhost:8000/#/style-guide` 
   - Paste into a new browser tab
   - Should load style guide directly

### Step 4: Test Browser Navigation

1. **Forward/Back Navigation:**
   - Start at landing page: `http://localhost:8000/#/landing`
   - Click to navigate to tic-tac-toe game
   - URL should change to: `http://localhost:8000/#/tic-tac-toe`
   - Click browser back button → Should return to landing page
   - Click browser forward button → Should return to tic-tac-toe game

2. **Navigation History:**
   - Navigate: Landing → Tic-Tac-Toe → Robot Game → Style Guide
   - Use browser back button to go: Style Guide → Robot Game → Tic-Tac-Toe → Landing
   - Each step should work correctly and maintain proper URLs

### Step 5: Test Error Handling

Test these invalid URLs to ensure they redirect to landing page:

- [ ] `http://localhost:8000/#/invalid-route` → Should redirect to landing
- [ ] `http://localhost:8000/#/TIC-TAC-TOE` → Should redirect to landing (case sensitive)
- [ ] `http://localhost:8000/#/tic-tac-toe/extra/path` → Should redirect to landing
- [ ] `http://localhost:8000/#/robot-game@#$%` → Should redirect to landing

### Step 6: Test State Preservation

1. **Theme Preservation:**
   - Go to `http://localhost:8000/#/tic-tac-toe`
   - Toggle to dark theme
   - Navigate to `http://localhost:8000/#/robot-game`
   - Theme should remain dark
   - Navigate back to `http://localhost:8000/#/tic-tac-toe`
   - Theme should still be dark

2. **Game State Preservation:**
   - Go to `http://localhost:8000/#/tic-tac-toe`
   - Make a few moves in the game
   - Navigate to `http://localhost:8000/#/landing`
   - Navigate back to `http://localhost:8000/#/tic-tac-toe`
   - Game state should be preserved (moves still visible)

### Step 7: Test Web Worker Functionality

**Important:** Web workers only work in production builds, not development mode.

1. **AI Functionality Test:**
   - Go to `http://localhost:8000/#/tic-tac-toe`
   - Make a move as player X
   - Verify that the game shows "Player O's thinking"
   - Verify that the AI makes a move automatically
   - Check browser developer tools for any worker-related errors

2. **Worker Loading Test:**
   - Open browser Developer Tools (F12)
   - Go to Network tab
   - Navigate to `http://localhost:8000/#/tic-tac-toe`
   - Verify that `worker.*.js` file is loaded successfully
   - Make a move to trigger AI
   - Verify no errors in Console tab

## Expected Results

### All Tests Should Pass

- ✅ All direct hash URL access works correctly
- ✅ Bookmark and refresh functionality works
- ✅ Browser navigation (back/forward) works
- ✅ Invalid URLs redirect to landing page
- ✅ State preservation works across navigation
- ✅ Web worker functionality works in production build

### Common Issues and Solutions

**Issue:** Hash URLs don't work
- **Solution:** Ensure you're serving the production build, not using development mode

**Issue:** Web workers don't work
- **Solution:** Web workers require production build. Development mode removes worker functionality.

**Issue:** Navigation doesn't update URL
- **Solution:** Check that Browser.Hash is being used correctly in the main application

**Issue:** Refresh shows 404 error
- **Solution:** This is expected for hash routing. The hash fragment should be preserved and parsed correctly.

## Verification Checklist

Mark each item as completed during testing:

### Direct Hash URL Access
- [ ] Root URL loads landing page
- [ ] `#/landing` loads landing page
- [ ] `#/tic-tac-toe` loads tic-tac-toe game
- [ ] `#/robot-game` loads robot game
- [ ] `#/style-guide` loads style guide
- [ ] Invalid URLs redirect to landing

### Browser Navigation
- [ ] Back button works correctly
- [ ] Forward button works correctly
- [ ] URL updates during navigation
- [ ] Navigation history is maintained

### State Preservation
- [ ] Theme persists across navigation
- [ ] Game state persists across navigation
- [ ] Window size information is maintained

### Error Handling
- [ ] Invalid routes handled gracefully
- [ ] Malformed URLs redirect to landing
- [ ] Case sensitivity enforced

### Production Build Specific
- [ ] Web workers function correctly
- [ ] All assets load properly
- [ ] No console errors
- [ ] Performance is acceptable

## Test Completion

Once all tests pass, the hash routing implementation meets all requirements:

- **Requirement 1.1-1.5:** Direct hash URL access ✅
- **Requirement 3.4:** State preservation on refresh ✅
- **All other requirements:** Verified through comprehensive testing ✅

The production build hash routing functionality is working correctly and ready for deployment.