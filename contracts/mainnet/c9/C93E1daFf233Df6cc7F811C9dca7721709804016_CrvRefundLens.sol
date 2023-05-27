// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";

interface ICauldronV2 {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function accrueInfo() external view returns (uint64, uint128, uint64);

    function BORROW_OPENING_FEE() external view returns (uint256);

    function COLLATERIZATION_RATE() external view returns (uint256);

    function LIQUIDATION_MULTIPLIER() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function bentoBox() external view returns (address);

    function feeTo() external view returns (address);

    function masterContract() external view returns (ICauldronV2);

    function collateral() external view returns (IERC20);

    function setFeeTo(address newFeeTo) external;

    function accrue() external;

    function totalBorrow() external view returns (Rebase memory);

    function userBorrowPart(address account) external view returns (uint256);

    function userCollateralShare(address account) external view returns (uint256);

    function withdrawFees() external;

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function addCollateral(address to, bool skim, uint256 share) external;

    function removeCollateral(address to, uint256 share) external;

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

    function reduceSupply(uint256 amount) external;

    function magicInternetMoney() external view returns (IERC20);

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV2.sol";

interface ICauldronV3 is ICauldronV2 {
    function borrowLimit() external view returns (uint128 total, uint128 borrowPartPerAddres);

    function changeInterestRate(uint64 newInterestRate) external;

    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) external;

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper,
        bytes calldata swapperData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV3.sol";

interface ICauldronV4 is ICauldronV3 {
    function setBlacklistedCallee(address callee, bool blacklisted) external;

    function blacklistedCallees(address callee) external view returns (bool);

    function repayForAll(uint128 amount, bool skim) external returns (uint128);
}

pragma solidity >=0.7.0 <0.9.0;

interface IGaugeController {
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event AddType(string name, int128 type_id);
    event NewTypeWeight(int128 type_id, uint256 time, uint256 weight, uint256 total_weight);
    event NewGaugeWeight(address gauge_address, uint256 time, uint256 weight, uint256 total_weight);
    event VoteForGauge(uint256 time, address user, address gauge_addr, uint256 weight);
    event NewGauge(address addr, int128 gauge_type, uint256 weight);

    function commit_transfer_ownership(address addr) external;

    function apply_transfer_ownership() external;

    function gauge_types(address _addr) external view returns (int128);

    function add_gauge(address addr, int128 gauge_type) external;

    function add_gauge(address addr, int128 gauge_type, uint256 weight) external;

    function checkpoint() external;

    function checkpoint_gauge(address addr) external;

    function gauge_relative_weight(address addr) external view returns (uint256);

    function gauge_relative_weight(address addr, uint256 time) external view returns (uint256);

    function gauge_relative_weight_write(address addr) external returns (uint256);

    function gauge_relative_weight_write(address addr, uint256 time) external returns (uint256);

    function add_type(string memory _name) external;

    function add_type(string memory _name, uint256 weight) external;

    function change_type_weight(int128 type_id, uint256 weight) external;

    function change_gauge_weight(address addr, uint256 weight) external;

    function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight) external;

    function get_gauge_weight(address addr) external view returns (uint256);

    function get_type_weight(int128 type_id) external view returns (uint256);

    function get_total_weight() external view returns (uint256);

    function get_weights_sum_per_type(int128 type_id) external view returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function token() external view returns (address);

    function voting_escrow() external view returns (address);

    function n_gauge_types() external view returns (int128);

    function n_gauges() external view returns (int128);

    function gauge_type_names(int128 arg0) external view returns (string memory);

    function gauges(uint256 arg0) external view returns (address);

    function vote_user_slopes(address arg0, address arg1) external view returns (uint256 slope, uint256 power, uint256 end);

    function vote_user_power(address arg0) external view returns (uint256);

    function last_user_vote(address arg0, address arg1) external view returns (uint256);

    function points_weight(address arg0, uint256 arg1) external view returns (uint256 bias, uint256 slope);

    function time_weight(address arg0) external view returns (uint256);

    function points_sum(int128 arg0, uint256 arg1) external view returns (uint256 bias, uint256 slope);

    function time_sum(uint256 arg0) external view returns (uint256);

