// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Puzzle0 {

    bytes32 constant ANSWERHASH = 0x922f80dc50d3e8ac04d531874d1e6999301f7b5a8fda0675481eaed3984b12b1;

    constructor() payable {}

    function claim(string calldata answer) external {
        require(keccak256(abi.encode(answer)) == ANSWERHASH, "Wrong answer");
        payable(msg.sender).transfer(0.1 ether);
    }
}