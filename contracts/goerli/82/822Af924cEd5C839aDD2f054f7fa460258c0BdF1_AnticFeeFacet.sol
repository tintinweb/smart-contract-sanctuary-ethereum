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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAnticFee} from "../../interfaces/IAnticFee.sol";
import {LibAnticFee} from "../../libraries/LibAnticFee.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFee` for docs
contract AnticFeeFacet is IAnticFee {
    function antic() external view override returns (address) {
        return LibAnticFee._antic();
    }

    function calculateAnticJoinFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        return LibAnticFee._calculateAnticJoinFee(value);
    }

    function calculateAnticSellFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        return LibAnticFee._calculateAnticSellFee(value);
    }

    function anticFeePercentages()
        external
        view
        override
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage)
    {
        return LibAnticFee._anticFeePercentages();
    }

    /// @return the total Antic join fee deposited
    function totalJoinFeeDeposits() external view returns (uint256) {
        return LibAnticFee._totalJoinFeeDeposits();
    }

    /// @return the antic fee deposit made by `member`
    function memberAnticFeeDeposits(address member)
        external
        view
        returns (uint256)
    {
        return LibAnticFee._memberFeeDeposits(member);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Antic fee collection
interface IAnticFee {
    /// @dev Emitted on value transfer to Antic
    /// @param amount the amount transferred to Antic
    event TransferredToAntic(uint256 amount);

    /// @return The address that the Antic fees will be sent to
    function antic() external view returns (address);

    /// @return The fee amount that will be collected from
    /// `value` when joining the group
    function calculateAnticJoinFee(uint256 value)
        external
        view
        returns (uint256);

    /// @return The fee amount that will be collected from `value` when
    /// value is transferred to the contract
    function calculateAnticSellFee(uint256 value)
        external
        view
        returns (uint256);

    /// @dev The percentages are out of 1000. So 25 -> 25/1000 = 2.5%
    /// @return joinFeePercentage The Antic fee percentage for join
    /// @return sellFeePercentage The Antic fee percentage for sell/receive
    function anticFeePercentages()
        external
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibTransfer} from "./LibTransfer.sol";
import {StorageAnticFee} from "../storage/StorageAnticFee.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFee` for docs
library LibAnticFee {
    event TransferredToAntic(uint256 amount);

    function _antic() internal view returns (address) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.antic;
    }

    /// @return The amount of fee collected so far from `join`
    function _totalJoinFeeDeposits() internal view returns (uint256) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.totalJoinFeeDeposits;
    }

    function _calculateAnticJoinFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.joinFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    function _calculateAnticSellFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.sellFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    /// @dev Store `member`'s join fee
    function _depositJoinFeePayment(address member, uint256 value) internal {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        ds.memberFeeDeposits[member] += value;
        ds.totalJoinFeeDeposits += value;
    }

    /// @dev Removes `member` from fee collection
    /// @return amount The amount that needs to be refunded to `member`
    function _refundFeePayment(address member)
        internal
        returns (uint256 amount)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        amount = ds.memberFeeDeposits[member];
        ds.totalJoinFeeDeposits -= amount;
        delete ds.memberFeeDeposits[member];
    }

    /// @dev Transfer `value` to Antic
    function _untrustedTransferToAntic(uint256 value) internal {
        emit TransferredToAntic(value);

        LibTransfer._untrustedSendValue(payable(_antic()), value);
    }

    /// @dev Transfer all the `join` fees collected to Antic
    function _untrustedTransferJoinAnticFee() internal {
        _untrustedTransferToAntic(_totalJoinFeeDeposits());
    }

    function _anticFeePercentages()
        internal
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        joinFeePercentage = ds.joinFeePercentage;
        sellFeePercentage = ds.sellFeePercentage;
    }

    function _memberFeeDeposits(address member)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.memberFeeDeposits[member];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

/// @author Amit Molek
/// @dev Transfer helpers
library LibTransfer {
    /// @dev Sends `value` in wei to `recipient`
    /// Reverts on failure
    function _untrustedSendValue(address payable recipient, uint256 value)
        internal
    {
        Address.sendValue(recipient, value);
    }

    /// @dev Performs a function call
    function _untrustedCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool successful, bytes memory returnData) {
        require(
            address(this).balance >= value,
            "Transfer: insufficient balance"
        );

        (successful, returnData) = to.call{value: value}(data);
    }

    /// @dev Extracts and bubbles the revert reason if exist, otherwise reverts with a hard-coded reason.
    function _revertWithReason(bytes memory returnData) internal pure {
        if (returnData.length == 0) {
            revert("Transfer: call reverted without a reason");
        }

        // Bubble the revert reason
        assembly {
            let returnDataSize := mload(returnData)
            revert(add(32, returnData), returnDataSize)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for Antic fee
library StorageAnticFee {
    uint16 public constant PERCENTAGE_DIVIDER = 1000; // .1 precision
    uint16 public constant MAX_ANTIC_FEE_PERCENTAGE = 500; // 50%

    struct DiamondStorage {
        address antic;
        /// @dev Maps between member and it's Antic fee deposit
        /// Used only in `leave`
        mapping(address => uint256) memberFeeDeposits;
        /// @dev Total Antic join deposits mades
        uint256 totalJoinFeeDeposits;
        /// @dev Antic join fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 joinFeePercentage;
        /// @dev Antic sell/receive fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 sellFeePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.AnticFee");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        address antic,
        uint16 joinFeePercentage,
        uint16 sellFeePercentage
    ) internal {
        DiamondStorage storage ds = diamondStorage();

        require(antic != address(0), "Storage: Invalid Antic address");

        require(
            joinFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic join fee percentage"
        );

        require(
            sellFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic sell/receive fee percentage"
        );

        ds.antic = antic;
        ds.joinFeePercentage = joinFeePercentage;
        ds.sellFeePercentage = sellFeePercentage;
    }
}