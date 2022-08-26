// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ERC1155Base is Ownable, ERC1155, ERC1155Burnable, ERC2981 {
    // Royalty limit to capped royities while minting.
    uint96 public royaltyLimit;

    // tokenId counter
    uint256 counter = 0;

    // Mapping to manage nonce for lazy mint
    mapping(uint256 => uint256) public nonceToTokenId;

    // Mapping for whitelist users
    mapping(address => bool) public whitelistedUsers;

    struct tokenDetail {
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 totalSupply;
        string uri;
    }

    mapping(uint256 => tokenDetail) public tokenDetails;

    bool public openForAll = false;

    string public baseURI;

    constructor(
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit // Max Royalty limit for collection
    ) ERC1155("") {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC1155Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
        baseURI = _tokenURIPrefix;
    }

    modifier whitelistCheck(address user) {
        require(
            whitelistedUsers[user] || owner() == user || openForAll,
            "ERC1155Base: Whitelisted users only."
        );
        _;
    }

    function toggleOpenForAll() external onlyOwner {
        openForAll = !openForAll;
    }

    function whitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = true;
        }
    }

    function removeWhitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = false;
        }
    }

    // Method to set Max royalty for collection
    function setRoyaltyLimit(uint96 _royaltyLimit) external onlyOwner {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC1155Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
    }

    // internal method to mint the nft
    function _mint(
        address to,
        uint256 amount,
        uint96 royalty,
        string memory _tokenURI
    ) internal virtual whitelistCheck(to) returns (uint256) {
        require(
            royalty <= royaltyLimit,
            "ERC1155Base: Royalty must be below royalty limit"
        );
        counter++;
        super._mint(to, counter, amount, bytes(""));
        _setTokenRoyalty(counter, to, royalty);
        tokenDetails[counter] = tokenDetail(amount, amount, amount, _tokenURI);
        return counter;
    }

    function _lazyMint(
        address to,
        uint96 royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        uint256 _maxSupply,
        uint256 amount,
        bytes memory sign,
        address buyer
    ) internal whitelistCheck(to) returns (uint256) {
        // Verfify signature
        {
            bytes32 signedMessageHash;
            {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(
                        address(this),
                        royalty,
                        nonce,
                        _tokenURI,
                        price,
                        _maxSupply
                    )
                );

                signedMessageHash = keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        messageHash
                    )
                );
            }
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            require(
                to == ecrecover(signedMessageHash, v, r, s),
                "ERC1155Base: Signature not verfied."
            );
        }

        // tokenDetail
        tokenDetail memory _tokenDetail;
        uint256 tokenId;

        // Get existing details
        if (isNonceProcessed(nonce)) {
            tokenId = nonceToTokenId[nonce];
            _tokenDetail = tokenDetails[tokenId];
        } else {
            require(
                royalty <= royaltyLimit,
                "ERC1155Base: Royalty must be below royalty limit"
            );
            // Create new token.
            counter++;
            tokenId = counter;
            _tokenDetail = tokenDetail(_maxSupply, 0, 0, _tokenURI);
            _setTokenRoyalty(tokenId, to, royalty);
        }
        require(
            _tokenDetail.totalMinted + amount <= _tokenDetail.maxSupply,
            "ERC1155Base: Max supply exceeded for this token"
        );

        // mint new token
        super._mint(to, tokenId, amount, bytes(""));

        // update token details
        _tokenDetail.totalMinted += amount;
        _tokenDetail.totalSupply += amount;
        tokenDetails[tokenId] = _tokenDetail;

        // transfer the NFT to buyer
        _safeTransferFrom(to, buyer, tokenId, amount, bytes(""));
        return tokenId;
    }

    // Method to check if nonce is processed
    function isNonceProcessed(uint256 nonce) public view returns (bool) {
        return nonceToTokenId[nonce] > 0;
    }

    // Method to get totalSupply of NFT
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].totalSupply;
    }

    // Method to get MaxSupply of NFT
    function maxSupply(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].maxSupply;
    }

    // Method to get totalMinted of NFT
    function totalMinted(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].totalMinted;
    }

    // Method to check if NFT exists
    function exists(uint256 tokenId) external view returns (bool) {
        return tokenDetails[tokenId].totalSupply > 0;
    }

    // Method to get token uri
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenDetails[tokenId].uri));
    }

    // Method to withdraw Native currency
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Method to withdraw ERC20 in this contract
    function withdrawERC20(address _erc20) external onlyOwner {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    // Fallback method
    fallback() external payable {}

    // Fallback method
    receive() external payable {}

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                tokenDetails[ids[i]].totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                tokenDetails[ids[i]].totalSupply -= amounts[i];
            }
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity 0.8.13;

import "./ERC1155Base.sol";
import "./IERC1155Mintable.sol";

