/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/* 
   SPDX-License-Identifier: MIT

    SHADOW NFT
    ==========

    Author: Alex Van de Sande

    This is a very simple contract that will create a "virtual NFT", by shadowing an existing NFT
    The virtual NFT requires no minting or on chain interaction, but will repeat the state of the
    shadow-caster token. If you have a balance on the original you'll have a balance on the shadow.

    The current version does not allow transfers, it should be considered "soulbound" to the original
    token. One could in theory allow you to mint a new NFT from the shadow in a future development.

    This was created with the intent of facilitating adding NFT avatars to ENS names. 

    The arts on the shadow NFT can be anything you want. I am using Robohash (https://github.com/e1ven/Robohash) 
    and dicebear but I strongly encourage artists to fork them and create their own sets. Robohash was
    created by Colin Davies and other contributors and the code is available under the MIT/Expat license.
    DiceBear was created b Florian Koerner and other contributors and is also under MIT. 
    
    The collection set arts are all licensed under CC requiring attribution:

    ### Robohash
    (https://robohash.org/SEED.png?set=set2&size=1200x1200&bgset=bg2) 

    * Robots/"set1" artwork (and robohash backgrounds) were created by Zikri Kader. 
    They are available under CC-BY-3.0 or CC-BY-4.0 license. Variants: 1M Robots.

    * Monsters/"set2" artwork was created by Hrvoje Novakovic. They are available under CC-BY-3.0 license. Variants: 16M Monsters.

    * Robot heads/"set3" artwork was created by Julian Peter Arias. They are available under CC-BY-3.0 license. Variants: 12,830,400 droids.

    * Cats/"set4" were created by David Revoy, used under CC-BY-4.0. Variants: 360k cats.
    
    * Avataaars/"set5" were uploaded by Simon Franz, MIT Licensed (derived from the repo). Variants: 1.141T Avatars.

    ### Dicebear
    (https://avatars.dicebear.com/api/adventurer/SEED.svg) 

    * Dicebear Adventurer by Lisa Wischofsky, Licensed under CC BY 4.0

    * Big Ears, by The Visual Team, licensed under CC BY 4.0

    * Big Smile, by Ashley Seo, licensed under CC BY 4.0

    * Bottts by Pablo Stanley

    * Pixel Art by Florian Korner, inspired by 8biticon

    * Croodles by Vijay Verna, licensed under CC BY 4.0

    Robohash has a low entropy, and should not be considered safe from collision attacks. 
    Do not use it for important stuff.
    Do not sell other people's art as yours.

*/
// File: @openzeppelin/contracts/utils/Strings.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/shadowNFTSimple.sol

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



// import "samplenft.sol";

interface NFT {
    function balanceOf(address owner) view external returns (uint256);
    function ownerOf(uint256 tokenId) view external  returns (address);
}

contract shadowNFT is  Ownable {
    using Strings for uint256;
    
    // The token that is used to create the shadow token
    NFT public caster;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Base URI
    string public baseURI;

    // Suffix
    string public suffix;
    
    // Description
    string public description;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event AttributesChanged( string tokenPrefix, string tokenSuffix);

    constructor(
        string memory tokenName, 
        string memory tokenSymbol, 
        string memory tokenPrefix, 
        string memory tokenSuffix,
        string memory tokenDescription) {
        // ENS Registrar on main and goerli: 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
        caster = NFT(address(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85));
        name= tokenName;
        symbol= tokenSymbol;
        description = tokenDescription;
        editAttributes(tokenPrefix,tokenSuffix);
    }


    /*
    @dev Allows Function Owner to edit the prefix, suffix, name, etc
    @notice Allows owner to edit the attributes
    it will show here as its own metadata. If not then it will revert
    */
    function editAttributes (string memory tokenPrefix, string memory tokenSuffix) public onlyOwner {
        
        baseURI = string(tokenPrefix);
        suffix = string(tokenSuffix);

        emit AttributesChanged(tokenPrefix,tokenSuffix);
    }
    
    // TokenURI: the important bit. Change this to your own data.
    /*
    @dev See {IERC721-balanceOf}.
    @notice overrides default behavior. If the token exists on the shadowcaster side, 
    it will show here as its own metadata. If not then it will revert
    */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        // _requireMinted(tokenId);
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        //?set=set5&size=500x500&bgset=bg2

        return string(abi.encodePacked(
            'data:application/json;charset=utf-8,{"name":"',
            name,
            '","description":"Robohash for ENS names","image":"',
            baseURI,
            tokenId.toString(),
            suffix,
            '"}'));
    }

    /*
    @dev See {IERC721-balanceOf}.
    @notice overrides default behavior, will reflect the Balance of the shadowcaster token
    */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        uint256 casterBalance = caster.balanceOf(owner);
        return casterBalance;
    }
  
    /*
    @dev See {IERC721-ownerOf}.
    @notice overrides default behavior, will reflect the Owner of the shadowcaster token
    */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner;
        
        owner = caster.ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        
        return owner;
    }

	/*
    @notice emit a Transfer event where from == to so that indexers can scan the token.
	This can be called by anyone at any time and does not change state.
	@param tokenID token to emit the event for.
    */
    function emitSelfTransferEvent(uint256 tokenId) public virtual {
        // Requires that the token actually exists
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        address tokenOwner = ownerOf(tokenId);
        emit Transfer(tokenOwner, tokenOwner, tokenId);
    }
}