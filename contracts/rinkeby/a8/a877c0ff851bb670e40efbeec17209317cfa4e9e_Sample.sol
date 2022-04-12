/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

contract Sample {
	uint256 private x;

	constructor(uint256 defaultX) {
		x = defaultX;
	}

	function setValue(uint256 _x) public returns(uint256) {
		x = _x;
		return x;
	}

	function getValue() public view returns(uint256) {
		return x;
	}
}