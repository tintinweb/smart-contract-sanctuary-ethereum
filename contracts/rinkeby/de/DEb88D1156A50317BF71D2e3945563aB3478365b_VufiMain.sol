// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Governance.sol";
import "./Constants.sol";
import "./Data.sol";
import {Wallet} from "./Wallet.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {IVufi} from "../token/IVufi.sol";
import {Reward} from "./Reward.sol";

import "../mocks/TestnetUSDC.sol";

import "./Regulator.sol";
import "./Market.sol";

contract VufiMain is Data, Setters, Wallet, Reward, Regulator, Market {
  using SafeMath for uint256;
  bool private _isSetup;
  bool private _isInit;

  event Advance(uint256 indexed cycle, uint256 block, uint256 timestamp);
  event Incentivization(address indexed account, uint256 amount);

  function implement(address implementation) external onlyAdmin {
    upgradeTo(implementation);
  }

  function incentivize(address account, uint256 amount) private {
    mintToAccount(account, amount);
    emit Incentivization(account, amount);
  }

  function advance() external {
    require(
      canIncrementCycle(),
      "VufiMain: Still current cycle"
    );

    incentivize(msg.sender, getAdvanceIncentive());

    Wallet.stepWallet();
    incrementCycle();
    Reward.stepReward();
    Regulator.stepRegulator();

    // solhint-disable-next-line not-rely-on-time
    emit Advance(cycle(), block.number, block.timestamp);
  }

  // TODO: remove this later
  function stepWalletEx() external {
    Wallet.stepWallet();
  }

  function incrementCycleEx() external {
    incrementCycle();
  }

  function stepRewardEx() external {
    Reward.stepReward();
  }

  function stepRegulatorEx() external {
    Regulator.stepRegulator();
  }

  function initAdmin() external {
    require(_isInit == false, "VufiMain: Already setup admin.");

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _isInit = true;
  }

  function setup() external onlyAdmin {
    require(_isSetup == false, "VufiMain: Already setup.");

    // Bootstrap Treasury
    incentivize(getTreasuryAddress(), 5e23);
    // Reward committer
    incentivize(msg.sender, 1e21);

    _isSetup = true;
  }

  // TODO: remove after finish
  function setupMock() external {
    mintFromPool(msg.sender, 10000 * (10 ** uint256(18)));
    TestnetUSDC(usdc()).mint(msg.sender, 10000 * (10 ** uint256(6)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "../deploy/CommonInitializable.sol";
import "../external/Decimal.sol";
import "./Constants.sol";
import {GovernanceData} from "./GovernanceData.sol";
import {AccountStore} from "./Data.sol";
import "./Access.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {AccessControlWithData} from "./AccessControlWithData.sol";
import {GovernanceSetters} from "./GovernanceSetters.sol";

contract Governance is GovernanceData, CommonInitializable, GovernanceSetters, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Decimal for Decimal.D256;
  bool private _isInit;

  event Proposal(address indexed proposal, address indexed account, uint256 indexed start, uint256 period);
  event Voted(address indexed account, address indexed proposal, ProposalStore.Vote vote, uint256 staked);
  event Commit(address indexed account, address indexed proposal);
  event WithdrawShares(address indexed account, uint256 value);
  event DepositShares(address indexed account, uint256 value);

  modifier onlyFrozenOrLocked(address account) {
    require(
      wallet().statusOf(account) != AccountStore.Status.Fluid,
      "Governance: Not frozen or locked"
    );

    _;
  }

  function initAdmin() external {
    require(_isInit == false, "Governance: Already setup admin.");

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _isInit = true;
  }

  /**
  * @dev Takes 'proposal' address and 'voteStatus' and records vote
  *
  * Vote on selected proposal
  *
  * Emits Voted event
  *
  * Requirements:
  *
  * - Account can't be frozen or locked
  * - Proposal can't be finished
  * - Can vote only once
  */
  function vote(address proposal, ProposalStore.Vote voteStatus) external nonReentrant onlyFrozenOrLocked(msg.sender) {
    require(
      balanceOfDepositedShares(msg.sender) > 0,
      "Governance: Must have deposited"
    );

    if (!isNominated(proposal)) {
      require(
        canPropose(msg.sender),
        "Governance: Not enough stake to propose"
      );

      createProposal(proposal, getGovernancePeriod());
      emit Proposal(proposal, msg.sender, cycle(), getGovernancePeriod());
    }

    require(
      cycle() < startFor(proposal).add(periodFor(proposal)),
      "Governance: Ended"
    );

    uint256 owned = balanceOfDepositedShares(msg.sender);
    ProposalStore.Vote recordedVote = recordedVote(msg.sender, proposal);
    if (voteStatus == recordedVote) {
      return;
    }

    if (recordedVote == ProposalStore.Vote.REJECT) {
      decrementRejectFor(proposal, owned, "Governance: Insufficient reject");
    }
    if (recordedVote == ProposalStore.Vote.APPROVE) {
      decrementApproveFor(proposal, owned, "Governance: Insufficient approve");
    }
    if (voteStatus == ProposalStore.Vote.REJECT) {
      incrementRejectFor(proposal, owned);
    }
    if (voteStatus == ProposalStore.Vote.APPROVE) {
      incrementApproveFor(proposal, owned);
    }

    placeLock(msg.sender, proposal);
    recordVote(msg.sender, proposal, voteStatus);

    emit Voted(msg.sender, proposal, voteStatus, owned);
  }

  function withdrawShares(uint256 value) external nonReentrant onlyFrozenOrLocked(msg.sender) {
    IERC20(vufiShares()).safeTransfer(msg.sender, value);
    decrementBalanceOfDepositedVufiShares(msg.sender, value, "Governance: insufficient deposited balance");

    emit WithdrawShares(msg.sender, value);
  }

  function depositShares(uint256 value) external nonReentrant onlyFrozenOrLocked(msg.sender) {
    IERC20(vufiShares()).safeTransferFrom(msg.sender, address(this), value);
    incrementBalanceOfDepositedVufiShares(msg.sender, value);

    emit DepositShares(msg.sender, value);
  }

  /**
  * @dev Take 'proposal' address and calls 'upgradeTo' method
  *
  * Commit proposal changes to protocol
  *
  * Emits Commit event
  *
  * Requirements:
  *
  * - Proposal need end
  * - Proposal can't expire
  * - Proposal need to be approved
  * - Proposal need have majority of votes
  */
  function commit(address proposal) external {
    require(proposal != address(0), "Governance: Not null address");

    require(
      isNominated(proposal),
      "Governance: Not nominated"
    );

    uint256 endsAfter = startFor(proposal).add(periodFor(proposal)).sub(1);

    require(
      cycle() > endsAfter,
      "Governance: Not ended"
    );

    require(
      cycle() <= endsAfter.add(1).add(getGovernanceExpiration()),
      "Governance: Expired"
    );

    require(
      Decimal.ratio(votesFor(proposal), IERC20(vufiShares()).totalSupply()).greaterThan(getGovernanceQuorum()),
      "Governance: Must have quorom"
    );

    require(
      approveFor(proposal) > rejectFor(proposal),
      "Governance: Not approved"
    );

    wallet().upgradeFromGovernance(proposal);

    emit Commit(msg.sender, proposal);
  }

  function emergencyCommit(address proposal) external onlyAdmin {
    require(
      isNominated(proposal),
      "Governance: Not nominated"
    );

    require(
      cycleTime() > cycle().add(getGovernanceEmergencyDelay()),
      "Governance: Cycle synced"
    );

    require(
      approveFor(proposal) > rejectFor(proposal),
      "Governance: Not approved"
    );

    wallet().upgradeFromGovernance(proposal);

    emit Commit(msg.sender, proposal);
  }

  function canPropose(address account) private view returns (bool) {
    if (balanceOfDepositedShares(account) == 0) {
      return false;
    }

    Decimal.D256 memory stake = Decimal.ratio(balanceOfDepositedShares(account), IERC20(vufiShares()).totalSupply());
    return stake.greaterThan(getGovernanceProposalThreshold());
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

//library Constants {
//  /* Cycle */
//  uint256 internal constant CURRENT_CYCLE_OFFSET = 0;
//  uint256 internal constant CURRENT_CYCLE_START = 1625152453;
//  uint256 internal constant CURRENT_CYCLE_PERIOD = 600; // 1 hour
//
//  /* Governance */
//  uint256 internal constant GOVERNANCE_PERIOD = 1; // 200 cycles
//  uint256 internal constant GOVERNANCE_EXPIRATION = 50; // 50 cycles
//  uint256 internal constant GOVERNANCE_QUORUM = 1e16; // 20%
//  uint256 internal constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
//  uint256 internal constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
//  uint256 internal constant GOVERNANCE_EMERGENCY_DELAY = 10; // 100 cycles
//
//  /* Pool */
//  uint256 internal constant POOL_EXIT_LOCKUP_CYCLES = 1;
//  uint256 internal constant POOL_LIMIT = 41000000000000;
//  uint256 internal constant POOL_COLLATERAL_RANGE = 60; // 60%
//  uint256 internal constant POOL_REDEMPTION_DELAY = 3;
//
//  /* WALLET */
//  uint256 internal constant ADVANCE_INCENTIVE = 150e18; // 150 VUFI
//  uint256 internal constant WALLET_EXIT_LOCKUP_CYCLES = 120; // 120 cycles fluid
//
//  /* Wallet */
//  uint256 internal constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VUFI -> 100M VUFI
//  uint256 internal constant WALLET_COUPONS_RATIO = 20; // 20%
//
//  /* Reword */
//  uint256 internal constant NEXT_REWORD_CYCLE = 168; // 24 cycle
//  uint256 internal constant NEXT_REWORD_AMOUNT = 100000000e18; // 100000000
//
//  /* Bootstrapping */
//  uint256 internal constant BOOTSTRAPPING_PERIOD = 3;
//  uint256 internal constant BOOTSTRAPPING_PRICE = 154e16; //  1.10 USDC
//  uint256 internal constant BOOTSTRAPPING_SPEEDUP_FACTOR = 3; // 30 days @ 1 hours
//
//  /* Regulator */
//  uint256 internal constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%
//  uint256 internal constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
//  uint256 internal constant TREASURY_RATIO = 250; // 2.5%
//  // TODO: change address from V to own
//  address internal constant TREASURY_ADDRESS = address(0xA5fC823743492c9cbe9F0a399873b89c60165e7B);
//
//  /* Market */
//  // TODO: update ratio cap
//  uint256 internal constant DEBT_RATIO_CAP = 90e16; // 35%
//
//  /* Oracle */
//  uint256 internal constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
//  uint256 internal constant DOLLAR_SPENDING_MAX = 5e16; // 5%
//
//  /* Dollar spending power */
//  uint256 internal constant MANUAL_START_CPI = 273012 * 1e13;
//  uint256 internal constant MANUAL_CHANGE_LIMIT = 1160; // 0.116%
//  uint256 internal constant NEXT_SPENDING_UPDATE = 720;
//  bool internal constant ONLY_MANUAL_CPI = true;
//  uint256 internal constant VALIDATE_TOLERANCE_CPI = 20e18; // 20%
//  address internal constant ORACLE_CPI_ADDRESS = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
//  bytes32 internal constant ORACLE_CPI_JOB_ID = "29fa9aa13bf1468788b7cc4a500a45b8";
//  uint256 internal constant ORACLE_CPI_FEE = 0.1 * 10 ** 18;
//}

library Constants {
  /* Cycle */
  uint256 internal constant CURRENT_CYCLE_OFFSET = 0;
  uint256 internal constant CURRENT_CYCLE_START = 1629516827;
  uint256 internal constant CURRENT_CYCLE_PERIOD = 3600; // 1 hour

  /* Governance */
  uint256 internal constant GOVERNANCE_PERIOD = 200; // 200 cycles
  uint256 internal constant GOVERNANCE_EXPIRATION = 50; // 50 cycles
  uint256 internal constant GOVERNANCE_QUORUM = 20e16; // 10%
  uint256 internal constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
  uint256 internal constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
  uint256 internal constant GOVERNANCE_EMERGENCY_DELAY = 100; // 100 cycles

  /* Pool */
  uint256 internal constant POOL_EXIT_LOCKUP_CYCLES = 1;
  uint256 internal constant POOL_LIMIT = 41000000000000;
  uint256 internal constant POOL_COLLATERAL_RANGE = 60; // 60%
  uint256 internal constant POOL_REDEMPTION_DELAY = 3;

  /* WALLET */
  uint256 internal constant ADVANCE_INCENTIVE = 150e18; // 150 VUFI
  uint256 internal constant WALLET_EXIT_LOCKUP_CYCLES = 120; // 120 cycles fluid

  /* Wallet */
  uint256 internal constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VUFI -> 100M VUFI
  uint256 internal constant WALLET_COUPONS_RATIO = 20; // 20%

  /* Reword */
  uint256 internal constant NEXT_REWORD_CYCLE = 168; // 24 cycle
  uint256 internal constant NEXT_REWORD_AMOUNT = 70000e18; // 100000
  uint256 internal constant POOL_REWARD_TAKE = 100000e18; // 100000
  bool internal constant NEXT_REWARDS_ENDED = false;

  /* Bootstrapping */
  uint256 internal constant BOOTSTRAPPING_PERIOD = 7;
  uint256 internal constant BOOTSTRAPPING_PRICE = 11e17; //  1.10 USDC
  uint256 internal constant BOOTSTRAPPING_SLOWDOWN_FACTOR = 24; // 7 days @ 24 hours

  /* Regulator */
  uint256 internal constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%
  uint256 internal constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
  uint256 internal constant TREASURY_RATIO = 250; // 2.5%
  uint256 internal constant MAXIMUM_BURN_FROM_WALLET = 50; // 50%
  uint256 internal constant CYCLE_EACH_COUPONS = 2400; // 0.24%
  // TODO: update address of treasury
  address internal constant TREASURY_ADDRESS = 0xc0C114C32082D732d57c633ACE36E4348bA4A82e;

  /* Market */
  uint256 internal constant DEBT_RATIO_CAP = 50e16; // 50%
  uint256 internal constant CURVE_TIME_N = 17e6; // 17%
  uint256 internal constant CURVE_TIME_A = 2e7; // 0.2
  uint256 internal constant CURVE_PRICE_N = 3; // 300%
  uint256 internal constant CURVE_PRICE_A = 1;

  /* Oracle */
  uint256 internal constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
  uint256 internal constant DOLLAR_SPENDING_MAX = 5e16; // 5%

  /* Dollar spending power */
  uint256 internal constant MANUAL_START_CPI = 27301200000 * 1e10;
  uint256 internal constant MANUAL_CHANGE_LIMIT = 1160; // 0.116%
  uint256 internal constant NEXT_SPENDING_UPDATE = 720;
  bool internal constant ONLY_MANUAL_CPI = true;
  uint256 internal constant VALIDATE_TOLERANCE_CPI = 20e18; // 20%
  address internal constant ORACLE_CPI_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
  bytes32 internal constant ORACLE_CPI_JOB_ID = "6d1bfe27e7034b1d87b5270556b17277";
  uint256 internal constant ORACLE_CPI_FEE = 0.1 * 10 ** 18;
  address internal constant ORACLE_USDC_USD = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
  address internal constant ORACLE_LINK_ADDRESS = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../token/IVufi.sol";
import "../oracle/IOracle.sol";
import "../external/IFractionalExponents.sol";
import {IGovernance} from "./IGovernance.sol";

contract RewardStore {
  struct Global {
    uint256 rate;
    uint256 stored;
    uint256 lastCycle;
    uint256 nextCycle;
  }
}

contract CycleStore {
  struct Global {
    uint256 start;
    uint256 period;
    uint256 current;
    uint256 nextCpi;
    uint256 lastCpi;
    uint256 belowPriceStart;
    bool belowPrice;
  }

  struct Coupons {
    uint256 outstanding;
  }

  struct Store {
    uint256 peged;
    uint256 rewards;
    uint256 pegToCoupons;
    Coupons coupons;
  }
}

contract AccountStore {
  enum Status {
    Frozen,
    Fluid,
    Locked
  }

  struct Store {
    uint256 deposited;
    uint256 balance;
    mapping(uint256 => uint256) coupons;
    mapping(address => uint256) couponAllowances;
    uint256 fluidUntil;
    uint256 lockedUntil;
    uint256 rewards;
    uint256 rewardsPaid;
  }
}

contract Implementation {
  struct Store {
    bool _initialized;
  }
}

contract EntrepotStore {
  struct Contracts {
    IVufi vufi;
    IOracle oracle;
    IGovernance governance;
    address exponents;
    address pool;
    address usdc;
    address gov;
    address vufiShares;
    address sharedPool;
    address factory;
    address chainUsdcUsd;
    address manualDollarSpending;
    address chainDollarSpending;
  }

  struct Balance {
    uint256 supply;
    uint256 peg;
    uint256 deposited;
    uint256 depositedShares;
    uint256 redeemable;
    uint256 debt;
    uint256 coupons;
    uint256 totalRewords;
    uint256 pegToCoupons;
  }

  struct DataJoin {
    Contracts contracts;
    Balance balance;
    CycleStore.Global cycle;
    RewardStore.Global reward;

    mapping(address => AccountStore.Store) accounts;
    mapping(uint256 => CycleStore.Store) cycles;
  }
}

contract Data {
  EntrepotStore.DataJoin internal _data;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Setters} from "./Setters.sol";
import {Access} from "./Access.sol";
import {Constants} from "./Constants.sol";
import {AccountGetters} from "./AccountGetters.sol";
import {IVufi} from "../token/IVufi.sol";
import {RewardShared} from "./RewardShared.sol";
import {Decimal} from "../external/Decimal.sol";

contract Wallet is Setters, Access, RewardShared {
  using SafeMath for uint256;
  using SafeERC20 for IVufi;
  using Decimal for Decimal.D256;

  event Deposit(address indexed account, uint256 value);
  event Withdraw(address indexed account, uint256 value);
  event MoveToPeg(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);
  event MoveOutPeg(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);

  function stepWallet() internal {
    snapshotTotalStaked();
    snapshotTotalReword();
    snapshotPegToCoupons();
  }

  /**
  * @dev Moves `value` tokens from `sender` to cellar `value` is then
  * increment _data.accounts[account].deposited amount
  *
  * Deposit founds in order to benefit from staking or peg system
  *
  * Emits Deposit event
  *
  * Requirements:
  *
  * - Account can't be frozen or locked
  */
  function deposit(uint256 value) external nonReentrant onlyFrozenOrLocked(msg.sender) updateReward(msg.sender) {
    vufi().safeTransferFrom(msg.sender, address(this), value);
    incrementBalanceOfDeposited(msg.sender, value);

    emit Deposit(msg.sender, value);
  }

  /**
  * @dev Moves `value` tokens from cellar to sender `amount` is then
  * decrements _data.accounts[account].deposited amount
  *
  * Withdraw founds back to owner
  *
  * Emits Withdraw event
  *
  * Requirements:
  *
  * - Account can't be frozen or locked
  */
  function withdraw(uint256 value) external nonReentrant onlyFrozenOrLocked(msg.sender) updateReward(msg.sender) {
    vufi().safeTransfer(msg.sender, value);
    decrementBalanceOfDeposited(msg.sender, value, "Wallet: insufficient deposited balance");

    emit Withdraw(msg.sender, value);
  }

  /**
  * @dev Updates `value` tokens from '_data.accounts[account].deposited' to `_data.accounts[account].peged` is then
  * decrements _data.accounts[account].deposited amount and increments _data.accounts[account].peged
  *
  * Put funds to peg
  *
  * Emits MoveToPeg event
  *
  * Requirements:
  *
  * - Account can't be frozen or locked
  */
  function moveToPeg(uint256 value) external onlyFrozenOrFluid(msg.sender) {
    _unfreeze(msg.sender);

    uint256 balance = totalPeged() == 0 ?
    value.mul(getInitialStakeMultiple()) :
    value.mul(totalSupply()).div(totalPeged());
    incrementBalanceOf(msg.sender, balance);
    incrementTotalPeg(value);
    decrementBalanceOfDeposited(msg.sender, value, "Wallet: insufficient staged balance");

    emit MoveToPeg(msg.sender, cycle().add(1), balance, value);
  }

  function moveOutPeg(uint256 value) external onlyFrozenOrFluid(msg.sender) {
    _unfreeze(msg.sender);

    uint256 staged = value.mul(balanceOfPeged(msg.sender)).div(balanceOf(msg.sender));

    incrementBalanceOfDeposited(msg.sender, staged);
    decrementTotalPeg(staged, "Wallet: insufficient total bonded");
    decrementBalanceOf(msg.sender, value, "Wallet: insufficient balance");

    emit MoveOutPeg(msg.sender, cycle().add(1), value, staged);
  }

  /**
  * @dev Updates `value` tokens from '_data.accounts[account].peged' to `_data.accounts[account].deposited` is then
  * decrements _data.accounts[account].peged amount and increments _data.accounts[account].deposited
  *
  * Put out funds from peg
  *
  * Emits MoveOutPegUnderlyin event
  *
  * Requirements:
  *
  * - Account can't be frozen or locked
  */
  function moveOutPegUnderlying(uint256 value) external onlyFrozenOrFluid(msg.sender) {
    _unfreeze(msg.sender);

    uint256 balance = _getCurrentRatioCouponsToPeg().mul(value.mul(totalSupply()).div(totalPeged())).asUint256();
    incrementBalanceOfDeposited(msg.sender, value);
    decrementTotalPeg(value, "Wallet: insufficient total staked");
    decrementBalanceOf(msg.sender, balance, "Wallet: insufficient balance");

    emit MoveOutPeg(msg.sender, cycle().add(1), balance, value);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../external/Decimal.sol";

abstract contract IOracle {
  function setup() public virtual;
  function capture() public virtual returns (Decimal.D256 memory, bool);
  function pair() external virtual view returns (address);
  function targetPrice() external virtual view returns (Decimal.D256 memory);
  function updateDollarSpendingPower() public virtual returns (uint256);
  function setWallet(address wallet) external virtual;
  function setPair(address pair) external virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVufi is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
// TODO: Fix initial reward
pragma solidity 0.7.6;
pragma abicoder v2;

import {Setters} from "./Setters.sol";
import {Access} from "./Access.sol";
import {RewardShared} from "./RewardShared.sol";
import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {Constants} from "./Constants.sol";
import {IVufi} from "../token/IVufi.sol";
import {Decimal} from "../external/Decimal.sol";
import {PriceStabilityAdapter} from "./PriceStabilityAdapter.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reward is Setters, Access, PriceStabilityAdapter, RewardShared {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Decimal for Decimal.D256;

  event RewardPaid(address indexed user, uint256 reward);
  event RewardAdded(uint256 reward);
  event RewordCycle(uint256 indexed cycle, uint256 amount);

  function rewardPerTokenStored() external view returns (uint256) {
    return _rewardPerTokenStored();
  }

  function lastTimeRewardApplicable() external view returns (uint256) {
    return _lastTimeRewardApplicable();
  }

  function rate() external view returns(uint256) {
    return _rate();
  }

  /**
  * @dev returns _data.reward.nextCycle number
  *
  * Returns next cycle that will give rewards
  */
  function nextCycleReward() external view returns(uint256) {
    return _nextCycleReward();
  }

  /**
  * @dev Gives 'reward' amount that is allocated to address then sets to zero '_data.accounts[msg.sender].rewards'
  * and does 'safeTransfer' to sender
  *
  * User will get all amount of rewards that he collected before.
  *
  * Emits reward paid event
  *
  * Requirements:
  *
  * - the reward amount of sender need be bigger then zero
  * -
  */
  function getReward() public nonReentrant updateReward(msg.sender) {
    uint256 reward = rewardsOf(msg.sender);
    if (reward > 0) {
      _data.accounts[msg.sender].rewards = 0;
      IERC20(vufiShares()).safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function stepReward() internal {
    if (Constants.NEXT_REWARDS_ENDED == false && cycle() >= _nextCycleReward()) {
      liquidityRewards(Constants.NEXT_REWORD_AMOUNT);
      _notifyRewardAmount(Constants.NEXT_REWORD_AMOUNT);
      emit RewordCycle(cycle(), Constants.NEXT_REWORD_AMOUNT);
    }
  }

  function _notifyRewardAmount(uint256 reward) private updateReward(address(0)) {
    _data.reward.rate = reward.div(Constants.NEXT_REWORD_CYCLE);
    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint balance = IERC20(vufiShares()).balanceOf(address(this));
    require(_data.reward.rate <= balance.div(Constants.NEXT_REWORD_CYCLE), "Reward: Provided reward too high");
    _data.reward.lastCycle = cycle();
    _data.reward.nextCycle = cycle().add(Constants.NEXT_REWORD_CYCLE);
    emit RewardAdded(reward);
  }

  function _nextCycleReward() private view returns(uint256) {
    return _data.reward.nextCycle;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {ERC20Burnable} from "../external/openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import {ERC20} from "../external/openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestnetUSDC is ERC20, ERC20Burnable {
  mapping(address => bool) private _blacklisted;
  uint8 private immutable _decimals;
  string private name_ = "USD//C";
  string private symbol_ = "USDC";

  constructor() ERC20(name_, symbol_) {
    _decimals = 6;
  }

  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function isBlacklisted(address _account) external view returns (bool) {
    return _blacklisted[_account];
  }

  function setIsBlacklisted(bool blacklisted, address _account) external {
    _blacklisted[_account] = blacklisted;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./PriceStabilityAdapter.sol";
import {Decimal} from "../external/Decimal.sol";

contract Regulator is PriceStabilityAdapter {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  event SupplyIncrease(uint256 indexed cycle, uint256 price, uint256 newRedeemable, uint256 lessDebt, uint256 newPeged);
  event SupplyDecrease(uint256 indexed cycle, uint256 price, uint256 newDebt);
  event SupplyNeutral(uint256 indexed cycle);
  event UpdateCpi(uint256 indexed cycle);

  function stepRegulator() internal {
    Decimal.D256 memory price = oracleCapture();

    if (lastCpi() == 0) {
      updateNextCpi(getNextCpi());
    }

    if (cycle() > nextCpi()) {
      updateCpiCycles();
      oracle().updateDollarSpendingPower();
      emit UpdateCpi(cycle());
    }

    if (price.greaterThan(oracle().targetPrice())) {
      if(belowPrice()) {
        setBelowPrice(false);
      }
      growSupply(price);
      return;
    }

    if (price.lessThan(oracle().targetPrice())) {
      if(!belowPrice()) {
        setBelowPriceStartCycle(cycle());
        setBelowPrice(true);
      }
      shrinkSupply(price);
      return;
    }

    emit SupplyNeutral(cycle());
  }

  function updateCpiCycles() private {
    updateLastCpi(cycle());
    updateNextCpi(cycle().add(getNextCpi()));
    return;
  }

  function setBelowPriceStartCycle(uint256 cycleNumber) private {
    _data.cycle.belowPriceStart = cycleNumber;
  }

  function setBelowPrice(bool status) private {
    _data.cycle.belowPrice = status;
  }

  function shrinkSupply(Decimal.D256 memory price) private {
    Decimal.D256 memory delta = limit(oracle().targetPrice().sub(price), price);
    uint256 newDebt = delta.mul(totalNet()).asUint256();

    if (totalPegToCoupons() == 0 || Decimal.ratio(totalPegToCoupons(),
      _data.balance.peg).lessThanOrEqualTo(Decimal.ratio(Constants.MAXIMUM_BURN_FROM_WALLET, 100))) {
      uint256 debtToBurn = newDebt.mul(Constants.CYCLE_EACH_COUPONS).div(1e5);

      newDebt = newDebt.sub(debtToBurn);

      burnFromWallet(debtToBurn);
    }

    uint256 cappedNewDebt = increaseDebt(newDebt);

    emit SupplyDecrease(cycle(), price.value, cappedNewDebt);
    return;
  }

  function growSupply(Decimal.D256 memory price) private {
    uint256 lessDebt = resetDebt(Decimal.zero());

    Decimal.D256 memory delta = limit(price.sub(Decimal.one()), price);
    uint256 newSupply = delta.mul(totalNet()).asUint256();
    (uint256 newRedeemable, uint256 newPeged) = increaseSupply(newSupply);
    emit SupplyIncrease(cycle(), price.value, newRedeemable, lessDebt, newPeged);
  }

  function limit(Decimal.D256 memory delta, Decimal.D256 memory price) private view returns (Decimal.D256 memory) {

    Decimal.D256 memory supplyChangeLimit = getSupplyChangeLimit();

    uint256 totalRedeemable = totalRedeemable();
    uint256 totalCoupons = totalCoupons();
    if (price.greaterThan(oracle().targetPrice()) && (totalRedeemable < totalCoupons)) {
      supplyChangeLimit = getCouponSupplyChangeLimit();
    }

    return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
  }

  function oracleCapture() private returns (Decimal.D256 memory) {
    (Decimal.D256 memory price, bool valid) = oracle().capture();

    if (bootstrappingAt(cycle().sub(1))) {
      return getBootstrappingPrice();
    }
    if (!valid) {
      return oracle().targetPrice();
    }

    return price;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./PriceStabilityAdapter.sol";
import "./Curve.sol";

contract Market is PriceStabilityAdapter, Curve {
  using SafeMath for uint256;

  event CouponPurchase(address indexed account, uint256 indexed cycle, uint256 vufiAmount, uint256 couponAmount);
  event CouponRedemption(address indexed account, uint256 indexed cycle, uint256 couponAmount);
  event CouponTransfer(address indexed from, address indexed to, uint256 indexed cycle, uint256 value);
  event CouponApproval(address indexed owner, address indexed spender, uint256 value);

  function couponPremium(uint256 amount) public view returns (uint256) {
    return calculateCouponPremium(vufi().totalSupply(), totalDebt(), amount, cycle());
  }

  /**
  * @dev Burn `vufiAmount` with method `_burnFromAccount`, add `couponPremium` then `incrementBalanceOfCoupons`
  *
  *
  * Purchase coupons
  *
  * Requirements:
  *
  * - vufiAmount need to be over 0
  * - totalDebt need to be over 0 or equal vufiAmount
  */
  function purchaseCoupons(uint256 vufiAmount) external nonReentrant returns (uint256) {
    require(
      vufiAmount > 0,
      "Market: Must purchase non-zero amount"
    );

    require(
      totalDebt() >= vufiAmount,
      "Market: Not enough debt"
    );

    uint256 cycle = calculateCycleLengthBelowPrice();
    uint256 couponAmount = vufiAmount.add(couponPremium(vufiAmount));
    _burnFromAccount(msg.sender, vufiAmount);
    incrementBalanceOfCoupons(msg.sender, cycle, couponAmount);

    emit CouponPurchase(msg.sender, cycle, vufiAmount, couponAmount);

    return couponAmount;
  }

  /**
  * @dev approveCoupons with `spender` and `amount`
  *
  * Redeem Coupons
  *
  * Requirements:
  *
  * - vufiAmount need to be over 0
  * - Coupon cycle need to be older than two cycles
  * - Coupon balance need to same or higher than `couponCycle`
  */
  function redeemCoupons(uint256 couponCycle, uint256 couponAmount) external nonReentrant {
    require(cycle().sub(couponCycle) >= 2, "Market: Too early to redeem");
    decrementBalanceOfCoupons(msg.sender, couponCycle, couponAmount, "Market: Insufficient coupon balance");
    redeemToAccount(msg.sender, couponAmount);

    emit CouponRedemption(msg.sender, couponCycle, couponAmount);
  }

  /**
  * @dev approveCoupons with `spender` and `amount`
  *
  * Approve coupons
  *
  */
  function approveCoupons(address spender, uint256 amount) external {
    require(spender != address(0), "Market: Coupon approve to the zero address");

    updateAllowanceCoupons(msg.sender, spender, amount);

    emit CouponApproval(msg.sender, spender, amount);
  }

  /**
  * @dev decrementBalanceOfCoupons with `spender` and `amount` and incrementBalanceOfCoupons with `spender` and `amount`
  *
  * Transfer coupons from one account to another
  *
  */
  function transferCoupons(address sender, address recipient, uint256 cycle, uint256 amount) external nonReentrant {
    require(sender != address(0), "Market: Coupon transfer from the zero address");
    require(recipient != address(0), "Market: Coupon transfer to the zero address");

    decrementBalanceOfCoupons(sender, cycle, amount, "Market: Insufficient coupon balance");
    incrementBalanceOfCoupons(recipient, cycle, amount);

    if (msg.sender != sender && allowanceCoupons(sender, msg.sender) != uint256(-1)) {
      decrementAllowanceCoupons(sender, msg.sender, amount, "Market: Insufficient coupon approval");
    }

    emit CouponTransfer(sender, recipient, cycle, amount);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import "./Data.sol";
import "./Getters.sol";
import "../token/Vufi.sol";
import "./GovernanceSetters.sol";
import "./CycleSetters.sol";
import "../deploy/CommonInitializable.sol";

contract Setters is Data, Getters, CycleSetters, ReentrancyGuard, CommonInitializable {
  using SafeMath for uint256;

  modifier onlyGovernanceOrAdmin() {
    require(
      msg.sender == address(gov()) ||
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Access: Not gov or admin"
    );
    _;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);

  function setVufi(address _vufi) external onlyAdmin {
    _data.contracts.vufi = IVufi(_vufi);
  }

  function upgradeFromGovernance(address newImplementation) external onlyGovernanceOrAdmin {
    upgradeTo(newImplementation);
  }

  function setGovernance(address _governance) external onlyAdmin {
    _data.contracts.governance = IGovernance(_governance);
  }

  function setUsdc(address _usdc) external onlyAdmin {
    _data.contracts.usdc = _usdc;
  }

  function setVufiShares(address _vufiShares) external onlyAdmin {
    _data.contracts.vufiShares = _vufiShares;
  }

  function setSharedPool(address _sharedPool) external onlyAdmin {
    _data.contracts.sharedPool = _sharedPool;
  }

  function setPool(address _pool) external onlyAdmin {
    _data.contracts.pool = _pool;
  }

  function setExponents(address _exponents) external onlyAdmin {
    _data.contracts.exponents = _exponents;
  }

  function setChainDollarSpending(address _chainDollarSpending) external onlyAdmin {
    _data.contracts.chainDollarSpending = _chainDollarSpending;
  }

  function setChainUsdcUsd(address _chainUsdcUsd) external onlyAdmin {
    _data.contracts.chainUsdcUsd = _chainUsdcUsd;
  }

  function setOracle(address _oracle) external onlyAdmin {
    _data.contracts.oracle = IOracle(_oracle);
  }

  function setManualDollarSpending(address _manualDollarSpending) external onlyAdmin {
    _data.contracts.manualDollarSpending = _manualDollarSpending;
  }

  function setLockedUntil(address account, uint256 _lockedUntil) public onlyGovernanceOrAdmin {
    _data.accounts[account].lockedUntil = _lockedUntil;
  }

  function incrementBalanceOf(address account, uint256 amount) internal {
    _data.accounts[account].balance = _data.accounts[account].balance.add(amount);
    _data.balance.supply = _data.balance.supply.add(amount);

    emit Transfer(address(0), account, amount);
  }

  function _unfreeze(address account) internal {
    _data.accounts[account].fluidUntil = cycle().add(getWalletExitLockupCycles());
  }

  function decrementBalanceOf(address account, uint256 amount, string memory reason) internal {
    _data.accounts[account].balance = _data.accounts[account].balance.sub(amount, reason);
    _data.balance.supply = _data.balance.supply.sub(amount, reason);

    emit Transfer(account, address(0), amount);
  }

  function incrementTotalBalanceOfCoupons(uint256 cycle, uint256 amount) internal {
    _data.cycles[cycle].coupons.outstanding = _data.cycles[cycle].coupons.outstanding.add(amount);
    _data.balance.coupons = _data.balance.coupons.add(amount);
  }

  function decrementTotalBalanceOfCoupons(uint256 cycle, uint256 amount, string memory reason) internal {
    _data.cycles[cycle].coupons.outstanding = _data.cycles[cycle].coupons.outstanding.sub(amount, reason);
    _data.balance.coupons = _data.balance.coupons.sub(amount, reason);
  }

  function incrementBalanceOfCoupons(address account, uint256 cycle, uint256 amount) internal {
    _data.accounts[account].coupons[cycle] = _data.accounts[account].coupons[cycle].add(amount);
    _data.cycles[cycle].coupons.outstanding = _data.cycles[cycle].coupons.outstanding.add(amount);
    _data.balance.coupons = _data.balance.coupons.add(amount);
  }

  function decrementBalanceOfCoupons(address account, uint256 cycle, uint256 amount, string memory reason) internal {
    _data.accounts[account].coupons[cycle] = _data.accounts[account].coupons[cycle].sub(amount, reason);
    _data.cycles[cycle].coupons.outstanding = _data.cycles[cycle].coupons.outstanding.sub(amount, reason);
    _data.balance.coupons = _data.balance.coupons.sub(amount, reason);
  }

  function incrementBalanceOfDeposited(address account, uint256 amount) internal {
    _data.accounts[account].deposited = _data.accounts[account].deposited.add(amount);
    _data.balance.deposited = _data.balance.deposited.add(amount);
  }

  function decrementBalanceOfDeposited(address account, uint256 amount, string memory reason) internal {
    _data.accounts[account].deposited = _data.accounts[account].deposited.sub(amount, reason);
    _data.balance.deposited = _data.balance.deposited.sub(amount, reason);
  }

  function decrementTotalPeg(uint256 amount, string memory reason) internal {
    _data.balance.peg = _data.balance.peg.sub(amount, reason);
  }

  function incrementTotalPeg(uint256 amount) internal {
    _data.balance.peg = _data.balance.peg.add(amount);
  }

  function incrementTotalDeposited(uint256 amount) internal {
    _data.balance.deposited = _data.balance.peg.add(amount);
  }

  function incrementTotalDebt(uint256 amount) internal {
    _data.balance.debt = _data.balance.debt.add(amount);
  }

  function decrementTotalPegToCoupons(uint256 amount, string memory reason) internal {
    _data.balance.pegToCoupons = _data.balance.pegToCoupons.sub(amount, reason);
  }

  function incrementTotalPegToCoupons(uint256 amount) internal {
    _data.balance.pegToCoupons = _data.balance.pegToCoupons.add(amount);
  }

  function decrementTotalDebt(uint256 amount, string memory reason) internal {
    _data.balance.debt = _data.balance.debt.sub(amount, reason);
  }

  function incrementTotalRewords(uint256 amount) internal {
    _data.balance.totalRewords = _data.balance.totalRewords.add(amount);
  }

  function incrementTotalRedeemable(uint256 amount) internal {
    _data.balance.redeemable = _data.balance.redeemable.add(amount);
  }

  function updateAllowanceCoupons(address owner, address spender, uint256 amount) internal {
    _data.accounts[owner].couponAllowances[spender] = amount;
  }

  function decrementAllowanceCoupons(address owner, address spender, uint256 amount, string memory reason) internal {
    _data.accounts[owner].couponAllowances[spender] =
    _data.accounts[owner].couponAllowances[spender].sub(amount, reason);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./BaseUpgradeabililtyProxy.sol";
import {Implementation} from "../wallet/Data.sol";

contract CommonInitializable is BaseUpgradeabililtyProxy {
    mapping(address => Implementation.Store) public implementations;

    modifier initializer() {
        require(!isInitialized(implementation()), "Initializable: contract is already initialized");

        initialized(implementation());

        _;
    }

    function isInitialized(address _implementation) public view returns (bool) {
        return implementations[_implementation]._initialized;
    }

    function initialized(address _implementation) public {
        implementations[_implementation]._initialized = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "./openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
  using SafeMath for uint256;

  // ============ Constants ============

  uint256 internal constant BASE = 10 ** 18;

  // ============ Structs ============


  struct D256 {
    uint256 value;
  }

  // ============ Static Functions ============

  function zero()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : 0});
  }

  function one()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : BASE});
  }

  function from(
    uint256 a
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : a.mul(BASE)});
  }

  function ratio(
    uint256 a,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(a, BASE, b)});
  }

  // ============ Self Functions ============

  function add(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE), reason)});
  }

  function mul(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.mul(b)});
  }

  function div(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.div(b)});
  }

  function pow(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    if (b == 0) {
      return from(1);
    }

    D256 memory temp = D256({value : self.value});
    for (uint256 i = 1; i < b; i++) {
      temp = mul(temp, self);
    }

    return temp;
  }

  function add(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value, reason)});
  }

  function mul(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, b.value, BASE)});
  }

  function div(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, BASE, b.value)});
  }

  function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
    return self.value == b.value;
  }

  function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 2;
  }

  function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 0;
  }

  function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) > 0;
  }

  function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) < 2;
  }

  function isZero(D256 memory self) internal pure returns (bool) {
    return self.value == 0;
  }

  function asUint256(D256 memory self) internal pure returns (uint256) {
    return self.value.div(BASE);
  }

  // ============ Core Methods ============

  function getPartial(
    uint256 target,
    uint256 numerator,
    uint256 denominator
  )
  private
  pure
  returns (uint256)
  {
    return target.mul(numerator).div(denominator);
  }

  function compareTo(
    D256 memory a,
    D256 memory b
  )
  private
  pure
  returns (uint256)
  {
    if (a.value == b.value) {
      return 1;
    }
    return a.value > b.value ? 2 : 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../token/IVufi.sol";
import "../oracle/IOracle.sol";
import "../external/IFractionalExponents.sol";
import {RoleStore} from "./RoleStore.sol";
import {IWallet} from "../wallet/IWallet.sol";

contract ProposalStore {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct Store {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => Vote) votes;
    }
}

