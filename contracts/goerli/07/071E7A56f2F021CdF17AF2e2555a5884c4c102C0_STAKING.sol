// SPDX-License-Identifier: MIT

/**
 * @title Staking
 * Staking - a contract for staking The ERC-721A Tokens
 */

pragma solidity ^0.8.11;

import "./IStaking.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
  function safeTransferFrom(address from,address to,uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256);

  function nftGeneration(uint256 tokenId) external view returns (uint256);
}

interface ICoin {
  function grantCoins(address to, uint256 amount) external;
}

contract STAKING is IStaking, Ownable, ERC721Holder {
  INFT public nftContract;
  ICoin public coinContract;

	// || ADMIN SWITCHES ||

	// Halt staking
	bool stakingEnabled = true;

	// Grant equity while staked
  bool grantCoins = true;

	// Minimum staking period of 7 days
  uint64 public LOCK_IN = 604800;

	// || YIELD ||

	// Daily rate of award per level 1 estate
  uint256 public BASE_RATE = 10 ether;

  // Yield tracking
  mapping(address => uint256) public unclaimedRewards;
  mapping(address => uint256) public lastUpdate;
	event RewardGranted(address user, uint256 amount);	

	// || USER BALANCES ||

  // NFT tokenId to time staked and owner's address.
  mapping(uint64 => StakedToken) public stakes;

	// Gen balances per owner (necessary as different gens give different rewards)
	struct genBalance {
		uint gen1;
		uint gen2;
		uint gen3;
		uint gen4;
	}
	mapping (address => genBalance) public generationBalance;

	// || BREED FROM STAKED ||
	event Upgraded(uint256 newEstate, uint256 parent1, uint256 parent2);

  constructor(
    address _nftContract,
    address _coinContract
  ) {
    require(_nftContract != address(0),"Invalid NFT contract address");
    require(_coinContract != address(0),"Invalid Coin contract address");
    nftContract = INFT(_nftContract);
    coinContract = ICoin(_coinContract);
  }

	/** *********************************** **/
	/** ********* RewardFunctions ********* **/
	/** *********************************** **/

  function getPendingReward(address user) internal view returns (uint256) {
    // gen2 yields 2.4 gen1
    // gen3 yields 2.5 gen2
    // gen4 yields 2.6 gen3 
    uint dayrate = (generationBalance[user].gen1 + (generationBalance[user].gen2*12/5) + (generationBalance[user].gen3*6) + (generationBalance[user].gen4*78/5));
    // return weighted nfts held * rate *days since last updated
    return (dayrate * BASE_RATE * (block.timestamp - lastUpdate[user])) / 86400;
  }

	// Update yield ledger
    function updateRewardAndTimestamp(address user) internal {
      if (user != address(0)) {
        unclaimedRewards[user] += getPendingReward(user);
        lastUpdate[user] = block.timestamp;
      }
    }

	function withdrawEquity() public {
		require(grantCoins, "Withdrawing equity has been paused.");
		uint256 reward = unclaimedRewards[msg.sender] +  getPendingReward(msg.sender);
		coinContract.grantCoins(msg.sender, reward);
		// reset rewards to zero
		unclaimedRewards[msg.sender] = 0;
		lastUpdate[msg.sender] = block.timestamp;
		emit RewardGranted(msg.sender,reward);
	}

	/** *********************************** **/
	/** ******** Staking Functions ******** **/
	/** *********************************** **/

    function setStake(uint64 tokenId, address user) external {	
      require(stakingEnabled, "Staking has been paused.");
      require(msg.sender == address(nftContract), "Only NFT contract set stake");		
      updateRewardAndTimestamp(user);
      // assign owner and timestamp to this token
      stakes[tokenId] = StakedToken(user, uint64(block.timestamp));
      // update generation balance for user
      uint gen = nftContract.nftGeneration(tokenId);
      // this is awkward I know...
      if (gen == 0){
        generationBalance[user].gen1 += 1;
      } else if (gen == 1){
        generationBalance[user].gen2 += 1;
      } else if (gen == 2){
        generationBalance[user].gen3 += 1;
      } else {
        generationBalance[user].gen4 += 1;
      }
      emit StartStake(user, tokenId);
    }

    function setGroupStake(uint64[] memory tokenIds, address user) external {	
      require(stakingEnabled, "Staking has been paused.");
      require(msg.sender == address(nftContract), "Only NFT contract set stake");		
      updateRewardAndTimestamp(user);
      for (uint64 i = 0; i < tokenIds.length; ++i) {
        // assign owner and timestamp to this token
        stakes[tokenIds[i]] = StakedToken(user, uint64(block.timestamp));
        // update generation balance for user
        uint gen = nftContract.nftGeneration(tokenIds[i]);
        // this is awkward I know...
        if (gen == 0){
          generationBalance[user].gen1 += 1;
        } else if (gen == 1){
          generationBalance[user].gen2 += 1;
        } else if (gen == 2){
          generationBalance[user].gen3 += 1;
        } else {
          generationBalance[user].gen4 += 1;
        }
        emit StartStake(user, tokenIds[i]);
      }
    }

	// slightly cheaper version of setStake that assumes the token has already been transferred to the staking contract and is gen1 
	function stakeMint(uint256 firstTokenId, address user, uint256 _vol) public {
    require(msg.sender == address(nftContract), "Only NFT contract can mint to stake");
		updateRewardAndTimestamp(user);
		for (uint256 i=0; i<_vol; ++i) {
			stakes[uint64(firstTokenId+i)] = StakedToken(user, uint64(block.timestamp));
			emit StartStake(user, uint64(firstTokenId+i));
		}
		generationBalance[user].gen1 += _vol;	
	}

  function unstake(uint64 tokenId) internal {
    require(stakes[tokenId].user != address(0), "TokenId not staked");
    require(stakes[tokenId].user == msg.sender,"Sender didn't stake token");
    uint64 stakeLength = uint64(block.timestamp) - stakes[tokenId].timeStaked;
    require(stakeLength > LOCK_IN, "Can not remove token until lock-in period is over");

    // update gen balance
    uint gen = nftContract.nftGeneration(tokenId);
    if (gen == 0){
      generationBalance[msg.sender].gen1 -= 1;
    } else if (gen == 1){
      generationBalance[msg.sender].gen2 -= 1;
    } else if (gen == 2){
      generationBalance[msg.sender].gen3 -= 1;
    } else {
      generationBalance[msg.sender].gen4 -= 1;
    }		
        
    delete stakes[tokenId];
    nftContract.safeTransferFrom(address(this),msg.sender,uint256(tokenId));
    emit Unstake(msg.sender,tokenId,stakeLength);
  }

	function singleUnstake(uint64 tokenId) public override {
    // withdraw any unclaimed rewards
		if (grantCoins) {
      withdrawEquity();
    } else {
			updateRewardAndTimestamp(msg.sender);
		}
		unstake(tokenId);
	}

  function groupUnstake(uint64[] memory tokenIds) external override {
    // withdraw any unclaimed rewards
    if (grantCoins) {
      withdrawEquity();
    } else {
      updateRewardAndTimestamp(msg.sender);
    }

    for (uint64 i = 0; i < tokenIds.length; ++i) {
      unstake(tokenIds[i]);
    }
  }

	/** *********************************** **/
	/** ********** View Functions ********* **/
	/** *********************************** **/

	function getTokenOwner(uint64 tokenId) external view returns (address) {
		return stakes[uint64(tokenId)].user;
	}	

	// NEVER CALL THIS ON CHAIN, VERY EXPENSIVE
  function viewStakes(address _address) public view returns (uint256[] memory) {
    uint256[] memory _tokens = new uint256[](18750);
    uint256 tookCount = 0;
    for (uint64 i = 0; i < 18750; i++) {
      if (stakes[i].user == _address) {
        _tokens[tookCount] = i;
        tookCount++;
      }
    }

    uint256[] memory trimmedResult = new uint256[](tookCount);
    for (uint256 j = 0; j < trimmedResult.length; j++) {
      trimmedResult[j] = _tokens[j];
    }

    return trimmedResult;
  }

	// Gets COMBINED balance of UNSTAKED and STAKED estates, useful for collabland etc
  function balanceOf(address _address) external view returns (uint256) {
    return nftContract.balanceOf(_address) + viewStakes(_address).length;
  }

  function getTotalUnclaimed(address user) external view returns (uint256 unclaimed)	{
    return unclaimedRewards[user] + getPendingReward(user);
  }

	/** *********************************** **/
	/** ********* Owner Functions ********* **/
	/** *********************************** **/

	// Enable or disable staking
  function setStaking(bool _enable) external onlyOwner {
    stakingEnabled = _enable;
  }

	// Enable or disable equity granting
  function setGrantCoins(bool _grant) external onlyOwner {
    grantCoins = _grant;
  }

	// Set the lockin period for staking
  function setLockIn(uint64 _lockin) external onlyOwner {
    LOCK_IN = _lockin;
  }

	// Set the base rate for rewards
  function setBaseRate(uint256 _rate) external onlyOwner {
    BASE_RATE = 1 ether * _rate;
  } 

	// Set NFT contract
  function setNftContract(address _address) external onlyOwner {
    nftContract = INFT(_address);
  }

	// Set $Coin contract
  function setCoinContract(address _address) external onlyOwner {
    coinContract = ICoin(_address);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IStaking is IERC721Receiver {
    struct StakedToken {
        address user;
        uint64 timeStaked;
    }

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param tokenId the tokenId of the Estates NFT being staked.
    event StartStake(address indexed owner, uint64 tokenId);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param tokenId the tokenId of the Estates NFT being unstaked.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint64 tokenId,
        uint64 duration
    );

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param tokenId the tokenId of the staked NFT
    function singleUnstake(uint64 tokenId) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupUnstake(uint64[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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