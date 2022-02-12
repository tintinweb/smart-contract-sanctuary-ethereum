//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

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

contract NFTStaking is Context, ERC1155Holder, Ownable {
    using SafeMath for uint256;

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
            POOL memory pool = stakingPools[i];
            uint256 poolRewards = pool.totalRewards;
            total = total.add(poolRewards);
        }
        return total;
    }

    /**
     * @notice get staking pool by id
     * @param _poolId is the staking pool identifier
     * @return stakingPool
     */
    function getPool(uint256 _poolId) public view returns (POOL memory) {
      return stakingPools[_poolId];
    }

    /**
     * @notice gets staking pool by NFT id with highest remaining rewards that the staker can claim
     * @param _nftId is the NFT identifier
     * @param _staker is the staker for whom we are looking for the best pool
     * @return stakingPool
     */
    function getPool(uint256 _nftId, address _staker) public view returns (POOL memory) {
        POOL memory poolInfo;
        uint256 bestRewards = 0;
        for (uint i = 0; i < stakingPoolsCount; i++) {
            uint256 poolNftId = stakingPools[i].nftTokenId;
            uint256 clamableRewards = rewardOf(i, _staker);
            if (poolNftId == _nftId && clamableRewards >= bestRewards) {
                poolInfo = stakingPools[i];
                bestRewards = clamableRewards;
            }
        }
      return poolInfo;
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
        uint poolId = poolInfo.poolId;
        return balances[poolId][_staker];
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
        uint poolId = poolInfo.poolId;
        uint rewards = rewardOf(poolId, _staker);
        return rewards;
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
        STAKE memory stakeDetail = balances[_poolId][_staker];

        // if staker is NOT staking the token anymore then rewards is 0
        // notice that lastClaimedAt is set at the time of stake event occuring, if user didnt staked anything then timePassed calculations would NOT be valid
        if (stakeDetail.amount == 0) return 0;

        POOL memory poolInfo = stakingPools[_poolId];

        uint256 timeNow = block.timestamp;
        // passed time in seconds since the last claim
        uint256 timePassed = timeNow - stakeDetail.lastClaimedAt;
        uint256 totalReward = stakeDetail.amount.mul(poolInfo.rewardPerNFT).mul(timePassed).div(poolInfo.rewardPeriod);

        // there can be a situation where someone is staking for a very long time and no one is claiming, then sudenly 1 person ruggs everyone
        // to solve this issue we force people to claim every time they accumulate maxPerClaim and thus available rewards don't suddenly go to 0
        if (totalReward > poolInfo.maxPerClaim) totalReward = poolInfo.maxPerClaim;
        if (totalReward > poolInfo.totalRewards) totalReward = poolInfo.totalRewards;
        return totalReward;
    }

    function claimReward(uint256 _poolId) public {
        uint256 reward = rewardOf(_poolId, _msgSender());
        POOL memory poolInfo = stakingPools[_poolId];
        STAKE storage balance = balances[_poolId][_msgSender()];

        _token.transfer(_msgSender(), reward);

        balance.lastClaimedAt = block.timestamp;
        balance.rewardSoFar = balance.rewardSoFar.add(reward);
        poolInfo.totalRewards = poolInfo.totalRewards.sub(reward);

        emit Withdraw(_poolId, _msgSender(), reward);
    }

    /**
     * @notice stake NFT
     * @param _poolId is the pool identifier
     * @param _amount is the NFT count to stake
     */
    function stake(uint256 _poolId, uint256 _amount) external {
        POOL memory poolInfo = stakingPools[_poolId];

        _nftToken.safeTransferFrom(_msgSender(), address(this), poolInfo.nftTokenId, _amount, '');

        STAKE storage balance = balances[_poolId][_msgSender()];

        if (balance.amount > 0) {
            uint256 reward = rewardOf(_poolId, _msgSender());

            _token.transfer(_msgSender(), reward);
            balance.rewardSoFar = balance.rewardSoFar.add(reward);
            poolInfo.totalRewards = poolInfo.totalRewards.sub(reward);

            emit Withdraw(_poolId, _msgSender(), reward);
        }
        if (balance.amount == 0) balance.firstStakedAt = block.timestamp;

        balance.lastClaimedAt = block.timestamp;
        balance.amount = balance.amount.add(_amount);
        stakingPools[_poolId].totalStakes = stakingPools[_poolId].totalStakes.add(_amount);

        emit Stake(_poolId, _msgSender(), _amount);
    }

    /**
     * @notice unstake current staking
     * @param _poolId is the pool identifier
     */
    function unstake(uint256 _poolId, uint256 _count) external {
        require(balances[_poolId][_msgSender()].amount > 0, 'Not staking');

        POOL memory poolInfo = stakingPools[_poolId];
        STAKE storage balance = balances[_poolId][_msgSender()];
        uint256 reward = rewardOf(_poolId, _msgSender()).div(balance.amount).mul(_count);

        _token.transfer(_msgSender(), reward);
        _nftToken.safeTransferFrom(address(this), _msgSender(), poolInfo.nftTokenId, _count, '');

        poolInfo.totalStakes = poolInfo.totalStakes.sub(_count);
        poolInfo.totalRewards = poolInfo.totalRewards.sub(reward);

        balance.amount = balance.amount.sub(_count);
        balance.rewardSoFar = balance.rewardSoFar.add(reward);

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
    function notifyRewards(uint256 _poolId, uint256 _amount) public onlyOwner {
        require(_amount > 0, "NFTStaking.notifyRewards: Can't add zero amount!");

        POOL storage poolInfo = stakingPools[_poolId];
        uint total = _token.balanceOf(address(this));
        uint reserved = getReservedRewards();

        require(total.sub(reserved) >= _amount, "NFTStaking.notifyRewards: Can't add more tokens than available");
        poolInfo.totalRewards = poolInfo.totalRewards.add(_amount);
    }

    /**
     * @notice function to claim staking rewards from the contract
     * @param poolId is the pool id to contribute reward
     * @param amount is the amount to claim
     */
    function withdrawRewards(uint256 poolId, uint256 amount) public onlyOwner {
        require(stakingPools[poolId].totalRewards >= amount, 'NFTStaking.withdrawRewards: Not enough remaining rewards!');
        POOL storage poolInfo = stakingPools[poolId];
        _token.transfer(_msgSender(), amount);
        poolInfo.totalRewards = poolInfo.totalRewards.sub(amount);
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
    ) public onlyOwner {
        uint256 poolId = stakingPoolsCount;
        require(_rewardPeriod > 0, "NFTStaking.addPool: Rewards period can NOT be 0");
        require(_maxPerClaim > 0, "NFTStaking.addPool: Rewards max per each claim can NOT be 0");
        require(stakingPools[poolId].rewardPerNFT == 0, 'NFTStaking.addPool: Pool already exists!');
        require(stakingPools[poolId].poolId == 0, 'NFTStaking.addPool: poolId already exists!');
        require(stakingPools[poolId].rewardPeriod == 0, 'NFTStaking.addPool: Pool already exists!');

        stakingPools[poolId] = POOL(poolId, _nftTokenId, 0, 0, _rewardPerNFT, _rewardPeriod, _maxPerClaim);
        stakingPoolsCount++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

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