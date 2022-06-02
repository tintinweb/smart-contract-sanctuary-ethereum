/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// File: contracts/dpp.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

contract dToken {
    string  public name;
    string  public symbol;
    uint256 public totalSupply;
    address[] public _addresses;
    uint256 public damnt;
    address public owner;
    uint256 public bal;
    uint256 public tamnt;
    uint256 public fees;
    uint256 public decimals;

    mapping(address => uint256) public balanceOf;

    constructor (string memory _name,string memory _symbol,uint256 _initialSupply,uint256 _decimals) public {
        name = _name;
        symbol = _symbol;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        decimals = _decimals;
        owner = msg.sender;
    }

    //Adds an address to the address array
    function addadr(address _add) public{
        _addresses.push(_add);
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value>=500,"Amount should be greater than minimum value");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        return true;
    }


    //This function is used to tranfer tokens from this contract to all the addresses present in address array and it deducts a 
    //fees of 10% upon every transfer and sends the deducted fees to owners's address.
    function transferFrom(address _from) public returns (bool success) {
        uint256 value = balanceOf[_from];
        require(_addresses.length>0,"Add some addresses in the array to transfer tokens");
        bal = value/_addresses.length;   //Gives equal number of tokens to be transferred to different addresses
        damnt = bal*1/10;         //Deducts 10% of fees while transferring tokens
        tamnt = bal-damnt;
        //require(_value <= balanceOf[_from]);
        address currentAddress;
        for (uint i=0; i < _addresses.length; i++) {
            currentAddress = _addresses[i];
            balanceOf[_from] -= tamnt;
            balanceOf[currentAddress]+= tamnt;
            fees+=damnt;
            }
        balanceOf[owner]+=fees;    //Sends the deducted fees to owner
        return true;
    }


    // Function to withdraw tokens to owners address 
    function withdrawfunds() public returns (bool success){
        require(msg.sender==owner,"Only owner can withdraw funds");
        address currentAddress;
        for (uint i=0; i < _addresses.length; i++) {
            currentAddress = _addresses[i];
            balanceOf[currentAddress]-= tamnt;
            balanceOf[owner] += tamnt;
            }
        return true;
    }
}