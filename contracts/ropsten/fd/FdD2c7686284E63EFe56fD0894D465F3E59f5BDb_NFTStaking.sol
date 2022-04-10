//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

struct STAKE {
    uint256 amount;
    uint256 rewardSoFar;
    uint256 firstStakedAt;
    uint256 lastClaimedAt;
}

struct POOL {
    uint256 poolId;
    uint256 nftTokenId;
    uint256 totalStakes;
    uint256 totalRewards;
    uint256 rewardPerNFT;
    uint256 rewardPeriod;
    uint256 maxPerClaim;
}

contract NFTStaking is Context, ERC1155Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev map poolId to staking Pool detail
    uint public stakingPoolsCount;
    mapping(uint256 => POOL) stakingPools;
    mapping(uint256 => mapping(address => STAKE)) balances;
    IERC20 private _token;
    IERC1155 private _nftToken;

    constructor(IERC20 _tokenAddress, IERC1155 _nftTokenAddress) {
        _token = _tokenAddress;
        _nftToken = _nftTokenAddress;
        stakingPoolsCount = 0;
    }

    function setTokenAddress(IERC20 _tokenAddress) external onlyOwner {
        _token = _tokenAddress;
    }

    function setNftTokenAddress(IERC1155 _nftTokenAddress) external onlyOwner {
        _nftToken = _nftTokenAddress;
    }

    event Stake(uint256 indexed poolId, address staker, uint256 amount);
    event Unstake(uint256 indexed poolId, address staker, uint256 amount);
    event Withdraw(uint256 indexed poolId, address staker, uint256 amount);

    /**
     * @notice get remaining rewards from all existing pools
     * @return rewardsTotal
     */
    function getReservedRewards() public view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < stakingPoolsCount; i++) {
            uint256 poolRewards = stakingPools[i].totalRewards;
            total = total + poolRewards;
        }
        return total;
    }

    /**
     * @notice get staking pool by id
     * @param _poolId is the staking pool identifier
     * @return stakingPool
     */
    function getPool(uint256 _poolId) public view returns (POOL memory) {
      require((_poolId >= 0 && _poolId < stakingPoolsCount), "Invalid poolId range");
      return stakingPools[_poolId];
    }

    /**
     * @notice gets staking pool by NFT id or the pool with most available rewards
     * @param _nftId is the NFT identifier
     * @param _staker is the staker for whom we are looking for the best pool
     * @return stakingPool
     */
    function getPool(uint256 _nftId, address _staker) public view returns (POOL memory) {
        // return undefined pool if nothing is found
        POOL memory poolInfoBestAvailable = POOL(0,0,0,0,0,0,0);
        for (uint i = 0; i < stakingPoolsCount; i++) {
            POOL memory poolInfo = stakingPools[i];

            // ignore all pools not relevant to searched token
            if (poolInfo.nftTokenId != _nftId) continue;

            uint amount = balances[i][_staker].amount;

            // return immediately first pool if user has anything already staked with the pool that was just found
            if (amount > 0) return poolInfo;
            if (poolInfo.totalRewards >= poolInfoBestAvailable.totalRewards) poolInfoBestAvailable = poolInfo;
        }

      return poolInfoBestAvailable;
    }

    /**
     * @notice gets the staker balance of for the staking pool that can give the most rewards
     * @param _nftId is the NFT identifier
     * @param _staker is the staker for whose stake we are looking for
     * @return stakingBalance
     */
    function getBalance(uint256 _nftId, address _staker) public view returns (STAKE memory) {
        // get pool that gives max possible rewards at the current time instance
        POOL memory poolInfo = getPool(_nftId, _staker);

        uint poolDefined = poolInfo.rewardPeriod;
        // if pool is undefined
        if (poolDefined == 0) return STAKE(0,0,0,0);

        // pool is defined, return balance
        uint poolId = poolInfo.poolId;
        return balances[poolId][_staker];
    }

    /**
     * @notice gets the staker balance of for the specific staking pool
     * @param _staker is the staker for whose stake we are looking for
     * @param _poolId is the pool identifier
     * @return stakingBalance
     */
    function getBalance(address _staker, uint256 _poolId) public view returns (STAKE memory) {
        require((_poolId >= 0 && _poolId < stakingPoolsCount), "Invalid poolId range");
        return balances[_poolId][_staker];
    }

    /**
     * @notice gets amount of staker claimable rewards by nft identifier
     * @param _nftId is the NFT identifier
     * @param _staker is the staker for whose stake we are looking for
     * @return claimable rewards amount
     */
    function getRewards(uint256 _nftId, address _staker) public view returns (uint256) {
        // get pool that gives max possible rewards at the current time instance
        POOL memory poolInfo = getPool(_nftId, _staker);

        uint poolDefined = poolInfo.rewardPeriod;
        // if pool is undefined
        if(poolDefined == 0) return 0;

        return rewardOf(poolInfo.poolId, _staker);
    }

    /**
     * @notice calculate total stakes of staker
     * @param _poolId is the pool identifier
     * @param _staker is the address of staker
     * @return _total
     */
    function totalStakeOf(uint256 _poolId, address _staker) public view returns (uint256) {
        return balances[_poolId][_staker].amount;
    }

    /**
     * @notice calculate entire stake amount
     * @param _poolId is the pool identifier
     * @return _total
     */
    function getTotalStakes(uint256 _poolId) public view returns (uint256) {
        return stakingPools[_poolId].totalStakes;
    }

    /**
     * @notice get the first staked time
     * @param _poolId is the pool identifier
     * @return firstStakedAt
     */
    function getFirstStakedAtOf(uint256 _poolId, address _staker) public view returns (uint256) {
        return balances[_poolId][_staker].firstStakedAt;
    }

    /**
     * @notice get total claimed reward of staker
     * @param _poolId is the pool identifier
     * @return rewardSoFar
     */
    function getRewardSoFarOf(uint256 _poolId, address _staker) public view returns (uint256) {
        return balances[_poolId][_staker].rewardSoFar;
    }

    /**
     * @notice calculate reward of staker
     * @param _poolId is the pool identifier
     * @return reward is the reward amount of the staker
     */
    function rewardOf(uint256 _poolId, address _staker) public view returns (uint256) {
        STAKE memory balanceInfo = balances[_poolId][_staker];

        // if staker is NOT staking the token anymore then rewards is always 0 because claim is triggered on withdraw
        // notice that lastClaimedAt is set at the time of stake event occuring, if user didnt staked anything then timePassed calculations would NOT be valid
        if (balanceInfo.amount == 0) return 0;

        POOL memory poolInfo = stakingPools[_poolId];

        uint256 timeNow = block.timestamp;
        // passed time in seconds since the last claim
        uint256 timePassed = timeNow - balanceInfo.lastClaimedAt;
        uint256 totalReward = (balanceInfo.amount * poolInfo.rewardPerNFT * timePassed) / poolInfo.rewardPeriod;

        // there can be a situation where someone is staking for a very long time and no one is claiming, then sudenly 1 person ruggs everyone
        // to solve this issue we force people to claim every time they accumulate maxPerClaim and thus available rewards don't suddenly go to 0
        if (totalReward > poolInfo.maxPerClaim) totalReward = poolInfo.maxPerClaim;

        // there can be a situation where someone is staking longer than others and claimed multiple times
        // we should inform everyone about this by decreasing everyone max claim
        uint256 fairRewardPerNFT = poolInfo.totalRewards / poolInfo.totalStakes;
        uint256 maxFairReward = balanceInfo.amount * fairRewardPerNFT;
        if (totalReward > maxFairReward) totalReward = maxFairReward;

        if (totalReward > poolInfo.totalRewards) totalReward = poolInfo.totalRewards;
        return totalReward;
    }

    function claimReward(uint256 _poolId) external nonReentrant {
        require((_poolId >= 0 && _poolId < stakingPoolsCount), "Invalid poolId range");
        uint256 reward = rewardOf(_poolId, _msgSender());
        POOL storage poolInfo = stakingPools[_poolId];
        STAKE storage balanceInfo = balances[_poolId][_msgSender()];

        _token.safeTransfer(_msgSender(), reward);

        balanceInfo.lastClaimedAt = block.timestamp;
        balanceInfo.rewardSoFar = balanceInfo.rewardSoFar + reward;
        poolInfo.totalRewards = poolInfo.totalRewards - reward;

        emit Withdraw(_poolId, _msgSender(), reward);
    }

    /**
     * @notice stake NFT
     * @param _poolId is the pool identifier
     * @param _amount is the NFT count to stake
     */
    function stake(uint256 _poolId, uint256 _amount) external nonReentrant {
        require((_poolId >= 0 && _poolId < stakingPoolsCount), "Invalid poolId range");
        POOL storage poolInfo = stakingPools[_poolId];

        _nftToken.safeTransferFrom(_msgSender(), address(this), poolInfo.nftTokenId, _amount, '');

        STAKE storage balance = balances[_poolId][_msgSender()];

        if (balance.amount > 0) {
            uint256 reward = rewardOf(_poolId, _msgSender());

            _token.safeTransfer(_msgSender(), reward);
            balance.rewardSoFar = balance.rewardSoFar + reward;
            poolInfo.totalRewards = poolInfo.totalRewards - reward;

            emit Withdraw(_poolId, _msgSender(), reward);
        }
        if (balance.amount == 0) balance.firstStakedAt = block.timestamp;

        balance.lastClaimedAt = block.timestamp;
        balance.amount = balance.amount + _amount;
        stakingPools[_poolId].totalStakes = stakingPools[_poolId].totalStakes + _amount;

        emit Stake(_poolId, _msgSender(), _amount);
    }

    /**
     * @notice unstake current staking
     * @param _poolId is the pool identifier
     * @param _count number of tokens to unstake
     */
    function unstake(uint256 _poolId, uint256 _count) external nonReentrant {
        STAKE storage balance = balances[_poolId][_msgSender()];
        require((balance.amount >= _count && _count > 0), 'Unsufficient stake');

        POOL storage poolInfo = stakingPools[_poolId];
        uint256 reward = (rewardOf(_poolId, _msgSender()) * _count) / balance.amount;

        _token.safeTransfer(_msgSender(), reward);
        _nftToken.safeTransferFrom(address(this), _msgSender(), poolInfo.nftTokenId, _count, '');

        poolInfo.totalStakes = poolInfo.totalStakes - _count;
        poolInfo.totalRewards = poolInfo.totalRewards - reward;

        balance.amount = balance.amount - _count;
        balance.rewardSoFar = balance.rewardSoFar + reward;

        if (balance.amount == 0) {
            balance.firstStakedAt = 0;
            balance.lastClaimedAt = 0;
        }

        emit Unstake(_poolId, _msgSender(), _count);
    }

    /**
     * @notice function to notify contract how many rewards to assign for the specific pool
     * @param _poolId is the pool id to contribute reward
     * @param _amount is the amount to put
     */
    function notifyRewards(uint256 _poolId, uint256 _amount) external onlyOwner {
        require(_amount > 0, "NFTStaking.notifyRewards: Can't add zero amount!");

        POOL storage poolInfo = stakingPools[_poolId];
        uint total = _token.balanceOf(address(this));
        uint reserved = getReservedRewards();

        require(total - reserved >= _amount, "NFTStaking.notifyRewards: Can't add more tokens than available");
        poolInfo.totalRewards = poolInfo.totalRewards + _amount;
    }

    /**
     * @notice function to forecefully remove staking rewards from the pool into owner's wallet
     * @param _poolId is the pool id to contribute reward
     * @param _amount is the amount to claim
     */
    function withdrawRewards(uint256 _poolId, uint256 _amount) public onlyOwner {
        POOL storage poolInfo = stakingPools[_poolId];
        require(poolInfo.totalRewards >= _amount, 'NFTStaking.withdrawRewards(_poolId, _amount): Not enough remaining rewards!');

        _token.safeTransfer(_msgSender(), _amount);
        poolInfo.totalRewards = poolInfo.totalRewards - _amount;
    }

    /**
     * @notice function to forecefully remove ALL staking rewards from the pool into owner's wallet
     * @param _poolId is the pool id to contribute reward
     */
    function withdrawRewards(uint256 _poolId) external onlyOwner {
        POOL memory poolInfo = stakingPools[_poolId];
        require(poolInfo.totalRewards > 0, 'NFTStaking.withdrawRewards(_poolId): Staking pool is already empty');
        withdrawRewards(_poolId, poolInfo.totalRewards);
    }

    /**
     * @notice adds new staking pool
     * @param _nftTokenId is the token id that can be staked to the pool
     * @param _rewardPerNFT is the amount of rewards token can receive over the rewar period 
     * @param _rewardPeriod is the numer of seconds within each nft can earn the amount equal to rewardPerNFT
     * @param _maxPerClaim each account has restriction regarding max amount per each rewards claim, this way rewards do NOT suddenly disappear when users check their rewards balances
     */
    function addPool(
        uint256 _nftTokenId,
        uint256 _rewardPerNFT,
        uint256 _rewardPeriod,
        uint256 _maxPerClaim
    ) external onlyOwner {
        uint256 poolId = stakingPoolsCount;
        require((_rewardPeriod >= 3600 && _rewardPeriod <= 31556925), "NFTStaking.addPool: Rewards period must be within 1h & 1Y");
        require(_maxPerClaim > 0, "NFTStaking.addPool: Rewards max per each claim can NOT be 0");
        require(stakingPools[poolId].rewardPerNFT == 0, 'NFTStaking.addPool: Pool already exists!');
        require(stakingPools[poolId].poolId == 0, 'NFTStaking.addPool: poolId already exists!');
        require(stakingPools[poolId].rewardPeriod == 0, 'NFTStaking.addPool: Pool already exists!');

        stakingPools[poolId] = POOL(poolId, _nftTokenId, 0, 0, _rewardPerNFT, _rewardPeriod, _maxPerClaim);
        stakingPoolsCount++;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}