/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
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
 uint256 public price = 1 ether ;
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
        require(msg.sender != Owner);
       require( IcO == true, " it should be active"); 
       price = msg.value * number_of_token;

       payable(Owner).transfer(price);
       token.transferFrom(Owner,msg.sender,number_of_token);

   }  
}