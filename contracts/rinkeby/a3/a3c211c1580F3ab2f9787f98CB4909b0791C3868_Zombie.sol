// SPDX-License-Identifier: MIT
// Oleksandr Bakhmach Contracts

pragma solidity ^0.8.0;

import "Uint.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "IERC721Receiver.sol";
import "Utils.sol";
import "Address.sol";

contract Zombie is Utils , IERC721Metadata, IERC721Enumerable {
    using Uint for uint256;
    using Address for address;

    string private _zombieTokenName;
    string private _zombieTokenSymbol;
    string private _zombieTokenBaseLink;

    uint private _dnaDigits = 15;
    uint private _dnaModulus = 10 ** _dnaDigits;
    uint private _cooldownTime = 1 days;

    //The main structure describing a zombie
    struct Zombie {
        string name;
        uint256 dna;
        uint32 level;
        uint256 readyTime;
        uint16 winCount;
        uint16 lossCount;
    }

    // Store here all zombies ids as a list
    uint256[] private _allZombieIds;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _zombieIdToOwnerAddress;
    // Mapping owner address to token count
    mapping(address => uint256) private _zombieOwnerAddressToZombiesCount;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _zombieIdToApprovedAddress;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _ownerAddressToOperatorApprovals;
    // Mapping from the owner to the mapping of the zombie token index on the zombie token id
    mapping(address => mapping(uint256 => uint256)) private _ownerAddressToOwnedZombies2Indexes;
    // Mapping from the zombieId to the actual zombie
    mapping(uint256 => Zombie) private _zombies;

    // Event will be fired when a new zombie will be created
    event ZombieGenerated(uint zombieId, string zombieName);

    constructor (string memory zombieTokenName, string memory zombieTokenSymbol, string memory zombieTokenBaseLink) {
        _zombieTokenName = zombieTokenName;
        _zombieTokenSymbol = zombieTokenSymbol;
        _zombieTokenBaseLink = zombieTokenBaseLink;
	}

    /**
     * @dev Function returns 16 digits number for a corresponding given string.
     */
    function _generateRandomDna(string memory str) private view returns (uint) {
        bytes memory binarizedStr = abi.encodePacked(str); // We encode given string and
                                                           // receive encoded bytes
        bytes32 hashedStr = keccak256(binarizedStr); // We hash the bytes representation of the given string
                                                     // to receive a hash in bytes
        uint rand = uint(hashedStr); // We cast bytes hash to integer thus achive psevdo randomness.

        return rand % _dnaModulus;
    }

    /**
     * @dev Proceed the transdering from one account to another with a token
     * optionally with the data. Emit an event.
     */
    function _transferZombieToken(
        address from,
        address to,
        uint256 zombieTokenId
    ) private {
        _zombieIdToOwnerAddress[zombieTokenId] = to;
        _zombieOwnerAddressToZombiesCount[from].sub(1);
        _zombieOwnerAddressToZombiesCount[to].add(1);

        emit Transfer(from, to, zombieTokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            address sender = msg.sender;

            try IERC721Receiver(to).onERC721Received(sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Zombie: Transfer to non ERC721Receiver implementer.");
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
     * @dev Function to create new zombie by a given name for caller.
     */
    function generateRandomZombie(string memory zombieName) public returns (uint) {
        address zombieOwner = msg.sender;

        require(zombieOwner != address(0), "Zombie: Sender must not be zero address.");
        require(_zombieOwnerAddressToZombiesCount[zombieOwner] == 0, "Zombie: Sender must not have any zombies.");
        require(bytes(zombieName).length > 0, "Zombie: Name must be not an empty string.");
        require(_zombieOwnerAddressToZombiesCount[zombieOwner] == 0, "Zombie: No previous zombies must be owned.");

        uint256 zombieDna = _generateRandomDna(zombieName);

        require(_zombies[zombieDna].dna == 0, "Zombie: Zombie with such name exists.");
        
        _zombies[zombieDna] = Zombie(zombieName, zombieDna, 0, block.timestamp, 0, 0);
        _zombieOwnerAddressToZombiesCount[zombieOwner].add(1);
        _zombieIdToOwnerAddress[zombieDna] = zombieOwner;
        _allZombieIds.push(zombieDna);
        _ownerAddressToOwnedZombies2Indexes[zombieOwner][_allZombieIds.length] = zombieDna;

        emit ZombieGenerated(zombieDna, zombieName);

        return zombieDna;
    }

    /**
     * @dev Getter for a zombie.
     */
    function getZombieByToken(uint256 tokenId) public view returns (Zombie memory) {
        return _zombies[tokenId];
    }

    /**
     * @dev Implementation to receive name to support the token metadata functionality
     */
    function name() external view override returns (string memory _name) {
        return _zombieTokenName;
	}

    /**
     * @dev Implementation to receive symbol to support the token metadata functionality
     */
    function symbol() external view override returns (string memory _symbol) {
        return _zombieTokenSymbol;
    }
    
    /**
     * @dev Implementation to receive tokenURI to support the token metadata functionality
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
    	require(_zombieIdToOwnerAddress[tokenId] != address(0), "Zombie: Token is not owned and does not exist.");

        uint256 zombieDna = _zombies[tokenId].dna;
        uint256 zombieDnaSliced = zombieDna / (10 ** 12); // Crutch
        string memory stringifiedZombieDna = Utils.toString(zombieDnaSliced);
        string memory zombieTokenUri = string(abi.encodePacked(_zombieTokenBaseLink, "0000", stringifiedZombieDna, "-zombie.json"));

        return zombieTokenUri;
    }

    /**
     * @dev Implementation to receive the total balance to support the token metadata functionality
     */
    function balanceOf(address zombieOwner) external view override returns (uint256 balance) {
        require(zombieOwner != address(0), "Zombie: The owner must be valid owner.");

        return _zombieOwnerAddressToZombiesCount[zombieOwner];
    }

    /**
     * @dev Implementation to receive the owner address to support the token metadata functionality.
     */
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        require(_zombieIdToOwnerAddress[tokenId] != address(0), "Zombie: The zombie must have owner and must exists.");

        return _zombieIdToOwnerAddress[tokenId];
    }

    /**
     * @dev Implementation to receive the owner approval for the operator to support the nft functionality.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _ownerAddressToOperatorApprovals[owner][operator];
    }

    /**
     * @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller
     * to support the nft functionality.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != address(0), "Zombie: Operator must be not zero address.");

        address owner = msg.sender;

        _ownerAddressToOperatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns the account approved for `tokenId` token to support the nft functionality.
     */
    function getApproved(uint256 tokenId) external view override returns (address operator) {
        require(_zombies[tokenId].dna != 0, "Zombie: Token must exist.");

        return _zombieIdToApprovedAddress[tokenId];
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account to support the nft functionality.
     */
    function approve(address to, uint256 tokenId) external override {
        address approver = msg.sender;
        address zombieOwner = _zombieIdToOwnerAddress[tokenId];

        require(zombieOwner != to, "Zombie: Can not be approved for the owner of the token.");
        require(
            zombieOwner == approver || isApprovedForAll(zombieOwner, approver), 
            "Zombie: Token can be approved only by a holder of the token or approver must be validated by the owner."
        );

        _zombieIdToApprovedAddress[tokenId] = to;

        emit Approval(zombieOwner, to, tokenId);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        address zombieOwner = _zombieIdToOwnerAddress[tokenId];
        require(_zombies[tokenId].dna != 0, "Token must exist.");
        require(from != address(0), "Zombie: From must be not a zero address.");
        require(to != address(0), "Zombie: To must be not a zero address.");
        require(
            zombieOwner == from || this.getApproved(tokenId) == from || this.isApprovedForAll(zombieOwner, from),
            "Zombie: From must be an token owner or approved to perform that action."
        );

        _transferZombieToken(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override{
        this.transferFrom(from, to, tokenId);

        require(_checkOnERC721Received(from, to, tokenId, ""), "Zombie: Transfer to non ERC721Receiver implementer.");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override{
        this.transferFrom(from, to, tokenId);

        require(_checkOnERC721Received(from, to, tokenId, data), "Zombie: Transfer to non ERC721Receiver implementer.");
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view override returns (uint256) {
        return _allZombieIds.length;
    }

    /**
     * @dev  Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        uint256 zombieTokenId = _ownerAddressToOwnedZombies2Indexes[owner][index];

        require(owner != address(0), "Zombie: Owner must not be 0 address.");
        require(_zombieIdToOwnerAddress[zombieTokenId] == owner, "The token id on idex must be owned by owner.");

        return zombieTokenId;
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view override returns (uint256) {
        require(index < this.totalSupply(), "Zombie: Global index out of bounds.");

        return _allZombieIds[index];
    }

    /**
     * @dev Returns true if this contract implements the interface defined.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OleksandrBakhmach Contracts v1.0.0

pragma solidity ^0.8.0;

/**
 * @title Uint
 * @dev Math operations with safety checks that throw on error
 */
library Uint {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

/**
 * @title Uint32
 * @dev Uint library implemented for uint32
 */
library Uint32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Uint16
 * @dev Uint library implemented for uint16
 */
library Uint16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;

        assert(c / a == b);

        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);

        return c;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// Oleksandr Bakhmach Contracts

pragma solidity ^0.8.0;

contract Utils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    /**
     * Perform slicing from begin to end on text
    */
    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
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
// Oleksandr Bakhmach Contracts

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}