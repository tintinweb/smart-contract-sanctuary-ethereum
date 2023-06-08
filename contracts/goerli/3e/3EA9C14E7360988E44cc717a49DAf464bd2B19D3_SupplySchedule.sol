// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./utils/Owned.sol";
import "./interfaces/ISupplySchedule.sol";

// Libraries
import "./libraries/SafeDecimalMath.sol";
import "./libraries/Math.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IKwenta.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/IMultipleMerkleDistributor.sol";

// https://docs.synthetix.io/contracts/source/contracts/supplyschedule
contract SupplySchedule is Owned, ISupplySchedule {
    using SafeDecimalMath for uint;
    using Math for uint;

    IKwenta public kwenta;
    IStakingRewards public stakingRewards;
    IMultipleMerkleDistributor public tradingRewards;

    // Time of the last inflation supply mint event
    uint public lastMintEvent;

    // Counter for number of weeks since the start of supply inflation
    uint public weekCounter;

    // The number of KWENTA rewarded to the caller of Kwenta.mint()
    uint public minterReward = 1e18;

    uint public constant INITIAL_SUPPLY = 313373e18;

    // Initial Supply * 240% Initial Inflation Rate / 52 weeks.
    uint public constant INITIAL_WEEKLY_SUPPLY = INITIAL_SUPPLY * 240 / 100 / 52;

    // Max KWENTA rewards for minter
    uint public constant MAX_MINTER_REWARD = 20 * 1e18;

    // How long each inflation period is before mint can be called
    uint public constant MINT_PERIOD_DURATION = 1 weeks;

    uint public immutable inflationStartDate;
    uint public constant MINT_BUFFER = 1 days;
    uint8 public constant SUPPLY_DECAY_START = 2; // Supply decay starts on the 2nd week of rewards
    uint8 public constant SUPPLY_DECAY_END = 208; // Inclusive of SUPPLY_DECAY_END week.

    // Weekly percentage decay of inflationary supply
    uint public constant DECAY_RATE = 20500000000000000; // 2.05% weekly

    // Percentage growth of terminal supply per annum
    uint public constant TERMINAL_SUPPLY_RATE_ANNUAL = 10000000000000000; // 1.0% pa

    uint public treasuryDiversion = 2000; // 20% to treasury
    uint public tradingRewardsDiversion = 2000;

    // notice treasury address may change
    address public treasuryDAO;

    /* ========== EVENTS ========== */
    
    /**
     * @notice Emitted when the inflationary supply is minted
     **/
    event SupplyMinted(uint supplyMinted, uint numberOfWeeksIssued, uint lastMintEvent);

    /**
     * @notice Emitted when the KWENTA minter reward amount is updated
     **/
    event MinterRewardUpdated(uint newRewardAmount);

    /**
     * @notice Emitted when setKwenta is called changing the Kwenta Proxy address
     **/
    event KwentaUpdated(address newAddress);

    /**
     * @notice Emitted when treasury inflation share is changed
     **/
    event TreasuryDiversionUpdated(uint newPercentage);

    /**
     * @notice Emitted when trading rewards inflation share is changed
     **/
    event TradingRewardsDiversionUpdated(uint newPercentage);

    /**
     * @notice Emitted when StakingRewards is changed
     **/
    event StakingRewardsUpdated(address newAddress);

    /**
     * @notice Emitted when TradingRewards is changed
     **/
    event TradingRewardsUpdated(address newAddress);

    /**
     * @notice Emitted when treasuryDAO address is changed
     **/
    event TreasuryDAOSet(address treasuryDAO);

    constructor(
        address _owner,
        address _treasuryDAO
    ) Owned(_owner) {
        treasuryDAO = _treasuryDAO;

        inflationStartDate = block.timestamp; // inflation starts as soon as the contract is deployed.
        lastMintEvent = block.timestamp;
        weekCounter = 0;
    }

    // ========== VIEWS ==========

    /**
     * @return The amount of KWENTA mintable for the inflationary supply
     */
    function mintableSupply() override public view returns (uint) {
        uint totalAmount;

        if (!isMintable()) {
            return totalAmount;
        }

        uint remainingWeeksToMint = weeksSinceLastIssuance();

        uint currentWeek = weekCounter;

        // Calculate total mintable supply from exponential decay function
        // The decay function stops after week 208
        while (remainingWeeksToMint > 0) {
            currentWeek++;

            if (currentWeek < SUPPLY_DECAY_START) {
                // If current week is before supply decay we add initial supply to mintableSupply
                totalAmount = totalAmount + INITIAL_WEEKLY_SUPPLY;
                remainingWeeksToMint--;
            } else if (currentWeek <= SUPPLY_DECAY_END) {
                // if current week before supply decay ends we add the new supply for the week
                // diff between current week and (supply decay start week - 1)
                uint decayCount = currentWeek - (SUPPLY_DECAY_START - 1);

                totalAmount = totalAmount + tokenDecaySupplyForWeek(decayCount);
                remainingWeeksToMint--;
            } else {
                // Terminal supply is calculated on the total supply of Kwenta including any new supply
                // We can compound the remaining week's supply at the fixed terminal rate
                uint totalSupply = IERC20(kwenta).totalSupply();
                uint currentTotalSupply = totalSupply + totalAmount;

                totalAmount = totalAmount + terminalInflationSupply(currentTotalSupply, remainingWeeksToMint);
                remainingWeeksToMint = 0;
            }
        }

        return totalAmount;
    }

    /**
     * @return A unit amount of decaying inflationary supply from the INITIAL_WEEKLY_SUPPLY
     * @dev New token supply reduces by the decay rate each week calculated as supply = INITIAL_WEEKLY_SUPPLY * ()
     */
    function tokenDecaySupplyForWeek(uint counter) public pure returns (uint) {
        // Apply exponential decay function to number of weeks since
        // start of inflation smoothing to calculate diminishing supply for the week.
        uint effectiveDecay = (SafeDecimalMath.unit() - DECAY_RATE).powDecimal(counter);
        uint supplyForWeek = INITIAL_WEEKLY_SUPPLY.multiplyDecimal(effectiveDecay);

        return supplyForWeek;
    }

    /**
     * @return A unit amount of terminal inflation supply
     * @dev Weekly compound rate based on number of weeks
     */
    function terminalInflationSupply(uint totalSupply, uint numOfWeeks) public pure returns (uint) {
        // rate = (1 + weekly rate) ^ num of weeks
        uint effectiveCompoundRate = (SafeDecimalMath.unit() + (TERMINAL_SUPPLY_RATE_ANNUAL / 52)).powDecimal(numOfWeeks);

        // return Supply * (effectiveRate - 1) for extra supply to issue based on number of weeks
        return totalSupply.multiplyDecimal(effectiveCompoundRate - SafeDecimalMath.unit());
    }

    /**
     * @dev Take timeDiff in seconds (Dividend) and MINT_PERIOD_DURATION as (Divisor)
     * @return Calculate the numberOfWeeks since last mint rounded down to 1 week
     */
    function weeksSinceLastIssuance() public view returns (uint) {
        // Get weeks since lastMintEvent
        // If lastMintEvent not set or 0, then start from inflation start date.
        uint timeDiff = block.timestamp - lastMintEvent;
        return timeDiff / MINT_PERIOD_DURATION;
    }

    /**
     * @return boolean whether the MINT_PERIOD_DURATION (7 days)
     * has passed since the lastMintEvent.
     * */
    function isMintable() override public view returns (bool) {
        return block.timestamp - lastMintEvent > MINT_PERIOD_DURATION;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice Record the mint event from Kwenta by incrementing the inflation
     * week counter for the number of weeks minted (probabaly always 1)
     * and store the time of the event.
     * @param supplyMinted the amount of KWENTA the total supply was inflated by.
     * */
    function recordMintEvent(uint supplyMinted) internal returns (bool) {
        uint numberOfWeeksIssued = weeksSinceLastIssuance();

        // add number of weeks minted to weekCounter
        weekCounter = weekCounter + numberOfWeeksIssued;

        // Update mint event to latest week issued (start date + number of weeks issued * seconds in week)
        // 1 day time buffer is added so inflation is minted after feePeriod closes
        lastMintEvent = inflationStartDate + (weekCounter * MINT_PERIOD_DURATION) + MINT_BUFFER;

        emit SupplyMinted(supplyMinted, numberOfWeeksIssued, lastMintEvent);
        return true;
    }

    /**
     * @notice Mints new inflationary supply weekly
     * New KWENTA is distributed between the minter, treasury, and StakingRewards contract
     * */
    function mint() override external {
        require(address(stakingRewards) != address(0), "Staking rewards not set");
        require(address(tradingRewards) != address(0), "Trading rewards not set");

        uint supplyToMint = mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        // record minting event before mutation to token supply
        recordMintEvent(supplyToMint);

        uint amountToDistribute = supplyToMint - minterReward;
        uint amountToTreasury = amountToDistribute * treasuryDiversion / 10000;
        uint amountToTradingRewards = amountToDistribute * tradingRewardsDiversion / 10000;
        uint amountToStakingRewards = amountToDistribute - amountToTreasury - amountToTradingRewards;

        kwenta.mint(treasuryDAO, amountToTreasury);
        kwenta.mint(address(tradingRewards), amountToTradingRewards);
        kwenta.mint(address(stakingRewards), amountToStakingRewards);
        stakingRewards.notifyRewardAmount(amountToStakingRewards);
        kwenta.mint(msg.sender, minterReward);
    }

    // ========== SETTERS ========== */

    /**
     * @notice Set the Kwenta should it ever change.
     * SupplySchedule requires Kwenta address as it has the authority
     * to record mint event.
     * */
    function setKwenta(IKwenta _kwenta) external onlyOwner {
        require(address(_kwenta) != address(0), "Address cannot be 0");
        kwenta = _kwenta;
        emit KwentaUpdated(address(kwenta));
    }

    /**
     * @notice Sets the reward amount of KWENTA for the caller of the public
     * function Kwenta.mint().
     * This incentivises anyone to mint the inflationary supply and the mintr
     * Reward will be deducted from the inflationary supply and sent to the caller.
     * @param amount the amount of KWENTA to reward the minter.
     * */
    function setMinterReward(uint amount) external onlyOwner {
        require(amount <= MAX_MINTER_REWARD, "SupplySchedule: Reward cannot exceed max minter reward");
        minterReward = amount;
        emit MinterRewardUpdated(minterReward);
    }

    function setTreasuryDiversion(uint _treasuryDiversion) override external onlyOwner {
        require(_treasuryDiversion + tradingRewardsDiversion < 10000, "SupplySchedule: Cannot be more than 100%");
        treasuryDiversion = _treasuryDiversion;
        emit TreasuryDiversionUpdated(_treasuryDiversion);
    }

    function setTradingRewardsDiversion(uint _tradingRewardsDiversion) override external onlyOwner {
        require(_tradingRewardsDiversion + treasuryDiversion < 10000, "SupplySchedule: Cannot be more than 100%");
        tradingRewardsDiversion = _tradingRewardsDiversion;
        emit TradingRewardsDiversionUpdated(_tradingRewardsDiversion);
    }

    function setStakingRewards(address _stakingRewards) override external onlyOwner {
        require(_stakingRewards != address(0), "SupplySchedule: Invalid Address");
        stakingRewards = IStakingRewards(_stakingRewards);
        emit StakingRewardsUpdated(_stakingRewards);
    }

    function setTradingRewards(address _tradingRewards) override external onlyOwner {
        require(_tradingRewards != address(0), "SupplySchedule: Invalid Address");
        tradingRewards = IMultipleMerkleDistributor(_tradingRewards);
        emit TradingRewardsUpdated(_tradingRewards);
    }

    /// @notice set treasuryDAO address
    /// @dev only owner may change address
    function setTreasuryDAO(address _treasuryDAO) external onlyOwner {
        require(_treasuryDAO != address(0), "SupplySchedule: Zero Address");
        treasuryDAO = _treasuryDAO;
        emit TreasuryDAOSet(treasuryDAO);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IERC20.sol";

abstract contract $IERC20 is IERC20 {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IKwenta.sol";

abstract contract $IKwenta is IKwenta {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IMultipleMerkleDistributor.sol";

abstract contract $IMultipleMerkleDistributor is IMultipleMerkleDistributor {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IStakingRewards.sol";

abstract contract $IStakingRewards is IStakingRewards {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISupplySchedule.sol";

abstract contract $ISupplySchedule is ISupplySchedule {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/Math.sol";

contract $Math {
    constructor() {}

    function $powDecimal(uint256 x,uint256 n) external pure returns (uint256) {
        return Math.powDecimal(x,n);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/SupplySchedule.sol";

contract $SupplySchedule is SupplySchedule {
    constructor(address _owner, address _treasuryDAO) SupplySchedule(_owner, _treasuryDAO) {}

    function $recordMintEvent(uint256 supplyMinted) external returns (bool) {
        return super.recordMintEvent(supplyMinted);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/utils/Owned.sol";

contract $Owned is Owned {
    constructor(address _owner) Owned(_owner) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

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

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IKwenta is IERC20 {

    function mint(address account, uint amount) external;

    function burn(uint amount) external;

    function setSupplySchedule(address _supplySchedule) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMultipleMerkleDistributor {
    /// @notice data structure for aggregating multiple claims
    struct Claims {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
        uint256 epoch;
    }

    /// @notice event is triggered whenever a call to `claim` succeeds
    event Claimed(
        uint256 index,
        address account,
        uint256 amount,
        uint256 epoch
    );

    /// @notice event is triggered whenever a merkle root is set
    event MerkleRootModified(uint256 epoch);

    /// @return token to be distributed
    function token() external view returns (address);

    // @return the merkle root of the merkle tree containing account balances available to claim
    function merkleRoots(uint256) external view returns (bytes32);

    /// @notice determine if indexed claim has been claimed
    /// @param index: used for claim managment
    /// @param epoch: distribution index number
    /// @return true if indexed claim has been claimed
    function isClaimed(uint256 index, uint256 epoch)
        external
        view
        returns (bool);

    /// @notice attempt to claim as `account` and transfer `amount` to `account`
    /// @param index: used for merkle tree managment and verification
    /// @param account: address used for escrow entry
    /// @param amount: token amount to be escrowed
    /// @param merkleProof: off-chain generated proof of merkle tree inclusion
    /// @param epoch: distribution index number
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 epoch
    ) external;

    /// @notice function that aggregates multiple claims
    /// @param claims: array of valid claims
    function claimMultiple(Claims[] calldata claims) external;

    /// @notice modify merkle root for existing distribution epoch
    /// @param merkleRoot: new merkle root
    /// @param epoch: distribution index number
    function setMerkleRootForEpoch(bytes32 merkleRoot, uint256 epoch) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
    /// VIEWS
    // token state
    function totalSupply() external view returns (uint256);
    // staking state
    function balanceOf(address account) external view returns (uint256);
    function escrowedBalanceOf(address account) external view returns (uint256);
    function nonEscrowedBalanceOf(address account) external view returns (uint256);
    // rewards
    function getRewardForDuration() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function earned(address account) external view returns (uint256);

    /// MUTATIVE
    // Staking/Unstaking
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function stakeEscrow(address account, uint256 amount) external;
    function unstakeEscrow(address account, uint256 amount) external;
    function exit() external;
    // claim rewards
    function getReward() external;
    // settings
    function notifyRewardAmount(uint256 reward) external;
    function setRewardsDuration(uint256 _rewardsDuration) external;
    // pausable
    function pauseStakingRewards() external;
    function unpauseStakingRewards() external;
    // misc.
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface ISupplySchedule {
    // Views
    function mintableSupply() external view returns (uint);

    function isMintable() external view returns (bool);

    // Mutative functions

    function mint() external;

    function setTreasuryDiversion(uint _treasuryDiversion) external;

    function setTradingRewardsDiversion(uint _tradingRewardsDiversion) external;
    
    function setStakingRewards(address _stakingRewards) external;

    function setTradingRewards(address _tradingRewards) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import "./SafeDecimalMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/math
library Math {
    using SafeDecimalMath for uint;

    /**
     * @dev Uses "exponentiation by squaring" algorithm where cost is 0(logN)
     * vs 0(N) for naive repeated multiplication.
     * Calculates x^n with x as fixed-point and n as regular unsigned int.
     * Calculates to 18 digits of precision with SafeDecimalMath.unit()
     */
    function powDecimal(uint x, uint n) internal pure returns (uint) {
        // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/

        uint result = SafeDecimalMath.unit();
        while (n > 0) {
            if (n % 2 != 0) {
                result = result.multiplyDecimal(x);
            }
            x = x.multiplyDecimal(x);
            n /= 2;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return (x * UNIT) / y;
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}