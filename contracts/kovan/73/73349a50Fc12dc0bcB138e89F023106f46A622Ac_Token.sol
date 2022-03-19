/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.6;

contract Token {

    string public name ;
    string public symbol;
    uint256 public decimal; 
    uint256 public totalSupply;



    mapping(address => uint256) public balanceOf; //tells how much tokens each person has
    mapping(address => mapping(address => uint256)) public allowance; //keeps track of your acct w/ fist map and 2nd map keeps track of the spending on behalf of your account

    event Transfer(address indexed from, address indexed to, uint256 value); // we are logging the transfer to the blockchain
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name, string memory _symbol, uint256 _decimal, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply ;//the person calling the contract will get the total supply since its there token
    }

    function transfer(address _to, uint _value) external payable returns (bool success) {
        require(balanceOf[msg.sender] >= _value); // make sure person transferring has enough in there account for transaction
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value); // log to blockchain
        return true; //the ERC20 standard: must return bool success == return true in transfer fnc
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function approve( address _spender, uint256 _value) external returns (bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external payable{
        require(_value <= balanceOf[_from]);
        require(_value <=  allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
    }





}