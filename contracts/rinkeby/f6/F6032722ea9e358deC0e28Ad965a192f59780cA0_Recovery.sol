/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Recovery {
    bytes32 public hashedPassword;
    mapping(bytes32 => uint256) public lockHashes;
    address public owner;

    constructor(bytes32 _hashedPassword) {
        hashedPassword = _hashedPassword;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // modifier inactive {
    //   // proof of inactivity
    // }

    function verifyPassword(string memory password) public view returns (bool) {
        return keccak256(abi.encodePacked(password)) == hashedPassword;
    }

    function verifyLockHash(string memory password) public view returns (bool) {
      if (lockHashes[keccak256(abi.encodePacked(password, msg.sender))] != 0) {
        return true;
      }
      return false;
    }

    function commitLockHash(bytes32 _lockHash) public {
      lockHashes[_lockHash] = block.timestamp;
    }

    function claimOwnership(string memory password) public {
      require(verifyPassword(password), "password is incorrect");
      require(verifyLockHash(password), "address has not been previously committed");
      require(block.timestamp > lockHashes[keccak256(abi.encodePacked(password, msg.sender))], "ownership claiming cannot be on the same block as locking address");
      owner = msg.sender;
    }

    function retrieveERC20() public onlyOwner {
        // return greeting;
    }

    // function retrieveERC721() public onlyOwner {
    //     return greeting;
    // }
}