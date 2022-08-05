/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../AppStorage.sol";
import "../../../C.sol";
import "../../../tokens/ERC20/BeanstalkERC20.sol";
import "../../../libraries/Silo/LibWhitelist.sol";
/**
 * @author Publius
 * @title Replant8 Deploys the Bean, Unripe Bean and Unripe Bean:3Crv Tokens. It also
 * deploys the Bean:3Crv Pool, initializes the Unripe tokens and adds all 4 tokens to the Silo Whitelist
 * ------------------------------------------------------------------------------------
 **/

interface OldCurveFactory {
    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external returns (address);
}

interface NewCurveFactory {
    function add_existing_metapools(
        address[10] memory _pools
    ) external returns (bool);
}

contract Replant8 {

    AppStorage internal s;

    event AddUnripeToken(
        address indexed unripeToken,
        address indexed underlyingToken,
        bytes32 merkleRoot
    );

    // Bean Token
    bytes32 constant BEAN_SALT = 0x3230353630323135343731000000000000000000000000000000000000000000;
    uint256 constant INITIAL_LP = 100e6; // 100 Beans
    string constant NAME = "Bean";
    string constant SYMBOL = "BEAN";

    //Bean 3Crv Pool
    OldCurveFactory constant OLD_FACTORY = OldCurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);
    address constant BASEPOOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 constant A = 1;
    uint256 constant FEE = 	4000000;
    NewCurveFactory constant NEW_FACTORY = NewCurveFactory(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
    uint256 constant MIN_LP_OUT = 200e6;

    bytes32 constant UNRIPE_BEAN_SALT = 0x3236313439353338320000000000000000000000000000000000000000000000;
    uint256 constant NON_DEPOSITED_UNRIPE_BEANS = 18_602_856_267_146;
    uint256 constant DEPOSITED_UNRIPE_BEANS = 20_920_949_043_068;
    uint256 constant EARNED_UNRIPE_BEANS = 11_294_952_663_176;

    bytes32 constant UNRIPE_BEAN3CRV_SALT = 0x3131313133343838393900000000000000000000000000000000000000000000;
    uint256 constant NON_DEPOSITED_UNRIPE_BEAN3CRV = 4_239_601_332_428;
    uint256 constant DEPOSITED_UNRIPE_BEAN3CRV = 140_873_906_070_854;

    bytes32 constant UNRIPE_BEAN_MERKLE_ROOT = 0x4387a1240f0b31c891fabe2eb6dabe6089dd3eba0a8730f7da6d6d3580e8880a;
    bytes32 constant UNRIPE_LP_MERKLE_ROOT = 0xbcad44f78fd24cc53104883e6c8badbc8dbd1c60283c85d3a584f9215f2cb086;

    using SafeMath for uint256;

    function init() external {
        BeanstalkERC20 bean = new BeanstalkERC20{salt: BEAN_SALT}(address(this), NAME, SYMBOL);
        bean.mint(address(this), INITIAL_LP);
        address metapool = OLD_FACTORY.deploy_metapool(BASEPOOL, NAME, SYMBOL, address(bean), A, FEE);
        require(NEW_FACTORY.add_existing_metapools([metapool, address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0)]));

        bean.approve(C.curveMetapoolAddress(), type(uint256).max);
        bean.approve(C.curveZapAddress(), type(uint256).max);
        C.usdc().approve(C.curveZapAddress(), type(uint256).max);
        C.usdc().transferFrom(msg.sender, address(this), INITIAL_LP);

        uint256 newLP = C.curveZap().add_liquidity(
            metapool,
            [INITIAL_LP, 0, INITIAL_LP, 0],
            0
        );

        IERC20(metapool).transfer(msg.sender, newLP);

        BeanstalkERC20 ub = new BeanstalkERC20{salt: UNRIPE_BEAN_SALT}(address(this), "Unripe Bean", "urBEAN");
        ub.mint(address(this), NON_DEPOSITED_UNRIPE_BEANS + DEPOSITED_UNRIPE_BEANS + EARNED_UNRIPE_BEANS);
        s.siloBalances[address(ub)].deposited = DEPOSITED_UNRIPE_BEANS + EARNED_UNRIPE_BEANS;
        addUnripeToken(address(ub), address(bean), UNRIPE_BEAN_MERKLE_ROOT);

        BeanstalkERC20 ub3 = new BeanstalkERC20{salt: UNRIPE_BEAN3CRV_SALT}(address(this), "Unripe BEAN3CRV", "urBEAN3CRV");
        ub3.mint(address(this), NON_DEPOSITED_UNRIPE_BEAN3CRV + DEPOSITED_UNRIPE_BEAN3CRV);
        s.siloBalances[address(ub3)].deposited = DEPOSITED_UNRIPE_BEAN3CRV;
        addUnripeToken(address(ub3), metapool, UNRIPE_LP_MERKLE_ROOT);

        LibWhitelist.whitelistPools();
        LibWhitelist.dewhitelistToken(C.unripeLPPool1());
        LibWhitelist.dewhitelistToken(C.unripeLPPool2());
    }

    function addUnripeToken(
        address unripeToken,
        address underlyingToken,
        bytes32 root
    ) private {
        s.u[unripeToken].underlyingToken = underlyingToken;
        s.u[unripeToken].merkleRoot = root;
        emit AddUnripeToken(unripeToken, underlyingToken, root);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Beanstalk.
**/

// The Account contract stores all of the Farmer specific storage data.
// Each unique Ethereum address is a Farmer.
// Account.State is the primary struct that is referenced in the greater Storage.State struct.
// All other structs in Account are stored in Account.State.
contract Account {

    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and formerly stored Withdrawals.
    // Asset Silo currently stores Unripe Bean and Unripe LP Deposits.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals; // DEPRECATED – Silo V1 Withdrawals are no longer referenced.
        mapping(uint32 => uint256) deposits; // Unripe Bean/LP Deposits (previously Bean/LP Deposits).
        mapping(uint32 => uint256) depositSeeds; // BDV of Unripe LP Deposits / 4 (previously # of Seeds in corresponding LP Deposit).
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount; // The amount of Tokens in the Deposit.
        uint128 bdv; // The Bean-denominated-value of the total amount of Tokens in the Deposit.
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        // uint256 base; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        // uint256 basePerRoot; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 plentyPerRoot; // The global Plenty Per Root index at the last time a Farmer updated their Silo. 
        uint256 plenty; // The balance of a Farmer's plenty. Plenty can be claimed directly for 3Crv.
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    // The global AppStorage state stores a mapping from account address to Account.State.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo bean; // A Farmer's Unripe Bean Deposits only as a result of Replant (previously held the V1 Silo Deposits/Withdrawals for Beans).
        AssetSilo lp;  // A Farmer's Unripe LP Deposits as a result of Replant of BEAN:ETH Uniswap v2 LP Tokens (previously held the V1 Silo Deposits/Withdrawals for BEAN:ETH Uniswap v2 LP Tokens).
        Silo s; // A Farmer's Silo storage.
        uint32 votedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to vote on BIPs.
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        uint32 lastSIs; // DEPRECATED – In Silo V1.2, the Silo reward mechanism was updated to no longer need to store the number of the Supply Increases at the time the Farmer last updated their Silo.
        uint32 proposedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to propose BIPs.
        SeasonOfPlenty deprecated; // DEPRECATED – Replant reset the Season of Plenty mechanism
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedBeans; // DEPRECATED – Replant generalized Internal Balances. Wrapped Beans are now stored at the AppStorage level.
        mapping(address => mapping(uint32 => Deposit)) deposits; // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals; // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
    }
}

