// SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.13;
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Challenge 1
/// @author Byont Labs
/// @notice These comments are written in NatSpec format. This is not mandatory, but nice to have. For more info, visit https://docs.soliditylang.org/en/v0.8.17/natspec-format.html
/// @dev Simple hello world contract that shows the message "Hello World!"
contract Challenge1 {
  string message = "Hello World!";

  constructor(string memory _name) {}

  /// @return message:string; the message stored in the contract.
  function getMessage() public view returns (string memory) {
    return message;
  }
}