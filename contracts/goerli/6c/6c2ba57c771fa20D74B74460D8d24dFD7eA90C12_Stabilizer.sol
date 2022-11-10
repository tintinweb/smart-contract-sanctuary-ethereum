// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

import "../Sweep/ISweep.sol";
import "../Common/ERC20/ERC20.sol";
import "../AMM/IAMM.sol";
import "../Utils/Math/Math.sol";
import "../Utils/Uniswap/V2/TransferHelper.sol";
import "../Assets/IAsset.sol";

/**
 * @title Stabilizer
 * @author MAXOS Team - https://maxos.finance/
 * @dev Implementation:
 * Facilitates the investment and paybacks of off-chain & on-chain strategies
 * Allows to deposit and withdraw usdx
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 * Requires that the EquityRatio > MinimumEquityRatio when:
 * minting => increase of the senior tranche
 * withdrawing => decrease of the junior tranche
 */
contract Stabilizer {
  uint public sweep_borrowed;
  uint public minimum_equity_ratio;

  // Investment Strategy
  IAsset public asset;

  address public banker;
  address public admin;
  address public settings_manager;

  // Swaps
  IAMM public amm;

  // Tokens
  ISweep public sweep;
  ERC20 public usdx;

  // Control
  bool public frozen;

  constructor(
    address _admin_address,
    address _amm_address,
    address _sweep_address,
    address _usdx_address,
    uint _minimum_equity_ratio

  ) {
    admin = _admin_address;
    banker = _admin_address;
    settings_manager = _admin_address;

    amm = IAMM(_amm_address);
    sweep = ISweep(_sweep_address);
    usdx = ERC20(_usdx_address);

    minimum_equity_ratio = _minimum_equity_ratio;
    frozen = false;
  }

  // ERRORS ====================================================================

  error InputIsZero();
  error StabilizerNotWhitelisted();
  error NotEnoughBalance();
  error BurningMoreThanMinted();
  error MaximumMintExcess();
  error MinimumEquityRatioExcess();
  error TargetPriceTooLow();
  error TargetPriceTooHigh();
  error StabilizerFrozen();

  error OnlyBanker();
  error OnlyAdmin();
  error OnlySettingsManager();

  // EVENTS ====================================================================

  event Minted(uint sweep_amount);
  event Sold(uint sweep_amount);
  event Invested(address token, uint amount);
  event Paidback(address token, uint amount);
  event Bought(uint sweep_amount);
  event Burnt(uint sweep_amount);
  event Withdrawn(address token, uint amount);
  event Collected(address owner);

  event FrozenChanged(bool frozen);
  event AdminChanged(address new_admin);
  event BankerChanged(address new_banker);
  event SettingsManagerChanged(address new_settings_manager);

  event AssetChanged(address asset);
  event MinimumEquityRatioChanged(uint minimum_equity_ratio);

  // MODIFIERS =================================================================

  modifier notFrozen {
    if(frozen) { revert StabilizerFrozen(); }
    _;
  }

  modifier onlyBanker {
    if(msg.sender != banker) { revert OnlyBanker(); }
    _;
  }

  modifier onlyAdmin {
    if(msg.sender != admin) { revert OnlyAdmin(); }
    _;
  }

  modifier onlySettingsManager {
    if(msg.sender != settings_manager) { revert OnlySettingsManager(); }
    _;
  }

  // ADMIN FUNCTIONS ===========================================================

  /**
   * @notice Set Admin - a MAXOS protocol representative.
   * @param _new_admin.
   */
  function setAdmin(address _new_admin) external onlyAdmin {
    admin = _new_admin;
    emit AdminChanged(admin);
  }

  /**
   * @notice Set Banker - who manages the investment actions.
   * @param _banker.
   */
  function setBanker(address _banker) external onlyAdmin {
    banker = _banker;
    settings_manager = _banker;
    emit BankerChanged(banker);
  }

  /**
   * @notice Frozen - stops investment actions.
   * @param _frozen.
   */
  function setFrozen(bool _frozen) external onlyAdmin {
    frozen = _frozen;
    emit FrozenChanged(frozen);
  }


  // SETTINGS FUNCTIONS ====================================================

  /**
   * @notice Set Asset to invest. This can be an On-Chain or Off-Chain asset.
   * @param _asset Address
   */
  function setAsset(address _asset) public onlySettingsManager {
    asset = IAsset(_asset);
    emit AssetChanged(_asset);
  }

  /**
   * @notice Set Minimum Equity Ratio that defines the junior tranche size.
   * @param _value New minimum equity ratio.
   * @dev this value is a percentage with 6 decimals.
   */
  function setMinimumEquityRatio(uint _value) public onlySettingsManager {
    minimum_equity_ratio = _value;
    emit MinimumEquityRatioChanged(_value);
  }

  /**
   * @notice set Settings Manager to control the global configuration.
   * @dev after delegating the settings management to the admin
   * the protocol will evaluate adding the stabilizer to the minter list.
   */
  function setSettingsManager() public onlySettingsManager {
    settings_manager = settings_manager == banker ? admin : banker;
    emit SettingsManagerChanged(settings_manager);
  }

  // BANKER FUNCTIONS ==========================================================

  /**
   * @notice Mint Sweep
   * Asks the stabilizer to mint a certain amount of sweep token.
   * @param sweep_amount.
   * @dev Increases the sweep_borrowed (senior tranche).
   */
  function mint(uint sweep_amount) public onlyBanker notFrozen {
    if(sweep_amount == 0) { revert InputIsZero(); }
    if(sweep.isValidMinter(address(this)) == false) { revert StabilizerNotWhitelisted(); }

    uint sweep_available = sweep.minters(address(this)).max_mint_amount - sweep_borrowed;
    if(sweep_available < sweep_amount) { revert MaximumMintExcess(); }

    uint sweep_price = sweep.amm_price();
    uint current_equity_ratio = calculateEquityRatio(sweep_amount, 0, sweep_price);
    if(current_equity_ratio < minimum_equity_ratio) { revert MinimumEquityRatioExcess(); }

    sweep.minter_mint(address(this), sweep_amount);

    sweep_borrowed += sweep_amount;

    emit Minted(sweep_amount);
  }

  /**
   * @notice Sell Sweep
   * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
   * @param sweep_amount.
   * @dev Decreases the sweep balance and increase usdx balance
   */
  function sell(uint sweep_amount) public onlyBanker notFrozen {
    if(sweep_amount == 0) { revert InputIsZero(); }
    if(sweep.balanceOf(address(this)) < sweep_amount) { revert NotEnoughBalance(); }

    uint sweep_price = sweep.amm_price();
    uint usdx_amount = SWEEPinUSDX(sweep_amount, sweep_price);

    TransferHelper.safeApprove(address(sweep), address(amm), sweep_amount);
    // expects 1% less to ensure swap exact input
    amm.swapExactInput(address(sweep), address(usdx), 3000, sweep_amount, usdx_amount * 99/100 );
    sweep.refreshTargetPrice(sweep_price);

    emit Sold(sweep_amount);
  }

  /**
   * @notice Invest USDX
   * Sends usdx balance from the STABILIZER to the ASSET address.
   * @param usdx_amount Amount to be invested.
   * @dev Decreases the usdx balance
   */
  function investUSDX(uint usdx_amount) external onlyBanker notFrozen {
    _invest(address(usdx), usdx_amount);
  }

  /**
   * @notice Invest SWEEP
   * Sends sweep balance from the STABILIZER to the (OffChain) ASSET address.
   * OnChainAssets will revert the transaction.
   * @param sweep_amount Amount to be invested.
   * @dev Decreases the usdx balance
   */
  function investSWEEP(uint sweep_amount) external onlyBanker notFrozen {
    _invest(address(sweep), sweep_amount);
  }

  /**
   * @notice Payback USDX
   * Sends balance from the ASSET to the STABILIZER.
   * @param usdx_amount Amount to be repaid.
   */
  function paybackUSDX(uint usdx_amount) external onlyBanker {
    _payback(address(usdx), usdx_amount);
  }

  /**
   * @notice Payback SWEEP
   * Sends balance from the ASSET to the STABILIZER.
   * @param sweep_amount Amount to be repaid.
   */
  function paybackSWEEP(uint sweep_amount) external onlyBanker {
    _payback(address(sweep), sweep_amount);
  }

  /**
   * @notice Buy
   * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
   * @param sweep_amount Amount to be changed in the AMM.
   * @dev Increases the sweep balance and decrease usdx balance.
   */
  function buy(uint sweep_amount) public onlyBanker notFrozen {
    if(sweep_amount == 0) { revert InputIsZero(); }

    uint sweep_price = sweep.amm_price();
    // sends 1% more to ensure swap exact output
    uint usdx_amount = SWEEPinUSDX(sweep_amount, sweep_price) * 101/100;
    if(usdx.balanceOf(address(this)) < usdx_amount) { revert NotEnoughBalance(); }

    TransferHelper.safeApprove(address(usdx), address(amm), usdx_amount);
    amm.swapExactOutput(address(usdx), address(sweep), 3000, sweep_amount, usdx_amount);
    sweep.refreshTargetPrice(sweep_price);

    emit Bought(sweep_amount);
  }

  /**
   * @notice Burn
   * Burns the sweep_amount to reduce the debt (senior tranche).
   * @param sweep_amount Amount to be burnt by Sweep.
   * @dev Decreases the sweep borrowed.
   */
  function burn(uint sweep_amount) public onlyBanker {
    if(sweep_amount == 0) { revert InputIsZero(); }
    if(sweep_borrowed < sweep_amount) { revert BurningMoreThanMinted(); }
    if(sweep.balanceOf(address(this)) < sweep_amount) { revert NotEnoughBalance(); }

    sweep_borrowed -= sweep_amount;

    TransferHelper.safeApprove(address(sweep), address(this), sweep_amount);
    sweep.minter_burn_from(sweep_amount);

    emit Burnt(sweep_amount);
  }

  /**
   * @notice Withdraw USDX
   * Takes out usdx_amount if the new equity ratio is higher than the minimum equity ratio.
   * @param usdx_amount.
   * @dev Decreases the usdx balance.
   */
  function withdrawUSDX(uint usdx_amount) external onlyBanker notFrozen {
    _withdraw(address(usdx), usdx_amount);
  }

  /**
   * @notice Withdraw SWEEP
   * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
   * @param sweep_amount.
   * @dev Decreases the sweep balance.
   */
  function withdrawSWEEP(uint sweep_amount) external onlyBanker notFrozen {
    _withdraw(address(sweep), sweep_amount);
  }

  /**
   * @notice Collect Rewards
   * Takes the rewards generated by the asset (On-Chain only).
   * @dev Rewards are sent to the banker.
   */
  function collect() external onlyBanker {
    asset.withdrawRewards(banker);
    emit Collected(banker);
  }

  /**
   * @notice Buy And Burn Profitably
   * Executes buy and burn sweep_amount of tokens only if the target price is higher than the current SWEEP price.
   * @param sweep_amount Amount to be bought and burnt.
   */
  function buyAndBurnProfitably(uint sweep_amount) external onlyBanker {
    if(sweep.target_price() < sweep.amm_price()) { revert TargetPriceTooLow(); }
    buy(sweep_amount);
    burn(sweep_amount);
  }

  /**
   * @notice Mint And Sell Profitably
   * Executes mint and sell sweep_amount of tokens only if the target price is lower than the current SWEEP price.
   * @param sweep_amount Amount to be minted and sold.
   */
  function mintAndSellProfitably(uint sweep_amount) external onlyBanker {
    if(sweep.target_price() > sweep.amm_price()) { revert TargetPriceTooHigh(); }
    mint(sweep_amount);
    sell(sweep_amount);
  }

  // INTERNAL HELPERS ==========================================================

  /**
   * @notice SWEEP in USDX
   * Calculate the amount of USDX that are equivalent to the SWEEP input.
   * @param amount Amount of SWEEP.
   * @param price Price of Sweep in USDX. This value is obtained from the AMM.
   * @return amount of USDX.
   */
  function SWEEPinUSDX(uint amount, uint price) internal view returns(uint) {
    return amount * price * (10 ** usdx.decimals()) / (10 ** sweep.decimals() * sweep.PRICE_PRECISION());
  }

  function _invest(address token, uint amount) internal {
    if(amount == 0) { revert InputIsZero(); }
    if(ERC20(token).balanceOf(address(this)) < amount) { revert NotEnoughBalance(); }

    TransferHelper.safeApprove(address(token), address(asset), amount);
    asset.deposit(token, amount);

    emit Invested(token, amount);
  }

  function _withdraw(address token, uint amount) internal {
    if(amount == 0) { revert InputIsZero(); }
    if(ERC20(token).balanceOf(address(this)) < amount) { revert NotEnoughBalance(); }

    if(sweep_borrowed > 0) {
      uint sweep_price = sweep.amm_price();
      if(token == address(sweep)){
        amount = SWEEPinUSDX(amount, sweep_price);
      }
      uint current_equity_ratio = calculateEquityRatio(0, amount, sweep_price);
      if(current_equity_ratio < minimum_equity_ratio) { revert MinimumEquityRatioExcess(); }
    }

    TransferHelper.safeTransfer(token, msg.sender, amount);

    emit Withdrawn(token, amount);
  }

  function _payback(address token, uint amount) internal {
    if(amount == 0) { revert InputIsZero(); }

    asset.withdraw(token, amount);
    emit Paidback(token, amount);
  }

  // GETTERS ===================================================================

  /**
   * @notice Calculate Equity Ratio
   * Calculated the equity ratio based on the internal storage.
   * @param sweep_delta Variation of SWEEP to recalculate the new equity ratio.
   * @param usdx_delta Variation of USDX to recalculate the new equity ratio.
   * @return the new equity ratio used to control the Mint and Withdraw functions.
   * @dev Current Equity Ratio percentage has a precision of 6 decimals.
   */
  function calculateEquityRatio(uint sweep_delta, uint usdx_delta, uint sweep_price) internal view returns(uint) {
    uint sweep_balance = sweep.balanceOf(address(this));
    uint usdx_balance = usdx.balanceOf(address(this));
    uint sweep_balance_in_usdx = SWEEPinUSDX(sweep_balance + sweep_delta, sweep_price);
    uint senior_tranche_in_usdx = SWEEPinUSDX(sweep_borrowed + sweep_delta, sweep_price);
    uint total_value = asset.currentValue() + usdx_balance + sweep_balance_in_usdx - usdx_delta;
    if(total_value == 0 || total_value <= senior_tranche_in_usdx) { return 0; }

    // 1e6 is decimals of the percentage result
    uint current_equity_ratio = (total_value - senior_tranche_in_usdx) * 100e6 / total_value;
    return current_equity_ratio;
  }

  /**
   * @notice Get Equity Ratio
   * @return the current equity ratio based in the internal storage.
   * @dev this value have a precision of 6 decimals.
   */
  function getEquityRatio() public view returns(uint) {
    return calculateEquityRatio(0, 0, sweep.amm_price());
  }

  /**
   * @notice Defaulted
   * @return bool that tells if stabilizer is in default.
   */
  function defaulted() public view returns(bool) {
    return getEquityRatio() < minimum_equity_ratio;
  }

  /**
   * @notice Get Junior Tranche Value
   * @return int calculated junior tranche amount.
   */
  function getJuniorTrancheValue() external view returns(int) {
    uint sweep_price = sweep.amm_price();
    uint sweep_balance = sweep.balanceOf(address(this));
    uint usdx_balance = usdx.balanceOf(address(this));
    uint sweep_balance_in_usdx = SWEEPinUSDX(sweep_balance, sweep_price);
    uint senior_tranche_in_usdx = SWEEPinUSDX(sweep_borrowed, sweep_price);
    uint total_value = asset.currentValue() + usdx_balance + sweep_balance_in_usdx;
    return int(total_value) - int(senior_tranche_in_usdx);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IAMM {
    function dollarBalances() external view returns (uint256 sweep_val_e18, uint256 collat_val_e18);
    function swapExactInput(address _tokenA, address _tokenB, uint24 _fee_tier, uint256 _amountIn, uint256 amountOutMinimum) external returns (uint256);
    function swapExactOutput(address _tokenA, address _tokenB, uint24 _fee_tier, uint256 amountOut, uint256 amountInMaximum) external returns(uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface ISweep {
  struct Minter {
      bool is_listed;
      uint256 max_mint_amount;
      uint256 minted_amount;
  }

  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function PRICE_PRECISION() external view returns (uint256);
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function sweep_eth_oracle_address() external view returns (address);
  function sweep_info() external view returns (uint256, uint256, uint256, uint256, uint256);
  function isValidMinter(address) external view returns(bool);
  function amm_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function mintPrice() external view returns (uint256);
  function redeemPrice() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function minter_burn_from(uint256 b_amount ) external;
  function minter_mint(address m_address, uint256 m_amount ) external;
  function minters(address m_address) external returns(Minter memory);
  function price_band() external view returns (uint256);
  function target_price() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function renounceRole(bytes32 role, address account ) external;
  function refreshTargetPrice(uint _amm_price) external;
  function revokeRole(bytes32 role, address account ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setUniswapOracle(address _uniswap_oracle_address ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setMintPrice(uint256 _new_mint_price ) external;
  function setRedeemPrice(uint256 _new_redeem_price ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleMint() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;
pragma experimental ABIEncoderV2;

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

interface IAsset {
  function currentValue() external view returns (uint);

  function deposit(address token, uint amount) external;
  function withdraw(address token, uint amount) external;

  function updateValue(uint value) external;
  function withdrawRewards(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Context.sol";
import "./IERC20.sol";
import "../../Utils/Math/SafeMath.sol";
import "../../Utils/Address.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * Requirements
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

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
pragma solidity >=0.6.11;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Context.sol";
import "../../Utils/Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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