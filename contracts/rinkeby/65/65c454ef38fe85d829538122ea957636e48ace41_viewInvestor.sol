/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.4.26;

contract viewInvestor{
	string public Title = "Crowd-Funding";
	string public investorName;
	uint public investors = 0;

	function writeName (string _Name) public payable{
		investorName = _Name;
		investors++;
	}	

	function viewName() public view returns(string){
		return investorName;
	}
}