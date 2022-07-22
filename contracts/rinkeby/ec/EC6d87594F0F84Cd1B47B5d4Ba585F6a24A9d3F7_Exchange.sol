/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Exchange
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Exchange {

	address owner;
	uint256 public minExchange1To2amt = 1000000000000000;
	uint256 public exchange1To2rate = 20;
	uint256 public minExchange2To1amt = 1000000000000000000;
	uint256 public exchange2To1rate = 5;
	event Exchanged (address tgt);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	//This function allows the owner to change the value of minExchange1To2amt.
	function changeValueOf_minExchange1To2amt (uint256 _minExchange1To2amt) external onlyOwner {
		 minExchange1To2amt = _minExchange1To2amt;
	}

	//This function allows the owner to change the value of exchange1To2rate.
	function changeValueOf_exchange1To2rate (uint256 _exchange1To2rate) external onlyOwner {
		 exchange1To2rate = _exchange1To2rate;
	}

	//This function allows the owner to change the value of minExchange2To1amt.
	function changeValueOf_minExchange2To1amt (uint256 _minExchange2To1amt) external onlyOwner {
		 minExchange2To1amt = _minExchange2To1amt;
	}

	//This function allows the owner to change the value of exchange2To1rate.
	function changeValueOf_exchange2To1rate (uint256 _exchange2To1rate) external onlyOwner {
		 exchange2To1rate = _exchange2To1rate;
	}

/**
 * Function exchange1To2
 * Minimum Exchange Amount : Variable minExchange1To2amt
 * Exchange Rate : Variable exchange1To2rate
 * The function takes in 1 variable, zero or a positive integer v0. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that v0 is greater than or equals to minExchange1To2amt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (v0) * (exchange1To2rate)
*/
	function exchange1To2(uint256 v0) public {
		require((v0 >= minExchange1To2amt), "Too little exchanged");
		ERC20(0x43995D5A8221841AD6c1F28C1ea8cA802214a318).transfer(msg.sender, (v0 * exchange1To2rate));
	}

/**
 * Function exchange2To1
 * Minimum Exchange Amount : Variable minExchange2To1amt
 * Exchange Rate : Variable exchange2To1rate
 * The function takes in 1 variable, zero or a positive integer v0. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that v0 is greater than or equals to minExchange2To1amt
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as v0
 * transfers ((v0) * (exchange2To1rate)) / (100) of the native currency to the address that called this function
*/
	function exchange2To1(uint256 v0) public {
		require((v0 >= minExchange2To1amt), "Too little exchanged");
		ERC20(0x43995D5A8221841AD6c1F28C1ea8cA802214a318).transferFrom(msg.sender, address(this), v0);
		payable(msg.sender).transfer(((v0 * exchange2To1rate) / 100));
	}

/**
 * Function withdrawToken1
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers _amt of the native currency to the address that called this function
 * emits event Exchanged with inputs the address that called this function
*/
	function withdrawToken1(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
		emit Exchanged(msg.sender);
	}

/**
 * Function withdrawToken2
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
 * emits event Exchanged with inputs the address that called this function
*/
	function withdrawToken2(uint256 _amt) public onlyOwner {
		ERC20(0x43995D5A8221841AD6c1F28C1ea8cA802214a318).transfer(msg.sender, _amt);
		emit Exchanged(msg.sender);
	}

	function sendMeNativeCurrency() external payable {
	}
}