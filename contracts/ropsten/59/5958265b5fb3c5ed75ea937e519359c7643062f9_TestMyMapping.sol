/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity 0.5.3;

contract TestMyMapping {
	mapping (address => uint) mappingOff;

	event MappingSet(address from, uint myNumber);

	function setMyMapping (uint myNumber) public {

		mappingOff[msg.sender] = myNumber;

		emit MappingSet(msg.sender, myNumber);
	}
}