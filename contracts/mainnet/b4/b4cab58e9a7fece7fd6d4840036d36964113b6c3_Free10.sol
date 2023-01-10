/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$    /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$   /$$$_  $$
| $$      | $$  \ $$| $$      | $$            |_  $$  | $$$$\ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$  | $$ $$ $$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$  | $$\ $$$$
| $$      | $$  \ $$| $$      | $$              | $$  | $$ \ $$$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$$$$$|  $$$$$$/
|__/      |__/  |__/|________/|________/      |______/ \______/



 /$$
| $$
| $$$$$$$  /$$   /$$
| $$__  $$| $$  | $$
| $$  \ $$| $$  | $$
| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$$
|_______/  \____  $$
           /$$  | $$
          |  $$$$$$/
           \______/
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


CC0 2022
*/


pragma solidity ^0.8.17;


interface IFree {
  function mint(uint256 collectionId, address to) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
  function tokenIdToCollectionId(uint256 tokenId) external returns (uint256 collectionId);
  function appendAttributeToToken(uint256 tokenId, string memory attrKey, string memory attrValue) external;
}

interface I10EthGiveaway {
  function exists() external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface ITenETHChallenge {
  function challenge(address sender, uint256 free0TokenId) external returns (bool);
}


contract Free10 {
  IFree public immutable free;
  I10EthGiveaway public immutable tenEthGiveaway;

  address public easyChallengeAddress;
  address public impossibleChallengeAddress;
  address public selectedChallengeAddress;


  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address tenETHAddr) {
    free = IFree(freeAddr);
    tenEthGiveaway = I10EthGiveaway(tenETHAddr);

    easyChallengeAddress = address(new EasyTenETHChallenge());
    impossibleChallengeAddress = address(new ImpossibleTenETHChallenge());
  }

  function setTenEthChallenge(address addr) external {
    require(msg.sender == tenEthGiveaway.ownerOf(0), 'Only the 10 ETH Giveaway token owner can set the challenge');
    selectedChallengeAddress = addr;
  }

  function claim(uint256 free0TokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free10');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(tenEthGiveaway.exists(), '10 ETH Giveaway token has been redeemed');
    require(ITenETHChallenge(selectedChallengeAddress).challenge(msg.sender, free0TokenId), '10 ETH Giveaway challenge has not been met');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free10 Mint', 'true');
    free.mint(10, msg.sender);
  }
}


contract EasyTenETHChallenge {
  function challenge(address sender, uint256 free0TokenId) external pure returns (bool) {
    return true;
  }
}

contract ImpossibleTenETHChallenge {
  function challenge(address sender, uint256 free0TokenId) external pure returns (bool) {
    return false;
  }
}