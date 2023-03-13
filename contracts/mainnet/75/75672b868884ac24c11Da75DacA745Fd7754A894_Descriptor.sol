// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {

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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
pragma solidity ^0.8.19;
interface InterfaceRenderer {
    function renderSVG(
      uint16 _trait0,
      uint16 _trait1,
      uint16 _trait2,
      uint16 _trait3,
      uint16 _trait4,
      uint16 _trait5,
      uint16 _trait6,
      uint16 _trait7
    ) external view returns (bytes memory);
    }


pragma solidity 0.8.19;

contract Descriptor is Ownable {
  using Strings for uint256;

    InterfaceRenderer public renderer;
    InterfaceRenderer public rendererSpritesheet;

    uint16[][8] rarities;
    string[][8] traitsByName;

    string public metadata_description = "200% on-chain Ordinal Edgehog #";

    constructor(){

      renderer = InterfaceRenderer(0xE8D68c300214a766C17813184082259c83786CA0);
      rendererSpritesheet = InterfaceRenderer(0xaa05564b450Fe67D8757AAAA9Ae565B7954F40fB);

      rarities[0] = [0,2000,2000,2000,2000,2000]; //background
      traitsByName[0] = ["n/a","Blue","Emerald","Green","Pink","Purple"];

      rarities[1] = [0,500,200,1000,1500,200,1000,1000,500,1000,200,800,500,400,100,600,500]; //back
      traitsByName[1] = ["n/a","Ball","Ballsack","Bitcoin","Classic","Dildos","Edgy Blue","Edgy Green","Electric","Glitter","Heart","Hogdenza","Lava","Planet","Punk","Spikes","Turtle"];

      rarities[2] = [0,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000]; //pants
      traitsByName[2] = ["n/a","Black Pants","Blue Pants","Dark Armor","Green Pants","Knight Armor","Orange Pants","Pink Pants","Purple Pants","Red Pants","Yellow Pants"];

      rarities[3] = [0,1500,1000,1000,1000,500,1500,1000,1000,1200,300]; //clothes
      traitsByName[3] = ["n/a","Bitboy","Buff","Collar","Heartbeat","Knight","Rockstar","Soccer","Stripes","Tie","Vader"];

      rarities[4] = [0,3000,800,700,200,100,1000,100,1000,200,500,500,300,100,500,500,500]; //headgear
      traitsByName[4] = ["n/a","None","Bandana","Crest","Crown","Darth","Ducky","Edgerine","Furry Ears","Knight Helm","Leprechaun","Military","Poo","Sandman","Saudi","Uncle Sam","Wizard"];

      rarities[5] = [0,1500,1500,1500,500,500,500,500,500,1500,1500]; //shoes
      traitsByName[5] = ["n/a","Bare Feet","Black Shoes","Blue Sneakers","Clown Boots","Elven Shoes","Fins","Heels","Party Shoes","Red Shoes","White Sneakers"];

      rarities[6] = [0,3000,500,500,300,700,300,200,500,500,600,500,500,900,1000]; //item
      traitsByName[6] = ["n/a","None","Bong","Booze","Chainsaw","Claws","Diamond Hand","Dildo","Down Bad","Lightsaber","Love Letter","Shroom","Sword","Up Only","Whiskey"];   

      rarities[7] = [0,500,100,200,1000,600,100,500,500,500,3000,300,500,200,1000,1000]; //eyes
      traitsByName[7] = ["n/a","3D","Beam","Creepy","Cute","Evil Genius","Flames","Goggles","Hoggo","Insane","Just Eyes","Maxi","Ninja","Noun","Popping","Sus"];
    
    }

    ///////////////////////////////////////////////////////////
    /////🦔GENERATE TRAITS AND SVG BASED ON SEED🦔////////////
    ///////////////////////////////////////////////////////////

    //Get randomized values for each different trait with a single pseudorandom seed
    // note: we are generating both traits and SVG on the fly based on the seed which is the the only parameter saved in memory
    // Not writing a whole struct allows for serious gas savings on mint, but has a downside that we can't easily address or change a single trait
    function getTraits(uint256 seed)
      public
      view
      returns (
        string memory svg, 
        string memory html,
        string memory properties
       )
    {
      uint16[] memory randomInputs = expand(seed, 8);
      uint16[] memory traits = new uint16[](8);

      traits[0] = getRandomIndex(rarities[0], randomInputs[0]);
      traits[1] = getRandomIndex(rarities[1], randomInputs[1]);
      traits[2] = getRandomIndex(rarities[2], randomInputs[2]);
      traits[3] = getRandomIndex(rarities[3], randomInputs[3]);
      traits[4] = getRandomIndex(rarities[4], randomInputs[4]);
      traits[5] = getRandomIndex(rarities[5], randomInputs[5]);
      traits[6] = getRandomIndex(rarities[6], randomInputs[6]);  
      traits[7] = getRandomIndex(rarities[7], randomInputs[7]); 

      //handling compatibility exceptions
      //              Darth            Edgerine        Knight Helm         Sandman > no eyes
      if (traits[4] == 5 || traits[4] == 7 || traits[4] == 9 || traits[4] == 13) {
        traits[7] = 0;
      }
      //Sandman > no item
      if (traits[4] == 13) {
        traits[6] = 1;
      }

      // render svg
      bytes memory _svg = renderer.renderSVG(
        traits[0],
        traits[1],
        traits[2],
        traits[3],
        traits[4],
        traits[5],
        traits[6],
        traits[7]
      );

      bytes memory _svgSpritesheet = rendererSpritesheet.renderSVG(
        traits[0],
        traits[1],
        traits[2],
        traits[3],
        traits[4],
        traits[5],
        traits[6],
        traits[7]
      );

      // render HTML
      bytes memory _html = abi.encodePacked("<html><body style='margin: 0;'>",_svgSpritesheet,"</html></body>");
  
      // pack properties, put 1 after the last property for JSON to be formed correctly (no comma after the last entry)
      bytes memory _properties = abi.encodePacked(
        packMetaData("Background", _getTrait(0, traits[0]), 0),
        packMetaData("Back",       _getTrait(1, traits[1]), 0),
        packMetaData("Pants",      _getTrait(2, traits[2]), 0),
        packMetaData("Clothes",    _getTrait(3, traits[3]), 0),
        packMetaData("Headgear",   _getTrait(4, traits[4]), 0),
        packMetaData("Shoes",      _getTrait(5, traits[5]), 0),
        packMetaData("Item",       _getTrait(6, traits[6]), 0),
        packMetaData("Eyes",       _getTrait(7, traits[7]), 1)
      );
           
      svg = base64(_svg);
      html = base64(_html);
      properties = string(abi.encodePacked(_properties));

      return (svg, html, properties);

    }

    // Get a random attribute using the rarities defined
    // Shout out to Anonymice for the logic
    function getRandomIndex(
      uint16[] memory attributeRarities,
      uint256 randomNumber
    ) private pure returns (uint16 index) {
      uint16 random10k = uint16(randomNumber % 10000);
      uint16 lowerBound;
      for (uint16 i = 1; i <= attributeRarities.length; i++) {
        uint16 percentage = attributeRarities[i];

        if (random10k < percentage + lowerBound && random10k >= lowerBound) {
          return i;
        }
        lowerBound = lowerBound + percentage;
      }
      revert();
    }

  /////////////////////////////////////
  /////🦔GENERATE METADATA🦔//////////
  ////////////////////////////////////

    //Get the metadata for a token in base64 format
    function tokenURI(uint256 tokenId, uint256 tokenSeed)
      public
      view
      virtual
      returns (string memory)
    {
      (string memory svg, string memory html, string memory properties) = getTraits(tokenSeed);
      string memory _description = string(abi.encodePacked(metadata_description,tokenId.toString()));
      return
        string(
          abi.encodePacked(
            "data:application/json;base64,",
            base64(
              abi.encodePacked(
                '{"name":"Edgehog Ordinal #',
                tokenId.toString(),' ',
                '", "description": "',_description,'", "traits": [',
                properties,
                '], "image":"data:image/svg+xml;base64,',
                svg, '",',
                ' "animation_url": "data:text/html;base64,',
                html,
                '"}'
              )
            )
          )
        );
    }

    // Bundle metadata so it follows the standard
    function packMetaData(
      string memory _name,
      string memory _value,
      uint256 last
    ) private pure returns (bytes memory) {
      string memory comma = ",";
      if (last > 0) comma = "";
      return
        abi.encodePacked(
          '{"trait_type": "',
          _name,
          '", "value": "',
          _value,
          '"}',
          comma
        );
    }

    /////////////////////////
    //🦔HELPER FUNCTIONS🦔//
    /////////////////////////


    //Get the attribute name for the properties of the token by its index
    function _getTrait(uint256 _trait, uint256 index)
      internal
      view
      returns (string memory)
    {
      return traitsByName[_trait][index];
    }

    ///set attributes libraries
    function setRenderer(address _renderer) external onlyOwner {
        renderer = InterfaceRenderer(_renderer);
    }

    function setRendererSpritesheet(address _rendererSpritesheet) external onlyOwner {
        rendererSpritesheet = InterfaceRenderer(_rendererSpritesheet);
    }

    ///set external uri
    function setMetadataDescription(string calldata _description) external onlyOwner {
        metadata_description = _description;
    }


    //generates random numbers based on a random number
    function expand(uint256 _randomNumber, uint256 n)
        private
        pure
        returns (uint16[] memory expandedValues)
    {
        expandedValues = new uint16[](n);
        for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = bytes2uint(keccak256(abi.encode(_randomNumber, i)));
        }
        return expandedValues;
    }

    //converts uint256 to uint16
    function bytes2uint(bytes32 _a) private pure returns (uint16) {
        return uint16(uint256(_a));
  }

    //  Base64 by Brecht Devos - <[email protected]>
    //  Provides a function for encoding some bytes in base64

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