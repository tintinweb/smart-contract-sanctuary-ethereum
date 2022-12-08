// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Template {

    address public owner;
    uint public something;

    constructor(address _owner, uint args) {
        owner = _owner;
        something = args;
    }       

}  

contract Factory {

    address[] public deployedContracts;
    Template[] public deployedTemplates;

    function createNew(uint arg1) public {
        Template t = new Template(msg.sender, arg1);
        deployedContracts.push(address(t));
        deployedTemplates.push(t);
    }
}