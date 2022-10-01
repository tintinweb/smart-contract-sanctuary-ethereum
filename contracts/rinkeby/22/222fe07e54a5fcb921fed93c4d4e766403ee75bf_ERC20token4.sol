/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


contract ERC20token4{

    string public token4Name; 
    string public token4Symbol; 
    uint256 public token4TotalSupply;
    uint256 public  token4decimals; 
    address internal owner;

    mapping(address => uint256) balances;
    mapping(address => bool) minters;

    constructor(){
        token4Name = "Token4";
        token4Symbol = "TK4";
        token4decimals = 18;
        token4TotalSupply = token4TotalSupply*(10**uint256(token4decimals));
        minters[msg.sender]= true;
        owner = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this method");
        _;
    }


    function balanceof(address tokenOwner)  public view returns(uint256) { 
        return balances[tokenOwner];
        }

    function mint(address to, uint _tokens) public onlyOwner returns(bool) {
        token4TotalSupply += _tokens;
        balances[to] += _tokens;
        return true;
    }

    function transfer(address to, uint token)  public  returns(bool){
        require(balances[msg.sender] >= token, "you should have some token");
        balances[msg.sender] -= token;
        balances[to] += token;
        return true;
    }

    function burn(uint _tokens) public onlyOwner returns(bool) {
     token4TotalSupply -= _tokens;
     balances[msg.sender] -= _tokens;
     return true;
    }
}