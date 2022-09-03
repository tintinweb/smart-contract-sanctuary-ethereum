//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract ICO_token
{ 
address payable public Owner;
 IERC20  token ;
 uint256 public initial_supply;
 uint256 public price = 100000000000000000 ;
 address[]investors;
 uint256 public token_amount_per_user =1 ;
bool public IcO = false ;
 modifier onlyowner
 {
      require (msg.sender == Owner);
      _;
 }
 struct investor
 {
     address user;
     IERC20  _token;
     uint256 totalTokent_invest;

 }
   constructor( IERC20  token_ ,uint256 initial_supply_)
 { 
  token = token_;
  initial_supply =initial_supply_;
  Owner = payable(msg.sender);
  token.transferFrom(msg.sender, address(this),initial_supply );
      IcO  =true;
}

   function buyToken(uint256 number_of_token)payable external
   {
     require (msg.value >= price);
       price = msg.value * number_of_token;
       require(msg.sender != Owner);
       require( IcO == true, " it should be active"); 
       payable(Owner).transfer(price);
       token.transferFrom(Owner,msg.sender,number_of_token);

   }  
}