    function points_total(uint256 arg0) external view returns (uint256);

    function time_total() external view returns (uint256);

    function points_type_weight(int128 arg0, uint256 arg1) external view returns (uint256);

    function time_type_weight(uint256 arg0) external view returns (uint256);
}

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IMarketLens {
    function getBorrowFee(address cauldron) external view returns (uint256);

    function getCollateralPrice(address cauldron) external view returns (uint256);

    function getInterestPerYear(address cauldron) external view returns (uint64);

    function getLiquidationFee(address cauldron) external view returns (uint256);

    function getMarketInfoCauldronV2(address cauldron) external view returns (MarketInfo memory);

    function getMarketInfoCauldronV3(address cauldron) external view returns (MarketInfo memory marketInfo);

    function getMaxMarketBorrowForCauldronV2(address cauldron) external view returns (uint256);

    function getMaxMarketBorrowForCauldronV3(address cauldron) external view returns (uint256);

    function getMaxUserBorrowForCauldronV2(address cauldron) external view returns (uint256);

    function getMaxUserBorrowForCauldronV3(address cauldron) external view returns (uint256);

    function getMaximumCollateralRatio(address cauldron) external view returns (uint256);

    function getOracleExchangeRate(address cauldron) external view returns (uint256);

    function getTotalBorrowed(address cauldron) external view returns (uint256);

    function getTotalCollateral(address cauldron) external view returns (AmountValue memory);

    function getUserBorrow(address cauldron, address account) external view returns (uint256);

    function getUserCollateral(address cauldron, address account) external view returns (AmountValue memory);

    function getUserLiquidationPrice(address cauldron, address account) external view returns (uint256 liquidationPrice);

    function getUserLtv(address cauldron, address account) external view returns (uint256 ltvBps);

    function getUserMaxBorrow(address cauldron, address account) external view returns (uint256);

    function getUserPosition(address cauldron, address account) external view returns (UserPosition memory);

    function getUserPositions(address cauldron, address[] memory accounts) external view returns (UserPosition[] memory positions);

    struct MarketInfo {
        uint256 borrowFee;
        uint256 maximumCollateralRatio;
        uint256 liquidationFee;
        uint256 interestPerYear;
        uint256 marketMaxBorrow;
        uint256 userMaxBorrow;
        uint256 totalBorrowed;
        uint256 oracleExchangeRate;
        uint256 collateralPrice;
        AmountValue totalCollateral;
    }

    struct AmountValue {
        uint256 amount;
        uint256 value;
    }

    struct UserPosition {
        uint256 ltvBps;
        uint256 borrowValue;
        AmountValue collateralValue;
        uint256 liquidationPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

pragma solidity >=0.7.0 <0.9.0;

interface IVoteEscrowedCrv {
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 typeParam, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    function commit_transfer_ownership(address addr) external;

    function apply_transfer_ownership() external;

    function commit_smart_wallet_checker(address addr) external;

    function apply_smart_wallet_checker() external;

    function get_last_user_slope(address addr) external view returns (int128);

    function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function checkpoint() external;

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 _t) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function changeController(address _newController) external;

    function token() external view returns (address);

    function supply() external view returns (uint256);

    function locked(address arg0) external view returns (int128 amount, uint256 end);

    function epoch() external view returns (uint256);

    function point_history(uint256 arg0) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk);

    function user_point_history(address arg0, uint256 arg1) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk);

    function user_point_epoch(address arg0) external view returns (uint256);

    function slope_changes(uint256 arg0) external view returns (int128);

    function controller() external view returns (address);

    function transfersEnabled() external view returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint256);

    function future_smart_wallet_checker() external view returns (address);

    function smart_wallet_checker() external view returns (address);

    function admin() external view returns (address);

    function future_admin() external view returns (address);
}

pragma solidity >=0.7.0 <0.9.0;

