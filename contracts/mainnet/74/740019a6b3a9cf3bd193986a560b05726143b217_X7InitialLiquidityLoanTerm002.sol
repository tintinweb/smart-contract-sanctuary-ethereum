/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: X7 Initial Liquidity Loan Term (002) - "X7ILL002"

Name: Amortizing Loan with interest
Loan Origination Fee: 10% of borrowed capital (10x leverage)
Loan Retention Premium: 6.25% in premiums due by the end of each quarter of the loan term
Principal Repayment Condition: 25% of borrowed capital due by the end of each quarter of the loan term
Liquidation Conditions: Failure to pay the principal or premium on time will result in full liquidation up to the liability amount

This contract uses an abstract base contract shared among all our standard Initial Liquidity Loan Terms. Although this contract only allows a small number of configuration changes (namely minimum and maximum loan amounts and durations), variations can be deployed and added to the Active Loan terms of the Lending Pool.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setLoanAuthority(address contractAddress, bool isAuthority) external onlyOwner {
        require(loanAuthorities[contractAddress] != isAuthority);
        loanAuthorities[contractAddress] = isAuthority;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(keccak256(abi.encodePacked(internalBaseURI)) != keccak256(abi.encodePacked(baseURI_)));
        string memory oldBaseURI = internalBaseURI;
        internalBaseURI = baseURI_;
        emit BaseURISet(oldBaseURI, baseURI_);
    }

    function setUseBaseURIOnly(bool shouldUse) external onlyOwner {
        require(useBaseURIOnly != shouldUse);
        useBaseURIOnly = shouldUse;
        emit UseBaseURIOnlySet(shouldUse);
    }

    function setLoanLengthLimits(uint256 minimumSeconds, uint256 maximumSeconds) external onlyOwner {
        _setLoanLengthLimits(minimumSeconds, maximumSeconds);
    }

    function setLoanAmountLimits(uint256 minimum, uint256 maximum) external onlyOwner {
        _setLoanAmountLimits(minimum, maximum);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

interface IX7InitialLiquidityLoanTerm {
    enum LiquidationPolicy {
        NONE,
        LIQUIDATE_INCREMENTAL,
        LIQUIDATE_IN_FULL
    }

    enum LoanState {
        ACTIVE,
        COMPLETE
    }

    event BaseURISet(string oldURI, string newURI);
    event UseBaseURIOnlySet(bool shouldUseBaseURIOnly);
    event LoanLengthLimitsSet(uint256 oldMinSeconds, uint256 oldMaxSeconds, uint256 minSeconds, uint256 maxSeconds);
    event LoanAmountLimitsSet(uint256 oldMinAmount, uint256 oldMaxAmount, uint256 minAmount, uint256 maxAmount);
    event LoanAuthoritySet(address contractAddress, bool isAuthority);
    event LoanOriginated(uint256 indexed loanID);
    event LoanComplete(uint256 indexed loanID);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function internalBaseURI() external view returns (string memory);
    function useBaseURIOnly() external view returns (bool);
    function loanAuthorities(address) external view returns (bool);
    function principleFractionDenominator() external view returns (uint16);
    function loanPrecision() external view returns (uint256);
    function repaymentPeriodIndices(uint256) external view returns (uint8);
    function premiumPeriodIndices(uint256) external view returns (uint8);
    function originationFeeNumerator() external view returns (uint16);
    function minimumLoanAmount() external view returns (uint256);
    function maximumLoanAmount() external view returns (uint256);
    function minimumLoanLengthSeconds() external view returns (uint256);
    function maximumLoanLengthSeconds() external view returns (uint256);
    function repaymentFractions(uint8 period) external view returns (uint16);
    function premiumFractions(uint8 period) external view returns (uint16);
    function liquidationPolicy() external view returns (LiquidationPolicy);
    function loanAmount(uint256 loanID) external view returns (uint256);
    function premiumAmountPaid(uint256 loanID) external view returns (uint256);
    function principalAmountPaid(uint256 loanID) external view returns (uint256);
    function premiumAmount(uint256 loanID) external view returns (uint256);
    function premiumModifierNumerator(uint256 loanID) external view returns (uint256);
    function originationFeeModifierNumerator(uint256 loanID) external view returns (uint256);
    function originationFeeCollected(uint256 loanID) external view returns (uint256);
    function loanLengthSeconds(uint256 loanID) external view returns (uint256);
    function loanStartTime(uint256 loanID) external view returns (uint256);
    function loanState(uint256 loanID) external view returns (LoanState);
    function numberOfRepaymentPeriods() external view returns (uint256);
    function numberOfPremiumPeriods() external view returns (uint256);
    function getOriginationAmounts(uint256 loanAmount_) external view returns (uint256 loanAmountRounded, uint256 originationFee);
    function isComplete(uint256 loanID) external view returns (bool);
    function liquidationAmount(uint256 loanID) external view returns (uint256);
    function getQuote(uint256 loanAmount_) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium);
    function getDiscountedQuote(uint256 loanAmount_, uint256 premiumFeeModifier, uint256 originationFeeModifier) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium);
    function getPrincipalDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getPremiumsDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getTotalDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getRemainingLiability(uint256 loanID) external view returns (uint256);
    function getPremiumPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory);
    function getPrincipalPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setLoanAuthority(address contractAddress, bool isAuthority) external;
    function setBaseURI(string memory baseURI_) external;
    function setUseBaseURIOnly(bool shouldUse) external;
    function originateLoan(
        uint256 loanAmount_,
        uint256 originationFee,
        uint256 loanLengthSeconds_,
        uint256 premiumFeeModifierNumerator_,
        uint256 originationFeeModifierNumerator_,
        address receiver,
        uint256 tokenId
    ) external returns (uint256);
    function recordPayment(uint256 loanID, uint256 amount) external returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability);
    function recordPrincipalRepayment(uint256 loanID, uint256 amount) external returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

