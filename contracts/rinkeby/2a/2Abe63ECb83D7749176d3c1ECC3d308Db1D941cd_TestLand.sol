// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";
import "ERC721BStaticTokenURI.sol";

contract TestLand is Ownable, ERC721BStaticTokenURI {
    function mint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function name() external view returns (string memory) {
        return "Silks - TestLand";
    }

    function symbol() external view returns (string memory) {
        return "SILKS-TESTLAND";
    }

    function setTokenURI(uint256 tokenId, string memory uri)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, uri);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721B, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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

pragma solidity ^0.8.0;

import "IERC721Metadata.sol";
import "ERC721B.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721BStaticTokenURI is ERC721B, IERC721Metadata {
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return staticTokenURI(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function staticTokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        _tokenURIs[tokenId] = _tokenURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

import "IERC721.sol";
import "IERC721Receiver.sol";

import "Context.sol";
import "ERC165.sol";

error InvalidCall();
error BalanceQueryZeroAddress();
error NonExistentToken();
error ApprovalToCurrentOwner();
error ApprovalOwnerIsOperator();
error NotERC721Receiver();
error ERC721ReceiverNotReceived();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721]
 * Non-Fungible Token Standard, including the Metadata extension and
 * token Auto-ID generation.
 *
 * You must provide `name()` `symbol()` and `tokenURI(uint256 tokenId)`
 * to conform with IERC721Metadata
 */
abstract contract ERC721B is Context, ERC165, IERC721 {
    // ============ Storage ============

    // The last token id minted
    uint256 private _lastTokenId;
    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ============ Read Methods ============

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryZeroAddress();
        return _balances[owner];
    }

    /**
     * @dev Shows the overall amount of tokens generated in the contract
     */
    function totalSupply() public view virtual returns (uint256) {
        return _lastTokenId;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        unchecked {
            //this is the situation when _owners normalized
            uint256 id = tokenId;
            if (_owners[id] != address(0)) {
                return _owners[id];
            }
            //this is the situation when _owners is not normalized
            if (id > 0 && id <= _lastTokenId) {
                //there will never be a case where token 1 is address(0)
                while (true) {
                    id--;
                    if (id == 0) {
                        break;
                    } else if (_owners[id] != address(0)) {
                        return _owners[id];
                    }
                }
            }
        }

        revert NonExistentToken();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============ Approval Methods ============

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721B.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        address sender = _msgSender();
        if (sender != owner && !isApprovedForAll(owner, sender))
            revert ApprovalToCurrentOwner();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev transfers token considering approvals
     */
    function _approveTransfer(
        address spender,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (!_isApprovedOrOwner(spender, tokenId, from)) revert InvalidCall();

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers token considering approvals
     */
    function _approveSafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _approveTransfer(_msgSender(), from, to, tokenId);
        //see: @openzep/utils/Address.sol
        if (
            to.code.length > 0 &&
            !_checkOnERC721Received(from, to, tokenId, _data)
        ) revert ERC721ReceiverNotReceived();
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId,
        address owner
    ) internal view virtual returns (bool) {
        return
            spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender);
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
        if (owner == operator) revert ApprovalOwnerIsOperator();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    // ============ Mint Methods ============

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint}
     * whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 amount,
        bytes memory _data,
        bool safeCheck
    ) private {
        if (amount == 0 || to == address(0)) revert InvalidCall();
        uint256 startTokenId = _lastTokenId + 1;

        _beforeTokenTransfers(address(0), to, startTokenId, amount);

        unchecked {
            _lastTokenId += amount;
            _balances[to] += amount;
            _owners[startTokenId] = to;

            _afterTokenTransfers(address(0), to, startTokenId, amount);

            uint256 updatedIndex = startTokenId;
            uint256 endIndex = updatedIndex + amount;
            //if do safe check and,
            //check if contract one time (instead of loop)
            //see: @openzep/utils/Address.sol
            if (safeCheck && to.code.length > 0) {
                //loop emit transfer and received check
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) revert ERC721ReceiverNotReceived();
                } while (updatedIndex != endIndex);
                return;
            }

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != endIndex);
        }
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a
     *   safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 amount) internal virtual {
        _safeMint(to, amount, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`],
     * with an additional `data` parameter which is forwarded in
     * {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 amount,
        bytes memory _data
    ) internal virtual {
        _mint(to, amount, _data, true);
    }

    // ============ Transfer Methods ============

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _approveTransfer(_msgSender(), from, to, tokenId);
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
        bytes memory _data
    ) public virtual override {
        _approveSafeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received}
     * on a target address. The call is not executed if the target address
     * is not a contract.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert NotERC721Receiver();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via
     * {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId > 0 && tokenId <= _lastTokenId;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking
     * first that contract recipients are aware of the ERC721 protocol to
     * prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is
     * sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can
     * be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as
     * signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a
     *   safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        //see: @openzep/utils/Address.sol
        if (
            to.code.length > 0 &&
            !_checkOnERC721Received(from, to, tokenId, _data)
        ) revert ERC721ReceiverNotReceived();
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`. As opposed to
     * {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) private {
        //if transfer to null or not the owner
        if (to == address(0) || from != ERC721B.ownerOf(tokenId))
            revert InvalidCall();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        unchecked {
            //this is the situation when _owners are normalized
            _balances[to] += 1;
            _balances[from] -= 1;
            _owners[tokenId] = to;
            //this is the situation when _owners are not normalized
            uint256 nextTokenId = tokenId + 1;
            if (
                nextTokenId <= _lastTokenId &&
                _owners[nextTokenId] == address(0)
            ) {
                _owners[nextTokenId] = from;
            }
        }

        _afterTokenTransfers(from, to, tokenId, 1);
        emit Transfer(from, to, tokenId);
    }

    // ============ TODO Methods ============

    /**
     * @dev Hook that is called before a set of serially-ordered token ids
     * are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * amount - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId`
     *   will be transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids
     * have been transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * amount - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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