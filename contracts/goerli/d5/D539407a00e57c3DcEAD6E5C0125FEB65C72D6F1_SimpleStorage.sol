// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
	int256 public intVaule;

	// in order for a function to be orderridable
	// it needs to be specified as virtual
	function setIntValue(int256 _intValue) public virtual {
		intVaule = _intValue;
	}
}