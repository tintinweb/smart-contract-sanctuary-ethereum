// SPDX-License-Identify: LGPL-3.0-only
pragma solidity >=0.8.8 <0.9;

contract Token {
    address private owner;
    string public constant name= "My Token";
    uint256 private totalSuply;
    mapping (address=>uint256) private balances;

    constructor(uint256 _totalSupply){
        owner=msg.sender;
        totalSuply=_totalSupply;
        balances[owner]+=totalSuply;

    }

    function transfer(uint256 _amount, address _to) external{

        require(balances[msg.sender]>_amount,"No enough funds");
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;

    }
    function balanceOf(address _address) external view returns(uint256 result){

        result= balances[_address];

    }

    function getTotalSupply() external view returns(uint256 _totalsuply){
        _totalsuply=totalSuply;
    }
}