// Storage stores the Global Beanstalk State.
// Storage.State stores the highest level State
// All Facets define Storage.State as the first and only state variable in the contract.
contract Storage {

    // DEPRECATED – After Replant, Beanstalk stores Token addresses as constants to save gas.
    // Contracts stored the contract addresses of various important contracts to Beanstalk.
    struct Contracts {
        address bean; // DEPRECATED – See above note
        address pair; // DEPRECATED – See above note
        address pegPair; // DEPRECATED – See above note
        address weth; // DEPRECATED – See above note
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Beans.
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Bip stores Bip related data.
    struct Bip {
        address proposer; // DEPRECATED – See above note
        uint32 start; // DEPRECATED – See above note
        uint32 period; // DEPRECATED – See above note
        bool executed; // DEPRECATED – See above note
        int pauseOrUnpause; // DEPRECATED – See above note
        uint128 timestamp; // DEPRECATED – See above note
        uint256 roots; // DEPRECATED – See above note
        uint256 endTotalRoots; // DEPRECATED – See above note
    }

    // DEPRECATED – Replant moved governance off-chain.
    // DiamondCut stores DiamondCut related data for each Bip.
    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Governance stores global Governance balances.
    struct Governance {
        uint32[] activeBips; // DEPRECATED – See above note
        uint32 bipIndex; // DEPRECATED – See above note
        mapping(uint32 => DiamondCut) diamondCuts; // DEPRECATED – See above note
        mapping(uint32 => mapping(address => bool)) voted; // DEPRECATED – See above note
        mapping(uint32 => Bip) bips; // DEPRECATED – See above note
    }

    // AssetSilo stores global Token level Silo balances.
    // In Storage.State there is a mapping from Token address to AssetSilo.
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    // Silo stores global level Silo balances.
    struct Silo {
        uint256 stalk; // The total amount of active Stalk (including Earned Stalk, excluding Grown Stalk).
        uint256 seeds; // The total amount of active Seeds (excluding Earned Seeds).
        uint256 roots; // Total amount of Roots.
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average delta b calculated from the Bean:3Crv pool.
    struct Oracle {
        bool initialized; // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint32 startSeason; // The Season the Oracle started minting. Used to ramp up delta b when oracle is first added.
        uint256[2] balances; // The cumulative reserve balances of the pool at the start of the Season (used for computing time weighted average delta b).
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    // Note: The `raining` storage variable is stored in the Season section for a gas efficient read operation.
    struct Rain {
        uint256 depreciated; // Ocupies a storage slot in place of a deprecated State variable.
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Beanstalk.
        uint32 lastSop; // The Season in which the most recent consecutive series of Seasons of Plenty started.
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint32 lastSopSeason; // The Season in which the most recent consecutive series of Seasons of Plenty ended.
        uint32 rainStart; // rainStart stores the most recent Season in which Rain started.
        bool raining; // True if it is Raining (P < 1, Pod Rate Excessively Low).
        bool fertilizing; // True if Beanstalk has Fertilizer left to be paid off.
        uint256 start; // The timestamp of the Beanstalk deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Beanstalk.
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint96 lastSoilPercent; // DEPRECATED: Was removed with Extreme Weather V2
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Beans in Soil.
        bool didSowBelowMin; // DEPRECATED: Was removed with Extreme Weather V2
        bool didSowFaster; // DEPRECATED: Was removed with Extreme Weather V2
    }

    // Fundraiser stores Fundraiser data for a given Fundraiser.
    struct Fundraiser {
        address payee; // The address to be paid after the Fundraiser has been fully funded.
        address token; // The token address that used to raise funds for the Fundraiser.
        uint256 total; // The total number of Tokens that need to be raised to complete the Fundraiser.
        uint256 remaining; // The remaining number of Tokens that need to to complete the Fundraiser.
        uint256 start; // The timestamp at which the Fundraiser started (Fundraisers cannot be started and funded in the same block).
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        // selector is an encoded function selector 
        // that pertains to an external view Beanstalk function 
        // with the following signature:
        // function tokenToBdv(uint256 amount) public view returns (uint256);
        // It is called by `LibTokenSilo` through the use of delegatecall
        // To calculate the BDV of a Deposit at the time of Deposit.
        bytes4 selector; // The encoded BDV function selector for the Token.
        uint32 seeds; // The Seeds Per BDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per BDV that the Silo mints in exchange for Depositing this Token.
    }

    // UnripeSettings stores the settings for an Unripe Token in Beanstalk.
    // An Unripe token is a vesting Token that is redeemable for a a pro rata share
    // of the balanceOfUnderlying subject to a penalty based on the percent of
    // Unfertilized Beans paid back.
    // There were two Unripe Tokens added at Replant: 
    // Unripe Bean with its underlying Token as Bean; and
    // Unripe LP with its underlying Token as Bean:3Crv LP.
    // Unripe Tokens are distirbuted through the use of a merkleRoot.
    // The existence of a non-zero UnripeSettings implies that a Token is an Unripe Token.
    struct UnripeSettings {
        address underlyingToken; // The address of the Token underlying the Unripe Token.
        uint256 balanceOfUnderlying; // The number of Tokens underlying the Unripe Tokens (redemption pool).
        bytes32 merkleRoot; // The Merkle Root used to validate a claim of Unripe Tokens.
    }
}

struct AppStorage {
    uint8 index; // DEPRECATED - Was the index of the Bean token in the Bean:Eth Uniswap v2 pool, which has been depreciated.
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Beanstalk is Paused.
    uint128 pausedAt; // The timestamp at which Beanstalk was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c; // DEPRECATED - Previously stored the Contracts State struct. Removed when contract addresses were moved to constants in C.sol.
    Storage.Field f; // The Field storage struct found above.
    Storage.Governance g; // The Governance storage struct found above.
    Storage.Oracle co; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance.
    Storage.Weather w; // The Weather storage struct found above.

    //////////////////////////////////

    uint256 earnedBeans; // The number of Beans distributed to the Silo that have not yet been Deposited as a result of the Earn function being called.
    uint256[14] depreciated; // DEPRECATED - 14 slots that used to store state variables which have been deprecated through various updates. Storage slots can be left alone or reused.
    mapping (address => Account.State) a; // A mapping from Farmer address to Account state.
    uint32 bip0Start; // DEPRECATED - bip0Start was used to aid in a migration that occured alongside BIP-0.
    uint32 hotFix3Start; // DEPRECATED - hotFix3Start was used to aid in a migration that occured alongside HOTFIX-3.
    mapping (uint32 => Storage.Fundraiser) fundraisers; // A mapping from Fundraiser Id to Fundraiser storage.
    uint32 fundraiserIndex; // The number of Fundraisers that have occured.
    mapping (address => bool) isBudget; // DEPRECATED - Budget Facet was removed in BIP-14. 
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss; // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    uint256[3] depreciated2; // DEPRECATED - 3 slots that used to store state variables which have been depreciated through various updates. Storage slots can be left alone or reused.

    // New Sops
    mapping (uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.

    // Internal Balances
    mapping(address => mapping(IERC20 => uint256)) internalTokenBalance; // A mapping from Farmer address to Token address to Internal Balance. It stores the amount of the Token that the Farmer has stored as an Internal Balance in Beanstalk.

    // Unripe
    mapping(address => mapping(address => bool)) unripeClaimed; // True if a Farmer has Claimed an Unripe Token. A mapping from Farmer to Unripe Token to its Claim status.
    mapping(address => Storage.UnripeSettings) u; // Unripe Settings for a given Token address. The existence of a non-zero Unripe Settings implies that the token is an Unripe Token. The mapping is from Token address to Unripe Settings.

    // Fertilizer
    mapping(uint128 => uint256) fertilizer; // A mapping from Fertilizer Id to the supply of Fertilizer for each Id.
    mapping(uint128 => uint128) nextFid; // A linked list of Fertilizer Ids ordered by Id number. Fertilizer Id is the Beans Per Fertilzer level at which the Fertilizer no longer receives Beans. Sort in order by which Fertilizer Id expires next.
    uint256 activeFertilizer; // The number of active Fertilizer.
    uint256 fertilizedIndex; // The total number of Fertilizer Beans.
    uint256 unfertilizedIndex; // The total number of Unfertilized Beans ever.
    uint128 fFirst; // The lowest active Fertilizer Id (start of linked list that is stored by nextFid). 
    uint128 fLast; // The highest active Fertilizer Id (end of linked list that is stored by nextFid). 
    uint128 bpf; // The cumulative Beans Per Fertilizer (bfp) minted over all Season.
    uint256 recapitalized; // The nubmer of USDC that has been recapitalized in the Barn Raise.
    uint256 isFarm; // Stores whether the function is wrapped in the `farm` function (1 if not, 2 if it is).
    address ownerCandidate; // Stores a candidate address to transfer ownership to. The owner must claim the ownership transfer.
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IBean.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IFertilizer.sol";
import "./interfaces/IProxyAdmin.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Beanstalk.
**/
library C {

    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    // Chain
    uint256 private constant CHAIN_ID = 1; // Mainnet

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e6; // 100 beans
    uint256 private constant SOP_PRECISION = 1e24;

    // Sun
    uint256 private constant FERTILIZER_DENOMINATOR = 3;
    uint256 private constant HARVEST_DENOMINATOR = 2;
    uint256 private constant SOIL_COEFFICIENT_HIGH = 0.5e18;
    uint256 private constant SOIL_COEFFICIENT_LOW = 1.5e18;

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%
    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    // Silo
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;


    // Exploit
    uint256 private constant UNRIPE_LP_PER_DOLLAR = 1884592; // 145_113_507_403_282 / 77_000_000
    uint256 private constant ADD_LP_RATIO = 866616;
    uint256 private constant INITIAL_HAIRCUT = 185564685220298701; // SET

    // Contracts
    address private constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address private constant CURVE_BEAN_METAPOOL = 0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49;
    address private constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant UNRIPE_BEAN = 0x1BEA0050E63e05FBb5D8BA2f10cf5800B6224449;
    address private constant UNRIPE_LP = 0x1BEA3CcD22F4EBd3d37d731BA31Eeca95713716D;
    address private constant FERTILIZER = 0x402c84De2Ce49aF88f5e2eF3710ff89bFED36cB6;
    address private constant FERTILIZER_ADMIN = 0xfECB01359263C12Aa9eD838F878A596F0064aa6e;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address private constant TRI_CRYPTO = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    address private constant TRI_CRYPTO_POOL = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant CURVE_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    address private constant UNRIPE_CURVE_BEAN_LUSD_POOL = 0xD652c40fBb3f06d6B58Cb9aa9CFF063eE63d465D;
    address private constant UNRIPE_CURVE_BEAN_METAPOOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;

    /**
     * Getters
    **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getFertilizerDenominator() internal pure returns (uint256) {
        return FERTILIZER_DENOMINATOR;
    }

    function getHarvestDenominator() internal pure returns (uint256) {
        return HARVEST_DENOMINATOR;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
      return STALK_PER_BEAN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getSopPrecision() internal pure returns (uint256) {
        return SOP_PRECISION;
    }

    function beanAddress() internal pure returns (address) {
        return BEAN;
    }

    function curveMetapoolAddress() internal pure returns (address) {
        return CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool1() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool2() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_LUSD_POOL;
    }

    function unripeBeanAddress() internal pure returns (address) {
        return UNRIPE_BEAN;
    }

    function unripeLPAddress() internal pure returns (address) {
        return UNRIPE_LP;
    }

    function unripeBean() internal pure returns (IERC20) {
        return IERC20(UNRIPE_BEAN);
    }

    function unripeLP() internal pure returns (IERC20) {
        return IERC20(UNRIPE_LP);
    }

    function bean() internal pure returns (IBean) {
        return IBean(BEAN);
    }

    function usdc() internal pure returns (IERC20) {
        return IERC20(USDC);
    }

    function curveMetapool() internal pure returns (ICurvePool) {
        return ICurvePool(CURVE_BEAN_METAPOOL);
    }

    function curve3Pool() internal pure returns (I3Curve) {
        return I3Curve(CURVE_3_POOL);
    }
    
    function curveZap() internal pure returns (ICurveZap) {
        return ICurveZap(CURVE_ZAP);
    }

    function curveZapAddress() internal pure returns (address) {
        return CURVE_ZAP;
    }

    function curve3PoolAddress() internal pure returns (address) {
        return CURVE_3_POOL;
    }

    function threeCrv() internal pure returns (IERC20) {
        return IERC20(THREE_CRV);
    }

    function fertilizer() internal pure returns (IFertilizer) {
        return IFertilizer(FERTILIZER);
    }

    function fertilizerAddress() internal pure returns (address) {
        return FERTILIZER;
    }

    function fertilizerAdmin() internal pure returns (IProxyAdmin) {
        return IProxyAdmin(FERTILIZER_ADMIN);
    }

    function triCryptoPoolAddress() internal pure returns (address) {
        return TRI_CRYPTO_POOL;
    }

    function triCrypto() internal pure returns (IERC20) {
        return IERC20(TRI_CRYPTO);
    }

    function unripeLPPerDollar() internal pure returns (uint256) {
        return UNRIPE_LP_PER_DOLLAR;
    }

    function dollarPerUnripeLP() internal pure returns (uint256) {
        return 1e12/UNRIPE_LP_PER_DOLLAR;
    }

    function exploitAddLPRatio() internal pure returns (uint256) {
        return ADD_LP_RATIO;
    }

    function precision() internal pure returns (uint256) {
        return PRECISION;
    }

    function initialRecap() internal pure returns (uint256) {
        return INITIAL_HAIRCUT;
    }

    function soilCoefficientHigh() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_HIGH;
    }

    function soilCoefficientLow() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_LOW;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import {ERC20Permit} from "./ERC20Permit.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract BeanstalkERC20 is ERC20Permit, ERC20Burnable, AccessControl { // removed Context,
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     * See {ERC20-constructor}.
     */
    constructor(address admin, string memory name, string memory symbol) 
        ERC20(name, symbol) 
        ERC20Permit(name) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
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
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "!Minter");
        _mint(to, amount);
    }

    /**
     * @dev Returns the number of decimals=
     * Beanstalk
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title LibWhitelist handles the whitelisting of different tokens.
 **/

interface IBS {
    function lusdToBDV(uint256 amount) external view returns (uint256);

    function curveToBDV(uint256 amount) external view returns (uint256);

    function beanToBDV(uint256 amount) external pure returns (uint256);

    function unripeBeanToBDV(uint256 amount) external view returns (uint256);

    function unripeLPToBDV(uint256 amount) external view returns (uint256);
}

library LibWhitelist {

    event WhitelistToken(
        address indexed token,
        bytes4 selector,
        uint256 seeds,
        uint256 stalk
    );

    event DewhitelistToken(address indexed token);

    uint32 private constant BEAN_3CRV_STALK = 10000;
    uint32 private constant BEAN_3CRV_SEEDS = 4;

    uint32 private constant BEAN_STALK = 10000;
    uint32 private constant BEAN_SEEDS = 2;

    function whitelistPools() internal {
        whitelistBean3Crv();
        whitelistBean();
        whitelistUnripeBean();
        whitelistUnripeLP();
    }

    function whitelistBean3Crv() internal {
        whitelistToken(
            C.curveMetapoolAddress(),
            IBS.curveToBDV.selector,
            BEAN_3CRV_STALK,
            BEAN_3CRV_SEEDS
        );
    }

    function whitelistBean() internal {
        whitelistToken(
            C.beanAddress(),
            IBS.beanToBDV.selector,
            BEAN_STALK,
            BEAN_SEEDS
        );
    }

    function whitelistUnripeBean() internal {
        whitelistToken(
            C.unripeBeanAddress(),
            IBS.unripeBeanToBDV.selector,
            BEAN_STALK,
            BEAN_SEEDS
        );
    }

    function whitelistUnripeLP() internal {
        whitelistToken(
            C.unripeLPAddress(),
            IBS.unripeLPToBDV.selector,
            BEAN_3CRV_STALK,
            BEAN_3CRV_SEEDS
        );
    }

    function dewhitelistToken(address token) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.ss[token];
        emit DewhitelistToken(token);
    }

    function whitelistToken(
        address token,
        bytes4 selector,
        uint32 stalk,
        uint32 seeds
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ss[token].selector = selector;
        s.ss[token].stalk = stalk;
        s.ss[token].seeds = seeds;

        emit WhitelistToken(token, selector, stalk, seeds);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @author Publius
 * @title Bean Interface
**/
abstract contract IBean is IERC20 {

    function burn(uint256 amount) public virtual;
    function burnFrom(address account, uint256 amount) public virtual;
    function mint(address account, uint256 amount) public virtual;

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface ICurvePool {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    function totalSupply() external view returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external returns (uint256);
    function balances(int128 i) external view returns (uint256);
    function fee() external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICurveZap {
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
    function calc_token_amount(address _pool, uint256[4] memory _amounts, bool _is_deposit) external returns (uint256);
}

interface ICurvePoolR {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount, address receiver) external returns (uint256);
}

interface ICurvePool2R {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address reciever) external returns (uint256[2] calldata);
    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool3R {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts, address reciever) external returns (uint256[3] calldata);
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool4R {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[4] memory _min_amounts, address reciever) external returns (uint256[4] calldata);
    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface I3Curve {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFactory {
    function get_coins(address _pool) external view returns (address[4] calldata);
    function get_underlying_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurveCryptoFactory {
    function get_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurvePoolC {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

interface ICurvePoolNoReturn {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts) external;
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;
}

interface ICurvePoolNoReturn128 {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface IFertilizer {
    struct Balance {
        uint128 amount;
        uint128 lastBpf;
    }
    function beanstalkUpdate(
        address account,
        uint256[] memory ids,
        uint128 bpf
    ) external returns (uint256);
    function beanstalkMint(address account, uint256 id, uint128 amount, uint128 bpf) external;
    function balanceOfFertilized(address account, uint256[] memory ids) external view returns (uint256);
    function balanceOfUnfertilized(address account, uint256[] memory ids) external view returns (uint256);
    function lastBalanceOf(address account, uint256 id) external view returns (Balance memory);
    function lastBalanceOfBatch(address[] memory account, uint256[] memory id) external view returns (Balance[] memory);
    function setURI(string calldata newuri) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

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
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
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
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
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
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
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
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
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
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
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
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import "@openzeppelin/contracts/drafts/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * ERC20Permit is duplicated from OpenZeppelin's ERC20Permit contract.
 * 
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Beanstalk's state.
**/
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

}