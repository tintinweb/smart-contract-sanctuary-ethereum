// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";

// import other helper contracts 
import {SVG} from "SVG.sol";
import {Base64} from "Base64.sol";

contract JerseyMCL is ERC721, ERC721URIStorage, Ownable, SVG {
    using Strings for uint256;
    // using Counters for Counters.Counter;
   
    // Counters.Counter private _tokenIdCounter;
    mapping (uint256 => string) public playerName;

    uint256 constant MINTABLE = 99;
    uint256[MINTABLE] internal availableIndex;
    uint256 public totalMinted;

    address public contractOwner;

    string[10] internal players;


    event Minted(uint256 indexed tokenId, string indexed playerName, address indexed to);

    constructor() ERC721("JerseyMCL", "JMCL") SVG(){
        totalMinted = 0;
        contractOwner = msg.sender;
        players = [
            "Alien", "Rolex", "knight", "Spike", "Kong",
            "Monk", "Prince", "Wild", "Ronin", "Flash"
        ];
    }

    function _getNewIndex() internal returns(uint256 value) {
		uint256 remaining = MINTABLE - totalMinted;
        uint rand = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, remaining))) % remaining;
		value = 0;
        
		// if array value exists, use, otherwise, use generated random value
		if (availableIndex[rand] != 0)
			value = availableIndex[rand];
		else
			value = rand;
		// store remaining - 1 in used ID to create mapping
		if (availableIndex[remaining - 1] == 0)
			availableIndex[rand] = remaining - 1;
		else
			availableIndex[rand] = availableIndex[remaining - 1];	

        value += 1;
	}
    
    function _getPlayerName() internal returns (uint256 randomNum, string memory){
        uint256 ind = _getNewIndex();
        if (ind > 0  && ind < 11) return (ind, players[0]);
        if (ind > 10 && ind < 21) return (ind, players[1]);
        if (ind > 20 && ind < 31) return (ind, players[2]);
        if (ind > 30 && ind < 41) return (ind, players[3]);
        if (ind > 40 && ind < 51) return (ind, players[4]);
        if (ind > 50 && ind < 61) return (ind, players[5]);
        if (ind > 60 && ind < 71) return (ind, players[6]);
        if (ind > 70 && ind < 81) return (ind, players[7]);
        if (ind > 80 && ind < 91) return (ind, players[8]);
        return (ind, players[9]);
    }

    function nftMint() public returns (uint){
        // _tokenIdCounter.increment();
        // uint256 tokenId = _tokenIdCounter.current();
        uint256 tokenId;
        string memory player;
        require(tokenId <= MINTABLE, "Jersey's Sold Out !!!" );

        (tokenId, player) = _getPlayerName();

        playerName[tokenId] = player;
        _safeMint(msg.sender, tokenId);
        // _setTokenURI(tokenId, generateFinalMetaJson(player, tokenId, msg.sender) );
        emit Minted(tokenId, playerName[tokenId], msg.sender );

        totalMinted+=1;
        return tokenId;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.generateFinalMetaJson(playerName[tokenId], tokenId, ownerOf(tokenId));
    }

    function generateSVGFromHash(uint256 tokenId) public virtual view returns (string memory) {
        return super.generateSVGFromHash(playerName[tokenId], tokenId, ownerOf(tokenId));
    }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";

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
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "Strings.sol";

//  import the helper functions from the contract 
import {Base64} from "Base64.sol";

