// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____                _ _                      
 |  __ \                   | |              / _| | | | |           / ____|              (_) |                     
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __ _ __ _| |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| '__| | '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | |  | | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|  |_|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

pragma solidity ^0.8.14;

import "./Owned.sol";
import "./IPOTC.sol";
import "./IPapaya.sol";

contract POTCStaking is Owned {

  IPapaya public immutable papayaContract;
  IPOTC public immutable potcContract;

  uint256 private constant normalRate = (10 * 1E18) / uint256(1 days); 
  uint256 private constant legendaryRate = (30 * 1E18) / uint256(1 days); 

  mapping(uint256 => address) public parrotOwner;
  mapping(address => uint256) public parrotOwnerRewards;
  mapping(address => uint256) public _normalBalance;
  mapping(address => uint256) public _legendaryBalance;
  mapping(address => uint256) public _timeLastUpdate;

  constructor(address _parrotContract, address _papayaContract) Owned(msg.sender) {
    potcContract = IPOTC(_parrotContract);
    papayaContract = IPapaya(_papayaContract);
  }

  function outstandingPapaya() external view returns(uint256) {
    return parrotOwnerRewards[msg.sender] + calculatePapaya(msg.sender);
  }

  function calculatePapaya(address ownerAddress) private view returns(uint256) {
    uint256 papayaPayout = (((block.timestamp - _timeLastUpdate[ownerAddress]) * normalRate * _normalBalance[ownerAddress])
      + ((block.timestamp - _timeLastUpdate[ownerAddress]) * legendaryRate * _legendaryBalance[ownerAddress])
    );
    return papayaPayout;
  }

  function isLegendary(uint256 tokenId) private pure returns(bool) {
    if(tokenId >= 14 && tokenId <= 25){
      return true;
    } else {
      return false;
    }
  } 

  modifier updatePapaya(address ownerAddress) {
    uint256 papayaPayout = calculatePapaya(ownerAddress);
    _timeLastUpdate[ownerAddress] = block.timestamp;
    parrotOwnerRewards[ownerAddress] += papayaPayout;
    _;
  }

  function withdrawPapaya() external updatePapaya(msg.sender) returns(uint256) {
    uint256 papayaPayout = parrotOwnerRewards[msg.sender];
    parrotOwnerRewards[msg.sender] = 0;
    papayaContract.stakerMint(msg.sender, papayaPayout);
    return papayaPayout;
  }
  
  function stake(uint256 _tokenId) public updatePapaya(msg.sender) {
    bool isLegend = isLegendary(_tokenId);

    unchecked {
      if(isLegend){
        ++_legendaryBalance[msg.sender];
      } else {
        ++_normalBalance[msg.sender];
      }
    }
    parrotOwner[_tokenId] = msg.sender;
    potcContract.transferFrom(msg.sender, address(this), _tokenId);
  } 

  function stakeMany(uint256[] calldata tokenIds) public updatePapaya(msg.sender) {
    for(uint256 i = 0; i < tokenIds.length; i++){
      stake(tokenIds[i]);
    }
  }

  function unstake(uint256 _tokenId) public updatePapaya(msg.sender) {
    require(parrotOwner[_tokenId] == msg.sender, "You do not own this parrot");
    bool isLegend = isLegendary(_tokenId);

    unchecked {
      if(isLegend){
        --_legendaryBalance[msg.sender];
      } else {
        --_normalBalance[msg.sender];
      }
    }
    delete parrotOwner[_tokenId];
    potcContract.transferFrom(address(this), msg.sender, _tokenId);
  }

  function unstakeMany(uint256[] calldata tokenIds) public updatePapaya(msg.sender) {
    for(uint256 i = 0; i < tokenIds.length; i++) {
      unstake(tokenIds[i]);
    }
  }
}