//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Verify {
	struct Review {
		address reviewer;
		string[] questions;
		string[] answers;
	}
    
	mapping(address => Review[]) public reviews;

	function review(address recipient, Review memory _review) public {
		reviews[recipient].push(_review);
	}
}