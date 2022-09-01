// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SSTORE2.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import '@divergencetech/ethier/contracts/utils/DynamicBuffer.sol';
import './interfaces/IExquisiteGraphics.sol';

interface IInflator {
    function puff(bytes memory source, uint256 destlen) external pure returns (uint8, bytes memory);
}

interface ICCZPayment {
    function addPayee(address account, uint256 shares_) external; 
}

interface ICCZooMain {
    function ownerOf(uint256 tokenId) external returns(address); 
    function getMetadataHash(uint256 tokenId) external view returns(uint256 );
    function totalSupply() external view returns(uint256);
}

contract CCZooRender is OwnableUpgradeable {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    uint8 constant NUM_LAYERS = 5;
    uint256 constant TRAIT_TOTAL = 199;
    address public artAllowed;

    IExquisiteGraphics public gfx;
    IInflator public inflateLib;
    ICCZPayment public cczpayment;
    ICCZooMain public cczoo;

    struct Animal {
        bool curated;
        string name;
        address data;
        address submitter;
        uint256 destLen;
    }

    struct Trait {
        address data;
        uint256 destLen;
    }

    uint16[][NUM_LAYERS] private TIERS;
    string[NUM_LAYERS] public LAYER_NAMES;
    IExquisiteGraphics.Palette[] palettes;

    //some sort of mapping for the traits
    mapping(uint256 => Trait) traits;
    mapping(uint256 => string[]) traitNames; 
    Animal[] animals;

    //mapping for the metadata
    mapping(uint256 => uint256) tokenAnimal;

    error animalDoesntExist();
    error tokenDoesntExists();
    error notOwnerOfToken();
    error notAllowedToAddAnimals();

    event animalSuggested(string indexed _name, bytes _data, address indexed _by);
    event animalSet(uint256 indexed tokenId, uint256 animalId);

    function initialize() initializer public {
        __Ownable_init();
        TIERS[0] = [33,33,33,33,33,35];
        TIERS[1] = [200];
        TIERS[2] = [100, 100]; 
        TIERS[3] = [100, 100];
        TIERS[4] = [100, 100];
        artAllowed = msg.sender;
        LAYER_NAMES = ["Palette", "Background", "Hat", "Hand" , "Ground"];
    }

    ////////////////////////  Set external contract addresses /////////////////////////////////

    function setGfx( address newGfx) public onlyOwner {
        gfx = IExquisiteGraphics(newGfx);
    }

    function setInflator( address newInflate) public onlyOwner {
        inflateLib = IInflator(newInflate);
    }

    function setPayment( address newPayment) public onlyOwner {
        cczpayment = ICCZPayment(newPayment);
    }

    function setCCZooMain( address newCCZoo) public onlyOwner {
        cczoo = ICCZooMain(newCCZoo);
    }

    ////////////////////////  Set allowed addresses /////////////////////////////////

    function setArtAllowed(address _newArtAllowed) external onlyOwner {
        artAllowed = _newArtAllowed;
    }

    ////////////////////////  Metadata functions /////////////////////////////////

    function getTokenTraits(uint256 tokenId) public view returns(uint256[NUM_LAYERS] memory tokenTraits) {
        uint16[NUM_LAYERS] memory dna = splitNumber(cczoo.getMetadataHash(tokenId));
        for (uint8 i = 0; i < NUM_LAYERS; i ++) {
            tokenTraits[i] = getLayerIndex(dna[i], i);
        }
    }

    ////////////////////////  Upload and set data for traits, palletes and animals  /////////////////////////////////

    function setTrait(uint256 trait, bytes memory _data, uint256 destLen, string[] memory names) external onlyOwner {
        traits[trait] = (Trait(SSTORE2.write(_data), destLen));
        traitNames[trait] = names;
    }

    // function setPalettes(IExquisiteGraphics.Palette[] memory _newColors, string[] memory names) external onlyOwner {
    //     for(uint256 i = 0; i < _newColors.length; i++) {
    //         palettes.push(_newColors[i]);
    //     }
    //     traitNames[0] = names;
    // }

    function addAnimal(string memory name, bytes memory _data, uint256 destLen) external {
        emit animalSuggested(name, _data, msg.sender);
        animals.push(Animal(false, name, SSTORE2.write(_data), msg.sender, destLen));
    }

    function allowedAddAnimal(string memory name, bytes memory _data, uint256 destLen) external {
        if(msg.sender != artAllowed) revert notAllowedToAddAnimals();
        animals.push(Animal(true, name, SSTORE2.write(_data), msg.sender, destLen));
    }

    function currateAnimal(uint8 _animalId, address) external {
        if(msg.sender != artAllowed) revert notAllowedToAddAnimals();
        animals[_animalId].curated = true;
        cczpayment.addPayee(animals[_animalId].submitter, 1);
    }

    function setAnimal(uint256 tokenId, uint8 animal) public {
        if(cczoo.ownerOf(tokenId) != msg.sender) revert notOwnerOfToken(); //ownerof
        if(animal >= animals.length) revert animalDoesntExist();
        tokenAnimal[tokenId] = animal; 
        emit animalSet(tokenId, animal);
    }

    ////////////////////////  Get Info on traits and animals /////////////////////////////////

    function getAnimals() public view returns(string[][] memory _animalList) {
        _animalList = new string[][](animals.length - 1);
        for(uint256 i = 1; i < animals.length; i++) { 
            _animalList[i-1] = new string[](3);
            _animalList[i-1][0] = Strings.toString(i);
            _animalList[i-1][1] = animals[i].name; 
            _animalList[i-1][2] = (animals[i].curated ? "curated": "");
        }
    }

    function getTraitNames() public view returns(string[][] memory allTraits) {
        allTraits = new string[][](NUM_LAYERS);
        for(uint256 i = 0; i < NUM_LAYERS; i++) {
            allTraits[i] = new string[](traitNames[i].length);
            allTraits[i] = traitNames[i];   
        }
    }

    function getTokenAnimal(uint256 tokenId) public view returns(string memory) {
        return animals[tokenAnimal[tokenId]].name;
    }

    function checkAnimal(string memory name) public view returns(bool) {
        for(uint8 i = 0; i < animals.length; i++) {
            if(keccak256(abi.encodePacked(animals[i].name)) == keccak256(abi.encodePacked(name))) return true;
        }
        return false;
    }

    function _getAnimal(string memory name) private view returns(Animal memory) {
        for(uint8 i = 0; i < animals.length; i++) {
            if(keccak256(abi.encodePacked(animals[i].name)) == keccak256(abi.encodePacked(name))) return animals[i];
        }
        revert animalDoesntExist();
    }

    ////////////////////////  Helper functions /////////////////////////////////

    function splitNumber(uint256 _number) public pure returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % TRAIT_TOTAL);
            _number >>= 14; //maybe change this number? 
        }
        return numbers;
    }

    function getLayerIndex(uint16 _dna, uint8 _index) public view returns (uint256) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < TIERS[_index].length; i++) {
            percentage = TIERS[_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return TIERS[_index].length;
    }

    function _getSize(bytes memory data) internal pure returns (uint8 _size) {
        uint128 h;
        assembly { h := mload(add(data, 16)) }
        return uint8(h >> 56); 
    }

    ////////////////////////  TokenURI /////////////////////////////////

    function tokenURI(uint256 tokenId) public view returns (string memory) { //view
        if(tokenId > cczoo.totalSupply() || tokenId == 0 ) revert tokenDoesntExists();

        uint256[NUM_LAYERS] memory tokenTraits = getTokenTraits(tokenId);

        string memory _outString = string.concat('data:application/json,', '{', '"name" : "CCZoo ' , Strings.toString(tokenId), '", ',
            '"description" : "An editable and expandable CC0 zoo, where everyone can contribute!"');
        
        _outString = string.concat(_outString, ',"attributes":[');
        for(uint8 i = 1; i < NUM_LAYERS; i++) {
            if(i > 1) _outString = string.concat(_outString,',');
              _outString = string.concat(
              _outString,
             '{"trait_type":"',
              LAYER_NAMES[i],
              '","value":"',
              traitNames[i][tokenTraits[i]],
              '"}'
          );
        }
        _outString = string.concat(_outString, ']');
       
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        _getTokenSVG(tokenTraits, tokenId ,buffer);

        _outString = string.concat(_outString,',"image": "data:image/svg+xml;base64,',
            Base64.encode(buffer),'"}');

        //add how attributes are added
        return _outString; 
    }

    ////////////////////////  Full SVG functions /////////////////////////////////

    function _getTokenSVG(uint256[NUM_LAYERS] memory tokenTraits, uint256 tokenId, bytes memory buffer) public view  { 
        uint8[2][3] memory locations;
        bytes memory _animalData;
        bytes memory _animalImage;
        if(tokenAnimal[tokenId] == 0) {
            _animalData = _renderAnimal(animals[ (uint256(keccak256(abi.encodePacked(tokenId,block.number))) % (animals.length-1)) + 1]);
        } else {
            _animalData = _renderAnimal(animals[tokenAnimal[tokenId]]);
        }
        IExquisiteGraphics.Palette memory _currentPallet = _getTokenPalette(tokenTraits[0]);
        (locations, _animalImage) = gfx.drawPixelsAnimal(_animalData, _currentPallet);
        uint8 _size = _getSize(_animalData);
        
        buffer.appendSafe(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ', Strings.toString(_size), ' ', Strings.toString(_size),  '" width="320" height="320" ')));
        
        //render background
        _renderBack(traits[1], tokenTraits[1], buffer);
        buffer.appendSafe(_animalImage);
        for(uint256 i = 2; i < tokenTraits.length; i++) {
            if( tokenTraits[i] == 0) continue; 
            if((locations[i-2][0] == 0) && (locations[i-2][1] == 0)) continue;
            _renderTrait(traits[i], tokenTraits[i], buffer, locations[i-2][0], locations[i-2][1]);
         }
        buffer.appendSafe('</svg>');
    }

    function getTokenSVGWithAnimal(uint256 tokenId, string memory name)  public view returns (string memory) {
        if(!checkAnimal(name)) revert animalDoesntExist();
       
        uint256[NUM_LAYERS] memory tokenTraits = getTokenTraits(tokenId);

        uint8[2][3] memory locations;
        bytes memory _animalData;
        bytes memory _animalImage;
        _animalData = _renderAnimal(_getAnimal(name));

        IExquisiteGraphics.Palette memory _currentPallet = _getTokenPalette(tokenTraits[0]);
        (locations, _animalImage) = gfx.drawPixelsAnimal(_animalData, _currentPallet);
        uint8 _size = _getSize(_animalData);
        
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        buffer.appendSafe(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ', Strings.toString(_size), ' ', Strings.toString(_size),  '" width="320" height="320" ')));
        
        //render background
        _renderBack(traits[1], tokenTraits[1], buffer);

        buffer.appendSafe(_animalImage);

        for(uint256 i = 2; i < tokenTraits.length; i++) {
            if( tokenTraits[i] == 0) continue; 
            if((locations[i-2][0] == 0) && (locations[i-2][1] == 0)) continue;
            _renderTrait(traits[i], tokenTraits[i], buffer, locations[i-2][0], locations[i-2][1]);
         }
        buffer.appendSafe('</svg>');
        return string(buffer);
    }  

    function getTokenSVGForBytes(bytes memory _animal, uint256[NUM_LAYERS] memory tokenTraits)  public view returns (string memory) {
        
        uint8 _size = _getSize(_animal);
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        buffer.appendSafe(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ', Strings.toString(_size), ' ', Strings.toString(_size),  '" width="320" height="320" ')));
        
        //render background
        _renderBack(traits[1], tokenTraits[1], buffer);
        
        //render animal
        uint8[2][3] memory locations;
        bytes memory _animalData;
        IExquisiteGraphics.Palette memory _currentPallet = _getTokenPalette(tokenTraits[0]);
        (locations, _animalData) = gfx.drawPixelsAnimal(_animal, _currentPallet);
        buffer.appendSafe(_animalData);

        for(uint256 i = 2; i < tokenTraits.length; i++) {
            if( tokenTraits[i] == 0) continue; 
            if((locations[i-2][0] == 0) && (locations[i-2][1] == 0)) continue;
            _renderTrait(traits[i], tokenTraits[i], buffer, locations[i-2][0], locations[i-2][1]);
         }
        buffer.appendSafe('</svg>');
        return string(buffer);
    }   

    ////////////////////////  SVG helper functions /////////////////////////////////

    function _renderTrait(Trait memory _currentTrait, uint256 _currentTokenTrait, bytes memory buffer, uint8 _locx, uint8 _locy) private view  { //view
        (, bytes memory _toDecode) = inflateLib.puff(SSTORE2.read(_currentTrait.data), _currentTrait.destLen);
        bytes[] memory _traitData = abi.decode(_toDecode, (bytes[]));
        buffer.appendSafe(gfx.drawPixelsItems(_traitData[_currentTokenTrait], _locx, _locy));
    }

    function _renderBack(Trait memory _currentTrait, uint256 _currentTokenTrait, bytes memory buffer) private view {
        (, bytes memory _toDecode) = inflateLib.puff(SSTORE2.read(_currentTrait.data), _currentTrait.destLen);
        bytes[] memory _traitData = abi.decode(_toDecode, (bytes[]));
        buffer.appendSafe(bytes('style="background-color:transparent;background-image:url(data:image/gif;base64,'));
        buffer.appendSafe(bytes(Base64.encode(_traitData[_currentTokenTrait])));
        buffer.appendSafe(bytes(');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;">'));
    }

    function _renderAnimal(Animal memory _currentAnimal) private view returns(bytes memory )  {
        (, bytes memory _toDecode) = inflateLib.puff(SSTORE2.read(_currentAnimal.data), _currentAnimal.destLen);
        return abi.decode(_toDecode, (bytes));
    }

    function _getTokenPalette(uint256 _tokenPalette) private view returns(IExquisiteGraphics.Palette memory )  { 
        (, bytes memory _toDecode) = inflateLib.puff(SSTORE2.read(traits[0].data), traits[0].destLen);
        IExquisiteGraphics.Palette[] memory _traitData = abi.decode(_toDecode, (IExquisiteGraphics.Palette[]));
        return _traitData[_tokenPalette];
    }

    ////////////////////////  Withdraw funds /////////////////////////////////

    function withdraw() external onlyOwner  { 
        (bool success,) = msg.sender.call{value : address(this).balance}("");
            require(success, "Withdrawal failed");
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
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
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExquisiteGraphics {
  struct Header {
    /* HEADER START */
    uint8 version; // 8 bits
    uint16 width; // 8 bits
    uint16 height; // 8 bits
    uint8 locx; // 8 bits
    uint8 locy; // 8 bits
    uint16 numColors; // 16 bits
    uint8 backgroundColorIndex; // 8 bits
    uint16 scale; // 10 bits
    uint8 reserved; // 4 bits
    bool alpha; // 1 bit
    bool hasBackground; // 1 bit
    /* HEADER END */

    /* CALCULATED DATA START */
    uint24 totalPixels; // total pixels in the image
    uint8 bitsPerPixel; // bits per pixel
    uint8 pixelsPerByte; // pixels per byte
    uint16 paletteStart; // number of the byte where the palette starts
    uint16 dataStart; // number of the byte where the data starts
    /* CALCULATED DATA END */
  }

  struct DrawContext {
    bytes data; // the binary data in .xqst format
    Header header; // the header of the data
    string[] palette; // hex color for each color in the image
    uint8[] pixels; // color index (in the palette) for a pixel
  }

  enum HeaderType {
    ITEM,
    ANIMAL
  }

  struct Palette {
        bytes3[] colors;
        PaletteTypes paletteType;
  }

    enum PaletteTypes {
        none,
        gray,
        monochrome,
        multicolorHue,
        multicolorFix,
        inverted
    }

  error ExceededMaxPixels();
  error ExceededMaxRows();
  error ExceededMaxColumns();
  error ExceededMaxColors();
  error BackgroundColorIndexOutOfRange();
  error PixelColorIndexOutOfRange();
  error MissingHeader();
  error NotEnoughData();
  error NoColors();

  /// @notice Draw the <rect> elements of an SVG from the data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawPixelsItems(bytes memory data, uint8 xOffset, uint8 yOffset)
    external
    view
    returns (bytes memory);

    function drawPixelsAnimal(bytes memory data, Palette memory palette)
    external
    view
    returns (uint8[2][3] memory , bytes memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }

}