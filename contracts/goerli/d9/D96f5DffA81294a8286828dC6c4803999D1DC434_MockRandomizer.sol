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
pragma solidity >=0.8.10;
pragma experimental ABIEncoderV2;

/// A mixin that allows a contract to add/remove admins
/// and guard functions as `onlyAdmin`
abstract contract Administrated {
    mapping (address => bool) private _isAdmin;
    bool public permaLocked;

    /// By default, the message sender is the only admin.
    constructor() {
        permaLocked = false;
        _isAdmin[msg.sender] = true;
    }

    /// Returns true if the given address is an admin of this contract.
    function isAdmin(address addr) public view returns (bool) {
        return !permaLocked && _isAdmin[addr];
    }

    /// Restricts the usage of a given function to admins only.
    modifier onlyAdmin() {
        require(!permaLocked, "Administrated: Admin functions are permanently locked");
        require(isAdmin(msg.sender), "Administrated: Sender must be an admin");
        _;
    }

    /// Adds an admin to the contract, or does nothing if the given address is already admin.
    ///
    /// Can only be called by admins.
    function addAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = true;
    }

    /// Removes an admin from the contract, or does nothing if the given address is not an admin.
    /// If you remove the last admin you have access to, you'll no longer be able to perform admin functionality.
    ///
    /// Can only be called by admins.
    function removeAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = false;
    }

    /// Permanently revokes all admin rights.
    ///
    /// No `onlyAdmin` functions are callable after using this function,
    /// so make sure you call it only after you no longer need admin privileges in any capacity.
    function permaLock() external onlyAdmin {
        permaLocked = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// interface for randomizer.ai's randomizing oracle

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function request(uint256 callbackGasLimit, uint256 confirmations)
        external
        returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations)
        external view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Administrated} from "./Administrated.sol";
import {IRandomizer} from "./IRandomizer.sol";
import {RandomizerClient} from "./RandomizerClient.sol";

contract PRNGRandomizer is IRandomizer, Administrated {
    bytes32 private _state;
    mapping (uint256 => address) public requests;
    uint256 _requestId;

    constructor() {
        _state = getEntropy();
    }

    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    function generate() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(getEntropy(), _state));
    }

    function fulfillRequest(uint256 requestId) external {
        address target = requests[requestId];
        require(isAdmin(msg.sender) || target == msg.sender, "Not allowed to fulfill that request");

        RandomizerClient(target).randomizerCallback(requestId, generate());
    }

    function request(uint256) public returns (uint256) {
        requests[++_requestId] = msg.sender;
        return _requestId;
    }

    function request(uint256 callbackGasLimit, uint256) public returns (uint256) {
        return request(callbackGasLimit);
    }

    function clientWithdrawTo(address to, uint256 amount) external onlyAdmin {
        Address.sendValue(payable(to), amount);
    }

    function estimateFee(uint256) public pure returns (uint256) {
        return 20000;
    }

    function estimateFee(uint256 callbackGasLimit, uint256) public pure returns (uint256) {
        return estimateFee(callbackGasLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IRandomizer} from "./IRandomizer.sol";

// interface for users of randomizer.ai

abstract contract RandomizerClient {
    IRandomizer public randomizer;

    constructor(address _randomizer) {
        randomizer = IRandomizer(_randomizer);
    }

    function onReceiveRandomValue(uint256 _id, bytes32 _value) internal virtual;

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(msg.sender == address(randomizer), "Caller is not the Randomizer");
        onReceiveRandomValue(_id, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {PRNGRandomizer} from "src/PRNGRandomizer.sol";
import {RandomizerClient} from "src/RandomizerClient.sol";

contract MockRandomizer is PRNGRandomizer {
    function fulfillRequestWithValue(uint256 requestId, bytes32 value) external {
        address target = requests[requestId];

        RandomizerClient(target).randomizerCallback(requestId, value);
    }
}