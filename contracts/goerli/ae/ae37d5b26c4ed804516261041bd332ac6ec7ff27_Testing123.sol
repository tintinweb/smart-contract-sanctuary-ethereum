/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title some title
/// @author some author
/// @notice some nice
/// @dev some dev
/// @custom:experimental This is an experimental contract.
contract Testing123 {

    /// some event
    /// @dev set current state event
    /// @param _currentState the new state
    event CurrentState(uint256 indexed _currentState);

    /// custom error
    /// @dev reverts with error message
    /// @param _errorMessage the message
    error SomeError(string _errorMessage);

    /// current state
    uint256 public currentState;

    constructor() {
        currentState = 1;
        emit CurrentState(1);
    }

    /// Set the current state
    /// @dev set and emit event
    /// @param _newCurrentState the new current state
    function SetCurrentState(uint256 _newCurrentState) public {
        currentState = _newCurrentState;
        emit CurrentState(_newCurrentState);
    }

    /// just reverts
    /// @dev reverts a custom error
    function JustRevert() public {
        revert SomeError('just revert');
    }
}