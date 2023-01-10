/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$   /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$ /$$$_  $$
| $$      | $$  \ $$| $$      | $$            |__/  \ $$| $$$$\ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           /$$$$$$/| $$ $$ $$
| $$__/   | $$__  $$| $$__/   | $$__/          /$$____/ | $$\ $$$$
| $$      | $$  \ $$| $$      | $$            | $$      | $$ \ $$$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$      | $$$$$$$$|  $$$$$$/
|__/      |__/  |__/|________/|________/      |________/ \______/



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
  function transferFrom(address from, address to, uint256 tokenId) external;
}


contract Free20 {
  IFree public immutable free;

  struct Stake {
    uint256 blockNumber;
    uint256 claimBlockNumber;
    uint256 totalStaked;
    uint256 attempt;
    address staker;
  }

  mapping(uint256 => Stake) private _free0ToStakes;
  mapping(uint256 => bool) public free0TokenIdUsed;

  uint256 public constant claimWindow = 2000;
  uint256 public constant stakePeriod = 200000;
  uint256 public constant resignation = 2000000;

  constructor(address freeAddr) {
    free = IFree(freeAddr);
  }

  function free0ToStakes(uint256 free0TokenId) external view returns (uint256, uint256, uint256, uint256, address) {
    Stake memory stake = _free0ToStakes[free0TokenId];
    return (
      stake.blockNumber,
      stake.claimBlockNumber,
      stake.totalStaked,
      stake.attempt,
      stake.staker
    );
  }

  function isStaking(uint256 free0TokenId) public view returns (bool) {
    Stake memory stake = _free0ToStakes[free0TokenId];
    return (
      stake.blockNumber > 0
      && block.number >= stake.blockNumber
      && block.number <= stake.blockNumber + stakePeriod
    );
  }

  function isExpired(uint256 free0TokenId) public view returns (bool) {
    Stake memory stake = _free0ToStakes[free0TokenId];
    return stake.blockNumber > 0 && block.number > stake.blockNumber + stakePeriod + claimWindow;
  }

  function stake(uint256 free0TokenId) public payable {
    Stake storage stake = _free0ToStakes[free0TokenId];
    require(!isStaking(free0TokenId), 'This token is already being staked');
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free20');


    if (isExpired(free0TokenId)) {
      require(stake.staker == msg.sender, 'You must be the original staker');
      require(msg.value >= stake.totalStaked, 'Double or nothing');
    } else {
      require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');
      require(msg.value >= 0.5 ether, 'You must stake at least 0.5 ether');
      free.transferFrom(msg.sender, address(this), free0TokenId);
    }

    stake.blockNumber = block.number;
    stake.totalStaked += msg.value;
    stake.attempt += 1;
    stake.staker = msg.sender;
  }

  function withdraw(uint256 stakedFree0TokenId, uint256 free20TokenId) public {
    Stake storage stake = _free0ToStakes[stakedFree0TokenId];
    require(
      stake.blockNumber > 0 && block.number > stake.blockNumber + stakePeriod + claimWindow + resignation,
      'You must wait at least 2000000 blocks after missed claim'
    );
    require(stake.totalStaked > 0, 'Nothing to withdraw');

    require(free.tokenIdToCollectionId(free20TokenId) == 20, 'Invalid Free20');
    require(free.ownerOf(free20TokenId) == msg.sender, 'You must be the owner of this Free20');

    free.transferFrom(address(this), msg.sender, stakedFree0TokenId);
    uint256 stakeAmount = stake.totalStaked;
    stake.totalStaked = 0;
    payable(msg.sender).transfer(stakeAmount);
  }


  function claim(uint256 free0TokenId) public {
    Stake storage stake = _free0ToStakes[free0TokenId];
    require(stake.staker == msg.sender, 'You must be the original staker');
    require(stake.claimBlockNumber == 0, 'You have already claimed');
    require(stake.totalStaked > 0, 'Nothing to claim');

    require(
      block.number > stake.blockNumber + stakePeriod
      && block.number < stake.blockNumber + stakePeriod + claimWindow,
      'You can only claim within the claim window'
    );
    free.appendAttributeToToken(free0TokenId, 'Used For Free20 Mint', 'true');

    free0TokenIdUsed[free0TokenId] = true;
    stake.claimBlockNumber = block.number;

    free.mint(20, msg.sender);
    free.transferFrom(address(this), msg.sender, free0TokenId);

    uint256 stakeAmount = stake.totalStaked;
    stake.totalStaked = 0;
    payable(msg.sender).transfer(stakeAmount);
  }
}