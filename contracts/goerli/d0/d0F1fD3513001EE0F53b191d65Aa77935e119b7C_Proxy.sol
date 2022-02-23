/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)
pragma solidity ^0.8.0;

contract StorageStructure {
    address public implementation;
    address public owner;
    mapping(address => uint256) public points;
    uint256 public totalPlayers;
}

contract Proxy is StorageStructure {
    //确保只有所有者可以运行这个函数
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function upgradeTo(address _newImplementation) external onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }

    function _delegate() internal {
        address imp = implementation;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), imp, ptr, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(ptr, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }

    function _fallback() internal {
        _delegate();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }
}