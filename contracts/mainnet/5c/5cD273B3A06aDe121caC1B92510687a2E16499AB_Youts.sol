//SPDX-License-Identifier: CC0-1.0

/*                                                                      

`YMM'   `MM' .g8""8q. `7MMF'   `7MF'MMP""MM""YMM  .M"""bgd                                                                 
  VMA   ,V .dP'    `YM. MM       M  P'   MM   `7 ,MI    "Y                                                                 
   VMA ,V  dM'      `MM MM       M       MM      `MMb.         gp                                                          
    VMMP   MM        MM MM       M       MM        `YMMNq.     ""                                                          
     MM    MM.      ,MP MM       M       MM      .     `MM                                                                 
     MM    `Mb.    ,dP' YM.     ,M       MM      Mb     dM     ,,                                                          
   .JMML.    `"bmmd"'    `bmmmmd"'     .JMML.    P"Ybmmd"      db                                                          
                                                                                                                        
                                                                                                                           
 ..|'''.|  '||''''|  '|.   '|' '||''''|  '||''|.       |     |''||''| '||'  ..|''||   '|.   '|'  .|'''.|  
.|'     '   ||  .     |'|   |   ||  .     ||   ||     |||       ||     ||  .|'    ||   |'|   |   ||..  '  
||    ....  ||''|     | '|. |   ||''|     ||''|'     |  ||      ||     ||  ||      ||  | '|. |    ''|||.  
'|.    ||   ||        |   |||   ||        ||   |.   .''''|.     ||     ||  '|.     ||  |   |||  .     '|| 
 ''|...'|  .||.....| .|.   '|  .||.....| .||.  '|' .|.  .||.   .||.   .||.  ''|...|'  .|.   '|  |'....|'  


    On-chain art by ok_0S (weatherlight.eth). 2022.

    // 6,969 Youts
    // Fully on-chain SVG artwork
    // Most (non-Special) Youts can toggleDarkMode()
    // Special Themes inspired by legendary NFT collections

    gm.

    "A fully on-chain gang of misfits and weirdos for everyone. CC0."
    
    That's the description set for Youts, and it's really means what
    it says. Youts are for everyone, and they're CC0, so they're for
    everyone to do with them what they want. I hope you take your 
    Youts and run with them. Go wild.

    Youts: Generations tokens are fully on-chain, and the contract was
    developed to allow full visibility into all components from within
    the Etherscan interface. Youts are SVG images and therefore may
    not be displayable in certain wallets or implementations that
    don't support SVGs.

    Youts: Generations is a love letter to the NFT scene of 2021-2022.
    This collection would not be possible without the community, and
    especially the following collections and the people who created
    them. Noted with each of these legendary collections is a brief
    note on how that inspiration has manifested in Youts: Generations.


    - Manny's Game
        * "Gamer" Theme
        * Special thanks to all Mannys for the last year of learning
          and bagel rinsing. Best community in web3.

    - OKPC
        * Light / Dark mode rendering toggle.
        * Special thanks to the OKPC team for the inspo for making
          dynamic on-chain NFTs 
    
    - Shields
        * Base Theme Color Scheme Inspiration
        * "Heraldry" Theme
        * Special thanks to the Shields team for the inspo for using
          separate contracts for component pieces
    
    - LOOT
        * "Inventory" Theme
        * Divine Robes and Divine Orders
        * Special thanks to Dom for making on-chain SVG understandable
        * Special thanks to DivineDAO for the Divine Order glyphs
    
    - Corruption(s*)
        * "Ion" Theme 
        * Special thanks to Dom for showing how to shed responsibility
        * Special thanks to the Corruption(s*) community for showing
          how a communities can prop themselves up. 
    
    - BLOOT
        * "Deriv" Theme
        * Thanks to the BLOOT team for all the memes.

    - Shinsei Galverse
        * "Gal" Theme
        * Special thanks to the Galverse team for being in it for the
          right reasons.

    - Nouns
        * "Nounish" Theme
        * "Nounish" Face
        * Special thanks to NounsDAO for doing it iconic.
    
    - CryptoPunks
        * "2017" Theme
        * Special thanks to CryptoPunks. Acknowledge your elders.
    
    
    Countless other collections and individuals inspired elements of 
    Youts: Generations; my gratitude is real.

    May all who inspire vibe eternally. 

    | ~~~
    |  ACKNOWLEDGE:
    |  Youts are experimental art.
    |  This contract is unaudited.
    |  There is no roadmap.
    |  Absolutely no promises have been made.
    | ~~~

    Sound good? Mint directly from the contract.

    Follow @YoutsNFT on twitter.

*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "./YoutsMetadata.sol";

interface IYouts {
    function getDarkMode(uint256 tokenId) external view returns (bool);
}

/** @title Youts - Main contract 
  * @author @ok_0S / weatherlight.eth
  * The main contract for Youts. ERC721 with upgradeable metadata contracts.
  */
contract Youts is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    mapping(uint256 => bool) public darkTokens;
	address public metadataAddress;
	bool public mintIsActive;
    uint256 public mintPrice = 50000000000000000;
    uint256 public togglePrice = 10000000000000000;


    /** @dev Initialize the Youts Metadata contract. Mint the first 69 Youts to the contract owner.
        * @param _metadataAddress Address of Youts Metadata Contract 
        */
    constructor(address _metadataAddress) 
        ERC721("Youts", "YOUTS") 
        Ownable() 
    {
		metadataAddress = _metadataAddress;
	}


    /** @dev Start or pause the mint.
        * @param status "true" will enable minting; "false" will disable 
        */
    function setMintState(bool status)
        external
        onlyOwner
    {
      mintIsActive = status;
    }


	/** @dev Sets the price for mints.  
      * @notice Only callable by the contract owner.
	  * @param price Value expressed in wei 
	  */
    function setMintPrice(uint256 price)
        external
        onlyOwner
    {
      mintPrice = price;
    }


	/** @dev Sets the price for toggling Dark Mode.  
      * @notice Only callable by the contract owner.
	  * @param price Value expressed in wei 
	  */
    function setTogglePrice(uint256 price)
        external
        onlyOwner
    {
      togglePrice = price;
    }


	/** @dev Sets the address for the Metadata contract. Allows for upgrading contract.  
      * @notice Only callable by the contract owner.
	  * @param addr Address of Metadata Contract 
	  */
	function setMetadataAddress(address addr)
        public
        onlyOwner
    {
        metadataAddress = addr;
    }


    /** @dev Renders a JSON object containing the token's metadata and image. 
	  * @param tokenId A token's numeric ID. 
	  */
	function tokenURI(uint256 tokenId)
        override
        public
        view
        returns (string memory) 
    {
        if (!_exists(tokenId)) revert YoutNotFound();
        return 
            IYoutsMetadata(metadataAddress).tokenURI(tokenId, address(this));
    }
    

    /** @dev Mint a Yout for 0.05 ETH.
	  */
	function mint()
        public
        payable
        nonReentrant
    {   
        require(mintIsActive, "Youts: Minting is not available right now");
        require(msg.value == mintPrice, "Youts: 0.05 ETH to mint");
        require(totalSupply() < 6970, "Youts: All Youts claimed");
    	_doMint();
    }


    /** @dev Mint up to 10 Youts at once.
      * @param quantity A number of Youts to mint. 
	  */
    function mintQuantity(uint256 quantity) 
        public 
        payable
        nonReentrant 
    {
        require(mintIsActive, "Youts: Minting is not available right now");
        require(msg.value == mintPrice * quantity, "Youts: Transaction value must equal (mintPrice * quantity)");
        require(quantity < 11, "Youts: Try minting less than 10 Youts at once");
        require(quantity > 0, "Youts: You can't mint 0 Youts, ya goof");
        require(totalSupply() < 6970 - quantity, "Youts: All Youts claimed");
        uint256 i = 0;
        while (i < quantity) {
            _doMint();
            i++;
        }
    }


    /** @dev Mint a number of Youts at no cost, regardless of sale status.
      * @notice Only callable by the contract owner.
      * @param quantity A number of Youts to mint. 
	  */
    function ownerMint(uint256 quantity) 
        public 
        nonReentrant 
        onlyOwner 
    {
        require(totalSupply() < 6970 - quantity, "Youts: All Youts claimed");
        uint256 i = 0;
        while (i < quantity) {
            _doMint();
            i++;
        }
    }


    /** @dev Mints a token, increments the token counter, and sets Dark Mode "on" for a few tokens.
      * @notice All of these steps must be performed when minting a token to maintain correct state.
	  */
    function _doMint() 
        internal
    {   
        _mint(msg.sender, totalSupply());
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        initializeDarkMode(tokenId);
    }


    /** @dev Toggles Dark Mode "on" for ~10% of tokens
      * @param tokenId A token's numeric ID. 
	  */
    function initializeDarkMode(uint256 tokenId)
        internal
    {           
        if (IYoutsMetadata(metadataAddress).isToggleable(tokenId, address(this)) == true && uint256(keccak256(abi.encodePacked("DARKMODE", tokenId))) % 10 == 0) {
            _toggleDarkMode(tokenId);
        }
    }


    /** @dev 
      * @param tokenId A number of Youts to mint. 
	  */
    function toggleDarkMode(uint256 tokenId) 
        external
        payable 
        onlyOwnerOf(tokenId) 
    {
        require(msg.value == togglePrice, "Youts: Payment doesn't match togglePrice");
        require(IYoutsMetadata(metadataAddress).isToggleable(tokenId, address(this)) == true, "Youts: Youts with special themes can't be toggled");
        _toggleDarkMode(tokenId);
    }


    /** @dev 
      * @param tokenId A token's numeric ID.  
	  */
    function _toggleDarkMode(uint256 tokenId) 
        internal 
    {
        darkTokens[tokenId] = !darkTokens[tokenId];
    }


    /** @dev 
      * @param tokenId A token's numeric ID. 
	  */
    function getDarkMode(uint256 tokenId) 
        external
        view
        returns (bool)
    {   
        return
            darkTokens[tokenId];
    }


    /** @dev Transfer the contract's balance to the contract owner.
      * @notice Only callable by the contract owner.
	  */
	function withdrawAvailableBalance() 
        public  
        onlyOwner 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    

    /** @dev Requires the caller to be the owner of the specified tokenId.
	  * @param tokenId A token's numeric ID. 
    */
    modifier onlyOwnerOf(uint256 tokenId)
    {
        if (msg.sender != ownerOf(tokenId)) revert NotYoutOwner();
        _;
    }

    error NotYoutOwner();
    error YoutNotFound();

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "./Youts.sol";
import "./Body.sol";
import "./Face.sol";
import "./Outfit.sol";
import "./Surround.sol";

interface IYoutsMetadata {
    function isToggleable(uint256 tokenId, address youtsAddress) external view returns (bool);
    function tokenURI(uint256 tokenId, address youtsAddress) external view returns (string memory);
}

