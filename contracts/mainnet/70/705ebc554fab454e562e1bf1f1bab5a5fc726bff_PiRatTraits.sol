/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IPiRats.sol



pragma solidity ^0.8.0;


interface IPiRats is IERC721 {

    struct CrewCaptain {
        bool isCrew;
        uint8 body;
        uint8 clothes;
        uint8 face;
        uint8 mouth;
        uint8 eyes;
        uint8 head;
        uint8 legendRank;
    }
    
    function paidTokens() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function mintPiRat(address recipient, uint16 amount, uint256 seed) external;
    function plankPiRat(address recipient, uint16 amount, uint256 seed, uint256 _burnToken) external;
    function getTokenTraits(uint256 tokenId) external view returns (CrewCaptain memory);
    function isCrew(uint256 tokenId) external view returns(bool);
    function getBalanceCrew(address owner) external view returns (uint16);
    function getBalanceCaptain(address owner) external view returns (uint16);
    function getTotalRank(address owner) external view returns (uint256);
    function walletOfOwner(address owner) external view returns (uint256[] memory);
    function getTotalPiratsMinted() external view returns(uint256 totalPiratsMinted);
    function getTotalPiratsBurned() external view returns(uint256 totalPiratsBurned);
    function getTotalPirats() external view returns(uint256 totalPirats);
  
}
// File: contracts/IPOTMTraits.sol



pragma solidity ^0.8.0;


interface IPOTMTraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function selectMintTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
  function selectPlankTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
}
// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/POTMTraits.sol



pragma solidity ^0.8.0;





////////////////////////////////
//     ╔═╗╦╦═╗╔═╗╔╦╗╔═╗       //
//     ╠═╝║╠╦╝╠═╣ ║ ╚═╗       //
//     ╩  ╩╩╚═╩ ╩ ╩ ╚═╝       //
//     ╔═╗╔═╗  ╔╦╗╦ ╦╔═╗      //
//     ║ ║╠╣    ║ ╠═╣║╣       //
//     ╚═╝╚     ╩ ╩ ╩╚═╝      //
//╔╦╗╔═╗╔╦╗╔═╗╦  ╦╔═╗╦═╗╔═╗╔═╗//
//║║║║╣  ║ ╠═╣╚╗╔╝║╣ ╠╦╝╚═╗║╣ //
//╩ ╩╚═╝ ╩ ╩ ╩ ╚╝ ╚═╝╩╚═╚═╝╚═╝//
////////////////////////////////

