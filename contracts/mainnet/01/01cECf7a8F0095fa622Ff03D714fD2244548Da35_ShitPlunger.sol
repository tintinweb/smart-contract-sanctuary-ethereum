// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ShitPlungerRenderer.sol";

interface IRenderer {
    function render() external view returns (string memory);
}

contract ShitPlunger is ERC1155, ERC2981, Ownable {
    uint32 public constant MAX_SUPPLY = 8888;

    address public _renderer;
    uint32 public _minted = 0;
    address public _allowedMinter;
    address public _burner;

    constructor(address renderer) ERC1155("") {
        _renderer = renderer;
        setFeeNumerator(750);
    }

    function mint(address to, uint32 amount) external {
        require(_allowedMinter == msg.sender, "ShitPlunger: ?");
        require(amount + _minted <= MAX_SUPPLY, "ShitPlunger: Exceed max supply");

        _minted += amount;
        _mint(to, 0, amount, "");
    }

    function airdrop(address[] memory tos, uint32[] memory amounts) external onlyOwner {
        require(tos.length == amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _minted += amounts[i];
            require(_minted <= MAX_SUPPLY, "ShitPlunger: Exceed max supply");

            _mint(tos[i], 0, amounts[i], "");
        }
    }

    function burn(address who, uint32 amount) external {
        require(msg.sender == _burner, "ShitPlunger: ?");

        _burn(who, 0, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return IRenderer(_renderer).render();
    }

    function setMinter(address minter) external onlyOwner {
        _allowedMinter = minter;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function setRenderer(address renderer) external onlyOwner {
        _renderer = renderer;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

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
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
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
     * - `tokenId` must be already minted.
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
pragma solidity ^0.8.9;

import "./Base64.sol";

contract ShitPlungerRenderer {
    string public constant IMAGE_DATA =
        "data:image/webp;base64,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";

    function render() external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"ShitPlunger",',
                            '"description":"The best shit plunger you can get on the market!",',
                            '"image":"',
                            IMAGE_DATA,
                            '"}'
                        )
                    )
                )
            );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Base64 {
    string constant private B64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = B64_ALPHABET;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}