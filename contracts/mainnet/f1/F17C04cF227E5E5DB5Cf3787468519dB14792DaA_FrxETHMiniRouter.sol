/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/Curve/ICurvefrxETHETHPool.sol


interface ICurvefrxETHETHPool {
  function A() external view returns (uint256);
  function A_precise() external view returns (uint256);
  function get_p() external view returns (uint256);
  function price_oracle() external view returns (uint256);
  function get_virtual_price() external view returns (uint256);
  function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);
  function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
  function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external payable returns (uint256);
  function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
  function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
  function ramp_A(uint256 _future_A, uint256 _future_time) external;
  function stop_ramp_A() external;
  function commit_new_fee(uint256 _new_fee, uint256 _new_admin_fee) external;
  function apply_new_fee() external;
  function revert_new_parameters() external;
  function set_ma_exp_time(uint256 _ma_exp_time) external;
  function commit_transfer_ownership(address _owner) external;
  function apply_transfer_ownership() external;
  function revert_transfer_ownership() external;
  function admin_balances(uint256 i) external view returns (uint256);
  function withdraw_admin_fees() external;
  function donate_admin_fees() external;
  function kill_me() external;
  function unkill_me() external;
  function coins(uint256 arg0) external view returns (address);
  function balances(uint256 arg0) external view returns (uint256);
  function fee() external view returns (uint256);
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
  function future_owner() external view returns (address);
  function ma_exp_time() external view returns (uint256);
  function ma_last_time() external view returns (uint256);
}


// File contracts/FraxETH/IfrxETH.sol


