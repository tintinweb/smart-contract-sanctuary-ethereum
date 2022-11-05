/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

pragma solidity ^0.8.17;

contract Ultimum {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
    } 
}