contract ERC1155Collection is ERC1155Base {
    address payable public mintableAddress;

    // Metadata:
    string private _name;
    string private _symbol;
    string private _contractURI;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    constructor(
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit, // Max Royalty limit for collection
        address payable _mintableAddress, // Mintable contract address
        address sender, // Owner of contract
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) ERC1155Base(_tokenURIPrefix, _royaltyLimit) {
        mintableAddress = _mintableAddress;
        _transferOwnership(sender);
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_)
        external
        virtual
        onlyOwner
    {
        _contractURI = contractURI_;
    }

    function mint(
        string memory tokenURI,
        uint96 _royalty,
        uint256 amount,
        address _to
    ) public payable returns (uint256) {
        uint256 mintingCharges = IERC1155Mintable(mintableAddress)
            .mintingChargePerToken();
        require(
            msg.value >= mintingCharges * amount,
            "ERC1155Collection: Insufficent fund transferred."
        );
        uint256 tokenId = _mint(_to, amount, _royalty, tokenURI);
        IERC1155Mintable(mintableAddress).broker().transfer(msg.value);
        return tokenId;
    }

    function lazyMint(
        address to,
        uint96 royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        uint256 _maxSupply,
        uint256 amount,
        bytes memory sign,
        address buyer
    ) external payable returns (uint256) {
        IERC1155Mintable mintable = IERC1155Mintable(mintableAddress);
        uint256 mintingCharges = mintable.mintingChargePerToken();
        IERC1155Mintable._brokerage memory brokerage = mintable.brokerage();
        uint256 buyingBrokerage = (brokerage.buyer * price) /
            (100 * decimalPrecision);
        require(
            msg.value >= (price + mintingCharges + buyingBrokerage) * amount,
            "ERC1155Collection: Insufficent fund transferred."
        );
        uint256 tokenId = _lazyMint(
            to,
            royalty,
            _tokenURI,
            nonce,
            price,
            _maxSupply,
            amount,
            sign,
            buyer
        );
        uint256 sellerFund;
        {
            uint256 sellingBrokerage = (brokerage.seller * price) /
                (100 * decimalPrecision);
            sellerFund = (price - sellingBrokerage) * amount;
        }
        payable(to).transfer(sellerFund);
        mintable.broker().transfer(msg.value - sellerFund);
        return tokenId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Mintable is IERC1155, IERC2981 {
    function mintingChargePerToken() external view returns(uint);

    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

    function broker() external view returns (address payable);

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    function brokerage() external view returns (_brokerage calldata);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import './ERC1155Collection.sol';


/**
 * @title Factory contract to create collections
 * This implementation deploy the collection contract and returns the list of colledtions deployed
 */
contract UPYOERC1155Factory is Ownable{

    // List to store all collections created till now.
    address[] private _collections;

    // Mapping to store collection created by user
    // sender => list of collection deployed
    mapping(address => address[]) private _userCollections;
    
    address payable public mintableToken;   
    
    /**
     * @dev Constructor function
     */
    constructor(address payable _mintableToken){
        mintableToken = _mintableToken;
    }


    /**
     * @dev Public function that deploys new collection contract and return new collection address.
     * @dev Returns address of deployed contract
     * @param tokenURIPrefix prefix for tokenURI of NFT contract
     */
    function createCollection(
        string memory tokenURIPrefix, 
        uint96 royaltyLimit,
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) public returns (address collectionAddress){
        ERC1155Collection collection = new ERC1155Collection(
            tokenURIPrefix,
            royaltyLimit,
            mintableToken,
            msg.sender,
            name_,
            symbol_,
            contractURI_
        );
        collectionAddress = address(collection);
        _collections.push(collectionAddress);
        _userCollections[msg.sender].push(collectionAddress);
    }

    function setMintabaleAddress(address payable _mintableToken) external onlyOwner{
        mintableToken = _mintableToken;
    }

    /**
     * @dev return all collections deployed till now.
     */
    function getAllCollection() public view returns (address[]memory){
        return _collections;
    }

    /**
     * @dev Returns contracts depolyet to address
     */
    function getUserCollection(address _user) public view returns (address[] memory){
        return _userCollections[_user];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC1155Mintable.sol";

contract UPYOERC1155MarketplaceV2 is
    Initializable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable
{
    // Sale details
    struct auction {
        uint256 quantity;
        uint256 price;
        address erc20;
    }

    // Master data strcture
    /**
     Master data structure explaination
     {
        ERC1155Address: {
            TokenID: {
                Seller: SellDetalis
            }
        }
     }
     */
    mapping(address => mapping(uint256 => mapping(address => auction)))
        public _auctions;

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // address to transfer brokerage
    address payable public broker;

    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // events
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 quantity,
        uint256 time,
        bool onOffer,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC1155Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier isSufficientNFTOnAuction(
        address _erc1155,
        uint256 _tokenId,
        address payable _seller,
        uint256 _quantity
    ) {
        require(
            _auctions[_erc1155][_tokenId][_seller].quantity >= _quantity,
            "ERC1155Marketplace: Not Enough NFT on auction"
        );
        _;
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    /**
     Funtion to check if it have active auction or not
     */
    function haveActiveSell(
        address _erc1155,
        uint256 _tokenId,
        address _seller
    ) external view returns (bool) {
        return _auctions[_erc1155][_tokenId][_seller].quantity > 0;
    }

    function _getCreatorAndRoyalty(
        IERC1155Mintable collection,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable creator, uint256 royalty) {
        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = payable(receiver);
            royalty = royaltyAmount;
        } catch {
            //  =
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
    }

    function _transferNFTs(
        IERC1155Mintable collection,
        uint256 _tokenId,
        uint256 price,
        address erc20Token,
        uint256 _quantity,
        address payable _seller,
        address buyer
    ) private {
        // Get creator and royalty
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            collection,
            _tokenId,
            price * _quantity
        );

        _brokerage memory brokerage_;

        brokerage_.seller =
            (brokerage[erc20Token].seller * price) /
            (100 * decimalPrecision);

        // Calculate Brokerage
        brokerage_.buyer =
            (brokerage[erc20Token].buyer * price) /
            (100 * decimalPrecision);

        uint256 seller_fund = ((price - brokerage_.buyer - brokerage_.seller) *
            _quantity) - royalty;

        // Transfer the funds
        if (erc20Token == address(0)) {
            require(
                msg.value >= (price + brokerage_.buyer) * _quantity,
                "ERC1155Marketplace: Insufficient Payment"
            );
            // Transfer the fund to creator if royalty available
            if (royalty > 0 && creator != payable(address(0))) {
                creator.transfer(royalty);
            } else {
                royalty = 0;
            }
            _seller.transfer(seller_fund);
            broker.transfer(msg.value - seller_fund - royalty);
        } else {
            IERC20 erc20 = IERC20(erc20Token);
            require(
                erc20.allowance(msg.sender, address(this)) >=
                    (price + brokerage_.buyer) * _quantity,
                "ERC1155Marketplace: Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            if (royalty > 0 && creator != payable(address(0))) {
                erc20.transferFrom(msg.sender, creator, royalty);
                royalty = 0;
            }
            // transfer brokerage amount to broker
            erc20.transferFrom(
                msg.sender,
                broker,
                ((brokerage_.seller + brokerage_.buyer) * price) + royalty
            );
            // transfer remaining  amount to lastOwner
            erc20.transferFrom(msg.sender, _seller, seller_fund);
        }

        collection.safeTransferFrom(
            _seller,
            buyer,
            _tokenId,
            _quantity,
            bytes("")
        );
    }

    function buy(
        address _erc1155,
        uint256 _tokenId,
        address payable _seller,
        uint256 _quantity,
        address buyer,
        auction calldata auction_,
        uint256 _nonce,
        bytes calldata sign
    ) external payable {
        // Get Objects
        IERC1155Mintable collection = IERC1155Mintable(_erc1155);

        if (!isNonceProcessed[_seller][_nonce]) {
            {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(
                        address(this),
                        _erc1155,
                        _tokenId,
                        _nonce,
                        auction_.erc20,
                        auction_.price,
                        auction_.quantity
                    )
                );

                bytes32 signedMessageHash = keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        messageHash
                    )
                );

                (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

                require(
                    _seller == ecrecover(signedMessageHash, v, r, s),
                    "ERC1155BaseUpgradeable: Signature not verfied."
                );
            }
            // Check if broker approved
            require(
                collection.isApprovedForAll(_seller, address(this)),
                "ERC1155Marketplace: Broker Not approved"
            );

            // Check if seller have sufficient assets to put on sale.
            require(
                collection.balanceOf(_seller, _tokenId) >= _quantity,
                "ERC1155Marketplace: Seller don't have sufficient copies to put on sale"
            );

            _auctions[_erc1155][_tokenId][_seller] = auction_;

            isNonceProcessed[_seller][_nonce] = true;
        }

        auction storage _auction = _auctions[_erc1155][_tokenId][_seller];

        // Check if the requested quantity if available for sale
        require(
            _auction.quantity >= _quantity,
            "ERC1155Marketplace: Requested quantity not available for sale"
        );

        // Complete the transfer process
        _transferNFTs(
            collection,
            _tokenId,
            _auction.price,
            _auction.erc20,
            _quantity,
            _seller,
            buyer
        );

        // Update the Auction details if more items left for sale.
        if (_auction.quantity > _quantity) {
            _auction.quantity -= _quantity;
        } else {
            // Delete auction if no items left for sale.
            delete _auctions[_erc1155][_tokenId][_seller];
        }

        // Buy event
        emit Sold(
            _erc1155,
            _tokenId,
            _seller,
            buyer,
            _auction.price,
            _quantity,
            block.timestamp,
            false,
            _auction.erc20
        );
    }

    function putOffSale(
        address _erc1155,
        uint256 _tokenId,
        uint256 _nonce
    ) external {
        isNonceProcessed[msg.sender][_nonce] = true;
        // Reset the auction
        delete _auctions[_erc1155][_tokenId][msg.sender];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721BaseUpgradeable is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    // Royalty limit to capped royities while minting.
    uint96 public royaltyLimit;

    // contractURI
    string public contractURI;

    // _base URI
    string baseURI_;

    // tokenId counter
    uint256 counter;

    // Mapping to manage nonce for lazy mint
    mapping(uint256 => bool) public isNonceProcessed;

    // Mapping for whitelist users
    mapping(address => bool) public whitelistedUsers;

    bool public openForAll;

    function __ERC721Base_init(
        string memory _name, // Name of collection
        string memory _symbol, // Symbol of collection
        string memory _contractURI, // Metadata of collection
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit // Max Royalty limit for collection
    ) internal onlyInitializing{
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __ERC721Burnable_init();
        __ERC721Enumerable_init();
        __ERC721Royalty_init();
        __ERC721URIStorage_init();
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC721Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
        contractURI = _contractURI;
        baseURI_ = _tokenURIPrefix;
        counter = 0;
    }

    modifier whitelistCheck(address user) {
        require(
            whitelistedUsers[user] || owner() == user || openForAll,
            "ERC721Base: Whitelisted users only."
        );
        _;
    }

    function toggleOpenForAll() external onlyOwner {
        openForAll = !openForAll;
    }

    function whitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = true;
        }
    }

    function removeWhitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = false;
        }
    }

    // Method to set Max royalty for collection
    function setRoyaltyLimit(uint96 _royaltyLimit) external onlyOwner {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC721Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
    }

    function _mint(
        address to,
        uint96 _royalty,
        string memory _tokenURI
    ) internal whitelistCheck(to) returns (uint256) {
        require(
            _royalty <= royaltyLimit,
            "ERC721Base: Royalty must be below royalty limit"
        );
        counter++;
        _mint(to, counter);
        _setTokenRoyalty(counter, to, _royalty);
        _setTokenURI(counter, _tokenURI);
        return counter;
    }

    function _lazyMint(
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign,
        address buyer
    ) internal whitelistCheck(to) returns (uint){
        {
            require(
                !isNonceProcessed[nonce],
                "ERC721Base: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _royalty,
                    nonce,
                    _tokenURI,
                    price
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(to == signer_, "ERC721Base: Signature not verfied.");
        }
        uint256 tokenId = _mint(to, _royalty, _tokenURI);
        _transfer(to, buyer, tokenId);
        isNonceProcessed[nonce] = true;
        return tokenId;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI_ = _baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // Method to withdraw Native currency
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Method to withdraw ERC20 in this contract
    function withdrawERC20(address _erc20) external onlyOwner {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    // Fallback method
    fallback() external payable {}

    // Receive method
    receive() external payable {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../common/ERC2981Upgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721RoyaltyUpgradeable is Initializable, ERC2981Upgradeable, ERC721Upgradeable {
    function __ERC721Royalty_init() internal onlyInitializing {
    }

    function __ERC721Royalty_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
pragma solidity 0.8.13;

import "./ERC721BaseUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UPYOERC721Mintable is UUPSUpgradeable, ERC721BaseUpgradeable {
    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    address payable public broker;

    mapping(address => bool) public ecosystemContract;

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    _brokerage public brokerage;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    modifier ecosystemContractOnly() {
        require(
            ecosystemContract[msg.sender],
            "UPYOERC721Mintable: Internal contracts only"
        );
        _;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    // Method to set minting charges per NFT
    function setBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    // Method to set minting charges per NFT
    function setBrokerage(_brokerage calldata brokerage_) external onlyOwner {
        require(
            brokerage_.buyer <= 100 * decimalPrecision &&
                brokerage_.seller <= 100 * decimalPrecision,
            "UPYOERC721Mintable: Brokerage can't be more than 100%"
        );
        brokerage = brokerage_;
    }

    // Method to update ecosystem contracts
    function addEcosystemContracts(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            ecosystemContract[_addresses[i]] = true;
        }
    }

    // Method to remove ecosystem contracts
    function removeEcosystemContracts(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            ecosystemContract[_addresses[i]] = false;
        }
    }

    function initialize(
        string memory _name, // Name of collection
        string memory _symbol, // Symbol of collection
        string memory _contractURI, // Metadata of collection
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit, // Max Royalty limit for collection
        uint256 _mintingCharge, // Minting charges for collection
        address payable _broker, // Broker address
        _brokerage calldata brokerage_
    ) external initializer {
        __ERC721Base_init(
            _name,
            _symbol,
            _contractURI,
            _tokenURIPrefix,
            _royaltyLimit
        );
        mintingCharge = _mintingCharge;
        broker = _broker;
        openForAll = true;
        brokerage = brokerage_;
    }

    function mint(
        string memory tokenURI,
        uint96 _royalty,
        address _to
    ) external payable returns (uint256) {
        require(
            msg.value >= mintingCharge,
            "ERC721Mintable: Minting charges required"
        );
        uint256 tokenId = _mint(_to, _royalty, tokenURI);
        broker.transfer(msg.value);
        return tokenId;
    }

    function lazyMint(
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign,
        address buyer
    ) external payable returns(uint){
        uint256 buyingBrokerage = (brokerage.buyer * price) /
            (100 * decimalPrecision);
        require(
            msg.value >= price + mintingCharge + buyingBrokerage,
            "ERC721Minatable: Insufficent fund transferred."
        );
        uint tokenId = _lazyMint(to, _royalty, _tokenURI, nonce, price, sign, buyer);
        uint256 sellingBrokerage = (brokerage.seller * price) /
            (100 * decimalPrecision);
        uint256 sellerFund = price - sellingBrokerage;

        payable(to).transfer(sellerFund);
        broker.transfer(msg.value - sellerFund);
        return tokenId;
    }

    function delegatedMint(
        string memory tokenURI,
        uint96 _royalty,
        address _to,
        address _receiver
    ) external ecosystemContractOnly {
        uint256 tokenId = _mint(_to, _royalty, tokenURI);
        _transfer(_to, _receiver, tokenId);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Mintable.sol";

contract UPYOERC721MarketPlaceV4 is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Storage

    //auction type :
    // 1 : only direct buy
    // 2 : only bid

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store auction details
    mapping(address => mapping(uint256 => auction)) _auctions;

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // address to transfer brokerage
    address payable public broker;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Mapping to manage nonce for lazy mint
    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // Platform's signer address
    address _signer;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    // WETH address
    address public WETH;

    // Mapping to store nonce status.
    mapping(uint256 => bool) public auctionNonceStatus;

    // offer nonce
    mapping(uint256 => bool) isOfferNonceProcessed;

    struct sellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 endingTime;
        address erc20Token;
    }

    struct buyerVoucher {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    // Events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        uint256 nonce
    );
    event LazyAuction(
        address seller,
        address buyer,
        address collection,
        address ERC20Address,
        uint256 price,
        uint256 time
    );
    event OfferAccepted(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC721Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).seller != address(0),
            "ERC721Marketplace: Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _erc721) {
        require(
            block.timestamp < auctions(_erc721, _tokenId).closingTime,
            "ERC721Marketplace: Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 2,
            "ERC721Marketplace: Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 1,
            "ERC721Marketplace: Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _erc721) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_erc721).ownerOf(_tokenId) == msg.sender,
            "ERC721Marketplace: You must be owner and Token should not have any bid"
        );
        _;
    }

    // Getters
    function auctions(address _erc721, uint256 _tokenId)
        public
        view
        returns (auction memory)
    {
        address _owner = IERC721Mintable(_erc721).ownerOf(_tokenId);
        if (
            _owner == _auctions[_erc721][_tokenId].seller ||
            _owner == address(this)
        ) {
            return _auctions[_erc721][_tokenId];
        }
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function setSigner(address signer_) external onlyOwner {
        require(
            signer_ != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        _signer = signer_;
    }

    function setWETH(address _WETH) external onlyOwner {
        require(
            _WETH != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        WETH = _WETH;
    }

    function signer() external view onlyOwner returns (address) {
        return _signer;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    function bid(
        uint256 _tokenId,
        address _erc721,
        uint256 amount,
        address payable bidder,
        auction memory _auction,
        uint256 _nonce,
        bytes calldata sign
    ) external payable nonReentrant {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        {
            address seller = Token.ownerOf(_tokenId);

            if (auctionNonceStatus[_nonce]) {
                _auction = _auctions[_erc721][_tokenId];
                require(
                    _auction.seller != address(0) &&
                        (seller == _auction.seller || seller == address(this)),
                    "ERC721Marketplace: Token Not For Sale"
                );
            } else {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(
                        address(this),
                        _auction.seller,
                        _erc721,
                        _tokenId,
                        _nonce,
                        _auction.startingPrice,
                        _auction.startingTime,
                        _auction.closingTime,
                        _auction.erc20Token
                    )
                );

                bytes32 signedMessageHash = keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        messageHash
                    )
                );
                (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

                address signer_ = ecrecover(signedMessageHash, v, r, s);

                require(signer_ == seller, "ERC721Marketplace: Invalid Sign");

                _auction.currentBid =
                    _auction.startingPrice +
                    (brokerage[_auction.erc20Token].buyer *
                        _auction.startingPrice) /
                    (100 * decimalPrecision);
                _auction.auctionType = 2;
            }
            require(
                block.timestamp >= _auction.startingTime &&
                    block.timestamp <= _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
            auctionNonceStatus[_nonce] = true;
        }

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "ERC721Marketplace: Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        if (Token.ownerOf(_tokenId) != address(this)) {
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        }
        _auction.highestBidder = bidder;

        _auctions[_erc721][_tokenId] = _auction;

        // Bid event
        emit Bid(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _erc721)
        external
        onSaleOnly(_tokenId, _erc721)
        auctionOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Only allow collect without finishing the auction only if admin collects it.
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "ERC721Marketplace: Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            // Get royality and seller
            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _auction.currentBid
            );

            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.currentBid -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            // Transfer funds for native currency
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(brokerage_.seller + brokerage_.buyer);
            }
            // Transfer funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(_auction.seller, sellerFund);
                erc20Token.transfer(
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
            }
            // Transfer the NFT to Buyer
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );

            // Sold event
            emit Sold(
                _erc721,
                _tokenId,
                _auction.seller,
                _auction.highestBidder,
                _auction.currentBid - brokerage_.buyer,
                msg.sender,
                _auction.auctionType,
                block.timestamp,
                _auction.erc20Token
            );
        }
        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address buyer
    ) external payable nonReentrant {
        require(
            !auctionNonceStatus[_nonce],
            "ERC721Marketplace: Nonce have been already processed."
        );
        IERC721Mintable Token = IERC721Mintable(_erc721);

        address seller = Token.ownerOf(_tokenId);

        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _tokenId,
                    _erc721,
                    price,
                    _nonce,
                    _erc20Token
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
        }

        require(
            Token.getApproved(_tokenId) == address(this) ||
                Token.isApprovedForAll(seller, address(this)),
            "ERC721Marketplace: Broker Not approved"
        );

        // Get royality and creator
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            _erc721,
            _tokenId,
            price
        );
        {
            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_erc20Token].seller * price) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_erc20Token].buyer * price) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = price - royalty - brokerage_.seller;

            // Transfer funds for natice currency
            if (_erc20Token == address(0)) {
                require(
                    msg.value >= price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient Payment"
                );
                creator.transfer(royalty);
                payable(seller).transfer(sellerFund);
                broker.transfer(msg.value - royalty - sellerFund);
            }
            // Transfer the funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
                require(
                    erc20Token.allowance(msg.sender, address(this)) >=
                        price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient spent allowance "
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(msg.sender, creator, royalty);
                // transfer brokerage amount to broker
                erc20Token.transferFrom(
                    msg.sender,
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
                // transfer remaining  amount to Seller
                erc20Token.transferFrom(msg.sender, seller, sellerFund);
            }
        }
        Token.safeTransferFrom(seller, buyer, _tokenId);
        auctionNonceStatus[_nonce] = true;
        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            seller,
            buyer,
            price,
            buyer,
            1,
            block.timestamp,
            _erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    function putSaleOff(
        uint256 _tokenId,
        address _erc721,
        uint256 _nonce
    ) external tokenOwnerOnly(_tokenId, _erc721) {
        auctionNonceStatus[_nonce] = true;

        // OffSale event
        emit OffSale(_erc721, _tokenId, msg.sender, block.timestamp, _nonce);
        delete _auctions[_erc721][_tokenId];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function lazyMintAuction(
        sellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        bytes memory globalSign
    ) external nonReentrant erc20Allowed(_sellerVoucher.erc20Token) {
        // globalSignValidation
        {
            require(
                _sellerVoucher.erc20Token != address(0),
                "ERC721Marketplace: Must be ERC20 token address"
            );

            require(
                !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
                "ERC721Marketplace: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _sellerVoucher.to,
                    _sellerVoucher.royalty,
                    _sellerVoucher.tokenURI,
                    _sellerVoucher.nonce,
                    _sellerVoucher.erc721,
                    _sellerVoucher.startingPrice,
                    _sellerVoucher.startingTime,
                    _sellerVoucher.endingTime,
                    _sellerVoucher.erc20Token,
                    _buyerVoucher.buyer,
                    _buyerVoucher.time,
                    _buyerVoucher.amount
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(globalSign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _signer == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                _sellerVoucher.endingTime <= block.timestamp ||
                    msg.sender == _sellerVoucher.to,
                "ERC721Marketplace: Auction not over yet."
            );
        }

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[_sellerVoucher.erc20Token];

        uint256 buyingBrokerage = (brokerage_.buyer *
            _sellerVoucher.startingPrice) / (100 * decimalPrecision);

        require(
            _sellerVoucher.startingPrice + buyingBrokerage <=
                _buyerVoucher.amount,
            "ERC721Marketplace: Amount must include Buying Brokerage"
        );

        buyingBrokerage =
            (brokerage_.buyer * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        // Transfer the funds.
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _sellerVoucher.erc20Token
        );

        if (WETH == _sellerVoucher.erc20Token) {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage + mintingCharge
            );
        } else {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount,
                "Allowance is less than amount sent for bidding."
            );

            IERC20Upgradeable weth = IERC20Upgradeable(WETH);

            require(
                weth.allowance(_buyerVoucher.buyer, address(this)) >=
                    mintingCharge,
                "Allowance is less than minting charges"
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage
            );

            weth.transferFrom(_buyerVoucher.buyer, broker, mintingCharge);
        }

        erc20Token.transferFrom(
            _buyerVoucher.buyer,
            _sellerVoucher.to,
            _buyerVoucher.amount - (sellingBrokerage + buyingBrokerage)
        );

        IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
            _sellerVoucher.tokenURI,
            _sellerVoucher.royalty,
            _sellerVoucher.to,
            _buyerVoucher.buyer
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;

        emit LazyAuction(
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _sellerVoucher.erc721,
            _sellerVoucher.erc20Token,
            _buyerVoucher.amount,
            block.timestamp
        );
    }

    function acceptOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _bidder,
        IERC20Upgradeable _erc20Token,
        uint256 _nonce,
        bytes calldata _sign
    ) external nonReentrant tokenOwnerOnly(_tokenId, _erc721) {
        // Verify the signature.
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _tokenId,
                    _erc721,
                    _amount,
                    _validTill,
                    address(_erc20Token),
                    _nonce
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _bidder == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                address(_erc20Token) != address(0),
                "ERC721Marketplace: Native currencies are not supported for offers."
            );

            require(
                _validTill <= block.timestamp,
                "ERC721Marketplace: Offer expired."
            );

            require(
                !isOfferNonceProcessed[_nonce],
                "ERC721Marketplace: Offer is already processed."
            );
        }

        {
            _brokerage memory brokerage_;
            // IERC20Upgradeable erc20 = IERC20Upgradeable(_erc20Token);

            require(
                _erc20Token.allowance(_bidder, msg.sender) > _amount &&
                    _erc20Token.balanceOf(_bidder) > _amount,
                "ERC721Marketplace: Isufficient allowance or balance in bidder's account."
            );

            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _amount
            );

            brokerage_.seller =
                (brokerage[address(_erc20Token)].seller * _amount) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[address(_erc20Token)].buyer * _amount) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _amount -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            _erc20Token.transfer(creator, royalty);
            _erc20Token.transfer(msg.sender, sellerFund);
            _erc20Token.transfer(broker, brokerage_.seller + brokerage_.buyer);

            _amount -= brokerage_.buyer;
        }

        IERC721Mintable Token = IERC721Mintable(_erc721);

        require(
            Token.getApproved(_tokenId) == address(this) ||
                Token.isApprovedForAll(msg.sender, address(this)),
            "ERC721Marketplace: Broker Not approved"
        );
        // Transfer the NFT to Buyer
        Token.safeTransferFrom(msg.sender, _bidder, _tokenId);

        // Sold event
        emit OfferAccepted(
            _erc721,
            _tokenId,
            msg.sender,
            _bidder,
            _amount,
            block.timestamp,
            address(_erc20Token)
        );

        isOfferNonceProcessed[_nonce] = true;
    }

    function cancelOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _seller,
        address _erc20Token,
        uint256 _nonce,
        bytes calldata _sign
    ) external {
                // Verify the signature.
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _seller,
                    _tokenId,
                    _erc721,
                    _amount,
                    _validTill,
                    address(_erc20Token),
                    _nonce
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                msg.sender == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                !isOfferNonceProcessed[_nonce],
                "ERC721Marketplace: Offer is already processed."
            );
        }
        isOfferNonceProcessed[_nonce] = true;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Mintable is IERC721, IERC2981 {
    function mintingCharge() external view returns (uint256);

    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

    function broker() external view returns (address payable);

    function ecosystemContract(address) external view returns (bool);

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    function brokerage() external view returns (_brokerage calldata);

    function delegatedMint(
        string memory tokenURI,
        uint96 _royalty,
        address _to,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Mintable.sol";

contract UPYOERC721MarketPlaceV3 is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Storage

    //auction type :
    // 1 : only direct buy
    // 2 : only bid

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store auction details
    mapping(address => mapping(uint256 => auction)) _auctions;

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // address to transfer brokerage
    address payable public broker;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Mapping to manage nonce for lazy mint
    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // Platform's signer address
    address _signer;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    // WETH address
    address public WETH;

    // Mapping to store nonce status.
    mapping(uint256 => bool) public auctionNonceStatus;

    struct sellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 endingTime;
        address erc20Token;
    }

    struct buyerVoucher {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    // Events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        uint256 nonce
    );
    event LazyAuction(
        address seller,
        address buyer,
        address collection,
        address ERC20Address,
        uint256 price,
        uint256 time
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC721Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).seller != address(0),
            "ERC721Marketplace: Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _erc721) {
        require(
            block.timestamp < auctions(_erc721, _tokenId).closingTime,
            "ERC721Marketplace: Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 2,
            "ERC721Marketplace: Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 1,
            "ERC721Marketplace: Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _erc721) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_erc721).ownerOf(_tokenId) == msg.sender,
            "ERC721Marketplace: You must be owner and Token should not have any bid"
        );
        _;
    }

    // Getters
    function auctions(address _erc721, uint256 _tokenId)
        public
        view
        returns (auction memory)
    {
        address _owner = IERC721Mintable(_erc721).ownerOf(_tokenId);
        if (
            _owner == _auctions[_erc721][_tokenId].seller ||
            _owner == address(this)
        ) {
            return _auctions[_erc721][_tokenId];
        }
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function setSigner(address signer_) external onlyOwner {
        require(
            signer_ != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        _signer = signer_;
    }

    function setWETH(address _WETH) external onlyOwner {
        require(
            _WETH != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        WETH = _WETH;
    }

    function signer() external view onlyOwner returns (address) {
        return _signer;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    function bid(
        uint256 _tokenId,
        address _erc721,
        uint256 amount,
        address payable bidder,
        auction memory _auction,
        uint256 _nonce,
        bytes calldata sign
    ) external payable nonReentrant {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        {
            address seller = Token.ownerOf(_tokenId);

            if (auctionNonceStatus[_nonce]) {
                _auction = _auctions[_erc721][_tokenId];
                require(
                    _auction.seller != address(0) &&
                        (seller == _auction.seller || seller == address(this)),
                    "ERC721Marketplace: Token Not For Sale"
                );
            } else {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(
                        address(this),
                        _auction.seller,
                        _erc721, 
                        _tokenId,
                        _nonce,
                        _auction.startingPrice,
                        _auction.startingTime,
                        _auction.closingTime,
                        _auction.erc20Token
                    )
                );

                bytes32 signedMessageHash = keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        messageHash
                    )
                );
                (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

                address signer_ = ecrecover(signedMessageHash, v, r, s);

                require(signer_ == seller, "ERC721Marketplace: Invalid Sign");

                _auction.currentBid =
                    _auction.startingPrice +
                    (brokerage[_auction.erc20Token].buyer *
                        _auction.startingPrice) /
                    (100 * decimalPrecision);
                _auction.auctionType = 2;
            }
            require(
                block.timestamp >= _auction.startingTime &&
                    block.timestamp <= _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
            auctionNonceStatus[_nonce] = true;
        }

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "ERC721Marketplace: Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        if (Token.ownerOf(_tokenId) != address(this)) {
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        }
        _auction.highestBidder = bidder;

        _auctions[_erc721][_tokenId] = _auction;

        // Bid event
        emit Bid(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _erc721)
        external
        onSaleOnly(_tokenId, _erc721)
        auctionOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Only allow collect without finishing the auction only if admin collects it.
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "ERC721Marketplace: Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            // Get royality and seller
            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _auction.currentBid
            );

            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.currentBid -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            // Transfer funds for native currency
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(brokerage_.seller + brokerage_.buyer);
            }
            // Transfer funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(_auction.seller, sellerFund);
                erc20Token.transfer(
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
            }
            // Transfer the NFT to Buyer
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );

            // Sold event
            emit Sold(
                _erc721,
                _tokenId,
                _auction.seller,
                _auction.highestBidder,
                _auction.currentBid - brokerage_.buyer,
                msg.sender,
                _auction.auctionType,
                block.timestamp,
                _auction.erc20Token
            );
        }
        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address buyer
    ) external payable nonReentrant {
        require(
            !auctionNonceStatus[_nonce],
            "ERC721Marketplace: Nonce have been already processed."
        );
        IERC721Mintable Token = IERC721Mintable(_erc721);

        address seller = Token.ownerOf(_tokenId);

        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _tokenId,
                    _erc721,
                    price,
                    _nonce,
                    _erc20Token
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
        }

        require(
            Token.getApproved(_tokenId) == address(this) ||
                Token.isApprovedForAll(seller, address(this)),
            "ERC721Marketplace: Broker Not approved"
        );

        // Get royality and creator
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            _erc721,
            _tokenId,
            price
        );
        {
            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_erc20Token].seller * price) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_erc20Token].buyer * price) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = price - royalty - brokerage_.seller;

            // Transfer funds for natice currency
            if (_erc20Token == address(0)) {
                require(
                    msg.value >= price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient Payment"
                );
                creator.transfer(royalty);
                payable(seller).transfer(sellerFund);
                broker.transfer(msg.value - royalty - sellerFund);
            }
            // Transfer the funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
                require(
                    erc20Token.allowance(msg.sender, address(this)) >=
                        price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient spent allowance "
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(msg.sender, creator, royalty);
                // transfer brokerage amount to broker
                erc20Token.transferFrom(
                    msg.sender,
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
                // transfer remaining  amount to Seller
                erc20Token.transferFrom(msg.sender, seller, sellerFund);
            }
        }
        Token.safeTransferFrom(seller, buyer, _tokenId);
        auctionNonceStatus[_nonce] = true;
        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            seller,
            buyer,
            price,
            buyer,
            1,
            block.timestamp,
            _erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    function putSaleOff(
        uint256 _tokenId,
        address _erc721,
        uint256 _nonce
    ) external tokenOwnerOnly(_tokenId, _erc721) {
        auctionNonceStatus[_nonce] = true;

        // OffSale event
        emit OffSale(_erc721, _tokenId, msg.sender, block.timestamp, _nonce);
        delete _auctions[_erc721][_tokenId];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function lazyMintAuction(
        sellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        bytes memory globalSign
    ) external erc20Allowed(_sellerVoucher.erc20Token) {
        // globalSignValidation
        {
            require(
                _sellerVoucher.erc20Token != address(0),
                "ERC721Marketplace: Must be ERC20 token address"
            );

            require(
                !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
                "ERC721Marketplace: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _sellerVoucher.to,
                    _sellerVoucher.royalty,
                    _sellerVoucher.tokenURI,
                    _sellerVoucher.nonce,
                    _sellerVoucher.erc721,
                    _sellerVoucher.startingPrice,
                    _sellerVoucher.startingTime,
                    _sellerVoucher.endingTime,
                    _sellerVoucher.erc20Token,
                    _buyerVoucher.buyer,
                    _buyerVoucher.time,
                    _buyerVoucher.amount
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(globalSign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _signer == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                _sellerVoucher.endingTime <= block.timestamp ||
                    msg.sender == _sellerVoucher.to,
                "ERC721Marketplace: Auction not over yet."
            );
        }

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[_sellerVoucher.erc20Token];

        uint256 buyingBrokerage = (brokerage_.buyer *
            _sellerVoucher.startingPrice) / (100 * decimalPrecision);

        require(
            _sellerVoucher.startingPrice + buyingBrokerage <=
                _buyerVoucher.amount,
            "ERC721Marketplace: Amount must include Buying Brokerage"
        );

        buyingBrokerage =
            (brokerage_.buyer * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        // Transfer the funds.
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _sellerVoucher.erc20Token
        );

        if (WETH == _sellerVoucher.erc20Token) {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage + mintingCharge
            );
        } else {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount,
                "Allowance is less than amount sent for bidding."
            );

            IERC20Upgradeable weth = IERC20Upgradeable(WETH);

            require(
                weth.allowance(_buyerVoucher.buyer, address(this)) >=
                    mintingCharge,
                "Allowance is less than minting charges"
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage
            );

            weth.transferFrom(_buyerVoucher.buyer, broker, mintingCharge);
        }

        erc20Token.transferFrom(
            _buyerVoucher.buyer,
            _sellerVoucher.to,
            _buyerVoucher.amount - (sellingBrokerage + buyingBrokerage)
        );

        IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
            _sellerVoucher.tokenURI,
            _sellerVoucher.royalty,
            _sellerVoucher.to,
            _buyerVoucher.buyer
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;

        emit LazyAuction(
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _sellerVoucher.erc721,
            _sellerVoucher.erc20Token,
            _buyerVoucher.amount,
            block.timestamp
        );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Mintable.sol";

contract UPYOERC721MarketPlaceV2 is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Storage

    //auction type :
    // 1 : only direct buy
    // 2 : only bid

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store auction details
    mapping(address => mapping(uint256 => auction)) _auctions;

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // address to transfer brokerage
    address payable public broker;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Mapping to manage nonce for lazy mint
    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // Platform's signer address
    address _signer;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    // WETH address
    address public WETH;

    struct sellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 endingTime;
        address erc20Token;
    }

    struct buyerVoucher {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    // Events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );
    event LazyAuction(
        address seller,
        address buyer,
        address collection,
        address ERC20Address,
        uint256 price,
        uint256 time
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC721Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).seller != address(0),
            "ERC721Marketplace: Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _erc721) {
        require(
            block.timestamp < auctions(_erc721, _tokenId).closingTime,
            "ERC721Marketplace: Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 2,
            "ERC721Marketplace: Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 1,
            "ERC721Marketplace: Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _erc721) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_erc721).ownerOf(_tokenId) == msg.sender,
            "ERC721Marketplace: You must be owner and Token should not have any bid"
        );
        _;
    }

    // Getters
    function auctions(address _erc721, uint256 _tokenId)
        public
        view
        returns (auction memory)
    {
        address _owner = IERC721Mintable(_erc721).ownerOf(_tokenId);
        if (
            _owner == _auctions[_erc721][_tokenId].seller ||
            _owner == address(this)
        ) {
            return _auctions[_erc721][_tokenId];
        }
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function setSigner(address signer_) external onlyOwner {
        require(
            signer_ != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        _signer = signer_;
    }

    function setWETH(address _WETH) external onlyOwner {
        require(
            _WETH != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        WETH = _WETH;
    }

    function signer() external view onlyOwner returns (address) {
        return _signer;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    function bid(
        uint256 _tokenId,
        address _erc721,
        uint256 amount,
        address payable bidder
    )
        external
        payable
        onSaleOnly(_tokenId, _erc721)
        activeAuction(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);

        auction memory _auction = _auctions[_erc721][_tokenId];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "ERC721Marketplace: Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        if (Token.ownerOf(_tokenId) != address(this)) {
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        }
        _auction.highestBidder = bidder;

        _auctions[_erc721][_tokenId] = _auction;

        // Bid event
        emit Bid(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            //  =
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _erc721)
        external
        onSaleOnly(_tokenId, _erc721)
        auctionOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Only allow collect without finishing the auction only if admin collects it.
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "ERC721Marketplace: Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            // Get royality and seller
            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _auction.currentBid
            );

            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.currentBid -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            // Transfer funds for native currency
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(brokerage_.seller + brokerage_.buyer);
            }
            // Transfer funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(_auction.seller, sellerFund);
                erc20Token.transfer(
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
            }
            // Transfer the NFT to Buyer
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );

            // Sold event
            emit Sold(
                _erc721,
                _tokenId,
                _auction.seller,
                _auction.highestBidder,
                _auction.currentBid - brokerage_.buyer,
                msg.sender,
                _auction.auctionType,
                block.timestamp,
                _auction.erc20Token
            );
        }
        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buy(
        uint256 _tokenId,
        address _erc721,
        address buyer
    )
        external
        payable
        onSaleOnly(_tokenId, _erc721)
        flatSaleOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Get royality and creator
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            _erc721,
            _tokenId,
            _auction.startingPrice
        );
        {
            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller *
                    _auction.startingPrice) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer *
                    _auction.startingPrice) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.startingPrice -
                royalty -
                brokerage_.seller;

            // Transfer funds for natice currency
            if (_auction.erc20Token == address(0)) {
                require(
                    msg.value >= _auction.startingPrice + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient Payment"
                );
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(msg.value - royalty - sellerFund);
            }
            // Transfer the funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                require(
                    erc20Token.allowance(msg.sender, address(this)) >=
                        _auction.startingPrice + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient spent allowance "
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(msg.sender, creator, royalty);
                // transfer brokerage amount to broker
                erc20Token.transferFrom(
                    msg.sender,
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
                // transfer remaining  amount to Seller
                erc20Token.transferFrom(
                    msg.sender,
                    _auction.seller,
                    sellerFund
                );
            }
        }
        Token.safeTransferFrom(_auction.seller, buyer, _tokenId);

        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            _auction.seller,
            buyer,
            _auction.startingPrice,
            buyer,
            _auction.auctionType,
            block.timestamp,
            _auction.erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    function putOnSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _startingTime,
        uint256 _endindTime,
        address _erc721,
        address _erc20Token
    ) external erc20Allowed(_erc20Token) tokenOwnerOnly(_tokenId, _erc721) {
        // Scope to overcome "Stack too deep error"
        {
            IERC721Mintable Token = IERC721Mintable(_erc721);

            require(
                Token.getApproved(_tokenId) == address(this) ||
                    Token.isApprovedForAll(msg.sender, address(this)),
                "ERC721Marketplace: Broker Not approved"
            );
            require(
                _startingTime < _endindTime,
                "ERC721Marketplace: Ending time must be grater than Starting time"
            );
        }
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (_auction.seller != address(0) && _auction.auctionType == 2) {
            require(
                _auction.highestBidder == address(0) &&
                    block.timestamp > _auction.closingTime,
                "ERC721Marketplace: This NFT is already on sale."
            );
        }

        auction memory newAuction = auction(
            payable(msg.sender),
            _startingPrice +
                (brokerage[_erc20Token].buyer * _startingPrice) /
                (100 * decimalPrecision),
            payable(address(0)),
            _auctionType,
            _startingPrice,
            _startingTime,
            _endindTime,
            _erc20Token
        );

        _auctions[_erc721][_tokenId] = newAuction;

        // OnSale event
        emit OnSale(
            _erc721,
            _tokenId,
            msg.sender,
            _auctionType,
            _startingPrice,
            block.timestamp,
            _erc20Token
        );
    }

    function updatePrice(
        uint256 _tokenId,
        address _erc721,
        uint256 _newPrice,
        address _erc20Token
    )
        external
        onSaleOnly(_tokenId, _erc721)
        erc20Allowed(_erc20Token)
        tokenOwnerOnly(_tokenId, _erc721)
    {
        auction memory _auction = _auctions[_erc721][_tokenId];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.auctionType,
            _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        _auction.startingPrice = _newPrice;
        if (_auction.auctionType == 2) {
            _auction.currentBid =
                _newPrice +
                (brokerage[_erc20Token].buyer * _newPrice) /
                (100 * decimalPrecision);
        }
        _auction.erc20Token = _erc20Token;
        _auctions[_erc721][_tokenId] = _auction;
    }

    function putSaleOff(uint256 _tokenId, address _erc721)
        external
        tokenOwnerOnly(_tokenId, _erc721)
    {
        auction memory _auction = _auctions[_erc721][_tokenId];

        // OffSale event
        emit OffSale(
            _erc721,
            _tokenId,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );
        delete _auctions[_erc721][_tokenId];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function lazyMintAuction(
        sellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        bytes memory globalSign
    ) external erc20Allowed(_sellerVoucher.erc20Token) {
        // globalSignValidation
        {
            require(
                _sellerVoucher.erc20Token != address(0),
                "ERC721Marketplace: Must be ERC20 token address"
            );

            require(
                !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
                "ERC721Marketplace: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _sellerVoucher.to,
                    _sellerVoucher.royalty,
                    _sellerVoucher.tokenURI,
                    _sellerVoucher.nonce,
                    _sellerVoucher.erc721,
                    _sellerVoucher.startingPrice,
                    _sellerVoucher.startingTime,
                    _sellerVoucher.endingTime,
                    _sellerVoucher.erc20Token,
                    _buyerVoucher.buyer,
                    _buyerVoucher.time,
                    _buyerVoucher.amount
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(globalSign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _signer == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                _sellerVoucher.endingTime <= block.timestamp ||
                    msg.sender == _sellerVoucher.to,
                "ERC721Marketplace: Auction not over yet."
            );
        }

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[_sellerVoucher.erc20Token];

        uint256 buyingBrokerage = (brokerage_.buyer *
            _sellerVoucher.startingPrice) / (100 * decimalPrecision);

        require(
            _sellerVoucher.startingPrice + buyingBrokerage <=
                _buyerVoucher.amount,
            "ERC721Marketplace: Amount must include Buying Brokerage"
        );

        buyingBrokerage =
            (brokerage_.buyer * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        // Transfer the funds.
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _sellerVoucher.erc20Token
        );

        if (WETH == _sellerVoucher.erc20Token) {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage + mintingCharge
            );
        } else {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount,
                "Allowance is less than amount sent for bidding."
            );

            IERC20Upgradeable weth = IERC20Upgradeable(WETH);

            require(
                weth.allowance(_buyerVoucher.buyer, address(this)) >=
                    mintingCharge,
                "Allowance is less than minting charges"
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage
            );

            weth.transferFrom(_buyerVoucher.buyer, broker, mintingCharge);
        }

        erc20Token.transferFrom(
            _buyerVoucher.buyer,
            _sellerVoucher.to,
            _buyerVoucher.amount - (sellingBrokerage + buyingBrokerage)
        );

        IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
            _sellerVoucher.tokenURI,
            _sellerVoucher.royalty,
            _sellerVoucher.to,
            _buyerVoucher.buyer
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;

        emit LazyAuction(
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _sellerVoucher.erc721,
            _sellerVoucher.erc20Token,
            _buyerVoucher.amount,
            block.timestamp
        );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC1155BaseUpgradeable is
    OwnableUpgradeable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC2981Upgradeable
{
    // Royalty limit to capped royities while minting.
    uint96 public royaltyLimit;

    // tokenId counter
    uint256 counter;

    // Mapping to manage nonce for lazy mint
    mapping(uint256 => uint256) public nonceToTokenId;

    // Mapping for whitelist users
    mapping(address => bool) public whitelistedUsers;

    struct tokenDetail {
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 totalSupply;
        string uri;
    }

    mapping(uint256 => tokenDetail) public tokenDetails;

    bool public openForAll;

    string public baseURI;

    function __ERC1155BaseUpgradeable(
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit // Max Royalty limit for collection
    ) internal onlyInitializing {
        __ERC1155_init("");
        __Ownable_init();
        __ERC1155Burnable_init();
        __ERC2981_init();
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC1155BaseUpgradeable: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
        baseURI = _tokenURIPrefix;
        openForAll = true;
    }

    modifier whitelistCheck(address user) {
        require(
            whitelistedUsers[user] || owner() == user || openForAll,
            "ERC1155BaseUpgradeable: Whitelisted users only."
        );
        _;
    }

    function toggleOpenForAll() external onlyOwner {
        openForAll = !openForAll;
    }

    function whitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = true;
        }
    }

    function removeWhitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = false;
        }
    }

    // Method to set Max royalty for collection
    function setRoyaltyLimit(uint96 _royaltyLimit) external onlyOwner {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC1155BaseUpgradeable: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
    }

    // internal method to mint the nft
    function _mint(
        address to,
        uint256 amount,
        uint96 royalty,
        string memory _tokenURI
    ) internal virtual whitelistCheck(to) returns (uint256) {
        require(
            royalty <= royaltyLimit,
            "ERC1155BaseUpgradeable: Royalty must be below royalty limit"
        );
        counter++;
        super._mint(to, counter, amount, bytes(""));
        _setTokenRoyalty(counter, to, royalty);
        tokenDetails[counter] = tokenDetail(amount, amount, amount, _tokenURI);
        return counter;
    }

    function _lazyMint(
        address to,
        uint96 royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        uint256 _maxSupply,
        uint256 amount,
        bytes memory sign,
        address buyer
    ) internal whitelistCheck(to) returns (uint256) {
        // Verfify signature
        {
            bytes32 signedMessageHash;
            {
                bytes32 messageHash = keccak256(
                    abi.encodePacked(
                        address(this),
                        royalty,
                        nonce,
                        _tokenURI,
                        price,
                        _maxSupply
                    )
                );

                signedMessageHash = keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        messageHash
                    )
                );
            }
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            require(
                to == ecrecover(signedMessageHash, v, r, s),
                "ERC1155BaseUpgradeable: Signature not verfied."
            );
        }

        // tokenDetail
        tokenDetail memory _tokenDetail;
        uint256 tokenId;

        // Get existing details
        if (isNonceProcessed(nonce)) {
            tokenId = nonceToTokenId[nonce];
            _tokenDetail = tokenDetails[tokenId];
        } else {
            require(
                royalty <= royaltyLimit,
                "ERC1155BaseUpgradeable: Royalty must be below royalty limit"
            );
            // Create new token.
            counter++;
            tokenId = counter;
            _tokenDetail = tokenDetail(_maxSupply, 0, 0, _tokenURI);
            _setTokenRoyalty(tokenId, to, royalty);
        }
        require(
            _tokenDetail.totalMinted + amount <= _tokenDetail.maxSupply,
            "ERC1155BaseUpgradeable: Max supply exceeded for this token"
        );

        // mint new token
        super._mint(to, tokenId, amount, bytes(""));

        // update token details
        _tokenDetail.totalMinted += amount;
        _tokenDetail.totalSupply += amount;
        tokenDetails[tokenId] = _tokenDetail;

        // transfer the NFT to buyer
        _safeTransferFrom(to, buyer, tokenId, amount, bytes(""));
        return tokenId;
    }

    // Method to check if nonce is processed
    function isNonceProcessed(uint256 nonce) public view returns (bool) {
        return nonceToTokenId[nonce] > 0;
    }

    // Method to get totalSupply of NFT
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].totalSupply;
    }

    // Method to get MaxSupply of NFT
    function maxSupply(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].maxSupply;
    }

    // Method to get totalMinted of NFT
    function totalMinted(uint256 tokenId) external view returns (uint256) {
        return tokenDetails[tokenId].totalMinted;
    }

    // Method to check if NFT exists
    function exists(uint256 tokenId) external view returns (bool) {
        return tokenDetails[tokenId].totalSupply > 0;
    }

    // Method to get token uri
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenDetails[tokenId].uri));
    }

    // Method to withdraw Native currency
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Method to withdraw ERC20 in this contract
    function withdrawERC20(address _erc20) external onlyOwner {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    // Fallback method
    fallback() external payable {}

    // Fallback method
    receive() external payable {}

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                tokenDetails[ids[i]].totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                tokenDetails[ids[i]].totalSupply -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155BaseUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";



contract UPYOERC1155Mintable is ERC1155BaseUpgradeable, UUPSUpgradeable {
    // Metadata:
    string private _name;
    string private _symbol;
    string private _contractURI;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingChargePerToken;

    address payable public broker;

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    _brokerage public brokerage;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Method to set minting charges per NFT
    function setMintingChargePerToken(uint256 _mintingCharge) external onlyOwner {
        mintingChargePerToken = _mintingCharge;
    }


    // Method to set minting charges per NFT
    function setBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    // Method to set minting charges per NFT
    function setBrokerage(_brokerage calldata brokerage_) external onlyOwner {
        require(
            brokerage_.buyer <= 100 * decimalPrecision &&
                brokerage_.seller <= 100 * decimalPrecision,
            "UPYOERC721Mintable: Brokerage can't be more than 100%"
        );
        brokerage = brokerage_;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit, // Max Royalty limit for collection
        uint256 _mintingChargePerToken, // Minting charges for collection
        address payable _broker, // Broker address
        _brokerage calldata brokerage_
    ) external initializer {
        __UUPSUpgradeable_init();
        __ERC1155BaseUpgradeable(_tokenURIPrefix, _royaltyLimit);
        mintingChargePerToken = _mintingChargePerToken;
        brokerage = brokerage_;
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
        broker = _broker;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_)
        external
        virtual
        onlyOwner
    {
        _contractURI = contractURI_;
    }

    function mint(
        string memory tokenURI,
        uint96 _royalty,
        uint256 amount,
        address _to
    ) external payable returns (uint){
        require(
            msg.value >= mintingChargePerToken * amount,
            "ERC1155Mintable: Minting charges required"
        );
        uint tokenId = _mint(_to, amount, _royalty, tokenURI);
        broker.transfer(msg.value);
        return tokenId;
    }

    function lazyMint(
        address to,
        uint96 royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        uint256 _maxSupply,
        uint256 amount,
        bytes memory sign,
        address buyer
    ) external payable returns(uint){
        uint256 buyingBrokerage = (brokerage.buyer * price) /
            (100 * decimalPrecision);
        require(
            msg.value >= (price + mintingChargePerToken + buyingBrokerage) * amount,
            "ERC1155Mintable: Insufficent fund transferred."
        );
        uint tokenId = _lazyMint(
            to,
            royalty,
            _tokenURI,
            nonce,
            price,
            _maxSupply,
            amount,
            sign, 
            buyer
        );
        uint256 sellingBrokerage = (brokerage.seller * price) /
            (100 * decimalPrecision);
        uint sellerFund = (price - sellingBrokerage) * amount;
        payable(to).transfer(sellerFund);
        broker.transfer(msg.value - sellerFund);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC721Mintable.sol";

contract UPYOERC721MarketPlace is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Storage

    //auction type :
    // 1 : only direct buy
    // 2 : only bid

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store auction details
    mapping(address => mapping(uint256 => auction)) _auctions;

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // address to transfer brokerage
    address payable public broker;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // Mapping to manage nonce for lazy mint
    mapping(address => mapping(uint256 => bool)) public isNonceProcessed;

    // Platform's signer address
    address _signer;

    // mintingCharges in wei, Will be controlled by owner
    uint256 public mintingCharge;

    // WETH address
    address public WETH;

    struct sellerVoucher {
        address to;
        uint96 royalty;
        string tokenURI;
        uint256 nonce;
        address erc721;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 endingTime;
        address erc20Token;
    }

    struct buyerVoucher {
        address buyer;
        uint256 amount;
        uint256 time;
    }

    // Events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );
    event LazyAuction(
        address seller,
        address buyer,
        address collection,
        address ERC20Address,
        uint256 price,
        uint256 time
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC721Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).seller != address(0),
            "ERC721Marketplace: Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _erc721) {
        require(
            block.timestamp < auctions(_erc721, _tokenId).closingTime,
            "ERC721Marketplace: Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 2,
            "ERC721Marketplace: Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _erc721) {
        require(
            auctions(_erc721, _tokenId).auctionType == 1,
            "ERC721Marketplace: Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _erc721) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_erc721).ownerOf(_tokenId) == msg.sender,
            "ERC721Marketplace: You must be owner and Token should not have any bid"
        );
        _;
    }

    // Getters
    function auctions(address _erc721, uint256 _tokenId)
        public
        view
        returns (auction memory)
    {
        address _owner = IERC721Mintable(_erc721).ownerOf(_tokenId);
        if (
            _owner == _auctions[_erc721][_tokenId].seller ||
            _owner == address(this)
        ) {
            return _auctions[_erc721][_tokenId];
        }
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function setSigner(address signer_) external onlyOwner {
        require(
            signer_ != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        _signer = signer_;
    }

    function setWETH(address _WETH) external onlyOwner {
        require(
            _WETH != address(0),
            "ERC721MarketPlace: Signer can't be null address"
        );
        WETH = _WETH;
    }

    function signer() external view onlyOwner returns (address) {
        return _signer;
    }

    // Method to set minting charges per NFT
    function setMintingCharge(uint256 _mintingCharge) external onlyOwner {
        mintingCharge = _mintingCharge;
    }

    function bid(
        uint256 _tokenId,
        address _erc721,
        uint256 amount,
        address payable bidder
    )
        external
        payable
        onSaleOnly(_tokenId, _erc721)
        activeAuction(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);

        auction memory _auction = _auctions[_erc721][_tokenId];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "ERC721Marketplace: Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        if (Token.ownerOf(_tokenId) != address(this)) {
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        }
        _auction.highestBidder = bidder;

        _auctions[_erc721][_tokenId] = _auction;

        // Bid event
        emit Bid(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            //  =
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _erc721)
        external
        onSaleOnly(_tokenId, _erc721)
        auctionOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Only allow collect without finishing the auction only if admin collects it.
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "ERC721Marketplace: Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            // Get royality and seller
            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _auction.currentBid
            );

            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer * _auction.currentBid) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.currentBid -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            // Transfer funds for native currency
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(brokerage_.seller + brokerage_.buyer);
            }
            // Transfer funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(_auction.seller, sellerFund);
                erc20Token.transfer(
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
            }
            // Transfer the NFT to Buyer
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );

            // Sold event
            emit Sold(
                _erc721,
                _tokenId,
                _auction.seller,
                _auction.highestBidder,
                _auction.currentBid - brokerage_.buyer,
                msg.sender,
                _auction.auctionType,
                block.timestamp,
                _auction.erc20Token
            );
        }
        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function buy(
        uint256 _tokenId,
        address _erc721,
        address buyer
    )
        external
        payable
        onSaleOnly(_tokenId, _erc721)
        flatSaleOnly(_tokenId, _erc721)
        nonReentrant
    {
        IERC721Mintable Token = IERC721Mintable(_erc721);
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Get royality and creator
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            _erc721,
            _tokenId,
            _auction.startingPrice
        );
        {
            _brokerage memory brokerage_;

            brokerage_.seller =
                (brokerage[_auction.erc20Token].seller *
                    _auction.startingPrice) /
                (100 * decimalPrecision);

            // Calculate Brokerage
            brokerage_.buyer =
                (brokerage[_auction.erc20Token].buyer *
                    _auction.startingPrice) /
                (100 * decimalPrecision);

            // Calculate seller fund
            uint256 sellerFund = _auction.startingPrice -
                royalty -
                brokerage_.seller;

            // Transfer funds for natice currency
            if (_auction.erc20Token == address(0)) {
                require(
                    msg.value >= _auction.startingPrice + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient Payment"
                );
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(msg.value - royalty - sellerFund);
            }
            // Transfer the funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                require(
                    erc20Token.allowance(msg.sender, address(this)) >=
                        _auction.startingPrice + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient spent allowance "
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(msg.sender, creator, royalty);
                // transfer brokerage amount to broker
                erc20Token.transferFrom(
                    msg.sender,
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
                // transfer remaining  amount to Seller
                erc20Token.transferFrom(
                    msg.sender,
                    _auction.seller,
                    sellerFund
                );
            }
        }
        Token.safeTransferFrom(_auction.seller, buyer, _tokenId);

        // Sold event
        emit Sold(
            _erc721,
            _tokenId,
            _auction.seller,
            buyer,
            _auction.startingPrice,
            buyer,
            _auction.auctionType,
            block.timestamp,
            _auction.erc20Token
        );

        // Delete the auction
        delete _auctions[_erc721][_tokenId];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    function putOnSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _startingTime,
        uint256 _endindTime,
        address _erc721,
        address _erc20Token
    ) external erc20Allowed(_erc20Token) tokenOwnerOnly(_tokenId, _erc721) {
        // Scope to overcome "Stack too deep error"
        {
            IERC721Mintable Token = IERC721Mintable(_erc721);

            require(
                Token.getApproved(_tokenId) == address(this) ||
                    Token.isApprovedForAll(msg.sender, address(this)),
                "ERC721Marketplace: Broker Not approved"
            );
            require(
                _startingTime < _endindTime,
                "ERC721Marketplace: Ending time must be grater than Starting time"
            );
        }
        auction memory _auction = _auctions[_erc721][_tokenId];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (_auction.seller != address(0) && _auction.auctionType == 2) {
            require(
                _auction.highestBidder == address(0) &&
                    block.timestamp > _auction.closingTime,
                "ERC721Marketplace: This NFT is already on sale."
            );
        }

        auction memory newAuction = auction(
            payable(msg.sender),
            _startingPrice +
                (brokerage[_erc20Token].buyer * _startingPrice) /
                (100 * decimalPrecision),
            payable(address(0)),
            _auctionType,
            _startingPrice,
            _startingTime,
            _endindTime,
            _erc20Token
        );

        _auctions[_erc721][_tokenId] = newAuction;

        // OnSale event
        emit OnSale(
            _erc721,
            _tokenId,
            msg.sender,
            _auctionType,
            _startingPrice,
            block.timestamp,
            _erc20Token
        );
    }

    function updatePrice(
        uint256 _tokenId,
        address _erc721,
        uint256 _newPrice,
        address _erc20Token
    )
        external
        onSaleOnly(_tokenId, _erc721)
        erc20Allowed(_erc20Token)
        tokenOwnerOnly(_tokenId, _erc721)
    {
        auction memory _auction = _auctions[_erc721][_tokenId];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "ERC721Marketplace: Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _erc721,
            _tokenId,
            _auction.seller,
            _auction.auctionType,
            _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        _auction.startingPrice = _newPrice;
        if (_auction.auctionType == 2) {
            _auction.currentBid =
                _newPrice +
                (brokerage[_erc20Token].buyer * _newPrice) /
                (100 * decimalPrecision);
        }
        _auction.erc20Token = _erc20Token;
        _auctions[_erc721][_tokenId] = _auction;
    }

    function putSaleOff(uint256 _tokenId, address _erc721)
        external
        tokenOwnerOnly(_tokenId, _erc721)
    {
        auction memory _auction = _auctions[_erc721][_tokenId];

        // OffSale event
        emit OffSale(
            _erc721,
            _tokenId,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );
        delete _auctions[_erc721][_tokenId];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function lazyMintAuction(
        sellerVoucher memory _sellerVoucher,
        buyerVoucher memory _buyerVoucher,
        bytes memory globalSign
    ) external erc20Allowed(_sellerVoucher.erc20Token) {
        // globalSignValidation
        {
            require(
                _sellerVoucher.erc20Token != address(0),
                "ERC721Marketplace: Must be ERC20 token address"
            );

            require(
                !isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce],
                "ERC721Marketplace: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _sellerVoucher.to,
                    _sellerVoucher.royalty,
                    _sellerVoucher.tokenURI,
                    _sellerVoucher.nonce,
                    _sellerVoucher.erc721,
                    _sellerVoucher.startingPrice,
                    _sellerVoucher.startingTime,
                    _sellerVoucher.endingTime,
                    _sellerVoucher.erc20Token,
                    _buyerVoucher.buyer,
                    _buyerVoucher.time,
                    _buyerVoucher.amount
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(globalSign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _signer == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                _sellerVoucher.endingTime <= block.timestamp ||
                    msg.sender == _sellerVoucher.to,
                "ERC721Marketplace: Auction not over yet."
            );
        }

        // Calculating brokerage and validation
        _brokerage memory brokerage_ = brokerage[_sellerVoucher.erc20Token];

        uint256 buyingBrokerage = (brokerage_.buyer *
            _sellerVoucher.startingPrice) / (100 * decimalPrecision);

        require(
            _sellerVoucher.startingPrice + buyingBrokerage <=
                _buyerVoucher.amount,
            "ERC721Marketplace: Amount must include Buying Brokerage"
        );

        buyingBrokerage =
            (brokerage_.buyer * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        uint256 sellingBrokerage = (brokerage_.seller * _buyerVoucher.amount) /
            (100 * decimalPrecision);

        // Transfer the funds.
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _sellerVoucher.erc20Token
        );

        if (WETH == _sellerVoucher.erc20Token) {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage + mintingCharge
            );
        } else {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount,
                "Allowance is less than amount sent for bidding."
            );

            IERC20Upgradeable weth = IERC20Upgradeable(WETH);

            require(
                weth.allowance(_buyerVoucher.buyer, address(this)) >=
                    mintingCharge,
                "Allowance is less than minting charges"
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage
            );

            weth.transferFrom(_buyerVoucher.buyer, broker, mintingCharge);
        }

        erc20Token.transferFrom(
            _buyerVoucher.buyer,
            _sellerVoucher.to,
            _buyerVoucher.amount - (sellingBrokerage + buyingBrokerage)
        );

        IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
            _sellerVoucher.tokenURI,
            _sellerVoucher.royalty,
            _sellerVoucher.to,
            _buyerVoucher.buyer
        );

        isNonceProcessed[_sellerVoucher.erc721][_sellerVoucher.nonce] = true;

        emit LazyAuction(
            _sellerVoucher.to,
            _buyerVoucher.buyer,
            _sellerVoucher.erc721,
            _sellerVoucher.erc20Token,
            _buyerVoucher.amount,
            block.timestamp
        );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC1155Mintable.sol";

