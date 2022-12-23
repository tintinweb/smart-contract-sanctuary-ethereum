// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBunnyKittyToken } from "./IBunnyKittyToken.sol";

contract BunnyKittyMint {

    uint16 public constant maxSupply = 1111;
    uint256 public constant cost = 0.001 ether;
    
    address owner;
    address tokenContract;
    uint256 startTime;

    constructor(address _tokenContract) {
      owner = msg.sender;
      tokenContract = _tokenContract;
      startTime = block.timestamp;
    }

    function mint(uint256 _amount, address _recipient) external payable {
      require(msg.value >= cost * _amount, "Ether value sent is below the price");
      require(block.timestamp >= startTime, "Mint is not available");
      require(tx.origin == msg.sender, "Contracts are unable to mint");
      require(IBunnyKittyToken(tokenContract).totalSupply() + _amount <= maxSupply, "Sold out");

      (bool success, ) = payable(owner).call{value: msg.value}("");
      require(success, "Failed to send Ether");

      IBunnyKittyToken(tokenContract).mint(_amount, _recipient);
    }

    function getPrice() external pure returns(uint256) {
      return cost;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBunnyKittyToken {

    function mint(uint256 _amount, address _recipient) external;

    function setMintContract(address _mintContract) external;

    function totalSupply() external view returns (uint256); 

}