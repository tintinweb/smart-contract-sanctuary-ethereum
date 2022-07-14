/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

//SPDX-License-Identifier: MIT
//Day 3 and I Own the JEFI Token HAHA.
// JEFI Token (J5) is a ERC-20 Token on Ropsten testnet created by Jay0x5

pragma solidity ^0.8.7;
contract Token {

    string public name;
    string public symbol;
    uint256 public decimals; 
    
    // Total supply storage variable
    uint256 public totalSupply;   
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name, string memory _symbol, uint _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 1000000000000000000000000;
        balanceOf[msg.sender] = totalSupply; 
    }

    //dummy transac function to check all the requirements and then call the main transaction function
    function transfer(address _to, uint _value) external returns (bool){

        require(balanceOf[msg.sender] >= _value, "Insufficient funds to send ://"); //check my funds
        require(_to != address(0), "Invalid address"); //check receiver address
        _transfer(msg.sender,_to,_value); //call real transaction function
        return true; //return true
    }

    function _transfer(address owner, address receiver, uint amount) internal{
        balanceOf[owner] = balanceOf[owner] - amount; //deduct the amount from my(owner) balanceOf
        balanceOf[receiver] = balanceOf[receiver] + amount; //add the amount to the receiver balanceOf
        emit Transfer(owner,receiver,amount); //emit the Transfer Event
    }

    //Approve some tokens to the dapp's address [ex=> Uniswap]
    function approve(address _spender, uint _value) external returns(bool){
        require(_spender != address(0), "Invalid Address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    //Allow the actual transfer for dapps
    //_from is basically dapp's address
    function transferFrom(address _from, address _to, uint amount) external returns(bool){
        require(balanceOf[_from] >= amount); //check if dapp got enough juice
        require(allowance[_from][msg.sender] >= amount); //check if that much token spending is allowed
        allowance[_from][msg.sender] =allowance[_from][msg.sender] - amount; //deduct the dapp's balanceOf
       _transfer(_from,_to,amount); //call the real transaction ;)
        return true;
    }



  
}