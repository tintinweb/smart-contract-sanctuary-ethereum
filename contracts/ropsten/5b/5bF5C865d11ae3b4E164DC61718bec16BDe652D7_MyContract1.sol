/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.13;

contract MyContract1 {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function getContractOnwer() public view returns (address) {
        return owner;
    }
}