// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getPrice(uint256 interval) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { OwnerPausable } from "./base/OwnerPausable.sol";
import { CollateralManagerStorageV1 } from "./storage/CollateralManagerStorage.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { IPriceFeed } from "@perp/perp-oracle-contract/contracts/interface/IPriceFeed.sol";
import { Collateral } from "./lib/Collateral.sol";
import { ICollateralManager } from "./interface/ICollateralManager.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { IVault } from "./interface/IVault.sol";

contract CollateralManager is ICollateralManager, OwnerPausable, CollateralManagerStorageV1 {
    using AddressUpgradeable for address;

    uint24 private constant _ONE_HUNDRED_PERCENT_RATIO = 1e6;

    //
    // MODIFIER
    //

    modifier checkRatio(uint24 ratio) {
        // CM_IR: invalid ratio, should be in [0, 1]
        require(ratio <= _ONE_HUNDRED_PERCENT_RATIO, "CM_IR");
        _;
    }

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(
        address clearingHouseConfigArg,
        address vaultArg,
        uint8 maxCollateralTokensPerAccountArg,
        uint24 debtNonSettlementTokenValueRatioArg,
        uint24 liquidationRatioArg,
        uint24 mmRatioBufferArg,
        uint24 clInsuranceFundFeeRatioArg,
        uint256 debtThresholdArg,
        uint256 collateralValueDustArg
    )
        external
        initializer
        checkRatio(debtNonSettlementTokenValueRatioArg)
        checkRatio(liquidationRatioArg)
        checkRatio(clInsuranceFundFeeRatioArg)
    {
        // CM_CHCNC: clearing house config is not contract
        require(clearingHouseConfigArg.isContract(), "CM_CHCNC");
        // CM_VNC: vault is not contract
        require(vaultArg.isContract(), "CM_VNC");

        __OwnerPausable_init();

        _clearingHouseConfig = clearingHouseConfigArg;
        _vault = vaultArg;
        _maxCollateralTokensPerAccount = maxCollateralTokensPerAccountArg;
        _debtNonSettlementTokenValueRatio = debtNonSettlementTokenValueRatioArg;
        _liquidationRatio = liquidationRatioArg;

        requireValidCollateralMmRatio(mmRatioBufferArg);
        _mmRatioBuffer = mmRatioBufferArg;

        _clInsuranceFundFeeRatio = clInsuranceFundFeeRatioArg;
        _debtThreshold = debtThresholdArg;
        _collateralValueDust = collateralValueDustArg;

        emit ClearingHouseConfigChanged(clearingHouseConfigArg);
        emit VaultChanged(vaultArg);
        emit MaxCollateralTokensPerAccountChanged(maxCollateralTokensPerAccountArg);
        emit MmRatioBufferChanged(mmRatioBufferArg);
        emit DebtNonSettlementTokenValueRatioChanged(debtNonSettlementTokenValueRatioArg);
        emit LiquidationRatioChanged(liquidationRatioArg);
        emit CLInsuranceFundFeeRatioChanged(clInsuranceFundFeeRatioArg);
        emit DebtThresholdChanged(debtThresholdArg);
        emit CollateralValueDustChanged(collateralValueDustArg);
    }

    function addCollateral(address token, Collateral.Config memory config)
        external
        checkRatio(config.collateralRatio)
        checkRatio(config.discountRatio)
        onlyOwner
    {
        // CM_CTE: collateral token already exists
        require(!isCollateral(token), "CM_CTE");
        // CM_CTNC: collateral token is not contract
        require(token.isContract(), "CM_CTNC");
        // CM_PFNC: price feed is not contract
        require(config.priceFeed.isContract(), "CM_PFNC");
        // CM_CIS: collateral token is settlement token
        require(IVault(_vault).getSettlementToken() != token, "CM_CIS");

        _collateralConfigMap[token] = config;
        emit CollateralAdded(token, config.priceFeed, config.collateralRatio, config.discountRatio, config.depositCap);
    }

    function setPriceFeed(address token, address priceFeed) external onlyOwner {
        _requireIsCollateral(token);
        // CM_PFNC: price feed is not contract
        require(priceFeed.isContract(), "CM_PFNC");

        _collateralConfigMap[token].priceFeed = priceFeed;
        emit PriceFeedChanged(token, priceFeed);
    }

    function setCollateralRatio(address token, uint24 collateralRatio) external checkRatio(collateralRatio) onlyOwner {
        _requireIsCollateral(token);

        _collateralConfigMap[token].collateralRatio = collateralRatio;
        emit CollateralRatioChanged(token, collateralRatio);
    }

    function setDiscountRatio(address token, uint24 discountRatio) external checkRatio(discountRatio) onlyOwner {
        _requireIsCollateral(token);

        _collateralConfigMap[token].discountRatio = discountRatio;
        emit DiscountRatioChanged(token, discountRatio);
    }

    function setDepositCap(address token, uint256 depositCap) external onlyOwner {
        _requireIsCollateral(token);
        _collateralConfigMap[token].depositCap = depositCap;
        emit DepositCapChanged(token, depositCap);
    }

    function setMaxCollateralTokensPerAccount(uint8 maxCollateralTokensPerAccount) external onlyOwner {
        _maxCollateralTokensPerAccount = maxCollateralTokensPerAccount;
        emit MaxCollateralTokensPerAccountChanged(maxCollateralTokensPerAccount);
    }

    function setMmRatioBuffer(uint24 mmRatioBuffer) external onlyOwner {
        requireValidCollateralMmRatio(mmRatioBuffer);

        _mmRatioBuffer = mmRatioBuffer;
        emit MmRatioBufferChanged(mmRatioBuffer);
    }

    function setDebtNonSettlementTokenValueRatio(uint24 debtNonSettlementTokenValueRatio)
        external
        checkRatio(debtNonSettlementTokenValueRatio)
        onlyOwner
    {
        _debtNonSettlementTokenValueRatio = debtNonSettlementTokenValueRatio;
        emit DebtNonSettlementTokenValueRatioChanged(debtNonSettlementTokenValueRatio);
    }

    function setLiquidationRatio(uint24 liquidationRatio) external checkRatio(liquidationRatio) onlyOwner {
        _liquidationRatio = liquidationRatio;
        emit LiquidationRatioChanged(liquidationRatio);
    }

    function setCLInsuranceFundFeeRatio(uint24 clInsuranceFundFeeRatio)
        external
        checkRatio(clInsuranceFundFeeRatio)
        onlyOwner
    {
        _clInsuranceFundFeeRatio = clInsuranceFundFeeRatio;
        emit CLInsuranceFundFeeRatioChanged(clInsuranceFundFeeRatio);
    }

    function setDebtThreshold(uint256 debtThreshold) external onlyOwner {
        // CM_ZDT: zero debt threshold
        require(debtThreshold != 0, "CM_ZDT");

        _debtThreshold = debtThreshold;
        emit DebtThresholdChanged(debtThreshold);
    }

    /// @dev Same decimals as the settlement token
    function setCollateralValueDust(uint256 collateralValueDust) external onlyOwner {
        _collateralValueDust = collateralValueDust;
        emit CollateralValueDustChanged(collateralValueDust);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc ICollateralManager
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc ICollateralManager
    function getVault() external view override returns (address) {
        return _vault;
    }

    /// @inheritdoc ICollateralManager
    function getCollateralConfig(address token) external view override returns (Collateral.Config memory) {
        return _collateralConfigMap[token];
    }

    /// @inheritdoc ICollateralManager
    function getPriceFeedDecimals(address token) external view override returns (uint8) {
        _requireIsCollateral(token);
        return IPriceFeed(_collateralConfigMap[token].priceFeed).decimals();
    }

    /// @inheritdoc ICollateralManager
    function getPrice(address token, uint256 interval) external view override returns (uint256) {
        _requireIsCollateral(token);
        return IPriceFeed(_collateralConfigMap[token].priceFeed).getPrice(interval);
    }

    function getMaxCollateralTokensPerAccount() external view override returns (uint8) {
        return _maxCollateralTokensPerAccount;
    }

    /// @inheritdoc ICollateralManager
    function getMmRatioBuffer() external view override returns (uint24) {
        return _mmRatioBuffer;
    }

    /// @inheritdoc ICollateralManager
    function getDebtNonSettlementTokenValueRatio() external view override returns (uint24) {
        return _debtNonSettlementTokenValueRatio;
    }

    /// @inheritdoc ICollateralManager
    function getLiquidationRatio() external view override returns (uint24) {
        return _liquidationRatio;
    }

    /// @inheritdoc ICollateralManager
    function getCLInsuranceFundFeeRatio() external view override returns (uint24) {
        return _clInsuranceFundFeeRatio;
    }

    /// @inheritdoc ICollateralManager
    function getDebtThreshold() external view override returns (uint256) {
        return _debtThreshold;
    }

    /// @inheritdoc ICollateralManager
    function getCollateralValueDust() external view override returns (uint256) {
        return _collateralValueDust;
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc ICollateralManager
    function isCollateral(address token) public view override returns (bool) {
        return _collateralConfigMap[token].priceFeed != address(0);
    }

    /// @inheritdoc ICollateralManager
    function requireValidCollateralMmRatio(uint24 mmRatioBuffer) public view override returns (uint24) {
        uint24 collateralMmRatio = IClearingHouseConfig(_clearingHouseConfig).getMmRatio() + mmRatioBuffer;
        // CM_ICMR : invalid collateralMmRatio
        require(collateralMmRatio <= _ONE_HUNDRED_PERCENT_RATIO, "CM_ICMR");

        return collateralMmRatio;
    }

    //
    // INTERNAL VIEW
    //

    function _requireIsCollateral(address token) internal view {
        // CM_TINAC: token is not a collateral
        require(isCollateral(token), "CM_TINAC");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { SafeOwnable } from "./SafeOwnable.sol";

abstract contract OwnerPausable is SafeOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;

    // solhint-disable-next-line func-order
    function __OwnerPausable_init() internal initializer {
        __SafeOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address payable) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _candidate = address(0);
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // newOwner is 0
        require(newOwner != address(0), "SO_NW0");
        // same as original
        require(newOwner != _owner, "SO_SAO");
        // same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // candidate is zero
        require(_candidate != address(0), "SO_C0");
        // caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IClearingHouseConfig {
    /// @return maxMarketsPerAccount Max value of total markets per account
    function getMaxMarketsPerAccount() external view returns (uint8 maxMarketsPerAccount);

    /// @return imRatio Initial margin ratio
    function getImRatio() external view returns (uint24 imRatio);

    /// @return mmRatio Maintenance margin requirement ratio
    function getMmRatio() external view returns (uint24 mmRatio);

    /// @return liquidationPenaltyRatio Liquidation penalty ratio
    function getLiquidationPenaltyRatio() external view returns (uint24 liquidationPenaltyRatio);

    /// @return partialCloseRatio Partial close ratio
    function getPartialCloseRatio() external view returns (uint24 partialCloseRatio);

    /// @return twapInterval TwapInterval for funding and prices (mark & index) calculations
    function getTwapInterval() external view returns (uint32 twapInterval);

    /// @return settlementTokenBalanceCap Max value of settlement token balance
    function getSettlementTokenBalanceCap() external view returns (uint256 settlementTokenBalanceCap);

    /// @return maxFundingRate Max value of funding rate
    function getMaxFundingRate() external view returns (uint24 maxFundingRate);

    /// @return isBackstopLiquidityProvider is backstop liquidity provider
    function isBackstopLiquidityProvider(address account) external view returns (bool isBackstopLiquidityProvider);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Collateral } from "../lib/Collateral.sol";

interface ICollateralManager {
    /// @notice Emitted when owner add collateral
    /// @param token address of token
    /// @param priceFeed address of price feed
    /// @param collateralRatio collateral ratio
    /// @param discountRatio discount ratio for the collateral liquidation
    /// @param depositCap max amount of collateral that can be deposited
    event CollateralAdded(
        address indexed token,
        address priceFeed,
        uint24 collateralRatio,
        uint24 discountRatio,
        uint256 depositCap
    );

    /// @notice Emitted when owner update the address of clearing house config
    /// @param clearingHouseConfig address of clearing house config
    event ClearingHouseConfigChanged(address indexed clearingHouseConfig);

    /// @notice Emitted when owner update the address of vault
    /// @param vault address of vault
    event VaultChanged(address indexed vault);

    /// @notice Emitted when owner update the price feed address of a collateral token
    /// @param token address of token
    /// @param priceFeed address of price feed
    event PriceFeedChanged(address indexed token, address priceFeed);

    /// @notice Emitted when owner update the collateral ratio of a collateral token
    /// @param token address of token
    /// @param collateralRatio collateral ratio
    event CollateralRatioChanged(address indexed token, uint24 collateralRatio);

    /// @notice Emitted when owner change the discount ratio
    /// @param token address of token
    /// @param discountRatio discount ratio for the collateral liquidation
    event DiscountRatioChanged(address indexed token, uint24 discountRatio);

    /// @notice Emitted when owner update the deposit cap of a collateral token
    /// @param token address of token
    /// @param depositCap max amount of the collateral that can be deposited
    event DepositCapChanged(address indexed token, uint256 depositCap);

    /// @notice Emitted when owner init or update the max collateral tokens that per account can have,
    /// 		this is can prevent high gas cost.
    /// @param maxCollateralTokensPerAccount max amount of collateral tokens that per account can have
    event MaxCollateralTokensPerAccountChanged(uint8 maxCollateralTokensPerAccount);

    /// @notice Emitted when owner init or update the maintenance margin ratio buffer,
    ///         the value provides a safe range between the mmRatio & the collateralMMRatio.
    /// @param mmRatioBuffer safe buffer number (bps)
    event MmRatioBufferChanged(uint24 mmRatioBuffer);

    /// @notice Emitted when owner init or update the debt non-settlement token value ratio,
    ///         maximum `debt / nonSettlementTokenValue` before the account's is liquidatable
    /// @param debtNonSettlementTokenValueRatio debt non-settlement token value ratio, ≤ 1
    event DebtNonSettlementTokenValueRatioChanged(uint24 debtNonSettlementTokenValueRatio);

    /// @notice Emitted when owner init or update the liquidation ratio,
    ///         the value presents the max repaid ratio of the collateral liquidation.
    /// @param liquidationRatio liquidation ratio, ≤ 1
    event LiquidationRatioChanged(uint24 liquidationRatio);

    /// @notice Emitted when owner init or update the clearing house insurance fund fee ratio,
    ///         charge fee for clearing house insurance fund.
    /// @param clInsuranceFundFeeRatio clearing house insurance fund fee ratio, ≤ 1
    event CLInsuranceFundFeeRatioChanged(uint24 clInsuranceFundFeeRatio);

    /// @notice Emitted when owner init or update the debt threshold,
    ///		 	maximum debt allowed before an account’s collateral is liquidatable.
    /// @param debtThreshold debt threshold
    event DebtThresholdChanged(uint256 debtThreshold);

    /// @notice Emitted when owner init or update the collateral value dust,
    ///			if a trader’s debt value falls below this dust threshold,
    /// 		the liquidator will ignore the liquidationRatio.
    /// @param collateralValueDust collateral value dust
    event CollateralValueDustChanged(uint256 collateralValueDust);

    /// @notice Get the address of vault
    /// @return vault address of vault
    function getVault() external view returns (address);

    /// @notice Get the address of clearing house config
    /// @return clearingHouseConfig address of clearing house config
    function getClearingHouseConfig() external view returns (address);

    /// @notice Get collateral config by token address
    /// @param token address of token
    /// @return collateral config
    function getCollateralConfig(address token) external view returns (Collateral.Config memory);

    /// @notice Get price feed decimals of the collateral token
    /// @param token address of token
    /// @return decimals of the price feed
    function getPriceFeedDecimals(address token) external view returns (uint8);

    /// @notice Get the price of the collateral token
    /// @param token address of token
    /// @return price of the certain period
    function getPrice(address token, uint256 interval) external view returns (uint256);

    /// @notice Get the max number of collateral tokens per account
    /// @return max number of collateral tokens per account
    function getMaxCollateralTokensPerAccount() external view returns (uint8);

    /// @notice Get the minimum `margin ratio - mmRatio` before the account's collateral is liquidatable
    /// @dev 6 decimals, same decimals as _mmRatio
    /// @return ratio
    function getMmRatioBuffer() external view returns (uint24);

    /// @notice Get the maximum `debt / nonSettlementTokenValue` before the account's collaterals are liquidated
    /// @dev 6 decimals
    /// @return ratio
    function getDebtNonSettlementTokenValueRatio() external view returns (uint24);

    /// @notice Get the maximum ratio of debt can be repaid in one transaction
    /// @dev 6 decimals. For example, `liquidationRatio` = 50% means
    ///      the liquidator can repay as much as half of the trader’s debt in one liquidation
    /// @return liquidation ratio
    function getLiquidationRatio() external view returns (uint24);

    /// @notice Get the insurance fund fee ratio when liquidating a trader's collateral
    /// @dev 6 decimals. For example, `clInsuranceFundFeeRatio` = 5% means
    ///      the liquidator will pay 5% of transferred settlement token to insurance fund
    /// @return insurance fund fee ratio
    function getCLInsuranceFundFeeRatio() external view returns (uint24);

    /// @notice Get the maximum debt (denominated in settlement token) allowed
    ///			before an account’s collateral is liquidatable.
    /// @dev 6 decimals
    /// @return Debt threshold
    function getDebtThreshold() external view returns (uint256);

    /// @notice Get the threshold of the minium repaid.
    ///  		If a trader’s collateral value (denominated in settlement token) falls below the threshold,
    ///         the liquidator can convert it with 100% `liquidationRatio` so there is no dust left
    /// @dev 6 decimals
    /// @return Dust collateral value
    function getCollateralValueDust() external view returns (uint256);

    /// @notice Check if the given token is one of collateral tokens
    /// @param token address of token
    /// @return true if the token is one of collateral tokens
    function isCollateral(address token) external view returns (bool);

    /// @notice Require and get the the valid collateral maintenance margin ratio by mmRatioBuffer
    /// @param mmRatioBuffer safe margin ratio buffer; 6 decimals, same decimals as _mmRatio
    /// @return collateralMmRatio the collateral maintenance margin ratio
    function requireValidCollateralMmRatio(uint24 mmRatioBuffer) external view returns (uint24);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IVault {
    /// @notice Emitted when trader deposit collateral into vault
    /// @param collateralToken The address of token deposited
    /// @param trader The address of trader
    /// @param amount The amount of token deposited
    event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when trader withdraw collateral from vault
    /// @param collateralToken The address of token withdrawn
    /// @param trader The address of trader
    /// @param amount The amount of token withdrawn
    event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when a trader's collateral is liquidated
    /// @param trader The address of trader
    /// @param collateralToken The address of the token that is liquidated
    /// @param liquidator The address of liquidator
    /// @param collateral The amount of collateral token liquidated
    /// @param repaidSettlementWithoutInsuranceFundFeeX10_S The amount of settlement token repaid
    ///        for trader (in settlement token's decimals)
    /// @param insuranceFundFeeX10_S The amount of insurance fund fee paid(in settlement token's decimals)
    /// @param discountRatio The discount ratio of liquidation price
    event CollateralLiquidated(
        address indexed trader,
        address indexed collateralToken,
        address indexed liquidator,
        uint256 collateral,
        uint256 repaidSettlementWithoutInsuranceFundFeeX10_S,
        uint256 insuranceFundFeeX10_S,
        uint24 discountRatio
    );

    /// @notice Emitted when trustedForwarder is changed
    /// @dev trustedForwarder is only used for metaTx
    /// @param trustedForwarder The address of trustedForwarder
    event TrustedForwarderChanged(address indexed trustedForwarder);

    /// @notice Emitted when clearingHouse is changed
    /// @param clearingHouse The address of clearingHouse
    event ClearingHouseChanged(address indexed clearingHouse);

    /// @notice Emitted when collateralManager is changed
    /// @param collateralManager The address of collateralManager
    event CollateralManagerChanged(address indexed collateralManager);

    /// @notice Emitted when WETH9 is changed
    /// @param WETH9 The address of WETH9
    event WETH9Changed(address indexed WETH9);

    /// @notice Deposit collateral into vault
    /// @param token The address of the token to deposit
    /// @param amount The amount of the token to deposit
    function deposit(address token, uint256 amount) external;

    /// @notice Deposit the collateral token for other account
    /// @param to The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param amount The amount of the token to deposit
    function depositFor(
        address to,
        address token,
        uint256 amount
    ) external;

    /// @notice Deposit ETH as collateral into vault
    function depositEther() external payable;

    /// @notice Deposit ETH as collateral for specified account
    /// @param to The address of the account to deposit to
    function depositEtherFor(address to) external payable;

    /// @notice Withdraw collateral from vault
    /// @param token The address of the token to withdraw
    /// @param amount The amount of the token to withdraw
    function withdraw(address token, uint256 amount) external;

    /// @notice Withdraw ETH from vault
    /// @param amount The amount of the ETH to withdraw
    function withdrawEther(uint256 amount) external;

    /// @notice Withdraw all free collateral from vault
    /// @param token The address of the token to withdraw
    /// @return amount The amount of the token withdrawn
    function withdrawAll(address token) external returns (uint256 amount);

    /// @notice Withdraw all free collateral of ETH from vault
    /// @return amount The amount of ETH withdrawn
    function withdrawAllEther() external returns (uint256 amount);

    /// @notice Liquidate trader's collateral by given settlement token amount or non settlement token amount
    /// @param trader The address of trader that will be liquidated
    /// @param token The address of non settlement collateral token that the trader will be liquidated
    /// @param amount The amount of settlement token that the liquidator will repay for trader or
    ///               the amount of non-settlement collateral token that the liquidator will charge from trader
    /// @param isDenominatedInSettlementToken Whether the amount is denominated in settlement token or not
    /// @return returnAmount The amount of a non-settlement token (in its native decimals) that is liquidated
    ///         when `isDenominatedInSettlementToken` is true or the amount of settlement token that is repaid
    ///         when `isDenominatedInSettlementToken` is false
    function liquidateCollateral(
        address trader,
        address token,
        uint256 amount,
        bool isDenominatedInSettlementToken
    ) external returns (uint256 returnAmount);

    /// @notice Get the specified trader's settlement token balance, without pending fee, funding payment
    ///         and owed realized PnL
    /// @dev The function is equivalent to `getBalanceByToken(trader, settlementToken)`
    ///      We keep this function solely for backward-compatibility with the older single-collateral system.
    ///      In practical applications, the developer might want to use `getSettlementTokenValue()` instead
    ///      because the latter includes pending fee, funding payment etc.
    ///      and therefore more accurately reflects a trader's settlement (ex. USDC) balance
    /// @return balance The balance amount (in settlement token's decimals)
    function getBalance(address trader) external view returns (int256 balance);

    /// @notice Get the balance of Vault of the specified collateral token and trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return balance The balance amount (in its native decimals)
    function getBalanceByToken(address trader, address token) external view returns (int256 balance);

    /// @notice Get they array of collateral token addresses that a trader has
    /// @return collateralTokens array of collateral token addresses
    function getCollateralTokens(address trader) external view returns (address[] memory collateralTokens);

    /// @notice Get account value of the specified trader
    /// @param trader The address of the trader
    /// @return accountValueX10_S account value (in settlement token's decimals)
    function getAccountValue(address trader) external view returns (int256 accountValueX10_S);

    /// @notice Get the free collateral value denominated in the settlement token of the specified trader
    /// @param trader The address of the trader
    /// @return freeCollateral the value (in settlement token's decimals) of free collateral available
    ///         for withdraw or opening new positions or orders)
    function getFreeCollateral(address trader) external view returns (uint256 freeCollateral);

    /// @notice Get the free collateral amount of the specified trader and collateral ratio
    /// @dev There are three configurations for different insolvency risk tolerances:
    ///      **conservative, moderate &aggressive**. We will start with the **conservative** one
    ///      and gradually move to **aggressive** to increase capital efficiency
    /// @param trader The address of the trader
    /// @param ratio The margin requirement ratio, imRatio or mmRatio
    /// @return freeCollateralByRatio freeCollateral (in settlement token's decimals), by using the
    ///         input margin requirement ratio; can be negative
    function getFreeCollateralByRatio(address trader, uint24 ratio)
        external
        view
        returns (int256 freeCollateralByRatio);

    /// @notice Get the free collateral amount of the specified collateral token of specified trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return freeCollateral amount of that token (in the token's native decimals)
    function getFreeCollateralByToken(address trader, address token) external view returns (uint256 freeCollateral);

    /// @notice Get the specified trader's settlement value, including pending fee, funding payment,
    ///         owed realized PnL and unrealized PnL
    /// @dev Note the difference between `settlementTokenBalanceX10_S`, `getSettlementTokenValue()` and `getBalance()`:
    ///      They are all settlement token balances but with or without
    ///      pending fee, funding payment, owed realized PnL, unrealized PnL, respectively
    ///      In practical applications, we use `getSettlementTokenValue()` to get the trader's debt (if < 0)
    /// @param trader The address of the trader
    /// @return balance The balance amount (in settlement token's decimals)
    function getSettlementTokenValue(address trader) external view returns (int256 balance);

    /// @notice Get the settlement token address
    /// @dev We assume the settlement token should match the denominator of the price oracle.
    ///      i.e. if the settlement token is USDC, then the oracle should be priced in USD
    /// @return settlementToken The address of the settlement token
    function getSettlementToken() external view returns (address settlementToken);

    /// @notice Check if a given trader's collateral token can be liquidated; liquidation criteria:
    ///         1. margin ratio falls below maintenance threshold + 20bps (mmRatioBuffer)
    ///         2. USDC debt > nonSettlementTokenValue * debtNonSettlementTokenValueRatio (ex: 75%)
    ///         3. USDC debt > debtThreshold (ex: $10000)
    //          USDC debt = USDC balance + Total Unrealized PnL
    /// @param trader The address of the trader
    /// @return isLiquidatable If the trader can be liquidated
    function isLiquidatable(address trader) external view returns (bool isLiquidatable);

    /// @notice get the margin requirement for collateral liquidation of a trader
    /// @dev this value is compared with `ClearingHouse.getAccountValue()` (int)
    /// @param trader The address of the trader
    /// @return marginRequirement margin requirement (in 18 decimals)
    function getMarginRequirementForCollateralLiquidation(address trader)
        external
        view
        returns (int256 marginRequirement);

    /// @notice Get the maintenance margin ratio for collateral liquidation
    /// @return collateralMmRatio The maintenance margin ratio for collateral liquidation
    function getCollateralMmRatio() external view returns (uint24 collateralMmRatio);

    /// @notice Get a trader's liquidatable collateral amount by a given settlement amount
    /// @param token The address of the token of the trader's collateral
    /// @param settlementX10_S The amount of settlement token the liquidator wants to pay
    /// @return collateral The collateral amount(in its native decimals) the liquidator can get
    function getLiquidatableCollateralBySettlement(address token, uint256 settlementX10_S)
        external
        view
        returns (uint256 collateral);

    /// @notice Get a trader's repaid settlement amount by a given collateral amount
    /// @param token The address of the token of the trader's collateral
    /// @param collateral The amount of collateral token the liquidator wants to get
    /// @return settlementX10_S The settlement amount(in settlement token's decimals) the liquidator needs to pay
    function getRepaidSettlementByCollateral(address token, uint256 collateral)
        external
        view
        returns (uint256 settlementX10_S);

    /// @notice Get a trader's max repaid settlement & max liquidatable collateral by a given collateral token
    /// @param trader The address of the trader
    /// @param token The address of the token of the trader's collateral
    /// @return maxRepaidSettlementX10_S The maximum settlement amount(in settlement token's decimals)
    ///         the liquidator needs to pay to liquidate a trader's collateral token
    /// @return maxLiquidatableCollateral The maximum liquidatable collateral amount
    ///         (in the collateral token's native decimals) of a trader
    function getMaxRepaidSettlementAndLiquidatableCollateral(address trader, address token)
        external
        view
        returns (uint256 maxRepaidSettlementX10_S, uint256 maxLiquidatableCollateral);

    /// @notice Get settlement token decimals
    /// @dev cached the settlement token's decimal for gas optimization
    /// @return decimals The decimals of settlement token
    function decimals() external view returns (uint8 decimals);

    /// @notice Get the borrowed settlement token amount from insurance fund
    /// @return debtAmount The debt amount (in settlement token's decimals)
    function getTotalDebt() external view returns (uint256 debtAmount);

    /// @notice Get `ClearingHouseConfig` contract address
    /// @return clearingHouseConfig The address of `ClearingHouseConfig` contract
    function getClearingHouseConfig() external view returns (address clearingHouseConfig);

    /// @notice Get `AccountBalance` contract address
    /// @return accountBalance The address of `AccountBalance` contract
    function getAccountBalance() external view returns (address accountBalance);

    /// @notice Get `InsuranceFund` contract address
    /// @return insuranceFund The address of `InsuranceFund` contract
    function getInsuranceFund() external view returns (address insuranceFund);

    /// @notice Get `Exchange` contract address
    /// @return exchange The address of `Exchange` contract
    function getExchange() external view returns (address exchange);

    /// @notice Get `ClearingHouse` contract address
    /// @return clearingHouse The address of `ClearingHouse` contract
    function getClearingHouse() external view returns (address clearingHouse);

    /// @notice Get `CollateralManager` contract address
    /// @return clearingHouse The address of `CollateralManager` contract
    function getCollateralManager() external view returns (address clearingHouse);

    /// @notice Get `WETH9` contract address
    /// @return clearingHouse The address of `WETH9` contract
    function getWETH9() external view returns (address clearingHouse);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

library Collateral {
    struct Config {
        address priceFeed;
        uint24 collateralRatio;
        uint24 discountRatio;
        uint256 depositCap;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import { Collateral } from "../lib/Collateral.sol";

abstract contract CollateralManagerStorageV1 {
    // key: token address, value: collateral config
    mapping(address => Collateral.Config) internal _collateralConfigMap;

    address internal _clearingHouseConfig;

    address internal _vault;

    uint8 internal _maxCollateralTokensPerAccount;

    uint24 internal _mmRatioBuffer;

    uint24 internal _debtNonSettlementTokenValueRatio;

    uint24 internal _liquidationRatio;

    uint24 internal _clInsuranceFundFeeRatio;

    uint256 internal _debtThreshold;

    uint256 internal _collateralValueDust;
}