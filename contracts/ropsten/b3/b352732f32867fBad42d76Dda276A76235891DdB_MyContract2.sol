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


contract MyContract2 is MyContract1 {
    address public creator;
    string public name;

    constructor(string memory _name) {
        name = _name;
        creator = owner;
    }

    function getOwnerName() public view returns (string memory) {
        return name;
    }

    function getOwner2() public view returns (address) {
        return creator;
    }
}