/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract MyFirstStringContract {
    string rockText;

    function engrave(string calldata _rockText) public {
        rockText = _rockText;
    }

    function regain() public view returns(string memory) {
        return rockText;
    }

}