contract UPYOERC1155Marketplace is
    Initializable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable
{
    // Sale details
    struct auction {
        uint256 quantity;
        uint256 price;
        address erc20;
    }

    // Master data strcture
    /**
     Master data structure explaination
     {
        ERC1155Address: {
            TokenID: {
                Seller: SellDetalis
            }
        }
     }
     */
    mapping(address => mapping(uint256 => mapping(address => auction)))
        public _auctions;

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    // Mapping to store list of allowed tokens
    mapping(address => bool) public tokenAllowed;

    // Mapping to store the brokerage
    mapping(address => _brokerage) public brokerage;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    // address to transfer brokerage
    address payable public broker;

    // events
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 quantity,
        uint256 time,
        bool onOffer,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    // Modifiers
    modifier erc20Allowed(address _erc20Token) {
        require(
            tokenAllowed[_erc20Token],
            "ERC1155Marketplace: ERC20 not allowed"
        );
        _;
    }

    modifier isSufficientNFTOnAuction(
        address _erc1155,
        uint256 _tokenId,
        address payable _seller,
        uint256 _quantity
    ) {
        require(
            _auctions[_erc1155][_tokenId][_seller].quantity >= _quantity,
            "ERC1155Marketplace: Not Enough NFT on auction"
        );
        _;
    }

    function addERC20TokenPayment(
        address _erc20Token,
        _brokerage calldata brokerage_
    ) external onlyOwner {
        tokenAllowed[_erc20Token] = true;
        brokerage[_erc20Token] = brokerage_;
    }

    function updateBroker(address payable _broker) external onlyOwner {
        broker = _broker;
    }

    function removeERC20TokenPayment(address _erc20Token)
        external
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        tokenAllowed[_erc20Token] = false;
        delete brokerage[_erc20Token];
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address _erc20Token, uint256 amount)
        external
        onlyOwner
    {
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, amount);
    }

    /**
     Funtion to check if it have active auction or not
     */
    function haveActiveSell(
        address _erc1155,
        uint256 _tokenId,
        address _seller
    ) external view returns (bool) {
        return _auctions[_erc1155][_tokenId][_seller].quantity > 0;
    }

    function putOnSale(
        address _erc1155,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _erc20
    ) external erc20Allowed(_erc20) {
        IERC1155Mintable collection = IERC1155Mintable(_erc1155);
        // Check if broker approved
        require(
            collection.isApprovedForAll(msg.sender, address(this)),
            "ERC1155Marketplace: Broker Not approved"
        );

        // Check if seller have sufficient assets to put on sale.
        require(
            collection.balanceOf(msg.sender, _tokenId) >= _quantity,
            "ERC1155Marketplace: Seller don't have sufficient copies to put on sale"
        );

        auction storage _auction = _auctions[_erc1155][_tokenId][msg.sender];

        _auction.quantity = _quantity;
        _auction.price = _price;
        _auction.erc20 = _erc20;

        // OnSale event
        emit OnSale(
            _erc1155,
            _tokenId,
            msg.sender,
            _price,
            _quantity,
            block.timestamp,
            _auction.erc20
        );
    }

    function _getCreatorAndRoyalty(
        IERC1155Mintable collection,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable creator, uint256 royalty) {
        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = payable(receiver);
            royalty = royaltyAmount;
        } catch {
            //  =
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
    }

    function _transferNFTs(
        IERC1155Mintable collection,
        uint256 _tokenId,
        uint256 price,
        address erc20Token,
        uint256 _quantity,
        address payable _seller,
        address buyer
    ) private {
        // Get creator and royalty
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            collection,
            _tokenId,
            price * _quantity
        );

        _brokerage memory brokerage_;

        brokerage_.seller =
            (brokerage[erc20Token].seller * price) /
            (100 * decimalPrecision);

        // Calculate Brokerage
        brokerage_.buyer =
            (brokerage[erc20Token].buyer * price) /
            (100 * decimalPrecision);

        uint256 seller_fund = ((price - brokerage_.buyer - brokerage_.seller) *
            _quantity) - royalty;

        // Transfer the funds
        if (erc20Token == address(0)) {
            require(
                msg.value >= (price + brokerage_.buyer) * _quantity,
                "ERC1155Marketplace: Insufficient Payment"
            );
            // Transfer the fund to creator if royalty available
            if (royalty > 0 && creator != payable(address(0))) {
                creator.transfer(royalty);
            } else {
                royalty = 0;
            }
            _seller.transfer(seller_fund);
            broker.transfer(msg.value - seller_fund - royalty);
        } else {
            IERC20 erc20 = IERC20(erc20Token);
            require(
                erc20.allowance(msg.sender, address(this)) >=
                    (price + brokerage_.buyer) * _quantity,
                "ERC1155Marketplace: Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            if (royalty > 0 && creator != payable(address(0))) {
                erc20.transferFrom(msg.sender, creator, royalty);
                royalty = 0;
            }
            // transfer brokerage amount to broker
            erc20.transferFrom(
                msg.sender,
                broker,
                ((brokerage_.seller + brokerage_.buyer) * price) + royalty
            );
            // transfer remaining  amount to lastOwner
            erc20.transferFrom(msg.sender, _seller, seller_fund);
        }

        collection.safeTransferFrom(
            _seller,
            buyer,
            _tokenId,
            _quantity,
            bytes("")
        );
    }

    function _buy(
        address _erc1155,
        uint256 _tokenId,
        address payable _seller,
        uint256 _quantity,
        address buyer
    ) private {
        // Get Objects
        auction storage _auction = _auctions[_erc1155][_tokenId][_seller];
        IERC1155Mintable collection = IERC1155Mintable(_erc1155);
        // Check if the requested quantity if available for sale
        require(
            _auction.quantity >= _quantity,
            "ERC1155Marketplace: Requested quantity not available for sale"
        );

        uint256 price = _auction.price;
        address erc20Token = _auction.erc20;

        // Complete the transfer process
        _transferNFTs(
            collection,
            _tokenId,
            price,
            erc20Token,
            _quantity,
            _seller,
            buyer
        );

        // Update the Auction details if more items left for sale.
        if (_auction.quantity > _quantity) {
            _auction.quantity -= _quantity;
        } else {
            // Delete auction if no items left for sale.
            delete _auctions[_erc1155][_tokenId][_seller];
        }

        // Buy event
        emit Sold(
            _erc1155,
            _tokenId,
            _seller,
            buyer,
            price,
            _quantity,
            block.timestamp,
            false,
            erc20Token
        );
    }

    function buy(
        address _erc1155,
        uint256 _tokenId,
        address payable _seller,
        uint256 _quantity,
        address buyer
    ) external payable {
        _buy(_erc1155, _tokenId, _seller, _quantity, buyer);
    }

    function batchBuy(
        address _erc1155,
        uint256 _tokenId,
        address payable[] memory _sellers,
        uint256[] memory _quantities,
        address buyer
    ) external payable {
        require(
            _sellers.length == _quantities.length,
            "ERC1155Marketplace: Seller's list and Quantities list must be same"
        );
        for (uint256 i = 0; i < _sellers.length; i++) {
            _buy(_erc1155, _tokenId, _sellers[i], _quantities[i], buyer);
        }
    }

    function putOffSale(address _erc1155, uint256 _tokenId) external {
        // Reset the auction
        delete _auctions[_erc1155][_tokenId][msg.sender];
    }

    function initialize(address payable _broker) public initializer {
        broker = _broker;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721Base is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Royalty,
    ERC721URIStorage,
    Ownable
{
    // Royalty limit to capped royities while minting.
    uint96 public royaltyLimit;

    // contractURI
    string public contractURI;

    // _base URI
    string baseURI_;

    // tokenId counter
    uint256 counter = 0;

    // Mapping to manage nonce for lazy mint
    mapping(uint256 => bool) public isNonceProcessed;

    // Mapping for whitelist users
    mapping(address => bool) public whitelistedUsers;

    bool public openForAll = false;

    constructor(
        string memory _name, // Name of collection
        string memory _symbol, // Symbol of collection
        string memory _contractURI, // Metadata of collection
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit // Max Royalty limit for collection
    ) ERC721(_name, _symbol) {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC721Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
        contractURI = _contractURI;
        baseURI_ = _tokenURIPrefix;
    }

    modifier whitelistCheck(address user) {
        require(
            whitelistedUsers[user] || owner() == user || openForAll,
            "ERC721Base: Whitelisted users only."
        );
        _;
    }

    function toggleOpenForAll() external onlyOwner {
        openForAll = !openForAll;
    }

    function whitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = true;
        }
    }

    function removeWhitelistUsers(address[] memory users) external onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers[users[index]] = false;
        }
    }

    // Method to set Max royalty for collection
    function setRoyaltyLimit(uint96 _royaltyLimit) external onlyOwner {
        require(
            _royaltyLimit <= _feeDenominator(),
            "ERC721Base: Royalty limit must be below 100%"
        );
        royaltyLimit = _royaltyLimit;
    }

    function _mint(
        address to,
        uint96 _royalty,
        string memory _tokenURI
    ) internal whitelistCheck(to) returns (uint256) {
        require(
            _royalty <= royaltyLimit,
            "ERC721Base: Royalty must be below royalty limit"
        );
        counter++;
        _mint(to, counter);
        _setTokenRoyalty(counter, to, _royalty);
        _setTokenURI(counter, _tokenURI);
        return counter;
    }

    function _lazyMint(
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign,
        address buyer
    ) internal whitelistCheck(to) returns (uint256) {
        {
            require(
                !isNonceProcessed[nonce],
                "ERC721Base: Nonce already processed"
            );

            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _royalty,
                    nonce,
                    _tokenURI,
                    price
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(to == signer_, "ERC721Base: Signature not verfied.");
        }
        uint256 tokenId = _mint(to, _royalty, _tokenURI);
        _transfer(to, buyer, tokenId);
        isNonceProcessed[nonce] = true;
        return tokenId;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI_ = _baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // Method to withdraw Native currency
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Method to withdraw ERC20 in this contract
    function withdrawERC20(address _erc20) external onlyOwner {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transfer(msg.sender, erc20.balanceOf(address(this)));
    }

    // Fallback method
    fallback() external payable {}

    // Receive method
    receive() external payable {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Base.sol";
import "./IERC721Mintable.sol";

contract UPYOERC721Collection is ERC721Base {
    address payable public mintableAddress;

    // Decimal precesion for brokeage calculation
    uint256 public constant decimalPrecision = 100;

    constructor(
        string memory _name, // Name of collection
        string memory _symbol, // Symbol of collection
        string memory _contractURI, // Metadata of collection
        string memory _tokenURIPrefix, // Base URI of collection
        uint96 _royaltyLimit, // Max Royalty limit for collection
        address payable _mintableAddress, // Mintable contract address
        address sender // Owner of contract
    ) ERC721Base(_name, _symbol, _contractURI, _tokenURIPrefix, _royaltyLimit) {
        mintableAddress = _mintableAddress;
        _transferOwnership(sender);
    }

    modifier ecosystemContractOnly() {
        require(
            IERC721Mintable(mintableAddress).ecosystemContract(msg.sender),
            "ERC721Collection: Internal contracts only"
        );
        _;
    }

    function mint(
        string memory tokenURI,
        uint96 _royalty,
        address _to
    ) external payable returns (uint256) {
        require(
            msg.value >= IERC721Mintable(mintableAddress).mintingCharge(),
            "ERC721Collection: Minting charges required"
        );
        uint256 tokenId = _mint(_to, _royalty, tokenURI);
        IERC721Mintable(mintableAddress).broker().transfer(msg.value);
        return tokenId;
    }
 
    function lazyMint(
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign,
        address buyer
    ) external payable returns(uint){
        IERC721Mintable erc721 = IERC721Mintable(mintableAddress);
        IERC721Mintable._brokerage memory _brokerage = erc721.brokerage();

        uint256 buyingBrokerage = (_brokerage.buyer * price) /
            (100 * decimalPrecision);
        uint256 mintingCharge = erc721.mintingCharge();
        require(
            msg.value >= price + mintingCharge + buyingBrokerage,
            "ERC721Collection: Insufficent fund transferred."
        );
        uint tokenId = _lazyMint(to, _royalty, _tokenURI, nonce, price, sign, buyer);
        uint256 sellingBrokerage = (_brokerage.seller * price) /
            (100 * decimalPrecision);
        uint256 sellerFund = price - sellingBrokerage;
        payable(to).transfer(sellerFund);
        erc721.broker().transfer(msg.value - sellerFund);
        return tokenId;
    }

    function delegatedMint(
        string memory tokenURI,
        uint96 _royalty,
        address _to,
        address _receiver
    ) external ecosystemContractOnly {
        uint256 tokenId = _mint(_to, _royalty, tokenURI);
        _transfer(_to, _receiver, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Collection.sol";

/**
 * @title Factory contract to create collections
 * This implementation deploy the collection contract and returns the list of colledtions deployed
 */
contract UPYOERC721Factory is Ownable {
    // List to store all collections created till now.
    address[] private _collections;

    // Mapping to store collection created by user
    // sender => list of collection deployed
    mapping(address => address[]) private _userCollections;

    address payable mintableToken;

    event CollectionCreated(
        address indexed collection, 
        address indexed creator, 
        uint time
    );

    /**
     * @dev Constructor function
     */
    constructor(address payable _mintableToken) {
        mintableToken = _mintableToken;
    }

    function setMintableAddress(address payable _mintableToken) external onlyOwner{
        mintableToken = _mintableToken;
    }

    /**
     * @dev Public function that deploys new collection contract and return new collection address.
     * @dev Returns address of deployed contract
     * @param name Display name for collection contract
     * @param symbol Symbol for collection contract
     * @param contractURI Collection description URI which contains display image and other necessery details.
     * @param tokenURIPrefix prefix for tokenURI of NFT contract
     */
    function createCollection(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory tokenURIPrefix,
        uint96 royaltyLimit
    ) external returns (address collectionAddress) {
        UPYOERC721Collection collection = new UPYOERC721Collection(
            name,
            symbol,
            contractURI,
            tokenURIPrefix,
            royaltyLimit,
            mintableToken,
            msg.sender
        );
        collectionAddress = address(collection);
        _collections.push(collectionAddress);
        _userCollections[msg.sender].push(collectionAddress);

        emit CollectionCreated(collectionAddress, msg.sender, block.timestamp);
    }

    /**
     * @dev return all collections deployed till now.
     */
    function getAllCollection() external view returns (address[] memory) {
        return _collections;
    }

    /**
     * @dev Returns contracts depolyet to address
     */
    function getUserCollection(address _user)
        external
        view
        returns (address[] memory)
    {
        return _userCollections[_user];
    }
}