/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

function totalSupply() external view returns(uint256);
function balanceOf(address account)  external view returns(uint256);
function transfer(address recipient, uint256 amount) external returns (bool);

 //event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);   
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract CGCToken is IERC20 {


    string public name ; 
    string public symbol ;  
    uint8 public decimals ; 

    //  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);   
    //  event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances; 
    mapping(address => mapping(address => uint256)) allowed;                      

  // uint256 totalSupply_ = 100 wei; 

    uint256 totalSupply_;

//    constructor(string memory _name,string memory _symbol,uint8 _decimals,uint256 _tsupply) public {
   constructor(string memory _name,string memory _symbol,uint8 _decimals,uint256 _tsupply) {      //public used show the warning
   totalSupply_ = _tsupply;
   balances[msg.sender] = totalSupply_;   
   name = _name;
   symbol= _symbol;
   decimals= _decimals;
}
    function totalSupply() public override view returns(uint256){
        return totalSupply_;
}
    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];  
}
    function transfer(address receiver,uint256 numTokens) public override returns(bool) {
    require (numTokens <= balances[msg.sender]); 
    balances[msg.sender] -= numTokens;                       //dedacted 
    balances[receiver] += numTokens;                        //add reciver tokens
    emit Transfer(msg.sender,receiver,numTokens);    
        return true;
    }

    //total supply incresed add new tokens
    function min(uint256 _qty) public returns(uint256) {
    totalSupply_ += _qty; 
    balances[msg.sender] += _qty;                // jo token add krega uske wallet me add new tokens
   return totalSupply_;
                            
  }
}