abstract contract X7InitialLiquidityLoanTerm is ERC721Enumerable, ERC721Holder, Ownable {

    enum LiquidationPolicy {
        NONE,
        LIQUIDATE_INCREMENTAL,
        LIQUIDATE_IN_FULL
    }

    enum LoanState {
        ACTIVE,
        COMPLETE
    }

    struct LoanQuote {
        uint256 loanAmount;
        uint256 originationFee;
        uint256 totalPremiumFee;
    }

    string public internalBaseURI;
    bool public useBaseURIOnly;

    mapping(address => bool) public loanAuthorities;
    uint16 public principleFractionDenominator = 10000;
    uint256 public loanPrecision = 1 gwei;

    uint8[] public repaymentPeriodIndices;
    uint8[] public premiumPeriodIndices;

    uint16 public originationFeeNumerator;

    // Minimum and Maximum Loan Amounts in WEI
    uint256 public minimumLoanAmount;
    uint256 public maximumLoanAmount;

    uint256 public minimumLoanLengthSeconds;
    uint256 public maximumLoanLengthSeconds;

    // Period (1-60) => fraction of principle that must be paid.
    // values in this mapping MUST equal 10,000
    // For example, if 10% must be paid on the half way through, and then the remainder at the end, the expected values would be:
    //      repaymentFractions[30] = 1000;
    //      repaymentFractions[60] = 9000;
    mapping(uint8 => uint16) public repaymentFractions;

    // Period (1-60) => fraction of principle that must be paid on or before that period.
    mapping(uint8 => uint16) public premiumFractions;

    LiquidationPolicy liquidationPolicy;

    // tokenID => loanAmount
    mapping(uint256 => uint256) public loanAmount;
    mapping(uint256 => uint256) public premiumAmountPaid;
    mapping(uint256 => uint256) public principalAmountPaid;
    mapping(uint256 => uint256) public premiumAmount;
    mapping(uint256 => uint256) public premiumModifierNumerator;
    mapping(uint256 => uint256) public originationFeeModifierNumerator;
    mapping(uint256 => uint256) public originationFeeCollected;
    mapping(uint256 => uint256) public loanLengthSeconds;
    mapping(uint256 => uint256) public loanStartTime;
    mapping(uint256 => LoanState) public loanState;

    event BaseURISet(string oldURI, string newURI);
    event UseBaseURIOnlySet(bool shouldUseBaseURIOnly);
    event LoanLengthLimitsSet(uint256 oldMinSeconds, uint256 oldMaxSeconds, uint256 minSeconds, uint256 maxSeconds);
    event LoanAmountLimitsSet(uint256 oldMinAmount, uint256 oldMaxAmount, uint256 minAmount, uint256 maxAmount);
    event LoanAuthoritySet(address contractAddress, bool isAuthority);

    event LoanOriginated(uint256 indexed loanID);
    event LoanComplete(uint256 indexed loanID);

    modifier onlyLoanAuthority {
        require(loanAuthorities[msg.sender], 'X7: FORBIDDEN');
        _;
    }

    function setLoanAuthority(address contractAddress, bool isAuthority) external onlyOwner {
        require(loanAuthorities[contractAddress] != isAuthority);
        loanAuthorities[contractAddress] = isAuthority;
        emit LoanAuthoritySet(contractAddress, isAuthority);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(keccak256(abi.encodePacked(internalBaseURI)) != keccak256(abi.encodePacked(baseURI_)));
        string memory oldBaseURI = internalBaseURI;
        internalBaseURI = baseURI_;
        emit BaseURISet(oldBaseURI, baseURI_);
    }

    function setUseBaseURIOnly(bool shouldUse) external onlyOwner {
        require(useBaseURIOnly != shouldUse);
        useBaseURIOnly = shouldUse;
        emit UseBaseURIOnlySet(shouldUse);
    }

    function numberOfRepaymentPeriods() external view returns (uint256) {
        return repaymentPeriodIndices.length;
    }

    function numberOfPremiumPeriods() external view returns (uint256) {
        return premiumPeriodIndices.length;
    }

    function getOriginationAmounts(uint256 loanAmount_) external view returns (uint256 loanAmountRounded, uint256 originationFee) {
        (loanAmountRounded, originationFee) = _getOriginationAmounts(loanAmount_);
    }

    function isComplete(uint256 loanID) external view returns (bool) {
        return loanState[loanID] == LoanState.COMPLETE;
    }

    function liquidationAmount(uint256 loanID) external view returns (uint256) {
        require(loanState[loanID] == LoanState.ACTIVE);
        uint256 premiumsDue = _getPremiumsDue(loanID, block.timestamp);
        uint256 principalDue = _getPrincipalDue(loanID, block.timestamp);

        uint256 totalDue = premiumsDue + principalDue;

        if (totalDue == 0) {
            return 0;
        }

        uint256 remainingInitialCapital = loanAmount[loanID] - principalAmountPaid[loanID];

        if (
            liquidationPolicy == LiquidationPolicy.LIQUIDATE_INCREMENTAL
        ) {
            if (totalDue >= remainingInitialCapital) {
                return remainingInitialCapital;
            } else {
                return totalDue;
            }
        } else if (liquidationPolicy == LiquidationPolicy.LIQUIDATE_IN_FULL) {
            return remainingInitialCapital;
        } else {
            revert("Invalid repayment policy");
        }
    }

    function getQuote(uint256 loanAmount_) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium) {
        (loanAmountRounded, originationFee) = _getOriginationAmounts(loanAmount_);

        // Provide a non discounted quote
        totalPremium = _getTotalPremium(loanAmount_, principleFractionDenominator);

        return (loanAmountRounded, originationFee, totalPremium);
    }

    function getDiscountedQuote(uint256 loanAmount_, uint256 premiumFeeModifier, uint256 originationFeeModifier) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium) {
        (loanAmountRounded, originationFee) = _getOriginationAmounts(loanAmount_);

        // Modify origination fee to include a rounded discount
        originationFee = originationFee * originationFeeModifier / principleFractionDenominator / loanPrecision * loanPrecision;

        // Provide a discounted quote
        totalPremium = _getTotalPremium(loanAmount_, premiumFeeModifier);

        return (loanAmountRounded, originationFee, totalPremium);
    }

    function getPrincipalDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        require(loanAmount[loanID] > 0);
        return _getPrincipalDue(loanID, asOf);
    }

    function getPremiumsDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        require(loanAmount[loanID] > 0);
        return _getPremiumsDue(loanID, asOf);
    }

    function getTotalDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        require(loanAmount[loanID] > 0);
        return _getPrincipalDue(loanID, asOf) + _getPremiumsDue(loanID, asOf);
    }

    function getRemainingLiability(uint256 loanID) external view returns (uint256) {
        require(loanAmount[loanID] > 0);

        return premiumAmount[loanID] - premiumAmountPaid[loanID] + loanAmount[loanID] - principalAmountPaid[loanID];
    }

    function getPremiumPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory) {
        uint256 startTime = loanStartTime[loanID];
        uint256 durationSeconds = loanLengthSeconds[loanID];
        uint256 loanAmount_ = loanAmount[loanID];

        require(loanAmount_ > 0);

        uint256[] memory dueDates = new uint256[](premiumPeriodIndices.length);
        uint256[] memory paymentAmounts = new uint256[](premiumPeriodIndices.length);

        for (uint i=0; i < premiumPeriodIndices.length; i++) {
            dueDates[i] = (durationSeconds * premiumPeriodIndices[i] / 60) + startTime;
            paymentAmounts[i] = (loanAmount_ * premiumFractions[premiumPeriodIndices[i]] / principleFractionDenominator) / loanPrecision * loanPrecision;
        }

        return (dueDates, paymentAmounts);
    }

    function getPrincipalPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory) {
        uint256 startTime = loanStartTime[loanID];
        uint256 durationSeconds = loanLengthSeconds[loanID];
        uint256 loanAmount_ = loanAmount[loanID];

        require(loanAmount_ > 0);

        uint256[] memory dueDates = new uint256[](repaymentPeriodIndices.length);
        uint256[] memory paymentAmounts = new uint256[](repaymentPeriodIndices.length);

        for (uint i=0; i < repaymentPeriodIndices.length; i++) {
            dueDates[i] = (durationSeconds * repaymentPeriodIndices[i] / 60) + startTime;
            paymentAmounts[i] = (loanAmount_ * repaymentFractions[repaymentPeriodIndices[i]] / principleFractionDenominator) / loanPrecision * loanPrecision;
        }

        return (dueDates, paymentAmounts);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useBaseURIOnly) {
            return _baseURI();
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function originateLoan(
        uint256 loanAmount_,
        uint256 originationFee,
        uint256 loanLengthSeconds_,

        // 10000 == no discount 9000 == 10% discount
        uint256 premiumFeeModifierNumerator_,
        uint256 originationFeeModifierNumerator_,

        address receiver,
        uint256 tokenId
    ) external onlyLoanAuthority returns (uint256) {
        (uint256 expectedLoanAmount, uint256 expectedOriginationFee) = _getOriginationAmounts(loanAmount_);
        uint256 discountedOriginationFee = expectedOriginationFee * originationFeeModifierNumerator_ / principleFractionDenominator / loanPrecision * loanPrecision;

        // Check the loan conforms to the loan terms of this contract
        require(expectedLoanAmount == loanAmount_, "Loan amounts must be rounded");
        require(loanAmount_ >= minimumLoanAmount && loanAmount_ <= maximumLoanAmount, "Invalid loan Amount");
        require(loanLengthSeconds_ >= minimumLoanLengthSeconds && loanLengthSeconds_ <= maximumLoanLengthSeconds, "Invalid loan length");
        require(originationFee == discountedOriginationFee, "Insufficient origination fee collected");

        loanAmount[tokenId] = loanAmount_;
        originationFeeCollected[tokenId] = originationFee;
        premiumModifierNumerator[tokenId] = premiumFeeModifierNumerator_;
        originationFeeModifierNumerator[tokenId] = originationFeeModifierNumerator_;
        premiumAmount[tokenId] = _getTotalPremium(loanAmount_, premiumFeeModifierNumerator_);

        loanLengthSeconds[tokenId] = loanLengthSeconds_;
        loanState[tokenId] = LoanState.ACTIVE;

        loanStartTime[tokenId] = block.timestamp;

        _mint(receiver, tokenId);

        emit LoanOriginated(tokenId);

        return tokenId;
    }

    /*
        Payments are applied in the following manner:

            1. Premium Due (based on time)
            2. Principal Due (based on time)
            3. Premium Due (total)
            4. Principal Due (total)
    */
    function recordPayment(uint256 loanID, uint256 amount) external onlyLoanAuthority returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability) {
        if (loanState[loanID] == LoanState.COMPLETE) {
            refundAmount = amount;
            return (premiumPaid, principalPaid, refundAmount, remainingLiability);
        }

        uint256 premiumDue = _getPremiumsDue(loanID, block.timestamp);
        uint256 principalDue = _getPrincipalDue(loanID, block.timestamp);

        uint256 remaining = amount;

        if (premiumDue > 0) {
            if (remaining >= premiumDue) {
                remaining -= premiumDue;
                premiumPaid = premiumDue;
            } else {
                premiumPaid = amount;
                remaining = 0;
            }
        }

        if (principalDue > 0 && remaining > 0) {
            if (remaining >= principalDue) {
                principalPaid = principalDue;
                remaining -= principalDue;
            } else {
                principalPaid = remaining;
                remaining = 0;
            }
        }

        uint256 excessAmount = _recordPremiumPayment(loanID, premiumPaid + remaining);
        premiumPaid = premiumPaid + remaining - excessAmount;

        refundAmount = _recordPrincipalPayment(loanID, principalPaid + excessAmount);
        principalPaid = principalPaid + excessAmount - refundAmount;

        remainingLiability = premiumAmount[loanID] - premiumAmountPaid[loanID] + loanAmount[loanID] - principalAmountPaid[loanID];

        if (remainingLiability == 0) {
            loanState[loanID] = LoanState.COMPLETE;
            emit LoanComplete(loanID);
        }
    }

    function recordPrincipalRepayment(uint256 loanID, uint256 amount) external onlyLoanAuthority returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability) {
        uint256 excessAmount = _recordPrincipalPayment(loanID, amount);

        if (excessAmount > 0) {
            refundAmount = _recordPremiumPayment(loanID, excessAmount);
        }
        principalPaid = amount - excessAmount;
        premiumPaid = excessAmount - refundAmount;

        remainingLiability = premiumAmount[loanID] - premiumAmountPaid[loanID] + loanAmount[loanID] - principalAmountPaid[loanID];

        if (remainingLiability == 0) {
            loanState[loanID] = LoanState.COMPLETE;
            emit LoanComplete(loanID);
        }
    }

    function _getOriginationAmounts(uint256 loanAmount_) internal view returns (uint256 loanAmountRounded, uint256 originationFee) {
        for (uint i=0; i < repaymentPeriodIndices.length; i++) {
            loanAmountRounded += (loanAmount_ * repaymentFractions[repaymentPeriodIndices[i]] / principleFractionDenominator) / loanPrecision * loanPrecision;
        }

        require(loanAmountRounded > 0);

        originationFee = (loanAmountRounded * originationFeeNumerator / principleFractionDenominator) / loanPrecision * loanPrecision;
    }

    function _getTotalPremium(uint256 loanAmount_, uint256 discountModifier) internal view returns (uint256) {
        uint256 totalPremium;

        for (uint i=0; i < premiumPeriodIndices.length; i++) {
            totalPremium += (loanAmount_ * premiumFractions[premiumPeriodIndices[i]] / principleFractionDenominator) * discountModifier / principleFractionDenominator / loanPrecision * loanPrecision;
        }

        return totalPremium;
    }

    function _getPrincipalDue(uint256 loanID, uint256 asOf) internal view returns (uint256) {
        uint256 startTime = loanStartTime[loanID];
        uint256 durationSeconds = loanLengthSeconds[loanID];
        uint256 loanAmount_ = loanAmount[loanID];

        uint256 totalRepaymentDue;

        for (uint i=0; i < repaymentPeriodIndices.length; i++) {
            if (
                (durationSeconds * repaymentPeriodIndices[i] / 60) + startTime > asOf
            ) {
                break;
            }

            totalRepaymentDue += (loanAmount_ * repaymentFractions[repaymentPeriodIndices[i]] / principleFractionDenominator) / loanPrecision * loanPrecision;
        }

        if (principalAmountPaid[loanID] >= totalRepaymentDue) {
            return 0;
        } else {
            return totalRepaymentDue - principalAmountPaid[loanID];
        }
    }

    function _getPremiumsDue(uint256 loanID, uint256 asOf) internal view returns (uint256) {
        uint256 startTime = loanStartTime[loanID];
        uint256 durationSeconds = loanLengthSeconds[loanID];
        uint256 loanAmount_ = loanAmount[loanID];

        uint256 totalPremiumsDue;

        for (uint i=0; i < premiumPeriodIndices.length; i++) {
            if (
                (durationSeconds * premiumPeriodIndices[i] / 60) + startTime > asOf
            ) {
                break;
            }

            totalPremiumsDue += (loanAmount_ * premiumFractions[premiumPeriodIndices[i]] / principleFractionDenominator) * premiumModifierNumerator[loanID] / principleFractionDenominator / loanPrecision * loanPrecision;
        }

        if (premiumAmountPaid[loanID] >= totalPremiumsDue) {
            return 0;
        } else {
            return totalPremiumsDue - premiumAmountPaid[loanID];
        }
    }

    function _recordPremiumPayment(uint256 loanID, uint256 amount) internal returns (uint256 refundAmount) {
        if (amount == 0) {
            return 0;
        }
        uint256 owedAmount = premiumAmount[loanID] - premiumAmountPaid[loanID];

        if (owedAmount > 0) {
            if (owedAmount <= amount) {
                premiumAmountPaid[loanID] += owedAmount;
                refundAmount = amount - owedAmount;
            } else {
                premiumAmountPaid[loanID] += amount;
            }
        } else {
            refundAmount = amount;
        }
    }

    function _recordPrincipalPayment(uint256 loanID, uint256 amount) internal returns (uint256 refundAmount) {
        if (amount == 0) {
            return 0;
        }

        uint256 owedAmount = loanAmount[loanID] - principalAmountPaid[loanID];

        if (owedAmount > 0) {
            if (owedAmount <= amount) {
                principalAmountPaid[loanID] += owedAmount;
                refundAmount = amount - owedAmount;
            } else {
                principalAmountPaid[loanID] += amount;
            }
        } else {
            refundAmount = amount;
        }

    }

    function _setRepaymentTerms(uint16[60] memory fractions) internal {
        uint256 totalFraction;
        uint8 period;
        uint16 fraction;

        for (uint8 i=0; i < fractions.length; i++) {
            if (fractions[i] == 0) {
                continue;
            }

            period = i+1;
            fraction = fractions[i];
            require(period > 0 && period <= 60);

            totalFraction += fraction;
            repaymentFractions[period] = fraction;
            repaymentPeriodIndices.push(period);
        }

        require(totalFraction == principleFractionDenominator);
    }

    function _setPremiumTerms(uint16[60] memory fractions) internal {
        uint256 totalFraction;
        uint8 period;
        uint16 fraction;

        for (uint8 i=0; i < fractions.length; i++) {
            if (fractions[i] == 0) {
                continue;
            }
            period = i +1;
            fraction = fractions[i];
            require(period > 0 && period <= 60);

            totalFraction += fraction;
            premiumFractions[period] = fraction;
            premiumPeriodIndices.push(period);
        }
    }

    function _setOriginationFeeNumerator(uint16 feeNumerator) internal {
        require(feeNumerator < principleFractionDenominator);
        originationFeeNumerator = feeNumerator;
    }

    function _setLoanAmountLimits(uint256 minimumAmount, uint256 maximumAmount) internal {
        require(minimumAmount < maximumAmount);
        require(minimumAmount != minimumLoanAmount || maximumAmount != maximumLoanAmount);
        uint256 oldMinimumAmount = minimumLoanAmount;
        uint256 oldMaxiimumAmount = maximumLoanAmount;
        minimumLoanAmount = (minimumAmount / loanPrecision) * loanPrecision;
        maximumLoanAmount = (maximumAmount / loanPrecision) * loanPrecision;

        emit LoanAmountLimitsSet(oldMinimumAmount, oldMaxiimumAmount, minimumAmount, maximumAmount);
    }

    function _setLiquidationPolicy(LiquidationPolicy liquidationPolicy_) internal {
        require(liquidationPolicy_ != LiquidationPolicy.NONE);
        liquidationPolicy = liquidationPolicy_;
    }

    function _setLoanLengthLimits(uint256 minimumSeconds, uint256 maximumSeconds) internal {
        require(minimumSeconds <= maximumSeconds);
        require(minimumSeconds != minimumLoanLengthSeconds || maximumSeconds != maximumLoanLengthSeconds);
        uint256 oldMinimumSeconds = minimumLoanLengthSeconds;
        uint256 oldMaximumSeconds = maximumLoanLengthSeconds;
        minimumLoanLengthSeconds = minimumSeconds;
        maximumLoanLengthSeconds = maximumSeconds;

        emit LoanLengthLimitsSet(oldMinimumSeconds, oldMaximumSeconds, minimumSeconds, maximumSeconds);
    }

    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}

