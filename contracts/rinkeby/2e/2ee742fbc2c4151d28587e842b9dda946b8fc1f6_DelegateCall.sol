/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// File: delegateCall.sol

pragma solidity ^0.8.0;

contract DelegateCall {
    uint public number;
    address public owner;
    uint public value;

    function set(address test, uint num) public payable {
        (bool success, bytes memory data) = test.delegatecall(abi.encodeWithSignature("set(uint256)", num));
        require(success, "failed");
    }
}