interface IYBribeV3 {
    event Blacklisted(address indexed user);
    event ChangeOwner(address owner);
    event ClearRewardRecipient(address indexed user, address recipient);
    event FeeUpdated(uint256 fee);
    event NewTokenReward(address indexed gauge, address indexed reward_token);
    event PeriodUpdated(address indexed gauge, uint256 indexed period, uint256 bias, uint256 blacklisted_bias);
    event RemovedFromBlacklist(address indexed user);
    event RewardAdded(address indexed briber, address indexed gauge, address indexed reward_token, uint256 amount, uint256 fee);
    event RewardClaimed(address indexed user, address indexed gauge, address indexed reward_token, uint256 amount);
    event SetRewardRecipient(address indexed user, address recipient);

    function _gauges_per_reward(address, uint256) external view returns (address);

    function _rewards_in_gauge(address, address) external view returns (bool);

    function _rewards_per_gauge(address, uint256) external view returns (address);

    function accept_owner() external;

    function active_period(address, address) external view returns (uint256);

    function add_reward_amount(address gauge, address reward_token, uint256 amount) external returns (bool);

    function add_to_blacklist(address _user) external;

    function claim_reward(address gauge, address reward_token) external returns (uint256);

    function claim_reward_for(address user, address gauge, address reward_token) external returns (uint256);

    function claim_reward_for_many(
        address[] memory _users,
        address[] memory _gauges,
        address[] memory _reward_tokens
    ) external returns (uint256[] memory amounts);

    function claimable(address user, address gauge, address reward_token) external view returns (uint256);

    function claims_per_gauge(address, address) external view returns (uint256);

    function clear_recipient() external;

    function current_period() external view returns (uint256);

    function fee_percent() external view returns (uint256);

    function fee_recipient() external view returns (address);

    function gauges_per_reward(address reward) external view returns (address[] memory);

    function get_blacklist() external view returns (address[] memory _blacklist);

    function get_blacklisted_bias(address gauge) external view returns (uint256);

    function is_blacklisted(address address_to_check) external view returns (bool);

    function last_user_claim(address, address, address) external view returns (uint256);

    function next_claim_time(address) external view returns (uint256);

    function owner() external view returns (address);

    function pending_owner() external view returns (address);

    function remove_from_blacklist(address _user) external;

    function reward_per_gauge(address, address) external view returns (uint256);

    function reward_per_token(address, address) external view returns (uint256);

    function reward_recipient(address) external view returns (address);

    function rewards_per_gauge(address gauge) external view returns (address[] memory);

    function set_fee_percent(uint256 _percent) external;

    function set_fee_recipient(address _recipient) external;

    function set_owner(address _new_owner) external;

