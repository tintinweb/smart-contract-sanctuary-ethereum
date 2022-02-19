/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Storage {

    address public delegate;
    address public owner;

    constructor(address _owner){
        owner = _owner;
    }

    function setDelegate(address _impl) public{
        delegate = _impl;
    }
}

contract Proxy {

    address immutable public store;

    constructor(){
        store = address(new Storage(msg.sender));
    }

    function upgradeDelegate(address newDelegateAddress) public {
        require(msg.sender == Storage(store).owner());
        Storage(store).setDelegate(newDelegateAddress);
    }

    function _delegate(address impl) private {
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), impl, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }

    function _beforeFallback() private{
        emit CallMade(Storage(store).delegate(), msg.data, msg.value);
    }

    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(Storage(store).delegate());
    }
        
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    event CallMade(address implementation, bytes data, uint256 value);
}