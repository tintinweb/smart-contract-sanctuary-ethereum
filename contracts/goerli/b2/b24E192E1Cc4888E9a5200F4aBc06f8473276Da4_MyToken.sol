/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns(uint);
    function balanceOf(address $user) external view returns(uint);
    function transfer(address $receiver , uint $amount) external returns(bool);
    function transferFrom(address $from , address $to , uint $amount) external returns(bool);
    function approve(address $spender , uint $amount) external returns(bool);
    function allowance(address $owner , address $spender) external view returns(uint);

    event Transfer(address indexed $from , address indexed $to , uint $amount);
    event Approval(address indexed $owner , address indexed $spender , uint $amount);

}

contract MyToken is IERC20
{
    string $name;
    string $symbol;
    uint $decimal;
    uint $_totalSupply;

    mapping (address => uint) Balances;
    mapping (address => mapping(address => uint)) Allowed;


    constructor()
    {
        $name = "MyToken";
        $symbol = "MYT";
        $decimal = 10;
        $_totalSupply = 100000000000000;
        Balances[msg.sender] = $_totalSupply;
    }

    function totalSupply() external override view returns (uint)
    {
        return $_totalSupply;
    }

    function balanceOf(address $user) external override view returns(uint)
    {
        return Balances[$user];
    }

    function transfer(address $receiver, uint $amount) external override returns (bool)
    {
        require(Balances[msg.sender] <= $amount);
        Balances[msg.sender] -= $amount;
        Balances[$receiver] += $amount;
        emit Transfer(msg.sender, $receiver, $amount);
        return true; 
    }

    function approve(address $spender , uint $amount) external override returns(bool) {
        Allowed[msg.sender][$spender] = $amount;
        emit Approval(msg.sender , $spender , $amount);
        return true;
    }

    function allowance(address $owner , address $delegate) external override view returns(uint)
    {
        return Allowed[$owner][$delegate];
    }

    function transferFrom(address $from , address $to , uint $amount) external override returns(bool)
    {
        require(Balances[$from] <= $amount);
        require(Allowed[$from][msg.sender] <= $amount);

        Balances[$from] -= $amount;
        Balances[$to] += $amount;
        Allowed[$from][msg.sender] -= $amount;
        
        emit Transfer($from , $to , $amount);
        return true;
    }

}