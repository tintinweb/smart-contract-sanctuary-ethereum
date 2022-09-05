// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "../ERC20Testnet.sol";
import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IConvexPoolFactory } from "./ConvexPoolFactory.sol";
import { IConvexTokenFactory } from "./ConvexTokenFactory.sol";

contract Booster {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public crv;
  address public constant registry =
    address(0x0000000022D53366457F9d5E68Ec105046FC4383);
  uint256 public constant distributionAddressId = 4;
  address public constant voteOwnership =
    address(0xE478de485ad2fe566d49342Cbd03E49ed7DB3356);
  address public constant voteParameter =
    address(0xBCfF8B0b9419b9A88c44546519b1e909cF330399);

  uint256 public lockIncentive = 1000; //incentive to crv stakers
  uint256 public stakerIncentive = 450; //incentive to native token stakers
  uint256 public earmarkIncentive = 50; //incentive to users who spend gas to make calls
  uint256 public platformFee = 0; //possible fee to build treasury
  uint256 public constant MaxFees = 2000;
  uint256 public constant FEE_DENOMINATOR = 10000;

  address public owner;
  address public feeManager;
  address public poolManager;
  address public immutable staker;
  address public immutable minter;
  address public rewardFactory;
  address public stashFactory;
  address public tokenFactory;
  address public rewardArbitrator;
  address public voteDelegate;
  address public treasury;
  address public stakerRewards; //cvx rewards
  address public lockRewards; //cvxCrv rewards(crv)
  address public lockFees; //cvxCrv vecrv fees
  address public feeDistro;
  address public feeToken;

  bool public isShutdown;

  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  //index(pid) -> pool
  mapping(uint256 => PoolInfo) public poolInfo;
  mapping(address => bool) public gaugeMap;

  event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
  event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

  constructor(address _minter, address _crv) public {
    isShutdown = false;
    staker = address(0);
    owner = msg.sender;
    voteDelegate = msg.sender;
    feeManager = msg.sender;
    poolManager = msg.sender;
    feeDistro = address(0);
    feeToken = address(0);
    treasury = address(0);
    minter = _minter;
    crv = _crv;
  }

  /// SETTER SECTION ///

  function setOwner(address _owner) external {
    require(msg.sender == owner, "!auth");
    owner = _owner;
  }

  function setFeeManager(address _feeM) external {
    require(msg.sender == feeManager, "!auth");
    feeManager = _feeM;
  }

  function setPoolManager(address _poolM) external {
    require(msg.sender == poolManager, "!auth");
    poolManager = _poolM;
  }

  function setFactories(address _poolFactory, address _tokenFactory) external {
    require(msg.sender == owner, "!auth");
    rewardFactory = _poolFactory;
    tokenFactory = _tokenFactory;
  }

  /// END SETTER SECTION ///

  function poolLength() external view returns (uint256) {
    revert("Not implemented");
  }

  //create a new pool
  function addPool(address _lpToken, uint256 _pid) external returns (address) {
    require(msg.sender == poolManager, "!add");

    //the next pool's pid
    uint256 pid = _pid;

    string memory name = string(
      abi.encodePacked("Convex ", IERC20Metadata(_lpToken).name())
    );
    string memory symbol = string(
      abi.encodePacked("cvx", IERC20Metadata(_lpToken).symbol())
    );

    address token = IConvexTokenFactory(tokenFactory).deployPoolToken(
      name,
      symbol,
      18
    );

    address pool = IConvexPoolFactory(rewardFactory).deployBasePool(
      pid,
      token,
      crv,
      address(this),
      owner
    );

    poolInfo[pid] = PoolInfo({
      lptoken: _lpToken,
      token: token,
      gauge: address(0),
      crvRewards: pool,
      stash: address(0),
      shutdown: false
    });

    return pool;
  }

  //shutdown pool
  function shutdownPool(uint256 _pid) external returns (bool) {
    require(msg.sender == poolManager, "!auth");
    PoolInfo storage pool = poolInfo[_pid];

    //withdraw from gauge
    try IStaker(staker).withdrawAll(pool.lptoken, pool.gauge) {} catch {}

    pool.shutdown = true;
    gaugeMap[pool.gauge] = false;
    return true;
  }

  //shutdown this contract.
  //  unstake and pull all lp tokens to this address
  //  only allow withdrawals
  function shutdownSystem() external {
    revert("Not implemented");
  }

  //deposit lp tokens and stake
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) public returns (bool) {
    require(!isShutdown, "shutdown");
    PoolInfo storage pool = poolInfo[_pid];
    require(pool.shutdown == false, "pool is closed");

    //send to proxy to stake
    address lptoken = pool.lptoken;
    IERC20(lptoken).safeTransferFrom(msg.sender, staker, _amount);

    address token = pool.token;
    if (_stake) {
      //mint here and send to rewards on user behalf
      ITokenMinter(token).mint(address(this), _amount);
      address rewardContract = pool.crvRewards;
      IERC20(token).safeApprove(rewardContract, 0);
      IERC20(token).safeApprove(rewardContract, _amount);
      IRewards(rewardContract).stakeFor(msg.sender, _amount);
    } else {
      //add user balance directly
      ITokenMinter(token).mint(msg.sender, _amount);
    }

    emit Deposited(msg.sender, _pid, _amount);
    return true;
  }

  //deposit all lp tokens and stake
  function depositAll(uint256 _pid, bool _stake) external returns (bool) {
    address lptoken = poolInfo[_pid].lptoken;
    uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
    deposit(_pid, balance, _stake);
    return true;
  }

  //withdraw lp tokens
  function _withdraw(
    uint256 _pid,
    uint256 _amount,
    address _from,
    address _to
  ) internal {
    PoolInfo storage pool = poolInfo[_pid];
    address lptoken = pool.lptoken;

    //remove lp balance
    address token = pool.token;
    ITokenMinter(token).burn(_from, _amount);

    //return lp tokens
    IERC20(lptoken).safeTransfer(_to, _amount);

    emit Withdrawn(_to, _pid, _amount);
  }

  //withdraw lp tokens
  function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
    _withdraw(_pid, _amount, msg.sender, msg.sender);
    return true;
  }

  //withdraw all lp tokens
  function withdrawAll(uint256 _pid) public returns (bool) {
    address token = poolInfo[_pid].token;
    uint256 userBal = IERC20(token).balanceOf(msg.sender);
    withdraw(_pid, userBal);
    return true;
  }

  //allow reward contracts to send here and withdraw to user
  function withdrawTo(
    uint256 _pid,
    uint256 _amount,
    address _to
  ) external returns (bool) {
    address rewardContract = poolInfo[_pid].crvRewards;
    require(msg.sender == rewardContract, "!auth");

    _withdraw(_pid, _amount, msg.sender, _to);
    return true;
  }

  //delegate address votes on dao
  function vote(
    uint256 _voteId,
    address _votingAddress,
    bool _support
  ) external returns (bool) {
    revert("Not implemented");
  }

  function voteGaugeWeight(
    address[] calldata _gauge,
    uint256[] calldata _weight
  ) external returns (bool) {
    revert("Not implemented");
  }

  function claimRewards(uint256 _pid, address _gauge) external returns (bool) {
    revert("Not implemented");
  }

  function setGaugeRedirect(uint256 _pid) external returns (bool) {
    revert("Not implemented");
  }

  //claim crv and extra rewards and disperse to reward contracts
  function _earmarkRewards(uint256 _pid) internal {
    revert("Not implemented");
  }

  function earmarkRewards(uint256 _pid) external returns (bool) {
    revert("Not implemented");
  }

  //claim fees from curve distro contract, put in lockers' reward contract
  function earmarkFees() external returns (bool) {
    revert("Not implemented");
  }

  //callback from reward contract when crv is received.
  function rewardClaimed(
    uint256 _pid,
    address _address,
    uint256 _amount
  ) external returns (bool) {
    address rewardContract = poolInfo[_pid].crvRewards;
    require(msg.sender == rewardContract || msg.sender == lockRewards, "!auth");

    //mint reward tokens
    ITokenMinter(minter).mint(_address, _amount);

    return true;
  }
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Testnet is ERC20, Ownable {
  uint8 public immutable _decimals;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _dec
  ) ERC20(_name, _symbol) {
    _mint(msg.sender, 1e24);
    _decimals = _dec;
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyOwner {
    _burn(from, amount);
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICurveGauge {
  function deposit(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function withdraw(uint256) external;

  function claim_rewards() external;

  function reward_tokens(uint256) external view returns (address); //v2

  function rewarded_token() external view returns (address); //v1

  function lp_token() external view returns (address);
}

interface ICurveVoteEscrow {
  function create_lock(uint256, uint256) external;

  function increase_amount(uint256) external;

  function increase_unlock_time(uint256) external;

  function withdraw() external;

  function smart_wallet_checker() external view returns (address);
}

interface IWalletChecker {
  function check(address) external view returns (bool);
}

interface IVoting {
  function vote(
    uint256,
    bool,
    bool
  ) external; //voteId, support, executeIfDecided

  function getVote(uint256)
    external
    view
    returns (
      bool,
      bool,
      uint64,
      uint64,
      uint64,
      uint64,
      uint256,
      uint256,
      uint256,
      bytes memory
    );

  function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
  function mint(address) external;
}

interface IRegistry {
  function get_registry() external view returns (address);

  function get_address(uint256 _id) external view returns (address);

  function gauge_controller() external view returns (address);

  function get_lp_token(address) external view returns (address);

  function get_gauges(address)
    external
    view
    returns (address[10] memory, uint128[10] memory);
}

interface IStaker {
  function deposit(address, address) external;

  function withdraw(address) external;

  function withdraw(
    address,
    address,
    uint256
  ) external;

  function withdrawAll(address, address) external;

  function createLock(uint256, uint256) external;

  function increaseAmount(uint256) external;

  function increaseTime(uint256) external;

  function release() external;

  function claimCrv(address) external returns (uint256);

  function claimRewards(address) external;

  function claimFees(address, address) external;

  function setStashAccess(address, bool) external;

  function vote(
    uint256,
    address,
    bool
  ) external;

  function voteGaugeWeight(address, uint256) external;

  function balanceOfPool(address) external view returns (uint256);

  function operator() external view returns (address);

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external returns (bool, bytes memory);
}

interface IRewards {
  function stake(address, uint256) external;

  function stakeFor(address, uint256) external;

  function withdraw(address, uint256) external;

  function exit(address) external;

  function getReward(address) external;

  function queueNewRewards(uint256) external;

  function notifyRewardAmount(uint256) external;

  function addExtraReward(address) external;

  function stakingToken() external view returns (address);

  function rewardToken() external view returns (address);

  function earned(address account) external view returns (uint256);
}

interface IStash {
  function stashRewards() external returns (bool);

  function processStash() external returns (bool);

  function claimRewards() external returns (bool);

  function initialize(
    uint256 _pid,
    address _operator,
    address _staker,
    address _gauge,
    address _rewardFactory
  ) external;
}

interface IFeeDistro {
  function claim() external;

  function token() external view returns (address);
}

interface ITokenMinter {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

interface IDeposit {
  function isShutdown() external view returns (bool);

  function balanceOf(address _account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  function rewardClaimed(
    uint256,
    address,
    uint256
  ) external;

  function withdrawTo(
    uint256,
    uint256,
    address
  ) external;

  function claimRewards(uint256, address) external returns (bool);

  function rewardArbitrator() external returns (address);

  function setGaugeRedirect(uint256 _pid) external returns (bool);

  function owner() external returns (address);
}

interface ICrvDeposit {
  function deposit(uint256, bool) external;

  function lockIncentive() external view returns (uint256);
}

interface IRewardFactory {
  function setAccess(address, bool) external;

  function CreateCrvRewards(uint256, address) external returns (address);

  function CreateTokenRewards(
    address,
    address,
    address
  ) external returns (address);

  function activeRewardCount(address) external view returns (uint256);

  function addActiveReward(address, uint256) external returns (bool);

  function removeActiveReward(address, uint256) external returns (bool);
}

interface IStashFactory {
  function CreateStash(
    uint256,
    address,
    address,
    uint256
  ) external returns (address);
}

interface ITokenFactory {
  function CreateDepositToken(address) external returns (address);
}

interface IPools {
  function addPool(
    address _lptoken,
    address _gauge,
    uint256 _stashVersion
  ) external returns (bool);

  function forceAddPool(
    address _lptoken,
    address _gauge,
    uint256 _stashVersion
  ) external returns (bool);

  function shutdownPool(uint256 _pid) external returns (bool);

  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  function poolLength() external view returns (uint256);

  function gaugeMap(address) external view returns (bool);

  function setPoolManager(address _poolM) external;
}

interface IVestedEscrow {
  function fund(address[] calldata _recipient, uint256[] calldata _amount)
    external
    returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { BaseRewardPool } from "./ConvexBaseRewardPool.sol";
import { VirtualBalanceRewardPool } from "./ConvexVirtualBalanceRewardPool.sol";

interface IConvexPoolFactory {
  function deployBasePool(
    uint256 _pid,
    address _stakingToken,
    address _rewardToken,
    address _operator,
    address _manager
  ) external returns (address);

  function deployExtraPool(
    address _basePool,
    address _rewardToken,
    address _operator,
    address _manager
  ) external returns (address);
}

contract ConvexPoolFactory is IConvexPoolFactory {
  function deployBasePool(
    uint256 _pid,
    address _stakingToken,
    address _rewardToken,
    address _operator,
    address _manager
  ) external returns (address) {
    return
      address(
        new BaseRewardPool(
          _pid,
          _stakingToken,
          _rewardToken,
          _operator,
          _manager
        )
      );
  }

  function deployExtraPool(
    address _basePool,
    address _rewardToken,
    address _operator,
    address _manager
  ) external returns (address) {
    return
      address(
        new VirtualBalanceRewardPool(
          _basePool,
          _rewardToken,
          _operator,
          _manager
        )
      );
  }
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20Testnet.sol";

interface IConvexTokenFactory {
  function deployPoolToken(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) external returns (address);
}

contract ConvexTokenFactory is IConvexTokenFactory {
  function deployPoolToken(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) external returns (address) {
    address token = address(new ERC20Testnet(name, symbol, decimals));
    Ownable(token).transferOwnership(msg.sender);
    return token;
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library MathUtil {
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract BaseRewardPool {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public rewardToken;
  IERC20 public stakingToken;
  uint256 public constant duration = 7 days;

  address public operator;
  address public rewardManager;

  uint256 public pid;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public queuedRewards = 0;
  uint256 public currentRewards = 0;
  uint256 public historicalRewards = 0;
  uint256 public constant newRewardRatio = 830;
  uint256 private _totalSupply;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) private _balances;

  address[] public extraRewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  constructor(
    uint256 pid_,
    address stakingToken_,
    address rewardToken_,
    address operator_,
    address manager_
  ) public {
    pid = pid_;
    stakingToken = IERC20(stakingToken_);
    rewardToken = IERC20(rewardToken_);
    operator = operator_;
    rewardManager = manager_;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function extraRewardsLength() external view returns (uint256) {
    return extraRewards.length;
  }

  function addExtraReward(address _reward) external returns (bool) {
    require(msg.sender == rewardManager, "!authorized");
    require(_reward != address(0), "!reward setting");

    extraRewards.push(_reward);
    return true;
  }

  function clearExtraRewards() external {
    require(msg.sender == rewardManager, "!authorized");
    delete extraRewards;
  }

  modifier updateReward(address account) {
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return MathUtil.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    return rewardPerTokenStored;
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function stake(uint256 _amount)
    public
    updateReward(msg.sender)
    returns (bool)
  {
    require(_amount > 0, "RewardPool : Cannot stake 0");

    //also stake to linked rewards
    for (uint256 i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).stake(msg.sender, _amount);
    }

    _totalSupply = _totalSupply.add(_amount);
    _balances[msg.sender] = _balances[msg.sender].add(_amount);

    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(msg.sender, _amount);

    return true;
  }

  function stakeAll() external returns (bool) {
    uint256 balance = stakingToken.balanceOf(msg.sender);
    stake(balance);
    return true;
  }

  function stakeFor(address _for, uint256 _amount)
    public
    updateReward(_for)
    returns (bool)
  {
    require(_amount > 0, "RewardPool : Cannot stake 0");

    //also stake to linked rewards
    for (uint256 i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).stake(_for, _amount);
    }

    //give to _for
    _totalSupply = _totalSupply.add(_amount);
    _balances[_for] = _balances[_for].add(_amount);

    //take away from sender
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(_for, _amount);

    return true;
  }

  function withdraw(uint256 amount, bool claim)
    public
    updateReward(msg.sender)
    returns (bool)
  {
    require(amount > 0, "RewardPool : Cannot withdraw 0");

    //also withdraw from linked rewards
    for (uint256 i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).withdraw(msg.sender, amount);
    }

    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);

    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);

    if (claim) {
      getReward(msg.sender, true);
    }

    return true;
  }

  function withdrawAll(bool claim) external {
    withdraw(_balances[msg.sender], claim);
  }

  function withdrawAndUnwrap(uint256 amount, bool claim)
    public
    updateReward(msg.sender)
    returns (bool)
  {
    //also withdraw from linked rewards
    for (uint256 i = 0; i < extraRewards.length; i++) {
      IRewards(extraRewards[i]).withdraw(msg.sender, amount);
    }

    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);

    //tell operator to withdraw from here directly to user
    IDeposit(operator).withdrawTo(pid, amount, msg.sender);
    emit Withdrawn(msg.sender, amount);

    //get rewards too
    if (claim) {
      getReward(msg.sender, true);
    }
    return true;
  }

  function withdrawAllAndUnwrap(bool claim) external {
    withdrawAndUnwrap(_balances[msg.sender], claim);
  }

  function getReward(address _account, bool _claimExtras)
    public
    updateReward(_account)
    returns (bool)
  {
    uint256 reward = earned(_account);
    if (reward > 0) {
      rewards[_account] = 0;
      rewardToken.safeTransfer(_account, reward);
      IDeposit(operator).rewardClaimed(pid, _account, reward);
      emit RewardPaid(_account, reward);
    }

    //also get rewards from linked rewards
    if (_claimExtras) {
      for (uint256 i = 0; i < extraRewards.length; i++) {
        IRewards(extraRewards[i]).getReward(_account);
      }
    }
    return true;
  }

  function getReward() external returns (bool) {
    getReward(msg.sender, true);
    return true;
  }

  function donate(uint256 _amount) external returns (bool) {
    revert("Not implemented");
  }

  function queueNewRewards(uint256 _rewards) external returns (bool) {
    revert("Not implemented");
  }

  function notifyRewardAmount(uint256 reward)
    internal
    updateReward(address(0))
  {
    revert("Not implemented");
  }

  function sync(
    uint256 _periodFinish,
    uint256 _rewardRate,
    uint256 _lastUpdateTime,
    uint256 _rewardPerTokenStored,
    uint256 _queuedRewards,
    uint256 _currentRewards,
    uint256 _historicalRewards
  ) external {
    require(msg.sender == rewardManager, "!authorized");
    periodFinish = _periodFinish;
    rewardRate = _rewardRate;
    lastUpdateTime = _lastUpdateTime;
    rewardPerTokenStored = _rewardPerTokenStored;
    queuedRewards = _queuedRewards;
    currentRewards = _currentRewards;
    historicalRewards = _historicalRewards;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library MathUtil {
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract VirtualBalanceWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IDeposit public deposits;

  function totalSupply() public view returns (uint256) {
    return deposits.totalSupply();
  }

  function balanceOf(address account) public view returns (uint256) {
    return deposits.balanceOf(account);
  }
}

contract VirtualBalanceRewardPool is VirtualBalanceWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public rewardToken;
  uint256 public constant duration = 7 days;

  address public operator;
  address public manager;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public queuedRewards = 0;
  uint256 public currentRewards = 0;
  uint256 public historicalRewards = 0;
  uint256 public newRewardRatio = 830;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  constructor(
    address deposit_,
    address reward_,
    address op_,
    address manager_
  ) public {
    deposits = IDeposit(deposit_);
    rewardToken = IERC20(reward_);
    operator = op_;
    manager = manager_;
  }

  modifier updateReward(address account) {
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return MathUtil.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    return rewardPerTokenStored;
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  //update reward, emit, call linked reward's stake
  function stake(address _account, uint256 amount)
    external
    updateReward(_account)
  {
    require(msg.sender == address(deposits), "!authorized");
    // require(amount > 0, 'VirtualDepositRewardPool: Cannot stake 0');
    emit Staked(_account, amount);
  }

  function withdraw(address _account, uint256 amount)
    public
    updateReward(_account)
  {
    require(msg.sender == address(deposits), "!authorized");
    //require(amount > 0, 'VirtualDepositRewardPool : Cannot withdraw 0');

    emit Withdrawn(_account, amount);
  }

  function getReward(address _account) public updateReward(_account) {
    uint256 reward = earned(_account);
    if (reward > 0) {
      rewards[_account] = 0;
      rewardToken.safeTransfer(_account, reward);
      emit RewardPaid(_account, reward);
    }
  }

  function getReward() external {
    getReward(msg.sender);
  }

  function donate(uint256 _amount) external returns (bool) {
    revert("Not implemented");
  }

  function queueNewRewards(uint256 _rewards) external returns (bool) {
    revert("Not implemented");
  }

  function notifyRewardAmount(uint256 reward)
    internal
    updateReward(address(0))
  {
    revert("Not implemented");
  }

  function sync(
    uint256 _periodFinish,
    uint256 _rewardRate,
    uint256 _lastUpdateTime,
    uint256 _rewardPerTokenStored,
    uint256 _queuedRewards,
    uint256 _currentRewards,
    uint256 _historicalRewards
  ) external {
    require(msg.sender == manager, "!authorized");
    periodFinish = _periodFinish;
    rewardRate = _rewardRate;
    lastUpdateTime = _lastUpdateTime;
    rewardPerTokenStored = _rewardPerTokenStored;
    queuedRewards = _queuedRewards;
    currentRewards = _currentRewards;
    historicalRewards = _historicalRewards;
  }
}