// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DuckDuckGoose is Ownable, ERC721 {
    using Counters for Counters.Counter;

    /**
     * Duck.
     */
    string duck = 'data:image/png;base64,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';

    /**
     * Goose.
     */
    string goose = 'data:image/png;base64,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';

    /**
     * Geese.
     */
    mapping(uint256 => bool) public geese;

    /**
     * Goose percentage * 100.
     */
    uint256 public goosePercentage = 100;

    /**
     * Goose prize percentage * 100.
     */
    uint256 public goosePrizePercentage = 9000;

    /**
     * Price.
     */
    uint256 public price = 1000000000000000;

    /**
     * Token id tracker.
     */
    Counters.Counter private _tokenIdTracker;

    /**
     * Constructor.
     */
    constructor() ERC721('Duck, Duck, Goose!', '$DDG') {}

    /**
     * Goose found event.
     */
    event GooseFound(uint256 goose);

    /**
     * Mint.
     */
    function mint(uint256 quantity) external payable {
        require(msg.value >= quantity * price, 'Value is too low');
        for(uint256 i = 0; i < quantity; i++) {
            _tokenIdTracker.increment();
            _safeMint(msg.sender, _tokenIdTracker.current());
            if(_tokenIdTracker.current() % (10000 / goosePercentage) == 0) {
                findGoose();
            }
        }
    }

    /**
     * Find goose.
     */
    function findGoose() internal {
        uint256 foundGoose = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number - 1)))) % _tokenIdTracker.current();
        uint256 prize = address(this).balance / 10000 * goosePrizePercentage;
        payable(ownerOf(foundGoose)).transfer(prize);
        payable(owner()).transfer(address(this).balance);
        geese[foundGoose] = true;
        emit GooseFound(foundGoose);
    }

    /**
     * Total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * Token of owner by index.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns(uint256) {
        require(index < ERC721.balanceOf(owner), 'Owner index out of bounds');
        uint256 count = 0;
        for(uint256 i = 1; i <= _tokenIdTracker.current(); i++) {
            if(ownerOf(i) == owner) {
                if(count == index) {
                    return i;
                }
                count++;
            }
        }
        return 0;
    }

    /**
     * Set price.
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * Set goose percentage.
     */
    function setGoosePercentage(uint256 _percentage) external onlyOwner {
        goosePercentage = _percentage;
    }

    /**
     * Set goose prize percentage.
     */
    function setGoosePrizePercentage(uint256 _percentage) external onlyOwner {
        goosePrizePercentage = _percentage;
    }

    /**
     * Contract URI.
     */
    function contractURI() public pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"Duck, Duck, Goose!","description":"Play the classic game of Duck, Duck, Goose on the blockchain. Mint a goose and you might win a prize!"}'
                        )
                    )
                )
            )
        );
    }

    /**
     * Token URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId > 0 && _tokenId <= _tokenIdTracker.current(), 'Token does not exist');
        string memory image = duck;
        if(geese[_tokenId]) {
            image = goose;
        }
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"Duck Duck Goose #',
                            Strings.toString(_tokenId),
                            '","description":"Play the classic game of Duck, Duck, Goose on the blockchain. Mint a goose and you might win a prize!","fee_recipient":"',
                            addressToString(owner()),
                            '","seller_fee_basis_points":"1000","image":"',
                            image,
                            '","attributes":[{"trait_type":"Ticket","value":"',
                            Strings.toString(_tokenId),
                            '"}]}'
                        )
                    )
                )
            )
        );
    }

    /**
     * Convert address to string.
     */
    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(address(_address))));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
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