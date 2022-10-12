//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//for testing purposes
contract OldTellor{
    
    mapping(address => uint256) public balances;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function setBalance(address _a, uint256 _b) external{
        require(msg.sender == owner, "must be owner");
        balances[_a] = _b;
    }

    function changeOwner(address _newOwner) external{
        require(msg.sender == owner, "must be owner");
        owner = _newOwner;
    }

    function balanceOf(address _a) external view returns(uint256){
        return balances[_a];
    }

}