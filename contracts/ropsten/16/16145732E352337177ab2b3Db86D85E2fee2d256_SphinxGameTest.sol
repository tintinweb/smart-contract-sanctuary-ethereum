/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract SphinxGameTest {

  string private solution1;
  string private solution2;
  string private solution3;
  uint private price = 10000000000000000;

  //initialize hash + price
  constructor(string memory _solution1, string memory _solution2, string memory _solution3) {
      solution1 = _solution1;
      solution2 = _solution2;
      solution3 = _solution3;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function publicSaleMint(string memory answer1, string memory answer2, string memory answer3) external payable callerIsUser returns (string memory)
  {
    // require(
    //   msg.value >= price,
    //   "entry cost too low"
    // );

    if (compareStrings(answer1, solution1)) {
        return "solution1 correct";
    }

    if (compareStrings(answer2, solution2)) {
        return "solution2 correct";
    }

    if (compareStrings(answer3, solution3)) {
        return "solution3 correct";
    }

    return "none right";
  }

  function compareStrings (string memory a, string memory b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}