/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Vault {
    address public delegate;
    address public owner;

    event Deposit(address _from, uint256 value);
    event DelegateUpdated(address oldDelegate, address newDelegate);

    constructor(address _imp) {
        owner = msg.sender;
        delegate = _imp;
    }

    modifier onlyAuth() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "No permission"
        );
        _;
    }

    // Any ether sent to this contract will follow the vesting schedule defined in Vesting.sol
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        _delegate(delegate);
    }

    function upgradeDelegate(address newDelegateAddress) external {
        require(msg.sender == owner, "Only owner");
        address oldDelegate = delegate;
        delegate = newDelegateAddress;

        emit DelegateUpdated(oldDelegate, newDelegateAddress);
    }

    function execute(address _target, bytes memory payload)
        external
        returns (bytes memory)
    {
        (bool success, bytes memory ret) = address(_target).call(payload);
        require(success, "failed");
        return ret;
    }

    function _delegate(address _imp) internal onlyAuth {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch space at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // delegatecall the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let success := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch success
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}