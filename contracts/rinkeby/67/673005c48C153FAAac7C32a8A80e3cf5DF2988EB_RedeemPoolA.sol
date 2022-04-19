pragma solidity ^0.5.0;

import "./AToken.sol";

contract RedeemPoolA {
	string public name = "Redeem Pool A";
	AToken public atoken;
	address public owner;

	constructor(AToken _atoken) public {
		atoken = _atoken;
		// set deployer as owner of the contract
		owner = msg.sender;
	}

	function redeem (uint _amountA) public {

		//investors cannot stake more atoken than they have
		require(atoken.balanceOf(msg.sender) >= _amountA);

		//erc20 token: 1 ether == 10^18 wei
		uint unit = 10**18;

		//calculate how much A token to transfer to redeem pool 
		uint amountATokenInEther = _amountA / unit;

		atoken.transferFrom(msg.sender, address(this), amountATokenInEther*unit);
	}

}