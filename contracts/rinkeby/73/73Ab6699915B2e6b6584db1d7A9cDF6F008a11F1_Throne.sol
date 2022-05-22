pragma solidity ^0.8.0;

contract Throne{
	
	function sendEther (address payable _addr) payable public{
	
		_addr.call{value: msg.value}("");

	}

	receive() external payable {
		uint i;
		uint iter;
		for(i = 0; i<9999999999; i++){
			iter++;
		}
	}
}