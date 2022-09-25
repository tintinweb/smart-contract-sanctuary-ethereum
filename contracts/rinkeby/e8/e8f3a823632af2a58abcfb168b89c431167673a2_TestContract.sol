/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.8.0;

contract TestContract {
	address public target_address;
    address public change_target_address;
    address payable public owner;
	
	constructor(address _challenge) public{
		target_address = 0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf;
		change_target_address = _challenge;
        owner = payable(msg.sender);
	}
	
	function kill() public{
		selfdestruct(owner);
    }
    
	fallback() payable external {}
}