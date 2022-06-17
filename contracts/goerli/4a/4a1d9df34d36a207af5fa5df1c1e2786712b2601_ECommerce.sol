// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";

contract ECommerce {
    IERC20 token;
    address private owner;

    constructor() {
        token = IERC20(0x4dEF22ECEbF369840d5c8f10963Ebdc111435536);
        // this token address is LINK token deployed on Rinkeby testnet
       // You can use any other ERC20 token smart contarct address here
        owner = msg.sender;
    }

     modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

     function GetUserTokenBalance() public view returns(uint256){ 
       return token.balanceOf(msg.sender);// balanceOf function is already declared in ERC20 token function
   }

    function Approvetokens(uint256 _tokenamount) public returns(bool){
       token.approve(address(this), _tokenamount);
       return true;
   }

   function GetAllowance() public view returns(uint256){
       return token.allowance(msg.sender, address(this));
   }

   function AcceptPayment(uint256 _tokenamount) public returns(bool) {
       require(_tokenamount > GetAllowance(), "Please approve tokens before transferring");
       token.transfer(address(this), _tokenamount);
       return true;
   }

    function GetContractTokenBalance() public OnlyOwner view returns(uint256){
       return token.balanceOf(address(this));
   }
}