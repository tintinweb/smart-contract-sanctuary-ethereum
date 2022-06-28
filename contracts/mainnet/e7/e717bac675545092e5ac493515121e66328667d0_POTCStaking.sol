// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____           _ _     _                 
 |  __ \                   | |              / _| | | | |           / ____|         (_) |   | |                 
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __|_| |__ | |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| | '_ \| '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | | |_) | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|_.__/|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

/// @title Parrots of the Caribbean Staking
/// @author jackparrot

pragma solidity ^0.8.14;

import "./Owned.sol";
import "./IPOTC.sol";
import "./IPapaya.sol";

/// @notice Thrown when a user tries to stake without staking being live.
error StakingNotActive(); 
/// @notice Thrown when a user tries to unstake a parrot that doesn't belong to them.
error NotOwner();

contract POTCStaking is Owned {

  /// @notice Contract for $PAPAYA Utility token.
  IPapaya public papayaContract;
  /// @notice Contract for original POTC Collection.
  IPOTC public immutable potcContract;

  /// @notice 10 $PAPAYA per day for normal parrots.
  uint256 private constant normalRate = (10 * 1E18) / uint256(1 days); 
  /// @notice 25 $PAPAYA per day for legendary parrots.
  uint256 private constant legendaryRate = (25 * 1E18) / uint256(1 days); 

  /// @notice Returns owner for a particular ID.
  mapping(uint256 => address) public parrotOwner;
  /// @notice Returns array of IDs for a particular address.
  mapping(address => uint256[]) public stakerToParrot; 
  /// @notice Returns how much $PAPAYA is due to a particular staker.
  mapping(address => uint256) public parrotOwnerRewards;
  /// @notice Returns how many normal parrots a particular staker has staked.
  mapping(address => uint256) public _normalBalance;
  /// @notice Returns how many legendary parrots a particular staker has staked.
  mapping(address => uint256) public _legendaryBalance;
  /// @notice Return last time a particular staker's rewards were updated.
  mapping(address => uint256) public _timeLastUpdate;

  /// @notice Controls whether or not users are able to stake.
  bool public live = false;

  constructor(address _parrotContract, address _papayaContract) Owned(msg.sender) {
    potcContract = IPOTC(_parrotContract);
    papayaContract = IPapaya(_papayaContract);
  }

  /// @notice Returns an array containing all the owner's staked parrots.
  /// @param staker The particular owner whose staked parrots we want to know.
  function getStakedParrots(address staker) external view returns (uint256[] memory) {
    return stakerToParrot[staker];
  }

  /// @notice Returns total outstanding $PAPAYA currently claimable by the staker.
  /// @param staker The particular owner whose claimable $PAPAYA we want to know.
  function outstandingPapaya(address staker) external view returns(uint256) {
    return parrotOwnerRewards[staker] + calculatePapaya(staker);
  }

  /// @notice Calculates the $PAPAYA accrued by a staker since the last time their reward was updated.
  /// @param ownerAddress The particular owner whose $PAPAYA we want to update.
  function calculatePapaya(address ownerAddress) private view returns(uint256) {
    uint256 papayaPayout = (((block.timestamp - _timeLastUpdate[ownerAddress]) * normalRate * _normalBalance[ownerAddress])
      + ((block.timestamp - _timeLastUpdate[ownerAddress]) * legendaryRate * _legendaryBalance[ownerAddress])
    );
    return papayaPayout;
  }

  /// @notice States whether or not a particular ID belongs to a legendary parrot.
  /// @dev Parrots 15-24 are considered legendary and have a different $PAPAYA yield.
  /// @param tokenId The particular parrot we want to test for legendary status.
  function isLegendary(uint256 tokenId) private pure returns(bool) {
    if(tokenId >= 15 && tokenId <= 24){
      return true;
    } else {
      return false;
    }
  } 

  /// @notice Modifier called whenever staking, unstaking, or withdrawing to ensure reward is up to date.
  /// @param ownerAddress The particular owner whose assets we want to update.
  modifier updatePapaya(address ownerAddress) {
    uint256 papayaPayout = calculatePapaya(ownerAddress);
    _timeLastUpdate[ownerAddress] = block.timestamp;
    parrotOwnerRewards[ownerAddress] += papayaPayout;
    _;
  }

  /// @notice Withdraws papaya reward for a particular user.
  /// @dev Staking contract must be added as a verified minter in the $PAPAYA contract, as it mints tokens to the staker's address.
  function withdrawPapaya() external updatePapaya(msg.sender) returns(uint256) {
    uint256 papayaPayout = parrotOwnerRewards[msg.sender];
    parrotOwnerRewards[msg.sender] = 0;
    papayaContract.stakerMint(msg.sender, papayaPayout);

    return papayaPayout;
  }
  
  /// @notice Main staking function.
  /// @dev Normal and legendary balances cannot overflow, hence unchecked.
  /// @dev User must first approve staking contract to spend it's POTC balance in order to stake successfully.
  /// @dev Must keep track of legendary and normal balances separately as they have different yields.
  /// @param _tokenId The particular parrot being staked.
  function stake(uint256 _tokenId) public updatePapaya(msg.sender) {
    if (!live) revert StakingNotActive();

    bool isLegend = isLegendary(_tokenId);

    unchecked {
      if(isLegend){
        ++_legendaryBalance[msg.sender];
      } else {
        ++_normalBalance[msg.sender];
      }
    }
    parrotOwner[_tokenId] = msg.sender;
    stakerToParrot[msg.sender].push(_tokenId);
    potcContract.transferFrom(msg.sender, address(this), _tokenId);
  } 

  /// @notice Stakes many parrots at once.
  /// @param tokenIds Array of all parrots to be staked.
  function stakeMany(uint256[] calldata tokenIds) public updatePapaya(msg.sender) {
    for(uint256 i = 0; i < tokenIds.length; i++){
      stake(tokenIds[i]);
    }
  }

  /// @notice Main unstaking function.
  /// @dev Only the owner of a particular parrot can unstake that parrot.
  /// @param _tokenId The particular parrot being unstaked.
  function unstake(uint256 _tokenId) public updatePapaya(msg.sender) {
    if (parrotOwner[_tokenId] != msg.sender) revert NotOwner();

    bool isLegend = isLegendary(_tokenId);

    unchecked {
      if(isLegend){
        --_legendaryBalance[msg.sender];
      } else {
        --_normalBalance[msg.sender];
      }
    }

    delete parrotOwner[_tokenId];
    removeTokenIdFromArray(stakerToParrot[msg.sender], _tokenId);
    potcContract.transferFrom(address(this), msg.sender, _tokenId);
  }

  /// @notice Unstakes many parrots at once.
  /// @param tokenIds Array of all parrots to be unstaked.
  function unstakeMany(uint256[] calldata tokenIds) public updatePapaya(msg.sender) {
    for(uint256 i = 0; i < tokenIds.length; i++) {
      unstake(tokenIds[i]);
    }
  }

  /// @notice Removes an Id from a particular owner's parrot array.
  /// @dev this must be done when unstaking a parrot
  function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
    uint256 length = array.length;
    for (uint256 i = 0; i < length; i++) {
      if (array[i] == tokenId) {
        length--;
        if (i < length) {
            array[i] = array[length];
        }
        array.pop();
        break;
      }
    }
  }

  /// @notice Sets staking live.
  function toggle() external onlyOwner {
    live = !live;
  }

  /// @notice Sets Papaya contract. 
  function setPapayaContract(address papaya) external onlyOwner {
    papayaContract = IPapaya(papaya);
  } 
}