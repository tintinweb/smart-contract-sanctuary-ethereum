// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFi {
    function add_liquidity(
        // stETH pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function balances(int128) external view returns (uint256);
}

interface ICurveFi_2 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_2_256 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256,
        bool use_underlying
    ) external;
}

interface ICurveFi_3_int128 {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function balances(int128) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

interface ICurveFi_4 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);
}

interface ICurveZap_4 {
    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata uamounts, uint256 max_burn_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool donate_dust
    ) external;

    function withdraw_donated_dust() external;

    function coins(int128 arg0) external returns (address);

    function underlying_coins(int128 arg0) external returns (address);

    function curve() external returns (address);

    function token() external returns (address);
}

interface ICurveZap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

// Interface to manage Crv strategies' interactions
interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}

interface ICurveMintr {
    function mint(address) external;

    function minted(address arg0, address arg1) external view returns (uint256);
}

interface ICurveVotingEscrow {
    function locked(address arg0) external view returns (int128 amount, uint256 end);

    function locked__end(address _addr) external view returns (uint256);

    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function smart_wallet_checker() external returns (address);
}

interface ICurveSmartContractChecker {
    function wallets(address) external returns (bool);

    function approveWallet(address _wallet) external;
}

interface ICurveFi_Polygon_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveFi_Polygon_2 {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function dynamic_fee(int128 i, int128 j) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] calldata _min_amounts,
        bool _use_underlying
    ) external returns (uint256[2] calldata);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount,
        bool _use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(
        uint256 new_fee,
        uint256 new_admin_fee,
        uint256 new_offpeg_fee_multiplier
    ) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function set_aave_referral(uint256 referral_code) external;

    function set_reward_receiver(address _reward_receiver) external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function coins(uint256 arg0) external view returns (address);

    function underlying_coins(uint256 arg0) external view returns (address);

    function admin_balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function offpeg_fee_multiplier() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_offpeg_fee_multiplier() external view returns (uint256);

    function future_owner() external view returns (address);

    function reward_receiver() external view returns (address);

    function admin_fee_receiver() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IOracle {
    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function endMigration() external;

    function getDisputer() external view returns (address);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getPrice(address _asset) external view returns (uint256);

    function getPricer(address _asset) external view returns (address);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function migrateOracle(
        address _asset,
        uint256[] memory _expiries,
        uint256[] memory _prices
    ) external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetPricer(address _asset, address _pricer) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setDisputer(address _disputer) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setStablePrice(address _asset, uint256 _price) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IPricer {
    function asset() external view returns (address);

    function getPrice() external view returns (uint256);

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { IPricer } from "../interfaces/IPricer.sol";
import { ICurvePool } from "../interfaces/ICurve.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract CRV3Pricer is IPricer {
    address public constant asset = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    ICurvePool public constant CURVE_POOL = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    IOracle public oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function getPrice() external view override returns (uint256) {
        return _getPrice(oracle.getPrice(DAI), oracle.getPrice(USDC), oracle.getPrice(USDT));
    }

    function _getPrice(
        uint256 _daiPrice,
        uint256 _usdcPrice,
        uint256 _usdtPrice
    ) private view returns (uint256) {
        uint256 minPrice = _daiPrice < _usdcPrice && _daiPrice < _usdtPrice
            ? _daiPrice
            : _usdcPrice < _daiPrice && _usdcPrice < _usdtPrice
            ? _usdcPrice
            : _usdtPrice;
        return (CURVE_POOL.get_virtual_price() * minPrice) / 1e18;
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 daiPriceExpiry, ) = oracle.getExpiryPrice(DAI, _expiryTimestamp);
        require(daiPriceExpiry > 0, "DAI price not set yet");

        (uint256 usdcPriceExpiry, ) = oracle.getExpiryPrice(USDC, _expiryTimestamp);
        require(usdcPriceExpiry > 0, "USDC price not set yet");

        (uint256 usdtPriceExpiry, ) = oracle.getExpiryPrice(USDT, _expiryTimestamp);
        require(usdtPriceExpiry > 0, "USDT price not set yet");

        uint256 price = _getPrice(usdcPriceExpiry, daiPriceExpiry, usdtPriceExpiry);

        oracle.setExpiryPrice(asset, _expiryTimestamp, price);
    }
}