// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../balancer/WeightedPoolUserData.sol";
import "../balancer/IAsset.sol";
import { IVault as IBalancerVault } from "../balancer/IVault.sol";

import "../interfaces/IBalancerSwapVault.sol";
import "../interfaces/ITheVault.sol";
import "../interfaces/IBadgerTreeV2.sol";
import "../interfaces/ISaffron_Badger_AdapterV2.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error UnsupportedConversion(address token);
error UnsupportedSettWithdraw(address token);

/// @title Autocompounder for the Saffron BadgerDAO adapter
contract SaffronBadgerAutocompounder is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Governance
  address public governance;        // Governance address for operations
  address public new_governance;    // Proposed new governance address
  bool public autocompound_enabled = true;

  // Existing farms and composable protocol connectors to be set in constructor
  ITheVault public badger_the_vault;         // Badger's TheVault for Balancer 20WBTC-80BADGER vault
  IBadgerTreeV2 public badger_tree;          // BadgerTreeV2

  // Constants needed for conversion
  address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address internal constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
  address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
  address internal constant AURA_BAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
  address internal constant BB_A_USD = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;
  address internal constant WBTC20_BADGER80 = 0xb460DAa847c45f1C4a41cb05BFB3b51c92e41B36;
  uint256 internal constant REWARD_WITHDRAW_MIN = uint256(1000);
  uint256 internal constant CONVERSION_MIN = uint256(1000);
  address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  bytes32 internal constant AURA_WETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
  bytes32 internal constant AURABAL_WETH_POOL_ID = 0x0578292cb20a443ba1cde459c985ce14ca2bdee5000100000000000000000269;
  bytes32 internal constant BBAUSD_WETH_POOL_ID = 0x70b7d3b3209a59fb0400e17f67f3ee8c37363f4900020000000000000000018f;
  bytes32 internal constant WBTC_WETH_POOL_ID = 0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e;
  bytes32 internal constant BADGER_WBTC_POOL_ID = 0xb460daa847c45f1c4a41cb05bfb3b51c92e41b36000200000000000000000194;

  // Conversion toggles with defaults
  bool public aura_convert_enabled = true;
  bool public auraBal_convert_enabled = true;
  bool public bBal_convert_enabled = false;     // False due to vault low TVL

  // Badger parameters
  address public lp;                    // LP token to autocompound into. This is Badger Sett 20WBTC-80BADGER.)
  address public deposit_token;         // 20WBTC-80BADGER Balancer token
  address public sett;                  // Expect this to be Badger Sett 20WBTC-80BADGER

  // Reward tokens
  address internal constant B_AURA_BAL  = 0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8;        // Badger Sett Aura BAL
  address internal constant B_BAL_AAVE_STABLE = 0x06D756861De0724FAd5B5636124e0f252d3C1404; // Badger Sett Balancer Aave Boosted StablePool (USD)
  address internal constant B_GRAV_AURA  = 0xBA485b556399123261a5F9c95d413B4f93107407;       // Gravitationally Bound AURA

  ITheVault internal constant bAuraBal = ITheVault(B_AURA_BAL);
  ITheVault internal constant bbbAUsd = ITheVault(B_BAL_AAVE_STABLE);
  ITheVault internal constant bGravAura = ITheVault(B_GRAV_AURA);

  // Saffron
  ISaffron_Badger_AdapterV2 public adapter;

  // System events
  event ErcSwept(address who, address to, address token, uint256 amount);

  /// @param _adapter_address Address of Saffron_Badger_Adapter
  /// @param _lp_address Address of LP token (e.g. Badger 20WBTC-80BADGER vault LP)
  /// @param _deposit_token Address of deposit token (e.g. Balancer's 20WBTC-80BADGER)
  /// @param _sett_address Address of BadgerDAO vault or Sett (e.g. Badger Sett 20WBTC-80BADGER vault)
  /// @param _badger_tree_address Address of the Badger Tree contract
  constructor(
    address _adapter_address,
    address _lp_address,
    address _deposit_token,
    address _sett_address,
    address _badger_tree_address
  ) {
    require(_adapter_address != address(0) && _lp_address != address(0) && _deposit_token != address(0)  && _sett_address != address(0) && _badger_tree_address != address(0),
      "can't construct with 0 address");
    governance = msg.sender;

    // Badger protocol
    lp = _lp_address;
    deposit_token = _deposit_token;
    badger_the_vault = ITheVault(_sett_address);
    badger_tree = IBadgerTreeV2(_badger_tree_address);

    // Saffron protocol
    adapter = ISaffron_Badger_AdapterV2(_adapter_address);

    // Approve sending the deposit tokens (20WBTC-80BADGER) to Badger's vault
    IERC20(_deposit_token).safeApprove(address(badger_the_vault), 0);
    IERC20(_deposit_token).safeApprove(address(badger_the_vault), type(uint128).max);
  }
  
  /// @dev Reset approvals to uint128.max
  function reset_approvals() external {
    // Reset LP token
    IERC20(lp).safeApprove(address(badger_the_vault), 0);
    IERC20(lp).safeApprove(address(badger_the_vault), type(uint128).max);
  }

  /// @dev Deposit into Badger and autocompound
  /// @param amount_qlp Amount to deposit into the Badger vault
  function blend(uint256 amount_qlp) external {
    require(msg.sender == address(adapter), "must be adapter");
    badger_the_vault.deposit(amount_qlp);
  }

  /// @dev Withdraw from BadgerTree and return funds to router
  /// @param amount Amount of Badger vault LP to withdraw
  /// @param to The account address to receive funds
  function spill(
      uint256 amount,
      address to
 ) external {
        require(msg.sender == address(adapter), "must be adapter");
    badger_the_vault.withdraw(amount);
    uint256 amount_less_fee = amount * 999 / 1000;
    IERC20(badger_the_vault.token()).transfer(to, amount_less_fee);
  }

  /// @dev Autocompound rewards into more lp tokens. The parameters tokens, cumulativeAmounts, index, cycle,
  ///      merkleProof match the values returned by https://api.badger.finance/v2/reward/tree/{user account}
  /// @param tokens Array of the reward tokens from the Badger Tree
  /// @param to Address of account the receives the reward tokens
  function autocompound(
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] calldata merkleProof,
    uint256[] calldata amountsToClaim,
    address to
  ) external nonReentrant {
    _autocompound(tokens, cumulativeAmounts, index, cycle, merkleProof, amountsToClaim, to);
  }

  //
  // Sett vault addresses of rewards
  // bauraBAL: 0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8
  //     token: 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d (Aura BAL)
  // graviAURA: 0xBA485b556399123261a5F9c95d413B4f93107407
  //     token: 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF (AURA)
  // bbb-a-USD: 0x06D756861De0724FAd5B5636124e0f252d3C1404
  //     token: 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2 (bb-a-USD)
  function _autocompound(
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] calldata merkleProof,
    uint256[] calldata amountsToClaim,
    address to
  ) internal {
    if (!autocompound_enabled) return;

    // harvest tokens
    badger_tree.claim(tokens, cumulativeAmounts, index, cycle, merkleProof, amountsToClaim);

    // Convert bTokens and Badger to WBTC, deposit WBTC.
    _withdraw_rewards(tokens, cumulativeAmounts);
  }

  function _withdraw_rewards(address[] calldata tokens, uint256[] calldata cumulativeAmounts) internal {
    uint256 bauraBAL_amount;
    uint256 graviAURA_amount;
    uint256 bbbaUSD_amount;

    for (uint256 token_idx = 0; token_idx < tokens.length; token_idx++) {
      address current_token = tokens[token_idx];
      if (current_token == B_AURA_BAL) {
        bauraBAL_amount = cumulativeAmounts[token_idx];
      } else if (current_token == B_BAL_AAVE_STABLE) {
        bbbaUSD_amount = cumulativeAmounts[token_idx];
      } else if (current_token == B_GRAV_AURA) {
        graviAURA_amount = cumulativeAmounts[token_idx];
      }
    }

    // Withdraw the bTokens for underlying tokens: Aura BAL, AURA, bb-a-USD
    bAuraBal.withdraw(bauraBAL_amount);
    bbbAUsd.withdraw(bbbaUSD_amount);
    bGravAura.withdraw(graviAURA_amount);

  }


  /// @dev Convert the reward tokens into Badger vault deposit token, 20WBTC-80BADGER
  /// @param tokens Array of token addresses of expected rewards
  function convert_rewards(address[] memory tokens) external  {
        for (uint256 token_idx = 0; token_idx < tokens.length; token_idx++) {
      _convert_reward(tokens[token_idx]);
    }
  }

  /// @dev Deposit the rewards already converted into deposit token
  function deposit_rewards() external {
    // Assume auraBAL, AURA, and bb-a-usd already converted to the deposit_token, 20WBTC-80BADGER
    // Deposit 20WBTC-80BADGER rewards
    uint256 rewards_earned = IERC20(deposit_token).balanceOf(address(this));

    if (rewards_earned > REWARD_WITHDRAW_MIN) {
        badger_the_vault.deposit(rewards_earned);
      }
  }

  function _convert_reward(address token) internal returns (uint256) {
    // Convert auraBAL, AURA, or bb-a-USD to 20WBTC-80BADGER, return 20WBTC-80BADGER amount
    //
    // Paths for conversions:
    //   auraBAL --> WETH
    //   AURA --> WETH
    //   bb-a-USD --> WETH if liquidity exists
    //
    // 20% WETH --> WBTC
    // 80% WETH --> BADGER
    //
    // Deposit WBTC and BADGER into 20WBTC-80BADGER Badger Vault, return the 20WBTC-80BADGER amount

    uint256 tokenAmount = IERC20(token).balanceOf(address(this));
    if (tokenAmount < CONVERSION_MIN) {
        return uint256(0);
    }

    int256 amountOut;
    if (token == AURA) {
      amountOut = _convert_aura(tokenAmount);
    } else if (token == AURA_BAL) {
      amountOut = _convert_auraBAL(tokenAmount);
    } else if (token == BB_A_USD) {
      amountOut = _convert_bb_a_USD(tokenAmount);
    } else {
      return uint256(0);
    }


    uint256 wbtcBadgerAmount = _convert_weth_to_deposit_token();
    return wbtcBadgerAmount;
  }

  function _convert_weth_to_deposit_token() internal returns (uint256) {
    // Balance of WETH
    uint256 wethBal = IERC20(WETH).balanceOf(address(this));

    // 20% of WETH for WBTC, remainder for BADGER
    uint256 weth20 = wethBal * 20 / 100;
    uint256 weth80 = wethBal - weth20;

    if (weth20 < CONVERSION_MIN) {
            return uint256(0);
    }

    // Convert the 20% WETH to WBTC
    int256 wbtcAmount = _convert_asset_to(WETH, WBTC, weth20, WBTC_WETH_POOL_ID);
    if (wbtcAmount < 0) {
      wbtcAmount = -1 * wbtcAmount;
    }

    // Convert the 80% WETH to BADGER
    int256 badgerAmount = _convert_weth_to_badger(weth80);
    if (badgerAmount < 0) {
      badgerAmount = -1 * badgerAmount;
    }

    // Return amount of 20WBTC-80BADGER created
    uint256 wbtcBadgerBefore = IERC20(WBTC20_BADGER80).balanceOf(address(this));
        _join_balancer_wbtcbadger(uint256(wbtcAmount), uint256(badgerAmount));
    uint256 wbtcBadgerAfter = IERC20(WBTC20_BADGER80).balanceOf(address(this));

    return wbtcBadgerAfter - wbtcBadgerBefore;
  }

  function _join_balancer_wbtcbadger(uint256 wbtcAmount, uint256 badgerAmount) internal {

    // Must be ordered the same as result of getPoolTokens()
    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(WBTC);
    assets[1] = IAsset(BADGER);

    uint256[] memory maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] = wbtcAmount;
    maxAmountsIn[1] = badgerAmount;

    bytes memory userData = abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, uint256(1));
    IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest({
      assets: assets,
      maxAmountsIn: maxAmountsIn,
      userData: userData,
      fromInternalBalance: false
    });

    IBalancerVault vault = IBalancerVault(BALANCER_VAULT);

    IERC20(WBTC).safeApprove(BALANCER_VAULT, 0);
    IERC20(WBTC).safeApprove(BALANCER_VAULT, type(uint128).max);
    IERC20(BADGER).safeApprove(BALANCER_VAULT, 0);
    IERC20(BADGER).safeApprove(BALANCER_VAULT, type(uint128).max);

    vault.joinPool(BADGER_WBTC_POOL_ID, address(this), address(this), request);
  }

  // Convert provided reward asset to WETH
  function _convert_reward_asset(address asset, uint256 amount, bytes32 pool) internal returns (int256) {
    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(asset);
    assets[1] = IAsset(WETH);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
      sender: address(this),
      fromInternalBalance: false,
      recipient: payable(address(this)),
      toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory assetToWeth = IBalancerVault.BatchSwapStep(
    {
      poolId: pool,
      assetInIndex: uint256(0),
      assetOutIndex: uint256(1),
      amount: amount,
      userData: ""
    }
    );

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](1);
    steps[0] = assetToWeth;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](2);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(asset).safeApprove(BALANCER_VAULT, 0);
    IERC20(asset).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[1];
  }

  function _convert_asset_to(address assetIn, address assetOut, uint256 amount, bytes32 pool) internal returns (int256) {
    if (amount < CONVERSION_MIN) {
      return int256(0);
    }

    if (assetIn == WETH && assetOut == BADGER) {
        return _convert_weth_to_badger(amount);
    }

    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(assetIn);
    assets[1] = IAsset(assetOut);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
    sender: address(this),
    fromInternalBalance: false,
    recipient: payable(address(this)),
    toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory assetSwapStep = IBalancerVault.BatchSwapStep(
    {
    poolId: pool,
    assetInIndex: uint256(0),
    assetOutIndex: uint256(1),
    amount: amount,
    userData: ""
    });

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](1);
    steps[0] = assetSwapStep;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](2);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(assetIn).safeApprove(BALANCER_VAULT, 0);
    IERC20(assetIn).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[1];
  }

  function _convert_weth_to_badger(uint256 amount) internal returns (int256) {
    IAsset[] memory assets = new IAsset[](3);
    assets[0] = IAsset(WETH);
    assets[1] = IAsset(WBTC);
    assets[2] = IAsset(BADGER);

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
    {
    sender: address(this),
    fromInternalBalance: false,
    recipient: payable(address(this)),
    toInternalBalance: false
    });

    IBalancerVault.BatchSwapStep memory step1 = IBalancerVault.BatchSwapStep(
    {
    poolId: WBTC_WETH_POOL_ID,
    assetInIndex: uint256(0),
    assetOutIndex: uint256(1),
    amount: amount,
    userData: ""
    }
    );

    IBalancerVault.BatchSwapStep memory step2 = IBalancerVault.BatchSwapStep(
    {
    poolId: BADGER_WBTC_POOL_ID,
    assetInIndex: uint256(1),
    assetOutIndex: uint256(2),
    amount: uint256(0),
    userData: ""
    }
    );

    IBalancerVault.BatchSwapStep[] memory steps = new IBalancerVault.BatchSwapStep[](2);
    steps[0] = step1;
    steps[1] = step2;

    IBalancerVault vault = IBalancerVault(payable(BALANCER_VAULT));
    int256[] memory limits = new int256[](3);
    limits[0] = int256(1e20);
    limits[1] = int256(1e20);
    limits[2] = int256(1e20);
    uint256 MAX_INT = 2**256-1;

    IERC20(WETH).safeApprove(BALANCER_VAULT, 0);
    IERC20(WETH).safeApprove(BALANCER_VAULT, type(uint128).max);
    int256[] memory assetDeltas = vault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN, steps, assets, funds, limits, MAX_INT);

    return assetDeltas[2];
  }

  function _convert_aura(uint256 amount) internal returns (int256) {
    if (aura_convert_enabled == true) {
      return _convert_reward_asset(AURA, amount, AURA_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  function _convert_auraBAL(uint256 amount) internal returns (int256) {
    if (auraBal_convert_enabled == true) {
      return _convert_reward_asset(AURA_BAL, amount, AURABAL_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  function _convert_bb_a_USD(uint256 amount) internal returns (int256) {
    if (bBal_convert_enabled == true) {
      return _convert_reward_asset(BB_A_USD, amount, BBAUSD_WETH_POOL_ID);
    } else {
      return int256(0);
    }
  }

  /// GETTERS
  /// @dev Get autocompounder holdings after autocompounding
  function get_autocompounder_holdings() external view returns (uint256) {
    return badger_the_vault.balanceOf(address(this));
  }

  function get_badger_holdings() external view returns (uint256) {
    return badger_the_vault.balanceOf(address(this));
  }

  /// GOVERNANCE
  /// @dev Set new contract address
  /// @param _badger_sett BadgerDAO Sett vault
  function set_badger_sett(address _badger_sett) external {
    require(msg.sender == governance, "must be governance");
    badger_the_vault = ITheVault(_badger_sett);
  }

  /// @dev Set the Badger Tree
  /// @param _badger_tree Address of Badger Tree used to determine rewards
  function set_badger_tree(address _badger_tree) external {
    require(msg.sender == governance, "must be governance");
    badger_tree = IBadgerTreeV2(_badger_tree);
  }

  /// @dev Toggle autocompounding
  function set_autocompound_enabled(bool _enabled) external {
    require(msg.sender == governance, "must be governance");
    autocompound_enabled = _enabled;
  }

  /// @dev Withdraw funds from Badger Sett in case of emergency
  function emergency_withdraw() external {
    require(msg.sender == governance, "must be governance");
    badger_the_vault.withdrawAll();
  }

  /// GOVERNANCE
  /// @dev Propose governance transfer
  /// @param to Governance account address to propose
  function propose_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  /// @dev Accept governance transfer
  function accept_governance() external {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  /// @dev Sweep funds in case of emergency
  /// @param _token Token to sweep from this contract
  /// @param _to Sweep funds to this recipient's account address
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

  /// @dev Configuration to enable conversion of AURA reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_aura_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    aura_convert_enabled = enable_setting;
  }

  /// @dev Configuration to enable conversion AuraBal reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_auraBal_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    auraBal_convert_enabled = enable_setting;
  }

  /// @dev Configuration to enable conversion Balancer Aave Boosted StablePool reward
  /// @param enable_setting True to enable conversion, false to prevent conversion
  function set_bbalUsd_convert(bool enable_setting) external {
    require(msg.sender == governance, "must be governance");
    bBal_convert_enabled = enable_setting;
  }
}

/// @title Saffron Badger Adapter integrates the Aura - BADGER/WBTC vault with Saffron Pool V2
contract Saffron_Badger_Adapter is ISaffron_Badger_AdapterV2, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Governance and pool 
  address public governance;                          // Governance address
  address public new_governance;                      // Newly proposed governance address
  address public saffron_pool;                        // SaffronPool that owns this adapter

  // Platform-specific vars
  IERC20 public SETT_LP;                                  // Sett address (Badger Sett LP token)
  IERC20 public deposit_token;                           // The deposit token (WBTC)
  SaffronBadgerAutocompounder public autocompounder;     // Auto-Compounder

  // Saffron identifiers
  string public constant platform = "Badger";     // Platform name
  string public name;                                 // Adapter name

  /// @param _lp_address LP token address (e.g. Badger Sett 20WBTC-80BADGER)
  /// @param _deposit_token Token to deposit into Badger Sett (e.g. 20WBTC-80BADGER)
  /// @param _name Name of adapter (e.g. "Saffron Badger Adapter")
  constructor(address _lp_address, address _deposit_token, string memory _name) {
    require(_lp_address != address(0x0), "can't construct with 0 address");
    governance = msg.sender;
    name       = _name;
    SETT_LP     = IERC20(_lp_address);
    deposit_token = IERC20(_deposit_token);
  }

  // System Events
  event CapitalDeployed(uint256 lp_amount);
  event CapitalReturned(uint256 lp_amount, address to);
  event Holdings(uint256 holdings);
  event ErcSwept(address who, address to, address token, uint256 amount);

  /// @dev Adds funds (WBTC) to underlying protocol. Called from pool's deposit function
  function deploy_capital(uint256 lp_amount) external override nonReentrant returns (uint256){
    require(msg.sender == saffron_pool, "must be pool");

    // Send lp to autocompounder and deposit into BadgerDAO
    emit CapitalDeployed(lp_amount);
    deposit_token.safeTransfer(address(autocompounder), lp_amount);
    autocompounder.blend(lp_amount);
    return lp_amount;
  }

  /// @dev Returns funds to user. Called from pool's withdraw function
  function return_capital(uint256 lp_amount, address to) external override nonReentrant {
    require(msg.sender == saffron_pool, "must be pool");
    emit CapitalReturned(lp_amount, to);
    autocompounder.spill(lp_amount, to);
  }

  /// @dev Return autocompounder holdings and log (for use in pool / adapter core functions)
  function get_holdings() external override nonReentrant returns(uint256 holdings) {
    holdings = autocompounder.get_autocompounder_holdings();
    emit Holdings(holdings);
  }

  /// @dev Backwards compatible holdings getter (can be removed in next upgrade for gas efficiency)
  function get_holdings_view() external override view returns(uint256 holdings) {
    return autocompounder.get_autocompounder_holdings();
  }

  /// GOVERNANCE
  /// @dev Set a new Saffron autocompounder address
  /// @param _autocompounder Address of Autocompounder contract
  function set_autocompounder(address _autocompounder) external {
    require(msg.sender == governance, "must be governance");
    autocompounder = SaffronBadgerAutocompounder(_autocompounder);
  }

  /// @dev Set a new pool address
  /// @param pool Address of Saffron Pool V2
  function set_pool(address pool) external override {
    require(msg.sender == governance, "must be governance");
    require(pool != address(0x0), "can't set pool to 0 address");
    saffron_pool = pool;
  }

  /// @dev Set a new LP token
  /// @param addr Address of adapter's LP token
  function set_lp(address addr) external override {
    require(msg.sender == governance, "must be governance");
    SETT_LP=IERC20(addr);
  }

  /// @dev Set a new deposit token
  /// @param addr Address of token to deposit into Badger Sett vault
  function set_deposit_token(address addr) external override {
    require(msg.sender == governance, "must be governance");
    deposit_token=IERC20(addr);
  }

  /// @dev Governance transfer
  /// @param to Proposed governance account address
  function propose_governance(address to) external override {
    require(msg.sender == governance, "must be governance");
    require(to != address(0), "can't set to 0");
    new_governance = to;
  }

  /// @dev Governance transfer
  function accept_governance() external override {
    require(msg.sender == new_governance, "must be new governance");
    governance = msg.sender;
    new_governance = address(0);
  }

  /// @dev Sweep funds in case of emergency
  /// @param _token Token address to sweep
  /// @param _to Recipient's address
  function sweep_erc(address _token, address _to) external {
    require(msg.sender == governance, "must be governance");
    IERC20 token = IERC20(_token);
    uint256 token_balance = token.balanceOf(address(this));
    emit ErcSwept(msg.sender, _to, _token, token_balance);
    token.transfer(_to, token_balance);
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library WeightedPoolUserData {
  // In order to preserve backwards compatibility, make sure new join and exit kinds are added at the end of the enum.
  enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
    ADD_TOKEN // for Managed Pool
  }
  enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT,
    REMOVE_TOKEN // for ManagedPool
  }

  function joinKind(bytes memory self) internal pure returns (JoinKind) {
    return abi.decode(self, (JoinKind));
  }

  function exitKind(bytes memory self) internal pure returns (ExitKind) {
    return abi.decode(self, (ExitKind));
  }

  // Joins

  function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
    (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
  }

  function exactTokensInForBptOut(bytes memory self)
  internal
  pure
  returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
  {
    (, amountsIn, minBPTAmountOut) = abi.decode(self, (JoinKind, uint256[], uint256));
  }

  function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
    (, bptAmountOut, tokenIndex) = abi.decode(self, (JoinKind, uint256, uint256));
  }

  function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
    (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
  }

  function addToken(bytes memory self) internal pure returns (uint256 amountIn) {
    (, amountIn) = abi.decode(self, (JoinKind, uint256));
  }

  // Exits

  function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
    (, bptAmountIn, tokenIndex) = abi.decode(self, (ExitKind, uint256, uint256));
  }

  function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
    (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
  }

  function bptInForExactTokensOut(bytes memory self)
  internal
  pure
  returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
  {
    (, amountsOut, maxBPTAmountIn) = abi.decode(self, (ExitKind, uint256[], uint256));
  }

  // Managed Pool
  function removeToken(bytes memory self) internal pure returns (uint256 tokenIndex) {
    (, tokenIndex) = abi.decode(self, (ExitKind, uint256));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../interfaces/ISignaturesValidator.sol";
import "../interfaces/ITemporarilyPausable.sol";
import "../interfaces/IWETH.sol";

import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";

pragma solidity ^0.8.4;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBalancerSwapVault {
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
  }

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct PoolBalanceOp {
    uint8 kind;
    bytes32 poolId;
    address token;
    uint256 amount;
  }

  struct UserBalanceOp {
    uint8 kind;
    address asset;
    uint256 amount;
    address sender;
    address recipient;
  }

  struct SingleSwap {
    bytes32 poolId;
    uint8 kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITheVault {
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  event Harvested(
    address indexed token,
    uint256 amount,
    uint256 indexed blockNumber,
    uint256 timestamp
  );
  event PauseDeposits(address indexed pausedBy);
  event Paused(address account);
  event SetGuardian(address indexed newGuardian);
  event SetGuestList(address indexed newGuestList);
  event SetManagementFee(uint256 newManagementFee);
  event SetMaxManagementFee(uint256 newMaxManagementFee);
  event SetMaxPerformanceFee(uint256 newMaxPerformanceFee);
  event SetMaxWithdrawalFee(uint256 newMaxWithdrawalFee);
  event SetPerformanceFeeGovernance(uint256 newPerformanceFeeGovernance);
  event SetPerformanceFeeStrategist(uint256 newPerformanceFeeStrategist);
  event SetStrategy(address indexed newStrategy);
  event SetToEarnBps(uint256 newEarnToBps);
  event SetTreasury(address indexed newTreasury);
  event SetWithdrawalFee(uint256 newWithdrawalFee);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TreeDistribution(
    address indexed token,
    uint256 amount,
    uint256 indexed blockNumber,
    uint256 timestamp
  );
  event UnpauseDeposits(address indexed pausedBy);
  event Unpaused(address account);

  function MANAGEMENT_FEE_HARD_CAP() external view returns (uint256);

  function MAX_BPS() external view returns (uint256);

  function PERFORMANCE_FEE_HARD_CAP() external view returns (uint256);

  function SECS_PER_YEAR() external view returns (uint256);

  function WITHDRAWAL_FEE_HARD_CAP() external view returns (uint256);

  function additionalTokensEarned(address) external view returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function assetsAtLastHarvest() external view returns (uint256);

  function available() external view returns (uint256);

  function badgerTree() external view returns (address);

  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue)
  external
  returns (bool);

  function deposit(uint256 _amount, bytes32[] memory proof) external;

  function deposit(uint256 _amount) external;

  function depositAll(bytes32[] memory proof) external;

  function depositAll() external;

  function depositFor(address _recipient, uint256 _amount) external;

  function depositFor(
    address _recipient,
    uint256 _amount,
    bytes32[] memory proof
  ) external;

  function earn() external;

  function emitNonProtectedToken(address _token) external;

  function getPricePerFullShare() external view returns (uint256);

  function governance() external view returns (address);

  function guardian() external view returns (address);

  function guestList() external view returns (address);

  function increaseAllowance(address spender, uint256 addedValue)
  external
  returns (bool);

  function initialize(
    address _token,
    address _governance,
    address _keeper,
    address _guardian,
    address _treasury,
    address _strategist,
    address _badgerTree,
    string memory _name,
    string memory _symbol,
    uint256[4] memory _feeConfig
  ) external;

  function keeper() external view returns (address);

  function lastAdditionalTokenAmount(address) external view returns (uint256);

  function lastHarvestAmount() external view returns (uint256);

  function lastHarvestedAt() external view returns (uint256);

  function lifeTimeEarned() external view returns (uint256);

  function managementFee() external view returns (uint256);

  function maxManagementFee() external view returns (uint256);

  function maxPerformanceFee() external view returns (uint256);

  function maxWithdrawalFee() external view returns (uint256);

  function name() external view returns (string memory);

  function pause() external;

  function pauseDeposits() external;

  function paused() external view returns (bool);

  function pausedDeposit() external view returns (bool);

  function performanceFeeGovernance() external view returns (uint256);

  function performanceFeeStrategist() external view returns (uint256);

  function reportAdditionalToken(address _token) external;

  function reportHarvest(uint256 _harvestedAmount) external;

  function setGovernance(address _governance) external;

  function setGuardian(address _guardian) external;

  function setGuestList(address _guestList) external;

  function setKeeper(address _keeper) external;

  function setManagementFee(uint256 _fees) external;

  function setMaxManagementFee(uint256 _fees) external;

  function setMaxPerformanceFee(uint256 _fees) external;

  function setMaxWithdrawalFee(uint256 _fees) external;

  function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance)
  external;

  function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist)
  external;

  function setStrategist(address _strategist) external;

  function setStrategy(address _strategy) external;

  function setToEarnBps(uint256 _newToEarnBps) external;

  function setTreasury(address _treasury) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function strategist() external view returns (address);

  function strategy() external view returns (address);

  function sweepExtraToken(address _token) external;

  function symbol() external view returns (string memory);

  function toEarnBps() external view returns (uint256);

  function token() external view returns (address);

  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount)
  external
  returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function treasury() external view returns (address);

  function unpause() external;

  function unpauseDeposits() external;

  function version() external pure returns (string memory);

  function withdraw(uint256 _shares) external;

  function withdrawAll() external;

  function withdrawToVault() external;

  function withdrawalFee() external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"Harvested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pausedBy","type":"address"}],"name":"PauseDeposits","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newGuardian","type":"address"}],"name":"SetGuardian","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newGuestList","type":"address"}],"name":"SetGuestList","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newManagementFee","type":"uint256"}],"name":"SetManagementFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxManagementFee","type":"uint256"}],"name":"SetMaxManagementFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxPerformanceFee","type":"uint256"}],"name":"SetMaxPerformanceFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxWithdrawalFee","type":"uint256"}],"name":"SetMaxWithdrawalFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newPerformanceFeeGovernance","type":"uint256"}],"name":"SetPerformanceFeeGovernance","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newPerformanceFeeStrategist","type":"uint256"}],"name":"SetPerformanceFeeStrategist","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newStrategy","type":"address"}],"name":"SetStrategy","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newEarnToBps","type":"uint256"}],"name":"SetToEarnBps","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newTreasury","type":"address"}],"name":"SetTreasury","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newWithdrawalFee","type":"uint256"}],"name":"SetWithdrawalFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"TreeDistribution","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pausedBy","type":"address"}],"name":"UnpauseDeposits","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"MANAGEMENT_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_BPS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERFORMANCE_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SECS_PER_YEAR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WITHDRAWAL_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"additionalTokensEarned","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"assetsAtLastHarvest","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"available","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"badgerTree","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"depositAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"depositAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_recipient","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"depositFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_recipient","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"depositFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"earn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"emitNonProtectedToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getPricePerFullShare","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"guardian","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"guestList","outputs":[{"internalType":"contract BadgerGuestListAPI","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_governance","type":"address"},{"internalType":"address","name":"_keeper","type":"address"},{"internalType":"address","name":"_guardian","type":"address"},{"internalType":"address","name":"_treasury","type":"address"},{"internalType":"address","name":"_strategist","type":"address"},{"internalType":"address","name":"_badgerTree","type":"address"},{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"},{"internalType":"uint256[4]","name":"_feeConfig","type":"uint256[4]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"keeper","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"lastAdditionalTokenAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastHarvestAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastHarvestedAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lifeTimeEarned","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"managementFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxManagementFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxPerformanceFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxWithdrawalFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"pauseDeposits","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pausedDeposit","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"performanceFeeGovernance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"performanceFeeStrategist","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"reportAdditionalToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_harvestedAmount","type":"uint256"}],"name":"reportHarvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_governance","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_guardian","type":"address"}],"name":"setGuardian","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_guestList","type":"address"}],"name":"setGuestList","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_keeper","type":"address"}],"name":"setKeeper","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setManagementFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxManagementFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxPerformanceFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxWithdrawalFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceFeeGovernance","type":"uint256"}],"name":"setPerformanceFeeGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceFeeStrategist","type":"uint256"}],"name":"setPerformanceFeeStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategist","type":"address"}],"name":"setStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategy","type":"address"}],"name":"setStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newToEarnBps","type":"uint256"}],"name":"setToEarnBps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_treasury","type":"address"}],"name":"setTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_withdrawalFee","type":"uint256"}],"name":"setWithdrawalFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"strategist","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"strategy","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"sweepExtraToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"toEarnBps","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"token","outputs":[{"internalType":"contract IERC20Upgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"treasury","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpauseDeposits","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_shares","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawToVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawalFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBadgerTreeV2 {
  event Claimed(
    address indexed user,
    address indexed token,
    uint256 amount,
    uint256 indexed cycle,
    uint256 timestamp,
    uint256 blockNumber
  );
  event InsufficientFundsForRoot(bytes32 indexed root);
  event Paused(address account);
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );
  event RootProposed(
    uint256 indexed cycle,
    bytes32 indexed root,
    bytes32 indexed contentHash,
    uint256 startBlock,
    uint256 endBlock,
    uint256 timestamp,
    uint256 blockNumber
  );
  event RootUpdated(
    uint256 indexed cycle,
    bytes32 indexed root,
    bytes32 indexed contentHash,
    uint256 startBlock,
    uint256 endBlock,
    uint256 timestamp,
    uint256 blockNumber
  );
  event Unpaused(address account);

  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function PAUSER_ROLE() external view returns (bytes32);

  function ROOT_PROPOSER_ROLE() external view returns (bytes32);

  function ROOT_VALIDATOR_ROLE() external view returns (bytes32);

  function UNPAUSER_ROLE() external view returns (bytes32);

  function approveRoot(
    bytes32 root,
    bytes32 contentHash,
    uint256 cycle,
    uint256 startBlock,
    uint256 endBlock
  ) external;

  function claim(
    address[] memory tokens,
    uint256[] memory cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] memory merkleProof,
    uint256[] memory amountsToClaim
  ) external;

  function claimed(address, address) external view returns (uint256);

  function currentCycle() external view returns (uint256);

  function encodeClaim(
    address[] memory tokens,
    uint256[] memory cumulativeAmounts,
    address account,
    uint256 index,
    uint256 cycle
  ) external pure returns (bytes memory encoded, bytes32 hash);

  function getClaimableFor(
    address user,
    address[] memory tokens,
    uint256[] memory cumulativeAmounts
  ) external view returns (address[] memory, uint256[] memory);

  function getClaimedFor(address user, address[] memory tokens)
  external
  view
  returns (address[] memory, uint256[] memory);

  function getCurrentMerkleData()
  external
  view
  returns (BadgerTreeV2.MerkleData memory);

  function getMerkleRootFor(uint256 cycle) external view returns (bytes32);

  function getPendingMerkleData()
  external
  view
  returns (BadgerTreeV2.MerkleData memory);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function getRoleMember(bytes32 role, uint256 index)
  external
  view
  returns (address);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function grantRole(bytes32 role, address account) external;

  function hasPendingRoot() external view returns (bool);

  function hasRole(bytes32 role, address account)
  external
  view
  returns (bool);

  function initialize(
    address admin,
    address initialProposer,
    address initialValidator
  ) external;

  function isClaimAvailableFor(
    address user,
    address[] memory tokens,
    uint256[] memory cumulativeAmounts
  ) external view returns (bool);

  function lastProposeBlockNumber() external view returns (uint256);

  function lastProposeEndBlock() external view returns (uint256);

  function lastProposeStartBlock() external view returns (uint256);

  function lastProposeTimestamp() external view returns (uint256);

  function lastPublishBlockNumber() external view returns (uint256);

  function lastPublishEndBlock() external view returns (uint256);

  function lastPublishStartBlock() external view returns (uint256);

  function lastPublishTimestamp() external view returns (uint256);

  function merkleContentHash() external view returns (bytes32);

  function merkleRoot() external view returns (bytes32);

  function pause() external;

  function paused() external view returns (bool);

  function pendingCycle() external view returns (uint256);

  function pendingMerkleContentHash() external view returns (bytes32);

  function pendingMerkleRoot() external view returns (bytes32);

  function proposeRoot(
    bytes32 root,
    bytes32 contentHash,
    uint256 cycle,
    uint256 startBlock,
    uint256 endBlock
  ) external;

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function setCycle(uint256 x) external;

  function totalClaimed(address) external view returns (uint256);

  function unpause() external;
}

