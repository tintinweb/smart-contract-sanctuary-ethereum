/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20{
    function totalsupply() external view returns(uint);

    function balance(address account) external view returns (uint);

    function transfer(address recipient,uint amount)external returns(bool);

    function allowance(address owner,address spender)external view returns(uint);

    function approve(address spender,uint amount) external returns (bool);

    function transferfrom(address sender,address recipient,uint amount)external returns(bool);

    event transferof(address indexed from,address indexed to,uint amount);

    event approval(address indexed owner,address indexed spender,uint amount);

}
contract ERC20 is IERC20{
    uint public totalsupply;
    mapping(address => uint)public balance;
    mapping(address => mapping(address=>uint))public allowance;
    string public name="dappa";
    string public symbol= "dAPPS";
    uint public decimals=18;


    function transfer(address recipient,uint amount)external returns (bool){
        balance[msg.sender]-=amount;
        balance[recipient]+=amount;
        emit transferof(msg.sender,recipient,amount);
        return true;

    }
    function approve(address spender,uint amount)external returns(bool){
        allowance[msg.sender][spender]=amount;
        emit approval(msg.sender,spender,amount);
        return true;
    }
    function transferfrom(address sender,address recipient,uint amount)external returns(bool){
        allowance[sender][msg.sender] -= amount;
        balance[sender]-=amount;
        balance[recipient]+=amount;
        emit transferof(sender,recipient,amount);
        return true;

    }
    function mint(uint amount) external{
        balance[msg.sender] +=amount;
        totalsupply += amount;
        emit transferof(address(0),msg.sender,amount);
    }
}