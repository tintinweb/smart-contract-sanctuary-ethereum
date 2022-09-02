// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

contract Proxy {
    /* =========  MEMBER VARS ========== */
    // Code(Implementation Logic) position in storage is keccak256("implementation.address.slot")-1 = "0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6"
    // Admin/Owner position in storage is keccak256("admin.address.slot")-1 = "0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543"

    /* ===========   EVENTS  =========== */
    /**
     * @dev Emitted when the _implementation is upgraded.
     */
    event Upgraded(
        address indexed oldImplementation,
        address indexed newImplementation
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /* ========== MODIFIERS ============= */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address contractLogic) {
        // save the code address
        _upgradeTo(contractLogic);
        _transferOwnership(msg.sender);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @dev fallback
     */
    fallback() external {
        _delegate();
    }

    /**
     * @dev Upgrade function to be only called by owner
     */
    function upgrade(address _newLogic) external onlyOwner {
        _upgradeTo(_newLogic);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Proxy: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev external function to get the current implementation/logic address
     */
    function getImplementationAddress() external view returns (address logic) {
        return _getImplementationAddress();
    }

    /**
     * @dev external function to get the current admin/owner address
     */
    function getOwnerAddress() external view returns (address logic) {
        return _getOwnerAddress();
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address _newLogic) internal {
        require(
            _newLogic != address(0),
            "Proxy:new implementation cannot be zero address"
        );
        require(
            Address.isContract(_newLogic),
            "Proxy:new implementation is not a contract"
        );
        require(
            _getImplementationAddress() != _newLogic,
            "Proxy:new implementation cannot be the same address"
        );

        assembly {
            // solium-disable-line
            sstore(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6,
                _newLogic
            )
        }
        emit Upgraded(_getImplementationAddress(), _newLogic);
    }

    /**
     * @dev delegate to implementation logic
     */
    function _delegate() internal {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * Emits an {OwnershipTransferred} event.
     */
    function _transferOwnership(address _newOwner) internal {
        address oldOwner = _getOwnerAddress();
        assembly {
            // solium-disable-line
            sstore(
                0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543,
                _newOwner
            )
        }
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require(
            _getOwnerAddress() == msg.sender,
            "Proxy: caller is not the owner"
        );
    }

    /**
     * @dev internal function to get the current implementation/logic address
     */
    function _getImplementationAddress() internal view returns (address logic) {
        assembly {
            // solium-disable-line
            logic := sload(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6
            )
        }
    }

    /**
     * @dev internal function to get the current admin/owner address
     */
    function _getOwnerAddress() internal view returns (address owner) {
        assembly {
            // solium-disable-line
            owner := sload(
                0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543
            )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}