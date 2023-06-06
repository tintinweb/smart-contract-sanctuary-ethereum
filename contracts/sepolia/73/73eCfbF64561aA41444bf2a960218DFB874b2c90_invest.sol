/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

pragma solidity ^0.4.26;
contract invest{
	string Title = "Crowd-Funding";
	uint public investors;
        string public investName;

	function InvName(string _name) public payable{
		investors++;
		investName = _name; 
	}	

}