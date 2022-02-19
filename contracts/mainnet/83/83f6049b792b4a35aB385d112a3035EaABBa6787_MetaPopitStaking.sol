// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/Recoverable.sol";
import "./interfaces/ITokenStake.sol";

/**
 * @title MetaPopitStaking
 * @notice MetaPopit Staking contract
 * https://www.metapopit.com
 */
contract MetaPopitStaking is Ownable, Recoverable {
    using Counters for Counters.Counter;

    struct TokenInfo {
        uint256 level;
        uint256 pool;
        bool redeemed;
    }
    struct OwnerInfo {
        uint256 hints;
        uint256 staked;
        uint256 startHintTime;
        bool redeemed;
    }
    struct PoolInfo {
        uint256 depositTime;
        uint256 levelSpeed;
        uint256[] tokens;
        address owner;
    }

    uint256 public constant SPEED_RESOLUTION = 1000;

    bool public isStakingClosed;
    uint256 public stakedTokenCount;
    uint256 public maxLevelTeamSize;
    uint256 public maxHintTeamSize;
    address public immutable collection;

    Counters.Counter private _poolCounter;

    // speeds per number of NFT
    mapping(uint256 => uint256) private _levelSpeed;
    mapping(uint256 => uint256) private _hintSpeed;

    // mapping poolId => PoolInfo
    mapping(uint256 => PoolInfo) private _poolInfos;
    // mapping tokenId => TokenInfo
    mapping(uint256 => TokenInfo) private _tokenInfos;
    // mapping owner => OwnerInfo
    mapping(address => OwnerInfo) private _ownerInfos;

    event Stake(address indexed account, uint256 poolIndex, uint256[] tokenIds);
    event UnStake(address indexed account, uint256 poolIndex, uint256[] tokenIds);
    event RedeemToken(uint256 tokenId, uint256 level);
    event RedeemAccount(address indexed account, uint256 hints);
    event StakingClosed();

    modifier whenTokensNotStaked(uint256[] memory tokenIds) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!ITokenStake(collection).isTokenStaked(tokenIds[i]), "MetaPopitStaking: Token already staked");
        }
        _;
    }

    modifier whenStakingOpened() {
        require(!isStakingClosed, "MetaPopitStaking: staking closed");
        _;
    }

    constructor(address _collection) {
        collection = _collection;
    }

    function _getNextPoolId() internal returns (uint256) {
        _poolCounter.increment();
        return _poolCounter.current();
    }

    /**
     * @dev returns the current pending reward based on current value and speed
     */
    function _getPendingRewards(
        uint256 currentValue,
        uint256 depositTime,
        uint256 speed
    ) internal view returns (uint256 pendingReward, uint256 nextRewardDate) {
        pendingReward = currentValue;
        nextRewardDate = 0;

        if (speed > 0) {
            uint256 currentDate = depositTime * SPEED_RESOLUTION;
            uint256 maxDate = block.timestamp * SPEED_RESOLUTION;
            uint256 increment = speed;

            pendingReward = 0;
            while (currentDate <= maxDate) {
                pendingReward += 1;

                if (pendingReward > currentValue) {
                    currentDate += increment;
                }

                increment *= 2;
            }

            nextRewardDate = currentDate / SPEED_RESOLUTION;
        }
    }

    /**
     * @dev Apply completed pending level rewards for a token
     */
    function _applyPendingLevel(
        uint256 tokenId,
        uint256 depositTime,
        uint256 levelSpeed
    ) internal {
        if (depositTime > 0 && levelSpeed > 0) {
            (uint256 pendingLevel, ) = _getPendingRewards(_tokenInfos[tokenId].level, depositTime, levelSpeed);
            if (pendingLevel > 0) _tokenInfos[tokenId].level = pendingLevel - 1;
        }
    }

    /**
     * @dev Apply completed pending hints rewards for a user
     */
    function _applyPendingHints(address account) internal {
        if (_ownerInfos[account].staked == 0 || _ownerInfos[account].redeemed || _ownerInfos[account].startHintTime == 0) return;

        uint256 hintSpeed = getHintSpeed(_ownerInfos[account].staked);
        if (hintSpeed > 0) {
            (uint256 pendingHints, ) = _getPendingRewards(
                _ownerInfos[account].hints,
                _ownerInfos[account].startHintTime,
                hintSpeed
            );

            if (pendingHints > 0) {
                _ownerInfos[account].hints = pendingHints - 1;
            }
        }

        _ownerInfos[account].startHintTime = 0;
    }

    /**
     * @dev returns the current level state for token
     */
    function getLevel(uint256 tokenId)
        public
        view
        returns (
            uint256 level,
            uint256 pendingLevel,
            uint256 nextLevelDate,
            uint256 levelSpeed,
            uint256 poolId,
            bool redeemed
        )
    {
        level = _tokenInfos[tokenId].level;
        poolId = _tokenInfos[tokenId].pool;
        redeemed = _tokenInfos[tokenId].redeemed;
        levelSpeed = 0;

        if (_tokenInfos[tokenId].pool != 0) {
            (pendingLevel, nextLevelDate) = _getPendingRewards(
                _tokenInfos[tokenId].level,
                _poolInfos[_tokenInfos[tokenId].pool].depositTime,
                _poolInfos[_tokenInfos[tokenId].pool].levelSpeed
            );
            levelSpeed = _poolInfos[_tokenInfos[tokenId].pool].levelSpeed;
        }
    }

    /**
     * @dev returns the current hint state for a user
     */
    function getHints(address account)
        public
        view
        returns (
            uint256 hints,
            uint256 pendingHints,
            uint256 nextHintDate,
            uint256 hintSpeed,
            bool redeemed
        )
    {
        hints = _ownerInfos[account].hints;
        redeemed = _ownerInfos[account].redeemed;
        hintSpeed = 0;

        if (_ownerInfos[account].startHintTime != 0) {
            hintSpeed = getHintSpeed(_ownerInfos[account].staked);
            (pendingHints, nextHintDate) = _getPendingRewards(
                _ownerInfos[account].hints,
                _ownerInfos[account].startHintTime,
                hintSpeed
            );
        }
    }

    /**
     * @dev returns `true` if `tokenId` is staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return _tokenInfos[tokenId].pool != 0;
    }

    /**
     * @dev returns stake info for a token (poolIndex, deposit time and rewards speed)
     */
    function getStakeInfo(uint256 tokenId)
        public
        view
        returns (
            uint256 poolIndex,
            uint256 depositTime,
            uint256 levelSpeed
        )
    {
        uint256 poolId = _tokenInfos[tokenId].pool;
        if (poolId == 0) {
            poolIndex = 0;
            depositTime = 0;
            levelSpeed = 0;
        } else {
            poolIndex = poolId;
            depositTime = _poolInfos[poolId].depositTime;
            levelSpeed = _poolInfos[poolId].levelSpeed;
        }
    }

    /**
     * @dev returns the info for a pool
     */
    function getPoolInfo(uint256 poolIndex) public view returns (PoolInfo memory pool) {
        pool = _poolInfos[poolIndex];
    }

    /**
     * @dev returns the info for a token
     */
    function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory tokenInfo) {
        tokenInfo = _tokenInfos[tokenId];
    }

    function _redeemToken(uint256 tokenId) internal {
        require(_tokenInfos[tokenId].pool == 0, "MetaPopitStaking: Must unstake before redeem");
        _tokenInfos[tokenId].redeemed = true;
        emit RedeemToken(tokenId, _tokenInfos[tokenId].level);
    }

    function _redeemAccount(address account) internal {
        _applyPendingHints(account);
        _ownerInfos[account].redeemed = true;
        _ownerInfos[account].startHintTime = 0;
        emit RedeemAccount(account, _ownerInfos[account].hints);
    }

    /**
     * @dev returns `true` if `tokenId` is redeemed
     */
    function isTokenRedeemed(uint256 tokenId) public view returns (bool) {
        return _tokenInfos[tokenId].redeemed;
    }

    /**
     * @dev returns `true` if `tokenId` is redeemed
     */
    function isAccountRedeemed(address account) public view returns (bool) {
        return _ownerInfos[account].redeemed;
    }

    function _stake(address tokenOwner, uint256[] memory tokenIds)
        internal
        whenStakingOpened
        whenTokensNotStaked(tokenIds)
    {
        uint256 poolIndex = _getNextPoolId();
        _poolInfos[poolIndex] = PoolInfo({
            depositTime: block.timestamp,
            levelSpeed: getLevelSpeed(tokenIds.length),
            tokens: tokenIds,
            owner: tokenOwner
        });

        if (_ownerInfos[tokenOwner].staked < maxHintTeamSize) {
            _applyPendingHints(tokenOwner);
            _ownerInfos[tokenOwner].startHintTime = block.timestamp;
        }
        _ownerInfos[tokenOwner].staked += tokenIds.length;
        stakedTokenCount += tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_tokenInfos[tokenId].redeemed, "MetaPopitStaking: Rewards already redeemed");
            require(ITokenStake(collection).ownerOf(tokenId) == tokenOwner, "MetaPopitStaking: Not owner");
            _tokenInfos[tokenId].pool = poolIndex;
            ITokenStake(collection).stakeToken(tokenId);
        }

        emit Stake(tokenOwner, poolIndex, tokenIds);
    }

    function _unstake(uint256 poolId, bool redeemRewards) internal {
        require(_poolInfos[poolId].owner != address(0), "MetaPopitStaking: invalid pool");
        PoolInfo memory pool = _poolInfos[poolId];
        delete _poolInfos[poolId];

        if (_ownerInfos[pool.owner].staked - pool.tokens.length < maxHintTeamSize) {
            _applyPendingHints(pool.owner);
            _ownerInfos[pool.owner].startHintTime = block.timestamp;
        }
        _ownerInfos[pool.owner].staked -= pool.tokens.length;

        for (uint256 i = 0; i < pool.tokens.length; i++) {
            _tokenInfos[pool.tokens[i]].pool = 0;
            _applyPendingLevel(pool.tokens[i], pool.depositTime, pool.levelSpeed);
            if (redeemRewards) _redeemToken(pool.tokens[i]);
            ITokenStake(collection).unstakeToken(pool.tokens[i]);
        }

        stakedTokenCount -= pool.tokens.length;
        emit UnStake(pool.owner, poolId, pool.tokens);
    }

    /**
     * @dev Stake a group of tokens in a pool
     */
    function stake(uint256[] calldata tokenIds) external {
        require(tokenIds.length <= maxLevelTeamSize, "MetaPopitStaking: above max team size");
        _stake(_msgSender(), tokenIds);
    }

    /**
     * @dev Ustake tokens from `poolId``
     * @param redeemRewards : redeem rewards for token if set to `true`
     */
    function unstake(uint256 poolId, bool redeemRewards) external {
        require(_poolInfos[poolId].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
        _unstake(poolId, redeemRewards);
    }

    /**
     * @dev Batch stake a group of tokens in multiple pools
     */
    function batchStake(uint256[][] calldata batchTokenIds) external {
        for (uint256 i = 0; i < batchTokenIds.length; i++) {
            require(batchTokenIds[i].length <= maxLevelTeamSize, "MetaPopitStaking: above max team size");
            _stake(_msgSender(), batchTokenIds[i]);
        }
    }

    /**
     * @dev Batch unstake token from a list of pools
     * @param redeemRewards : redeem rewards for token if set to `true`
     */
    function batchUnstake(uint256[] calldata poolIds, bool redeemRewards) external {
        for (uint256 i = 0; i < poolIds.length; i++) {
            require(_poolInfos[poolIds[i]].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
            _unstake(poolIds[i], redeemRewards);
        }
    }

    /**
     * @dev Stake `tokenIds` in a existing pool
     */
    function addToPool(uint256 poolId, uint256[] calldata tokenIds)
        external
        whenStakingOpened
        whenTokensNotStaked(tokenIds)
    {
        require(_poolInfos[poolId].owner == _msgSender(), "MetaPopitStaking: not owner of pool");
        require(
            _poolInfos[poolId].tokens.length + tokenIds.length <= maxLevelTeamSize,
            "MetaPopitStaking: above max team size"
        );

        // apply pending rewards
        if (_ownerInfos[_msgSender()].staked < maxHintTeamSize) {
            _applyPendingHints(_msgSender());
            _ownerInfos[_msgSender()].startHintTime = block.timestamp;
        }
        _ownerInfos[_msgSender()].staked += tokenIds.length;

        uint256 oldLength = _poolInfos[poolId].tokens.length;
        uint256[] memory newTokenIds = new uint256[](oldLength + tokenIds.length);
        for (uint256 i = 0; i < _poolInfos[poolId].tokens.length; i++) {
            _applyPendingLevel(
                _poolInfos[poolId].tokens[i],
                _poolInfos[poolId].depositTime,
                _poolInfos[poolId].levelSpeed
            );
            newTokenIds[i] = _poolInfos[poolId].tokens[i];
        }

        // stake new tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!_tokenInfos[tokenIds[i]].redeemed, "MetaPopitStaking: Rewards already redeemed");
            require(ITokenStake(collection).ownerOf(tokenIds[i]) == _msgSender(), "MetaPopitStaking: Not owner");
            ITokenStake(collection).stakeToken(tokenIds[i]);
            newTokenIds[oldLength + i] = tokenIds[i];
            _tokenInfos[tokenIds[i]].pool = poolId;
        }

        // update pool infos
        _poolInfos[poolId].depositTime = block.timestamp;
        _poolInfos[poolId].levelSpeed = getLevelSpeed(newTokenIds.length);
        _poolInfos[poolId].tokens = newTokenIds;

        stakedTokenCount += tokenIds.length;
        emit Stake(_msgSender(), poolId, tokenIds);
    }

    /**
     * @dev Redeem the final rewards for a token.
     * Once redeemed a token cannot be staked in this contract anymore
     */
    function redeemToken(uint256 tokenId) external {
        require(!_tokenInfos[tokenId].redeemed, "MetaPopitStaking: Token already redeemed");
        require(ITokenStake(collection).ownerOf(tokenId) == _msgSender(), "MetaPopitStaking: not owner");
        _redeemToken(tokenId);
    }

    /**
     * @dev Redeem the final rewards for an account.
     * Once redeemed hints are not incremented any more
     */
    function redeemAccount() external {
        require(!_ownerInfos[_msgSender()].redeemed, "MetaPopitStaking: Account already redeemed");
        _redeemAccount(_msgSender());
    }

    /**
     * @dev returns the level speed for a `teamSize`
     */
    function getLevelSpeed(uint256 teamSize) public view returns (uint256) {
        if (teamSize > maxLevelTeamSize) {
            return _levelSpeed[maxLevelTeamSize];
        }
        return _levelSpeed[teamSize];
    }

    /**
     * @dev returns the hint speed for a `teamSize`
     */
    function getHintSpeed(uint256 teamSize) public view returns (uint256) {
        if (teamSize > maxHintTeamSize) {
            return _hintSpeed[maxHintTeamSize];
        }
        return _hintSpeed[teamSize];
    }

    /**
     * @dev Update the base speed of level and hint rewards
     * only callable by owner
     */
    function setSpeeds(uint256[] calldata levelSpeed, uint256[] calldata hintSpeed) external onlyOwner {
        maxLevelTeamSize = levelSpeed.length;
        maxHintTeamSize = hintSpeed.length;

        for (uint256 i = 0; i < levelSpeed.length; i++) {
            _levelSpeed[i + 1] = levelSpeed[i];
        }

        for (uint256 i = 0; i < hintSpeed.length; i++) {
            _hintSpeed[i + 1] = hintSpeed[i];
        }
    }

    /**
     * @dev Close the staking
     * only callable by owner
     */
    function closeStaking() external onlyOwner {
        require(!isStakingClosed, "MetaPopitStaking: staking already closed");
        isStakingClosed = true;
        emit StakingClosed();
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IRecoverable.sol";

abstract contract Recoverable is Ownable, IRecoverable {
    using SafeERC20 for IERC20;

    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    event EthRecovery(uint256 amount);

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external virtual onlyOwner {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external virtual onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(_token).safeTransfer(address(msg.sender), balance);
        emit TokenRecovery(_token, balance);
    }

    function recoverEth(address payable _to) external virtual onlyOwner {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
        emit EthRecovery(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenStake is IERC721 {
    function isTokenStaked(uint256 tokenId) external returns (bool);

    function stakeToken(uint256 tokenId) external;

    function unstakeToken(uint256 tokenId) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRecoverable {
    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the NFT contract by mistake and this contract
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external;

    /**
     * @notice Allows the owner to recover tokens sent to the NFT contract and this contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external;

    /**
     * @notice Allows the owner to recover ETH sent to the NFT contract ans and contract by mistake
     * @param _to: target address
     * @dev Callable by owner
     */
    function recoverEth(address payable _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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