contract AccountGovernanceStore {
    struct Store {
        uint256 depositedShares;
    }
}

contract EntrepotStoreGovernance {
    struct Contracts {
        IERC20 vufiShares;
        IWallet wallet;
        IERC20 vufi;
    }

    struct Balance {
        uint256 depositedShares;
    }

    struct DataJoin {
        Contracts contracts;
        Balance balance;

        mapping(address => AccountGovernanceStore.Store) accounts;
        mapping(address => ProposalStore.Store) proposals;
    }
}

contract GovernanceData {
    EntrepotStoreGovernance.DataJoin internal _data;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Setters.sol";

contract Access is Setters {

  modifier onlyPool() {
    require(
      msg.sender == address(pool()) ||
      address(this) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Access: Not pool"
    );

    _;
  }

  modifier onlyFrozenOrFluid(address account) {
    require(
      statusOf(account) != AccountStore.Status.Locked,
      "Access: Not frozen or fluid"
    );

    _;
  }

  modifier onlyFrozenOrLocked(address account) {
    require(
      statusOf(account) != AccountStore.Status.Fluid,
      "Access: Not frozen or locked"
    );

    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

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

  constructor () {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.7.6;

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

pragma solidity 0.7.6;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {EnumerableSet} from "../external/openzeppelin/contracts/utils/EnumerableSet.sol";
import {Address} from "../external/openzeppelin/contracts/utils/Address.sol";
import {Context} from "../external/openzeppelin/contracts/utils/Context.sol";
import {DataRoles} from "./RoleStore.sol";

abstract contract AccessControlWithData is Context, DataRoles {
  using EnumerableSet for EnumerableSet.AddressSet;
  using Address for address;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
  * @dev Returns default `DEFAULT_ADMIN_ROLE` role.
  */
  function defaultAdminRole() external pure returns(bytes32) {
    return DEFAULT_ADMIN_ROLE;
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return _dataRoles._roles[role].members.contains(account);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _dataRoles._roles[role].members.length();
  }

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
    return _dataRoles._roles[role].members.at(index);
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view returns (bytes32) {
    return _dataRoles._roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) public virtual {
    require(hasRole(_dataRoles._roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) public virtual {
    require(hasRole(_dataRoles._roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) public virtual {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  modifier onlyAdmin() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Access: Not admin"
    );

    _;
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, _dataRoles._roles[role].adminRole, adminRole);
    _dataRoles._roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_dataRoles._roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_dataRoles._roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {GovernanceData, ProposalStore} from "./GovernanceData.sol";
import {GovernanceGetters} from "./GovernanceGetters.sol";
import {IWallet} from "../wallet/IWallet.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernanceSetters is GovernanceData, GovernanceGetters {
  using SafeMath for uint256;

  function setWallet(address _wallet) public onlyAdmin {
    _data.contracts.wallet = IWallet(_wallet);
  }

  function setVufiShares(address _vufiShares) public onlyAdmin {
    _data.contracts.vufiShares = IERC20(_vufiShares);
  }

  function setVufi(address _vufiToken) public onlyAdmin {
    _data.contracts.vufi = IERC20(_vufiToken);
  }

  function createProposal(address proposal, uint256 period) internal {
    _data.proposals[proposal].start = cycle();
    _data.proposals[proposal].period = period;
  }

  function recordVote(address account, address candidate, ProposalStore.Vote vote) internal {
    _data.proposals[candidate].votes[account] = vote;
  }

  function incrementBalanceOfDepositedVufiShares(address account, uint256 amount) internal {
    _data.accounts[account].depositedShares = _data.accounts[account].depositedShares.add(amount);
    _data.balance.depositedShares = _data.balance.depositedShares.add(amount);
  }

  function decrementBalanceOfDepositedVufiShares(address account, uint256 amount, string memory reason) internal {
    _data.accounts[account].depositedShares = _data.accounts[account].depositedShares.sub(amount, reason);
    _data.balance.depositedShares = _data.balance.depositedShares.sub(amount, reason);
  }

  function incrementApproveFor(address proposal, uint256 amount) internal {
    _data.proposals[proposal].approve = _data.proposals[proposal].approve.add(amount);
  }

  function decrementApproveFor(address proposal, uint256 amount, string memory reason) internal {
    _data.proposals[proposal].approve = _data.proposals[proposal].approve.sub(amount, reason);
  }

  function incrementRejectFor(address proposal, uint256 amount) internal {
    _data.proposals[proposal].reject = _data.proposals[proposal].reject.add(amount);
  }

  function decrementRejectFor(address proposal, uint256 amount, string memory reason) internal {
    _data.proposals[proposal].reject = _data.proposals[proposal].reject.sub(amount, reason);
  }

  function placeLock(address account, address proposal) internal {
    uint256 _startFor = startFor(proposal);
    uint256 _periodFor = periodFor(proposal);

    require(_startFor > 0 || _periodFor > 0, "GovernanceSetters: start for proposal is not set");

    uint256 currentLock = wallet().lockedUntil(account);
    uint256 newLock = startFor(proposal).add(periodFor(proposal));
    if (newLock > currentLock) {
      wallet().setLockedUntil(account, newLock);
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Data.sol";
import "../token/IVufi.sol";
import "../oracle/IOracle.sol";
import "./CycleGetters.sol";
import {AccountGetters} from "./AccountGetters.sol";
import "./ERC20Getters.sol";
import {AccessControlWithData} from "./AccessControlWithData.sol";
import "./Constants.sol";
import "../external/Decimal.sol";
import "../external/IFractionalExponents.sol";
import {IGovernance} from "./IGovernance.sol";

contract Getters is Data, CycleGetters, ERC20Getters, AccessControlWithData, AccountGetters {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  function gov() public view returns (IGovernance) {
    return IGovernance(_data.contracts.governance);
  }

  function canIncrementCycle() public view returns (bool) {
    return cycleTime() > cycle();
  }

  function factory() public view returns (address) {
    return _data.contracts.factory;
  }

  function getTreasuryAddress() public pure returns (address) {
    return Constants.TREASURY_ADDRESS;
  }

  function getAdvanceIncentive() internal pure returns (uint256) {
    return Constants.ADVANCE_INCENTIVE;
  }

  function rewordAmount() public pure returns (uint256) {
    return Constants.NEXT_REWORD_AMOUNT;
  }

  function onlyManual() public pure  returns (bool) {
    return Constants.ONLY_MANUAL_CPI;
  }

  function poolRedemptionDelay() public pure returns (uint256) {
    return Constants.POOL_REDEMPTION_DELAY;
  }

  function dollarSpendingMax() public pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.DOLLAR_SPENDING_MAX});
  }

  function manualChangeLimit() public pure returns (uint256) {
    return Constants.MANUAL_CHANGE_LIMIT;
  }

  function poolExitLookup() public pure returns (uint256) {
    return Constants.POOL_EXIT_LOCKUP_CYCLES;
  }

  function chainUsdcUsd() public view returns (address) {
    return _data.contracts.chainUsdcUsd;
  }

  function vufi() public view returns (IVufi) {
    return _data.contracts.vufi;
  }

  function sharedPool() public view returns (address) {
    return _data.contracts.sharedPool;
  }

  function vufiShares() public view returns (address) {
    return _data.contracts.vufiShares;
  }

  function usdc() public view returns (address) {
    return _data.contracts.usdc;
  }

  function exponents() public view returns (address) {
    return _data.contracts.exponents;
  }

  function oracle() public view returns (IOracle) {
    return _data.contracts.oracle;
  }

  function chainDollarSpending() public view returns (address) {
    return _data.contracts.chainDollarSpending;
  }

  function manualDollarSpending() public view returns (address) {
    return _data.contracts.manualDollarSpending;
  }

  function pool() public view returns (address) {
    return _data.contracts.pool;
  }

  function poolCollateralRange() public pure returns (uint256) {
    return Constants.POOL_COLLATERAL_RANGE;
  }

  function debtData() public view returns (uint256, uint256, uint256) {
    return (totalDebt(), totalSupply(), Constants.DEBT_RATIO_CAP);
  }

  function totalNet() public view returns (uint256) {
    return vufi().totalSupply().sub(totalDebt());
  }

  function statusOf(address account) public view returns (AccountStore.Status) {
    if (_data.accounts[account].lockedUntil > cycle()) {
      return AccountStore.Status.Locked;
    }

    return cycle() >= _data.accounts[account].fluidUntil ? AccountStore.Status.Frozen : AccountStore.Status.Fluid;
  }

  function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.DEBT_RATIO_CAP});
  }

  function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.SUPPLY_CHANGE_LIMIT});
  }

  function getTreasuryRatio() internal pure returns (uint256) {
    return Constants.TREASURY_RATIO;
  }

  function getNextCpi() internal pure returns (uint256) {
    return Constants.NEXT_SPENDING_UPDATE;
  }

  function getWalletExitLockupCycles() internal pure returns (uint256) {
    return Constants.WALLET_EXIT_LOCKUP_CYCLES;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {ERC20Permit} from "../external/openzeppelin/contracts/drafts/ERC20Permit.sol";
import {AccessControl} from "../external/openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "../external/openzeppelin/contracts/utils/Context.sol";
import {ERC20} from "../external/openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "../external/openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import {IVufi} from "./IVufi.sol";

contract Vufi is Context, AccessControl, ERC20Burnable, ERC20Permit, IVufi {
  using SafeMath for uint256;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor(address admin, address minter) ERC20Permit("Vufi.finance") ERC20("Vufi.finance", "VUFI") {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, minter);
  }

  /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
  */
  function mint(address to, uint256 amount) public override virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), "Vufi: must have minter role to mint");
    _mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
  */
  function burn(uint256 amount) public override(ERC20Burnable, IVufi) virtual {
    super._burn(_msgSender(), amount);
  }

  /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {ERC20-_burn} and {ERC20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for ``accounts``'s tokens of at least
    * `amount`.
  */
  function burnFrom(address account, uint256 amount) public override(ERC20Burnable, IVufi) virtual {
    uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "Vufi: burn amount exceeds allowance");

    super._approve(account, _msgSender(), decreasedAllowance);
    super._burn(account, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
  */
  function transferFrom(address sender, address recipient, uint256 amount) public
  override(ERC20, IERC20) returns (bool) {
    _transfer(sender, recipient, amount);
    if (allowance(sender, _msgSender()) != uint256(-1)) {
      _approve(
        sender,
        _msgSender(),
        allowance(sender, _msgSender()).sub(amount, "Vufi: transfer amount exceeds allowance"));
    }
    return true;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Data.sol";
import "./CycleGetters.sol";
import "./ERC20Getters.sol";

contract CycleSetters is Data, CycleGetters, ERC20Getters {
  using SafeMath for uint256;

  function incrementCycle() internal {
    _data.cycle.current = _data.cycle.current.add(1);
  }

  function updateNextCpi(uint256 cycle) internal {
    _data.cycle.nextCpi = cycle;
  }

  function updateLastCpi(uint256 cycle) internal {
    _data.cycle.lastCpi = cycle;
  }

  function snapshotTotalStaked() internal {
    _data.cycles[cycle()].peged = totalSupply();
  }

  function snapshotTotalReword() internal {
    _data.cycles[cycle()].rewards = totalRewords();
  }

  function snapshotPegToCoupons() internal {
    _data.cycles[cycle()].pegToCoupons = _data.balance.pegToCoupons;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IFractionalExponents {
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IGovernance {
    function startFor(address proposal) external view returns (uint256);
    function periodFor(address proposal) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Constants.sol";
import "./Data.sol";
import "../external/Decimal.sol";

contract CycleGetters is Data {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  struct CycleStrategy {
    uint256 offset;
    uint256 start;
    uint256 period;
  }

  function balanceOfCoupons(address account, uint256 _cycle) public view returns (uint256) {
    if (outstandingCoupons(_cycle) == 0) {
      return 0;
    }
    return _data.accounts[account].coupons[_cycle];
  }

  function outstandingCoupons(uint256 _cycle) public view returns (uint256) {
    return _data.cycles[_cycle].coupons.outstanding;
  }

  function cycle() public view returns (uint256) {
    return _data.cycle.current;
  }

  function belowPriceStartCycle() public view returns (uint256) {
    return _data.cycle.belowPriceStart;
  }

  function belowPrice() public view returns (bool) {
    return _data.cycle.belowPrice;
  }

  function calculateCycleLengthBelowPrice() public view returns (uint256) {
    if(_data.cycle.belowPriceStart >= _data.cycle.current) {
      return 0;
    }

    return _data.cycle.current.sub(_data.cycle.belowPriceStart);
  }

  function nextCpi() public view returns (uint256) {
    return _data.cycle.nextCpi;
  }

  function lastCpi() public view returns (uint256) {
    return _data.cycle.lastCpi;
  }

  function totalRewords() public view returns (uint256) {
    return _data.balance.totalRewords;
  }

  function bootstrappingAt(uint256 cycleNumber) public virtual pure returns (bool) {
    return cycleNumber <= getBootstrappingPeriod();
  }

  function cycleTime() public virtual view returns (uint256) {
    CycleStrategy memory current = getCurrentCycleStrategy();

    return cycleTimeWithStrategy(current);
  }

  function getCurrentCycleStrategy() internal view returns (CycleStrategy memory) {
    uint256 bootstrappingTotal = Constants.BOOTSTRAPPING_PERIOD;

    return CycleStrategy({
      offset: Constants.CURRENT_CYCLE_OFFSET,
      start: Constants.CURRENT_CYCLE_START,
    // solhint-disable-next-line not-rely-on-time
      period: block.timestamp < Constants.CURRENT_CYCLE_START.add(bootstrappingTotal) ?
        Constants.CURRENT_CYCLE_PERIOD.mul(Constants.BOOTSTRAPPING_PERIOD) : Constants.CURRENT_CYCLE_PERIOD
    });
  }

  function getBootstrappingPeriod() internal pure returns (uint256) {
    return Constants.BOOTSTRAPPING_PERIOD;
  }

  function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.BOOTSTRAPPING_PRICE});
  }

  function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.COUPON_SUPPLY_CHANGE_LIMIT});
  }

  function cycleTimeWithStrategy(CycleStrategy memory strategy) private view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp
    .sub(strategy.start)
    .div(strategy.period)
    .add(strategy.offset);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Data.sol";
import "./ERC20Getters.sol";
import "./Setters.sol";
import "./Constants.sol";

contract AccountGetters is Data, ERC20Getters {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  function rewardsOfPaid(address account) external view returns (uint256) {
    return _rewardsOfPaid(account);
  }

  function allowanceCoupons(address owner, address spender) public view returns (uint256) {
    return _data.accounts[owner].couponAllowances[spender];
  }

  function fluidUntil(address account) public view returns (uint256) {
    return _data.accounts[account].fluidUntil;
  }

  function lockedUntil(address account) public view returns (uint256) {
    return _data.accounts[account].lockedUntil;
  }

  function balanceOfPeged(address account) public view returns (uint256) {
    uint256 totalSupply = totalSupply();
    if (totalSupply == 0) {
      return 0;
    }

    return totalPeged().mul(balanceOf(account)).div(totalSupply);
  }

  function balanceOfDeposited(address account) public view returns (uint256) {
    return _data.accounts[account].deposited;
  }

  function totalBalanceOf(address account) public view returns (uint256) {
    return _data.accounts[account].balance.add(_data.accounts[account].deposited);
  }

  function rewardsOf(address account) public view returns (uint256) {
    return _data.accounts[account].rewards;
  }

  function balanceOf(address account) public view returns (uint256) {
    if (_data.balance.pegToCoupons == 0 || _data.balance.peg == 0) {
      _data.accounts[account].balance;
    }

    return _getCurrentRatioCouponsToPeg().mul(_data.accounts[account].balance).asUint256();
  }

  function _rewardsOfPaid(address account) internal view returns (uint256) {
    return _data.accounts[account].rewardsPaid;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./Data.sol";
import {Constants} from "./Constants.sol";
import {Decimal} from "../external/Decimal.sol";

contract ERC20Getters is Data {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  function totalSupply() public view returns (uint256) {
    return _data.balance.supply;
  }

  function totalWallet() public view returns (uint256) {
    return totalPeged().add(totalDeposited());
  }

  function totalPegToCoupons() public view returns (uint256) {
    return _data.balance.pegToCoupons;
  }

  function _getCurrentRatioCouponsToPeg() internal view returns (Decimal.D256 memory) {
    if (_data.balance.pegToCoupons == 0 || _data.balance.peg == 0) {
      return Decimal.one();
    }

    return Decimal.one().sub(Decimal.ratio(_data.balance.pegToCoupons, _data.balance.peg));
  }

  function totalPeged() public view returns (uint256) {
    return _data.balance.peg;
  }

  function totalDeposited() public view returns (uint256) {
    return _data.balance.deposited;
  }

  function totalPegedAt(uint256 cycleIndex) public view returns (uint256) {
    return _data.cycles[cycleIndex].peged;
  }

  function totalCoupons() public view returns (uint256) {
    return _data.balance.coupons;
  }

  function totalRedeemable() public view returns (uint256) {
    return _data.balance.redeemable;
  }

  function totalDebt() public view returns (uint256) {
    return _data.balance.debt;
  }

  function getInitialStakeMultiple() internal pure returns (uint256) {
    return Constants.INITIAL_STAKE_MULTIPLE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../token/ERC20/ERC20.sol";
import "./IERC20Permit.sol";
import "../cryptography/ECDSA.sol";
import "../utils/Counters.sol";
import "./EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) internal EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceData.sol";
import "../external/Decimal.sol";
import "./Constants.sol";
import {IWallet} from "../wallet/IWallet.sol";
import {AccessControlWithData} from "../wallet/AccessControlWithData.sol";

contract GovernanceGetters is GovernanceData, AccessControlWithData {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  function wallet() public view virtual returns (IWallet) {
    return IWallet(_data.contracts.wallet);
  }

  function balanceOfDepositedShares(address account) public view returns (uint256) {
    return _data.accounts[account].depositedShares;
  }

  function cycleTime() public view virtual returns (uint256) {
    return wallet().cycleTime();
  }

  function cycle() public view returns (uint256) {
    return wallet().cycle();
  }

  function recordedVote(address account, address proposal) public view returns (ProposalStore.Vote) {
    return _data.proposals[proposal].votes[account];
  }

  function startFor(address proposal) public view returns (uint256) {
    return _data.proposals[proposal].start;
  }

  function periodFor(address proposal) public view returns (uint256) {
    return _data.proposals[proposal].period;
  }

  function approveFor(address proposal) public view returns (uint256) {
    return _data.proposals[proposal].approve;
  }

  function rejectFor(address proposal) public view returns (uint256) {
    return _data.proposals[proposal].reject;
  }

  function votesFor(address proposal) public view returns (uint256) {
    return approveFor(proposal).add(rejectFor(proposal));
  }

  function isNominated(address proposal) public view returns (bool) {
    return _data.proposals[proposal].start > 0;
  }

  function vufi() public view returns (address) {
    return address(_data.contracts.vufi);
  }

  function vufiShares() public view returns (address) {
    return address(_data.contracts.vufiShares);
  }

  function getGovernancePeriod() internal pure returns (uint256) {
    return Constants.GOVERNANCE_PERIOD;
  }

  function getGovernanceExpiration() internal pure returns (uint256) {
    return Constants.GOVERNANCE_EXPIRATION;
  }

  function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.GOVERNANCE_QUORUM});
  }

  function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
    return Decimal.D256({value: Constants.GOVERNANCE_PROPOSAL_THRESHOLD});
  }

  function getGovernanceEmergencyDelay() internal pure returns (uint256) {
    return Constants.GOVERNANCE_EMERGENCY_DELAY;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {AccountStore} from "./Data.sol";
import {Decimal} from "../external/Decimal.sol";

interface IWallet {
  function onlyManual() external pure returns (bool);
  function manualDollarSpending() external view returns (address);
  function chainDollarSpending() external view returns (address);
  function cycle() external view returns (uint256);
  function cycleTime() external virtual view returns (uint256);
  function mintFromPool(address account, uint256 amount) external;
  function burnFromPool(address account, uint256 amount) external;
  function vufi() external view returns (address);
  function chainUsdcUsd() external view returns (address);
  function statusOf(address account) external view returns (AccountStore.Status);
  function totalDebt() external view returns (uint256);
  function poolCollateralRange() external view returns (uint256);
  function poolExitLookup() external pure returns (uint256);
  function debtData() external view returns (uint256, uint256, uint256);
  function poolRedemptionDelay() external view returns (uint256);
  function manualChangeLimit() external view returns (uint256);
  function dollarSpendingMax() external pure returns (Decimal.D256 memory);
  function lockedUntil(address account) external view returns (uint256);
  function setLockedUntil(address account, uint256 lockedUntil) external;
  function upgradeFromGovernance(address newImplementation) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {EnumerableSet} from "../external/openzeppelin/contracts/utils/EnumerableSet.sol";
import {Address} from "../external/openzeppelin/contracts/utils/Address.sol";

contract RoleStore {
  using EnumerableSet for EnumerableSet.AddressSet;
  using Address for address;

  struct Store {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  struct DataJoin {
    mapping(bytes32 => RoleStore.Store) _roles;
  }
}

contract DataRoles {
  RoleStore.DataJoin internal _dataRoles;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import {UpgradesAddress} from "./Address.sol";

contract BaseUpgradeabililtyProxy {
  // solhint-disable-next-line no-empty-blocks
  function initialize() public virtual {}

  bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  event Upgraded(address indexed implementation);
  event ValueReceived(address user, uint amount);

  function implementation() public view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  function upgradeTo(address newImplementation) internal returns (bool) {
    setImplementation(newImplementation);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
    require(success, string(reason));

    emit Upgraded(newImplementation);
    return success;
  }

  function setImplementation(address newImplementation) internal {
    require(UpgradesAddress.isContract(newImplementation),
      "Cannot set a proxy implementation to a non-contract address");
    bytes32 slot = IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }

  receive() external payable {
    emit ValueReceived(msg.sender, msg.value);
  }

  // solhint-disable-next-line no-complex-fallback
  fallback () external payable {
    address _impl = implementation();
    require(_impl != address(0), "implementation not set");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

library UpgradesAddress {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {Math} from "../external/openzeppelin/contracts/math/Math.sol";
import {Data} from "./Data.sol";
import {AccountGetters} from "./AccountGetters.sol";
import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";

contract RewardShared is Data, AccountGetters {
  using SafeMath for uint256;

  modifier updateReward(address account) {
    _data.reward.stored = _rewardPerToken();
    _data.reward.lastCycle = _data.cycle.current;
    if (account != address(0)) {
      _data.accounts[account].rewards = earned(account);
      _data.accounts[account].rewardsPaid = _data.reward.stored;
    }
    _;
  }

 /**
 * @dev Calculates earned amount based on 'account' where
 * 'balanceOfDeposited' multiply (times '_rewardPerToken' minus '_rewardsOfPaid') dividing by 1 and adding 'rewardsOf'
 *
 *
 * Returns earned rewards based on account address
 *
 */
  function earned(address account) public view returns (uint256) {
    return totalBalanceOf(account).mul(
      _rewardPerToken().sub(_rewardsOfPaid(account))
    ).div(1e18).add(rewardsOf(account));
  }

  function rewardPerToken() external view returns (uint256) {
    return _rewardPerToken();
  }

  function _rewardPerToken() internal view returns (uint256) {
    if (totalWallet() == 0 || _data.reward.rate == 0) {
      return _rewardPerTokenStored();
    }

    return _data.reward.stored.add(
      _lastTimeRewardApplicable().sub(_data.reward.lastCycle).mul(_data.reward.rate).mul(1e18).div(totalWallet())
    );
  }

  function _rewardPerTokenStored() internal view returns(uint256) {
    return _data.reward.stored;
  }

  function _rate() internal view returns(uint256) {
    return _data.reward.rate;
  }

  function _lastTimeRewardApplicable() internal view returns (uint256) {
    return Math.min(_data.cycle.current, _data.reward.nextCycle);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {Access} from "./Access.sol";
import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "./ISharesPool.sol";

import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../external/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Decimal} from "../external/Decimal.sol";

contract PriceStabilityAdapter is Setters, Access {
  using SafeMath for uint256;
  using SafeERC20 for IVufi;
  using Decimal for Decimal.D256;

  function mintFromPool(address account, uint256 amount) public onlyPool {
    if (amount > 0) {
      vufi().mint(account, amount);
    }
  }

  function mintToAccount(address account, uint256 amount) internal {
    vufi().mint(account, amount);
    if (!bootstrappingAt(cycle())) {
      increaseDebt(amount);
    }

    balanceCheck();
  }

  function burnFromPool(address account, uint256 amount) public {
    _burnFrom(account, amount);

    balanceCheck();
  }

  function _burnFromAccount(address account, uint256 amount) internal {
    _burnFrom(account, amount);
    decrementTotalDebt(amount, "PriceStabilityAdapter: not enough outstanding debt");

    balanceCheck();
  }

  function _burnFrom(address account, uint256 amount) internal {
    vufi().safeTransferFrom(account, address(this), amount);
    vufi().burn(amount);
  }

  function redeemToAccount(address account, uint256 amount) internal {
    vufi().safeTransfer(account, amount);
    decrementTotalRedeemable(amount, "PriceStabilityAdapter: not enough redeemable balance");

    balanceCheck();
  }

  function balanceCheck() private view {
    require(
      vufi().balanceOf(address(this)) >= totalPeged().add(totalDeposited()).sub(totalPegToCoupons()),
      "PriceStabilityAdapter: Inconsistent balances"
    );
  }

  function liquidityRewards(uint256 amount) internal {
    mintToRewards(amount);

    require(
      IERC20(vufiShares()).balanceOf(address(this)) >= totalRewords(),
      "PriceStabilityAdapter: Inconsistent balances"
    );
  }

  function mintToRewards(uint256 amount) private {
    require(sharedPool() != address(0), "PriceStabilityAdapter: Pool ZERO_ADDRESS");
    require(vufiShares() != address(0), "PriceStabilityAdapter: Shared ZERO_ADDRESS");

    if (amount > 0) {
      ISharesPool(sharedPool()).withdraw(vufiShares(), Constants.POOL_REWARD_TAKE, address(this));
      incrementTotalRewords(amount);
    }
  }

  function burnFromWallet(uint256 amount) internal {
    incrementTotalPegToCoupons(amount);
    vufi().burn(amount);

    require(
      totalPegToCoupons() < totalPeged(),
      "PriceStabilityAdapter: Inconsistent peg to coupons with peg"
    );
  }

  function mintToRedeemable(uint256 amount) private {
    vufi().mint(address(this), amount);
    incrementTotalRedeemable(amount);

    balanceCheck();
  }

  function mintToTreasury(uint256 amount) private {
    if (amount > 0) {
      vufi().mint(Constants.TREASURY_ADDRESS, amount);
    }
  }

  function mintToWallet(uint256 amount) private {
    if (amount > 0) {
      vufi().mint(address(this), amount);
      incrementTotalPeg(amount);
    }
  }

  function decrementTotalRedeemable(uint256 amount, string memory reason) internal {
    _data.balance.redeemable = _data.balance.redeemable.sub(amount, reason);
  }

  function increaseDebt(uint256 amount) internal returns (uint256) {
    incrementTotalDebt(amount);
    uint256 lessDebt = resetDebt(getDebtRatioCap());

    balanceCheck();

    return lessDebt > amount ? 0 : amount.sub(lessDebt);
  }

  function resetPegToCoupons(uint256 amount) internal {
    decrementTotalPegToCoupons(amount, "PriceStabilityAdapter: above peg amount");

    require(
      totalPegToCoupons() < totalPeged(),
      "PriceStabilityAdapter: Inconsistent peg to coupons with peg"
    );
  }

  function resetDebt(Decimal.D256 memory targetDebtRatio) internal returns (uint256) {
    uint256 targetDebt = targetDebtRatio.mul(vufi().totalSupply()).asUint256();
    uint256 currentDebt = totalDebt();

    if (currentDebt > targetDebt) {
      uint256 lessDebt = currentDebt.sub(targetDebt);
      decreaseDebt(lessDebt);

      return lessDebt;
    }

    return 0;
  }

  function decreaseDebt(uint256 amount) internal {
    decrementTotalDebt(amount, "PriceStabilityAdapter: not enough debt");

    balanceCheck();
  }

  function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) {
    uint256 totalPegToCoupons = totalPegToCoupons();

    if (totalPegToCoupons > 0) {
      // 0-a. Pay out in exchange for coupons
      uint256 couponReward = totalPegToCoupons.mul(Constants.WALLET_COUPONS_RATIO).div(100);
      resetPegToCoupons(totalPegToCoupons);
      mintToWallet(couponReward.add(totalPegToCoupons));
    }

    // 0-b. Pay out to Treasury
    uint256 rewards = newSupply.mul(getTreasuryRatio()).div(10000);
    mintToTreasury(rewards);

    newSupply = newSupply > rewards ? newSupply.sub(rewards) : 0;

    // 1. True up redeemable pool
    uint256 newRedeemable = 0;
    uint256 totalRedeemable = totalRedeemable();
    uint256 totalCoupons = totalCoupons();
    if (totalRedeemable < totalCoupons) {
      newRedeemable = totalCoupons.sub(totalRedeemable);
      newRedeemable = newRedeemable > newSupply ? newSupply : newRedeemable;
      mintToRedeemable(newRedeemable);
      newSupply = newSupply.sub(newRedeemable);
    }

    // 2. Payout to DAO
    if (totalPeged() == 0) {
      newSupply = 0;
    }
    if (newSupply > 0) {
      mintToWallet(newSupply);
    }

    balanceCheck();

    return (newRedeemable, newSupply.add(rewards));
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface ISharesPool {
  function withdraw(address token, uint256 value, address destination) external;
  function setAdmin(address admin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import {SafeMath} from "../external/openzeppelin/contracts/math/SafeMath.sol";
import "../external/Decimal.sol";
import "../external/IFractionalExponents.sol";
import "./Constants.sol";
import "./Data.sol";

contract Curve is Data {
  using SafeMath for uint256;
  using Decimal for Decimal.D256;

  function calculateCouponPremium(
    uint256 totalSupply,
    uint256 totalDebt,
    uint256 amount,
    uint256 cycle
  ) internal view returns (uint256) {
    require(amount <= totalSupply, "Curve: amount is greater than total supply");
    require(amount <= totalDebt, "Curve: amount is greater than total debt");

    return effectivePremium(totalSupply, totalDebt, cycle).mul(amount).asUint256();
  }

  function effectivePremium(
    uint256 totalSupply,
    uint256 totalDebt,
    uint256 cycle
  ) private view returns (Decimal.D256 memory) {
    Decimal.D256 memory debtRatio = Decimal.ratio(totalDebt, totalSupply);
    Decimal.D256 memory debtRatioUpperBound = Decimal.D256({value: Constants.DEBT_RATIO_CAP});

    if (debtRatio.greaterThan(debtRatioUpperBound)) {
      return curvePrice(Decimal.one().sub(debtRatioUpperBound)).mul(curveTime(cycle));
    } else {
      return curvePrice(Decimal.one().sub(debtRatio)).mul(curveTime(cycle));
    }
  }

  function curveTime(uint256 cycle) private view returns (Decimal.D256 memory) {
    if (cycle == 0 || cycle > 10000) {
      return Decimal.one();
    }

    uint256 base = 1e8;
    uint256 cycleAfter = cycle.mul(base);

    (uint256 result, uint8 precision) = IFractionalExponents(_data.contracts.exponents).power(
      cycleAfter, base, uint32(Constants.CURVE_TIME_N), uint32(base)
    );
    uint256 temp = Constants.CURVE_TIME_A.mul(result) >> precision;
    uint256 output = base.sub(temp);

    Decimal.D256 memory curveRatio = Decimal.ratio(output, base);

    require(curveRatio.lessThan(Decimal.one()), "Curve: Must be below one");

    return curveRatio;
  }

  function curvePrice(Decimal.D256 memory debtRatio) private pure returns (Decimal.D256 memory) {
    return Decimal.from(Constants.CURVE_PRICE_A).sub(debtRatio.pow(Constants.CURVE_PRICE_N).mul(Decimal.one()));
  }
}