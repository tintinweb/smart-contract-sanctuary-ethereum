// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { Constant } from "../lib/Constant.sol";
import { ClearingHouseCallee } from "../clearinghouse/ClearingHouseCallee.sol";
import { IERC20Metadata } from "../interface/IERC20Metadata.sol";
import { IAmmFactory } from "../interface/IAmmFactory.sol";
import { IVirtualToken } from "../interface/IVirtualToken.sol";
import { AmmFactoryStorageV1 } from "../storage/AmmFactoryStorage.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract AmmFactory is IAmmFactory, ClearingHouseCallee, AmmFactoryStorageV1 {
    using AddressUpgradeable for address;

    //
    // MODIFIER
    //

    modifier checkRatio(uint24 ratio) {
        // AF_RO: ratio overflow
        require(ratio <= 1e6, "AF_RO");
        _;
    }

    modifier checkAmm(address baseToken) {
        // AF_PNE: amm not exists
        require(_ammMap[baseToken] != Constant.ADDRESS_ZERO, "AF_PNE");
        _;
    }

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(address quoteTokenArg) external initializer {
        __ClearingHouseCallee_init();

        // AF_QTNC: QuoteToken is not contract
        require(quoteTokenArg.isContract(), "AF_QTNC");

        // update states
        _quoteToken = quoteTokenArg;
    }

    function addAmm(
        address baseToken,
        address amm,
        uint24 exchangeFeeRatio
    ) external override {
        // AF_EAM: existent amm
        require(_ammMap[baseToken] == Constant.ADDRESS_ZERO, "AF_EAM");
        // AF_BDN18: baseToken decimals is not 18
        require(IERC20Metadata(baseToken).decimals() == 18, "AF_BDN18");
        // AF_CHBNE: ClearingHouse base token balance not enough
        require(IERC20Metadata(baseToken).balanceOf(_clearingHouse) == type(uint256).max, "AF_CHBNE");
        // AF_QTSNE: quote token total supply not enough
        require(IERC20Metadata(_quoteToken).totalSupply() == type(uint256).max, "AF_QTSNE");
        // AF_AMNC: amm is not contract
        require(amm.isContract(), "AF_AMNC");
        // AF_CNBWL: ClearingHouse not in baseToken whitelist
        require(IVirtualToken(baseToken).isInWhitelist(_clearingHouse), "AF_CNBWL");
        // AF_AMNBWL: amm not in baseToken whitelist
        require(IVirtualToken(baseToken).isInWhitelist(amm), "AF_AMNBWL");

        // AF_CHNQWL: ClearingHouse not in quoteToken whitelist
        require(IVirtualToken(_quoteToken).isInWhitelist(_clearingHouse), "AF_CHNQWL");
        // AF_AMNQWL: amm not in quoteToken whitelist
        require(IVirtualToken(_quoteToken).isInWhitelist(amm), "AF_AMNQWL");

        _ammMap[baseToken] = amm;
        _exchangeFeeRatioMap[baseToken] = exchangeFeeRatio;

        emit AmmAdded(baseToken, exchangeFeeRatio, amm);
    }

    function setExchangeFeeRatio(address baseToken, uint24 exchangeFeeRatio)
        external
        override
        checkAmm(baseToken)
        checkRatio(exchangeFeeRatio)
        onlyOwner
    {
        _exchangeFeeRatioMap[baseToken] = exchangeFeeRatio;
        emit ExchangeFeeRatioChanged(baseToken, exchangeFeeRatio);
    }

    function setInsuranceFundFeeRatio(address baseToken, uint24 insuranceFundFeeRatioArg)
        external
        override
        checkAmm(baseToken)
        checkRatio(insuranceFundFeeRatioArg)
        onlyOwner
    {
        _insuranceFundFeeRatioMap[baseToken] = insuranceFundFeeRatioArg;
        emit InsuranceFundFeeRatioChanged(insuranceFundFeeRatioArg);
    }

    //
    // EXTERNAL VIEW
    //

    function getQuoteToken() external view override returns (address) {
        return _quoteToken;
    }

    function getAmm(address baseToken) external view override checkAmm(baseToken) returns (address) {
        return _ammMap[baseToken];
    }

    function getExchangeFeeRatio(address baseToken) external view override checkAmm(baseToken) returns (uint24) {
        return _exchangeFeeRatioMap[baseToken];
    }

    function getInsuranceFundFeeRatio(address baseToken) external view override checkAmm(baseToken) returns (uint24) {
        return _insuranceFundFeeRatioMap[baseToken];
    }

    function getAmmInfo(address baseToken) external view override checkAmm(baseToken) returns (AmmInfo memory) {
        return
            AmmInfo({
                amm: _ammMap[baseToken],
                exchangeFeeRatio: _exchangeFeeRatioMap[baseToken],
                insuranceFundFeeRatio: _insuranceFundFeeRatioMap[baseToken]
            });
    }

    function hasAmm(address baseToken) external view override returns (bool) {
        return _ammMap[baseToken] != Constant.ADDRESS_ZERO;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

library Constant {
    address internal constant ADDRESS_ZERO = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { SafeOwnable } from "../base/SafeOwnable.sol";

abstract contract ClearingHouseCallee is SafeOwnable {
    address internal _clearingHouse;
    uint256[50] private __gap;

    event ClearingHouseChanged(address indexed clearingHouse);

    // solhint-disable-next-line func-order
    function __ClearingHouseCallee_init() internal initializer {
        __SafeOwnable_init();
    }

    function setClearingHouse(address clearingHouseArg) external onlyOwner {
        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    function getClearingHouse() external view returns (address) {
        return _clearingHouse;
    }

    function _requireOnlyClearingHouse() internal view {
        // CHD_OCH: only ClearingHouse
        require(_msgSender() == _clearingHouse, "CHD_OCH");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
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
pragma solidity 0.8.0;
pragma abicoder v2;

interface IAmmFactory {
    struct AmmInfo {
        address amm;
        uint24 exchangeFeeRatio;
        uint24 insuranceFundFeeRatio;
    }

    event AmmAdded(address indexed baseToken, uint24 indexed exchangeFeeRatio, address indexed amm);

    event ExchangeFeeRatioChanged(address baseToken, uint24 exchangeFeeRatio);

    event InsuranceFundFeeRatioChanged(uint24 insuranceFundFeeRatio);

    function addAmm(
        address baseToken,
        address amm,
        uint24 exchangeFeeRatio
    ) external;

    function setExchangeFeeRatio(address baseToken, uint24 exchangeFeeRatio) external;

    function setInsuranceFundFeeRatio(address baseToken, uint24 insuranceFundFeeRatioArg) external;

    function getAmm(address baseToken) external view returns (address);

    function getExchangeFeeRatio(address baseToken) external view returns (uint24);

    function getInsuranceFundFeeRatio(address baseToken) external view returns (uint24);

    function getAmmInfo(address baseToken) external view returns (AmmInfo memory);

    function getQuoteToken() external view returns (address);

    function hasAmm(address baseToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

interface IVirtualToken {
    function isInWhitelist(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

/// @notice For future upgrades, do not change AmmFactoryStorageV1. Create a new
/// contract which implements AmmFactoryStorageV1 and following the naming convention
/// AmmFactoryStorageVX.
abstract contract AmmFactoryStorageV1 {
    address internal _quoteToken;

    // key: baseToken, value: amm
    mapping(address => address) internal _ammMap;

    // key: baseToken, what insurance fund get = exchangeFee * insuranceFundFeeRatio
    mapping(address => uint24) internal _insuranceFundFeeRatioMap;

    // key: baseToken , exchange fee
    mapping(address => uint24) internal _exchangeFeeRatioMap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Constant } from "../lib/Constant.sol";

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
        // SO_CNO: caller not owner
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
        emit OwnershipTransferred(Constant.ADDRESS_ZERO, msgSender);
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
        emit OwnershipTransferred(_owner, Constant.ADDRESS_ZERO);
        _owner = Constant.ADDRESS_ZERO;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // SO_NW0: newOwner is 0
        require(newOwner != Constant.ADDRESS_ZERO, "SO_NW0");
        // SO_SAO: same as original
        require(newOwner != _owner, "SO_SAO");
        // SO_SAC: same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // SO_C0: candidate is zero
        require(_candidate != Constant.ADDRESS_ZERO, "SO_C0");
        // SO_CNC: caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = Constant.ADDRESS_ZERO;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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