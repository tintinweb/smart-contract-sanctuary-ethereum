/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Call {
	struct CallParams {
		address dst_address;
		bytes params;
		uint dst_chain;
	}

	event CallEvent(CallParams params);

	function call(CallParams memory params) public {
		emit CallEvent(params);
	}
}