    function set_recipient(address _recipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "interfaces/ICauldronV4.sol";
import "interfaces/IMarketLens.sol";
import "interfaces/IGaugeController.sol";
import "interfaces/IVoteEscrowedCrv.sol";
import "interfaces/IYBribeV3.sol";

contract CrvRefundLens {
    address constant SPELL_ADDR = 0x090185f2135308BaD17527004364eBcC2D37e5F6;
    address constant LENS_ADDR = 0x73F52bD9e59EdbDf5Cf0DD59126Cef00ecC31528;
    address constant CRV_CAULDRON_ADDR = 0x207763511da879a900973A5E092382117C3c1588;
    address constant CRV_CAULDRON_2_ADDR = 0x7d8dF3E4D06B0e19960c19Ee673c0823BEB90815;
    address constant YBRIBE_V2_ADDR = 0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026;
    address constant YBRIBE_V3_ADDR = 0x03dFdBcD4056E2F92251c7B07423E1a33a7D3F6d;
    address constant CURVE_MIM_GAUGE_ADDR = 0xd8b712d29381748dB89c36BCa0138d7c75866ddF;
    address constant CURVE_GAUGE_CONTROLLER_ADDR = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
    address constant SPELL_ORACLE_ADDR = 0x75e14253dE6a5c2af12d5f1a1EA0A2E11e69EC10;
    address constant VE_CRV_ADDR = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    uint256 constant WEEKS_IN_YEAR = 52;
    IMarketLens private immutable marketLens;
    IGaugeController private immutable gaugeController;
    IVoteEscrowedCrv private immutable voteEscrowedCrv;
    IYBribeV3 private immutable yBribeContract;

    struct AmountValue {
        uint256 amount;
        uint256 value;
    }

    struct RefundInfo {
        address[] cauldrons;
        uint256 spellPrice;
        uint256[] userBorrowAmounts;
        uint256 userVeCrvVoted;
        uint256 userBribesReceived;
    }
    uint256 constant PRECISION = 1e18;
    uint256 constant TENK_PRECISION = 1e5;
    uint256 constant BPS_PRECISION = 1e4;

    constructor() {
        marketLens = IMarketLens(LENS_ADDR);
        gaugeController = IGaugeController(CURVE_GAUGE_CONTROLLER_ADDR);
        voteEscrowedCrv = IVoteEscrowedCrv(VE_CRV_ADDR);
        yBribeContract = IYBribeV3(YBRIBE_V3_ADDR);
    }

    function getUserBorrowAmounts(ICauldronV4[] calldata cauldrons, address user) public view returns (uint256[] memory borrows) {
        borrows = new uint256[](cauldrons.length);
        for (uint256 i = 0; i < cauldrons.length; i++) {
            borrows[i] = marketLens.getUserBorrow(address(cauldrons[i]), user);
        }
    }

    function getVoterMimGaugeVotes(address votingAddress) public view returns (uint256) {
        uint256 voterVeCrv = getVoterVeCrv(votingAddress);
        uint256 mimGaugePower = getVoterMimGaugePower(votingAddress);
        return (voterVeCrv * mimGaugePower) / 1e4;
    }

    function getVoterVeCrv(address votingAddress) public view returns (uint256) {
        return voteEscrowedCrv.balanceOf(votingAddress);
    }

    // Get MIM gauge power of a voter. Power represents % of veCrv balance applied to gauge.
    function getVoterMimGaugePower(address votingAddress) public view returns (uint256) {
        (, uint256 power, ) = gaugeController.vote_user_slopes(votingAddress, CURVE_MIM_GAUGE_ADDR);
        return power;
    }

    function getSpellPrice() public view returns (uint256) {
        IOracle oracle = IOracle(SPELL_ORACLE_ADDR);
        bytes memory data = abi.encodePacked(uint256(0));
        return PRECISION ** 2 / oracle.peekSpot(data);
    }

    function getTotalMimGaugeVotes() public view returns (uint256) {
        return gaugeController.get_gauge_weight(CURVE_MIM_GAUGE_ADDR);
    }

    function getWeeklySpellBribes() public view returns (uint256) {
        uint256 rewardsPerGauge = yBribeContract.reward_per_gauge(CURVE_MIM_GAUGE_ADDR, SPELL_ADDR);
        uint256 claimsPerGauge = yBribeContract.claims_per_gauge(CURVE_MIM_GAUGE_ADDR, SPELL_ADDR);
        return rewardsPerGauge - claimsPerGauge;
    }

    function getVoterSpellBribes(address votingAddress) public view returns (uint256) {
        uint256 totalMimGaugeVotes = getTotalMimGaugeVotes();
        uint256 voterMimGaugeVotes = getVoterMimGaugeVotes(votingAddress);
        uint256 weeklySpellBribes = getWeeklySpellBribes();

        // Pro-rate total SPELL bribes by voter's share of gauge votes
        return (weeklySpellBribes * voterMimGaugeVotes) / totalMimGaugeVotes;
    }

    function getVoterSpellBribesUsd(address votingAddress) public view returns (uint256) {
        return (getVoterSpellBribes(votingAddress) * getSpellPrice()) / PRECISION;
    }

    function getRefundInfo(ICauldronV4[] calldata cauldrons, address user, address votingAddress) public view returns (RefundInfo memory) {
        address[] memory cauldronContracts = new address[](cauldrons.length);
        for (uint256 i = 0; i < cauldrons.length; i++) {
            cauldronContracts[i] = address(cauldrons[i]);
        }

        return
            RefundInfo({
                cauldrons: cauldronContracts,
                spellPrice: getSpellPrice(),
                userBorrowAmounts: getUserBorrowAmounts(cauldrons, user),
                userVeCrvVoted: getVoterMimGaugeVotes(votingAddress),
                userBribesReceived: getVoterSpellBribesUsd(votingAddress)
            });
    }
}