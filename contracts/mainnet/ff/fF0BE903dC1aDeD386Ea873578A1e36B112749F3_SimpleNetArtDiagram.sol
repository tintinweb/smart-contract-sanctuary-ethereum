//SPDX-License-Identifier: MIT
//SimpleNetArtDiagram.sol by MTAA
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract SimpleNetArtDiagram is Ownable, ERC721Royalty {
    /**
     * @dev Keeps track of the number of tokens and is returned from totalSupply function
     */
    uint256 private _tokenCount; // default to 0

    /**
     * @dev Keeps track of whether mintMax has ever been called.
     */
    bool private _minted; // default to false

    string public constant NAME = "Simple Net Art Diagram";
    string public constant DESCRIPTION = "The simplest possible net art diagram. CC0 1.0 Universal";

    /**
     * @notice data URI of the Simple Net Art Diagram
     */
    string public constant SIMPLE_NET_ART_DIAGRAM =
        "data:image/gif;base64,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";
    uint256 public constant MAX_SUPPLY = 3; // there will only ever be 3 SNAD tokens

    constructor() ERC721(NAME, "SNAD") {
        // set a 10% royalty
        _setDefaultRoyalty(owner(), 1000);
    }

    /**
     * @notice Contract owner may mint max supply to the contract owner only once
     */
    function mintMax() public onlyOwner {
        require(_minted == false, "Already minted");
        for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
            _mint(owner(), i);
        }
        _tokenCount = MAX_SUPPLY;
        _minted = true;
    }

    /**
     * @notice Returns the license name
     * conforms to ICantBeEvil https://github.com/a16z/a16z-contracts/blob/master/contracts/licenses/ICantBeEvil.sol
     */
    function getLicenseName() public pure returns (string memory) {
        return "CC0 1.0 Universal";
    }

    /**
     * @notice Returns the license URI
     * conforms to ICantBeEvil https://github.com/a16z/a16z-contracts/blob/master/contracts/licenses/ICantBeEvil.sol
     */
    function getLicenseURI() public pure returns (string memory) {
        return "ipfs://QmZcU7ZkmVSNfVZjsxoHSoCtw89Az5hmqufLPowZxCURn8";
    }

    /**
     * @notice Returns current token supply
     */
    function totalSupply() public view returns (uint256) {
        return _tokenCount;
    }

    /**
     * @notice ...can't think of a reason someone would want to burn
     * one of these precious tokens, but you never know!
     * Let's hope this function is never called on mainnet.
     */
    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
        require(_tokenCount > 0, "decrement overflow");
        unchecked {
            _tokenCount = _tokenCount - 1;
        }
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `_tokenId` token if it's a valid token id
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        // ownerOf will revert if _tokenId belongs to address 0
        ownerOf(_tokenId);
        string memory edition = string.concat(_tokenIdToString(_tokenId), "/3");
        string memory licence = string.concat(getLicenseName(), " ", getLicenseURI());
        string memory attributes = string.concat(
            '"attributes": [{"trait_type":"Artist","value":"MTAA"},{"trait_type":"License","value":"',
            licence,
            '"},{"trait_type":"Edition", "value":"',
            edition,
            '"}]'
        );
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"',
                    NAME,
                    " #",
                    edition,
                    '","description":"',
                    DESCRIPTION,
                    '","image":"',
                    SIMPLE_NET_ART_DIAGRAM,
                    '","license":"',
                    licence,
                    '","edition":"',
                    edition,
                    '",',
                    attributes,
                    "}"
                )
            )
        );
        return string.concat("data:application/json;base64,", metadata);
    }

    /**
     * @dev Since only 1, 2 or 3 are valid, turn the token ID into a string in this simple manner.
     */
    function _tokenIdToString(uint256 _tokenId) private pure returns (string memory tokenId) {
        if (_tokenId == 1) {
            return "1";
        }
        if (_tokenId == 2) {
            return "2";
        }
        if (_tokenId == 3) {
            return "3";
        }
        revert("Invalid token ID");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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