interface BadgerTreeV2 {
  struct MerkleData {
    bytes32 root;
    bytes32 contentHash;
    uint256 timestamp;
    uint256 publishBlock;
    uint256 startBlock;
    uint256 endBlock;
  }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"Claimed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"}],"name":"InsufficientFundsForRoot","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"previousAdminRole","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"newAdminRole","type":"bytes32"}],"name":"RoleAdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleGranted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleRevoked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"startBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"endBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"RootProposed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"startBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"endBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"RootUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"DEFAULT_ADMIN_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PAUSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ROOT_PROPOSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ROOT_VALIDATOR_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"UNPAUSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"name":"approveRoot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"bytes32[]","name":"merkleProof","type":"bytes32[]"},{"internalType":"uint256[]","name":"amountsToClaim","type":"uint256[]"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"claimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentCycle","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"},{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"uint256","name":"cycle","type":"uint256"}],"name":"encodeClaim","outputs":[{"internalType":"bytes","name":"encoded","type":"bytes"},{"internalType":"bytes32","name":"hash","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"}],"name":"getClaimableFor","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"}],"name":"getClaimedFor","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCurrentMerkleData","outputs":[{"components":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"publishBlock","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"internalType":"struct BadgerTreeV2.MerkleData","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"cycle","type":"uint256"}],"name":"getMerkleRootFor","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPendingMerkleData","outputs":[{"components":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"publishBlock","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"internalType":"struct BadgerTreeV2.MerkleData","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleAdmin","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"getRoleMember","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleMemberCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"grantRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"hasPendingRoot","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"admin","type":"address"},{"internalType":"address","name":"initialProposer","type":"address"},{"internalType":"address","name":"initialValidator","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"}],"name":"isClaimAvailableFor","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeBlockNumber","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeEndBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeStartBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishBlockNumber","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishEndBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishStartBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"merkleContentHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"merkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingCycle","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingMerkleContentHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingMerkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"name":"proposeRoot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"renounceRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"revokeRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"x","type":"uint256"}],"name":"setCycle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"totalClaimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISaffron_Badger_AdapterV2 {
    function set_pool(address pool) external;
    function deploy_capital(uint256 lp_amount) external returns(uint256);
    function return_capital(uint256 lp_amount, address to) external;
    function get_holdings() external returns(uint256);
    function set_lp(address addr) external;
    function propose_governance(address to) external;
    function accept_governance() external;
    function get_holdings_view() external view returns(uint256);
    function set_deposit_token(address addr) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

import "./IERC20.sol";

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../interfaces/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";

import "./IVault.sol";
import "./IAuthorizer.sol";

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}