// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GelatoRelayERC2771Base} from "./base/GelatoRelayERC2771Base.sol";

uint256 constant _FEE_COLLECTOR_START = 40; // offset: address + address
uint256 constant _MSG_SENDER_START = 20; // offset: address

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayFeeCollectorERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeCollectorERC2771() pure returns (address feeCollector) {
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _FEE_COLLECTOR_START))
        )
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContextERC2771
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getMsgSenderFeeCollectorERC2771() pure returns (address _msgSender) {
    assembly {
        _msgSender := shr(
            96,
            calldataload(sub(calldatasize(), _MSG_SENDER_START))
        )
    }
}

/**
 * @dev Context variant with feeCollector + _msgSender() appended to msg.data
 * Expects calldata encoding:
 *   abi.encodePacked(bytes data, address feeCollectorAddress, address _msgSender)
 * Therefore, we're expecting 40 bytes to be appended to normal msgData
 *    feeCollector: - 40 bytes
 *    _msgSender: - 20 bytes
 */

/// @dev Do not use with GelatoRelayFeeCollectorERC2771 - pick only one
abstract contract GelatoRelayFeeCollectorERC2771 is GelatoRelayERC2771Base {
    function _getMsgData() internal view returns (bytes calldata) {
        return
            _isGelatoRelayERC2771(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    function _getMsgSender() internal view returns (address) {
        return
            _isGelatoRelayERC2771(msg.sender)
                ? _getMsgSenderFeeCollectorERC2771()
                : msg.sender;
    }

    // Only use with GelatoRelayERC2771Base onlyGelatoRelayERC2771 or `_isGelatoRelayERC2771` checks
    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorERC2771();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GELATO_RELAY_ERC2771} from "../constants/GelatoRelay.sol";

abstract contract GelatoRelayERC2771Base {
    modifier onlyGelatoRelayERC2771() {
        require(_isGelatoRelayERC2771(msg.sender), "onlyGelatoRelayERC2771");
        _;
    }

    function _isGelatoRelayERC2771(address _forwarder)
        internal
        pure
        returns (bool)
    {
        return _forwarder == GELATO_RELAY_ERC2771;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant GELATO_RELAY = 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;
address constant GELATO_RELAY_ERC2771 = 0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    GelatoRelayFeeCollectorERC2771,
    _getMsgSenderFeeCollectorERC2771
} from "@gelatonetwork/relay-context/contracts/GelatoRelayFeeCollectorERC2771.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DEV_GELATO_RELAY_ERC2771} from "./constants/Addresses.sol";

// Inheriting GelatoRelayFeeCollector gives access to:
// 1. _getFeeCollector(): returns the address of Gelato's feeCollector
// 2. __msgData(): returns the original msg.data without feeCollector appended
// 3. onlyGelatoRelay modifier: allows only Gelato Relay's smart contract to call the function
contract CounterFeeCollectorERC2771 is Proxied, GelatoRelayFeeCollectorERC2771 {
    using Address for address payable;

    uint256 public counter;

    // solhint-disable-next-line var-name-mixedcase
    bool public immutable IS_DEV_ENV;

    event GetBalance(uint256 balance);
    event IncrementCounter(uint256 newCounterValue, address msgSender);

    constructor(bool _isDevEnv) {
        IS_DEV_ENV = _isDevEnv;
    }

    // `increment` is the target function to call
    // this function increments the state variable `counter` by 1
    // Payment to Gelato
    // NOTE: be very careful here!
    // if you do not use the onlyGelatoRelayERC2771 modifier,
    // anyone could encode themselves as the fee collector
    // in the low-level data and drain tokens from this contract.
    function increment(uint256 _fee) external {
        // Checks
        if (IS_DEV_ENV) {
            require(
                msg.sender == DEV_GELATO_RELAY_ERC2771,
                "CounterFeeCollectorERC2771.increment: DEV_GELATO_RELAY_ERC2771"
            );
        } else {
            require(
                _isGelatoRelayERC2771(msg.sender),
                "CounterFeeCollectorERC2771.increment: isGelatoRelayERC2771"
            );
        }

        // Effects
        counter++;

        // Interactions
        payable(_getFeeCollector()).sendValue(_fee);

        emit IncrementCounter(
            counter,
            IS_DEV_ENV ? _getMsgSenderDevEnv() : _getMsgSender()
        );
    }

    function emptyBalance() external onlyProxyAdmin {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function getBalance() external {
        emit GetBalance(address(this).balance);
    }

    function _getMsgSenderDevEnv() internal view returns (address) {
        return
            msg.sender == DEV_GELATO_RELAY_ERC2771
                ? _getMsgSenderFeeCollectorERC2771()
                : msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

address constant DEV_GELATO_RELAY = 0xB08823e822885cE7eEfDD75A63363fb287B64167;
address constant DEV_GELATO_RELAY_ERC2771 = 0xf8324aEDDE8b3204332558F32Ad8f46F184Ac630;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}