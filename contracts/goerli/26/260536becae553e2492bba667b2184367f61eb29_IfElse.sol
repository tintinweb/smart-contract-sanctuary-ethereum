/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

pragma solidity ^0.8.13;

contract IfElse {
	uint public x;
    function setx(uint _x) public {
        uint i;
        if (_x > 10) {
            revert();
        } else {
            for (i=0;i<=_x;i++)
			    x = i;
        }
    }

    function getsum() public view returns (uint) {
		uint s;
		uint i;
		for (i=1;i<=x;i++)
			s += i;
		return s;
    }
}