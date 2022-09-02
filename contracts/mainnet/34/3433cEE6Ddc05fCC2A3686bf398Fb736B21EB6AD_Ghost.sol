// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Puppet.sol";
import "./values.sol";

//              ..              ';;,'.;.          ,,               
//              .'...           ,d:,'..        ...'                
//                 ..          'YYOd,          ..                  
//                        ..   .;:oY,    .'...                     
//            ,:.                     .'      ..   ....            
//     .,.  ...::,dd,::,;dd;. :YYYYYYo:..dYdYddd,ddd;        ..    
//      ;d:dYodOY00YYYYYTTTT0YYTTTTTTTTOYTTTTY0YO0T0do:,.';,..     
//      .::dYododdYYYYO0YYYTTTYTTYTTTYTYTTTTYO0OYdYYO0dddd,.  ..   
//      .,.';dddY:'',d0YTYYYTTYYTTTTYYYYTYYT0YYYd;;ddod:d:'..      
//      ....'';dd. ..d0YYYYYTYY0OO0YOYYYYY00YOdd;..,,;;d:'...      
//        ...';:,  'ddodd000YOYYodddddoooYYdoodoY:...'......       
//            ,d'   ,d:dddodd:'.;;. ....:d,,;do:..   ..            
//            .,.      ..;dd:d:ddd,'':odo::d:'.      ..            
//         ....'.         ...;;;do:',:;,:...        .'.'.          
//           .';'    ,Yd;.      .....      .:dOd    ...'.          
//          ':,'...  .dYYYY: ..        ...dYYYd.   ....::..        
//          'Yd.......  .,,.   .ddd::'    .,.   ...,'..d:..        
//          :o.  ......  ..',..oYTYYYd;.......''..... .:;.         
//        ....         ...,;:,':::ddd;';,'';;,;. ..       ..       
//        ..           ..   .';..    ..'.... ..            .       
//                       .  .. ......  ..                          
//          ..                                                     
//           .                                  ..      ..         
//                       .      ..       ..                        
//              .. ..         ....                                 
//             ...                                                 
//           ..'.                .                     ..   .'...  
//         .,'.            ..                          '....oOd;:. 
//       .',.            ..            .   ..         .'.,;..;o:'. 
//     .,,'..                               ..           .:..,;... 
//    .'....        .'.                    ... ..                  
//   ,,....         .'.                    ...,,'             
    
// Seppuku is an ancient geometrical form;  
contract Ghost is Puppet, Sacrifice {

    event Seppuku(address token, uint samuraiId, uint spiritId);
    mapping(uint => uint) private _commits;
    Hand private _samurai;

    function seppuku(uint samuraiId) external {
        // Transfer your samurai to the ghost;
        address you = msg.sender;
        address ghost = address(this);
        _samurai.transferFrom(you, ghost, samuraiId);

        //  Mint a spirit in return;
        uint spiritId = _mint(msg.sender);
        _commits[spiritId] = block.number;

        // Seppuku;
        emit Seppuku(address(_samurai), samuraiId, spiritId);
    }

    function lastCommit(uint spiritId) external view returns (uint) {
        return _commits[spiritId];
    }

    constructor(address origin, Hand samurai, string memory baseURI) Puppet(
        "GHOST", 
        "GHOST",
        origin,
        baseURI
    ) { _samurai = samurai; }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../utils/Origin.sol";
import "./values.sol";

abstract contract Puppet is Origin, Honor {
    string private _baseURI = "";

    function tokenURI(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Unknown token");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    function setBaseURI(string memory uri) external onlyOrigin {
        _baseURI = uri;
    }

    constructor(
        string memory name,
        string memory symbol,
        address origin,
        string memory baseURI
    ) Origin(origin) Honor(name, symbol) {
        _baseURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract Hand is IERC721 {}

abstract contract Honor is IERC721, ERC165 {
    string private _name;
    string private _symbol;
    uint private _total;

    mapping(address => uint) private _balances;
    mapping(uint => address) private _owners;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint) {
        return _total;
    }

    function balanceOf(address owner) external view returns (uint) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }
    
    function _mint(address to) internal returns (uint) {
        require(to != address(0), "Honor is not yours");

        _total += 1;
        _balances[to] += 1;
        _owners[_total] = to;

        emit Transfer(address(0), to, _total);

        return _total;
    }

    function _exists(uint tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
}

abstract contract Sacrifice is IERC721 {
    function safeTransferFrom(address, address, uint256, bytes calldata) pure external {
        revert("Honor is not transferable");
    }

    function safeTransferFrom(address, address, uint256) pure external {
        revert("Honor is not transferable");
    }

    function transferFrom(address, address, uint256) pure external {
        revert("Honor is not transferable");
    }

    function approve(address, uint256) pure external {
        revert("Honor is not for sale");
    }

    function getApproved(uint256) pure external returns (address) {
        revert("Honor is not for sale");
    }

    function setApprovalForAll(address, bool) pure external  {
        revert("Honor is not for sale");
    }

    function isApprovedForAll(address, address) pure external returns (bool) {
        return false;
    }
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
pragma solidity ^0.8.9;

contract Origin {
    address private _address;
    address private _provenance; 

    event Move(address indexed previousAddress, address indexed newAddress);
    event Relinquish(address provenance);

    modifier onlyOrigin() {
        bool active = _address == msg.sender && _address != address(0);
        require(active, "Caller is not the ORIGIN");
        _;
    }

    function originAddress() public view returns (address) { 
        return _address; 
    }    
    
    function originProvenance() public view returns (address) { 
        return _provenance; 
    }

    function moveOrigin(address newAddress) external onlyOrigin {
        address previousAddress = _address;
        _address = newAddress;
        emit Move(previousAddress, newAddress);
    }

    function relinquishOrigin() external onlyOrigin {
        _provenance = _address;
        _address = address(0);
        emit Relinquish(_provenance);
    }

    constructor(address addr) {
        _address = addr;
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