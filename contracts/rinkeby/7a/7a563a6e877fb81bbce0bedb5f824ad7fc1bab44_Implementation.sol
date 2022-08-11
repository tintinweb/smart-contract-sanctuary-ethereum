/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

contract Implementation{
    uint public x;
    bool public isBase;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner, "ERROR: Only Owner");
        _;
    }

    constructor(){
        //This ensures that the base contract cann't be initialized
        isBase = true;
    }

    function initialize(address _owner) external{
        //For the base contract, isBase == true. Impossible to use.
        require(isBase == false, "ERROR: This is the base contract, cann't initialize");
        //Owner address defaults to address(0). Once this function is called, there is no way to call it again.
        require(owner == address(0), "ERROR: contract already initialized");
        owner = _owner;
    }

    function setX(uint _X) external{
        x = _X;
    }

    function getX() external view returns(uint){
        return x;
    }
}