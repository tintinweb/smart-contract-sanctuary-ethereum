// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ContractDataStorage.sol";
import "./SvgParser.sol";

contract CyberBrokersMetadata is Ownable {
  using Strings for uint256;

  bool private _useOnChainMetadata = false;
  bool private _useIndividualExternalUri = false;

  string private _externalUri = "https://cyberbrokers.io/";
  string private _imageCacheUri = "ipfs://QmcsrQJMKA9qC9GcEMgdjb9LPN99iDNAg8aQQJLJGpkHxk/";

  // Mapping of all layers
  struct CyberBrokerLayer {
    string key;
    string attributeName;
    string attributeValue;
  }
  CyberBrokerLayer[1460] public layerMap;

  // Mapping of all talents
  struct CyberBrokerTalent {
    string talent;
    string species;
    string class;
    string description;
  }
  CyberBrokerTalent[51] public talentMap;

  // Directory of Brokers
  uint256[10001] public brokerDna;

  // Bitwise constants
  uint256 constant private BROKER_MIND_DNA_POSITION = 0;
  uint256 constant private BROKER_BODY_DNA_POSITION = 5;
  uint256 constant private BROKER_SOUL_DNA_POSITION = 10;
  uint256 constant private BROKER_TALENT_DNA_POSITION = 15;
  uint256 constant private BROKER_LAYER_COUNT_DNA_POSITION = 21;
  uint256 constant private BROKER_LAYERS_DNA_POSITION = 26;

  uint256 constant private BROKER_LAYERS_DNA_SIZE = 12;

  uint256 constant private BROKER_MIND_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_BODY_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_SOUL_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_TALENT_DNA_BITMASK = uint256(0x2F);
  uint256 constant private BROKER_LAYER_COUNT_DNA_BITMASK = uint256(0x1F);
  uint256 constant private BROKER_LAYER_DNA_BITMASK = uint256(0x0FFF);

  // Contracts
  ContractDataStorage public contractDataStorage;
  SvgParser public svgParser;

  constructor(
    address _contractDataStorageAddress,
    address _svgParserAddress
  ) {
    // Set the addresses
    setContractDataStorageAddress(_contractDataStorageAddress);
    setSvgParserAddress(_svgParserAddress);
  }

  function setContractDataStorageAddress(address _contractDataStorageAddress) public onlyOwner {
    contractDataStorage = ContractDataStorage(_contractDataStorageAddress);
  }

  function setSvgParserAddress(address _svgParserAddress) public onlyOwner {
    svgParser = SvgParser(_svgParserAddress);
  }

  /**
   * Save the data on-chain
   **/
  function setLayers(
    uint256[] memory indexes,
    string[]  memory keys,
    string[]  memory attributeNames,
    string[]  memory attributeValues
  )
    public
    onlyOwner
  {
    require(
      indexes.length == keys.length &&
      indexes.length == attributeNames.length &&
      indexes.length == attributeValues.length,
      "Number of indexes much match keys, names and values"
    );

    for (uint256 idx; idx < indexes.length; idx++) {
      uint256 index = indexes[idx];
      layerMap[index] = CyberBrokerLayer(keys[idx], attributeNames[idx], attributeValues[idx]);
    }
  }

  function setTalents(
    uint256[] memory indexes,
    string[]  memory talent,
    string[]  memory species,
    string[]  memory class,
    string[]  memory description
  )
    public
    onlyOwner
  {
    require(
      indexes.length == talent.length &&
      indexes.length == species.length &&
      indexes.length == class.length &&
      indexes.length == description.length
    , "Number of indexes must match talent, species, class, and description");

    for (uint256 idx; idx < indexes.length; idx++) {
      uint256 index = indexes[idx];
      talentMap[index] = CyberBrokerTalent(talent[idx], species[idx], class[idx], description[idx]);
    }
  }

  function setBrokers(
    uint256[]  memory indexes,
    uint8[]    memory talent,
    uint8[]    memory mind,
    uint8[]    memory body,
    uint8[]    memory soul,
    uint16[][] memory layers
  )
    public
    onlyOwner
  {
    require(
      indexes.length == talent.length &&
      indexes.length == mind.length &&
      indexes.length == body.length &&
      indexes.length == soul.length &&
      indexes.length == layers.length,
      "Number of indexes must match talent, mind, body, soul, and layers"
    );

    for (uint8 idx; idx < indexes.length; idx++) {
      require(talent[idx] <= talentMap.length, "Invalid talent index");
      require(mind[idx] <= 30, "Invalid mind");
      require(body[idx] <= 30, "Invalid body");
      require(soul[idx] <= 30, "Invalid soul");

      uint256 _dna = (
        (uint256(mind[idx])   << BROKER_MIND_DNA_POSITION) +
        (uint256(body[idx])   << BROKER_BODY_DNA_POSITION) +
        (uint256(soul[idx])   << BROKER_SOUL_DNA_POSITION) +
        (uint256(talent[idx]) << BROKER_TALENT_DNA_POSITION) +
        (layers[idx].length   << BROKER_LAYER_COUNT_DNA_POSITION)
      );

      for (uint16 layerIdx; layerIdx < layers[idx].length; layerIdx++) {
        require(uint256(layers[idx][layerIdx]) <= layerMap.length, "Invalid layer index");
        _dna += uint256(layers[idx][layerIdx]) << (BROKER_LAYERS_DNA_SIZE * layerIdx + BROKER_LAYERS_DNA_POSITION);
      }

      uint256 index = indexes[idx];

      brokerDna[index] = _dna;
    }
  }

  /**
   * On-Chain Metadata Construction
   **/

  // REQUIRED for token contract
  function hasOnchainMetadata(uint256) public view returns (bool) {
    return _useOnChainMetadata;
  }

  function setOnChainMetadata(bool _state) public onlyOwner {
    _useOnChainMetadata = _state;
  }

  function setExternalUri(string calldata _uri) public onlyOwner {
    _externalUri = _uri;
  }

  function setUseIndividualExternalUri(bool _setting) public onlyOwner {
    _useIndividualExternalUri = _setting;
  }

  function setImageCacheUri(string calldata _uri) public onlyOwner {
    _imageCacheUri = _uri;
  }

  // REQUIRED for token contract
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Unpack the name, talent and layers
    string memory name = getBrokerName(tokenId);

    return string(
        abi.encodePacked(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                name,
                bytes('","description":"'),
                getDescription(tokenId),
                bytes('","external_url":"'),
                getExternalUrl(tokenId),
                bytes('","image":"'),
                getImageCache(tokenId)
            ),
            abi.encodePacked(
                bytes('","attributes":['),
                getTalentAttributes(tokenId),
                getStatAttributes(tokenId),
                getLayerAttributes(tokenId),
                bytes(']}')
            )
        )
    );
  }

  function getBrokerName(uint256 _tokenId) public view returns (string memory) {
    string memory _key = 'broker-names';
    require(contractDataStorage.hasKey(_key), "Broker names are not uploaded");

    // Get the broker names
    bytes memory brokerNames = contractDataStorage.getData(_key);

    // Pull the broker name size
    uint256 brokerNameSize = uint256(uint8(brokerNames[_tokenId * 31]));

    bytes memory name = new bytes(brokerNameSize);
    for (uint256 idx; idx < brokerNameSize; idx++) {
      name[idx] = brokerNames[_tokenId * (31) + 1 + idx];
    }

    return string(name);
  }

  function getLayers(uint256 tokenId) public view returns (uint256[] memory) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA -> layers
    uint256 dna = brokerDna[tokenId];
    require(dna > 0, "Broker DNA missing for token");

    uint256 layerCount = (dna >> BROKER_LAYER_COUNT_DNA_POSITION) & BROKER_LAYER_COUNT_DNA_BITMASK;
    uint256[] memory layers = new uint256[](layerCount);
    for (uint256 layerIdx; layerIdx < layerCount; layerIdx++) {
      layers[layerIdx] = (dna >> (BROKER_LAYERS_DNA_SIZE * layerIdx + BROKER_LAYERS_DNA_POSITION)) & BROKER_LAYER_DNA_BITMASK;
    }
    return layers;
  }

  function getDescription(uint256 tokenId) public view returns (string memory) {
    CyberBrokerTalent memory talent = getTalent(tokenId);
    return talent.description;
  }

  function getExternalUrl(uint256 tokenId) public view returns (string memory) {
    if (_useIndividualExternalUri) {
      return string(abi.encodePacked(_externalUri, tokenId.toString()));
    }

    return _externalUri;
  }

  function getImageCache(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_imageCacheUri, tokenId.toString(), ".svg"));
  }

  function getTalentAttributes(uint256 tokenId) public view returns (string memory) {
    CyberBrokerTalent memory talent = getTalent(tokenId);

    return string(
      abi.encodePacked(
        abi.encodePacked(
          bytes('{"trait_type": "Talent", "value": "'),
          talent.talent,
          bytes('"},{"trait_type": "Species", "value": "'),
          talent.species
        ),
        abi.encodePacked(
          bytes('"},{"trait_type": "Class", "value": "'),
          talent.class,
          bytes('"},')
        )
      )
    );
  }

  function getTalent(uint256 tokenId) public view returns (CyberBrokerTalent memory talent) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA
    uint256 dna = brokerDna[tokenId];
    require(dna > 0, "Broker DNA missing for token");

    // Get the talent
    uint256 talentIndex = (dna >> BROKER_TALENT_DNA_POSITION) & BROKER_TALENT_DNA_BITMASK;

    require(talentIndex < talentMap.length, "Invalid talent index");

    return talentMap[talentIndex];
  }

  function getStats(uint256 tokenId) public view returns (uint256 mind, uint256 body, uint256 soul) {
    require(tokenId <= 10000, "Invalid tokenId");

    // Get the broker DNA
    uint256 dna = brokerDna[tokenId];
    require(dna > 0, "Broker DNA missing for token");

    // Return the mind, body, and soul
    return (
      (dna >> BROKER_MIND_DNA_POSITION) & BROKER_MIND_DNA_BITMASK,
      (dna >> BROKER_BODY_DNA_POSITION) & BROKER_BODY_DNA_BITMASK,
      (dna >> BROKER_SOUL_DNA_POSITION) & BROKER_SOUL_DNA_BITMASK
    );
  }

  function getStatAttributes(uint256 tokenId) public view returns (string memory) {
    (uint256 mind, uint256 body, uint256 soul) = getStats(tokenId);

    return string(
      abi.encodePacked(
        abi.encodePacked(
          bytes('{"trait_type": "Mind", "value": '),
          mind.toString(),
          bytes('},{"trait_type": "Body", "value": '),
          body.toString()
        ),
        abi.encodePacked(
          bytes('},{"trait_type": "Soul", "value": '),
          soul.toString(),
          bytes('}')
        )
      )
    );
  }

  function getLayerAttributes(uint256 tokenId) public view returns (string memory) {
    // Get the layersg
    uint256[] memory layers = getLayers(tokenId);

    // Get the attribute names for all layers
    CyberBrokerLayer[] memory attrLayers = new CyberBrokerLayer[](layers.length);

    uint256 maxAttrLayerIdx = 0;
    for (uint16 layerIdx; layerIdx < layers.length; layerIdx++) {
      CyberBrokerLayer memory attribute = layerMap[layers[layerIdx]];

      if (keccak256(abi.encodePacked(attribute.attributeValue)) != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470) {
        attrLayers[maxAttrLayerIdx++] = attribute;
      }
    }

    // Compile the attributes
    string memory attributes = "";
    for (uint16 attrIdx; attrIdx < maxAttrLayerIdx; attrIdx++) {
      attributes = string(
        abi.encodePacked(
          attributes,
          bytes(',{"trait_type": "'),
          attrLayers[attrIdx].attributeName,
          bytes('", "value": "'),
          attrLayers[attrIdx].attributeValue,
          bytes('"}')
        )
      );
    }

    return attributes;
  }


  /**
   * On-Chain Token SVG Rendering
   **/

  // REQUIRED for token contract
  function render(
    uint256
  )
    public
    pure
    returns (string memory)
  {
    return string("To render the token on-chain, call CyberBrokersMetadata.renderBroker(_tokenId, _startIndex) or CyberBrokersMetadata._renderBroker(_tokenId, _startIndex, _thresholdCounter) and iterate through the pages starting at _startIndex = 0. To render off-chain and use an off-chain renderer, call CyberBrokersMetadata.getTokenData(_tokenId) to get the raw data. A JavaScript parser is available by calling CyberBrokersMetadata.getOffchainSvgParser().");
  }

  function renderData(
    string memory _key,
    uint256 _startIndex
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return _renderData(_key, _startIndex, 2800);
  }

  function _renderData(
    string memory _key,
    uint256 _startIndex,
    uint256 _thresholdCounter
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    require(contractDataStorage.hasKey(_key));
    return svgParser.parse(contractDataStorage.getData(_key), _startIndex, _thresholdCounter);
  }

  function renderBroker(
    uint256 _tokenId,
    uint256 _startIndex
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    return _renderBroker(_tokenId, _startIndex, 2800);
  }

  function _renderBroker(
    uint256 _tokenId,
    uint256 _startIndex,
    uint256 _thresholdCounter
  )
    public
    view
    returns (
      string memory,
      uint256
    )
  {
    require(_tokenId <= 10000, "Can only render valid token ID");
    return svgParser.parse(getTokenData(_tokenId), _startIndex, _thresholdCounter);
  }


  /**
   * Off-Chain Token SVG Rendering
   **/

  function getTokenData(uint256 _tokenId)
    public
    view
    returns (bytes memory)
  {
    uint256[] memory layerNumbers = getLayers(_tokenId);

    string[] memory layers = new string[](layerNumbers.length);
    for (uint256 layerIdx; layerIdx < layerNumbers.length; layerIdx++) {
      string memory key = layerMap[layerNumbers[layerIdx]].key;
      require(contractDataStorage.hasKey(key), "Key does not exist in contract data storage");
      layers[layerIdx] = key;
    }

    return contractDataStorage.getDataForAll(layers);
  }

  function getOffchainSvgParser()
    public
    view
    returns (
      string memory _output
    )
  {
    string memory _key = 'svg-parser.js';
    require(contractDataStorage.hasKey(_key), "Off-chain SVG Parser not uploaded");
    return string(contractDataStorage.getData(_key));
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Explaining the `init` variable within saveData:
 *
 * 61_00_00 -- PUSH2 (size)
 * 60_00 -- PUSH1 (code position)
 * 60_00 -- PUSH1 (mem position)
 * 39 CODECOPY
 * 61_00_00 PUSH2 (size)
 * 60_00 PUSH1 (mem position)
 * f3 RETURN
 *
 **/

contract ContractDataStorage is Ownable {

  struct ContractData {
    address rawContract;
    uint128 size;
    uint128 offset;
  }

  struct ContractDataPages {
    uint256 maxPageNumber;
    bool exists;
    mapping (uint256 => ContractData) pages;
  }

  mapping (string => ContractDataPages) internal _contractDataPages;

  mapping (address => bool) internal _controllers;

  constructor() {
    updateController(_msgSender(), true);
  }

  /**
   * Access Control
   **/
  function updateController(address _controller, bool _status) public onlyOwner {
    _controllers[_controller] = _status;
  }

  modifier onlyController() {
    require(_controllers[_msgSender()], "ContractDataStorage: caller is not a controller");
    _;
  }

  /**
   * Storage & Revocation
   **/

  function saveData(
    string memory _key,
    uint128 _pageNumber,
    bytes memory _b
  )
    public
    onlyController
  {
    require(_b.length < 24576, "SvgStorage: Exceeded 24,576 bytes max contract size");

    // Create the header for the contract data
    bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
    bytes1 size1 = bytes1(uint8(_b.length));
    bytes1 size2 = bytes1(uint8(_b.length >> 8));
    init[2] = size1;
    init[1] = size2;
    init[10] = size1;
    init[9] = size2;

    // Prepare the code for storage in a contract
    bytes memory code = abi.encodePacked(init, _b);

    // Create the contract
    address dataContract;
    assembly {
      dataContract := create(0, add(code, 32), mload(code))
      if eq(dataContract, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Store the record of the contract
    saveDataForDeployedContract(
      _key,
      _pageNumber,
      dataContract,
      uint128(_b.length),
      0
    );
  }

  function saveDataForDeployedContract(
    string memory _key,
    uint256 _pageNumber,
    address dataContract,
    uint128 _size,
    uint128 _offset
  )
    public
    onlyController
  {
    // Pull the current data for the contractData
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Store the maximum page
    if (_cdPages.maxPageNumber < _pageNumber) {
      _cdPages.maxPageNumber = _pageNumber;
    }

    // Keep track of the existance of this key
    _cdPages.exists = true;

    // Add the page to the location needed
    _cdPages.pages[_pageNumber] = ContractData(
      dataContract,
      _size,
      _offset
    );
  }

  function revokeContractData(
    string memory _key
  )
    public
    onlyController
  {
    delete _contractDataPages[_key];
  }

  function getSizeOfPages(
    string memory _key
  )
    public
    view
    returns (uint256)
  {
    // For all data within the contract data pages, iterate over and compile them
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Determine the total size
    uint256 totalSize;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      totalSize += _cdPages.pages[idx].size;
    }

    return totalSize;
  }

  function getData(
    string memory _key
  )
    public
    view
    returns (bytes memory)
  {
    // Get the total size
    uint256 totalSize = getSizeOfPages(_key);

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // Retrieve the pages
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // For each page, pull and compile
    uint256 currentPointer = 32;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      ContractData storage dataPage = _cdPages.pages[idx];
      address dataContract = dataPage.rawContract;
      uint256 size = uint256(dataPage.size);
      uint256 offset = uint256(dataPage.offset);

      // Copy directly to total data
      assembly {
        extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
      }

      // Update the current pointer
      currentPointer += size;
    }

    return _totalData;
  }

  function getDataForAll(string[] memory _keys)
    public
    view
    returns (bytes memory)
  {
    // Get the total size of all of the keys
    uint256 totalSize;
    for (uint256 idx; idx < _keys.length; idx++) {
      totalSize += getSizeOfPages(_keys[idx]);
    }

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // For each key, pull down all data
    uint256 currentPointer = 32;
    for (uint256 idx; idx < _keys.length; idx++) {
      // Retrieve the set of pages
      ContractDataPages storage _cdPages = _contractDataPages[_keys[idx]];

      // For each page, pull and compile
      for (uint256 innerIdx; innerIdx <= _cdPages.maxPageNumber; innerIdx++) {
        ContractData storage dataPage = _cdPages.pages[innerIdx];
        address dataContract = dataPage.rawContract;
        uint256 size = uint256(dataPage.size);
        uint256 offset = uint256(dataPage.offset);

        // Copy directly to total data
        assembly {
          extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
        }

        // Update the current pointer
        currentPointer += size;
      }
    }

    return _totalData;
  }

  function hasKey(string memory _key)
    public
    view
    returns (bool)
  {
    return _contractDataPages[_key].exists;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract SvgParser {

    // Limits
    uint256 constant DEFAULT_THRESHOLD_COUNTER = 2800;

    // Bits & Masks
    bytes1 constant tagBit            = bytes1(0x80);
    bytes1 constant startTagBit       = bytes1(0x40);
    bytes1 constant tagTypeMask       = bytes1(0x3F);
    bytes1 constant attributeTypeMask = bytes1(0x7F);

    bytes1 constant dCommandBit       = bytes1(0x80);
    bytes1 constant percentageBit     = bytes1(0x40);
    bytes1 constant negativeBit       = bytes1(0x20);
    bytes1 constant decimalBit        = bytes1(0x10);

    bytes1 constant numberMask        = bytes1(0x0F);

    bytes1 constant filterInIdBit     = bytes1(0x80);

    bytes1 constant filterInIdMask    = bytes1(0x7F);

    // SVG tags
    bytes constant SVG_OPEN_TAG = bytes('<?xml version="1.0" encoding="UTF-8"?><svg width="1320px" height="1760px" viewBox="0 0 1320 1760" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    bytes constant SVG_CLOSE_TAG = bytes("</svg>");

    bytes[25] TAGS = [
        bytes("g"),
        bytes("polygon"),
        bytes("path"),
        bytes("circle"),
        bytes("defs"),
        bytes("linearGradient"),
        bytes("stop"),
        bytes("rect"),
        bytes("polyline"),
        bytes("text"),
        bytes("tspan"),
        bytes("mask"),
        bytes("use"),
        bytes("ellipse"),
        bytes("radialGradient"),
        bytes("filter"),
        bytes("feColorMatrix"),
        bytes("feComposite"),
        bytes("feGaussianBlur"),
        bytes("feMorphology"),
        bytes("feOffset"),
        bytes("pattern"),
        bytes("feMergeNode"),
        bytes("feMerge"),
        bytes("INVALIDTAG")
    ];

    bytes[54] ATTRIBUTES = [
        bytes("d"),
        bytes("points"),
        bytes("transform"),
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("stroke"),
        bytes("stroke-width"),
        bytes("fill"),
        bytes("fill-opacity"),
        bytes("translate"),
        bytes("rotate"),
        bytes("scale"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("stop-color"),
        bytes("offset"),
        bytes("stop-opacity"),
        bytes("width"),
        bytes("height"),
        bytes("x"),
        bytes("y"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("opacity"),
        bytes("id"),
        bytes("xlink:href"),
        bytes("rx"),
        bytes("ry"),
        bytes("mask"),
        bytes("fx"),
        bytes("fy"),
        bytes("gradientTransform"),
        bytes("filter"),
        bytes("filterUnits"),
        bytes("result"),
        bytes("in"),
        bytes("in2"),
        bytes("type"),
        bytes("values"),
        bytes("operator"),
        bytes("k1"),
        bytes("k2"),
        bytes("k3"),
        bytes("k4"),
        bytes("stdDeviation"),
        bytes("edgeMode"),
        bytes("radius"),
        bytes("fill-rule"),
        bytes("dx"),
        bytes("dy"),
        bytes("INVALIDATTRIBUTE")
    ];

    bytes[2] PAIR_NUMBER_SET_ATTRIBUTES = [
        bytes("translate"),
        bytes("scale")
    ];

    bytes[4] PAIR_COLOR_ATTRIBUTES = [
        bytes("stroke"),
        bytes("fill"),
        bytes("stop-color"),
        bytes("mask")
    ];

    bytes[23] SINGLE_NUMBER_SET_ATTRIBUTES = [
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("rotate"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("offset"),
        bytes("x"),
        bytes("y"),
        bytes("rx"),
        bytes("ry"),
        bytes("fx"),
        bytes("fy"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("stroke-width"),
        bytes("width"),
        bytes("height"),
        bytes("fill-opacity"),
        bytes("stop-opacity"),
        bytes("opacity")
    ];

    bytes[20] D_COMMANDS = [
        bytes("M"),
        bytes("m"),
        bytes("L"),
        bytes("l"),
        bytes("H"),
        bytes("h"),
        bytes("V"),
        bytes("v"),
        bytes("C"),
        bytes("c"),
        bytes("S"),
        bytes("s"),
        bytes("Q"),
        bytes("q"),
        bytes("T"),
        bytes("t"),
        bytes("A"),
        bytes("a"),
        bytes("Z"),
        bytes("z")
    ];

    bytes[2] FILL_RULE = [
        bytes("nonzero"),
        bytes("evenodd")
    ];

    bytes[2] FILTER_UNIT = [
        bytes("userSpaceOnUse"),
        bytes("objectBoundingBox")
    ];

    bytes[6] FILTER_IN = [
        bytes("SourceGraphic"),
        bytes("SourceAlpha"),
        bytes("BackgroundImage"),
        bytes("BackgroundAlpha"),
        bytes("FillPaint"),
        bytes("StrokePaint")
    ];

    bytes[16] FILTER_TYPE = [
        bytes("translate"),
        bytes("scale"),
        bytes("rotate"),
        bytes("skewX"),
        bytes("skewY"),
        bytes("matrix"),
        bytes("saturate"),
        bytes("hueRotate"),
        bytes("luminanceToAlpha"),
        bytes("identity"),
        bytes("table"),
        bytes("discrete"),
        bytes("linear"),
        bytes("gamma"),
        bytes("fractalNoise"),
        bytes("turbulence")
    ];

    bytes[9] FILTER_OPERATOR = [
        bytes("over"),
        bytes("in"),
        bytes("out"),
        bytes("atop"),
        bytes("xor"),
        bytes("lighter"),
        bytes("arithmetic"),
        bytes("erode"),
        bytes("dilate")
    ];

    bytes[3] FILTER_EDGEMODE = [
        bytes("duplicate"),
        bytes("wrap"),
        bytes("none")
    ];


    function checkTag(bytes1 line) internal pure returns (bool) {
        return line & tagBit > 0;
    }

    function checkStartTag(bytes1 line) internal pure returns (bool) {
        return line & startTagBit > 0;
    }

    function getTag(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & tagTypeMask);

        if (key >= TAGS.length - 1) {
            return TAGS[TAGS.length - 1];
        }

        return TAGS[key];
    }

    function getAttribute(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & attributeTypeMask);

        if (key >= ATTRIBUTES.length - 1) {
            return ATTRIBUTES[ATTRIBUTES.length - 1];
        }

        return ATTRIBUTES[key];
    }

    function compareAttrib(bytes memory attrib, string memory compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(bytes(compareTo));
    }

    function compareAttrib(bytes memory attrib, bytes storage compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(compareTo);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum) internal pure returns (uint256) {
        for (uint256 _idx; _idx < _addendum.length; _idx++) {
            _output[_outputIdx++] = _addendum[_idx];
        }
        return _outputIdx;
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3, bytes memory _addendum4)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3), _addendum4);
    }

    function parse(bytes memory input, uint256 idx) public view returns (string memory, uint256) {
        return parse(input, idx, DEFAULT_THRESHOLD_COUNTER);
    }

    function parse(bytes memory input, uint256 idx, uint256 thresholdCounter) public view returns (string memory, uint256) {
        // Keep track of what we're returning
        bytes memory output = new bytes(thresholdCounter * 15); // Plenty of padding
        uint256 outputIdx = 0;

        bool isTagOpen = false;
        uint256 counter = idx;

        // Start the output with SVG tags if needed
        if (idx == 0) {
            outputIdx = addOutput(output, outputIdx, SVG_OPEN_TAG);
        }

        // Go through all bytes we want to review
        while (idx < input.length)
        {
            // Get the current byte
            bytes1 _b = bytes1(input[idx]);

            // If this is a tag, determine if we're creating a new tag
            if (checkTag(_b)) {
                // Close the current tag
                bool closeTag = false;
                if (isTagOpen) {
                    closeTag = true;
                    isTagOpen = false;

                    if ((idx - counter) >= thresholdCounter) {
                        outputIdx = addOutput(output, outputIdx, bytes(">"));
                        break;
                    }
                }

                // Start the next tag
                if (checkStartTag(_b)) {
                    isTagOpen = true;

                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("><"), getTag(_b));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("<"), getTag(_b));
                    }
                } else {
                    // If needed, open and close an end tag
                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("></"), getTag(_b), bytes(">"));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("</"), getTag(_b), bytes(">"));
                    }
                }
            }
            else
            {
                // Attributes
                bytes memory attrib = getAttribute(_b);

                if (compareAttrib(attrib, "transform") || compareAttrib(attrib, "gradientTransform")) {
                    // Keep track of which transform we're doing
                    bool isGradientTransform = compareAttrib(attrib, "gradientTransform");

                    // Get the next byte & attribute
                    idx += 2;
                    _b = bytes1(input[idx]);
                    attrib = getAttribute(_b);

                    outputIdx = addOutput(output, outputIdx, bytes(" "), isGradientTransform ? bytes('gradientTransform="') : bytes('transform="'));
                    while (compareAttrib(attrib, 'translate') || compareAttrib(attrib, 'rotate') || compareAttrib(attrib, 'scale')) {
                        outputIdx = addOutput(output, outputIdx, bytes(" "));
                        (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);

                        // Get the next byte & attribute
                        idx += 2;
                        _b = bytes1(input[idx]);
                        attrib = getAttribute(_b);
                    }

                    outputIdx = addOutput(output, outputIdx, bytes('"'));

                    // Undo the previous index increment
                    idx -= 2;
                }
                else if (compareAttrib(attrib, "d")) {
                    (idx, outputIdx) = packDPoints(output, outputIdx, input, idx);
                }
                else if (compareAttrib(attrib, "points"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' points="'));
                }
                else if (compareAttrib(attrib, "values"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' values="'));
                }
                else
                {
                    outputIdx = addOutput(output, outputIdx, bytes(" "));
                    (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);
                }
            }

            idx += 2;
        }

        if (idx >= input.length) {
            // Close out the SVG tags
            outputIdx = addOutput(output, outputIdx, SVG_CLOSE_TAG);
            idx = 0;
        }

        // Pack everything down to the size that actually fits
        bytes memory finalOutput = new bytes(outputIdx);
        for (uint256 _idx; _idx < outputIdx; _idx++) {
            finalOutput[_idx] = output[_idx];
        }

        return (string(finalOutput), idx);
    }

    function packDPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, bytes(' d="'));

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;

            // Add the d command prior to any bits
            if (uint8(input[idx + 1] & dCommandBit) > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), D_COMMANDS[uint8(input[idx])]);
            }
            else
            {
                countIdx++;
                outputIdx = addOutput(output, outputIdx, bytes(" "), parseNumberSetValues(input[idx], input[idx + 1]), bytes(","), parseNumberSetValues(input[idx + 2], input[idx + 3]));
                idx += 2;
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function packPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx, bytes memory attributePreface) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, attributePreface);

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;
            bytes memory numberSet = parseNumberSetValues(input[idx], input[idx + 1]);

            if (countIdx > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), numberSet);
            } else {
                outputIdx = addOutput(output, outputIdx, numberSet);
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function parseAttributeValues(
        bytes memory output,
        uint256 outputIdx,
        bytes memory attrib,
        bytes memory input,
        uint256 idx
    )
        internal
        view
        returns (uint256, uint256)
    {
        // Handled in main function
        if (compareAttrib(attrib, "d") || compareAttrib(attrib, "points") || compareAttrib(attrib, "values") || compareAttrib(attrib, 'transform')) {
            return (idx + 2, outputIdx);
        }

        if (compareAttrib(attrib, 'id') || compareAttrib(attrib, 'xlink:href') || compareAttrib(attrib, 'filter') || compareAttrib(attrib, 'result'))
        {
            bytes memory number = Utils.uint2bytes(
                uint256(uint8(input[idx + 2])) * 2**16 +
                uint256(uint8(input[idx + 5])) * 2**8 +
                uint256(uint8(input[idx + 4]))
            );

            if (compareAttrib(attrib, 'xlink:href')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="#id-'), number, bytes('"'));
            } else if (compareAttrib(attrib, 'filter')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="url(#id-'), number, bytes(')"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            }

            return (idx + 4, outputIdx);
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_NUMBER_SET_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_NUMBER_SET_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(','));
                outputIdx = addOutput(output, outputIdx, parseNumberSetValues(input[idx + 4], input[idx + 5]), bytes(')'));
                return (idx + 4, outputIdx);
            }
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_COLOR_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_COLOR_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseColorValues(input[idx + 2], input[idx + 3], input[idx + 4], input[idx + 5]), bytes('"'));
                return (idx + 4, outputIdx);
            }
        }

        if (compareAttrib(attrib, 'rotate')) {
            // Default, single number set values
            outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(')'));
            return (idx + 2, outputIdx);
        }

        // Dictionary lookups
        if (compareAttrib(attrib, 'in') || compareAttrib(attrib, 'in2')) {
            // Special case for the dictionary lookup for in & in2 => allow for ID lookup
            if (uint8(input[idx + 3] & filterInIdBit) > 0) {
                bytes memory number = Utils.uint2bytes(
                    uint256(uint8(input[idx + 2] & filterInIdMask)) * 2**16 +
                    uint256(uint8(input[idx + 5] & filterInIdMask)) * 2**8 +
                    uint256(uint8(input[idx + 4]))
                );

                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_IN[uint8(input[idx + 2])], bytes('"'));
            }

            return (idx + 4, outputIdx);
        } else if (compareAttrib(attrib, 'type')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_TYPE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'operator')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_OPERATOR[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'edgeMode')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_EDGEMODE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'fill-rule')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILL_RULE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'filterUnits')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_UNIT[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        }

        // Default, single number set values
        outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes('"'));
        return (idx + 2, outputIdx);
    }

    function parseColorValues(bytes1 one, bytes1 two, bytes1 three, bytes1 four) internal pure returns (bytes memory) {
        if (uint8(two) == 0xFF && uint8(one) == 0 && uint8(four) == 0 && uint8(three) == 0) {
            // None identifier case
            return bytes("none");
        }
        else if (uint8(two) == 0x80)
        {
            // URL identifier case
            bytes memory number = Utils.uint2bytes(
                uint256(uint8(one)) * 2**16 +
                uint256(uint8(four)) * 2**8 +
                uint256(uint8(three))
            );
            return abi.encodePacked("url(#id-", number, ")");
        } else {
            return Utils.unpackHexColorValues(uint8(one), uint8(four), uint8(three));
        }
    }

    function parseNumberSetValues(bytes1 one, bytes1 two) internal pure returns (bytes memory) {
        return Utils.unpackNumberSetValues(
            uint256(uint8(two & numberMask)) * 2**8 + uint256(uint8(one)), // number
            uint8(two & decimalBit) > 0, // decimal
            uint8(two & negativeBit) > 0, // negative
            uint8(two & percentageBit) > 0 // percent
        );
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
pragma solidity ^0.8.0;

library Utils {

  /**
   * From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
   **/

   function uint2bytes(uint _i) internal pure returns (bytes memory) {
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
    uint k = len - 1;
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }
    return bstr;
  }

  function unpackNumberSetValues(uint _i, bool decimal, bool negative, bool percent) internal pure returns (bytes memory) {
    // Base case
    if (_i == 0) {
      if (percent) {
        return "0%";
      } else {
        return "0";
      }
    }

    // Kick off length with the slots needed to make room for, considering certain bits
    uint j = _i;
    uint len = (negative ? 1 : 0) + (percent ? 1 : 0) + (decimal ? 2 : 0);

    // See how many tens we need
    uint numTens;
    while (j != 0) {
      numTens++;
      j /= 10;
    }

    // Expand length
    // Special case: if decimal & numTens is less than 3, need to pad by 3 since we'll left-pad zeroes
    if (decimal && numTens < 3) {
      len += 3;
    } else {
      len += numTens;
    }

    // Now create the byte "string"
    bytes memory bstr = new bytes(len);

    // Index from right-most to left-most
    uint k = len - 1;

    // Percent character
    if (percent) {
      bstr[k--] = bytes1("%");
    }

    // The entire number
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }

    // If a decimal, we need to left-pad if the numTens isn't enough
    if (decimal) {
      while (numTens < 3) {
        bstr[k--] = bytes1("0");
        numTens++;
      }
      bstr[k--] = bytes1(".");

      unchecked {
        bstr[k--] = bytes1("0");
      }
    }

    // If negative, the last byte should be negative
    if (negative) {
      bstr[0] = bytes1("-");
    }

    return bstr;
  }

  /**
   * Reference pulled from https://gist.github.com/okwme/f3a35193dc4eb9d1d0db65ccf3eb4034
   **/

  function unpackHexColorValues(uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
    bytes memory rHex = Utils.uint2hexchar(r);
    bytes memory gHex = Utils.uint2hexchar(g);
    bytes memory bHex = Utils.uint2hexchar(b);
    bytes memory bstr = new bytes(7);
    bstr[6] = bHex[1];
    bstr[5] = bHex[0];
    bstr[4] = gHex[1];
    bstr[3] = gHex[0];
    bstr[2] = rHex[1];
    bstr[1] = rHex[0];
    bstr[0] = bytes1("#");
    return bstr;
  }

  function uint2hexchar(uint8 _i) internal pure returns (bytes memory) {
    uint8 mask = 15;
    bytes memory bstr = new bytes(2);
    bstr[1] = (_i & mask) > 9 ? bytes1(uint8(55 + (_i & mask))) : bytes1(uint8(48 + (_i & mask)));
    bstr[0] = ((_i >> 4) & mask) > 9 ? bytes1(uint8(55 + ((_i >> 4) & mask))) : bytes1(uint8(48 + ((_i >> 4) & mask)));
    return bstr;
  }

}