contract X7InitialLiquidityLoanTerm002 is X7InitialLiquidityLoanTerm {
    constructor () Ownable(msg.sender) ERC721("X7 Initial Liquidity Loan Term (002)", "X7ILL002") {
        _setLiquidationPolicy(
            LiquidationPolicy.LIQUIDATE_IN_FULL
        );

        // This can be changed post deploy
        _setLoanAmountLimits(
            // 0.5 ETH
            1 ether * 5 / 10,
            5 ether
        );

        // This can be changed post deploy
        _setLoanLengthLimits(
            // 1 day
            24 * 60 * 60,

            // 7 days
            7 * 24 * 60 * 60
        );

        _setOriginationFeeNumerator(
            // 10% loan origination fee
            1000
        );

        // 6.25% due in premiums by end of each quarter of loan term
        uint16[60] memory premiumPeriodFraction;
        premiumPeriodFraction[14] = 625;
        premiumPeriodFraction[29] = 625;
        premiumPeriodFraction[44] = 625;
        premiumPeriodFraction[59] = 625;

         _setPremiumTerms(
             premiumPeriodFraction
         );

        // 25% of principal due by end of each quarter of loan term
        uint16[60] memory repaymentPeriodFraction;
        repaymentPeriodFraction[14] = 2500;
        repaymentPeriodFraction[29] = 2500;
        repaymentPeriodFraction[44] = 2500;
        repaymentPeriodFraction[59] = 2500;

        _setRepaymentTerms(
            repaymentPeriodFraction
        );
    }

    function setLoanLengthLimits(uint256 minimumSeconds, uint256 maximumSeconds) external onlyOwner {
        _setLoanLengthLimits(minimumSeconds, maximumSeconds);
    }

    function setLoanAmountLimits(uint256 minimum, uint256 maximum) external onlyOwner {
        _setLoanAmountLimits(minimum, maximum);
    }
}