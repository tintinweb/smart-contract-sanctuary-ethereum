// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./library/Initializable.sol";
import "./LSR/LSRModelBase.sol";

/**
 * @title dForce's Liquid Stability Reserve
 * @author dForce
 */
contract LSR is Initializable, LSRModelBase {
    /**
     * @notice Only for the implementation contract, as for the proxy pattern,
     *            should call `initialize()` separately.
     * @param _msdController MsdController address.
     * @param _msd Msd address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy Strategy address.
     */
    constructor(
        IMSDController _msdController,
        address _msd,
        address _mpr,
        address _strategy
    ) public {
        initialize(_msdController, _msd, _mpr, _strategy);
    }

    /**
     * @notice Initialize peg stability data.
     * @param _msdController MsdController address.
     * @param _msd MSD address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy Strategy address..
     */
    function initialize(
        IMSDController _msdController,
        address _msd,
        address _mpr,
        address _strategy
    ) public initializer {
        __Ownable_init();

        LSRMinter._initialize(_msdController, _msd);
        LSRModelBase._initialize(_msd, _mpr, _strategy);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./LSRMinter.sol";
import "./LSRCalculator.sol";

import "../interface/IStrategy.sol";

/**
 * @title dForce's Liquid Stability Reserve Base Model
 * @author dForce
 */
abstract contract LSRModelBase is Pausable, LSRMinter, LSRCalculator {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @dev Address of LSR's active strategy.
    address internal strategy_;

    /// @dev Emitted when `strategy_` is changed.
    event ChangeStrategy(address oldStrategy, address strategy);

    /// @dev Emitted when buy msd.
    event BuyMsd(
        address caller,
        address recipient,
        uint256 msdAmount,
        uint256 mprAmount
    );

    /// @dev Emitted when sell msd.
    event SellMsd(
        address caller,
        address recipient,
        uint256 msdAmount,
        uint256 mprAmount
    );

    /**
     * @notice Initialize the MSD,MPR,strategy related data.
     * @param _msd MSD address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy strategy address.
     */
    function _initialize(
        address _msd,
        address _mpr,
        address _strategy
    ) internal virtual {
        LSRCalculator._initialize(_msd, _mpr);
        _setStrategy(_strategy);
    }

    /**
     * @dev Unpause when LSR is paused.
     */
    function _open() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Pause LSR.
     */
    function _close() external onlyOwner {
        _pause();
    }

    /**
     * @dev Change strategy and move totalDeposits into new strategy.
     * @param _strategy strategy address.
     */
    function _switchStrategy(address _strategy) public virtual onlyOwner {
        require(_strategy != strategy_, "_switchStrategy: _strategy is active");

        strategy_.functionDelegateCall(
            abi.encodeWithSignature("withdrawAll()")
        );

        strategy_.functionDelegateCall(
            abi.encodeWithSignature("approveStrategy(bool)", false)
        );

        _setStrategy(_strategy);
    }

    /**
     * @dev Withdraw reserves to recipient address.
     * @param _recipient Recipient address.
     * @return _reservesAmount Amount of reserves.
     */
    function _withdrawReserves(address _recipient)
        external
        virtual
        onlyOwner
        returns (uint256 _reservesAmount)
    {
        uint256 _mprTotal = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_mprTotal == 0) {
            strategy_.functionDelegateCall(
                abi.encodeWithSignature("withdrawAll()")
            );
            _reservesAmount = IERC20(mpr_).balanceOf(address(this));
        } else {
            uint256 _totalDeposits = totalDeposits();

            if (_totalDeposits > _mprTotal) {
                _reservesAmount = _totalDeposits - _mprTotal;
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature(
                        "withdraw(uint256)",
                        _reservesAmount
                    )
                );
            }
        }

        if (_reservesAmount > 0)
            IERC20(mpr_).safeTransfer(_recipient, _reservesAmount);
    }

    /**
     * @dev Claim rewards and transfer to the treasury.
     * @param _treasury Treasury address.
     */
    function _claimRewards(address _treasury) external virtual onlyOwner {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature("_claimRewards(address)", _treasury)
        );
    }

    /**
     * @dev Set strategy and add to `strategies_`.
     * @param _strategy strategy address.
     */
    function _setStrategy(address _strategy) internal {
        require(
            IStrategy(_strategy).isLSRStrategy(),
            "_setStrategy: _strategy is not LSRStrategy contract"
        );
        require(
            IStrategy(_strategy).mpr() == mpr_,
            "_setStrategy: strategy's mpr does not match LSR"
        );

        _strategy.functionDelegateCall(
            abi.encodeWithSignature("approveStrategy(bool)", true)
        );

        uint256 _reserves = IERC20(mpr_).balanceOf(address(this));
        if (_reserves > 0)
            _strategy.functionDelegateCall(
                abi.encodeWithSignature("deposit(uint256)", _reserves)
            );

        address _oldStrategy = strategy_;
        strategy_ = _strategy;
        emit ChangeStrategy(_oldStrategy, strategy_);
    }

    /**
     * @dev The caller's MPR are deposited into liquidity model.
     * @param _caller Caller's address.
     * @param _amount Deposit amount.
     */
    function _deposit(address _caller, uint256 _amount) internal virtual {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature(
                "depositFor(address,uint256)",
                _caller,
                _amount
            )
        );
    }

    /**
     * @dev Withdraw from liquidity model and transfer to recipient.
     * @param _recipient Recipient address.
     * @param _amount Withdraw amount.
     */
    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        strategy_.functionDelegateCall(
            abi.encodeWithSignature(
                "withdrawTo(address,uint256)",
                _recipient,
                _amount
            )
        );
    }

    /**
     * @dev Caller buy MSD with MPR.
     * @param _caller Caller's address.
     * @param _recipient Recipient's address.
     * @param _mprAmount MPR amount.
     */
    function _buyMsd(
        address _caller,
        address _recipient,
        uint256 _mprAmount
    ) internal virtual whenNotPaused {
        _deposit(_caller, _mprAmount);
        uint256 _msdAmount = _amountToBuy(_mprAmount);
        _mint(_recipient, _msdAmount);
        emit BuyMsd(_caller, _recipient, _msdAmount, _mprAmount);
    }

    /**
     * @dev Caller sells MSD, receives MPR.
     * @param _caller Caller's address.
     * @param _recipient Recipient's address.
     * @param _msdAmount Msd amount.
     */
    function _sellMsd(
        address _caller,
        address _recipient,
        uint256 _msdAmount
    ) internal virtual whenNotPaused {
        _burn(_caller, _msdAmount);
        uint256 _mprAmount = _amountToSell(_msdAmount);
        _withdraw(_recipient, _mprAmount);
        emit SellMsd(_caller, _recipient, _msdAmount, _mprAmount);
    }

    /**
     * @dev Buy MSD with MPR.
     * @param _mprAmount MPR amount.
     */
    function buyMsd(uint256 _mprAmount) external {
        _buyMsd(msg.sender, msg.sender, _mprAmount);
    }

    /**
     * @dev Buy MSD with MPR.
     * @param _recipient Recipient's address.
     * @param _mprAmount MPR amount.
     */
    function buyMsd(address _recipient, uint256 _mprAmount) external {
        _buyMsd(msg.sender, _recipient, _mprAmount);
    }

    /**
     * @dev Sells MSD, receives MPR.
     * @param _msdAmount MSD amount.
     */
    function sellMsd(uint256 _msdAmount) external {
        _sellMsd(msg.sender, msg.sender, _msdAmount);
    }

    /**
     * @dev Sells MSD, receives MPR.
     * @param _recipient Recipient's address.
     * @param _msdAmount MSD amount.
     */
    function sellMsd(address _recipient, uint256 _msdAmount) external {
        _sellMsd(msg.sender, _recipient, _msdAmount);
    }

    /**
     * @dev Active strategy address.
     */
    function strategy() external view returns (address) {
        return strategy_;
    }

    /**
     * @dev  LSD estimated reserves.
     */
    function estimateReserves() external virtual returns (uint256 _reserve) {
        uint256 _totalDeposits = totalDeposits();

        uint256 _mprAmount = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_totalDeposits > _mprAmount)
            _reserve = _totalDeposits.sub(_mprAmount);
    }

    /**
     * @dev Deposit amount of LSR in strategy.
     */
    function totalDeposits() public virtual returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("totalDeposits()")
                ),
                (uint256)
            );
    }

    /**
     * @dev Strategy current liquidity.
     */
    function liquidity() public virtual returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("liquidity()")
                ),
                (uint256)
            );
    }

    /**
     * @dev Quotas for MSD peg reserve
     */
    function mprQuota() external view virtual returns (uint256) {
        return _calculator(totalMint_, msdDecimalScaler_, mprDecimalScaler_);
    }

    /**
     * @dev Available quota for MPR in LSR.
     */
    function mprOutstanding() external virtual returns (uint256 _outstandings) {
        _outstandings = totalDeposits();

        uint256 _cash = liquidity();
        if (_outstandings > _cash) _outstandings = _cash;

        uint256 _mprTotal = _calculator(
            totalMint_,
            msdDecimalScaler_,
            mprDecimalScaler_
        );

        if (_outstandings > _mprTotal) _outstandings = _mprTotal;
    }

    /**
     * @dev  Amount of reward earned in the strategy.
     */
    function rewardsEarned() external returns (uint256) {
        return
            abi.decode(
                strategy_.functionDelegateCall(
                    abi.encodeWithSignature("rewardsEarned()")
                ),
                (uint256)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            !_initialized,
            "Initializable: contract is already initialized"
        );

        _;

        _initialized = true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    function _claimRewards(address _treasury) external;

    function approveStrategy(bool _approved) external;

    function deposit(uint256 _amount) external;

    function depositFor(address _caller, uint256 _amount) external;

    function withdrawAll() external;

    function withdraw(uint256 _amount) external;

    function withdrawTo(address _recipient, uint256 _amount) external;

    function name() external view returns (string memory);

    function isLSRStrategy() external view returns (bool);

    function mpr() external view returns (address);

    function liquidityModel() external view returns (address);

    function totalDeposits() external returns (uint256);

    function liquidity() external returns (uint256);

    function rewardsEarned() external returns (uint256);

    function limitOfDeposit() external returns (uint256);

    function depositStatus() external returns (bool);

    function withdrawStatus() external returns (bool);

    // function getMiningReward() external;

    // function getProfitAmount() external returns (uint256);

    // function mprQuota() external view returns (uint256);

    // function mprOutstanding() external returns (uint256 _availableQuota);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/SafeRatioMath.sol";
import "../library/Ownable.sol";
import "../interface/IToken.sol";

/**
 * @title dForce's Liquid Stability Reserve Calculation Logic
 * @author dForce
 */
abstract contract LSRCalculator is Ownable {
    using SafeMath for uint256;
    using SafeRatioMath for uint256;

    /// @dev Address of liquid stability MSD peg reserve.
    address internal mpr_;

    /// @dev Amount of a MSD.
    uint256 internal msdDecimalScaler_;

    /// @dev Amount of a MPR.
    uint256 internal mprDecimalScaler_;

    /// @dev Max tax.
    uint256 internal constant maxTax_ = 1e18;

    /// @dev MSD tax in.
    uint256 internal taxIn_;

    /// @dev MSD tax out.
    uint256 internal taxOut_;

    /// @dev Emitted when `taxIn_` is changed.
    event SetTaxIn(uint256 oldTaxIn, uint256 taxIn);

    /// @dev Emitted when `taxOut_` is changed.
    event SetTaxOut(uint256 oldTaxOut, uint256 taxOut);

    /**
     * @dev Check the validity of the tax.
     */
    modifier checkTax(uint256 _tax) {
        require(_tax <= maxTax_, "checkTax: _tax > maxTax");
        _;
    }

    /**
     * @notice Initialize the MSD and MPR related data.
     * @param _msd MSD address.
     * @param _mpr MPR address.
     */
    function _initialize(address _msd, address _mpr) internal virtual {
        require(
            IToken(_mpr).decimals() > 0,
            "LSRCalculator: _mpr is not ERC20 contract"
        );

        mpr_ = _mpr;

        msdDecimalScaler_ = 10**uint256(IToken(address(_msd)).decimals());
        mprDecimalScaler_ = 10**uint256(IToken(_mpr).decimals());
    }

    /**
     * @dev Set up tax in.
     * @param _tax Tax in.
     */
    function _setTaxIn(uint256 _tax) external onlyOwner checkTax(_tax) {
        uint256 _oldtaxIn = taxIn_;
        require(
            _tax != _oldtaxIn,
            "_setTaxIn: Old and new tax cannot be the same."
        );
        taxIn_ = _tax;
        emit SetTaxIn(_oldtaxIn, _tax);
    }

    /**
     * @dev Set up tax out.
     * @param _tax Tax out.
     */
    function _setTaxOut(uint256 _tax) external onlyOwner checkTax(_tax) {
        uint256 _oldTaxOut = taxOut_;
        require(
            _tax != _oldTaxOut,
            "_setTaxOut: Old and new tax cannot be the same."
        );
        taxOut_ = _tax;
        emit SetTaxOut(_oldTaxOut, _tax);
    }

    /**
     * @dev When the decimal of the token is different, convert to the same decimal.
     * @param _amount The amount converted.
     * @param _decimalScalerIn Amount of token units converted.
     * @param _decimalScalerOut Amount of target token units.
     * @return The amount of conversion.
     */
    function _calculator(
        uint256 _amount,
        uint256 _decimalScalerIn,
        uint256 _decimalScalerOut
    ) internal pure returns (uint256) {
        return _amount.mul(_decimalScalerOut).div(_decimalScalerIn);
    }

    /**
     * @dev Get the amount of MSD that can be bought.
     * @param _amountIn Amount of spent tokens.
     * @return Amount of MSD that can be bought.
     */
    function _amountToBuy(uint256 _amountIn) internal view returns (uint256) {
        uint256 _msdAmount = _calculator(
            _amountIn,
            mprDecimalScaler_,
            msdDecimalScaler_
        );

        _msdAmount = _msdAmount.sub(_msdAmount.rmul(taxIn_));
        return _msdAmount;
    }

    /**
     * @dev Get the amount of tokens that can be bought.
     * @param _amountIn Amount of spent MSD.
     * @return Amount of tokens that can be bought.
     */
    function _amountToSell(uint256 _amountIn) internal view returns (uint256) {
        uint256 _msdAmount = _amountIn.sub(_amountIn.rmul(taxOut_));
        return _calculator(_msdAmount, msdDecimalScaler_, mprDecimalScaler_);
    }

    /**
     * @dev Get the amount of MSD that can be bought.
     * @param _amountIn Amount of spent tokens.
     * @return Amount of MSD that can be bought.
     */
    function getAmountToBuy(uint256 _amountIn) external view returns (uint256) {
        return _amountToBuy(_amountIn);
    }

    /**
     * @dev Get the amount of tokens that can be bought.
     * @param _amountIn Amount of spent MSD.
     * @return Amount of tokens that can be bought.
     */
    function getAmountToSell(uint256 _amountIn)
        external
        view
        returns (uint256)
    {
        return _amountToSell(_amountIn);
    }

    /**
     * @dev Address of liquid stability MSD peg reserve.
     */
    function mpr() external view returns (address) {
        return mpr_;
    }

    /**
     * @dev Amount of a MSD.
     */
    function msdDecimalScaler() external view returns (uint256) {
        return msdDecimalScaler_;
    }

    /**
     * @dev Amount of a MPR.
     */
    function mprDecimalScaler() external view returns (uint256) {
        return mprDecimalScaler_;
    }

    /**
     * @dev Buy msd tax.
     */
    function taxIn() external view returns (uint256) {
        return taxIn_;
    }

    /**
     * @dev Sell msd tax.
     */
    function taxOut() external view returns (uint256) {
        return taxOut_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interface/IMSDController.sol";
import "../interface/IMSD.sol";

/**
 * @title dForce's Liquid Stability Reserve Minter
 * @author dForce
 */
abstract contract LSRMinter {
    using SafeMath for uint256;

    /// @dev Address of MSD.
    address internal msd_;

    /// @dev Address of msdController.
    IMSDController internal msdController_;

    /// @dev Minter's total mint storage
    uint256 internal totalMint_;

    /**
     * @notice Initialize the MSD controller and MSD.
     * @param _msdController MSD controller address.
     * @param _msd MSD address.
     */
    function _initialize(IMSDController _msdController, address _msd)
        internal
        virtual
    {
        require(_msd != address(0), "LSRMinter: _msd cannot be zero address");
        require(
            _msdController.isMSDController(),
            "LSRMinter: _msdController is not MSD controller contract"
        );

        msd_ = _msd;
        msdController_ = _msdController;
    }

    /**
     * @dev Mint MSD to recipient.
     * @param _recipient Recipient address.
     * @param _amount Amount of minted MSD.
     */
    function _mint(address _recipient, uint256 _amount) internal virtual {
        totalMint_ = totalMint_.add(_amount);
        msdController_.mintMSD(msd_, _recipient, _amount);
    }

    /**
     * @dev Burn MSD.
     * @param _from Burned MSD holder address.
     * @param _amount Amount of MSD burned.
     */
    function _burn(address _from, uint256 _amount) internal virtual {
        totalMint_ = totalMint_.sub(_amount);
        IMSD(msd_).burn(_from, _amount);
    }

    /**
     * @dev  Msd quota provided by the minter.
     */
    function _msdQuota() internal view returns (uint256 _quota) {
        uint256 _mintCaps = msdController_.mintCaps(msd_, address(this));
        if (_mintCaps > totalMint_) _quota = _mintCaps - totalMint_;
    }

    /**
     * @dev MSD address.
     */
    function msd() external view returns (address) {
        return msd_;
    }

    /**
     * @dev MSD controller address.
     */
    function msdController() external view returns (IMSDController) {
        return msdController_;
    }

    /**
     * @dev  Minter's total mint.
     */
    function totalMint() external view returns (uint256) {
        return totalMint_;
    }

    /**
     * @dev  Minter's mint cap.
     */
    function mintCap() external view returns (uint256) {
        return msdController_.mintCaps(msd_, address(this));
    }

    /**
     * @dev  Msd quota provided by the minter.
     */
    function msdQuota() external view returns (uint256) {
        return _msdQuota();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface for MSD
 */
interface IMSD {
    function burn(address from, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface for MSDController
 */
interface IMSDController {
    function mintMSD(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function isMSDController() external view returns (bool);

    function mintCaps(address _token, address _minter)
        external
        view
        returns (uint256);

    function _addMSD(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeRatioMath {
    using SafeMath for uint256;

    uint256 private constant BASE = 10**18;
    uint256 private constant DOUBLE = 10**36;

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.add(y.sub(1)).div(y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).div(BASE);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).add(y.sub(1)).div(y);
    }

    function tmul(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 result) {
        result = x.mul(y).mul(z).div(DOUBLE);
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := base
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := base
                }
                default {
                    z := x
                }
                let half := div(base, 2) // for rounding.

                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, base)
                    }
                }
            }
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