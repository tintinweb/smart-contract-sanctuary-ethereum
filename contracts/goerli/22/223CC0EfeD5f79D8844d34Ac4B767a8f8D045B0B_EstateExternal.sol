// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IManagement.sol";
import "./utils/EstateBenefit.sol";
import "./interfaces/IEstate.sol";

contract EstateExternal is Context, EstateBenefit {
    struct License {
        string LLCRegId;
        string BVIFundId;
    }

    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    //  Address of Estate contract
    IEstate private _estate;

    //  Time that one item, in `claimed` status, must be locked after transferring ownership
    uint256 private _pendingTime;

    //  Max supply per Id of Real Estate Tier
    mapping(uint256 => uint256) private _maxSupplies;

    //  a mapping of License per `houseId`
    mapping(uint256 => License) private _licenses;

    //  a mapping of Tokenized Real Estate have been claimed
    mapping(uint256 => bool) private _claimed;

    constructor(
        IManagement _management,
        IEstate estate_
    ) EstateBenefit(_management) {
        _estate = estate_;
    }

    /**
       	@notice Get linked Estate contract
       	@dev  Caller can be ANY
    */
    function estate() public view returns (IEstate) {
        return _estate;
    }

    /**
       	@notice Checking whether `_tokenId` has been claimed
       	@dev  Caller can be ANY
    */
    function claimed(uint256 _tokenId) public view returns (bool) {
        return _claimed[_tokenId];
    }

    /**
       	@notice Get current setting of `pendingTime`
       	@dev  Caller can be ANY
    */
    function pendingTime() external view returns (uint256) {
        return _pendingTime;
    }

    /**
       	@notice Get max supply of one `_tierId`
       	@dev  Caller can be ANY
		@param	_tierId				Id of Real Estate Tier
    */
    function maxSupplyOf(uint256 _tierId) public view returns (uint256) {
        return _maxSupplies[_tierId];
    }

    /**
       	@notice Get the license of `_houseId`
       	@dev  Caller can be ANY
        @param	_houseId				House Id
    */
    function licenseOf(
        uint256 _houseId
    ) external view returns (string memory _llc, string memory _bvi) {
        _llc = _licenses[_houseId].LLCRegId;
        _bvi = _licenses[_houseId].BVIFundId;
    }

    /**
       	@notice Get benefit sharing info of `_tokenId`
       	@dev  Caller can be ANY
        @param	_tokenId				    Token Id of Tokenized Real Estate
        @param	_totalShare				    Total amount will be shared
    */
    function benefitInfo(
        uint256 _tokenId,
        uint256 _totalShare
    ) public view override returns (address, uint256) {
        require(estate().exists(_tokenId), "TokenId not exist");
        return super.benefitInfo(_tokenId, _totalShare);
    }

    /**
       	@notice Owner of `_tokenId` call to change state from `unclaim` -> `claimed`
       	@dev  Caller can be ANY

        Note: OPERATOR_ROLE is granted a privilege to claim on owner's behalf
    */
    function claim(uint256 _tokenId) external {
        address _caller = _msgSender();
        require(
            estate().ownerOf(_tokenId) == _caller || management().hasRole(OPERATOR_ROLE, _caller),
            "TokenId not owned or nor authorized"
        );
        require(!claimed(_tokenId), "TokenId already claimed");
        estate().setLastUpdate(_tokenId);
        _claimed[_tokenId] = true;
    }

    /**
       	@notice Update new `_pendingTime`
       	@dev  Caller must have MANAGER_ROLE
		@param	_time				New value of pending time
    */
    function setPendingTime(uint256 _time) external hasRole(MANAGER_ROLE) {
        _pendingTime = _time;
    }

    /**
       	@notice Set max supply per `_tierId`
       	@dev  Caller must have MANAGER_ROLE
		@param	_tierId				    Id of Real Estate Tier
        @param	_maxSupply				Max supply of this `_tierId`
    */
    function setMaxSupplyPerTier(
        uint256 _tierId,
        uint256 _maxSupply
    ) external hasRole(MANAGER_ROLE) {
        require(maxSupplyOf(_tierId) == 0, "TierId has been set");
        _maxSupplies[_tierId] = _maxSupply;
    }

    /**
       	@notice Set License of `houseId`
       	@dev  Caller must have MANAGER_ROLE
        @param	_houseId				House Id
    */
    function setLicense(
        uint256 _houseId,
        string calldata _LLCRegId,
        string calldata _BVIFundId
    ) external hasRole(MANAGER_ROLE) {
        _licenses[_houseId].LLCRegId = _LLCRegId;
        _licenses[_houseId].BVIFundId = _BVIFundId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IERC2981.sol";
import "../utils/Util.sol";

/**
 * @dev Implementation of the Tokenized Real Estate's benefit sharing based on NFT Royalty Standard,
 * a standardized way to retrieve benefit sharing information.
 * BenefitV2 has changed some logic in comparison to `Benefit.sol`
 *
 * Benefit sharing information can be specified globally for all token ids of one `_type` via {_setDefaultBenefit}, and/or individually for
 * specific token ids via {_setTokenBenefit}. The latter takes precedence over the first.
 *
 * Benefit sharing is specified as a fraction of the total benefit. {_benefitDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract Benefit is IERC2981, ERC165 {
    struct BenefitInfo {
        address receiver;
        uint96 sharingFraction;
    }

    mapping(uint256 => BenefitInfo) private _benefitInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function benefitInfo(
        uint256 tokenId,
        uint256 totalShare
    ) public view virtual override returns (address, uint256) {
        BenefitInfo memory benefit = _benefitInfo[tokenId];

        if (benefit.receiver == address(0)) {
            (uint256 tier, , ) = Util._decompose(tokenId);
            benefit = _benefitInfo[tier];
        }

        uint256 benefitAmount = (totalShare * benefit.sharingFraction) /
            _benefitDenominator();

        return (benefit.receiver, benefitAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenBenefit} and {_setDefaultBenefit} as a
     * fraction of the total benefit. Defaults to 100,000,000 so sharing amounts are expressed in basis points, but may be customized by an
     * override.
     */
    function _benefitDenominator() internal pure virtual returns (uint96) {
        return 10 ** 8;
    }

    /**
     * @dev Sets the global benefit information that all ids of one `benefitType` in this contract will default to.
     * Note:
     * There is a convention when tokenId is assigned to Tokenized Real Estate
     * TokenId = `type` + `fragmentNo`
     * Example: tokenId = 17_001234 -> type = 17, and fragmentNo = 1234
     * Thus, the default benefit and token benefit can use one mapping `_benefitInfo`
     *
     * Requirements:
     *
     * - `benefitType` must be distinctive
     * - `receiver` cannot be the zero address.
     * - `benefitNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultBenefit(
        uint256 benefitType,
        address receiver,
        uint96 benefitNumerator
    ) internal virtual {
        require(
            benefitNumerator <= _benefitDenominator(),
            "ERC2981: sharing amount will exceed the total share"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _benefitInfo[benefitType] = BenefitInfo(receiver, benefitNumerator);
    }

    /**
     * @dev Removes default benefit information of one `benefitType`.
     */
    function _deleteDefaultBenefit(uint256 benefitType) internal virtual {
        delete _benefitInfo[benefitType];
    }

    /**
     * @dev Sets the benefit information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `benefitNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenBenefit(
        uint256 tokenId,
        address receiver,
        uint96 benefitNumerator
    ) internal virtual {
        require(
            benefitNumerator <= _benefitDenominator(),
            "ERC2981: sharing amount will exceed the total share"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _benefitInfo[tokenId] = BenefitInfo(receiver, benefitNumerator);
    }

    /**
     * @dev Resets benefit information for the token id back to the global default.
     */
    function _resetTokenBenefit(uint256 tokenId) internal virtual {
        delete _benefitInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for Tokenized Real Estate Benefit sharing based on the NFT Royalty Standard.
 * Logic remains unchanged but description and context have been changed accordingly
 *
 * A standardized way to retrieve benefit sharing information for Tokenized Real Estate as NFT to enable universal
 * support for benefit sharing payments.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much benefit is owed and to whom, based on the total share that may be denominated in any unit of
     * payment token. The benefit amount is denominated and should be paid in that same unit of payment token.
     */
    function benefitInfo(
        uint256 tokenId,
        uint256 totalShare
    ) external view returns (address receiver, uint256 benefitAmount);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IEstate is IERC721Enumerable {
    /**
       	@notice Get current `_nonce` that binds to `_tokenId` and `_account`
       	@dev  Caller can be ANY
        @param	_tokenId				Token Id of Tokenized Real Estate
        @param	_tokenId				Account address
    */
    function nonces(
        uint256 _tokenId,
        address _account
    ) external view returns (uint256 _nonce);

    /**
       	@notice Check whether `_tokenId` has already minted
       	@dev  Caller can be ANY
        @param	_tokenId				Token Id of Tokenized Real Estate
    */
    function exists(uint256 _tokenId) external view returns (bool);

    /**
       	@notice Get last time that `_tokenId` has been transferred (mint, burn, transfer, or claim)
       	@dev  Caller can be ANY
        @param	_tokenId				Token Id of Tokenized Real Estate
    */
    function lastUpdate(uint256 _tokenId) external view returns (uint256);

    /**
       	@notice Get the license of `_tokenId`
       	@dev  Caller can be ANY
        @param	_tokenId				Token Id of Tokenized Real Estate
    */
    function licenseOf(
        uint256 _tokenId
    ) external view returns (string memory _llc, string memory _bvi);

    /**
       	@notice Get total number of Owners that currently own Tokenized Real Estate in this contract
       	@dev  Caller can be ANY
    */
    function numOfEstateOwners() external view returns (uint256);

    /**
       	@notice Get a list of Owners that currently own Tokenized Real Estate in this contract
       	@dev  Caller can be ANY
        @param	_fromIdx				Starting index in the list
        @param	_toIdx				    Ending index in the list
    */
    function estateOwners(
        uint256 _fromIdx,
        uint256 _toIdx
    ) external view returns (address[] memory _list);

    /**
       	@notice Get total supply of one `_houseId` and its `_tierId`
       	@dev  Caller can be ANY
        @param	_tierId				    Id of Real Estate Tier
		@param	_houseId				House ID
    */
    function totalSupplyOf(
        uint256 _tierId,
        uint256 _houseId
    ) external view returns (uint256);

    /**
       	@notice Get `baseURI` has been set for `_houseId` and its `_tierId`
       	@dev  Caller can be ANY
        @param	_houseId				House Id
		@param	_tierId				    Id of Real Estate Tier
    */
    function baseURI(
        uint256 _houseId,
        uint256 _tierId
    ) external view returns (string memory);

    /**
       	@notice Get `tokenURI` of `_tokenId`
       	@dev  Caller can be ANY
		@param	_tokenId				Number ID of Tokenized Real Estate
    */
    function tokenURI(
        uint256 _tokenId
    ) external view returns (string memory _uri);

    /**
       	@notice Extract `_tierId` and `_houseId` of Tokenized Real Estate from `_tokenId`
       	@dev  Caller can be ANY
		@param	_tokenId				Number ID of Tokenized Real Estate
    */
    function decompose(
        uint256 _tokenId
    ) external view returns (uint256 _tierId, uint256 _houseId);

    /**
       	@notice Adjust `_lastUpdate` of `_tokenId`
       	@dev  Caller must be EstateExternal contract
		@param	_tokenId		        Number ID of Tokenized Real Estate

        Note: when `_tokenId` is claimed (change status from `unclaim` -> `claimed`)
        `_lastUpdate` will also be adjusted. The `claim()` method is available in EstateExternal contract
    */
    function setLastUpdate(uint256 _tokenId) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IManagement contract
   @dev Provide interfaces that allow interaction to Management contract
*/
interface IManagement {
    function treasury() external view returns (address);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function paused() external view returns (bool);

    function mode() external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IManagement.sol";
import "../external/Benefit.sol";

contract EstateBenefit is Context, Benefit {
    using Address for address;

    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    //  Address of Management contract
    IManagement private _management;

    modifier hasRole(bytes32 _role) {
        require(management().hasRole(_role, _msgSender()), "Unauthorized");
        _;
    }

    constructor(IManagement management_) {
        _management = management_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(Benefit) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
       	@notice Get address of current Management contract
       	@dev  Caller can be ANY
    */
    function management() public view returns (IManagement) {
        return _management;
    }

    /**
       	@notice Update Address of Management contract
       	@dev  Caller must have MANAGER_ROLE
		@param	management_				Address of Management contract
    */
    function setManagement(address management_) external hasRole(MANAGER_ROLE) {
        require(management_.isContract(), "Must be a contract");
        _management = IManagement(management_);
    }

    /**
       	@notice Update Global Benefit of one `_tierId`
       	@dev  Caller must have MANAGER_ROLE
        @param	_tierId				        Id of Real Estate Tier
       	@param 	_receiver					Address that receives Global Benefit
		@param 	_benefitNumerator			Benefit's fraction (with benefitDenom = 100,000,000)

		Note: 
			- Global Benefit will be applied to all `_tokenIds` of one `_tierId` in this contract
			- If Token Benefit (for a specific `_tokenId`) is set, it overrides a global one
    */
    function setGlobalBenefit(
        uint256 _tierId,
        address _receiver,
        uint96 _benefitNumerator
    ) external hasRole(MANAGER_ROLE) {
        _setDefaultBenefit(_tierId, _receiver, _benefitNumerator);
    }

    /**
       	@notice Remove Global Benefit
       	@dev  Caller must have MANAGER_ROLE
        @param	_tierId				    Id of Real Estate Tier

		Note: If Token Benefit (for a specific `_tokenId`) is set, 
			removing a global benefit does not change a setting on Token Benefit
    */
    function removeGlobalBenefit(
        uint256 _tierId
    ) external hasRole(MANAGER_ROLE) {
        _deleteDefaultBenefit(_tierId);
    }

    /**
       	@notice Update Token Benefit of a `_tokenId`
       	@dev  Caller must have MANAGER_ROLE
		@param 	_tokenId					TokenId that Token Benefit will be applied
       	@param 	_receiver					Address that receives Token Benefit
		@param 	_benefitNumerator			Token Benefit's fraction (with sharingDenom = 100,000,000)

		Note: 
			- If Token Benefit is set, it overrides the Global Benefit regardless of setting orders
    */
    function setTokenBenefit(
        uint256 _tokenId,
        address _receiver,
        uint96 _benefitNumerator
    ) external hasRole(MANAGER_ROLE) {
        _setTokenBenefit(_tokenId, _receiver, _benefitNumerator);
    }

    /**
       	@notice Remove Token Benefit of a `_tokenId`
       	@dev  Caller must have MANAGER_ROLE

		Note: After removing Token Benefit, Global Benefit (for this `_tokenId`) will be counted if set
    */
    function removeTokenBenefit(
        uint256 _tokenId
    ) external hasRole(MANAGER_ROLE) {
        _resetTokenBenefit(_tokenId);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

library Util {
    uint256 private constant MASK = 10 ** 10;
    uint256 private constant SUB_MASK = 10 ** 5;

    function _decompose(
        uint256 _tokenId
    )
        internal
        pure
        returns (uint256 _tier, uint256 _houseId, uint256 _fragmentNo)
    {
        uint256 _num = (_tokenId % MASK);
        _houseId = _tokenId / MASK;
        _tier = _num / SUB_MASK;
        _fragmentNo = _num % SUB_MASK;
    }
}