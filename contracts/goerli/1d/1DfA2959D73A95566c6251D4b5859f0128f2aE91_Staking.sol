// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IMLC {
    function mintTo(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@andskur/contracts/contracts/extension/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@andskur/contracts/contracts/eip/interface/IERC20.sol";
import "@andskur/contracts/contracts/eip/interface/IERC721.sol";
import "./IMLC.sol";

contract Staking is Ownable, Pausable {

    // Collection data type with reward amount, reward interval and minimal time of staking
    struct StakedCollection {
        uint256 rewardAmount;
        uint256 rewardInterval;
        uint256 minStaking;
    }

    // Staked Token data type that identifier by collection address and token ID
    struct StakedToken {
        address collection;
        uint256 tokenId;
        address staker;
        uint256 totalStakingTime;
    }

    // Staker data type of token holder user
    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 claimedRewards;
        StakedToken[] stakedTokens;
    }

    // Interface for ERC20 rewards token
    IMLC public immutable rewardsToken;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Collection addresses Token Id to staker
    mapping(address => mapping(uint256 => address)) public stakerAddresses;

    // Added collections for stacking
    //collection address => stacking params see `stakedCollection` data type
    mapping(address => StakedCollection) private _stakedCollections;


    constructor (address _rewardsTokenAddress) {
        _setupOwner(msg.sender);
        rewardsToken = IMLC(_rewardsTokenAddress);
    }

    /*
    * @dev Adds `_amount` of available rewards to claim for given `_staker` address
    *
    * Requirements:
    * - Caller should be owner
    * - Contract should not be paused
    *
    * @param _staker  user address
    * @param _amount  amount of rewards that will be added to available rewards to claim
    */
    function addInitialReward(address _staker, uint256 _amount) external onlyOwner whenNotPaused {
        require(_staker != address(0), "Staker should not be 0 address!");
        require(_amount > 0, "Amount should be more than 0!");

        if (stakers[_staker].amountStaked > 0) {
            uint256 rewards = calculateRewards(_staker);
            stakers[_staker].unclaimedRewards += rewards;
            _updateTotalTimeStaked(_staker);
        }

        stakers[_staker].unclaimedRewards += _amount;

        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev If address already has ERC721 Token/s staked, calculate the rewards.
    * Increment the amountStaked and map msg.sender to the Token Id of the staked
    * Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    * value of now.
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenIds[]  NFT collection token IDs to withdraw
    */
    function stake(address _collectionAddress, uint256[] memory _tokenIds) external whenNotPaused {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            _updateTotalTimeStaked(msg.sender);
        }

        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection not registered or stacking interval is null");
        require(_stakedCollections[_collectionAddress].rewardInterval > 0, "Collection rewardInterval is null");
        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection rewardInterval is null");
        require(_tokenIds.length > 0, "There must be at least one token id");

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(IERC721(_collectionAddress).ownerOf(_tokenIds[i]) == msg.sender, "You don't own this token");

            IERC721(_collectionAddress).transferFrom(msg.sender, address(this), _tokenIds[i]);

            StakedToken memory stakedToken = StakedToken(_collectionAddress, _tokenIds[i], msg.sender, 0);

            stakers[msg.sender].stakedTokens.push(stakedToken);

            stakers[msg.sender].amountStaked++;

            stakerAddresses[_collectionAddress][_tokenIds[i]] = msg.sender;
        }

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    * calculate the rewards and store them in the unclaimedRewards
    * decrement the amountStaked of the user and transfer the ERC721 token back to them
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenId  NFT collection token ID to withdraw
    */
    function withdraw(address _collectionAddress, uint256 _tokenId) external whenNotPaused {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        require(stakerAddresses[_collectionAddress][_tokenId] == msg.sender, "You don't own this token");

        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId
                &&
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        stakers[msg.sender].stakedTokens[index].staker = address(0);
        stakers[msg.sender].amountStaked--;
        stakerAddresses[_collectionAddress][_tokenId] = address(0);

        IERC721(_collectionAddress).transferFrom(address(this), msg.sender, _tokenId);

        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim given amount, set unclaimedRewards to calculated rewards - amount to claim
    * and transfer the ERC20 Reward token to the user
    *
    */
    function claimRewards(uint256 amountToClaim) external whenNotPaused {
        require(amountToClaim > 0, "Amount to claim should be more than 0");
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = rewards - amountToClaim;
        stakers[msg.sender].claimedRewards = amountToClaim;
        rewardsToken.mintTo(msg.sender, amountToClaim);
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token to the user
    *
    */
    function claimAllRewards() external whenNotPaused {
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].claimedRewards = rewards;
        rewardsToken.mintTo(msg.sender, rewards);
    }

    /*
    * @dev Return available for given _staker address
    *
    * @param _staker   user address
    */
    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
        return rewards;
    }

    /*
    * @dev Return total claimed rewards for given _staker address
    *
    * @param _staker   user address
    */
    function claimedRewards(address _staker) public view returns (uint256) {
        return stakers[_staker].claimedRewards;
    }

    /*
    * @dev Return all staked tokens for given _staker address
    *
    * @param _staker   user address
    */
    function getStakedTokens(address _staker) public view returns (StakedToken[] memory) {
        if (stakers[_staker].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_staker].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_staker].stakedTokens.length; j++) {
                if (stakers[_staker].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_staker].stakedTokens[j];
                    _stakedTokens[_index].totalStakingTime += block.timestamp - stakers[_staker].timeOfLastUpdate;
                    _index++;
                }
            }

            return _stakedTokens;
        }

        else {
            return new StakedToken[](0);
        }
    }

    /*
    * @dev Return one staked token for given _collectionAddress and _tokenID
    *
    * @param _collectionAddress   collection address
    * @param _tokenID             token id
    */
    function getStakedToken(address _collectionAddress, uint256 _tokenID) public view returns(StakedToken memory) {
        if (_stakedCollections[_collectionAddress].minStaking > 0) {
            if (stakerAddresses[_collectionAddress][_tokenID] != address(0)) {
                for (uint256 j = 0; j < stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens.length; j++) {
                    if (
                        stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].staker != (address(0)) &&
                        stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].tokenId == _tokenID &&
                        stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].collection == _collectionAddress
                    ) {
                        uint256 totalStakingTime = stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].totalStakingTime;
                        return StakedToken(
                            stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].collection,
                            stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].tokenId,
                            stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].staker,
                            totalStakingTime += block.timestamp - stakers[stakerAddresses[_collectionAddress][_tokenID]].timeOfLastUpdate
                        );
                    }
                }
            }
        }

        return StakedToken(address(0), 0, address(0), 0);
    }

    /*
    * @dev Calculate rewards for given _staker address
    *
    * @param _staker   user address to calculate available reward
    */
    function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        for (uint256 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
            _rewards += ((block.timestamp - stakers[_staker].timeOfLastUpdate)
            * _stakedCollections[stakers[_staker].stakedTokens[i].collection].rewardAmount) / 3600;
        }
        return _rewards;
    }

    /*
    * @dev Adds `collectionAddress` with given params to `_stakedCollections` mapping
    *
    * Requirements:
    * - `collectionAddress` should not be 0
    * - `collectionAddress` should not be added to `_stakedCollections` mapping
    * - `rewardAmount` should not be 0
    * - `rewardInterval` should not be 0
    * - `minStaking` should not be 0
    * - only owner of the contract
    *
    * @param collectionAddress  address of the collection
    * @param rewardAmount       amount of coins as a reward for staking
    * @param rewardInterval     amount in block that could be produced in ethereum chain before users can take their reward
    * @param minStaking        amount in block that user could wait before he could be able to unstake tokens
    */
    function addCollection(
        address collectionAddress,
        uint256 rewardAmount,
        uint256 rewardInterval,
        uint256 minStaking
    ) external onlyOwner whenNotPaused {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount == 0, "Collection is already added!");
        require(rewardAmount != 0, "Reward amount should not be 0!");
        require(rewardInterval != 0, "Reward interval should not be 0!");
        require(minStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress] = StakedCollection(rewardAmount, rewardInterval, minStaking);
    }


    /*
     * @dev shows added collection params
     *
     * Requirements:
     * - `collectionAddress` must not be zero address
     * - `collectionAddress` must be in `_stakedCollections` mapping
     *
     * @param `collectionAddress`- address of a collection contract
     * @return `stakedCollection` data type with params of the collection such as
     * reward amount, reward interval and minimal time of staking
     */
    function showCollection(address collectionAddress) public view returns(StakedCollection memory) {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");

        return _stakedCollections[collectionAddress];
    }

    /*
     * @dev allows to edit amount of the reward for given collection. Changes `stakedCollection.rewardAmount`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardAmount` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardAmount`- new amount of coins as a reward for staking
     */
    function editRewardAmount(address collectionAddress, uint256 newRewardAmount) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardAmount != 0, "Reward amount should not be 0!");

        _stakedCollections[collectionAddress].rewardAmount = newRewardAmount;
    }

    /*
     * @dev allows to edit reward interval for given collection. Changes `stakedCollection.rewardInterval`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardInterval` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardInterval`- new amount in block that could be produced in ethereum chain before users can take their reward
     */
    function editRewardInterval(address collectionAddress, uint256 newRewardInterval) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardInterval != 0, "Reward interval should not be 0!");

        _stakedCollections[collectionAddress].rewardInterval = newRewardInterval;
    }

    /*
     * @dev allows to edit minimal time of staking for given collection. Changes `stakedCollection.minStaking`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newMinStaking` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newMinStaking`- new amount in block that user could wait before he could be able to unstake tokens
     */
    function editMinStaking(address collectionAddress, uint256 newMinStaking) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newMinStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress].minStaking = newMinStaking;
    }

    /*
     * @dev allows to set all not view only operations on pause
     *
     * Requirements:
     * - contract must not be paused
     * - only owner of the contract
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * @dev allows to set all not view-only operations to normal state
     *
     * Requirements:
     * - contract must be paused
     * - only owner of the contract
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _updateTotalTimeStaked(address stakerAddress) internal {
        for (uint256 i = 0; i < stakers[stakerAddress].stakedTokens.length; i++) {
            stakers[stakerAddress].stakedTokens[i].totalStakingTime += (
            block.timestamp - stakers[stakerAddress].timeOfLastUpdate
            );

        }

    }
}