// File: contracts/AllowanceTarget.sol

pragma solidity ^0.6.5;

import "./IAllowanceTarget.sol";
import "./Address.sol";

/**
 * @dev AllowanceTarget contract
 */
contract AllowanceTarget is IAllowanceTarget {
    using Address for address;

    uint256 private constant TIME_LOCK_DURATION = 1 days;

    address public spender;
    address public newSpender;
    uint256 public timelockExpirationTime;

    modifier onlySpender() {
        require(spender == msg.sender, "AllowanceTarget: not the spender");
        _;
    }

    constructor(address _spender) public {
        require(
            _spender != address(0),
            "AllowanceTarget: _spender should not be 0"
        );

        // Set spender
        spender = _spender;
    }

    function setSpenderWithTimelock(address _newSpender)
        external
        override
        onlySpender
    {
        require(
            _newSpender.isContract(),
            "AllowanceTarget: new spender not a contract"
        );
        require(
            newSpender == address(0) && timelockExpirationTime == 0,
            "AllowanceTarget: SetSpender in progress"
        );

        timelockExpirationTime = now + TIME_LOCK_DURATION;
        newSpender = _newSpender;
    }

    function completeSetSpender() external override {
        require(
            timelockExpirationTime != 0,
            "AllowanceTarget: no pending SetSpender"
        );
        require(
            now >= timelockExpirationTime,
            "AllowanceTarget: time lock not expired yet"
        );

        // Set new spender
        spender = newSpender;
        // Reset
        timelockExpirationTime = 0;
        newSpender = address(0);
    }

    function teardown() external override onlySpender {
        selfdestruct(payable(spender));
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(address payable target, bytes calldata callData)
        external
        override
        onlySpender
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call(callData);
        if (!success) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}