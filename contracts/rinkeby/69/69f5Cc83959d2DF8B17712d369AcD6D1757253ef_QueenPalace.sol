// SPDX-License-Identifier: MIT

/// @title Contract that handles Queen's Palace maintenance

/************************************************
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 *************************************************/

pragma solidity ^0.8.12;

import {Address} from "Address.sol";

import {BaseContractController} from "BaseContractController.sol";
import {IQueenPalace} from "IQueenPalace.sol";
import {IQueenStaff} from "IQueenStaff.sol";

contract QueenPalace is IQueenPalace, BaseContractController {
    mapping(uint256 => sDEPOSIT[]) depositHistory;
    mapping(uint256 => sWITHDRAW) withdrawHistory;
    sDEPOSIT[] deposits;
    sWITHDRAW[] withdraws;
    uint256 private nextWithdraw;

    constructor(IQueenStaff _queenStaff) {
        nextWithdraw = 1;
        queenStaff = _queenStaff;
    }

    /**
     * @notice Treasure Balance.
     */
    function palaceTreasure() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Treasure Balance.
     */
    function getDepositHistory(uint256 queeneId)
        external
        view
        returns (sDEPOSIT[] memory)
    {
        if (queeneId > 0) return depositHistory[queeneId];
        else return deposits;
    }

    /**
     * @notice Treasure Balance.
     */
    function getWithdrawHistory(
        uint256 initialBlockTime,
        uint256 finalBlockTime
    ) external view returns (sWITHDRAW[] memory) {
        if (initialBlockTime > 0 || finalBlockTime > 0) {
            uint256 itemsCounter = 0;
            for (uint256 idx = 1; idx <= withdraws.length; idx++) {
                if (
                    withdrawHistory[idx].blockTimeStamp >= initialBlockTime &&
                    withdrawHistory[idx].blockTimeStamp <= finalBlockTime
                ) {
                    itemsCounter++;
                }
            }
            sWITHDRAW[] memory _withdrawHistory = new sWITHDRAW[](itemsCounter);
            itemsCounter = 0;
            for (uint256 idx = 1; idx <= withdraws.length; idx++) {
                if (
                    withdrawHistory[idx].blockTimeStamp >= initialBlockTime &&
                    withdrawHistory[idx].blockTimeStamp <= finalBlockTime
                ) {
                    _withdrawHistory[itemsCounter++] = sWITHDRAW({
                        blockNumber: withdrawHistory[idx].blockNumber,
                        blockTimeStamp: withdrawHistory[idx].blockTimeStamp,
                        value: withdrawHistory[idx].value,
                        withdrawer: withdrawHistory[idx].withdrawer,
                        documentsUri: withdrawHistory[idx].documentsUri
                    });
                }
            }
            return _withdrawHistory;
        } else {
            sWITHDRAW[] memory _withdrawHistory = new sWITHDRAW[](
                withdraws.length
            );
            for (uint256 idx = 1; idx <= withdraws.length; idx++) {
                _withdrawHistory[idx - 1] = sWITHDRAW({
                    blockNumber: withdrawHistory[idx].blockNumber,
                    blockTimeStamp: withdrawHistory[idx].blockTimeStamp,
                    value: withdrawHistory[idx].value,
                    withdrawer: withdrawHistory[idx].withdrawer,
                    documentsUri: withdrawHistory[idx].documentsUri
                });
            }
            return _withdrawHistory;
        }
    }

    // fallback function
    fallback() external payable onlyOwnerOrAuctionHouse {
        _depositToPalaceTreasure(msg.sender, 0, msg.value);
    }

    // receive function
    receive() external payable onlyOwnerOrAuctionHouse {
        _depositToPalaceTreasure(msg.sender, 0, msg.value);
    }

    /**
     * @notice receive ETH to enrich palace treasure.
     */
    function depositToPalaceTreasure(uint256 _queeneAuctionId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyOwnerOrAuctionHouse
    {
        _depositToPalaceTreasure(msg.sender, _queeneAuctionId, msg.value);
    }

    /**
     * @notice receive ETH to enrich palace treasure.
     */
    function _depositToPalaceTreasure(
        address _sender,
        uint256 _queeneAuctionId,
        uint256 amount
    ) private {
        require(amount > 0, "invalid amount");
        depositHistory[_queeneAuctionId].push(
            sDEPOSIT({
                queeneId: _queeneAuctionId,
                blockNumber: block.number,
                blockTimeStamp: block.timestamp,
                value: msg.value
            })
        );
        deposits.push(
            sDEPOSIT({
                queeneId: _queeneAuctionId,
                blockNumber: block.number,
                blockTimeStamp: block.timestamp,
                value: msg.value
            })
        );

        emit TreasureDeposit(_sender, _queeneAuctionId, amount);
    }

    /**
     * @notice withdraw balance for Palace Maintenance.
     */
    function withdrawFromTreasure(uint256 _amount, string calldata uri)
        external
        nonReentrant
        whenNotPaused
        onlyOwner
    {
        _withdrawFromTreasure(payable(msg.sender), _amount, uri);
    }

    /**
     * @notice withdraw balance for Palace Maintenance.
     */
    function _withdrawFromTreasure(
        address payable to,
        uint256 _amount,
        string calldata uri
    ) private {
        require(
            _amount <= address(this).balance,
            "Not enough balance on treasure!"
        );

        Address.sendValue(to, _amount);

        withdrawHistory[nextWithdraw++] = sWITHDRAW({
            blockNumber: block.number,
            blockTimeStamp: block.timestamp,
            value: _amount,
            withdrawer: to,
            documentsUri: uri
        });

        withdraws.push(
            sWITHDRAW({
                blockNumber: block.number,
                blockTimeStamp: block.timestamp,
                value: _amount,
                withdrawer: msg.sender,
                documentsUri: uri
            })
        );
    }

    /**
     * @notice retrieve auction funds that went to fallback.
     */
    function retrieveAuctionFallbackFunds()
        external
        nonReentrant
        whenNotPaused
        onlyOwner
    {
        //withdraw all funds available for developer team
        (bool success, bytes memory data) = queenStaff
            .QueenAuctionHouseProxyAddr()
            .call(abi.encodeWithSignature("withdrawFallbackFund()"));

        require(success, "Error retrieving fallback funds");
    }
}

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

// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 *************************************************/

pragma solidity ^0.8.12;

//import {ERC165} from "ERC165.sol";
import {Pausable} from "Pausable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Ownable} from "Ownable.sol";
import {Address} from "Address.sol";

import {RoyalLibrary} from "RoyalLibrary.sol";
import {IBaseContractController} from "IBaseContractController.sol";
import {IQueenStaff} from "IQueenStaff.sol";
import {IQueenPalace} from "IQueenPalace.sol";

contract BaseContractController is
    IBaseContractController,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    IQueenStaff internal queenStaff;
    IQueenPalace internal queenPalace;

    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(address => bool) internal allowedEcosystem;

    /************************** vCONTROLLER REGION *************************************************** */

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return supportedInterfaces[interfaceID];
    }

    /**
     *IN
     *_allowee: address of contract to be allowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function allowOnEcosystem(address _allowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        allowedEcosystem[_allowee] = true;
        return allowedEcosystem[_allowee];
    }

    /**
     *IN
     *_disallowee: address of contract to be disallowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function disallowOnEcosystem(address _disallowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_disallowee), "Invalid address!");

        allowedEcosystem[_disallowee] = false;
        return allowedEcosystem[_disallowee];
    }

    /**
     *IN
     *_allowee: address to verify allowance
     *OUT
     *status: allow current status for contract
     */
    function isAllowedOnEconsystem(address _allowee)
        public
        view
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        return allowedEcosystem[_allowee];
    }

    /**
     *IN
     *_queenStaff: address of queen staff contract
     *OUT
     *newQueenStaff: new QueenStaff contract address
     */
    function setQueenStaff(IQueenStaff _queenStaff)
        external
        nonReentrant
        whenNotPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenStaff(_queenStaff);
    }

    /**
     *IN
     *_queenStaff: address of queen staff contract
     *OUT
     *newQueenStaff: new QueenStaff contract address
     */
    function _setQueenStaff(IQueenStaff _queenStaff) internal {
        queenStaff = _queenStaff;
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     */
    function setQueenPalace(IQueenPalace _queenPalace)
        external
        nonReentrant
        whenNotPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenPalace(_queenPalace);
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     */
    function _setQueenPalace(IQueenPalace _queenPalace) internal {
        queenPalace = _queenPalace;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */

    modifier onlyChiefArtist() {
        require(msg.sender == queenStaff.artist(), "Not Artist");
        _;
    }

    modifier onlyArtist() {
        require(queenStaff.isArtist(msg.sender), "Not Artist");
        _;
    }

    modifier onlyChiefDeveloper() {
        require(msg.sender == queenStaff.developer(), "Not Developer");
        _;
    }

    modifier onlyDeveloper() {
        require(queenStaff.isDeveloper(msg.sender), "Not Developer");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == queenStaff.minter(), "Not Minter");
        _;
    }

    modifier onlyActor() {
        require(
            msg.sender == owner() ||
                queenStaff.isArtist(msg.sender) ||
                queenStaff.isDeveloper(msg.sender),
            "Not a valid Actor"
        );
        _;
    }

    modifier onlyActorOrDAO() {
        require(
            msg.sender == owner() ||
                queenStaff.isArtist(msg.sender) ||
                queenStaff.isDeveloper(msg.sender) ||
                msg.sender == queenStaff.dao(),
            "Not a valid Actor Nor DAO"
        );
        _;
    }

    modifier onlyEcosystemOrActor() {
        require(
            msg.sender == owner() ||
                queenStaff.isArtist(msg.sender) ||
                queenStaff.isDeveloper(msg.sender) ||
                isAllowedOnEconsystem(msg.sender),
            "Not a valid Ecosystem Nor Actor"
        );
        _;
    }

    modifier onlyEcosystemOrActorOrDAO() {
        require(
            msg.sender == owner() ||
                queenStaff.isArtist(msg.sender) ||
                queenStaff.isDeveloper(msg.sender) ||
                msg.sender == queenStaff.dao() ||
                isAllowedOnEconsystem(msg.sender),
            "Not a valid Ecosystem Nor Actor Nor DAO"
        );
        _;
    }

    modifier onlyOwnerOrArtist() {
        require(
            msg.sender == owner() || queenStaff.isArtist(msg.sender),
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOwnerOrChiefArtist() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.artist(),
            "Not Owner nor Artist"
        );
        _;
    }

    modifier onlyOwnerOrChiefDeveloper() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.developer(),
            "Not Owner nor Developer"
        );
        _;
    }

    modifier onlyOwnerOrDeveloper() {
        require(
            msg.sender == owner() || queenStaff.isDeveloper(msg.sender),
            "Not Owner nor Developer"
        );
        _;
    }

    modifier onlyOwnerOrDeveloperOrDAO() {
        require(
            msg.sender == owner() ||
                queenStaff.isDeveloper(msg.sender) ||
                msg.sender == queenStaff.dao(),
            "Not Owner nor Developer nor DAO"
        );
        _;
    }

    modifier onlyOwnerOrArtistOrDAO() {
        require(
            msg.sender == owner() ||
                queenStaff.isArtist(msg.sender) ||
                msg.sender == queenStaff.dao(),
            "Not Owner nor Artist nor DAO"
        );
        _;
    }
    modifier onlyOwnerOrDAO() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.dao(),
            "Not Owner nor DAO"
        );
        _;
    }

    modifier onlyOwnerOrMinter() {
        require(
            msg.sender == owner() || msg.sender == queenStaff.minter(),
            "Not Owner nor Minter"
        );
        _;
    }

    modifier onlyOwnerOrAuctionHouse() {
        require(
            msg.sender == owner() ||
                msg.sender == address(queenStaff.QueenAuctionHouseProxyAddr()),
            "Not Owner nor Auction House"
        );
        _;
    }

    modifier onlyOnImplementationOrDAO() {
        require(
            queenStaff.isOnImplementation() || msg.sender == queenStaff.dao(),
            "Not On Implementation and sender is not DAO"
        );
        _;
    }

    modifier onlyOnImplementationOrPaused() {
        require(
            queenStaff.isOnImplementation() || paused(),
            "Not On Implementation nor Paused"
        );
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /**
     *IN
     *OUT
     *if given address is owner
     */
    function isOwner(address _address) external view override returns (bool) {
        return owner() == _address;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.12;

import {EnumerableSet} from "EnumerableSet.sol";

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        string uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        sBLOOD[] blueBlood;
        sDNA[] dna;
        string finalArt;
        string description;
    }

    struct sSIR {
        bool isSir;
        address sirAddress;
        uint256 queen;
    }

    struct sAUCTION {
        uint256 queeneId;
        uint256 lastBidAmount;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 initialBidPrice;
        address payable bidder;
        bool ended;
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.12;

interface IBaseContractController {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.12;

import {IQueenLab} from "IQueenLab.sol";
import {IQueenTraits} from "IQueenTraits.sol";
import {IQueenE} from "IQueenE.sol";
import {IQueenAuctionHouse} from "IQueenAuctionHouse.sol";

interface IQueenStaff {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function isArtist(address addr) external view returns (bool);

    function dao() external returns (address);

    function developer() external view returns (address);

    function isDeveloper(address devAddr) external view returns (bool);

    function minter() external view returns (address);

    function QueenLab() external view returns (IQueenLab);

    function QueenTraits() external view returns (IQueenTraits);

    function QueenAuctionHouse() external view returns (IQueenAuctionHouse);

    function payStaff(uint256 _queeneAuctionId) external payable;

    function QueenE() external view returns (IQueenE);

    function whiteListed() external view returns (uint256);

    function isWhiteListed(address _addr) external view returns (bool);

    function QueenAuctionHouseProxyAddr() external view returns (address);

    function retrieveAuctionFallbackFunds() external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.12;

import {IBaseContractController} from "IBaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";
import {IQueenTraits} from "IQueenTraits.sol";
import {IQueenE} from "IQueenE.sol";

interface IQueenLab is IBaseContractController {
    //posible rarities
    enum queeneRarity {
        COMMOM,
        RARE,
        SUPER_RARE,
        LEGENDARY
    }

    function BuildDna(uint256 queeneId, IQueenTraits _traitsContract)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function ProduceBlueBlood(
        RoyalLibrary.sDNA[] memory dna,
        IQueenTraits _traitsContract
    ) external view returns (RoyalLibrary.sBLOOD[] memory);

    function GenerateQueen(
        uint256 _queenId,
        IQueenTraits _traitsContract,
        IQueenE _queeneContract
    ) external view returns (RoyalLibrary.sQUEEN memory);

    function GetQueenRarity(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (queeneRarity finalRarity);

    function GetQueenRarityBidIncrement(
        RoyalLibrary.sDNA[] memory _dna,
        uint256[] calldata map
    ) external pure returns (uint256 value);

    function GetQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (string memory rarityName);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.12;

//import {IERC165} from "IERC165.sol";

import {IBaseContractController} from "IBaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";

interface IQueenTraits is IBaseContractController {
    event RarityCreated(
        uint256 indexed rarityId,
        string rarityName,
        uint256 _percentage
    );
    event RarityUpdated(
        uint256 indexed rarityId,
        string rarityName,
        uint256 _percentage
    );

    event TraitCreated(
        uint256 indexed traitId,
        string _traitName,
        uint8 _enabled
    );

    event TraitEnabled(uint256 indexed traitId, string _traitName);
    event TraitDisabled(uint256 indexed traitId, string _traitName);

    event ArtCreated(uint256 traitId, uint256 rarityId, string artUri);
    event ArtRemoved(uint256 traitId, uint256 rarityId, string artUri);
    event ArtPurged(uint256 traitId, uint256 rarityId, string artUri);

    function getRarityById(uint256 _rarityId)
        external
        view
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarityByName(string memory _rarityName)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarities(bool onlyWithArt, uint256 _traitId)
        external
        view
        returns (RoyalLibrary.sRARITY[] memory raritiesList);

    function getTrait(uint256 _id)
        external
        view
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraitByName(string memory _traitName)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraits(bool _onlyEnabled)
        external
        view
        returns (RoyalLibrary.sTRAIT[] memory _traits);

    function GetArtByUri(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function GetArtCount(uint256 _traitId, uint256 _rarityId)
        external
        view
        returns (uint256 quantity);

    function GetArt(
        uint256 _traitId,
        uint256 _rarityId,
        uint256 _artIdx
    ) external view returns (RoyalLibrary.sART memory art);

    function GetArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function GetRemovedArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.12;

import {IQueenTraits} from "IQueenTraits.sol";
import {IQueenLab} from "IQueenLab.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";
import {IBaseContractController} from "IBaseContractController.sol";
import {IERC721} from "IERC721.sol";

interface IQueenE is IBaseContractController, IERC721 {
    function _currentAuctionQueenE() external view returns (uint256);

    function contractURI() external view returns (string memory);

    function mint() external returns (uint256);

    function burn(uint256 queeneId) external;

    function lockMinter() external;

    function lockQueenLab() external;

    function lockQueenTraitStorage() external;

    function getQueenE(uint256 _queeneId)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function nominateSir(address _sir) external returns (bool);

    function getHouseSeats(uint8 _seatType) external view returns (uint256);

    function getHouseSeat(address addr) external view returns (uint256);

    function IsSir(address _address)
        external
        view
        returns (RoyalLibrary.sSIR memory);
}

// SPDX-License-Identifier: MIT
/// @title IERC721 Interface

/************************************************
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 * â–‘â–‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘ *
 *************************************************/

// LICENSE
// IERC721.sol modifies OpenZeppelin's interface IERC721.sol to user our own ERC165 standard:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
//
// MODIFICATIONS:
// Its the latest `IERC721` interface from OpenZeppelin (v4.4.5) using our own ERC165 controller.

pragma solidity ^0.8.12;

import {IBaseContractController} from "IBaseContractController.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IBaseContractController {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.12;

import {IBaseContractControllerUpgradeable} from "IBaseContractControllerUpgradeable.sol";

interface IQueenAuctionHouse is IBaseContractControllerUpgradeable {
    event AuctionStarted(
        uint256 indexed queeneId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed nounId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed queeneId, uint256 endTime);

    event AuctionEnded(
        uint256 indexed queeneId,
        address winner,
        uint256 amount
    );

    event AuctionTimeToleranceUpdated(uint256 timeBuffer);

    event AuctionInitialBidUpdated(uint256 initialBid);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function endAuction() external;

    function restartAuction() external payable;

    function bid(uint256 queeneId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeTolerance(uint256 _timeTolerance) external;

    function setBidRaiseRate(uint8 _bidRaiseRate) external;

    function setInitialBid(uint256 _initialBid) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.12;

interface IBaseContractControllerUpgradeable {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.12;

import {IBaseContractController} from "IBaseContractController.sol";

interface IQueenPalace is IBaseContractController {
    event TreasureDeposit(
        address indexed sender,
        uint256 queeneAuctionId,
        uint256 value
    );

    struct sDEPOSIT {
        uint256 queeneId;
        uint256 blockNumber;
        uint256 blockTimeStamp;
        uint256 value;
    }

    struct sWITHDRAW {
        uint256 blockNumber;
        uint256 blockTimeStamp;
        uint256 value;
        address withdrawer;
        string documentsUri;
    }

    function depositToPalaceTreasure(uint256 _queeneAuctionId) external payable;

    function retrieveAuctionFallbackFunds() external;
}