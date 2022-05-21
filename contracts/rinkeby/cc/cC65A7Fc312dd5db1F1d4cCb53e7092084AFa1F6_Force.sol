pragma solidity ^0.8.0;

contract Force {
	function byeBye (address payable _to) public{
		selfdestruct(_to);
	}
	receive() external payable {}
}