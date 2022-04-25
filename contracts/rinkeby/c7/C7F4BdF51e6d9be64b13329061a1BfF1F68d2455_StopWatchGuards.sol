// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @notice Transition guard functions
 *
 * - Machine: StopWatch
 * - Guards: Paused/Enter, Ready/Enter
 */
contract StopWatchGuards {

    // Events
    event StopWatchReset(address indexed user);
    event StopWatchRunning(address indexed user, uint256 elapsed);
    event StopWatchPaused(address indexed user, uint256 elapsed);

    // States
    string private constant READY   = "Ready";
    string private constant RUNNING = "Running";
    string private constant PAUSED  = "Paused";

    // Machine-specific storage slot
    bytes32 private constant STOPWATCH_SLOT = keccak256("fismo.example.stopwatch.storage.slot");

    /// User-specific slice of the stopwatch memory bank, accessed by state guards
    struct UserSlice {

        // starting block.timestamp
        uint256 timeStarted;

        // elapsed time
        uint256 timeElapsed;

        // block.timestamp when last paused
        uint256 timeLastPaused;

        // total time spent in paused state
        uint256 totalTimePaused;

    }

    /**
     * Storage slot structure
     */
    struct StopWatchSlot {

        // maps user wallet => UserSlice struct
        mapping(address => UserSlice) memoryBank;

    }

    /**
     * @notice Get the StopWatch machine's storage slot
     *
     * @return stopWatchStorage - StopWatch storage slot
     */
    function stopWatchSlot()
    internal
    pure
    returns (StopWatchSlot storage stopWatchStorage)
    {
        bytes32 position = STOPWATCH_SLOT;
        assembly {
            stopWatchStorage.slot := position
        }
    }

    /**
     * @notice Get the user's slice of the memory bank
     *
     * @param _user - the wallet address of the user
     * @return slice - the user's slice of the memory bank as a UserSlice struct
     */
    function userSlice(address _user)
    internal
    view
    returns (UserSlice storage slice)
    {
        slice = stopWatchSlot().memoryBank[_user];
    }

    /**
     * @notice Compare two strings
     */
    function compare(string memory _a, string memory _b)
    internal
    pure
    returns
    (bool)
    {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    /**
     * @notice Calculate / store time elapsed for user
     */
    function calcTimeElapsed(UserSlice memory slice)
    internal
    view
    {
        slice.timeElapsed = block.timestamp - (block.timestamp + slice.totalTimePaused);
    }

    // -------------------------------------------------------------------------
    // TRANSITION GUARDS
    // -------------------------------------------------------------------------

    // Ready / Enter
    // Initial state.
    // Valid prior states: Paused
    // - resets user memory
    // - emits StopWatchReset if previously paused
    function StopWatch_Ready_Enter(address _user, string calldata _action, string calldata _priorStateName)
    external
    returns(string memory message)
    {
        // Reset user memory
        delete stopWatchSlot().memoryBank[_user];

        // If previous state was paused, emit reset event
        if (compare(_priorStateName, PAUSED)) emit StopWatchReset(_user);

        // Respond with new state
        message = READY;
    }

    // Ready / Exit
    // Valid next states: Running
    // - Stores start time
    function StopWatch_Ready_Exit(address _user, string calldata _action, string calldata _nextStateName)
    external
    returns(string memory message)
    {
        stopWatchSlot().memoryBank[_user].timeStarted = block.timestamp;
    }

    // Running / Enter
    // Valid prior states: Ready, Paused
    // - emits StopWatchRunning if previously paused
    function StopWatch_Running_Enter(address _user, string calldata _action, string calldata _priorStateName)
    external
    returns(string memory message)
    {
        emit StopWatchRunning(_user, userSlice(_user).timeElapsed);
        message = RUNNING;
    }

    // Paused / Enter
    // Valid prior states: Running
    // - stores time last paused
    // - calculates & stores time elapsed
    // - emits StopWatchPaused event
    function StopWatch_Paused_Enter(address _user, string calldata _action, string calldata _priorStateName)
    external
    returns(string memory message)
    {
        UserSlice storage slice = userSlice(_user);
        slice.timeLastPaused = block.timestamp;
        calcTimeElapsed(slice);
        emit StopWatchPaused(_user, block.timestamp);
        message = PAUSED;
    }

    // Paused / Exit
    // Valid next states: Running
    // - calculates & stores total time paused
    // - calculates and stores time elapsed
    function StopWatch_Paused_Exit(address _user, string calldata _action, string calldata _priorStateName)
    external
    returns(string memory message)
    {
        UserSlice storage slice = userSlice(_user);
        slice.totalTimePaused = slice.totalTimePaused + (block.timestamp - slice.timeLastPaused);
        calcTimeElapsed(slice);
    }

}