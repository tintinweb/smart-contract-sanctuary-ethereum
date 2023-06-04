// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@builtbyfrancis/flagroles/contracts/FlagRoles.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./interfaces/ITraitMinter.sol";
import "./base/ERC1155Traits.sol";

contract TraitCollection is
    OperatorFilterer,
    ERC1155Traits,
    ITraitMinter,
    FlagRoles,
    ERC2981
{
    uint256 public constant MODERATOR = 1;
    uint256 public constant MINTER = 2;
    uint256 public constant BURNER = 4;

    bool public operatorFilteringEnabled;

    constructor(
        address[] memory moderators_,
        IERC721Canvas canvas_,
        ITraitUriProvider uriProvider_,
        uint256 optionalMask_
    ) ERC1155Traits(canvas_, uriProvider_, optionalMask_) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        for (uint256 i = 0; i < moderators_.length; i++) {
            grantRole(MODERATOR, moderators_[i]);
        }

        _setDefaultRoyalty(msg.sender, 500);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                     Moderators                                      #
    // #                                                                                     #
    // #######################################################################################

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MODERATOR) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRole(MODERATOR) {
        operatorFilteringEnabled = value;
    }

    function setUriProvider(
        ITraitUriProvider uriProvider
    ) external onlyRole(MODERATOR) {
        _setUriProvider(uriProvider);
    }

    //TODO: Test this
    function setOptionalMask(
        uint256 optionalMask
    ) external onlyRole(MODERATOR) {
        _setOptionalMask(optionalMask);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       Supply                                        #
    // #                                                                                     #
    // #######################################################################################

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(MINTER) {
        _mint(to, id, amount);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(BURNER) {
        _burn(from, id, amount);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  OperatorFilterer                                   #
    // #                                                                                     #
    // #######################################################################################

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Traits, ERC2981) returns (bool) {
        return
            ERC1155Traits.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FlagRoles is Ownable {
    error IncorrectRoleError();

    mapping(address => uint256) private _roles;

    modifier onlyRole(uint256 role) {
        if (!hasRole(role, _msgSender())) revert IncorrectRoleError();
        _;
    }

    function grantRole(uint256 role, address account) public onlyOwner {
        _roles[account] |= role;
    }

    function revokeRole(uint256 role, address account) public onlyOwner {
        _roles[account] &= ~role;
    }

    function hasRole(uint256 role, address account) public view returns (bool) {
        return _roles[account] & role == role;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))

            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            if iszero(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x04)) {
                // If the function selector has not been overwritten,
                // it is an out-of-gas error.
                if eq(shr(224, mload(0x00)), functionSelector) {
                    // To prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC1155Traits.sol";
import "../interfaces/IERC721Canvas.sol";
import "../interfaces/ITraitUriProvider.sol";
import "../library/Layers16.sol";

contract ERC1155Traits is IERC1155MetadataURI, IERC1155Traits, Context, ERC165 {
    using Layers16 for uint256;
    using Address for address;

    IERC721Canvas private immutable _canvas;
    uint256 private _optionalMask;
    ITraitUriProvider private _uriProvider;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        IERC721Canvas canvas_,
        ITraitUriProvider uriProvider_,
        uint256 optionalMask_
    ) {
        _canvas = canvas_;
        _uriProvider = uriProvider_;
        _optionalMask = optionalMask_;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                    IERC1155Traits                                   #
    // #                                                                                     #
    // #######################################################################################

    function equipSingle(
        uint256 characterId,
        uint256 traitId
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);

        (uint256 layer, uint256 isolated) = traitId.mostSignificantLayer();

        uint256 existing = oldCanvas.isolateLayer(layer);
        if (existing != 0) revert LayerOccupiedError();

        _burnOnLayer(operator, isolated.shiftFromLayer(layer), layer, 1);

        unchecked {
            _canvas.setCanvas(
                operator,
                characterId,
                oldCanvas,
                oldCanvas + isolated
            );
        }

        emit TransferSingle(operator, operator, address(0), traitId, 1);
    }

    function equipBatch(
        uint256 characterId,
        uint256[] calldata traitIds
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);
        uint256 newCanvas = oldCanvas;

        uint256[] memory values = new uint256[](traitIds.length);
        for (uint256 i = 0; i < traitIds.length; ) {
            (uint256 layer, uint256 isolated) = traitIds[i]
                .mostSignificantLayer();

            uint256 existing = newCanvas.isolateLayer(layer);
            if (existing != 0) revert LayerOccupiedError();

            _burnOnLayer(operator, isolated.shiftFromLayer(layer), layer, 1);

            values[i] = 1;

            unchecked {
                newCanvas += isolated;
                ++i;
            }
        }

        _canvas.setCanvas(operator, characterId, oldCanvas, newCanvas);

        emit TransferBatch(operator, operator, address(0), traitIds, values);
    }

    function unequipSingle(
        uint256 characterId,
        uint256 traitId
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);

        (uint256 layer, uint256 isolated) = traitId.mostSignificantLayer();

        uint256 existing = oldCanvas.isolateLayer(layer);
        if (existing != isolated) revert LayerMismatchError();

        uint256 optional = _optionalMask.isolateLayer(layer);
        if (optional == 0) revert MissingRequiredTraitError();

        _mintOnLayer(operator, isolated.shiftFromLayer(layer), layer, 1);

        unchecked {
            _canvas.setCanvas(
                operator,
                characterId,
                oldCanvas,
                oldCanvas - isolated
            );
        }

        emit TransferSingle(operator, address(0), operator, traitId, 1);
    }

    function unequipBatch(
        uint256 characterId,
        uint256[] calldata traitIds
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);
        uint256 newCanvas = oldCanvas;

        uint256[] memory values = new uint256[](traitIds.length);
        for (uint256 i = 0; i < traitIds.length; ) {
            (uint256 layer, uint256 isolated) = traitIds[i]
                .mostSignificantLayer();

            uint256 existing = newCanvas.isolateLayer(layer);
            if (existing != isolated) revert LayerMismatchError();

            uint256 optional = _optionalMask.isolateLayer(layer);
            if (optional == 0) revert MissingRequiredTraitError();

            _mintOnLayer(operator, isolated.shiftFromLayer(layer), layer, 1);

            values[i] = 1;

            unchecked {
                newCanvas -= isolated;
                ++i;
            }
        }

        _canvas.setCanvas(operator, characterId, oldCanvas, newCanvas);

        emit TransferBatch(operator, address(0), operator, traitIds, values);
    }

    function swapSingle(
        uint256 characterId,
        uint256 unequipTraitId,
        uint256 equipTraitId
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);

        (uint256 layer, uint256 unequipIsolated) = unequipTraitId
            .mostSignificantLayer();

        uint256 unequipExisting = oldCanvas.isolateLayer(layer);
        if (unequipExisting != unequipIsolated) revert LayerMismatchError();

        uint256 equipIsolated = equipTraitId.isolateLayer(layer);
        if (equipIsolated == 0) revert LayerMismatchError();

        _mintOnLayer(operator, unequipIsolated.shiftFromLayer(layer), layer, 1);
        _burnOnLayer(operator, equipIsolated.shiftFromLayer(layer), layer, 1);

        unchecked {
            _canvas.setCanvas(
                operator,
                characterId,
                oldCanvas,
                oldCanvas - unequipIsolated + equipIsolated
            );
        }

        emit TransferSingle(operator, address(0), operator, unequipTraitId, 1);
        emit TransferSingle(operator, operator, address(0), equipTraitId, 1);
    }

    function swapBatch(
        uint256 characterId,
        uint256[] calldata unequipTraitIds,
        uint256[] calldata equipTraitIds
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);
        uint256 newCanvas = oldCanvas;

        if (unequipTraitIds.length != equipTraitIds.length)
            revert ArrayLengthMismatchError();

        uint256[] memory values = new uint256[](unequipTraitIds.length);
        for (uint256 i = 0; i < unequipTraitIds.length; ) {
            (uint256 layer, uint256 unequipIsolated) = unequipTraitIds[i]
                .mostSignificantLayer();

            uint256 unequipExisting = newCanvas.isolateLayer(layer);
            if (unequipExisting != unequipIsolated) revert LayerMismatchError();

            uint256 equipIsolated = equipTraitIds[i].isolateLayer(layer);
            if (equipIsolated == 0) revert LayerMismatchError();

            _mintOnLayer(
                operator,
                unequipIsolated.shiftFromLayer(layer),
                layer,
                1
            );
            _burnOnLayer(
                operator,
                equipIsolated.shiftFromLayer(layer),
                layer,
                1
            );

            values[i] = 1;

            unchecked {
                newCanvas -= unequipIsolated;
                newCanvas += equipIsolated;
                ++i;
            }
        }

        _canvas.setCanvas(operator, characterId, oldCanvas, newCanvas);

        emit TransferBatch(
            operator,
            address(0),
            operator,
            unequipTraitIds,
            values
        );
        emit TransferBatch(
            operator,
            operator,
            address(0),
            equipTraitIds,
            values
        );
    }

    function buildBatch(
        uint256 characterId,
        uint256[] calldata unequipTraitIds,
        uint256[] calldata equipTraitIds
    ) external override {
        address operator = _msgSender();
        uint256 oldCanvas = _canvas.getCanvas(characterId);
        uint256 newCanvas = oldCanvas;

        uint256[] memory values = new uint256[](unequipTraitIds.length);
        if (unequipTraitIds.length != 0) {
            for (uint256 i = 0; i < unequipTraitIds.length; ) {
                (uint256 layer, uint256 isolated) = unequipTraitIds[i]
                    .mostSignificantLayer();

                uint256 existing = newCanvas.isolateLayer(layer);
                if (existing != isolated) revert LayerMismatchError();

                _mintOnLayer(
                    operator,
                    isolated.shiftFromLayer(layer),
                    layer,
                    1
                );

                values[i] = 1;

                unchecked {
                    newCanvas -= isolated;
                    ++i;
                }
            }
            emit TransferBatch(
                operator,
                address(0),
                operator,
                unequipTraitIds,
                values
            );
        }

        if (equipTraitIds.length != 0) {
            values = new uint256[](equipTraitIds.length);
            for (uint256 i = 0; i < equipTraitIds.length; ) {
                (uint256 layer, uint256 isolated) = equipTraitIds[i]
                    .mostSignificantLayer();

                uint256 existing = newCanvas.isolateLayer(layer);
                if (existing != 0) revert LayerOccupiedError();

                _burnOnLayer(
                    operator,
                    isolated.shiftFromLayer(layer),
                    layer,
                    1
                );

                values[i] = 1;

                unchecked {
                    newCanvas += isolated;
                    ++i;
                }
            }
            emit TransferBatch(
                operator,
                operator,
                address(0),
                equipTraitIds,
                values
            );
        }

        if (!newCanvas.optionalMaskOkay(_optionalMask))
            revert MissingRequiredTraitError();

        _canvas.setCanvas(operator, characterId, oldCanvas, newCanvas);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  IERC1155MetadataURI                                #
    // #                                                                                     #
    // #######################################################################################

    function canvas() public view returns (IERC721Canvas) {
        return _canvas;
    }

    function optionalMask() public view returns (uint256) {
        return _optionalMask;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _uriProvider.uri(tokenId);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       IERC1155                                      #
    // #                                                                                     #
    // #######################################################################################

    function balanceOf(
        address account,
        uint256 id
    ) public view override returns (uint256) {
        if (account == address(0)) revert ZeroAddressError();
        (uint256 layer, uint256 isolated) = id.mostSignificantLayer();
        return
            _balances[isolated.shiftFromLayer(layer)][account].shiftFromLayer(
                layer
            );
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view override returns (uint256[] memory) {
        if (accounts.length != ids.length) revert ArrayLengthMismatchError();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotApprovedError();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotApprovedError();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Traits).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                        Library                                      #
    // #                                                                                     #
    // #######################################################################################

    function _setOptionalMask(uint256 optionalMask_) internal {
        _optionalMask = optionalMask_;
    }

    function _setUriProvider(ITraitUriProvider uriProvider) internal {
        _uriProvider = uriProvider;
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        if (owner == operator) revert SelfApprovalError();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _mint(address to, uint256 id, uint256 amount) internal {
        (uint256 layer, uint256 isolated) = id.mostSignificantLayer();
        _mintOnLayer(to, isolated.shiftFromLayer(layer), layer, amount);

        emit TransferSingle(_msgSender(), address(0), to, id, amount);
    }

    function _mintOnLayer(
        address to,
        uint256 reduced,
        uint256 layer,
        uint256 amount
    ) internal {
        uint256 balance = _balances[reduced][to];

        if (balance.shiftFromLayer(layer) + amount > Layers16.MAX_VALUE)
            revert ExceedsLayerSizeError();

        unchecked {
            _balances[reduced][to] = balance + amount.shiftToLayer(layer);
        }
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
        (uint256 layer, uint256 isolated) = id.mostSignificantLayer();
        _burnOnLayer(from, isolated.shiftFromLayer(layer), layer, amount);

        emit TransferSingle(_msgSender(), from, address(0), id, amount);
    }

    function _burnOnLayer(
        address from,
        uint256 reduced,
        uint256 layer,
        uint256 amount
    ) internal {
        uint256 balance = _balances[reduced][from];

        if (balance.shiftFromLayer(layer) < amount)
            revert InsufficientBalanceError();

        unchecked {
            _balances[reduced][from] = balance - amount.shiftToLayer(layer);
        }
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to == address(0)) revert ZeroAddressError();

        (uint256 layer, uint256 isolated) = id.mostSignificantLayer();
        uint256 reduced = isolated.shiftFromLayer(layer);

        address operator = _msgSender();
        _burnOnLayer(from, reduced, layer, amount);
        _mintOnLayer(to, reduced, layer, amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (ids.length != amounts.length) revert ArrayLengthMismatchError();
        if (to == address(0)) revert ZeroAddressError();

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            (uint256 layer, uint256 isolated) = ids[i].mostSignificantLayer();
            uint256 reduced = isolated.shiftFromLayer(layer);
            uint256 amount = amounts[i];

            _burnOnLayer(from, reduced, layer, amount);
            _mintOnLayer(to, reduced, layer, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155ReceiverRejectedError();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert NotERC1155ReceiverError();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155ReceiverRejectedError();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert NotERC1155ReceiverError();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC1155Traits {
    error ZeroAddressError();
    error NotApprovedError();
    error SelfApprovalError();
    error LayerOccupiedError();
    error LayerMismatchError();
    error ExceedsLayerSizeError();
    error NotERC1155ReceiverError();
    error InsufficientBalanceError();
    error ArrayLengthMismatchError();
    error MissingRequiredTraitError();
    error ERC1155ReceiverRejectedError();

    function equipSingle(uint256 characterId, uint256 traitId) external;

    function equipBatch(
        uint256 characterId,
        uint256[] calldata traitIds
    ) external;

    function unequipSingle(uint256 characterId, uint256 traitId) external;

    function unequipBatch(
        uint256 characterId,
        uint256[] calldata traitIds
    ) external;

    function swapSingle(
        uint256 characterId,
        uint256 unequipTraitId,
        uint256 equipTraitId
    ) external;

    function swapBatch(
        uint256 characterId,
        uint256[] calldata unequipTraitIds,
        uint256[] calldata equipTraitIds
    ) external;

    function buildBatch(
        uint256 characterId,
        uint256[] calldata unequipTraitIds,
        uint256[] calldata equipTraitIds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC721Canvas {
    error NotUniqueError();
    error ZeroAddressError();
    error SelfApprovalError();
    error ExistingTokenError();
    error NotTokenOwnerError();
    error NonexistentTokenError();
    error NotERC721ReceiverError();
    error NotOwnerOrApprovedError();
    error ERC721ReceiverRejectedError();

    event CanvasChanged(uint256 indexed tokenId, uint256 from, uint256 to);

    function getUnique(uint256 canvas) external view returns (uint256);

    function getCanvas(uint256 tokenId) external view returns (uint256);

    function setCanvas(
        address caller,
        uint256 tokenId,
        uint256 from,
        uint256 to
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITraitMinter {
    function mint(address to, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITraitUriProvider {
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Layers16 {
    uint256 public constant LAYER_COUNT = 16;
    uint256 public constant LAYER_BITS = 16;
    uint256 public constant MAX_VALUE = 0xffff;

    error ZeroTraitError();

    function shiftToLayer(
        uint256 value,
        uint256 layer
    ) internal pure returns (uint256) {
        unchecked {
            return (value & MAX_VALUE) << (layer * LAYER_BITS);
        }
    }

    function shiftFromLayer(
        uint256 value,
        uint256 layer
    ) internal pure returns (uint256) {
        unchecked {
            return (value >> (layer * LAYER_BITS)) & MAX_VALUE;
        }
    }

    function isolateLayer(
        uint256 value,
        uint256 layer
    ) internal pure returns (uint256) {
        unchecked {
            return value & (MAX_VALUE << (layer * LAYER_BITS));
        }
    }

    function optionalMaskOkay(
        uint256 value,
        uint256 mask
    ) internal pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < LAYER_COUNT; i++) {
                if ((value | mask) & MAX_VALUE == 0) return false;
                value >>= LAYER_BITS;
                mask >>= LAYER_BITS;
            }
        }

        return true;
    }

    // If this is the best way of doing this then.. Bullish.
    function mostSignificantLayer(
        uint256 value
    ) internal pure returns (uint256, uint256) {
        if (value == 0) revert ZeroTraitError();
        if (value < 0x10000) return (0, value & 0xffff);
        if (value < 0x100000000) return (1, value & 0xffff0000);
        if (value < 0x1000000000000) return (2, value & 0xffff00000000);
        if (value < 0x10000000000000000) return (3, value & 0xffff000000000000);
        if (value < 0x100000000000000000000)
            return (4, value & 0xffff0000000000000000);
        if (value < 0x1000000000000000000000000)
            return (5, value & 0xffff00000000000000000000);
        if (value < 0x10000000000000000000000000000)
            return (6, value & 0xffff000000000000000000000000);
        if (value < 0x100000000000000000000000000000000)
            return (7, value & 0xffff0000000000000000000000000000);
        if (value < 0x1000000000000000000000000000000000000)
            return (8, value & 0xffff00000000000000000000000000000000);
        if (value < 0x0010000000000000000000000000000000000000000)
            return (9, value & 0x00ffff000000000000000000000000000000000000);
        if (value < 0x100000000000000000000000000000000000000000000)
            return (10, value & 0xffff0000000000000000000000000000000000000000);
        if (value < 0x1000000000000000000000000000000000000000000000000)
            return (
                11,
                value & 0xffff00000000000000000000000000000000000000000000
            );
        if (value < 0x10000000000000000000000000000000000000000000000000000)
            return (
                12,
                value & 0xffff000000000000000000000000000000000000000000000000
            );
        if (value < 0x100000000000000000000000000000000000000000000000000000000)
            return (
                13,
                value &
                    0xffff0000000000000000000000000000000000000000000000000000
            );
        if (
            value <
            0x1000000000000000000000000000000000000000000000000000000000000
        )
            return (
                14,
                value &
                    0xffff00000000000000000000000000000000000000000000000000000000
            );
        return (
            15,
            value &
                0xffff000000000000000000000000000000000000000000000000000000000000
        );
    }
}