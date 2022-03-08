// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICardHandler.sol";
import "../interfaces/IProjectHandler.sol";
import "../interfaces/IFeeReceiver.sol";
import "../general/BaseStructs.sol";

contract ProjectHandler is BaseStructs, IProjectHandler, Ownable {
  using SafeMath for uint256;

  mapping(uint256 => mapping(uint256 => RewardInfo[])) public rewardInfo;

  address public nftVillageChief;

  IFeeReceiver public override projectFeeRecipient;
  IFeeReceiver public override poolFeeRecipient;
  IFeeReceiver public override rewardFeeRecipient;
  uint256 public override projectFee;
  uint256 public override poolFee;
  uint256 public override rewardFee;

  ProjectInfo[] public projectInfo;
  ICardHandler public cardHandler;

  uint256 public constant FEE_DENOMINATOR = 10000;

  modifier onlyNFTVillageChief() {
    require(nftVillageChief == msg.sender, "ProjectHandler: Only NFTVillageChief");
    _;
  }

  event CardHandlerUpdate(address indexed oldHandler, address indexed newHandler);
  event ProjectFeeAndRecipientUpdated(address indexed recipient, uint256 indexed fee);
  event PoolFeeAndRecipientUpdated(address indexed recipient, uint256 indexed fee);
  event RewardFeeAndRecipientUpdated(address indexed recipient, uint256 indexed fee);

  constructor(
    address _nftVillageChief,
    address _owner,
    uint256 _projectFee,
    uint256 _poolFee,
    uint256 _rewardFee,
    address _projectFeeReceiver,
    address _poolFeeReceiver,
    address _rewardFeeReceiver
  ) {
    require(
      _nftVillageChief != address(0) &&
        _projectFeeReceiver != address(0) &&
        _poolFeeReceiver != address(0) &&
        _rewardFeeReceiver != address(0) &&
        _owner != address(0),
      "ProjectHandler: zero address"
    );

    nftVillageChief = _nftVillageChief;
    projectFee = _projectFee;
    poolFee = _poolFee;
    rewardFee = _rewardFee;

    projectFeeRecipient = IFeeReceiver(_projectFeeReceiver);
    poolFeeRecipient = IFeeReceiver(_poolFeeReceiver);
    rewardFeeRecipient = IFeeReceiver(_rewardFeeReceiver);

    transferOwnership(_owner);
  }

  function setCardHandler(ICardHandler _cardHandler) external override onlyNFTVillageChief {
    require(address(_cardHandler) != address(0), "ProjectHandler: _cardHandler is zero address");
    emit CardHandlerUpdate(address(cardHandler), address(_cardHandler));
    cardHandler = _cardHandler;
  }

  function initializeProject(uint256 projectId) external override {
    ProjectInfo storage project = projectInfo[projectId];
    require(project.admin == msg.sender, "ProjectHandler: Only Project Admin!");
    require(!project.initialized, "ProjectHandler: Project already initialized!");
    project.initialized = true;
    project.paused = false;
    project.startBlock = block.number;
    uint256 length = project.pools.length;
    for (uint256 p = 0; p < length; ++p) {
      RewardInfo[] storage rewardTokens = rewardInfo[projectId][p];
      for (uint256 r = 0; r < rewardTokens.length; r++) {
        rewardTokens[r].lastRewardBlock = project.startBlock;
      }
    }
  }

  function addProject(
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    uint256 _startBlock,
    INFTVillageCards _poolCards
  ) external payable override onlyOwner {
    require(_admin != address(0), "ProjectHandler: Invalid Admin!");
    require(msg.value == projectFee, "ProjectHandler: Invalid Project Fee!");

    uint256 fee = address(this).balance;
    projectFeeRecipient.onFeeReceived{value: fee}(address(0), fee);

    projectInfo.push();
    ProjectInfo storage project = projectInfo[projectInfo.length - 1];
    project.paused = true;
    project.admin = _admin;
    project.adminReward = _adminReward;
    project.referralFee = _referralFee;
    project.startBlock = _startBlock == 0 ? block.number : _startBlock;
    cardHandler.setPoolCard(projectInfo.length - 1, _poolCards);
  }

  function setProject(
    uint256 projectId,
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    INFTVillageCards _poolCards
  ) external override {
    ProjectInfo storage project = projectInfo[projectId];
    require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");
    require(_admin != address(0), "ProjectHandler: Invalid Admin!");

    project.admin = _admin;
    project.adminReward = _adminReward;
    project.referralFee = _referralFee;
    cardHandler.setPoolCard(projectId, _poolCards);
  }

  function addPool(
    uint256 projectId,
    PoolInfo memory _pool,
    RewardInfo[] memory _rewardInfo,
    NftDeposit[] memory _requiredCards
  ) external payable override {
    ProjectInfo storage project = projectInfo[projectId];
    require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");
    require(msg.value == poolFee, "ProjectHandler: Invalid Pool Fee!");

    uint256 fee = address(this).balance;
    poolFeeRecipient.onFeeReceived{value: fee}(address(0), fee);

    require(
      _pool.stakedToken != address(0) || TokenStandard(_pool.stakedTokenStandard) == TokenStandard.NONE,
      "ProjectHandler: stakedToken is a zero address"
    );
    require(_pool.stakedTokenStandard < 4, "ProjectHandler: Invalid stakedTokenStandard");
    _pool.stakedAmount = 0;
    _pool.totalShares = 0;
    project.pools.push(_pool);
    for (uint256 i = 0; i < _rewardInfo.length; i++) {
      _rewardInfo[i].accRewardPerShare = 0;
      _rewardInfo[i].supply = 0;
      _rewardInfo[i].lastRewardBlock = block.number > project.startBlock ? block.number : project.startBlock;
      rewardInfo[projectId][project.pools.length - 1].push(_rewardInfo[i]);
    }
    cardHandler.addPoolRequiredCards(projectId, project.pools.length - 1, _requiredCards);
  }

  function setPool(
    uint256 projectId,
    uint256 poolId,
    PoolInfo calldata _pool,
    RewardInfo[] memory _rewardInfo
  ) external override {
    ProjectInfo storage project = projectInfo[projectId];
    PoolInfo storage pool = project.pools[poolId];
    require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");

    pool.lockDeposit = _pool.lockDeposit;
    pool.minDeposit = _pool.minDeposit;
    pool.depositFee = _pool.depositFee;
    pool.harvestInterval = _pool.harvestInterval;
    pool.minWithdrawlFee = _pool.minWithdrawlFee;
    pool.maxWithdrawlFee = _pool.maxWithdrawlFee;
    pool.withdrawlFeeReliefInterval = _pool.withdrawlFeeReliefInterval;
    pool.minRequiredCards = _pool.minRequiredCards;

    RewardInfo[] storage __rewardInfo = rewardInfo[projectId][poolId];
    for (uint256 i = 0; i < _rewardInfo.length; i++) {
      if (i < __rewardInfo.length) {
        require(_rewardInfo[i].token == __rewardInfo[i].token, "ProjectHandler: Invalid reward info!");
        __rewardInfo[i].paused = _rewardInfo[i].paused;
        __rewardInfo[i].mintable = _rewardInfo[i].mintable;
        __rewardInfo[i].rewardPerBlock = _rewardInfo[i].rewardPerBlock;
      } else {
        _rewardInfo[i].accRewardPerShare = 0;
        _rewardInfo[i].supply = 0;
        _rewardInfo[i].lastRewardBlock = block.number > project.startBlock ? block.number : project.startBlock;
        rewardInfo[projectId][poolId].push(_rewardInfo[i]);
      }
    }
  }

  function setPoolShares(
    uint256 projectId,
    uint256 poolId,
    uint256 shares
  ) external override onlyNFTVillageChief {
    projectInfo[projectId].pools[poolId].totalShares = shares;
  }

  function setStakedAmount(
    uint256 projectId,
    uint256 poolId,
    uint256 amount
  ) external override onlyNFTVillageChief {
    projectInfo[projectId].pools[poolId].stakedAmount = amount;
  }

  function setRewardPerBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 rewardPerBlock
  ) external override onlyNFTVillageChief {
    rewardInfo[projectId][poolId][rewardId].rewardPerBlock = rewardPerBlock;
  }

  function setLastRewardBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 lastRewardBlock
  ) external override onlyNFTVillageChief {
    rewardInfo[projectId][poolId][rewardId].lastRewardBlock = lastRewardBlock;
  }

  function setRewardPerShare(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 accRewardPerShare
  ) external override onlyNFTVillageChief {
    rewardInfo[projectId][poolId][rewardId].accRewardPerShare = accRewardPerShare;
  }

  function setRewardSupply(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 supply
  ) external override onlyNFTVillageChief {
    rewardInfo[projectId][poolId][rewardId].supply = supply;
  }

  function setProjectFeeAndRecipient(IFeeReceiver recipient, uint256 fee) external onlyOwner {
    require(address(recipient) != address(0), "ProjectHandler: recipient is zero address");
    projectFeeRecipient = recipient;
    projectFee = fee;
    emit ProjectFeeAndRecipientUpdated(address(recipient), fee);
  }

  function setPoolFeeAndRecipient(IFeeReceiver recipient, uint256 fee) external onlyOwner {
    require(address(recipient) != address(0), "ProjectHandler: recipient is zero address");
    poolFeeRecipient = recipient;
    poolFee = fee;
    emit PoolFeeAndRecipientUpdated(address(recipient), fee);
  }

  function setRewardFeeAndRecipient(IFeeReceiver recipient, uint256 fee) external onlyOwner {
    require(address(recipient) != address(0), "ProjectHandler: recipient is zero address");
    rewardFeeRecipient = recipient;
    rewardFee = fee;
    emit RewardFeeAndRecipientUpdated(address(recipient), fee);
  }

  function addPoolRequiredCards(
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata requiredCards
  ) external {
    ProjectInfo storage project = projectInfo[projectId];
    require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");
    cardHandler.addPoolRequiredCards(projectId, poolId, requiredCards);
  }

  function removePoolRequiredCard(
    uint256 projectId,
    uint256 poolId,
    uint256 tokenId
  ) external {
    ProjectInfo storage project = projectInfo[projectId];
    require(msg.sender == project.admin, "ProjectHandler: Only Project Admin!");
    cardHandler.removePoolRequiredCard(projectId, poolId, tokenId);
  }

  function projectLength() external view override returns (uint256) {
    return projectInfo.length;
  }

  function projectPoolLength(uint256 projectId) external view override returns (uint256) {
    return projectInfo[projectId].pools.length;
  }

  function getProjectInfo(uint256 projectId) external view override returns (ProjectInfo memory) {
    return projectInfo[projectId];
  }

  function getPoolInfo(uint256 projectId, uint256 poolId) external view override returns (PoolInfo memory) {
    return projectInfo[projectId].pools[poolId];
  }

  function getRewardInfo(uint256 projectId, uint256 poolId) external view override returns (RewardInfo[] memory) {
    return rewardInfo[projectId][poolId];
  }

  function pendingRewards(
    uint256 projectId,
    uint256 poolId,
    UserInfo calldata user,
    UserRewardInfo[] calldata userReward
  ) external view override onlyNFTVillageChief returns (uint256[] memory) {
    ProjectInfo storage project = projectInfo[projectId];
    PoolInfo storage pool = project.pools[poolId];
    uint256[] memory rewards = new uint256[](rewardInfo[projectId][poolId].length);
    // if user is not a staker, just return emtpy array of rewards
    if (userReward.length == 0) return rewards;
    // if user reward list is not updated, the client must call the deposit method in spacemoon contract first before using this function
    require(userReward.length == rewards.length, "ProjectHandler: The user reward list is not updated!");
    for (uint256 i = 0; i < rewardInfo[projectId][poolId].length; i++) {
      RewardInfo storage _rewardInfo = rewardInfo[projectId][poolId][i];
      uint256 accRewardPerShare = _rewardInfo.accRewardPerShare;
      if (
        block.number > _rewardInfo.lastRewardBlock &&
        pool.totalShares != 0 &&
        (_rewardInfo.supply > 0 || _rewardInfo.mintable)
      ) {
        uint256 multiplier = block.number.sub(_rewardInfo.lastRewardBlock);
        uint256 rewardAmount = multiplier.mul(_rewardInfo.rewardPerBlock);
        uint256 devFee = rewardAmount.mul(project.rewardFee).div(FEE_DENOMINATOR);
        uint256 adminFee = rewardAmount.mul(project.adminReward).div(FEE_DENOMINATOR);
        uint256 totalRewards = rewardAmount.add(devFee).add(adminFee);
        if (!_rewardInfo.mintable && _rewardInfo.supply < totalRewards) {
          rewardAmount =
            (FEE_DENOMINATOR * _rewardInfo.supply) /
            (FEE_DENOMINATOR + project.adminReward + project.rewardFee);
          devFee = rewardAmount.mul(project.rewardFee).div(FEE_DENOMINATOR);
          adminFee = rewardAmount.mul(project.adminReward).div(FEE_DENOMINATOR);
          rewardAmount = _rewardInfo.supply - devFee - adminFee;
        }
        accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(1e12).div(pool.totalShares));
      }
      rewards[i] = user.shares.mul(accRewardPerShare).div(1e12).sub(userReward[i].rewardDebt);
    }
    return rewards;
  }

  function drainAccidentallySentTokens(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.transfer(recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "./INFTVillageCards.sol";
import "../general/BaseStructs.sol";

pragma solidity ^0.8.0;

interface ICardHandler is BaseStructs {
  function setProjectHandler(address _projectHandler) external;

  function ERC721Transferfrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) external;

  function ERC1155Transferfrom(
    address token,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  function getUserCardsInfo(
    uint256 projectId,
    uint256 poolId,
    address account
  ) external view returns (NftDepositInfo memory);

  function getPoolRequiredCards(uint256 projectId, uint256 poolId) external view returns (NftDeposit[] memory);

  function setPoolCard(uint256 _projectId, INFTVillageCards _poolcard) external;

  function addPoolRequiredCards(
    uint256 _projectId,
    uint256 _poolId,
    NftDeposit[] calldata _requiredCards
  ) external;

  function removePoolRequiredCard(
    uint256 _projectId,
    uint256 _poolId,
    uint256 _tokenId
  ) external;

  function useCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external returns (uint256);

  function withdrawCard(
    address user,
    uint8 cardType,
    uint256 projectId,
    uint256 poolId,
    NftDeposit[] calldata cards
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ICardHandler.sol";
import "./IFeeReceiver.sol";
import "../general/BaseStructs.sol";

interface IProjectHandler is BaseStructs {
  function setCardHandler(ICardHandler _cardHandler) external;

  function initializeProject(uint256 projectId) external;

  function getRewardInfo(uint256 projectId, uint256 poolId) external returns (RewardInfo[] calldata);

  function projectFeeRecipient() external returns (IFeeReceiver);

  function poolFeeRecipient() external returns (IFeeReceiver);

  function rewardFeeRecipient() external returns (IFeeReceiver);

  function projectFee() external returns (uint256);

  function poolFee() external returns (uint256);

  function rewardFee() external returns (uint256);

  function getProjectInfo(uint256 projectId) external returns (ProjectInfo memory);

  function projectLength() external view returns (uint256);

  function projectPoolLength(uint256 projectId) external view returns (uint256);

  function getPoolInfo(uint256 projectId, uint256 poolId) external view returns (PoolInfo memory);

  function addProject(
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    uint256 _startBlock,
    INFTVillageCards _poolCards
  ) external payable;

  function setProject(
    uint256 projectId,
    address _admin,
    uint256 _adminReward,
    uint256 _referralFee,
    INFTVillageCards _poolCards
  ) external;

  function addPool(
    uint256 projectId,
    PoolInfo memory _pool,
    RewardInfo[] memory _rewardInfo,
    NftDeposit[] calldata _requiredCards
  ) external payable;

  function setPool(
    uint256 projectId,
    uint256 poolId,
    PoolInfo calldata _pool,
    RewardInfo[] memory _rewardInfo
  ) external;

  function setPoolShares(
    uint256 projectId,
    uint256 poolId,
    uint256 shares
  ) external;

  function setStakedAmount(
    uint256 projectId,
    uint256 poolId,
    uint256 amount
  ) external;

  function setRewardPerBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 rewardPerBlock
  ) external;

  function setLastRewardBlock(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 lastRewardBlock
  ) external;

  function setRewardPerShare(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 accRewardPerShare
  ) external;

  function setRewardSupply(
    uint256 projectId,
    uint256 poolId,
    uint256 rewardId,
    uint256 supply
  ) external;

  function pendingRewards(
    uint256 projectId,
    uint256 poolId,
    UserInfo memory user,
    UserRewardInfo[] calldata userReward
  ) external view returns (uint256[] calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeReceiver {
  function onFeeReceived(address token, uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20Mintable.sol";
import "../interfaces/INFTVillageCards.sol";

interface BaseStructs {
  enum CardType {
    REQUIRED,
    FEE_DISCOUNT,
    HARVEST_RELIEF,
    MULTIPLIER
  }

  enum TokenStandard {
    ERC20,
    ERC721,
    ERC1155,
    NONE
  }

  struct NftDeposit {
    uint256 tokenId;
    uint256 amount;
  }

  struct NftDepositInfo {
    NftDeposit[] required;
    NftDeposit[] feeDiscount;
    NftDeposit[] harvest;
    NftDeposit[] multiplier;
  }

  struct ProjectInfo {
    address admin;
    uint256 adminReward;
    uint256 referralFee;
    uint256 rewardFee;
    uint256 startBlock;
    bool initialized;
    bool paused;
    INFTVillageCards cards;
    PoolInfo[] pools;
  }

  struct PoolInfo {
    address stakedToken;
    bool lockDeposit;
    uint8 stakedTokenStandard;
    uint256 stakedTokenId;
    uint256 stakedAmount;
    uint256 totalShares;
    uint16 depositFee;
    uint16 minWithdrawlFee;
    uint16 maxWithdrawlFee;
    uint16 withdrawlFeeReliefInterval;
    uint256 minDeposit;
    uint256 harvestInterval;
    uint256 minRequiredCards;
  }

  struct RewardInfo {
    IERC20Mintable token;
    bool paused;
    bool mintable;
    uint256 rewardPerBlock;
    uint256 lastRewardBlock;
    uint256 accRewardPerShare;
    uint256 supply;
  }

  struct UserInfo {
    uint256 amount;
    uint256 shares;
    uint256 shareMultiplier;
    uint256 canHarvestAt;
    uint256 harvestRelief;
    uint256 withdrawFeeDiscount;
    uint256 depositFeeDiscount;
    uint256 stakedTimestamp;
  }

  struct UserRewardInfo {
    uint256 rewardDebt;
    uint256 rewardLockedUp;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./INFTVillageCardFeatures.sol";

abstract contract INFTVillageCards is INFTVillageCardFeatures, IERC1155 {}

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract INFTVillageCardFeatures {
  function addHarvestReliefCard(uint256 _tokenId, uint256 _harvestRelief) external virtual;

  function addFeeDiscountCard(uint256 _tokenId, uint256 _feeDiscount) external virtual;

  function addMultiplierCard(uint256 _tokenId, uint256 _multiplier) external virtual;

  function removeHarvestReliefCard(uint256 _tokenId) external virtual;

  function removeFeeDiscountCard(uint256 _tokenId) external virtual;

  function removeMultiplierCard(uint256 _tokenId) external virtual;

  function getHarvestReliefCards() external view virtual returns (uint256[] memory);

  function getFeeDiscountCards() external view virtual returns (uint256[] memory);

  function getMultiplierCards() external view virtual returns (uint256[] memory);

  function getHarvestRelief(uint256 id) external virtual returns (uint256);

  function getFeeDiscount(uint256 id) external virtual returns (uint256);

  function getMultiplier(uint256 id) external virtual returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external;

  function transferOwnership(address newOwner) external;
}