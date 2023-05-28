/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity ^0.4.26;

contract invest{
	string Title = "Crowd-Funding";
	uint public investors;
    int256 public investAmount;

	function pay(int256 _money) public payable{
		investors++;
		investAmount = investAmount + _money; 
	}	

	function currentAmount() public view returns(uint, int256){
		return(investors, investAmount);
	}
}