interface IfrxETH {
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function acceptOwnership (  ) external;
  function addMinter ( address minter_address ) external;
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account, uint256 amount ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function minter_burn_from ( address b_address, uint256 b_amount ) external;
  function minter_mint ( address m_address, uint256 m_amount ) external;
  function minters ( address ) external view returns ( bool );
  function minters_array ( uint256 ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function nominateNewOwner ( address _owner ) external;
  function nominatedOwner (  ) external view returns ( address );
  function nonces ( address owner ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function permit ( address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external;
  function removeMinter ( address minter_address ) external;
  function setTimelock ( address _timelock_address ) external;
  function symbol (  ) external view returns ( string memory );
  function timelock_address (  ) external view returns ( address );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
}


// File contracts/FraxETH/IfrxETHMinter.sol


interface IfrxETHMinter {
struct Validator {
    bytes pubKey;
    bytes signature;
    bytes32 depositDataRoot;
}

  function DEPOSIT_SIZE (  ) external view returns ( uint256 );
  function RATIO_PRECISION (  ) external view returns ( uint256 );
  function acceptOwnership (  ) external;
  function activeValidators ( bytes memory ) external view returns ( bool );
  function addValidator ( Validator memory validator ) external;
  function addValidators ( Validator[] memory validatorArray ) external;
  function clearValidatorArray (  ) external;
  function currentWithheldETH (  ) external view returns ( uint256 );
  function depositContract (  ) external view returns ( address );
  function depositEther ( uint256 max_deposits ) external;
  function depositEtherPaused (  ) external view returns ( bool );
  function frxETHToken (  ) external view returns ( address );
  function getValidator ( uint256 i ) external view returns ( bytes memory pubKey, bytes memory withdrawalCredentials, bytes memory signature, bytes32 depositDataRoot );
  function getValidatorStruct ( bytes memory pubKey, bytes memory signature, bytes32 depositDataRoot ) external pure returns ( Validator memory );
  function moveWithheldETH ( address to, uint256 amount ) external;
  function nominateNewOwner ( address _owner ) external;
  function nominatedOwner (  ) external view returns ( address );
  function numValidators (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function popValidators ( uint256 times ) external;
  function recoverERC20 ( address tokenAddress, uint256 tokenAmount ) external;
  function recoverEther ( uint256 amount ) external;
  function removeValidator ( uint256 remove_idx, bool dont_care_about_ordering ) external;
  function setTimelock ( address _timelock_address ) external;
  function setWithdrawalCredential ( bytes memory _new_withdrawal_pubkey ) external;
  function setWithholdRatio ( uint256 newRatio ) external;
  function sfrxETHToken (  ) external view returns ( address );
  function submit (  ) external payable;
  function submitAndDeposit ( address recipient ) external payable returns ( uint256 shares );
  function submitAndGive ( address recipient ) external payable;
  function submitPaused (  ) external view returns ( bool );
  function swapValidator ( uint256 from_idx, uint256 to_idx ) external;
  function timelock_address (  ) external view returns ( address );
  function togglePauseDepositEther (  ) external;
  function togglePauseSubmits (  ) external;
  function withholdRatio (  ) external view returns ( uint256 );
}


// File contracts/FraxETH/IsfrxETH.sol


// Primarily added to prevent ERC20 name collisions in frxETHMinter.sol
interface IsfrxETH {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function asset() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function decimals() external view returns (uint8);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function depositWithSignature(uint256 assets, address receiver, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 shares);
    function lastRewardAmount() external view returns (uint192);
    function lastSync() external view returns (uint32);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function rewardsCycleEnd() external view returns (uint32);
    function rewardsCycleLength() external view returns (uint32);
    function symbol() external view returns (string memory);
    function syncRewards() external;
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}


// File contracts/FraxETH/FrxETHMiniRouter.sol






// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FrxETHMiniRouter =========================
// ====================================================================
// Routes ETH -> frxETH and ETH -> sfrxETH via the minter or via Curve, depending on pricing

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna


contract FrxETHMiniRouter  {
    /* ========== STATE VARIABLES ========== */
    IfrxETH public frxETH = IfrxETH(0x5E8422345238F34275888049021821E8E08CAa1f);
    IfrxETHMinter public minter = IfrxETHMinter(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);
    IsfrxETH public sfrxETH = IsfrxETH(0xac3E018457B222d93114458476f3E3416Abbe38F);
    ICurvefrxETHETHPool public pool = ICurvefrxETHETHPool(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
        // Nothing
    }

    /* ========== VIEWS ========== */

    // Get the prices and estimated frxETH out amounts
    function getFrxETHRoutePricesAndOuts(uint256 eth_in) public view returns (
        uint256 minter_price, 
        uint256 minter_out, 
        uint256 curve_price,
        uint256 curve_out,
        bool use_curve // false: Minter, true: Curve
    ) {
        // Minter prices are fixed
        minter_price = 1e18;
        minter_out = eth_in;

        // Get the Curve info
        curve_price = pool.price_oracle();
        curve_out = pool.get_dy(0, 1, eth_in);

        // Use Curve if you get more frxEth out
        use_curve = (curve_out >= minter_out);
    }

    // Get the prices and estimated frxETH out amounts
    function sendETH(
        address recipient, 
        bool get_sfrxeth_instead, 
        uint256 min_frxeth_out
    ) external payable returns (
        uint256 frxeth_used, 
        uint256 frxeth_out,
        uint256 sfrxeth_out
    ) {
        // First see which route to take
        (, , , , bool use_curve) = getFrxETHRoutePricesAndOuts(msg.value);

        // Take different routes for frxETH depending on pricing
        if (use_curve) {
            frxeth_used = pool.exchange{ value: msg.value }(0, 1, msg.value, min_frxeth_out);
        }
        else {
            minter.submit{ value: msg.value }();
            frxeth_used = msg.value;
        }

        // Convert the frxETH to sfrxETH if the user specified it
        if (get_sfrxeth_instead) {
            // Approve frxETH to sfrxETH for staking
            frxETH.approve(address(sfrxETH), msg.value);

            // Deposit the frxETH and give the generated sfrxETH to the final recipient
            sfrxeth_out = sfrxETH.deposit(msg.value, recipient);
            require(sfrxeth_out > 0, 'No sfrxETH was returned');

            emit ETHToSfrxETH(msg.sender, recipient, use_curve, msg.value, frxeth_used, sfrxeth_out);
        } else {
            // Set the frxETH out to the frxETH used
            frxeth_out = frxeth_used;

            // Give the frxETH to the recipient
            frxETH.transfer(recipient, frxeth_out);

            emit ETHToFrxETH(msg.sender, recipient, use_curve, msg.value, frxeth_out);
        }
    }

    /* ========== EVENTS ========== */
    event ETHToFrxETH(address indexed from, address indexed recipient, bool curve_used, uint256 eth_in, uint256 frxeth_out);
    event ETHToSfrxETH(address indexed from, address indexed recipient, bool curve_used, uint256 amt_in, uint256 frxeth_used, uint256 sfrxeth_out);
}