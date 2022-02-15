// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./ownable.sol";
import "./IERC20.sol";
//import "./IERC777.sol";
//import "IERC1820Registry.sol";
//import "./IERC777Recipient.sol";
//import "./IERC777Sender.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
	function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
}

//----------------------------------------------------------------------------------

contract CoinBank is Ownable  {
	using SafeMath for uint256;

	address coin;
	uint256 priceForMCoins;

	constructor (address coin_address) public {
        coin = coin_address;
		owner = msg.sender;
   }
	
	function buy1000000x(uint256 amount) public payable{
		require(IERC20(coin).balanceOf(address(this)) >= SafeMath.mul(amount,1000000));
		require(msg.value >= SafeMath.mul(amount, priceForMCoins));
		require(priceForMCoins > 0);
		IERC20(coin).transfer(msg.sender, SafeMath.mul(amount,1000000));
	}
	
	function mCoinPrice() public view returns (uint256 price){
		return priceForMCoins;
	}
	
	function payout() public {
		require(msg.sender == owner);
		owner.transfer(address(this).balance);
	}
	
	function reclaimCoins() public {
		require(msg.sender == owner);
		IERC20(coin).transfer(msg.sender, totalSupply());
	}
	
	function setPriceFor1M(uint256 _price) public {
		require(owner == msg.sender);
		priceForMCoins = _price;
	}
	
	function totalSupply() public view returns (uint256 _supply){
		return IERC20(coin).balanceOf(address(this));
	}
}