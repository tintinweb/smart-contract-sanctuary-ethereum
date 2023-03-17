// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IAMM {
    function swapExactInput(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256);

    function buySweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function sellSweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== OffChainAsset.sol ========================
// ====================================================================

/**
 * @title Off Chain Asset
 * @author MAXOS Team - https://maxos.finance/
 * @dev Representation of an off-chain investment
 */
import "../Stabilizer/Stabilizer.sol";

contract OffChainAsset is Stabilizer {
    // Variables
    bool public redeem_mode;
    uint256 public redeem_amount;
    uint256 public redeem_time;
    uint256 public current_value;
    uint256 public valuation_time;
    address public wallet;

    // Events
    event Payback(address token, uint256 amount);

    // Errors
    error NotEnoughAmount();
    error OnlyCollateralAgent();

    /* ========== Modifies ========== */

    modifier onlyCollateralAgent() {
        if (msg.sender != sweep.collateral_agency())
            revert OnlyCollateralAgent();
        _;
    }

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _wallet,
        address _amm_address,
        address _borrower
    ) Stabilizer(_sweep_address, _usdx_address, _amm_address, _borrower) {
        wallet = _wallet;
        redeem_mode = false;
    }

    /* ========== Views ========== */

    /**
     * @notice Get Current Value
     * @return uint256.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Asset Value of investment.
     */
    function assetValue() public view returns (uint256) {
        return current_value;
    }

    /* ========== Actions ========== */

    /**
     * @notice Update wallet to send the investment to.
     * @param _wallet New wallet address.
     */
    function setWallet(address _wallet)
        external
        onlyBorrower
        onlySettingsEnabled
    {
        wallet = _wallet;
    }

    /**
     * @notice Invest USDX
     * @param _usdx_amount USDX Amount to be invested.
     */
    function invest(uint256 _usdx_amount, uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
        validAmount(_sweep_amount)
    {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        TransferHelper.safeTransfer(address(usdx), wallet, _usdx_amount);

        TransferHelper.safeTransfer(address(sweep), wallet, _sweep_amount);

        uint256 sweep_in_usdx = sweep.convertToUSDX(_sweep_amount);
        current_value += _usdx_amount;
        current_value += sweep_in_usdx;
        valuation_time = block.timestamp;

        _logAction();
        emit Invested(_usdx_amount, _sweep_amount);
    }

    /**
     * @notice Divest
     * @param _usdx_amount Amount to be divested.
     */
    function divest(uint256 _usdx_amount)
        public
        override
        onlyBorrowerOrBalancer
        validAmount(_usdx_amount)
    {
        redeem_amount = _usdx_amount;
        redeem_mode = true;
        redeem_time = block.timestamp;

        _logAction();
        emit Divested(_usdx_amount, 0);
    }

    /**
     * @notice Payback stable coins to Asset
     * @param _token token address to payback. USDX, SWEEP ...
     * @param _amount The amount of usdx to payback.
     */
    function payback(address _token, uint256 _amount) external {
        if (_token != address(sweep) && _token != address(usdx))
            revert InvalidToken();
        if (_token == address(sweep)) _amount = sweep.convertToUSDX(_amount);
        if (redeem_amount > _amount) revert NotEnoughAmount();

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            _amount
        );

        current_value -= _amount;
        redeem_mode = false;
        redeem_amount = 0;

        emit Payback(_token, _amount);
    }

    /**
     * @notice Update Value of investment.
     * @param _value New value of investment.
     * @dev tracks the time when current_value was updated.
     */
    function updateValue(uint256 _value) external onlyCollateralAgent {
        current_value = _value;
        valuation_time = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

import "./IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

import "../Sweep/ISweep.sol";
import "../AMM/IAMM.sol";
import "../Common/ERC20/IERC20Metadata.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";

/**
 * @title Stabilizer
 * @author MAXOS Team - https://maxos.finance/
 * @dev Implementation:
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 * Requires that the EquityRatio > MinimumEquityRatio when:
 * minting => increase of the senior tranche
 * withdrawing => decrease of the junior tranche
 */
contract Stabilizer {
    // Variables
    address public borrower;
    int256 public min_equity_ratio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweep_borrowed;
    uint256 public loan_limit;

    uint256 public call_time;
    uint256 public call_delay;
    uint256 public call_amount;

    uint256 public spread_fee; // 10000 is 1%
    uint256 public spread_date;
    uint256 public liquidator_discount; // 10000 is 1%
    string public link;

    bool public settings_enabled;
    bool public frozen;

    IAMM public amm;

    // Tokens
    ISweep public sweep;
    IERC20Metadata public usdx;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant TIME_ONE_YEAR = 365 * DAY_SECONDS; // seconds of Year
    uint256 private constant PRECISION = 1e6;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweep_amount);
    event Repaid(uint256 indexed sweep_amount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event PayFee(uint256 indexed sweep_amount);
    event Bought(uint256 indexed sweep_amount);
    event Sold(uint256 indexed sweep_amount);
    event BoughtSWEEP(uint256 indexed sweep_amount);
    event SoldSWEEP(uint256 indexed usdx_amount);
    event FrozenChanged(bool indexed frozen);
    event BorrowerChanged(address indexed borrower);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);

    event Invested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Divested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Liquidated(address indexed user);

    event MarginCalled(uint256 indexed call_amount);

    event ConfigurationChanged(
        int256 indexed min_equity_ratio,
        uint256 indexed spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        string url_link
    );
    event StatusChanged(
        uint256 indexed current_value,
        int256 indexed equity_ratio,
        int256 indexed min_equity_ratio,
        uint256 call_time,
        uint256 call_delay,
        uint256 call_amount,
        bool is_defaulted
    );

    /* ========== Errors ========== */

    error StabilizerFrozen();
    error OnlyBorrower();
    error OnlyBalancer();
    error OnlyBorrowerOrBalancer();
    error OnlyAdmin();
    error SettingsDisabled();
    error ZeroAddressDetected();
    error OverZero();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error SpreadNotEnough();
    error NotDefaulted();

    /* ========== Modifies ========== */

    modifier notFrozen() {
        if (frozen) revert StabilizerFrozen();
        _;
    }

    modifier onlyBorrower() {
        if (msg.sender != borrower) revert OnlyBorrower();
        _;
    }

    modifier onlyBalancer() {
        if (msg.sender != sweep.balancer()) revert OnlyBalancer();
        _;
    }

    modifier onlyBorrowerOrBalancer() {
        if (msg.sender != borrower && msg.sender != sweep.balancer())
            revert OnlyBorrowerOrBalancer();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != sweep.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlySettingsEnabled() {
        if (!settings_enabled) revert SettingsDisabled();
        _;
    }

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert ZeroAddressDetected();
        _;
    }

    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert OverZero();
        _;
    }

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _amm_address,
        address _borrower
    ) {
        sweep = ISweep(_sweep_address);
        usdx = IERC20Metadata(_usdx_address);
        amm = IAMM(_amm_address);
        borrower = _borrower;
        settings_enabled = true;
        frozen = false;
    }

    /* ========== Views ========== */

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (call_amount > 0 && block.timestamp > call_time) ||
            (getEquityRatio() < min_equity_ratio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        return calculateEquityRatio(0, 0);
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweep_borrowed == 0) return 0;
        else {
            uint256 period = block.timestamp - spread_date;
            return
                (((sweep_borrowed * spread_fee) / PRECISION) * period) /
                TIME_ONE_YEAR;
        }
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() public view returns (uint256) {
        return sweep_borrowed + accruedFee();
    }

    /**
     * @notice Get Current Value
     * @return uint256.
     */
    function currentValue() public view virtual returns (uint256) {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 sweep_balance_in_usdx = sweep.convertToUSDX(sweep_balance);

        return usdx_balance + sweep_balance_in_usdx;
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 senior_tranche_in_usdx = sweep.convertToUSDX(sweep_borrowed);
        uint256 total_value = currentValue();

        return int256(total_value) - int256(senior_tranche_in_usdx);
    }

    /**
     * @notice Returns the SWEEP required to liquidate the stabilizer
     * @return uint256
     */
    function getLiquidationValue() public view returns (uint256) {
        return
            sweep.convertToSWEEP(
                (currentValue() * (1e6 - liquidator_discount)) / PRECISION
            );
    }

    /* ========== Settings ========== */

    /**
     * @notice Set Borrower - who manages the investment actions.
     * @param _borrower.
     */
    function setBorrower(address _borrower)
        external
        onlyAdmin
        validAddress(_borrower)
    {
        borrower = _borrower;
        settings_enabled = true;

        emit BorrowerChanged(_borrower);
    }

    /**
     * @notice Frozen - stops investment actions.
     * @param _frozen.
     */
    function setFrozen(bool _frozen) external onlyAdmin {
        frozen = _frozen;

        emit FrozenChanged(_frozen);
    }

    /**
     * @notice Configure intial settings
     * @param _min_equity_ratio The minimum equity ratio can be negative.
     * @param _spread_fee.
     * @param _loan_limit.
     * @param _link Url link.
     */
    function configure(
        int256 _min_equity_ratio,
        uint256 _spread_fee,
        uint256 _loan_limit,
        uint256 _liquidator_discount,
        uint256 _call_delay,
        string calldata _link
    ) external onlyBorrower onlySettingsEnabled {
        min_equity_ratio = _min_equity_ratio;
        spread_fee = _spread_fee;
        loan_limit = _loan_limit;
        liquidator_discount = _liquidator_discount;
        call_delay = _call_delay;
        link = _link;

        emit ConfigurationChanged(
            _min_equity_ratio,
            _spread_fee,
            _loan_limit,
            _liquidator_discount,
            _call_delay,
            _link
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settings_enabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyAdmin {
        settings_enabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param _sweep_amount.
     * @dev Increases the sweep_borrowed (senior tranche).
     */
    function borrow(uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
    {
        if (!sweep.isValidMinter(address(this))) revert InvalidMinter();
        uint256 p_amm_price = sweep.amm_price();
        uint256 q_amm_price = sweep.amm_price();
        uint256 r_amm_price = sweep.amm_price();

        int256 current_equity_ratio = calculateEquityRatio(_sweep_amount, 0);
        if (current_equity_ratio < min_equity_ratio)
            revert EquityRatioExcessed();

        _payFee();
        sweep.minter_mint(address(this), _sweep_amount);
        sweep_borrowed += _sweep_amount;

        _logAction();
        emit Borrowed(_sweep_amount);
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep_amount to reduce the debt (senior tranche).
     * @param _sweep_amount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 _sweep_amount) external onlyBorrower {
        _repay(_sweep_amount);
    }

    /**
     * @notice Divests From Asset.
     * Sends balance from the asset to the STABILIZER.
     * @param _amount Amount to be divested.
     */
    function divest(uint256 _amount) public virtual onlyBorrower {}

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower {
        _payFee();
    }

    /**
     * @notice Margin Call.
     * @param _usdx_call_amount to swap for Sweep.
     */
    function marginCall(uint256 _usdx_call_amount)
        external
        onlyBalancer
        validAmount(_usdx_call_amount)
    {
        uint256 missing_usdx;

        uint256 sweep_to_buy = sweep.convertToSWEEP(_usdx_call_amount);
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();

        call_time = block.timestamp + call_delay;
        call_amount = _min(sweep_to_buy, sweep_borrowed);

        if (sweep_balance < call_amount) {
            uint256 missing_sweep = call_amount - sweep_balance;
            missing_usdx = sweep.convertToUSDX(missing_sweep);
            if (missing_usdx > usdx_balance)
                divest(missing_usdx - usdx_balance);
        }

        if (missing_usdx > 0) _buy(missing_usdx, 0);
        if (call_amount > 0) _repay(call_amount);

        _logAction();
        emit MarginCalled(_usdx_call_amount);
    }

    /**
     * @notice Buy
     * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param _usdx_amount Amount to be changed in the AMM.
     * @param _amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buy(uint256 _usdx_amount, uint256 _amountOutMin)
        external
        onlyBorrower
        notFrozen
        returns (uint256 sweep_amount)
    {
        sweep_amount = _buy(_usdx_amount, _amountOutMin);

        _logAction();
        emit Bought(sweep_amount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sell(uint256 _sweep_amount, uint256 _amountOutMin)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
        returns (uint256 usdx_amount)
    {
        (, uint256 sweep_balance) = _balances();
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        TransferHelper.safeApprove(address(sweep), address(amm), _sweep_amount);
        usdx_amount = amm.sellSweep(
            address(usdx),
            _sweep_amount,
            _amountOutMin
        );

        _logAction();
        emit Sold(_sweep_amount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep_amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param _usdx_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function buySWEEP(uint256 _usdx_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
    {
        uint256 sweep_amount = (_usdx_amount * 10**sweep.decimals()) /
            sweep.target_price();
        (, uint256 sweep_balance) = _balances();
        if (sweep_amount > sweep_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            _usdx_amount
        );
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweep_amount);

        _logAction();
        emit BoughtSWEEP(sweep_amount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep_amount to the stabilizer (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSWEEP(uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
    {
        uint256 usdx_amount = sweep.convertToUSDX(_sweep_amount);
        (uint256 usdx_balance, ) = _balances();
        if (usdx_amount > usdx_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            _sweep_amount
        );
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_amount);

        _logAction();
        emit SoldSWEEP(usdx_amount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param _token.
     * @param _amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(address _token, uint256 _amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_amount)
    {
        if (_token != address(sweep) && _token != address(usdx))
            revert InvalidToken();

        if (_amount > IERC20Metadata(_token).balanceOf(address(this)))
            revert NotEnoughBalance();

        if (sweep_borrowed != 0) {
            uint256 usdx_amount = _amount;
            if (_token == address(sweep))
                usdx_amount = sweep.convertToUSDX(_amount);
            int256 current_equity_ratio = calculateEquityRatio(0, usdx_amount);
            if (current_equity_ratio < min_equity_ratio)
                revert EquityRatioExcessed();
        }

        TransferHelper.safeTransfer(_token, msg.sender, _amount);

        _logAction();
        emit Withdrawn(_token, _amount);
    }

    /**
     * @notice Liquidates
     * a liquidator repays the debt in sweep and gets the same value
     * of the assets that the stabilizer holds at a discount
     */
    function _liquidate(address token) internal {
        if (!isDefaulted()) revert NotDefaulted();

        uint256 sweep_to_liquidate = getLiquidationValue();
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 token_balance = IERC20Metadata(token).balanceOf(address(this));
        // Gives all the assets to the liquidator first
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweep_balance);
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_balance);
        TransferHelper.safeTransfer(token, msg.sender, token_balance);

        // Takes SWEEP from the liquidator and repays as much debt as it can
        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            sweep_to_liquidate
        );

        _repay(_min(sweep_to_liquidate, getDebt()));

        _logAction();
        emit Liquidated(msg.sender);
    }

    function _buy(uint256 _usdx_amount, uint256 _amountOutMin)
        internal
        returns (uint256)
    {
        (uint256 usdx_balance, ) = _balances();
        _usdx_amount = _min(_usdx_amount, usdx_balance);

        if(_usdx_amount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        uint256 sweep_amount = amm.buySweep(
            address(usdx),
            _usdx_amount,
            _amountOutMin
        );

        return sweep_amount;
    }

    function _repay(uint256 _sweep_amount) internal {
        (, uint256 sweep_balance) = _balances();
        _sweep_amount = _min(_sweep_amount, sweep_balance);

        if(_sweep_amount == 0) revert NotEnoughBalance();

        uint256 spread_amount = accruedFee();
        uint256 sweep_amount = _sweep_amount - spread_amount;
        if (sweep_borrowed < sweep_amount) {
            sweep_amount = sweep_borrowed;
            sweep_borrowed = 0;
        } else {
            sweep_borrowed -= sweep_amount;
        }
        TransferHelper.safeTransfer(
            address(sweep),
            sweep.treasury(),
            spread_amount
        );

        call_amount = (call_amount > _sweep_amount) ? call_amount - _sweep_amount : 0;

        TransferHelper.safeApprove(address(sweep), address(this), sweep_amount);
        spread_date = block.timestamp;
        sweep.minter_burn_from(sweep_amount);

        emit Repaid(sweep_amount);
    }

    function _payFee() internal {
        uint256 spread_amount = accruedFee();
        (, uint256 sweep_balance) = _balances();
        if (spread_amount > sweep_balance) revert SpreadNotEnough();

        if (spread_amount != 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spread_amount
            );
        }
        spread_date = block.timestamp;

        emit PayFee(spread_amount);
    }

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param _sweep_delta Variation of SWEEP to recalculate the new equity ratio.
     * @param _usdx_delta Variation of USDX to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 4 decimals.
     */
    function calculateEquityRatio(uint256 _sweep_delta, uint256 _usdx_delta)
        internal
        view
        returns (int256)
    {
        uint256 current_value = currentValue();
        uint256 sweep_delta_in_usdx = sweep.convertToUSDX(_sweep_delta);
        uint256 senior_tranche_in_usdx = sweep.convertToUSDX(
            sweep_borrowed + _sweep_delta
        );
        uint256 total_value = current_value + sweep_delta_in_usdx - _usdx_delta;

        if (total_value == 0) return 0;

        // 1e6 is decimals of the percentage result
        int256 current_equity_ratio = ((int256(total_value) -
            int256(senior_tranche_in_usdx)) * 1e6) / int256(total_value);

        if (current_equity_ratio < -1e6) current_equity_ratio = -1e6;

        return current_equity_ratio;
    }

    /**
     * @notice Get Balances of the usdx and sweep.
     **/
    function _balances()
        internal
        view
        returns (uint256 usdx_balance, uint256 sweep_balance)
    {
        usdx_balance = usdx.balanceOf(address(this));
        sweep_balance = sweep.balanceOf(address(this));
    }

    /**
     * @notice Get minimum value between a and b.
     **/
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a < b) ? a : b;
    }

    /**
     * @notice Events Log.
     **/
    function _logAction() internal {
        emit StatusChanged(
            currentValue(),
            getEquityRatio(),
            min_equity_ratio,
            call_time,
            call_delay,
            call_amount,
            isDefaulted()
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 approved_loan_amount;
        uint256 minted_amount;
        uint256 max_sweep_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSDX(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../../../../Common/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}