contract PiRatTraits is Ownable, IPOTMTraits {

  using Strings for uint256;

  struct Trait {
    string name;
    string png;
  }

  string[7] private _traitTypes = [
    "Body",
    "Clothes",
    "Face",
    "Mouth",
    "Eyes",
    "Head",
    "Legend Rank"
  ];

  string[3] private _captainRanks = [
    "8",
    "9",
    "10"
  ];

  string[7] private _crewRanks = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7"
  ];

  mapping(uint8 => mapping(uint8 => Trait)) private traitData;

  IPiRats public potm;

    // list of probabilities for each trait type
    // 0 - 6 are associated with Crew, 7 - 11 are associated with Captains
    uint8[][14] private rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 6 are associated with Crew, 7 - 11 are associated with Captains
    uint8[][14] private aliases;

    constructor() {
        // A.J. Walker's Alias Algorithm //
        
        // CREW //
        // body
        rarities[0] = [15, 35, 55, 95, 125, 155, 175, 255];
        aliases[0] = [0, 1, 2, 3, 4, 5, 6, 7];
        // clothes
        rarities[1] = [51, 54, 57, 64, 72, 90, 194, 199, 202, 207, 212, 135, 177, 219, 141, 183, 225, 147, 189, 231, 135, 135, 135, 135, 246, 150, 150, 156, 165, 171, 180, 186, 195, 201, 210, 243, 255];
        aliases[1] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
        // face
        rarities[2] = [51 ,54 ,57, 64, 72, 90, 194, 199, 202, 207, 212];
        aliases[2] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        // mouth
        rarities[3] = [255, 120, 195, 45, 75];
        aliases[3] = [0, 1, 2, 3, 4];
        // eyes
        rarities[4] = [75, 180, 165, 120, 60, 150, 105, 195, 45, 225, 75, 45, 195, 120, 255];
        aliases[4] =  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
        // head
        rarities[5] = [77, 255, 128, 77, 153, 153, 153, 77, 153, 230, 77, 77, 77, 204, 179, 230, 77, 179, 128, 179, 153, 230, 77, 77, 102, 77, 153, 153, 204, 77];
        aliases[5] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
        // Legend
        rarities[6] = [255, 175, 125, 95, 55, 35, 15];
        aliases[6] = [0, 1, 2, 3, 4, 5, 6];      

        // CAPTAIN //
        // body
        rarities[7] = [15, 32, 32, 32, 32, 32, 16, 65];
        aliases[7] = [0, 1, 2, 3, 4, 5, 6, 7];
        // clothes
        rarities[8] = [153, 153, 255, 102, 77, 230];
        aliases[8] = [0, 1, 2, 3, 4, 5];
        // face
        rarities[9] = [243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255];
        aliases[9] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
        // mouth
        rarities[10] = [255, 120, 195, 45, 75];
        aliases[10] = [0, 1, 2, 3, 4];
        // eyes
        rarities[11] = [75, 180, 165, 120, 60, 150, 105, 195, 45, 225, 75, 45, 195, 120, 255];
        aliases[11] =  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
        // head
        rarities[12] = [153, 153, 255, 102, 77, 230];
        aliases[12] = [0, 1, 2, 3, 4, 5];
        // Legend
        rarities[13] = [255, 175, 125];
        aliases[13] = [0, 1, 2]; 
    }

  /// ADMIN ///

  function setPOTM(address _potm) external onlyOwner {
    potm = IPiRats(_potm);
  }

  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitData[traitType][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].png
      );
    }
  }

  /// SELECT TRATIS ///

    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    function selectMintTraits(uint256 seed) external override view returns (IPiRats.CrewCaptain memory t) {
    require(_msgSender() == address(potm), "You cannot do that - selectMintTraits");  
        t.isCrew = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isCrew ? 0 : 7;
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.face = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.legendRank = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    }

    function selectPlankTraits(uint256 seed) external override view returns (IPiRats.CrewCaptain memory t) {
    require(_msgSender() == address(potm), "You cannot do that - selectPlankTraits");  
        t.isCrew = (seed & 0xFFFF) % 25 != 0;
        uint8 shift = t.isCrew ? 0 : 7;
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.face = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.legendRank = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    }

  /// RENDER ///

  function drawTrait(Trait memory trait) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
      trait.png,
      '"/>'
    ));
  }

  function drawSVG(uint256 tokenId) internal view returns (string memory) {
    string memory svgString;
    IPiRats.CrewCaptain memory s = potm.getTokenTraits(tokenId);
    if (s.isCrew) {
    svgString = string(abi.encodePacked(
      drawTrait(traitData[0][s.body]),
      drawTrait(traitData[1][s.clothes]),
      drawTrait(traitData[2][s.face]),
      drawTrait(traitData[3][s.mouth]),
      drawTrait(traitData[4][s.eyes]),
      drawTrait(traitData[5][s.head])
    ));
  } else {
    svgString = string(abi.encodePacked(
      drawTrait(traitData[0][s.body]),
      drawTrait(traitData[8][s.clothes]),
      drawTrait(traitData[9][s.face]),
      drawTrait(traitData[3][s.mouth]),
      drawTrait(traitData[4][s.eyes]),
      drawTrait(traitData[12][s.head])
    ));
  }
  return string(abi.encodePacked(
    '<svg id="potm" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
    svgString,
    "</svg>"
   ));
 }

  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  function compileAttributes(uint256 tokenId) internal view returns (string memory) {
    IPiRats.CrewCaptain memory s = potm.getTokenTraits(tokenId);
    string memory traits;
    if (s.isCrew) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.body].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.clothes].name),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.face].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[3][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[4][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[5][s.head].name),',',
        attributeForTypeAndValue("Legend Rank", _crewRanks[s.legendRank]),','
      ));
    } else {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.body].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[8][s.clothes].name),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[9][s.face].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[3][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[4][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[12][s.head].name),',',
        attributeForTypeAndValue("Legend Rank", _captainRanks[s.legendRank]),','
      ));
    }

    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Generation","value":',
      tokenId <= potm.paidTokens() ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Type","value":',
      s.isCrew ? '"Crew"' : '"Captain"',
      '}]'
    ));
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_msgSender() == address(potm), "You cannot do that - tokenURI");
    IPiRats.CrewCaptain memory s = potm.getTokenTraits(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      s.isCrew ? 'Crew #' : 'Captain #',
      tokenId.toString(),
      '", "description": "Thousands of Captains and their trusty Crew set sail on a voyage across the metaverse. A treasure of $BOOTY awaits, but danger and rough seas lay ahead. All the metadata and images are generated and stored 100% on-chain. No website, No IPFS. No API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
      base64(bytes(drawSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }

}
// 0xHooch //