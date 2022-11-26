// SPDX-License-Identifier: MPL-2

pragma solidity ^0.8;

contract Pension {

	mapping(address => uint) public funds;
	mapping(address => uint) public startWithdrawOf;
	
	uint public immutable valPerWithdraw = 1 wei; // 1e15;
	uint public immutable timeToFirstWithdraw = 1 minutes; //365 days;
	uint public immutable timeToNextWithdraw = 30 seconds; //365 days;

	// will assume that 1 year = 365 days and 1 month = 30 days
	// WARNING from solidity docs: https://docs.soliditylang.org/en/v0.8.12/units-and-global-variables.html#time-units
	// Take care if you perform calendar calculations using these units,
	// because not every year equals 365 days and not even every day has 24 hours because of leap seconds.

	// example
	// deposit 0.001 ether every month, 12 times
	// withdraw 0.001 ether every month, 12 times

	
	function register() external {
		startWithdrawOf[msg.sender] = block.timestamp + timeToFirstWithdraw;
	}
	
	function deposit() payable external {
		require(msg.value == valPerWithdraw);
		funds[msg.sender] += msg.value;
	}
	
	bool private locked;
	modifier protectReentrency{
		require(!locked);
		locked = true;
		_;
		locked = false;		
	}
	
	function withdraw() protectReentrency external {
		require(funds[msg.sender] >= valPerWithdraw, "not enough funds");
		require(block.timestamp >= startWithdrawOf[msg.sender], "wait for the next withdraw period");
		
		funds[msg.sender] -= valPerWithdraw;
		startWithdrawOf[msg.sender] = block.timestamp + timeToNextWithdraw;
		
		address payable addr = payable(msg.sender);
		(bool success, ) = addr.call{value: valPerWithdraw}("");
		require(success);
	}

	function getFunds() external view returns (uint){
		return funds[msg.sender];
	}
	
	function timeToWithdraw() external view returns (uint) {
		int t = int(startWithdrawOf[msg.sender]) - int(block.timestamp);
		return t > 0 ? uint(t) : 0;
	}
}