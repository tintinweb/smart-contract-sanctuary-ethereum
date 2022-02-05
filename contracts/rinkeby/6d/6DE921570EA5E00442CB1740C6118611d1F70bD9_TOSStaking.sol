// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: tos_nft                 *
 * @team:   TheOtherSide                *
 ****************************************
 *   TOS Staking business logic   *
 ****************************************/

import './ITOSStake.sol';
import './ITokenTrasfer.sol';

contract TOSStaking is ITOSStake {

    /**
     *    @notice Keep track of each user and their info
     */
    struct Staker {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256) timeStaked;
        uint256 amountStaked;
    }

    ITokenTransfer private _parentToken;
    
    // @notice mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // Mapping from token ID to owner address
    mapping(address => mapping(uint256 => address)) public tokenOwners;
    
    /**
    * @dev Stake the NFT based tokenId
    */
    function stake( address _sender, uint tokenId ) external override {
        _stake(_sender,tokenId);
    }

    /**
    * @dev Unstake the NFT based tokenId
    */
    function unStake( address _sender,  uint _tokenId ) external override {
        require(tokenOwners[_sender][_tokenId] == msg.sender,
            "Moon: Not exist tokenId"
        );

        _unstake(_sender, _tokenId);       
    }

    /**
    * @dev For internal access to stake the NFT based tokenId
    */
    function _stake( address _user, uint256 _tokenId ) internal {

        Staker storage staker = stakers[_user];

        staker.amountStaked += 1;
        staker.timeStaked[_user] = block.timestamp;
        staker.stakedTokens[_user].push(_tokenId);

        tokenOwners[_user][_tokenId] = msg.sender;

        _parentToken.transferToken(ITokenTransfer.StakeState.Stake,_user,_tokenId);
    }

  /**
    * @dev For internal access to unstake the NFT based tokenId
    */
    function _unstake( address _user, uint256 _tokenId) internal {

        Staker storage staker = stakers[_user];

        //staker.stakedTokens[_user].removeElement(_tokenId);
        removeElement(_user,_tokenId);

        delete tokenOwners[_user][_tokenId];
        staker.timeStaked[_user] = block.timestamp;
        staker.amountStaked -= 1;

        if(staker.amountStaked == 0) {
            delete stakers[_user];
        }

        _parentToken.transferToken(ITokenTransfer.StakeState.UnStake,_user,_tokenId);
        
    }

  /**
    * @dev Register a call back function to receive token transfer
    */
    function regTokenTransfer(address _to) external override {
        _parentToken = ITokenTransfer(_to);
    }

  /**
    * @dev Returns the array of TokenIds based on the staked address.
    */
    function getStakedTokens(address _user) external view override returns (uint256[] memory tokenIds) {
        Staker storage staker = stakers[_user];
        return staker.stakedTokens[_user]; 
    }

    /**
    *   @notice remove given elements from array
    *   @dev usable only if _array contains unique elements only
     */
    function removeElement(address _user, uint256 _element) public {
        Staker storage staker = stakers[_user];
        uint256[] storage _array = staker.stakedTokens[_user];
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: tos_nft                 *
 * @team:   TheOtherSide                *
 ****************************************
 *   Interface for transfering token    *
 ****************************************/

interface ITokenTransfer {

    /**
    * @dev Transfer the token based the stake states and emit event if Staked/Unstaked.
    */
    enum StakeState { 
        Stake, 
        UnStake
    }
    function transferToken(StakeState _stakeState, address _from, uint tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: tos_nft                 *
 * @team:   TheOtherSide                *
 *****************************************
 *   Interface for Staking related token *
 ****************************************/

interface ITOSStake {
  /**
    * @dev Interface for staking the NFT based on tokenId
    */
    function stake( address _sender, uint tokenId ) external;

  /**
    * @dev Interface for unstaking the NFT based on tokenId
    */
    function unStake( address _sender, uint tokenId ) external;

  /**
    * @dev Interface retrieving staked tokens based on user address.
    */
    function getStakedTokens(address _user) external view returns (uint256[] memory tokenIds);

  /**
    * @dev Interface to register a callback to receive tokenTransfer.
    */
    function regTokenTransfer(address _to) external;
}