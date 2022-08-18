/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Tether{
    string public name = "Tether";
    string public symbol = "$USDT";
    uint256 public totalSupply = 1000000000000000000;
    uint8 public decimal = 18;

    address public _owner;
    address payable[] wallets;
    mapping(address=>uint) balanceOf;


    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approve(address indexed _owner, address indexed _spender, uint _value);

    constructor(){
        _owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }


    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function balanceCheck (address _from, uint value) private view returns (bool) {
        if(balanceOf[_from] >= value ){
            return true;
        }else{return false;}
    }

    function Investor(address _to, uint value) public onlyOwner returns(bool success){
        bool check= balanceCheck(msg.sender, value);
        require(check == true);
        balanceOf[msg.sender] -= value;
        balanceOf[_to] += value;

        emit Transfer(msg.sender, _to, value);
        return true;
    }

}