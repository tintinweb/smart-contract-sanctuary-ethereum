/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
contract MyContract {
    string value;
		constructor() {
            value = "myValue";
		}

		function set(string calldata _value) private {
          value = _value;
		}

		function get() public view returns(string memory) {
           return value;
		}
}