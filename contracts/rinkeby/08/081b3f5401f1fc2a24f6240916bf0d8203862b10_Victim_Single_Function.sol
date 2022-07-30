/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity ^0.5.10;
contract Victim_Single_Function{
	mapping (address=>uint256) public userbalances;
	
	function withdraw() public returns(bool){
		uint amountToWithdraw = userbalances[msg.sender];
		msg.sender.call.value(amountToWithdraw);
		userbalances[msg.sender] = 0;
		return true;	
	}
	function updateUserBalance(address _attacker,uint256 _bal) public returns(bool){
		userbalances[_attacker] = _bal;
	}
	function () external payable{
	    
	}
}