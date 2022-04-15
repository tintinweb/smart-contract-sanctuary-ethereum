//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ByteSwapping.sol";
import "./Royalty.sol";
import "./SVG.sol";
import "./Traversable.sol";
import "./WAVE.sol";

contract INFRSNC is ERC721, Ownable, Traversable, Royalty {
    uint256 public chainSeed;
    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    constructor(
        address layerZeroEndpoint,
        uint256 chainSeed_,
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 mintPrice_
    ) ERC721("INFRSNC", "INFRSNC") Traversable(layerZeroEndpoint) {
        chainSeed = chainSeed_;
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;
        mintPrice = mintPrice_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "INFRSNC: msg value invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "INFRSNC: mint finished");
        _safeMint(to, tokenId);
        _registerTraversableSeeds(
            tokenId,
            chainSeed,
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), tokenId)
                )
            )
        );
        supplied++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory tokenURI)
    {
        require(_exists(tokenId), "INFRSNC: nonexistent token");
        (uint256 birthChainSeed, uint256 tokenIdSeed) = getTraversableSeeds(
            tokenId
        );
        uint256 sampleRate = WAVE.calculateSampleRate(chainSeed);
        uint256 dutyCycle = WAVE.calculateDutyCycle(birthChainSeed);
        uint256 hertz = WAVE.calculateHertz(tokenIdSeed);
        bytes memory wave = WAVE.generate(7627, 10, 1);
        bytes memory metadata = abi.encodePacked(
            '{"name":"INFRSNC #',
            Strings.toString(tokenId),
            '","description": "A traversed generative infrasonic.","image_data":"',
            SVG.generate(wave),
            '","animation_url":"',
            wave,
            '","attributes":',
            abi.encodePacked(
                '[{"trait_type":"SAMPLE RATE","value":"',
                Strings.toString(sampleRate),
                '"},{"trait_type":"DUTY CYCLE","value":"',
                Strings.toString(dutyCycle),
                '"},{"trait_type":"HERTZ","value":"',
                WAVE.addDecimalPointToHertz(hertz),
                '"}]'
            ),
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library ByteSwapping {
    function swapUint32(uint32 input) internal pure returns (uint32) {
        uint32 output = input;
        output = ((output & 0xFF00FF00) >> 8) | ((output & 0x00FF00FF) << 8);
        return (output >> 16) | (output << 16);
    }

    function swapUint16(uint16 input) internal pure returns (uint16) {
        uint16 output = input;
        return (output >> 8) | (output << 8);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IERC2981.sol";

abstract contract Royalty is Ownable, IERC2981 {
    uint256 private constant _BPS_BASE = 10000;
    uint256 private _bps;
    address private _recipient;

    function setRoyalty(address recipient, uint256 bps) public onlyOwner {
        require(_bps < _BPS_BASE, "Royalty: bps invalid");
        _recipient = recipient;
        _bps = bps;
    }

    // solhint-disable-next-line no-unused-vars
    function royaltyInfo(uint256 _tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        if (_recipient != address(0x0) && _bps != 0) {
            return (_recipient, (salePrice * _bps) / _BPS_BASE);
        } else {
            return (address(0x0), 0);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SVG {
    function generate(bytes memory wave) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg width=\\"350\\" height=\\"350\\" viewBox=\\"0 0 350 350\\" xmlns=\\"http://www.w3.org/2000/svg\\"><style>@font-face{font-family: \\"Tinos\\"; font-style: normal; font-weight: 400; src: url(data:font/woff2;base64,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) format(\\"woff2\\");}div{width: 350px; height: 350px; background: black; display: flex; align-items: center;}p{margin-left: -700px; margin-right: -700px; font-family: Tinos; color: white; word-break: break-all; letter-spacing: 10px; transform:scale(0.2); font-size: 10px; animation-duration: 0.01s; animation-name: textflicker; animation-iteration-count: infinite; animation-direction: alternate;}@keyframes textflicker{from{text-shadow: 1px 0 0 #ea36af, -2px 0 0 #75fa69;}to{text-shadow: 2px 0.5px 2px #ea36af, -1px -0.5px 2px #75fa69;}}</style><foreignObject x=\\"0\\" y=\\"0\\" width=\\"350\\" height=\\"350\\"><div xmlns=\\"http://www.w3.org/1999/xhtml\\"><p>',
                wave,
                "</p></div></foreignObject></svg>"
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "solidity-examples/contracts/token/onft/IONFT.sol";

abstract contract Traversable is ERC721, Ownable, NonblockingLzApp, IONFT {
    mapping(uint256 => uint256) private _birthChainSeeds;
    mapping(uint256 => uint256) private _tokenIdSeeds;

    constructor(address layerZeroEndpoint)
        NonblockingLzApp(layerZeroEndpoint)
    {} // solhint-disable-line no-empty-blocks

    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) external payable virtual override {
        _send(
            from,
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );
    }

    function send(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) external payable virtual override {
        _send(
            _msgSender(),
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );
    }

    function getTraversableSeeds(uint256 tokenId)
        public
        view
        returns (uint256 birthChainSeed, uint256 tokenIdSeed)
    {
        return (_birthChainSeeds[tokenId], _tokenIdSeeds[tokenId]);
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Traversable: transfer caller is not owner nor approved"
        );
        (uint256 birthChainSeed, uint256 tokenIdSeed) = getTraversableSeeds(
            tokenId
        );

        _unregisterTraversableSeeds(tokenId);
        _burn(tokenId);

        bytes memory payload = abi.encode(
            toAddress,
            tokenId,
            birthChainSeed,
            tokenIdSeed
        );

        _lzSend(
            dstChainId,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );

        uint64 nonce = lzEndpoint.getOutboundNonce(dstChainId, address(this));
        emit SendToChain(from, dstChainId, toAddress, tokenId, nonce);
    }

    function _registerTraversableSeeds(
        uint256 tokenId,
        uint256 birthChainSeed,
        uint256 tokenIdSeed
    ) internal {
        _birthChainSeeds[tokenId] = birthChainSeed;
        _tokenIdSeeds[tokenId] = tokenIdSeed;
    }

    function _unregisterTraversableSeeds(uint256 tokenId) internal {
        delete _birthChainSeeds[tokenId];
        delete _tokenIdSeeds[tokenId];
    }

    function _nonblockingLzReceive(
        uint16 srcChainId, // solhint-disable-line no-unused-vars
        bytes memory srcAddress, // solhint-disable-line no-unused-vars
        uint64 nonce, // solhint-disable-line no-unused-vars
        bytes memory payload
    ) internal override {
        (
            bytes memory toAddress,
            uint256 tokenId,
            uint256 birthChainSeed,
            uint256 tokenIdSeed
        ) = abi.decode(payload, (bytes, uint256, uint256, uint256));
        address localToAddress;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            localToAddress := mload(add(toAddress, 20))
        }
        if (localToAddress == address(0x0)) localToAddress == address(0xdEaD);

        _safeMint(localToAddress, tokenId);
        _registerTraversableSeeds(tokenId, birthChainSeed, tokenIdSeed);

        emit ReceiveFromChain(srcChainId, localToAddress, tokenId, nonce);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ByteSwapping.sol";

library WAVE {
    bytes4 private constant _CHANK_ID = "RIFF";
    bytes4 private constant _FORMAT = "WAVE";
    bytes4 private constant _SUB_CHANK_1_ID = "fmt ";
    uint32 private constant _SUB_CHANK_1_SIZE = 16;
    uint16 private constant _AUDIO_FORMAT = 1;
    uint16 private constant _NUM_CHANNELS = 1;
    uint16 private constant _BITS_PER_SAMPLE = 16;
    bytes4 private constant _SUB_CHANK_2_SIZE = "data";

    int16 private constant _UPPER_AMPLITUDE = 16383;
    int16 private constant _LOWER_AMPLITUDE = -16383;

    uint256 private constant _MAX_SAMPLE_RATE = 8000;
    uint256 private constant _MIN_SAMPLE_RATE = 3000;

    uint256 private constant _MAX_HERTZ = 160;
    uint256 private constant _MIN_HERTZ = 10;
    uint256 private constant _HERTZ_BASE = 10;

    uint256 private constant _MAX_DUTY_CYCLE = 99;
    uint256 private constant _MIN_DUTY_CYCLE = 1;
    uint256 private constant _DUTY_CYCLE_BASE = 100;

    function calculateSampleRate(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_SAMPLE_RATE, _MIN_SAMPLE_RATE);
    }

    function calculateDutyCycle(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_DUTY_CYCLE, _MIN_DUTY_CYCLE);
    }

    function calculateHertz(uint256 seed) internal pure returns (uint256) {
        return _ramdom(seed, _MAX_HERTZ, _MIN_HERTZ);
    }

    function addDecimalPointToHertz(uint256 hertz)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                Strings.toString(hertz / _HERTZ_BASE),
                ".",
                Strings.toString(hertz % _HERTZ_BASE)
            );
    }

    function generate(
        uint256 sampleRate,
        uint256 hertz,
        uint256 dutyCycle
    ) internal pure returns (bytes memory) {
        bytes memory wave;

        uint256 waveWidth = (sampleRate / hertz) * _HERTZ_BASE;

        uint256 amplitudesLength = 1;
        while (waveWidth >= 2**amplitudesLength) {
            amplitudesLength++;
        }

        bytes[] memory upperAmplitudes = new bytes[](amplitudesLength);
        bytes[] memory lowerAmplitudes = new bytes[](amplitudesLength);
        upperAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(_UPPER_AMPLITUDE))
        );
        lowerAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(_LOWER_AMPLITUDE))
        );

        for (uint256 i = 1; i < amplitudesLength; i++) {
            uint256 lastIndex = i - 1;
            upperAmplitudes[i] = abi.encodePacked(
                upperAmplitudes[lastIndex],
                upperAmplitudes[lastIndex]
            );
            lowerAmplitudes[i] = abi.encodePacked(
                lowerAmplitudes[lastIndex],
                lowerAmplitudes[lastIndex]
            );
        }

        uint256 upperWaveWidth = (waveWidth * dutyCycle) / _DUTY_CYCLE_BASE;
        uint256 lowerWaveWidth = (waveWidth * (_DUTY_CYCLE_BASE - dutyCycle)) /
            _DUTY_CYCLE_BASE;
        uint256 adjustWaveWidth = sampleRate %
            (upperWaveWidth + lowerWaveWidth);

        bytes memory upperWave = _concatAmplitudes(
            upperAmplitudes,
            upperWaveWidth
        );
        bytes memory lowerWave = _concatAmplitudes(
            lowerAmplitudes,
            lowerWaveWidth
        );
        bytes memory adjustWave = _concatAmplitudes(
            upperAmplitudes,
            adjustWaveWidth
        );

        while (sampleRate * 2 >= wave.length + waveWidth * 2) {
            wave = abi.encodePacked(wave, upperWave, lowerWave);
        }
        wave = abi.encodePacked(wave, adjustWave);
        return _encode(uint32(sampleRate), wave);
    }

    function _ramdom(
        uint256 seed,
        uint256 max,
        uint256 min
    ) private pure returns (uint256) {
        return (seed % (max - min)) + min;
    }

    function _concatAmplitudes(bytes[] memory amplitudes, uint256 waveWidth)
        private
        pure
        returns (bytes memory)
    {
        bytes memory concated;
        uint256 lastAmplitudesIndex = amplitudes.length - 1;
        while (concated.length < waveWidth * 2) {
            uint256 gap = waveWidth * 2 - concated.length;
            for (uint256 i = lastAmplitudesIndex; i >= 0; i--) {
                if (gap >= amplitudes[i].length) {
                    concated = abi.encodePacked(concated, amplitudes[i]);
                    lastAmplitudesIndex = i;
                    break;
                }
            }
        }
        return concated;
    }

    function _encode(uint32 sampleRate, bytes memory data)
        private
        pure
        returns (bytes memory)
    {
        bytes memory raw = abi.encodePacked(
            _riffChunk(sampleRate),
            _fmtSubChunk(sampleRate),
            _dataSubChunk(sampleRate, data)
        );
        return abi.encodePacked("data:audio/wav;base64,", Base64.encode(raw));
    }

    function _riffChunk(uint32 sampleRate) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                _CHANK_ID,
                ByteSwapping.swapUint32(_chunkSize(sampleRate)),
                _FORMAT
            );
    }

    function _chunkSize(uint32 sampleRate) private pure returns (uint32) {
        return 4 + (8 + _SUB_CHANK_1_SIZE) + (8 + _subchunk2Size(sampleRate));
    }

    function _fmtSubChunk(uint32 sampleRate)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _SUB_CHANK_1_ID,
                ByteSwapping.swapUint32(_SUB_CHANK_1_SIZE),
                ByteSwapping.swapUint16(_AUDIO_FORMAT),
                ByteSwapping.swapUint16(_NUM_CHANNELS),
                ByteSwapping.swapUint32(sampleRate),
                ByteSwapping.swapUint32(_byteRate(sampleRate)),
                ByteSwapping.swapUint16(_blockAlign()),
                ByteSwapping.swapUint16(_BITS_PER_SAMPLE)
            );
    }

    function _byteRate(uint32 sampleRate) private pure returns (uint32) {
        return (sampleRate * _NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
    }

    function _blockAlign() private pure returns (uint16) {
        return (_NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
    }

    function _dataSubChunk(uint32 sampleRate, bytes memory data)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _SUB_CHANK_2_SIZE,
                ByteSwapping.swapUint32(_subchunk2Size(sampleRate)),
                data
            );
    }

    function _subchunk2Size(uint32 sampleRate) private pure returns (uint32) {
        return (sampleRate * _NUM_CHANNELS * _BITS_PER_SAMPLE) / 8;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
pragma solidity 0.8.4;

interface IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "LzReceiver: caller must be Bridge.");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "LzReceiver: no stored message");
        require(keccak256(_payload) == payloadHash, "LzReceiver: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT is IERC721 {
    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParam` is a flexible bytes array to indicate messaging adapter services
     */
    function send(uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParam) external payable;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParam` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParam) external payable;

    /**
     * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce from
     */
    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, bytes indexed _toAddress, uint _tokenId, uint64 _nonce);

    /**
     * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 _srcChainId, address _toAddress, uint _tokenId, uint64 _nonce);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint internal immutable lzEndpoint;

    mapping(uint16 => bytes) internal trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint));
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "LzReceiver: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParam) internal {
        require(trustedRemoteLookup[_dstChainId].length != 0, "LzSend: destination chain is not a trusted source.");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(lzEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    // interacting with the LayerZero Endpoint and remote contracts

    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory) {
        return trustedRemoteLookup[_chainId];
    }

    function getLzEndpoint() external view returns (address) {
        return address(lzEndpoint);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}