/** @title Youts - Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract YoutsMetadata is Ownable, IYoutsMetadata {
	using Strings for uint256;

	struct Themes {
		string[10] themeName;
		string[10] bgColor;
		string[10] fillColor;
		string[10] faceColor;
		string[10] outfitColor;
		string[10] surroundColor;
		string[10] bodyColor;
		string[10] shadowColor;
	}

	address public bodyAddress;
	address public faceAddress;
	address public outfitAddress;
	address public surroundAddress;
	Themes themes;

	string[11] private bodyColorNames = [
		"Argent",
		"Gilt", 
		"Chromat",
		"Scarlet",
		"Tiger",
		"Goldenrod",
		"Hi-vis",
		"Mint",
		"Sapphire",
		"Peri",
		"Magenta"
	];


	/** @dev Initialize metadata contracts and theme data  
	  * @param _bodyAddress Address of Body Metadata Contract 
	  * @param _faceAddress Address of Face Metadata Contract 
	  * @param _outfitAddress Address of Outfit Metadata Contract 
	  * @param _surroundAddress Address of Surround Metadata Contract 
	  */ 
	constructor(
		address _bodyAddress,
		address _faceAddress,
		address _outfitAddress,
		address _surroundAddress
	) Ownable() {
		bodyAddress = _bodyAddress;
		faceAddress = _faceAddress;
		outfitAddress = _outfitAddress;
		surroundAddress = _surroundAddress;
		themes = Themes(
			['Light',		'Dark',			'Gal',			'Heraldry',     'Nounish', 		'2017',			'Inventory', 	'Deriv',		'Ion',       	'Gamer'	 ],
			['#FCFCFC',		'#424158',		'#29009A',		'#1C1D1F',	   	'#E1D7D5',		'#648596',		'#000',			'#01FF01',		'#000',			'#FFF'	 ],
			['#FFF',		'none',			'#511ADEAA',	'none',   		'#FFF', 		'#C9FBFC',		'none',			'none',			'none',			'#F9DECD'],
			['#222',		'#F3F2FC',		'#D843F0',		'#EEEEEE',	   	'#FE0C0C',		'#000',			'#FFF',			'#000',			'#CA0097',		'#080808'],
			['#222',		'#F3F2FC',		'#5AC1FA',		'#C6C6C6',	   	'#FE0C0C',		'#353535',		'#FFF',			'#000',			'#CA0097',		'#080808'],
			['#222',		'#F3F2FC',		'#D843F0',		'#EEEEEE',	   	'#FE0C0C',		'#000',			'#FFF',			'#000',			'#CA0097',		'#080808'],
			['none',		'none',			'#8E47D5',		'#EB2D6F', 	   	'#807F7E',		'#000', 		'#FFF', 		'#000', 		'#6C0050', 		'#D69784'],
			[
				'0 0 0 0 0     0 0 0 0 0     0 0 0 0 0     0 0 0 0.25 0',		// Light
				'0 0 0 0 0     0 0 0 0 0     0 0 0 0 0     0 0 0 0.35 0',		// Dark
				'0 0 0 0 0.216 0 0 0 0 0.039 0 0 0 0 0.31  0 0 0 1    0',		// Gal
				'0 0 0 0 0.444 0 0 0 0 0.136 0 0 0 0 0.758 0 0 0 1    0',		// Heraldry
				'0 0 0 0 0.384 0 0 0 0 0.380 0 0 0 0 0.427 0 0 0 1    0',		// Nounish
				'0 0 0 0 0.525 0 0 0 0 0.322 0 0 0 0 0.082 0 0 0 1    0',		// 2017
				'0 0 0 0 0.479 0 0 0 0 0.479 0 0 0 0 0.479 0 0 0 1    0',		// Inventory
				'0 0 0 0 0.004 0 0 0 0 0.749 0 0 0 0 0.004 0 0 0 1    0',		// Deriv
				'0 0 0 0 0.267 0 0 0 0 0     0 0 0 0 0.196 0 0 0 1    0',		// Ion
				'0 0 0 0 0.439 0 0 0 0 0.686 0 0 0 0 0.267 0 0 0 1    0'		// Gamer
			]
		);
	}


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
	function setBodyAddress(address addr) public onlyOwner {
        bodyAddress = addr;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
	function setFaceAddress(address addr) public onlyOwner {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Outfit Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Outfit Metadata Contract 
	  */
	function setOutfitAddress(address addr) public onlyOwner {
        outfitAddress = addr;
    }


	/** @dev Sets the address for the Surround Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Surround Metadata Contract 
	  */
	function setSurroundAddress(address addr) public onlyOwner {
        surroundAddress = addr;
    }


	/** @dev Returns a Base-64 encoded string containing a token's full JSON metadata  
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function tokenURI(uint256 tokenId, address youtsAddress)
		override
		public 
		view 
		returns (string memory) 
	{
		bool robeCheck = IBody(bodyAddress).isRobed(tokenId);

		return string(abi.encodePacked(
			"data:application/json;base64,",
			Base64.encode(
				bytes(abi.encodePacked(
					'{"name":"',
						string(
							abi.encodePacked("Youts #", tokenId.toString())
						),
					'", "description":"',
						"Youts are a fully on-chain gang of misfits and weirdos for everyone. CC0.",
					'", "attributes": [',
						_metadata(tokenId,youtsAddress),',',
						IFace(faceAddress).metadata(tokenId),',',
						IBody(bodyAddress).metadata(tokenId), robeCheck ? '' : ',',
						IOutfit(outfitAddress).metadata(tokenId), robeCheck ? '' : ',',
						ISurround(surroundAddress).metadata(tokenId),
					'], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(renderSVG(tokenId,youtsAddress))),
					'"}'
				))
			)
		));
	}

	
	/** @dev Returns a string containing a token's SVG container
	  * @param tokenId A token's numeric ID. 
  	  * @param youtsAddress The address of the main Youts contract 
	  */
	function renderSVG(uint256 tokenId,address youtsAddress)
		public
		view
		returns (string memory)
	{
		return string(abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" width="940" height="940" fill="none">',
				'<defs>',
					'<style>',
						'path,line{stroke-width:25px}',
						'circle,path,ellipse,line,rect{stroke-linejoin:round;shape-rendering:geometricPrecision}',
						'rect,.mJ{stroke-linejoin:miter !important}',
						'.bg{fill:#fff;fill-opacity:.01}',
						'.nS{stroke:none !important}',
						'.r{stroke-linejoin:round;stroke-linecap:round}',
						'.eO{fill-rule:evenodd;clip-rule:evenodd}',
						'.s0{stroke-width:25px}',
						'.s1{stroke-width:10px}',
						'.s2{stroke-width:20px}',
						'.s3{stroke-width:30px}',
						'.s4{stroke-width:31px}',
						'.i{r:12;}',
					'</style>',				
				'</defs>',
				_renderTheme(tokenId, youtsAddress),
				_renderFigure(tokenId),
			'</svg>'
		));
	}
	

	/** @dev Returns true if a token can toggleDarkMode()
	  * @notice Only non-Special themed Youts can toggleDarkMode()
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function isToggleable(uint256 tokenId, address youtsAddress)
		override
		external
		view
		returns (bool)
	{
		return
			_themeIndex(tokenId, youtsAddress) < 2;
	}


	/** @dev Renders theme metadata
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function _metadata(uint256 tokenId, address youtsAddress) 
        internal
        view
        returns (string memory)
    {
        string memory traits;
		uint256 themeIndex = _themeIndex(tokenId, youtsAddress);
		uint256 colorIndex = _colorIndex(tokenId);

        traits = string(abi.encodePacked(
			'{"trait_type":"Theme","value":"', themes.themeName[themeIndex], '"},', 
			'{"trait_type":"Toggleable","value":"', themeIndex < 2 ? 'True' : 'False' ,'"}'
        ));

		if (themeIndex < 2) {
			traits = string(abi.encodePacked(
				traits,',',
				'{"trait_type":"Body Color","value":"', bodyColorNames[colorIndex], '"},',
				'{"trait_type":"Body Color Type","value":"', colorIndex < 3 ? 'Gradient' : 'Solid', '"}' 
        	));
		}

        return traits;
    }	


	/** @dev Returns the theme index for a specified tokenId  
	  * @param tokenId A token's numeric ID
	  * @param youtsAddress The address of the main Youts contract 
	  */
	function _themeIndex(uint256 tokenId, address youtsAddress) 
		internal 
		view 
		returns (uint256)
	{
		uint256 themeIndex = uint256(keccak256(abi.encodePacked("THEME", tokenId))) % 10;
		bool darkMode = IYouts(youtsAddress).getDarkMode(tokenId);

		if (themeIndex < 8 && !darkMode) {
			themeIndex = 0;																										// Most are Light
		} else if (themeIndex < 8 && darkMode) {
			themeIndex = 1;																										// Some are Dark
		} else {
			themeIndex = (uint256(keccak256(abi.encodePacked("RARETHEME", tokenId))) % (themes.bgColor.length - 2)) + 2;		// The remaining are Special
		}

		return
			themeIndex;
	}
	

	/** @dev Returns the color index for a specified tokenId  
	  * @param tokenId A token's numeric ID
	  */
	function _colorIndex(uint256 tokenId) 
		internal 
		pure 
		returns (uint256)
	{
		uint256 colorIndex = uint256(keccak256(abi.encodePacked("COLOR", tokenId))) % 10;

		if (colorIndex == 0) {
			colorIndex = uint256(keccak256(abi.encodePacked("GRADIENT", tokenId))) % 3;
		} else { 
			colorIndex = (uint256(keccak256(abi.encodePacked("SOLID", tokenId))) % 8) + 3;
		}

		return
			 colorIndex;
	}


	/** @dev Returns a string containing the SVG elements that make up a token's figure
	  * @param tokenId A token's numeric ID. 
	  */
	function _renderFigure(uint256 tokenId)
		internal
		view
		returns (string memory)
	{
		string memory layer1;
		string memory layer2;
		if (IBody(bodyAddress).isRobed(tokenId)) {
			layer1 = string(
				abi.encodePacked(
					IBody(bodyAddress).element(tokenId)
				)
			);
			layer2 = string(
				abi.encodePacked(
					IBody(faceAddress).element(tokenId)
				)
			);
		} else {
			layer1 = string(
				abi.encodePacked(
					IBody(bodyAddress).element(tokenId),
					ISurround(surroundAddress).element(tokenId)
				)
			);
			layer2 = string(
				abi.encodePacked(
					IFace(faceAddress).element(tokenId),
					IOutfit(outfitAddress).element(tokenId)
				)
			);
		}
		return string(abi.encodePacked(
			'<g filter="url(#ds)">',
				layer1,
			'</g><g>',
				layer2,
			'</g>'
		));
	}
	


	/** @dev Returns a string containing the SVG elements that define a token's theme 
	  * @param tokenId A token's numeric ID. 
	  */
	function _renderTheme(uint256 tokenId, address youtsAddress)
        internal
        view
        returns (string memory)
    {
		string memory bodyColor;
		string memory gradient;
		string memory background;
		
		uint256 themeIndex = _themeIndex(tokenId, youtsAddress);

		if (themeIndex < 2) {
			
			uint256 colorIndex = _colorIndex(tokenId);
			
			string[11] memory bodyColors = [																					// Light and Dark have a random body color
				"url(#c_ag)", 	// Argent																						 
				"url(#c_au)", 	// Gilt																												
				"url(#c_ch)",  	// Chromat
				"#EF101C", 		// Scarlet
				"#FF6B00", 		// Tiger
				"#FFC700", 		// Goldenrod
				"#C1EE03", 		// Hi-vis
				"#00D67C", 		// Mint
				"#17B9DD", 		// Sapphire
				"#7B85F1", 		// Peri
				"#E21878" 		// Magenta
			];
			
			bodyColor = bodyColors[colorIndex];
			
			if (themeIndex == 0) {

				string[8] memory backgrounds = [																				// Light has two random background colors
					"0 0 0 0 0.94 0 0 0 0 0.06 0 0 0 0 0.11 0 0 0 0.06 0", 	// Scarlet 
					"0 0 0 0 0    0 0 0 0 0.84 0 0 0 0 0.49 0 0 0 0.06 0", 	// Mint
					"0 0 0 0 0.09 0 0 0 0 0.72 0 0 0 0 0.87 0 0 0 0.06 0", 	// Sapphire
					"0 0 0 0 0.48 0 0 0 0 0.52 0 0 0 0 0.95 0 0 0 0.06 0", 	// Peri
					"0 0 0 0 0.89 0 0 0 0 0.09 0 0 0 0 0.47 0 0 0 0.06 0", 	// Magenta
					"0 0 0 0 0.55 0 0 0 0 0.6  0 0 0 0 0.62 0 0 0 0.06 0", 	// Argent
					"0 0 0 0 0.28 0 0 0 0 0.19 0 0 0 0 0.8  0 0 0 0.06 0", 	// Chromat
					"0 0 0 0 0.99 0 0 0 0 0.49 0 0 0 0 0.21 0 0 0 0.06 0"  	// +1
				];
				
				uint256 bg1Index = uint256(keccak256(abi.encodePacked("BACKGROUND1", tokenId))) % (backgrounds.length - 1);
				uint256 bg2Index = uint256(keccak256(abi.encodePacked("BACKGROUND2", tokenId))) % (backgrounds.length - 1);

				if (bg1Index == bg2Index) {																						// Background colors never match
					bg2Index = bg1Index+1;
				}

				background = string(abi.encodePacked(
					'<g filter="url(#bg1)">',
						'<ellipse cx="102" cy="575" rx="367" ry="575" class="bg"/>',
					'</g>',
					'<g filter="url(#bg2)">',
						'<ellipse cx="837" cy="344" rx="367" ry="596" class="bg"/>',
					'</g>',
					'<filter id="bg1" x="-385" y="-116" width="975" height="1390" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
						'<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
						'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
						'<feGaussianBlur stdDeviation="60"/>',
						'<feColorMatrix type="matrix" values="',backgrounds[bg1Index],'"/>',
					'</filter>',
					'<filter id="bg2" x="350" y="-368" width="975" height="1432" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
						'<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
						'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
						'<feGaussianBlur stdDeviation="60"/>',
						'<feColorMatrix type="matrix" values="',backgrounds[bg2Index],'"/>',
					'</filter>'
				));

			}

			if (colorIndex < 3) {

				string[3] memory gradients = [

					// Argent
					string(abi.encodePacked(
						'<radialGradient id="c_ag" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(300 150) rotate(90) scale(1000 1000)">',
							'<stop stop-color="#E0E2E8"/>',
							'<stop offset="0.1" stop-color="#A0AFB8"/>',
							'<stop offset="0.25" stop-color="#7E8C95"/>',
							'<stop offset="0.35" stop-color="#B2B3BF"/>',
							'<stop offset="0.5" stop-color="#E1E6E9"/>',
							'<stop offset="0.6" stop-color="#A2AAAF"/>',
							'<stop offset="0.75" stop-color="#E0E2E8"/>',
							'<stop offset="0.95" stop-color="#7F8C95"/>',
							'<stop offset="1" stop-color="#DDF3FF"/>'
						'</radialGradient>'
					)),

					// Gilt
					string(abi.encodePacked(
						'<radialGradient id="c_au" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(300 150) rotate(90) scale(1000 1000)">',
							'<stop stop-color="#937F39"/>',
							'<stop offset="0.1" stop-color="#F1D48A"/>',
							'<stop offset="0.25" stop-color="#EAC46A"/>',
							'<stop offset="0.35" stop-color="#EFCF7E"/>',
							'<stop offset="0.5" stop-color="#F9E7BC"/>',
							'<stop offset="0.6" stop-color="#FBEDC9"/>',
							'<stop offset="0.75" stop-color="#DFB961"/>',
							'<stop offset="0.95" stop-color="#F9EBBF"/>',
							'<stop offset="1" stop-color="#A77928"/>'
						'</radialGradient>'
					)),

					// Chromat
					string(abi.encodePacked(
						'<radialGradient id="c_ch" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(460 200) rotate(90) scale(900 900)">',
							'<stop offset="0.1" stop-color="#E21878"/>',
							'<stop offset="0.3" stop-color="#7B85F1"/>',
							'<stop offset="0.4" stop-color="#17B9DD"/>',
							'<stop offset="0.5" stop-color="#00D67C"/>',
							'<stop offset="0.6" stop-color="#C1EE03"/>',
							'<stop offset="0.7" stop-color="#FFC700"/>',
							'<stop offset="0.8" stop-color="#FF6B00"/>',
							'<stop offset="0.9" stop-color="#EF101C"/>',
						'</radialGradient>'
					)) 

				];

				gradient = gradients[colorIndex];

			}

		} else {
			bodyColor = themes.bodyColor[themeIndex];
		}

		return string(abi.encodePacked(
			background,
			'<defs>',
				'<style>',
					'svg{background:',themes.bgColor[themeIndex],'}',
					'#b path,#r #i{fill:',themes.fillColor[themeIndex],'}#b path,#r path,#r line,#r circle{stroke:',bodyColor,';}#do path,#do line,#do circle{stroke-width:20px;}',
					'#f circle,#f path,#f line,#f rect{stroke:',themes.faceColor[themeIndex],';}#f .fB{fill:',themes.faceColor[themeIndex],'}',
					'#s circle,#s path,#s line{stroke:',themes.surroundColor[themeIndex],';}#s .fB{fill:',themes.surroundColor[themeIndex],'}',
					'#o circle,#o path,#o ellipse,#o line,#o rect{stroke:',themes.outfitColor[themeIndex],';}#o .fB{fill:',themes.outfitColor[themeIndex],'}',
				'</style>',		
				'<filter id="ds" color-interpolation-filters="sRGB" x="-20%" y="-20%" width="140%" height="140%">',
					'<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0" result="hardAlpha"/>',
					'<feColorMatrix type="matrix" values="',themes.shadowColor[themeIndex],'"/>',
					'<feOffset dx="4" dy="4"/>',
					'<feBlend mode="normal" in="SourceGraphic" result="shape"/>',
				'</filter>',		
			'</defs>',
			gradient
		));
    }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: MIT

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

interface IBody {
    function isRobed(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external pure returns (string memory);
    function element(uint256 tokenId) external pure returns (string memory);
}

/** @title Youts - Body Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Body {

    string[16] private divineOrderNames = [
        "Power",
        "Giants",
        "Titans",
        "Skill",
        "Perfection",
        "Brilliance",
        "Enlightenment",
        "Protection",
        "Anger",
        "Rage",
        "Fury",
        "Vitriol",
        "the Fox",
        "Detection",
        "Reflection",
        "the Twins"
    ];


	/** @dev External wrapper function that returns true if a Yout has the Robe body type
	  * @param tokenId A token's numeric ID. 
	  */
    function isRobed(uint256 tokenId)
        external 
        pure 
        returns (bool) 
    {
        return _isRobed(tokenId);
    }

	
    /** @dev Internal function that returns true if a Yout has the Robe body type
	  * @param tokenId A token's numeric ID. 
	  */
    function _isRobed(uint256 tokenId) 
        internal 
        pure 
        returns (bool) 
    {
        return uint256(keccak256(abi.encodePacked("ROBED", tokenId))) % 100 < 7 ? true : false;
    }


    /** @dev Internal function that returns the Divine Order index for this token
      * @notice This function will return a Divine Order index for ANY token, even Youts that aren't wearing Divine Robes. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _divineIndex(uint256 tokenId)
        internal
        pure
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked("DIVINEORDER", tokenId))) % 16;
    }


	/** @dev Renders a JSON string containing metadata for a Yout's body
	  * @param tokenId A token's numeric ID. 
	  */
    function metadata(uint256 tokenId) 
        external
        view
        returns (string memory)
    {
        string memory traits;
        bool robeCheck = _isRobed(tokenId);

        traits = string(abi.encodePacked(
            '{"trait_type":"Body Type","value":"', robeCheck ? "Divine Robe" : "Outline", '"}'
        ));

        if (robeCheck) {
            traits = string(abi.encodePacked(
                traits,',',
                '{"trait_type":"Divine Order","value":"', divineOrderNames[_divineIndex(tokenId)], '"}'
            ));
        }

        return traits;
    }


	/** @dev Renders a SVG element containing a Yout's body  
	  * @param tokenId A token's numeric ID. 
	  */
    function element(uint256 tokenId)
        external
        pure
        returns (string memory)
    {
        string memory body;

        if (_isRobed(tokenId)) {

            string[16] memory divineOrders = [

                // POWER
                string(abi.encodePacked(
                    '<path class="r" d="M628 840L600 879H639L613 918"/>'
                )),

                // GIANTS
                string(abi.encodePacked(
                    '<line class="r" x1="624.1" y1="839" x2="624" y2="838.9"/>',
                    '<path class="r mJ" d="M594 909V882.2L624 860L654 882.2V909"/>'
                )),

                // TITANS
                string(abi.encodePacked(
                    '<line class="r" x1="625" y1="845" x2="625" y2="902"/>',
                    '<path class="r mJ" d="M595 906V870L625 840L655 870V906"/>'
                )),

                // SKILL
                string(abi.encodePacked(
                    '<path class="r" d="M620.5 846.5L620.5 922"/>',
                    '<path class="r mJ" d="M597 862L620.5 834L644 862"/>',
                    '<path class="r mJ" d="M597 902L620.5 873L644 902"/>'
                )),

                // PERFECTION
                string(abi.encodePacked(
                    '<line class="r" x1="598" y1="902.73" x2="610.73" y2="890"/>',
                    '<line class="r" x1="646" y1="854.14" x2="633.27" y2="866.87"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(0.71 0.71 0.71 -0.71 598 841)"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(-0.71 -0.71 -0.71 0.71 645.87 915.87)"/>'
                )),

                // BRILLIANCE
                '<path class="r" d="M625.35 838C625.61 850.54 618.49 875.62 588 875.62C600.45 874.44 625.35 880.47 625.37 914C625.2 901.2 631.26 875.62 661 875.62C650.28 876.08 625.35 869.2 625.35 838Z"/>',

                // ENLIGHTENMENT
                string(abi.encodePacked(
                    '<circle cx="623.5" cy="868.5" r="27.5"/>',
                    '<line class="r" x1="585" y1="913" x2="661" y2="913"/>'
                )),

                // PROTECTION
                string(abi.encodePacked(
                    '<line x1="617.881" y1="869.216" x2="631.881" y2="883.216"/>',
                    '<circle cx="625" cy="876" r="32.5"/>'
                )),

                // ANGER
                '<path class="r mJ" d="M586.5 911.5L624.3 900.28M659.5 911.5L624.3 900.28M624.3 900.28C615.83 889.54 594 877 624.3 843C654.5 877.5 632.47 890.13 624.3 900.28Z"/>',

                // RAGE
                string(abi.encodePacked(
                    '<path class="r mJ" d="M599 845L624.5 905L650 845"/>',
                    '<line class="r" x1="595" y1="890" x2="655" y2="890"/>'
                )),

                // FURY
                string(abi.encodePacked(
                    '<path class="r mJ" d="M590 909C590 892.42 606.99 848 633.76 848C629.25 868 627.81 899.52 655 899.52"/>'
                )),

                // VITRIOL
                string(abi.encodePacked(
                    '<path class="r mJ" d="M610 845L580 875L610 905"/>',
                    '<line class="r" x1="661" y1="874" x2="651" y2="874"/>',
                    '<line class="r" x1="639" y1="851.142" x2="626.272" y2="863.87"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(-0.71 -0.71 -0.71 0.71 638.87 912.87)"/>'
                )),

                // THE FOX
                '<path class="r" d="M651 883.59L651 843L640.97 862.02L609.77 862.02L599 843L599 883.59L625 909L651 883.59Z"/>',

                // DETECTION
                string(abi.encodePacked(
                    '<circle cx="622" cy="866" r="17"/>',
                    '<circle cx="621.5" cy="885.5" r="36.5"/>'
                )),

                // REFLECTION
                string(abi.encodePacked(
                    '<path class="r" d="M625 838L625 916"/>',
                    '<path class="r" d="M645 878.421L658 860V895L645 878.421Z"/>',
                    '<path class="r" d="M605 878.421L592 860V895L605 878.421Z"/>'
                )),

                // THE TWINS
                string(abi.encodePacked(
                    '<line  x1="637" y1="911" x2="637" y2="844"/>',
                    '<line  x1="608" y1="911" x2="608" y2="844"/>',
                    '<line  class="s2 r" x1="589" y1="905" x2="655" y2="905"/>',
                    '<line  class="s2 r" x1="589" y1="854" x2="655" y2="854"/>'
                ))
                
            ];

            body = string(abi.encodePacked(
                '<g id="r">',
                    '<path id="i" d="M737.999 513.386C737.999 555.412 716.499 649.541 646.499 687.5C600.484 709.932 520.232 763.378 468.087 837.218C474.384 794.807 368.783 723.368 314 692.336C244 654.377 210 555.412 210 513.386C210 471.36 192.999 227.338 473.999 227.338C754.999 227.338 737.999 471.36 737.999 513.386Z"/>',
                    '<path class="s3" d="M314 776.388C244 738.429 134.031 751.5 147.031 511.5C149.304 469.535 150 181.004 473 181.004C796 181.004 793.727 469.539 796 511.504C809 751.504 701 734.541 631 772.5M314 776.388C354.156 791.388 430 855 432 905M314 776.388C257.2 811.093 199.667 910.148 178 955.338M631 772.5C596.167 787.167 513.999 842.504 483.999 952.504M631 772.5C687.8 807.205 748.333 910.148 770 955.338M468.087 837.218C520.232 763.378 600.484 709.932 646.499 687.5C716.499 649.541 737.999 555.412 737.999 513.386C737.999 471.36 754.999 227.338 473.999 227.338C192.999 227.338 210 471.36 210 513.386C210 555.412 244 654.377 314 692.336C368.783 723.368 474.384 794.807 468.087 837.218ZM468.087 837.218C444.684 870.357 426.942 907.605 420.499 948"/>',
                    '<g id="do">',
                        divineOrders[_divineIndex(tokenId)],
                    '</g>',
                '</g>'
            ));

        } else {

            body = string(abi.encodePacked(
                '<g id="b">',
                    '<path class="s3 eO" d="M174 955C195.67 909.8 253.2 810.8 310 776.05C381 732.7 380 730 310 692C240 654 206 555.1 206 513.05C206 471 189 227 470 227C751 227 734 471 734 513.05C734 555.1 700 654 630 692C560 730 559 732.7 630 776.05C686.8 810.8 744.3 909.8 766 955H174ZM174 955H765"/>',
                '</g>'
            ));

        }

        return body;
    }


}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "./Uint2str.sol";

interface IFace {
    function isWeird(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Face Metadata contract
  * @author @ok_0S / weatherlight.eth
  */
contract Face {
    using Uint2str for uint16;

    string[25] private humanFaceNames = [
        "Wiggle",
        "Blinker",
        "Grump",
        "I Liek U",
        "Grin",
        "U-On",
        "Stickout",
        "Black Eye",
        "uwu",
        "Browside Down",
        "Ring",
        "Rude Tude",
        "Devious Lick",
        "Uncle",
        "Nounish",
        "Tired Eye",
        "Smarty",
        "Mascara",
        "X'd Out",
        "2Cool",
        "Stoney",
        "Joyful",
        "Funhappy",
        "Straight Talker",
        "Bitey"
    ];

    string[14] private weirdFaceNames = [
        'North Tree', 
        'East Tree', 
        'West Tree', 
        'South Tree', 
        'Center Tree', 
        'U-shape', 
        'O-shape', 
        'Inverted U-shape', 
        'Rotated I-shape', 
        'Aligned', 
        'Four Eyes', 
        'Spiraling', 
        'Cyclops', 
        'Primal'
    ];
    

	/** @dev External wrapper function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function isWeird(uint256 tokenId) 
        external 
        pure 
        returns (bool) 
    {
        return
            _isWeird(tokenId);
    }	


    /** @dev Internal function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function _isWeird(uint256 tokenId) 
        internal 
        pure 
        returns (bool) 
    {
        return
            uint256(keccak256(abi.encodePacked("WEIRD", tokenId))) % 100 < 7 ? true : false;
    }
    

	/** @dev Renders a JSON string containing metadata for a Yout's face
	  * @param tokenId A token's numeric ID. 
	  */
    function metadata(uint256 tokenId) 
        external
        view 
        returns (string memory) 
    {
        string memory traits;

        bool weirdCheck = _isWeird(tokenId);

        traits = string(abi.encodePacked(
            '{"trait_type":"Origin","value":"', (weirdCheck ? _weirdOrigin(tokenId) : 'Human'), '"},',
            '{"trait_type":"Face","value":"', (weirdCheck ? _weirdFaceName(tokenId) : _humanFaceName(tokenId)),'"}'
        ));

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's face  
	  * @param tokenId A token's numeric ID. 
	  */
    function element(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<g id="f" filter="url(#ds)">', this.isWeird(tokenId) ? _weirdFace(tokenId) : _humanFace(tokenId), "</g>"
            ));
    }


    /** @dev Internal function that returns the weird origin associated with the given token ID.
      * @notice This function will return a weird origin for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdOrigin(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 faceRoll = uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length;
        string memory faceOrigin;

        if (faceRoll < 5) {
            faceOrigin = "Spirit";
        } else if (faceRoll > 8) {
            faceOrigin = "Primordial";
        } else {
            faceOrigin = "Alien";
        }

        return
            faceOrigin;
    }


	/** @dev Internal function that returns the weird face name associated with the given token ID.
      * @notice This function will return a weird face name for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            weirdFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length];
    }


	/** @dev Internal function that returns the name of the human face associated with the given token ID.
      * @notice This function will return a name even for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            humanFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % humanFaceNames.length];
    }


	/** @dev Internal function that returns the human face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[25] memory faces = [

            // WIGGLE
            string(abi.encodePacked(
                _eyes([400, 482, 637, 470]),
                _path(
                    'M350 542C358 576 403 582 428 565C453 548 472 541 500 562C529 584 551 578 576 557C601 536 642 545 659 565'
                )
            )),

            // BLINKER
            string(abi.encodePacked(
                _eyes([444, 505, 598, 468]),
                _path(
                    'M605 562C598 591 550 627 489 593'
                ),
                _path(
                    'M451 431C438 421 422 416 401 429'
                ),
                _path(
                    'M611 385C595 381 579 382 564 402'
                )
            )),

            // GRUMP
            string(abi.encodePacked(
                _eyes([630, 452, 439, 472]),
                _path(
                    'M457 578C477 538 584 496 637 571'
                ),
                _path(
                    'M556 455C570 427 644 398 680 450'
                ),
                _path(
                    'M373 478C384 449 455 414 496 462'
                )
            )),

            // I LIEK U
            string(abi.encodePacked(
                _eyes([388, 508, 639, 484]),
                _path(
                    'M580 572C580 587 568 607 536 608C493 609 485 591 484 581'
                )
            )),

            // GRIN
            string(abi.encodePacked(
                _eyes([589, 443, 382, 443]),
                _path(
                    'M398 553C422 595 529 629 573 542'
                ),
                _path(
                    'M449 440C433 410 352 382 314 440'
                ),
                _path(
                    'M649 440C633 410 552 382 514 440'
                )
            )),

            // U-ON
            string(abi.encodePacked(
                _eyes([567, 450, 461, 446]),
                _path(
                    'M555 532C555 554 559 603 514 603C469 603 473 554 473 532'
                )
            )),

            // STICKOUT
            string(abi.encodePacked(
                _eyes([365, 447, 633, 436]),
                _path(
                    'M614 498L402 505',
                    'r'
                ),
                _path(
                    'M585 506C585 529 589 577 544 577C499 577 503 529 503 506',
                    'r'
                )
            )),

            // BLACK EYE
            string(abi.encodePacked(
                _eyes([394, 487, 633, 458]),
                _path(
                    'M438 578C469 617 587 636 622 542'
                ),
                '<circle class="s0" cx="393" cy="486" r="46.5"/>'
            )),

            // UWU
            string(abi.encodePacked(
                _path(
                    'M662 433C667 464 613 502 580 447'
                ),
                _path(
                    'M326 459C327 491 387 518 410 458'
                ),
                _path(
                    'M426 546C452 605 499 571 497 538C499 571 551 598 567 535'
                )
            )),

            // BROWSIDE DOWN
            string(abi.encodePacked(
                _eyes([615, 567, 402, 578]),
                _path(
                    'M402 494C401 370 597 353 598 498'
                ),
                _path(
                    'M458 591C442 614 373 628 349 577'
                ),
                _path(
                    'M559 581C575 603 644 618 668 567'
                )
            )),

            // RING
            string(abi.encodePacked(
                _eyes([624, 462, 438, 458]),
                _path(
                    'M479 439C461 409 382 381 344 439'
                ),
                _path(
                    'M674 448C658 418 577 390 539 448'
                ),
                _path(
                    'M564 502C570 566 484 573 477 511'
                ),
                _path(
                    'M472 632C485 652 548 668 576 629'
                ),
                _path(
                    'M543 557C546 584 509 587 507 561', 
                    's1'
                )
            )),

            // RUDE TUDE
            string(abi.encodePacked(
                _line([600, 388, 400, 388]),
                _line([540, 443, 469, 443]),
                _path(
                    'M420 622C418 541 581 531 582 626'
                ),
                _path(
                    'M649 425C638 441 605 483 562 515'
                ),
                _path(
                    'M439 425C428 441 395 483 352 515'
                ),
                _path(
                    'M673 455C663 470 634 507 596 535', 
                    's3'
                ),
                _path(
                    'M463 455C453 470 424 507 386 535', 
                    's3'
                ),
                _path(
                    'M329 480C336 518 372 542 409 535C446 528 470 492 463 454C456 417 420 393 383 400C346 407 322 443 329 480Z'
                ),
                _path(
                    'M539 481C546 518 582 542 619 535C656 528 680 492 673 455C665 418 630 393 593 401C556 408 532 444 539 481Z'
                )
            )),

            // DEVIOUS LICK
            string(abi.encodePacked(
                _eyes([337, 462, 665, 438]),
                _path(
                    'M401 511C402 572 617 566 616 495'
                ),
                _path(
                    'M585 540C591 562 605 608 562 618C517 628 511 580 506 558'
                )
            )),

            // UNCLE
            string(abi.encodePacked(
                _eyes([622, 487, 396, 490]),
                _path(
                    'M647 455C633 445 617 441 597 455'
                ),
                _path(
                    'M421 455C407 445 391 441 371 455'
                ),
                _path(
                    'M602 574C593 572 551 567 531 568', 
                    's3 r'
                ),
                _path(
                    'M500 568C492 568 449 570 429 574', 
                    's3 r'
                )
            )),

            // NOUNISH
            string(abi.encodePacked(            
                _path(
                    'M358 449L262 449L262 510',
                    's3 mJ'
                ),
                _path(
                    'M431 598C447 600 524 599 566 599'
                ),
                _line(
                    [547, 449, 504, 449],
                    's3'
                ),
                '<rect x="554" y="403" width="125" height="125" class="s3"/>',
                '<rect x="365" y="403" width="125" height="125" class="s3"/>',
                '<rect x="629" y="429" width="25" height="75" class="fB s0"/>',
                '<rect x="440" y="429" width="25" height="75" class="fB s0"/>'
            )),

            // TIRED EYE
            string(abi.encodePacked(
                _eyes([364, 459, 649, 439]),
                _path(
                    'M449 582C492 628 584 616 598 553'
                ),
                _path(
                    'M316 491C333 516 403 520 416 471.102'
                )
            )),

            // SMARTY
            string(abi.encodePacked(
                _eyes([419, 480, 608, 481]),
                _path(
                    'M602 571C586 623 464 629 440 575'
                )
            )),

            // MASCARA
            string(abi.encodePacked(
                _eyes([603, 441, 417, 436]),
                _path(
                    'M681 429C667 419 651 415 631 429'
                ),
                _path(
                    'M389 426C375 416 359 412 339 426'
                ),
                _path(
                    'M501 442C528 452 557 510 509 541'
                ),
                _path(
                    'M451 611C464 630 527 647 555 607'
                )
            )),

            // X'D OUT
            string(abi.encodePacked(
                _line(
                    [372, 508, 410, 470],
                    'r'
                ),
                _line(
                    [372, 470, 410, 508],
                    'r'
                ),
                _line(
                    [597, 462, 635, 500],
                    'r'
                ),
                _line(
                    [597, 500, 635, 462],
                    'r'
                ),
                _eyes([616, 417, 391, 417]),
                _path(
                    'M539 558C535 576 516 586 499 582C481 577 471 559 475 541C480 523 498 513 516 517C534 522 544 540 539 558Z'
                )
            )),

            // 2COOL
            string(abi.encodePacked(
                _line([610, 423, 400, 423]),
                _line([545, 472, 465, 472]),
                _path(
                    'M475 629C495 616 540 629 558 618'
                ),
                _path(
                    'M652 460C641 476 608 518 565 550'
                ),
                _path(
                    'M442 460C431 476 398 518 355 550'
                ),
                _path(
                    'M676 490C666 505 637 542 599 570', 's3'
                ),
                _path(
                    'M466 490C456 505 427 542 389 570', 
                    's3'
                ),
                _path(
                    'M332 515C339 553 375 577 412 570C449 563 473 527 466 489C459 452 423 428 386 435C349 442 325 478 332 515Z'
                ),
                _path(
                    'M542 516C549 553 585 577 622 570C659 563 683 527 676 490C668 453 633 428 596 436C559 443 535 479 542 516Z'
                )
            )),

            // STONEY
            string(abi.encodePacked(
                _path(
                    'M360 435C369 419 414 404 435 435'
                ),
                _path(
                    'M558 435C567 419 612 404 633 435'
                ),
                _path(
                    'M526 489C529 536 465 538 463 493'
                ),
                _path(
                    'M389 541C383 658 593 682 601 546'
                ),
                _path(
                    'M521 523C523 558 476 560 473 527',
                    's1'
                )
            )),

            // JOYFUL
            string(abi.encodePacked(
                _path(
                    'M362 483C362 425 469 417 469 486'
                ),
                _path(
                    'M538 488C538 429 643 421 644 490'
                ),
                _path(
                    'M427 557C454 606 554 605 579 557'
                )
            )),

            // FUNHAPPY
            string(abi.encodePacked(
                _eyes([343, 461, 664, 461]),
                _path(
                    'M399 559C398 417 610 397 611 564'
                )
            )),

            // STRAIGHT TALKER
            string(abi.encodePacked(
                _line(
                    [370, 427, 424, 427],
                    'r'
                ),
                _line(
                    [567, 427, 623, 427],
                    'r'
                ),
                _eyes([397, 463, 596, 463]),
                _path(
                    'M443 552C458 561 532 569 566 552'
                )
            )),

            // BITEY
            string(abi.encodePacked(
                _eyes([419, 480, 610, 477]),
                _path(
                    'M655 430C645 424 600 427 583 446'
                ),
                _path(
                    'M374 436C384 429 429 428 447 446'
                ),
                _path(
                    'M622 536C615 549 605 565 588 576M415 552C430 569 437 572 449 581M588 576L589 616L564 588M588 576C580 580 572 584 564 588M564 588C537 598 506 602 477 593M477 593L453 621L449 581M477 593C467 590 458 586 449 581'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % faces.length];
    }


	/** @dev Internal function that returns the weird face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Weird Youts.  
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[14] memory faces = [
            
            // SPIRIT / NORTH TREE
            string(abi.encodePacked(
                _eyes([311, 482, 585, 591]),
                '<circle class="s0" cx="497" cy="416" r="33.5"/>'
            )),

            // SPIRIT / EAST TREE
            string(abi.encodePacked(
                _eyes([381, 600, 438, 363]),
                '<circle class="s0" cx="578" cy="537" r="33.5"/>'
            )),

            // SPIRIT / WEST TREE
            string(abi.encodePacked(
                _eyes([514, 567, 489, 349]),
                '<circle class="s0" cx="366" cy="524" r="33.5"/>'
            )),

            // SPIRIT / SOUTH TREE
            string(abi.encodePacked(
                _eyes([320, 496, 583, 364]),
                '<circle class="s0" cx="470" cy="542" r="33.5"/>'
            )),

            // SPIRIT / CENTER TREE
            string(abi.encodePacked(
                _eyes([292, 481, 628, 392]),
                '<circle class="s0" cx="471" cy="474" r="33.5"/>'
            )),

            // ALIEN / U-SHAPE
            string(abi.encodePacked(
                _eyes([507, 456, 454, 456]),
                _path(
                    'M446 540C446 581 521 585 521 538'
                ),
                '<circle class="s0" cx="606" cy="441" r="56.5"/>',
                '<circle class="s0" cx="348" cy="451" r="56.5"/>'
            )),

            // ALIEN / O-SHAPE
            string(abi.encodePacked(
                _eyes([467, 515, 522, 510]),
                '<circle class="s0" cx="503" cy="626" r="33.5"/>',
                '<circle class="s0" cx="343" cy="510" r="56.5"/>',
                '<circle class="s0" cx="625" cy="476" r="56.5"/>'
            )),

            // ALIEN / INVERTED U-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 465, 492]),
                _path(
                    'M529 646C529 603 453 610 459 646'
                ),
                '<circle class="s0" cx="353" cy="472" r="56.5"/>',
                '<circle class="s0" cx="620" cy="470" r="56.5"/>'
            )),

            // ALIEN / ROTATED I-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 456, 491]),
                _path(
                    'M439 584C450 583 505 582 530 584'
                ),
                '<circle class="s0" cx="344" cy="461" r="56.5"/>',
                '<circle class="s0" cx="623" cy="455" r="56.5"/>'
            )),

            // PRIMORDIAL / ALIGNED
            string(abi.encodePacked(
                _eyes([497, 414, 496, 668]),
                _path(
                    'M451 605C462 624 517 643 542 605'
                ),
                _path(
                    'M425 345C445 373 529 391 559 328'
                ),
                _path(
                    'M397 572C396 448 592 431 593 577'
                )
            )), 

            // PRIMORDIAL / FOUR EYES
            string(abi.encodePacked(
                _eyes([588,496,354,497]),
                _eyes([359,407,591,408]),
                _path(
                    'M662 411.353C646 382 565 353 527 411'
                ),
                _path(
                    'M428 411.797C412 382 331 353 293 411'
                ),
                _path(
                    'M657 499.553C641 470 559 442 522 501'
                ),
                _path(
                    'M423 499.999C407 470 325 442 288 501'
                ),
                _path(
                    'M288 553.666C279 679 650 708 661 562'
                )
            )),

            // PRIMORDIAL / SPIRALING
            string(abi.encodePacked(
                _eyes([357,601,586,356]),
                _path(
                    'M399 620C505 654 684 574 561 391C609 546 469 629 399 620Z'
                ),
                _path(
                    'M398 576C304 505 324 295 550 339C405 344 349 497 398 576Z'
                )
            )),

            // PRIMORDIAL / CYCLOPS
            string(abi.encodePacked(
                '<circle class="s0" cx="474" cy="433" r="49"/>',
                '<circle class="fB i" cx="474" cy="433"/>',
                _path(
                    'M288.098 487.326C281.091 709.646 652.733 747.352 660.929 487.326'
                )
            )),

            // PRIMORDIAL / PRIMAL
            string(abi.encodePacked(
                _eyes([611,489,473,492]),
                '<circle class="fB i" cx="337" cy="489" r="12"/>',
                _path(
                    'M541.847 495.922C542.363 588.19 405.284 600.773 404.68 492.855',
                    ''
                ),
                _path(
                    'M279.036 481.07C279.073 487.698 273.73 493.1 267.103 493.137C260.476 493.174 255.073 487.832 255.036 481.205L279.036 481.07ZM255.036 481.205C254.738 427.86 294.758 396.997 334.783 395.609C354.81 394.914 375.274 401.533 390.803 416.613C406.432 431.79 416.037 454.525 416.203 484.137L392.203 484.271C392.067 459.925 384.311 443.763 374.083 433.831C363.756 423.802 349.87 419.099 335.616 419.594C307.079 420.584 278.818 442.147 279.036 481.07L255.036 481.205Z',
                    'fB nS'
                ),
                _path(
                    'M691.203 491.137C691.24 497.764 685.898 503.167 679.27 503.204C672.643 503.241 667.24 497.899 667.203 491.271L691.203 491.137ZM530.036 488.205C529.738 434.86 569.758 403.997 609.783 402.609C629.81 401.914 650.274 408.533 665.803 423.613C681.432 438.79 691.037 461.525 691.203 491.137L667.203 491.271C667.067 466.925 659.311 450.763 649.083 440.831C638.756 430.802 624.87 426.099 610.616 426.594C582.079 427.584 553.818 449.147 554.036 488.07L530.036 488.205Z',
                    'fB nS'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked('FACE', tokenId))) % faces.length];
    }


	/** @dev Internal drawing helper function that draws two eye dots.
	  * @param position An array containing the X and Y coordinates for each eye (X1, Y1, X2, Y2)
	  */
    function _eyes(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<circle class="fB i" cx="',
                position[0].uint2str(),
                '" cy="',
                position[1].uint2str(),
                '"/>',
                '<circle class="fB i" cx="',
                position[2].uint2str(),
                '" cy="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
	  */
    function _line(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line with the provided class attribute.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
      * @param classNames A string containing the path's `class` attribute
	  */
    function _line(uint16[4] memory position, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '" class="',
                classNames,
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with a default class attribute.
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<path class="r" d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute.
	  * @param d A string containing the path's `d` attribute.
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return 
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Surround.sol";
import "./Face.sol";
import "./Body.sol";

interface IOutfit {
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Outfit Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Outfit is Ownable {
    address public faceAddress;
    address public surroundAddress;
    address public bodyAddress;

    string[15] private outfitNames = [
        'Natural',
        'Drip',
        'Forested',
        'Tee',
        'Pocket',        
        'Crewneck',
        'Blouse',
        'Toga',
        'Kimono',
        'Kimono, Forested',
        'Overalls',
        'Tank',
        'Ancient',
        'Sci-fi'
    ];
    

	/** @dev Initialize metadata contracts  
	  * @param _faceAddress Address of Facce Metadata Contract 
	  * @param _surroundAddress Address of Surround Metadata Contract 
	  * @param _bodyAddress Address of Body Metadata Contract 
	  */ 
    constructor(address _faceAddress, address _surroundAddress, address _bodyAddress) 
        Ownable() 
    {
        faceAddress = _faceAddress;
        surroundAddress = _surroundAddress;
        bodyAddress = _bodyAddress;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
    function setFaceAddress(address addr) 
        public 
        onlyOwner 
    {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Surround Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Surround Metadata Contract 
	  */
    function setSurroundAddress(address addr) 
        public 
        onlyOwner 
    {
        surroundAddress = addr;
    }


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
    function setBodyAddress(address addr) 
        public 
        onlyOwner 
    {
        bodyAddress = addr;
    }


    /** @dev Internal function that returns the Outfit index for this token
      * @notice This function will return a Outfit index for ANY token, even Youts that aren't wearing outfits
	  * @param tokenId A token's numeric ID
	  */
    function _outfitIndex(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return 
            uint256(keccak256(abi.encodePacked("OUTFIT", tokenId))) % ( 
                IFace(faceAddress).isWeird(tokenId) 
                    ? 15 
                    : 13
            );
    }


	/** @dev Renders a JSON string containing metadata for a Yout's Outfit
	  * @param tokenId A token's numeric ID
	  */
    function metadata(uint256 tokenId)
        external
        view
        returns (string memory) 
    {
        string memory traits;
        
        if (!IBody(bodyAddress).isRobed(tokenId)) {
            traits = string(abi.encodePacked(
                '{"trait_type":"Outfit","value":"', outfitNames[_outfitIndex(tokenId)], '"}'
            ));
        }

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's outfit  
	  * @param tokenId A token's numeric ID 
	  */
    function element(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory shirtOutline = string(abi.encodePacked(
            _path(
                'M592.521 757.644C540.289 810.837 452.375 840.491 336.999 744',
                's3'
            ),
            _path(
                'M292 871.612C301.641 884.617 314.115 951.654 298.906 984.035',
                's3 r'
            ),
            _path(
                'M640.627 876.644C635.766 891.774 638.767 963.632 656.222 994.838',
                's3 r'
            ),
            _path(
                'M182 956H767C745.333 910.811 687.8 811.756 631 777.05C620.696 770.754 589 750 583.5 745',
                's3'
            ),
            _path(
                'M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 343.5 755 356 745.5',
                's3'
            )
        ));

        string memory tank = string(abi.encodePacked(
            _path(
                "M293.572 774C301.322 797.795 313.655 867.784 300.99 957.374",
                's3'
            ),
            _path(
                "M348 752C348 752 342.808 754.918 335 760.071C324.532 766.98 314.145 773.518 310 776.05C303.156 780.232 296.301 785.348 289.5 791.192",
                "s3"
            ),
            _path(
                "M630 776.05L638.082 762.824L630 776.05ZM647.3 788.5L657.151 776.532L661.895 780.437L662.675 786.532L647.3 788.5ZM766 970.5H181V939.5H766V970.5ZM621.918 789.277C616.393 785.9 610.096 781.516 605.189 778.224C599.48 774.394 596.226 772.463 594.936 771.967L606.064 743.033C611.274 745.037 617.618 749.233 622.458 752.479C628.099 756.264 633.303 759.904 638.082 762.824L621.918 789.277ZM637.45 800.468C632.158 796.112 626.969 792.362 621.918 789.277L638.082 762.824C644.575 766.792 650.945 771.424 657.151 776.532L637.45 800.468ZM662.675 786.532C663.644 794.104 663.57 801.983 663.306 810.31C663.034 818.934 662.553 828.156 662.411 839.998C662.133 863.27 663.208 895.835 670.338 944.765L639.662 949.235C632.292 898.665 631.117 864.48 631.414 839.627C631.56 827.407 632.073 817.222 632.322 809.331C632.581 801.142 632.557 795.396 631.926 790.468L662.675 786.532Z",
                "fB nS mJ"
            ),
            _path(
                "M341 769C372.797 850.416 533.673 929.846 610.486 772.808",
                "s4"
            )
        ));

        string memory teeOutline = string(abi.encodePacked(
            _path(
                "M335 741.5C379.2 800.1 513 847 604.5 742", 
                "s3"
            ),
            _path(
                "M716 956.5C726.5 941.5 733 922 740.5 905.5C710 859.5 673.3 802.7 633 778.1C625.8 773.6 599.5 757 587 747.5",
                "s4 mJ"
            ),
            _path(
                "M225 956.5C214.5 941.5 207 923.5 199.5 907C227.5 859.8 267.7 802.7 308 778.1C315.2 773.6 341.5 757 354 747.5",
                "s4 mJ"
            )
        ));

        string memory teeDetails = string(abi.encodePacked(
            _path(
                "M644 847C637 863 635 943 651 979", 
                "r"
            ),
            _path(
                "M304 848C314 861 327 929 311 962", 
                "r"
            ),
            _path(
                "M304 773C344 838.4 543.5 900.2 636 773"
            )
        ));

        string memory kimono = string(abi.encodePacked(
            _path(
                "M289.053 858.253C289.053 858.253 289.053 925.753 312.556 1000.25", 
                "r"
            ),
            _path(
                "M659.672 863.206C661.148 879.46 659.748 926.159 642.335 982.924", 
                "r"
            ),
            _path(
                "M174 955.5C195.667 910.311 253.2 811.256 310 776.55C317.237 772.128 328.5 762.5 336.5 757.5C336.5 757.5 337 989 390.5 997",
                "s4 mJ"
            ),
            _path(
                "M766 955C744.333 909.811 688 812 632 777.05C621.756 770.657 616.5 767 608.5 761.5C608.5 761.5 608.5 861.5 605 914C602.694 948.591 585 987.5 585 987.5",
                "s4 mJ"
            )
        ));

        string memory forest = _path(
            'M444 901C502 931 528 878 484 845C469 833 448 847 452 860C457 873 468 878 482 873C534 856 523 806 469 807',
            's2 r'
        );

        string[15] memory outfits = [

            // NATURAL
            _chest(tokenId),

            // DRIP
            string(abi.encodePacked(
                _chest(tokenId),
                _dot(["360", "780"]),
                _dot(["392", "805"]),
                _dot(["427", "822"]),
                _dot(["468", "829"]),
                _dot(["509", "822"]),
                _dot(["546", "805"]),
                _dot(["609", "757"]),
                _dot(["336", "753"]),
                _dot(["580", "781"])
            )),

            // FORESTED
            string(abi.encodePacked(
                _dot(["591", "890"]),
                _dot(["349", "891"]),
                forest
            )),

            // TEE
            string(abi.encodePacked(
                teeOutline,
                teeDetails
            )),

            // POCKET
            string(abi.encodePacked(
                teeOutline,
                teeDetails,
                '<rect class="s2 r" x="492" y="910" width="89" height="86" transform="rotate(-7 492 910)" style="stroke-linejoin: round !important;"/>'
            )),

            // CREWNECK
            string(abi.encodePacked(
                shirtOutline,
                _path(
                    'M625.349 779.069C564.36 845.906 459.088 887.056 315 779.718',
                    's3'
                ),
                _path(
                    'M517.546 844.266C480.503 920.583 484.972 922.989 440.999 846.167'
                )
            )),

            // BLOUSE
            shirtOutline,

            // TOGA
            string(abi.encodePacked(
                _path(
                    "M637.5 781C621.5 770.5 588 750 583.5 744", 
                    "s4"
                ),
                _path(
                    "M220 875.5C198.5 909 196 912 173.5 956H765", 
                    "s4"
                ),
                _path(
                    "M586.719 755.355C572.782 840.371 382.485 988.716 223 895",
                    "s3"
                ),
                _path(
                    "M601.441 763C619.73 852.138 491.4 1049.82 302.435 995.962"
                ),
                _path(
                    "M633.705 777.151C687.532 845.185 664.386 1047.31 481.727 1060.18",
                    "s3"
                )
            )),

            // KIMONO
            kimono,

            // KIMONO, FORESTED
            string(abi.encodePacked(
                kimono,
                forest
            )),

            // OVERALLS
            string(abi.encodePacked(
                teeOutline,
                _dot(["504", "889"]),
                _path(
                    "M351 763C361 788 384 862 382 961"
                ),
                _path(
                    "M374 851C436 854 570 856 612 843"
                ),
                _path(
                    "M649 790C658 816 674 892 667 991"
                ),
                _path(
                    "M299 779C309 804 329 879 327 978", 
                    "s3"
                ),
                _path(
                    "M586 753C596 778 616 851 614 949" 
                    "s3"
                ),
                _path(
                    "M381 909C411 910 462 921 506 925C552 916 598 907 619 900"
                )
            )),

            // TANK
            tank,

            // JERSEY
            string(abi.encodePacked(
                tank,
                '<circle class="s2" cx="360.5" cy="875.5" r="22.5"/>',
                '<rect class="s2" x="585" y="861" width="30" height="30"/>',
                _path(
                    'M461.527 908.453C413.027 882.953 375.491 926.949 390.252 978.953',
                    'r'
                ),
                _path(
                    'M518 1010C531 1013 543 1007 551 998C559 990 565 978 568 964C571 951 570 937 565 926C561 915 552 905 539 903C526 900 515 906 506 915C498 923 492 935 489 949C487 962 488 976 492 987C497 998 505 1008 518 1010Z',
                    'r'
                )
            )),

            // ANCIENT
            string(abi.encodePacked(
                _path(
                    "M655 801C611 902 392 999 289 804"
                ),
                _path(
                    "M691 825C639 949 379 1068 257 829"
                ),
                _path(
                    "M612 780C577.743 852.16 405.783 921.495 325.366 782.347",
                    "s3"
                ),
                _path(
                    "M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 323 768 331 763",
                    "s4"
                ),
                _path(
                    "M766 955C744.333 909.811 686.8 810.756 630 776.05C619.696 769.754 613.5 765.5 606 761",
                    "s4"
                )
            )),

            // SCI-FI
            string(abi.encodePacked(
                _dot(['372','785']),
                _dot(['401','809']),
                _path(
                    'M612 780C592.948 820.133 478 887.5 468.5 892C458 887.5 361.059 844.106 325.366 782.347',
                    's4'
                ),
                _path(
                    'M630.18 834.851C608.691 875.004 479.13 942.491 468.422 947.001C456.593 942.512 347.376 899.219 307.187 837.496',
                    'r'
                ),
                _path(
                    'M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 323 768 331 763',
                    's4'
                ),
                _path(
                    'M766 955C744.333 909.811 686.8 810.756 630 776.05C619.696 769.754 613.5 765.5 606 761',
                    's4'
                )
            ))

        ];

        return
            string(abi.encodePacked(
                '<g id="o" filter="url(#ds)">', outfits[_outfitIndex(tokenId)], "</g>"
            ));
    }


	/** @dev Returns an appropriate chest for the token
	  * @param tokenId A token's numeric ID
	  */
    function _chest(uint256 tokenId)
        internal
        view
        returns
        (string memory) 
    {
        string memory xs = string(abi.encodePacked(
            '<line class="s2 r" x1="349" y1="859" x2="382" y2="892"/>',
            '<line class="s2 r" x1="557" y1="859" x2="590" y2="892"/>',
            '<line class="s2 r" x1="349" y1="892" x2="382" y2="859"/>',
            '<line class="s2 r" x1="557" y1="892" x2="590" y2="859"/>'
        ));

        if (ISurround(surroundAddress).hasLongHair(tokenId)) {
            return
                string(abi.encodePacked(
                    xs,
                    _path(
                        "M459 869C459 913 405 929 366 929C326 929 299 909 295 875C292 855 297 827 327 810",
                        "r"
                    ),
                    _path(
                        "M484 869C484 913 537 929 575 929C613 929 640 909 644 875C647 855 642 827 612 810",
                        "r"
                    )
                ));
        } else if (IFace(faceAddress).isWeird(tokenId)) {
            return
                string(abi.encodePacked(
                    '<ellipse class="fB" rx="16.5" ry="7.5" transform="matrix(0 1 1 -4.37114e-08 577.5 897.5)"/>',
                    '<ellipse class="fB" rx="17" ry="7.5" transform="matrix(1 -8.74228e-08 -8.74228e-08 -1 577 897.5)"/>',
                    '<ellipse class="fB" rx="16.5" ry="7.5" transform="matrix(-1 0 0 1 357.5 889.5)"/>',
                    '<ellipse class="fB" rx="17" ry="7.5" transform="matrix(0 1 1 -4.37114e-08 357.5 890)"/>'
                ));
        }
        
        return
            uint256(keccak256(abi.encodePacked("NATURAL", tokenId))) % 2 == 2
                ? xs
                : string(abi.encodePacked(
                    _dot(["591", "890"]), _dot(["349", "891"])
                ));
    }


	/** @dev Internal drawing helper function that renders a small dot
	  * @param position The X and Y coordinates for the dot
	  */
    function _dot(string[2] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<circle class="fB i" cx="',
                position[0],
                '" cy="',
                position[1],
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return
            string(abi.encodePacked(
                '<path d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute
	  * @param d A string containing the path's `d` attribute
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Face.sol";
import "./Body.sol";

interface ISurround {
    function hasLongHair(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Surround Metadat contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Surround is Ownable {
    address public faceAddress;
    address public bodyAddress;

    string[19] private accessoryName = [
        '',
        '',
        '',
        '',
        '',
        'Wings',
        'Wings',
        'Wings',
        'Power Pak',
        'Power Pak',
        'Power Pak',
        'Wings',
        'Power Pak',
        'Headphones',
        'Vibes',
        'Devilish',
        'Zap',
        'Hexed',
        ''
    ]; 

    string[19] private hairName = [
        'Flip',
        'Tails',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        ''
    ]; 
    

	/** @dev Initialize metadata contracts  
	  * @param _faceAddress Address of Facce Metadata Contract 
	  * @param _bodyAddress Address of Body Metadata Contract 
	  */ 
    constructor(address _faceAddress, address _bodyAddress)
        Ownable() 
    {
        faceAddress = _faceAddress;
        bodyAddress = _bodyAddress;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
    function setFaceAddress(address addr) 
        public
        onlyOwner 
    {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
    function setBodyAddress(address addr) 
        public 
        onlyOwner 
    {
        bodyAddress = addr;
    }

	
    /** @dev Internal function that returns true if a Yout has long hair
	  * @param tokenId A token's numeric ID. 
	  */
    function hasLongHair(uint256 tokenId) 
        external 
        view 
        returns (bool)
    {
        return 
            _surroundIndex(tokenId) <= 1;
    }


    /** @dev Internal function that returns the Surround index for this token
      * @notice This function will return a Surround index for ANY token, even some Youts that don't have hair or accessories
	  * @param tokenId A token's numeric ID
	  */
    function _surroundIndex(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (IFace(faceAddress).isWeird(tokenId)) {
            return 
                (uint256(keccak256(abi.encodePacked("SURROUND", tokenId))) % 8) + 11;
        } else {
            return
                uint256(keccak256(abi.encodePacked("SURROUND", tokenId))) %  19;
        }    
    }


	/** @dev Renders a JSON string containing metadata for a Yout's Hair and Accessories
	  * @param tokenId A token's numeric ID
	  */
    function metadata(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory traits;

        if (!IBody(bodyAddress).isRobed(tokenId)) {
            uint256 surroundIndex = _surroundIndex(tokenId);
            traits = string(abi.encodePacked(
                '{"trait_type":"Accessory","value":"',bytes(accessoryName[surroundIndex]).length != 0 ? accessoryName[surroundIndex] : 'none', '"},'
                '{"trait_type":"Hair","value":"',bytes(hairName[surroundIndex]).length != 0 ? hairName[surroundIndex] : 'none', '"}'
            ));
        }

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's Hair and Accessories  
	  * @param tokenId A token's numeric ID 
	  */
    function element(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string[3] memory shortHair = [

            // HAIR / CURLY LOOKING
            _path(
                'M166.4 581.6C112 453.1 375.9 493.9 249.2 340.8C225.6 312.3 168.4 298.6 153.6 341.6C138.7 384.6 181.9 405.2 221.766 405.45C308.179 406.088 367.907 359.586 350.694 241.322C344.451 198.43 301.966 158.969 262.542 182.031C223.118 205.093 235.978 264.955 282.9 285.214C373.109 324.162 488.056 297.5 507.302 225.472C515.562 194.557 509.802 141.74 453.975 143.11C398.148 144.481 397.527 206.746 403.115 230.004C426.331 326.638 610.5 364.5 659.491 279.24C685.5 237.938 674.5 193.138 640.711 182.362C574.614 161.282 557.351 219.687 556.494 237.938C550.623 362.958 782.478 379.174 757.222 241.375',
                's2 r'
            ),

            // HAIR / CURLY TOP
            _path(
                'M145 385C164 494 343 435 259 287C237 246 196 250 179 276C159 303 169 350 215 364C301 389 434 339 418 224C412 175 376 151 335 164C293 178 287 230 311 266C363 362 562 300 586 233C598 199 586 152 540 146C494 138 466 179 471 220C476 289 591 354 685 317C719 304 751 259 720 228C692 199 649 220 634 260C573 426 792 438 772 323',
                's2 r'
            ),
            
            // HAIR / WISP
            _path(
                'M432 173C479 220 519 177 487 132C476 116 453 123 453 137C453 150 462 158 477 158C532 158 536 107 484 91',
                's2 r'
            )

        ];

        // ACCESSORY / WINGS
        string memory wings = string(abi.encodePacked(
            _path(
                'M36 998C15 953 54 827 153 825',
                'r'
            ),
            _path(
                'M904 998C924 953 886 827 786 825',
                'r'
            ),
            _path(
                'M955.1 870C930.6 790.4 806.1 694 684.6 804.5'
            ),
            _path(
                'M-15.5 870C9.07657 790.396 133.5 694 255 804.5'
            ),
            _path(
                'M-41.5 818.5C-12.5 731.3 166.5 631 283.5 777.3'
            ),
            _path(
                'M981.2 818.5C952.1 731.3 773.1 631 656.1 777.3'
            )
        ));

        // ACCESSORY / POWER PAK
        string memory powerPak = string(abi.encodePacked(
            '<line x1="215.5" y1="698" x2="215" y2="745"/>',
            '<circle cx="215" cy="692" r="27" class="fB"/>',
            _path(
                "M190.35 781.6C235.29 759.65 288.55 751.8 324.95 749.05C333.5 743.5 341 739.5 347.5 732.5C341 726.5 334.5 723 327.35 718.8C287.6 721.5 225.4 730 173.2 756.637C170.9 757.81 168.94 759.54 167.52 761.7C134.63 811.02 113 891.02 113 955L143 955C143 897.43 162.38 825.62 190.35 781.6Z",
                "fB eO nS"
            ),
            _path(
                "M593 732C595.5 729.5 599.5 726.5 603.5 724.4C615.35 725.35 627.5 726.1 639.2 726.95C654.2 728.05 669.05 729.45 683.7 732.95C689.9 740.9 694.5 749.2 697.9 758.7C700.85 767 703.38 776.52 705.36 786.46C708.39 801.7 710.25 818.71 709.89 834.26C692 812 689 808 676.46 795.05C676.29 794.14 676.12 793.22 675.94 792.32C673.74 781.28 670.97 769.87 665.84 759.78C652.68 757.67 639.29 756 626 756.08C620.5 752.5 596.5 738.5 593 732Z",
                "fB eO nS"
            )
        ));

        string[19] memory combinations = [

            // (LONG) HAIR / FLIP
            string(abi.encodePacked(
                _path(
                    'M363 734L303 777L303 691L363 734Z',
                    'fB nS'
                ),
                _path(
                    'M577 734L637 691L637 777L577 734Z',
                    'fB nS'
                ),
                _path(
                    'M730.8 753C730.8 753 591.9 735.2 686.9 696.134C781.817 657.036 827.929 574.811 827.929 511.813C827.929 468.525 842.08 146.164 470.392 217.177C112.341 148.151 113 468.525 113 511.812C113 574.811 159.113 657.035 254.05 696.134C348.988 735.232 210.092 752.999 210.092 752.999',
                    'r'
                ),
                _path(
                    'M211.2 790C211.2 790 375.5 752.5 280.4 695.095C201.143 647.274 156.377 571.353 156.377 507.234C156.377 463.115 132.301 187.708 468.984 223.137L469.99 223.112C816.79 202.938 786.319 464.264 786.319 508.228C786.319 572.192 741.479 647.776 662.139 695.429C566.82 752.678 731.411 790 731.411 790',
                    'r'
                ),
                _path(
                    'M213.6 827C235.4 817.7 280 791 304.5 776.05C375.719 732.669 374.716 729.957 304.508 691.998C234.3 654.039 200.199 555.075 200.199 513.048C200.199 471.022 183.148 227 464.983 227H471H477.017C758.852 227 741.801 471.022 741.801 513.048C741.801 555.074 707.7 654.039 637.492 691.998C567.284 729.957 566.281 732.669 637.492 776.05C661.957 790.954 706.616 817.724 728.444 827',
                    'r'
                )
            )),

            // (LONG) HAIR / TAILS
            string(abi.encodePacked(
                '<line class="s3 r" x1="704" y1="732" x2="600" y2="732"/>',
                '<line class="s3 r" x1="340" y1="732" x2="235" y2="732"/>',
                _path(
                    'M168 952C189.7 906.8 247.2 807.8 304 773.1C375 729.7 374 731 304 693C234 655 200 552.1 200 510C200 468 189 224 470 224C751 224 740 468 740 510.1C740 552.1 706 655 636 693C566 731 565 729.7 636 773.1C692.8 807.8 750.3 906.8 772 952'
                ),
                _path(
                    'M119 962C144.7 915.1 212.9 812.4 280.3 776.4C364.5 731.4 363.3 728.6 280.3 689.2C197.3 649.9 157 547.2 157 503.7C157 460.1 136.7 207 470 207C803.4 207 783 460.1 783 503.7C783 547.2 742.7 649.9 659.7 689.2C576.6 728.6 575.4 731.4 659.7 776.4C727 812.4 795.3 915.1 821 962'
                ),
                _path(
                    'M876 962H63C92.8 915.1 172 812.4 250.1 776.4C347.8 731.4 346.4 728.6 250.1 689.2C153.8 649.9 107 547.2 107 503.7C107 460.1 83.4 207 470 207C856.7 207 833 460.1 833 503.7C833 547.2 786.2 649.9 689.9 689.2C593.5 728.6 592.2 731.4 689.9 776.4C768 812.4 847.2 915.1 877 962',
                    's3'
                )
            )),
            
            // HAIR
            shortHair[0],
            shortHair[1],
            shortHair[2],
            
            // HAIR + ACCESSORIES
            string(abi.encodePacked(wings, shortHair[0])),
            string(abi.encodePacked(wings, shortHair[1])),
            string(abi.encodePacked(wings, shortHair[2])),
            string(abi.encodePacked(powerPak, shortHair[0])),
            string(abi.encodePacked(powerPak, shortHair[1])),
            string(abi.encodePacked(powerPak, shortHair[2])),
            
            // ACCESSORIES
            wings,
            powerPak,
            
            // ACCESSORY - HEADPHONES
            _path(
                "M152.004 414.75C123.627 419.571 95.991 425.823 95.3108 431.03C90.8247 465.37 92.1981 493.633 92.1981 505.578C92.1981 515.884 194.718 552.5 206.072 552.5C206.072 552.5 205.067 507.911 205.572 479.5C206.077 451.089 212.072 407 212.072 407C205.586 407 178.472 410.253 152.004 414.75ZM152.004 414.75C152.312 177.239 172.88 161.001 470 161.001C767.147 161.001 787.642 177.242 787.946 414.814M787.946 414.814C816.19 419.626 843.584 425.846 844.261 431.03C848.748 465.37 847.374 493.633 847.374 505.578C847.374 515.884 744.855 552.5 733.5 552.5C733.5 552.5 734.505 507.911 734 479.5C733.495 451.089 727.5 407 727.5 407C734.017 407 761.358 410.284 787.946 414.814Z",
				"s3"
			),
            
            // ACCESSORY - VIBES
            string(abi.encodePacked(
                _path(
                    "M-158 454C-158 377.595 -128.748 -163.906 468.5 -150.765M1093 454C1093 377.595 1065.75 -164.042 468.5 -150.901",
                    "s3"
                ),
                _path(
                    "M-51.5273 784.286C10.0195 710.797 3.6025 745.726 -43.3185 664.204C-95.3419 573.818 -84.7645 522.338 -84.7645 454.575C-84.7645 386.812 -60.0675 -93.5654 467.5 -81.9106C994.864 -93.5436 1020.82 385.935 1020.82 453.572C1020.82 521.208 1038.81 574.242 986.803 664.459C939.9 745.829 933.485 710.965 995.008 784.316",
                    "s3"
                ),
                _path(
                    "M72 975C93.8104 926.163 152.56 833.629 198.836 781.604C238.095 737.468 237.088 734.538 198.836 690.766C143.99 628.007 133.666 542.789 133.666 497.37C133.666 451.951 131.804 145.004 465 145.004C803.163 145.004 807.415 451.951 807.415 497.37C807.415 542.789 796.937 628.007 741.273 690.766C702.451 734.538 701.43 737.468 741.273 781.604C788.239 833.629 847.864 926.163 870 975",
                    "s3"
                ),
                _path(
                    "M-24 990C-1.31124 935.881 54.6084 827.012 107.944 775.688C151.925 733.366 150.878 730.119 107.944 675.027C52.4624 603.834 50.5621 517.148 50.5621 466.817C50.5621 416.486 73.2789 60.3823 465 69.0388C856.721 60.3823 886.438 416.37 886.438 466.701C886.438 517.031 884.538 603.718 829.056 674.911C786.122 730.003 785.075 733.25 829.056 775.572C882.392 826.896 938.311 935.765 961 989.884",
                    "s3"
                ),
                _path(
                    "M-127 1034C-85.3969 979.127 -31.2033 851.273 31.2013 776.646C84.5569 712.84 78.9939 743.167 38.3177 672.387C-6.7819 593.911 -11.4966 522.705 -11.4966 463.871C-11.4966 405.037 11.6469 -11.938 469 -1.81886C926.353 -11.938 954.497 405.036 954.497 463.871C954.497 522.705 949.782 593.911 904.682 672.387C864.006 743.167 858.443 712.84 911.799 776.646C974.203 851.273 1028.4 979.127 1070 1034",
                    "s3"
                )
            )),

            // ACCESSORY - DEVILISH
            string(abi.encodePacked(
                _path(
                    "M157 195L183.845 222.45C198.16 237.088 219.86 249.344 243.571 254.694C267.192 260.023 291.57 258.252 312.116 246.681C281.006 266.321 277.006 270.321 259.391 287.247C251.786 286.735 244.275 285.606 236.969 283.958C221.31 280.425 206.238 274.436 192.752 266.672C202.633 307.692 233.31 350.466 245.485 362.377C238.5 379.5 238 381 232.5 398.5C213.27 379.685 160.102 300.627 158.127 233.378L157 195Z",
                    "fB eO nS"
                ),
                _path(
                    "M782.171 195L755.326 222.45C741.011 237.088 719.311 249.344 695.6 254.694C671.98 260.023 647.601 258.252 627.055 246.681C658.166 266.321 662.166 270.321 679.78 287.247C687.385 286.735 694.897 285.606 702.203 283.958C717.861 280.425 732.933 274.436 746.419 266.672C736.538 307.692 706.675 350.466 694.5 362.377C701.485 379.5 701.985 381 707.485 398.5C726.715 379.685 779.069 300.627 781.044 233.378L782.171 195Z",
                    "fB eO nS"
                ),
                _path(
                    "M145.148 777.499C136.864 777.499 130.148 770.784 130.148 762.5L130.147 676.961L218.795 676.961C227.08 676.961 233.795 683.677 233.795 691.961C233.795 700.245 227.08 706.961 218.795 706.961L184.793 706.961L228.724 745.757C231.769 748.445 233.593 752.254 233.779 756.311C233.966 760.369 232.499 764.328 229.714 767.285L180.805 819.21L215.5 854.5L198.5 880.5L149.292 829.927C143.651 824.178 143.558 815 149.08 809.137L197.256 757.991L160.148 725.22L160.148 762.499C160.148 770.783 153.433 777.499 145.148 777.499Z",
                    "fB eO nS"
                )
            )),

            // ACCESSORY - ZAP
            string(abi.encodePacked(
                _path(
                    "M799.9 126L743.2 211.5L726.3 159.8L672.6 244",
                    "mJ"
                ),
                _path(
                    "M465.4 17L481.7 118.3L434.3 91.87L451.9 190.1",
                    "mJ"
                ),
                _path(
                    "M126 146.4L208.9 206.8L156.6 221.4L238.4 278.8",
                    "mJ"
                )
            )),

            // ACCESSORY - HEXED
            string(abi.encodePacked(
                _path(
                    "M1078.9 314.2C1032 217 977.3 123.7 915.3 35.12L895.3 6.7C870.6 -28.4 800.8 -79.1 800.8 -79.12H157.7C157.7 -79.1 87.9 -28.4 63.3 6.74L43.3 35.3C-18.7 123.9 -73.5 217.3 -120.4 314.5"
                ),
                _path(
                    "M0 962C21.5 911.4 77.9 823.3 125.1 761.7C160 716.1 157.2 720.5 125 668C97 620.5 96.2 619 72 568.7L62 547.9C49.7 522.2 43.3 494.1 43.3 465.7C43.3 437.3 49.7 409.2 62 383.502L72 362.7C103.1 298 139.3 235.9 180.4 176.9L193.6 157.9C209.9 134.5 231.3 114.9 256.1 100.7C281 86.5 308.8 77.9 337.4 75.7L360.7 73.8C432.8 68.1 505.2 68.1 577.3 73.8L600.6 75.7C629.2 77.9 657 86.5 681.9 100.7C706.7 114.9 728.1 134.5 744.4 157.9L757.6 176.7C798.7 235.7 834.9 297.8 866 362.5L876 383.2C888.3 408.9 894.7 437 894.7 465.4C894.7 493.9 888.3 522 876 547.6L866 568.46C844.9 612.3 840 623.5 813.5 668C778.2 723.6 771.2 722.1 812.9 761.6C863.5 809.6 916.5 911.4 938 962"
                ),
                _path(
                    "M85 955C106.4 907.9 163.9 818.7 209.2 768.5C247.7 726 241.3 733.3 200.5 669.4C181.3 640.1 164.7 606.7 143 562.3L134.8 544.9C124.6 523 119.4 499.2 119.4 475.1C119.4 451.1 124.6 427.3 134.8 405.6L143 388C168.7 333.2 198.6 280.7 232.4 230.8L243.3 214.7C256.8 194.9 274.4 178.3 294.9 166.3C315.4 154.3 338.3 147 362 145.1L381.1 143.6C440.6 138.7 500.4 138.7 559.9 143.6L579 145.1C602.7 147 625.6 154.3 646.1 166.3C666.6 178.3 684.2 194.9 697.7 214.7L708.6 230.6C742.4 280.5 772.3 333 797.9 387.8L806.2 405.4C816.4 427.1 821.6 450.9 821.6 474.9C821.6 499 816.4 522.7 806.2 544.5L797.9 562.1C780.6 599.2 762.5 636.1 739.7 670.4C695.8 727.8 693.3 726 731.8 768.5C777.1 818.7 834.6 907.9 856 955"
                ),
                _path(
                    "M1003 941C952.8 791.3 866.6 736.9 866.6 708.7C866.6 678 915.1 631.4 935.7 587.9L947.3 563.2C961.7 532.7 969.2 499.4 969.2 465.7C969.2 431.9 961.7 398.6 947.3 368.2L935.7 343.6C899.4 266.8 857.1 193.1 809.3 123.2L793.8 100.8C774.8 73 749.9 49.9 720.848 32.9994C691.827 16.1331 659.434 5.9878 626.032 3.30067L598.914 1.10053C514.776 -5.70018 430.237 -5.70018 346.103 1.10053L318.984 3.30067C285.581 5.9878 253.191 16.1331 224.169 32.9994C195.148 49.8655 170.223 73.0295 151.206 100.807L135.759 123.358C87.8703 193.33 45.6013 267.035 9.35409 343.773L-2.31787 368.474C-16.6995 398.941 -24.1613 432.249 -24.1613 465.981C-24.1613 499.713 -16.6995 533.02 -2.31787 563.487L9.35409 588.189C32.3854 636.949 67.9719 680.291 67.9719 707.698C67.9719 741.305 -39.044 848.596 -73 937.923"
                ),
                _path(
                    "M1125 974.5C1068 804.6 945 719.1 941.5 702.8C941.5 691 978.8 649.1 1002.2 599.7L1015.4 571.7C1031.7 537.1 1040.2 499.3 1040.2 461C1040.2 422.8 1031.7 385 1015.4 350.4L1002.2 322.5C961 235.4 913 151.7 858.6 72.3L841.1 46.9C819.5 15.4 791.2 -10.9 758.3 -30C725.3 -49.2 688.5 -60.7 650.6 -63.7L619.8 -66.2C524.3 -73.9 428.3 -73.9 332.8 -66.2L302 -63.7C264.1 -60.7 227.3 -49.2 194.4 -30C161.4 -10.9 133.1 15.4 111.5 46.9L94 72.5C39.6 152 -8.3 235.6 -49.5 322.7L-62.8 350.7C-79.1 385.3 -87.6 423.1 -87.6 461.4C-87.5 499.7 -79.1 537.5 -62.8 572L-49.5 600.1C-23.3 655.4 -6.9 689.5 -4.8 698.2C-4.8 707.4 -104.4 895.6 -143 997"
                )
            )),

            // NO HAIR + NO ACCESSORY
            ""

        ];

        return 
            string(abi.encodePacked(
                '<g id="s">',
                    combinations[_surroundIndex(tokenId)],
                "</g>"
            ));
    }


	/** @dev Internal drawing helper function that renders a path element
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<path d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute
	  * @param d A string containing the path's `d` attribute
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Uint2str {


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
}