contract SVG  {
    using Strings for uint256;

    function getJerseyColour(address mintAddress) pure public returns (string memory colour){
        string memory str = Strings.toHexString(uint160(mintAddress), 20);
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(6);

        result[0] = strBytes[2];
        result[1] = strBytes[3];
        result[2] = strBytes[11];
        result[3] = strBytes[31];
        result[4] = strBytes[40];
        result[5] = strBytes[41];

        colour = string(abi.encodePacked('#',string(result)));
    }


    function generate_inner() internal pure returns (string memory){
        return string(abi.encodePacked(
            "<path id='inner1' fill='#78716f' d='M302.395 36.324c0 29.171-20.771 77.466-46.396 77.466s-46.396-48.295-46.396-77.466 20.771-28.237 46.396-28.237 46.396-.934 46.396 28.237z'/>",
            "<path id='inner2' fill='#524d4c' d='M261.406 36.324c0-18.252 8.132-24.718 20.495-27.001-7.397-1.367-16.309-1.236-25.901-1.236-25.625 0-46.396-.935-46.396 28.237S230.375 113.79 256 113.79c9.592 0 18.504-6.767 25.901-16.767-12.364-16.71-20.495-42.447-20.495-60.699z'/>"
        ));
    }

    function generate_collar() internal pure returns (string memory){
        return string(abi.encodePacked(
            "<path id='collar_light1' fill='#858280' d='M209.603 36.324c0-9.021 1.994-15.153 5.499-19.333l-34.49 28.812s-3.026 51.773 38.827 91.519l26.112-26.226c-20.592-10.507-35.948-49.692-35.948-74.772z'/>",
            "<path id='collar_dark' fill='#474646' d='M218.655 75.94c-.981-5.317-1.507-10.424-1.507-15.05 0-9.021-9.57-5.494-6.064-9.674-.963-5.259-1.481-10.313-1.481-14.892 0-9.021 1.994-15.153 5.499-19.333l-34.49 28.812s-1.092 18.774 7.171 42.387c-1.347-10.076-.973-16.518-.973-16.518l1.338-1.118c-.084 1.955-.617 19.919 7.181 42.202-1.347-10.076-.973-16.518-.973-16.518l24.299-20.298z'/>",
            "<path id='collar_light2' fill='#858280' d='m331.386 45.804-34.49-28.812c3.505 4.18 5.499 10.311 5.499 19.333 0 25.08-15.356 64.265-35.948 74.772l26.112 26.226c41.855-39.746 38.827-91.519 38.827-91.519z'/>"
        ));
    }

    function generate_base_jersey(string memory jerseyColour) internal pure returns (string memory){
        return string(abi.encodePacked(
            "<path id='jersey' fill='",jerseyColour,"' d='M348.578 503.916h41.324V211.06l43.37 37.654 70.606-66.938-92.795-110.869-77.522-23.782c.133 8.312-.95 54.19-38.87 90.198l-26.088-26.206c-3.364 1.719-6.869 2.672-10.47 2.672-3.6 0-7.105-.954-10.47-2.672l-26.09 26.206c-41.855-39.745-38.827-91.519-38.827-91.519l-81.829 25.101L8.121 181.776l70.606 66.938 43.37-37.654v292.855h200.612'/>",
            "<path id='shoulder' fill='#4e4947' d='m133.732 113.467 58.946-18.082c-11.254-26.878-9.933-49.58-9.933-49.58l-81.828 25.101-92.796 110.87 38.159 36.176 87.452-104.485zm244.536 0-58.947-18.082c11.254-26.878 9.933-49.58 9.933-49.58l81.829 25.102 92.796 110.869-38.159 36.176-87.452-104.485z'/>",
            "<path id='numberOverlay' fill='rgba(255,255,255,0.25)' d='M211.686 366.145h-18.187c-7.143 0-12.935-5.792-12.935-12.935V249.732c0-7.143 5.792-12.935 12.935-12.935h125.002c7.143 0 12.935 5.792 12.935 12.935V353.21c0 7.143-5.792 12.935-12.935 12.935h-79.868'/>",
            "<path id='sideL' fill='rgba(96,91,92,0.269)' d='M 130 200 v305 h40' />",
            "<path id='sideR' fill='rgba(96,91,92,0.269)' d='M 382 200 v305 h-40' />",
            "<text id='league' style='font-family: Comic Sans MS; font-size:15; letter-spacing: 4.8px;' x='140' y='485' stroke='#000000' stroke-width='0.2' fill='rgba(255,255,255,0.65)'>Meta Cricket League</text>"
        ));
    }

    function generate_outlines() internal pure returns (string memory){
        return string(abi.encodePacked(
            "<path id='Outline' fill='#231f20' d='M510.078 176.587 417.282 65.718a8.08 8.08 0 0 0-3.828-2.54l-76.9-23.59-33.887-28.308C292.639.016 274.828 0 260.572 0l-4.574.003L251.425 0c-14.255 0-32.066.016-42.095 11.28l-33.887 28.309-76.898 23.589a8.08 8.08 0 0 0-3.828 2.54L1.922 176.587a8.083 8.083 0 0 0 .637 11.055l70.606 66.938a8.082 8.082 0 0 0 10.862.238l29.986-26.033v275.131a8.084 8.084 0 0 0 8.084 8.084h200.61c4.465 0 8.084-3.618 8.084-8.084s-3.62-8.084-8.084-8.084H130.182V185.059c0-4.466-3.62-8.084-8.084-8.084s-8.084 3.618-8.084 8.084v22.314L78.967 237.8l-59.768-56.663L105.58 77.933l67.292-20.643c1.563 18.607 8.893 55.403 41.001 85.895a8.063 8.063 0 0 0 5.566 2.223c.358 0 .715-.032 1.069-.08a8.066 8.066 0 0 0 6.796-2.301l21.59-21.689c2.417.43 4.78.515 6.885.532.073 0 .147.005.221.005.054 0 .108-.003.161-.004l1.307.005.666-.001c2.277 0 4.551-.286 6.811-.829l21.884 21.982a8.063 8.063 0 0 0 5.73 2.38c.355 0 .708-.031 1.06-.078a8.063 8.063 0 0 0 6.639-2.144c31.628-30.032 39.195-66.493 40.915-85.268l65.247 20.015 86.381 103.204-59.768 56.663-35.048-30.427v-22.314a8.084 8.084 0 0 0-8.084-8.084 8.083 8.083 0 0 0-8.084 8.084V495.83h-33.24c-4.465 0-8.084 3.618-8.084 8.084s3.62 8.084 8.084 8.084h41.324a8.083 8.083 0 0 0 8.084-8.084v-275.13l29.986 26.033a8.081 8.081 0 0 0 10.862-.238l70.606-66.938a8.08 8.08 0 0 0 .639-11.054zm-216.544-51.884L280.1 111.208a64.601 64.601 0 0 0 .645-.608 61.003 61.003 0 0 0 3.191-3.29c.134-.148.267-.298.4-.447.364-.412.727-.832 1.088-1.26.149-.176.299-.348.445-.526.427-.516.85-1.043 1.272-1.582.266-.341.528-.689.791-1.036.162-.215.323-.428.484-.645.31-.418.617-.841.921-1.269l.201-.286c2.925-4.145 5.578-8.684 7.935-13.44.092-.184.182-.371.273-.556a162.093 162.093 0 0 0 1.636-3.467l.071-.161c6.098-13.484 10.032-28.464 10.851-41.412.015-.22.027-.437.04-.654.029-.521.06-1.042.079-1.556.002-.059.008-.122.01-.181l12.905 10.779c-.222 10.72-3.13 45.287-29.804 75.092zM255.999 16.172l4.574-.003c16.334 0 25.253.878 29.751 5.522.121.168.243.335.377.496 2.396 2.855 3.61 7.613 3.61 14.138a55.405 55.405 0 0 1-.13 3.78c-.018.308-.036.617-.058.927a74.372 74.372 0 0 1-.18 2.034l-.013.128c-.736 7.022-2.515 14.729-5.073 22.264-.196.572-.397 1.144-.602 1.713-.072.202-.14.403-.213.604-5.258 14.347-13.247 27.493-21.706 33.875l-.11.084c-.354.264-.708.497-1.063.736-.266.178-.531.366-.8.531-.016.011-.032.018-.05.028-.512.313-1.026.604-1.544.867-.039.019-.073.045-.112.066-2.205 1.113-4.419 1.73-6.605 1.741l-.129-.001c-2.181-.013-4.389-.628-6.59-1.74-.038-.02-.072-.045-.111-.066a23.685 23.685 0 0 1-1.538-.864c-.018-.012-.037-.02-.055-.032-.266-.164-.53-.352-.796-.528-.356-.241-.712-.474-1.067-.739-.036-.026-.071-.055-.107-.082-8.459-6.382-16.45-19.529-21.709-33.878-.071-.195-.138-.392-.208-.587-.207-.573-.409-1.148-.606-1.725-2.558-7.536-4.337-15.243-5.074-22.266l-.013-.128a74.372 74.372 0 0 1-.18-2.034c-.023-.31-.04-.619-.058-.927-.029-.465-.058-.929-.077-1.386a62.523 62.523 0 0 1-.053-2.394c0-6.526 1.214-11.282 3.61-14.138a8 8 0 0 0 .377-.496c4.501-4.643 13.42-5.521 29.754-5.521l4.577.001zM190.79 47.836l10.777-9.003.009.181c.018.514.05 1.036.079 1.556.013.218.025.434.04.654.82 12.952 4.757 27.938 10.859 41.427.022.047.041.095.063.141.213.471.432.939.652 1.406.321.691.649 1.376.983 2.059.093.189.184.378.278.567 2.357 4.756 5.008 9.293 7.933 13.436l.201.286c.304.427.611.85.922 1.269.16.216.321.428.482.64.264.348.526.698.794 1.041.42.538.845 1.065 1.271 1.58.148.178.298.35.445.526.36.428.723.848 1.088 1.26.134.15.266.3.4.448a62.48 62.48 0 0 0 3.188 3.289l.038.036a54.971 54.971 0 0 0 1.735 1.586l-12.43 12.485c-28.246-31.606-29.816-68.872-29.807-76.87z'/>",
            "<path id='numberOutline' fill='#231f20' d='M318.5 228.714H193.498c-11.591 0-21.019 9.429-21.019 21.019v103.478c0 11.59 9.428 21.019 21.019 21.019h18.187a8.083 8.083 0 0 0 8.084-8.084 8.084 8.084 0 0 0-8.084-8.084h-18.187a4.857 4.857 0 0 1-4.851-4.851V249.733a4.857 4.857 0 0 1 4.851-4.851H318.5a4.857 4.857 0 0 1 4.851 4.851v103.478a4.857 4.857 0 0 1-4.851 4.851h-79.868a8.083 8.083 0 0 0-8.084 8.084 8.084 8.084 0 0 0 8.084 8.084H318.5c11.591 0 21.019-9.429 21.019-21.019V249.733c0-11.589-9.429-21.019-21.019-21.019z'/>"
        ));
    }

    function generate_playerText(string memory playerName, string memory  token, address mintAddress) internal pure returns (string memory){
        return string(abi.encodePacked(
            "<text id='number' style='font: bold 90px sans-serif; ' x='205' y='330' stroke='rgba(0,0,0,0.55)' stroke-width='4' fill='#ffffff'>",token,"</text>",
            "<text id='Meta' style='font: bold 45px Comic Sans MS; letter-spacing: px' x='202' y='220' stroke='rgba(0,0,0,0.55)' stroke-width='2' fill='#ffffff'>Meta</text>",
            "<text id='Name' style='font: bold 45px Comic Sans MS; ' x='197' y='415' stroke='rgba(0,0,0,0.55)' stroke-width='2' fill='#ffffff'>",playerName,"</text>",
            "<text id='Address' style='font-family:  Monospace;font-size:12; letter-spacing: 1px;'>",
            "<textpath xlink:href='#AddressPath' fill='#ffffff' >",Strings.toHexString(uint160(mintAddress), 20),"</textpath></text> "
        ));
    }

    function generateSVGFromHash(string memory playerName, uint256 tokenId, address mintAddress) internal virtual view returns (string memory) {

        string memory token = tokenId.toString();
        if (tokenId < 10){
            token = string(abi.encodePacked('0',token));
        }

        string memory jerseyColour = getJerseyColour(mintAddress);


        string memory finalSvg = string(abi.encodePacked(
            "<svg xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 512 512' width='555' height='555'>", 
            "<defs><path id='AddressPath' d='M50 200 l85 -100 l40 -10 m 165 0 l35 10 L465 200 '/></defs>",
            
            generate_inner(),
            generate_collar(),
            generate_base_jersey(jerseyColour),
            generate_outlines(),
            generate_playerText(playerName, token, mintAddress),

            "</svg>"
        ));

        return finalSvg ;
    
    }

    function generateFinalMetaJson(string memory playerName , uint256 tokenId , address mintAddress) internal view returns (string memory){
        string memory finalSvg = generateSVGFromHash(playerName, tokenId, mintAddress);
        string memory nftName = string(abi.encodePacked("MCL Player #", tokenId.toString())) ;

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',nftName,
                        '", "description": "MCL Collection of On-Chain-Jerseys.", "image": "data:image/svg+xml;base64,',
                        //add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        // // Get all the JSON metadata in place and base64 encode it.
        // string memory json = string(
        //             abi.encodePacked(
        //                 '{"name": "',nftName,
        //                 '", "description": "MCL Collection of On-Chain Jerseys.", "image": "data:image/svg+xml;base64,',
        //                 //add data:image/svg+xml;base64 and then append our base64 encode our svg.
        //                 finalSvg,
        //                 '"}')
        //             );

        // prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return finalTokenUri;
    }    
   
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}