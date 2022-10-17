// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IFarmAnimalsTraits.sol';
import './interfaces/IHenHouse.sol';
import './libs/Base64.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';

contract FarmAnimalsTraits is Ownable, IFarmAnimalsTraits, Base64 {
  using Strings for uint256;
  using SafeMath for uint256;

  event ChangeName(uint16 indexed tokenId, string newName, uint256 fee);
  event ChangeBio(uint16 indexed tokenId, string newBio, uint256 fee);
  event ChangeBackground(uint16 indexed tokenId, string newBGColor, uint256 fee);
  event UpdatedChangeNameFee(uint256 _old, uint256 _new);
  event UpdatedChangeBioFee(uint256 _old, uint256 _new);
  event UpdatedChangeBGColorFee(uint256 _old, uint256 _new);
  event InitializedContract(address thisContract);

  // Utility Token Fee to update Name, Bio & Background
  uint256 public changeNameFee = 20000 ether;
  uint256 public changeDescFee = 15000 ether;
  uint256 public changeBGColorFee = 10000 ether;

  // Mapping of traits to metadata display names
  string[3] private _characters = ['Hen', 'Coyote', 'Rooster'];

  // Mapping from advantageIndex to its score
  uint256[6] private _advantages = [5, 6, 7, 8, 9, 10];

  IFarmAnimals public farmAnimalsNFT; //reference to Farm Animals
  IEGGToken private eggToken; //reference to EGG token
  IHenHouse public henHouse; // reference to the HenHouse contract

  // Address => allowedToCallFunctions
  mapping(address => bool) public controllers;

  // FarmAnimals (Custom RLE)
  // Storage of each image data
  struct TraitImage {
    string name;
    bytes rlePNG;
  }

  // Storage of each traits name and base64 PNG data [TRAIT][TRAIT VALUE]
  mapping(uint8 => mapping(uint8 => TraitImage)) public traitRLEData;

  // Token Name & Description
  struct Meta {
    string name;
    string description;
    string bgColor;
  }

  // Mapping from tokenId to meta struct
  mapping(uint256 => Meta) metaList;

  // Common description that shows in all tokenUri
  string private metadataDescription =
    'In the metaverse, fhe farm is full of animals. Hens produce an abundance of EGG.'
    ' alongside roosters who guard them, they expand the farm and multiply their earnings. There'
    "'"
    's only one small hitch-- the Farm has cought the eyes of a new threat and Coyotes are stalking the farm.';

  /** MODIFIERS */

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  constructor(IEGGToken _eggToken) {
    eggToken = _eggToken;
    controllers[_msgSender()] = true;
    emit InitializedContract(address(this));
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  // Start RLE

  // FarmAnimals Color Palettes (Index => Hex Colors)
  mapping(uint8 => string[]) public palettes;

  /**
   * @notice Add a single color to a color palette
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
    require(bytes(_color).length == 6 || bytes(_color).length == 0, 'Wrong lenght');
    palettes[_paletteIndex].push(_color);
  }

  /**
   * @notice Add a single color to a color palette
   * @dev This function can only be called by the owner
   * @param _paletteIndex index for current color
   * @param _color 6 character hex code for color
   */
  function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyController {
    require(palettes[_paletteIndex].length + 1 <= 500, 'Palettes can only hold 256 colors');
    _addColorToPalette(_paletteIndex, _color);
  }

  /**
   * @notice Add colors to a color palette
   * @dev This function can only be called by the owner
   * @param _paletteIndex index for colors
   * @param _colors Array of 6 character hex code for colors
   */
  function addManyColorsToPalette(uint8 _paletteIndex, string[] calldata _colors) external onlyController {
    require(palettes[_paletteIndex].length + _colors.length <= 500, 'Palettes can only hold 256 colors');
    for (uint256 i = 0; i < _colors.length; i++) {
      _addColorToPalette(_paletteIndex, _colors[i]);
    }
  }

  /**
   * @notice Upload trait art to blockchain!
   * @param traitTypeId trait name id (0 corresponds to "body")
   * @param traitValueIds array trait value ids (3 corresponds to "black", e.g,. [0,1,2,3])
   * @param traitNames array of trait [name] (e.g,. ["bandana", "orange"])
   * @param traitImages array of trait [rlePng] (e.g,. [{bytes}, {bytes}])
   */
  function uploadRLETraits(
    uint8 traitTypeId,
    uint8[] calldata traitValueIds,
    string[] calldata traitNames,
    bytes[] calldata traitImages
  ) external onlyController {
    require(traitValueIds.length == traitNames.length, 'Mismatched inputs');
    for (uint8 i = 0; i < traitNames.length; i++) {
      traitRLEData[traitTypeId][traitValueIds[i]] = TraitImage(traitNames[i], traitImages[i]);
    }
  }

  // End RLE

  /**
   * @notice Get the description of the token
   * @param _tokenId the ID of the token to get description for
   * @return a string of the current description for the token
   */
  function _getTokenDesc(uint16 _tokenId) internal view returns (string memory) {
    string memory _description = metaList[_tokenId].description;
    if (bytes(_description).length == 0) {
      return '';
    } else {
      return string.concat(_description, ' - ');
    }
  }

  /**
   * @notice Get the anme of the token
   * @param _tokenId the ID of the token to get name for
   * @return a string of the current name for the token
   */
  function _getTokenName(uint16 _tokenId) internal view returns (string memory) {
    string memory _name = metaList[_tokenId].name;
    if (bytes(_name).length == 0) {
      return '';
    } else {
      return string.concat(_name, ' - ');
    }
  }

  /** DESCRIPTOR & METADATA */

  /**
   * @notice Generates an attribute for the attributes array in the ERC721 metadata standard
   * @param displayType the display_type to be used in metadata (booster_number, boost_percentage, number, or date)
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function _attributeForTypeAndStringValue(
    string memory displayType,
    string memory traitType,
    string memory value
  ) internal pure returns (string memory) {
    if (bytes(displayType).length == 0) {
      return string.concat('{"trait_type":"', traitType, '","value":"', value, '"}');
    }
    return string.concat('{"display_type":"', displayType, '","trait_type":"', traitType, '","value":"', value, '"}');
  }

  /**
   * @notice Generates an attribute for the attributes array in the ERC721 metadata standard
   * @param displayType the display_type to be used in metadata (booster_number, boost_percentage, number, or date)
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function _attributeForTypeAndIntValue(
    string memory displayType,
    string memory traitType,
    uint256 value
  ) internal pure returns (string memory) {
    if (bytes(displayType).length == 0) {
      return string.concat('{"trait_type":"', traitType, '","value":', value.toString(), '}');
    }
    return
      string.concat(
        '{"display_type":"',
        displayType,
        '","trait_type":"',
        traitType,
        '","value":',
        value.toString(),
        '}'
      );
  }

  /**
   * @notice Generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return traits JSON array of all of the attributes for given token ID
   */
  function _compileAttributes(uint16 tokenId, IFarmAnimals.Traits memory t)
    internal
    view
    returns (string memory traits)
  {
    if (t.kind == IFarmAnimals.Kind.HEN) {
      traits = string.concat(
        _attributeForTypeAndStringValue('', 'Body', traitRLEData[0][t.traits[0]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Clothes', traitRLEData[1][t.traits[1]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Beak', traitRLEData[2][t.traits[2]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Eyes', traitRLEData[3][t.traits[3]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Feet', traitRLEData[4][t.traits[4]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Head', traitRLEData[5][t.traits[5]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Mouth', traitRLEData[6][t.traits[6]].name),
        ',',
        _attributeForTypeAndIntValue('', 'Production Score', _advantages[t.advantage]),
        ','
      );
    } else if (t.kind == IFarmAnimals.Kind.COYOTE) {
      traits = string.concat(
        _attributeForTypeAndStringValue('', 'Body', traitRLEData[7][t.traits[0]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Clothes', traitRLEData[8][t.traits[1]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Ears', traitRLEData[9][t.traits[2]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Eyes', traitRLEData[10][t.traits[3]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Feet', traitRLEData[11][t.traits[4]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Head', traitRLEData[12][t.traits[5]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Mouth', traitRLEData[13][t.traits[6]].name),
        ',',
        _attributeForTypeAndIntValue('', 'Wily Score', _advantages[t.advantage]),
        ','
      );
    } else {
      // ROOSTER
      traits = string.concat(
        _attributeForTypeAndStringValue('', 'Body', traitRLEData[14][t.traits[0]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Clothes', traitRLEData[15][t.traits[1]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Beak', traitRLEData[16][t.traits[2]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Eyes', traitRLEData[17][t.traits[3]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Feet', traitRLEData[18][t.traits[4]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Head', traitRLEData[19][t.traits[5]].name),
        ',',
        _attributeForTypeAndStringValue('', 'Mouth', traitRLEData[20][t.traits[6]].name),
        ',',
        _attributeForTypeAndIntValue('', 'Guard Score', _advantages[t.advantage]),
        ','
      );
    }

    string memory _generation = Strings.toString((_getGeneration(tokenId)));
    return
      string.concat(
        '[',
        traits,
        '{"display_type": "number", "trait_type":"Generation","value":',
        _generation,
        '},{"trait_type":"Type","value":"',
        _characters[uint256(t.kind)],
        '"}]'
      );
  }

  /**
   * @notice Given a name, description, and typeId, construct a base64 encoded data URI
   */
  function _genericDataURI(
    string memory name,
    string memory description,
    uint16 tokenId
  ) internal view returns (string memory) {
    IFarmAnimals.Traits memory traits = farmAnimalsNFT.getTokenTraits(tokenId);
    NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
      name: name,
      description: description,
      background: getTokenBGColor(tokenId),
      elements: _getElementsForTraits(traits),
      attributes: _compileAttributes(tokenId, traits),
      advantage: _advantages[traits.advantage],
      width: uint8(48),
      height: uint8(48)
    });
    return NFTDescriptor.constructTokenURI(params, palettes);
  }

  /**
   * @notice Get all TheFarm elements for the passed `seed`.
   * @param t Traits of the token
   */

  function _getElementsForTraits(IFarmAnimals.Traits memory t) internal view returns (bytes[] memory) {
    bytes[] memory _elements = new bytes[](7);
    if (t.kind == IFarmAnimals.Kind.HEN) {
      _elements[0] = traitRLEData[0][t.traits[0]].rlePNG; // Body
      _elements[1] = traitRLEData[1][t.traits[1]].rlePNG; // Clothes
      _elements[2] = traitRLEData[2][t.traits[2]].rlePNG; // Beak
      _elements[3] = traitRLEData[3][t.traits[3]].rlePNG; // Eyes
      _elements[4] = traitRLEData[4][t.traits[4]].rlePNG; // Feet
      _elements[5] = traitRLEData[5][t.traits[5]].rlePNG; // Head
      _elements[6] = traitRLEData[6][t.traits[6]].rlePNG; // Mouth
    } else if (t.kind == IFarmAnimals.Kind.COYOTE) {
      _elements[0] = traitRLEData[7][t.traits[0]].rlePNG; // Body
      _elements[1] = traitRLEData[8][t.traits[1]].rlePNG; // Clothes
      _elements[2] = traitRLEData[9][t.traits[2]].rlePNG; // Null (Fake Ears)
      _elements[3] = traitRLEData[10][t.traits[3]].rlePNG; // Eyes
      _elements[4] = traitRLEData[11][t.traits[4]].rlePNG; // Feet
      _elements[5] = traitRLEData[12][t.traits[5]].rlePNG; // Head
      _elements[6] = traitRLEData[13][t.traits[6]].rlePNG; // Mouth
    } else {
      // ROOSTER
      _elements[0] = traitRLEData[14][t.traits[0]].rlePNG; // Body
      _elements[1] = traitRLEData[15][t.traits[1]].rlePNG; // Clothes
      _elements[2] = traitRLEData[16][t.traits[2]].rlePNG; // Beak
      _elements[3] = traitRLEData[17][t.traits[3]].rlePNG; // Eyes
      _elements[4] = traitRLEData[18][t.traits[4]].rlePNG; // Feet
      _elements[5] = traitRLEData[19][t.traits[5]].rlePNG; // Head
      _elements[6] = traitRLEData[20][t.traits[6]].rlePNG; // Mouth
    }
    return _elements;
  }

  /**
   * @notice get the generation of tokenId: 0 = GEN 0, 1 = GEN 1...
   * @param tokenId Token ID of toke to get traits for
   */

  function _getGeneration(uint256 tokenId) internal view returns (uint16 gen) {
    uint256 maxGen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    uint256 gAmount = (maxSupply.sub(maxGen0Supply)).div(5);
    if (tokenId <= maxGen0Supply) return 0; // GEN 0
    if (tokenId <= (gAmount + maxGen0Supply)) return 1; // GEN 1
    if (tokenId <= (gAmount * 2) + maxGen0Supply) return 2; // GEN 2
    if (tokenId <= (gAmount * 3) + maxGen0Supply) return 3; // GEN 3
    if (tokenId <= (gAmount * 4) + maxGen0Supply) return 4; // GEN 4
    return 5; // GEN 5
  }

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint16 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Change the name of a the token
   * @param tokenId the ID of the token to change name for
   * @param name a string to set for the name of the current token
   */

  function changeName(uint16 tokenId, string memory name) external {
    require(
      farmAnimalsNFT.ownerOf(tokenId) == tx.origin || controllers[_msgSender()],
      'Caller not owner or controller'
    );
    require(bytes(name).length < 16, 'Should be no greater than 15 chars');

    IFarmAnimals.Kind kind = _getKind(tokenId);

    if (kind == IFarmAnimals.Kind.HEN || kind == IFarmAnimals.Kind.COYOTE) {
      uint256 rescuedAmount = changeNameFee.mul(30).div(100);
      henHouse.addRescuedEggPool(rescuedAmount);
    }
    eggToken.burn(_msgSender(), changeNameFee);
    emit ChangeName(tokenId, name, changeNameFee);

    Meta storage _meta = metaList[tokenId];
    _meta.name = name;
  }

  /**
   * @notice Change the description of a the token
   * @param tokenId the ID of the token to change description for
   * @param desc a string to set for the description of the current token
   */

  function changeDesc(uint16 tokenId, string memory desc) external {
    require(
      farmAnimalsNFT.ownerOf(tokenId) == tx.origin || controllers[_msgSender()],
      'Caller not owner or controller'
    );
    require(bytes(desc).length < 33, 'Should be no greater than 32 chars');

    IFarmAnimals.Kind kind = _getKind(tokenId);

    if (kind == IFarmAnimals.Kind.HEN || kind == IFarmAnimals.Kind.COYOTE) {
      uint256 rescuedAmount = changeDescFee.mul(30).div(100);
      henHouse.addRescuedEggPool(rescuedAmount);
    }
    eggToken.burn(_msgSender(), changeDescFee);
    emit ChangeBio(tokenId, desc, changeDescFee);

    Meta storage _meta = metaList[tokenId];
    _meta.description = desc;
  }

  /**
   * @notice Change the background color of a the token. Use "------" to make transparent
   * @param tokenId the ID of the token to change background color for
   * @param bgColor the HEX color code without '#'
   */

  function changeBGColor(uint16 tokenId, string memory bgColor) external {
    require(
      farmAnimalsNFT.ownerOf(tokenId) == tx.origin || controllers[_msgSender()],
      'Caller not owner or controller'
    );
    require(bytes(bgColor).length == 6, 'Must be exactly 6 chars');

    IFarmAnimals.Kind kind = _getKind(tokenId);

    if (kind == IFarmAnimals.Kind.HEN || kind == IFarmAnimals.Kind.COYOTE) {
      uint256 rescuedAmount = changeBGColorFee.mul(30).div(100);
      henHouse.addRescuedEggPool(rescuedAmount);
    }
    eggToken.burn(_msgSender(), changeBGColorFee);
    emit ChangeBackground(tokenId, bgColor, changeBGColorFee);

    Meta storage _meta = metaList[tokenId];
    _meta.bgColor = bgColor;
  }

  /**
   * @notice Get the background color of the token
   * @param tokenId the ID of the token to get background color for
   * @return a string of the HEX color
   */
  function getTokenBGColor(uint16 tokenId) public view returns (string memory) {
    string memory _bgColor = metaList[tokenId].bgColor;
    if (bytes(_bgColor).length == 0) {
      return '------';
    } else {
      return metaList[tokenId].bgColor;
    }
  }

  function _getTokenNameText(uint16 tokenId, IFarmAnimals.Traits memory t) internal view returns (string memory name) {
    return name = string.concat(_getTokenName(tokenId), _characters[uint8(t.kind)], ' #', uint256(tokenId).toString());
  }

  // Start RLE

  /**
   * @notice ERC720 token URI interface. Generates a base64 encoded metadata response without referencing off-chain content.
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */

  function tokenURI(uint16 tokenId) public view returns (string memory) {
    IFarmAnimals.Traits memory traits = farmAnimalsNFT.getTokenTraits(tokenId);
    string memory name = string(abi.encodePacked(_getTokenNameText(tokenId, traits)));
    string memory description = string.concat(_getTokenDesc(tokenId), metadataDescription);

    return _genericDataURI(name, description, tokenId);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Set changeNameFee amount
   * @param _fee Fee amount in wei
   */
  function setChangeNameFee(uint256 _fee) external onlyController {
    uint256 oldFee = changeNameFee;
    changeNameFee = _fee;
    emit UpdatedChangeNameFee(oldFee, changeNameFee);
  }

  /**
   * @notice Set changeDescFee amount
   * @dev Only callable by the controller
   * @param _fee Fee amount in wei
   */
  function setChangeBioFee(uint256 _fee) external onlyController {
    uint256 oldFee = changeDescFee;
    changeDescFee = _fee;
    emit UpdatedChangeBioFee(oldFee, changeDescFee);
  }

  /**
   * @notice Set setChangeBackgroundColorFee amount
   * @dev Only callable by the controller
   * @param _fee Fee amount in wei
   */
  function setChangeBGColorFee(uint256 _fee) external onlyController {
    uint256 oldFee = changeBGColorFee;
    changeBGColorFee = _fee;
    emit UpdatedChangeBGColorFee(oldFee, changeBGColorFee);
  }

  /**
   * @notice Set the farmAnimals contract address
   * @dev Only callable by the controller
   * @param _farmAnimalsNFT Address of Farm Animals contract
   */

  function setFarmAnimals(address _farmAnimalsNFT) external onlyController {
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
  }

  /**
   * @notice Set the henHouse contract address
   * @dev Only callable by the controller
   * @param _address Address of Hen House contract
   */
  function setHenHouse(address _address) external onlyController {
    henHouse = IHenHouse(_address);
  }

  /**
   * @notice Update the metadata description
   * @dev Only callable by the controller
   * @param _desc New description
   */

  function updateMetaDesc(string memory _desc) external onlyController {
    metadataDescription = _desc;
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint16 tokenId) external;

  function maxGen0Supply() external view returns (uint16);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint16 tokenId) external view returns (Traits memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function mint(address recipient, uint256 seed) external returns (uint16[] memory);

  function minted() external view returns (uint16);

  function mintedRoosters() external returns (uint16);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function updateAdvantage(
    uint16 tokenId,
    uint8 score,
    bool decrement
  ) external;

  function updateOriginAccess(uint16[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IFarmAnimalsTraits {
  function tokenURI(uint16 tokenId) external view returns (string memory);

  function changeName(uint16 tokenId, string memory name) external;

  function changeDesc(uint16 tokenId, string memory desc) external;

  function changeBGColor(uint16 tokenId, string memory BGColor) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint16 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Base64 {
  /** BASE 64 - Written by Brech Devos */

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
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }
    return result;
  }
}

// SPDX-License-Identifier: MIT

/// @title A library used to construct ERC721 token URIs and SVG images

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
  struct TokenURIParams {
    string name;
    string description;
    string background;
    bytes[] elements;
    string attributes;
    uint256 advantage;
    uint8 width;
    uint8 height;
  }

  /**
   * @notice Construct an ERC721 token URI.
   */
  function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory)
  {
    string memory image = generateSVGImage(
      MultiPartRLEToSVG.SVGParams({
        background: params.background,
        elements: params.elements,
        advantage: params.advantage,
        width: uint256(params.width),
        height: uint256(params.height)
      }),
      palettes
    );

    string memory attributesJson;

    if (bytes(params.attributes).length > 0) {
      attributesJson = string.concat(' "attributes":', params.attributes, ',');
    } else {
      attributesJson = string.concat('');
    }

    // prettier-ignore
    return string.concat(
			'data:application/json;base64,',
			Base64.encode(
				bytes(
					string.concat('{"name":"', params.name, '",',
					' "description":"', params.description, '",',
					attributesJson,
					' "image": "', 'data:image/svg+xml;base64,', image, '"}')
				)
			)
    );
  }

  /**
   * @notice Generate an SVG image for use in the ERC721 token URI.
   */
  function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory svg)
  {
    return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

/// @title A library used to convert multi-part RLE compressed images to SVG

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

/*
Adopted from Nouns.wtf source code
Modification allow for 48x48 pixel & 32x32 RLE images & using string.concat
*/

pragma solidity ^0.8.17;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library MultiPartRLEToSVG {
  using Strings for uint256;
  struct SVGParams {
    string background;
    bytes[] elements;
    uint256 advantage;
    uint256 width;
    uint256 height;
  }

  struct ContentBounds {
    uint8 top;
    uint8 right;
    uint8 bottom;
    uint8 left;
  }

  struct Rect {
    uint8 length;
    uint8 colorIndex;
  }

  struct DecodedImage {
    uint8 paletteIndex;
    ContentBounds bounds;
    Rect[] rects;
  }

  /**
   * @notice Given RLE image elements and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    internal
    view
    returns (string memory svg)
  {
    string memory width = (params.width * 10).toString();
    string memory height = (params.width * 10).toString();
    string memory _background = '';
    if (keccak256(abi.encodePacked(params.background)) != keccak256(abi.encodePacked('------'))) {
      _background = string.concat('<rect width="100%" height="100%" fill="#', params.background, '" />');
    }
    return
      string.concat(
        '<svg width="',
        width,
        '" height="',
        height,
        '"',
        ' viewBox="0 0 ',
        width,
        ' ',
        height,
        '"',
        ' xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
        _background,
        _generateSVGRects(params, palettes),
        '</svg>'
      );
  }

  /**
   * @notice Given RLE image elements and color palettes, generate SVG rects.
   */
  // prettier-ignore
  function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
			private
			view
			returns (string memory svg)
    {
			string[49] memory lookup;

			// This is a lookup table that enables very cheap int to string
			// conversions when operating on a set of predefined integers.
			// This is used below to convert the integer length of each rectangle
			// in a 32x32 pixel grid to the string representation of the length
			// in a 320x320 pixel grid.
			// For example: A length of 3 gets mapped to '30'.
			// This lookup can be used for up to a 48x48 pixel grid
				lookup = [
					'0', '10', '20', '30', '40', '50', '60', '70',
					'80', '90', '100', '110', '120', '130', '140', '150',
					'160', '170', '180', '190', '200', '210', '220', '230',
					'240', '250', '260', '270', '280', '290', '300', '310',
					'320', '330', '340', '350', '360', '370', '380', '390',
					'400', '410', '420', '430', '440', '450', '460', '470',
					'480'
        ];

			// The string of SVG rectangles
			string memory rects;
			// Loop through all element create svg rects
			uint256 elementSize = 0;
			for (uint8 p = 0; p < params.elements.length; p++) {
				elementSize = elementSize + params.elements[p].length;

				// Convert the element data into a format that's easier to consume
    		// than a byte array.
				DecodedImage memory image = _decodeRLEImage(params.elements[p]);

				// Get the color palette used by the current element (`params.elements[p]`)
				string[] storage palette = palettes[image.paletteIndex];

				// These are the x and y coordinates of the rect that's currently being drawn.
    		// We start at the top-left of the pixel grid when drawing a new element.

				uint256 currentX = image.bounds.left;
				uint256 currentY = image.bounds.top;

				// The `cursor` and `buffer` are used here as a gas-saving technique.
				// We load enough data into a string array to draw four rectangles.
				// Once the string array is full, we call `_getChunk`, which writes the
				// four rectangles to a `chunk` variable before concatenating them with the
				// existing element string. If there is remaining, unwritten data inside the
				// `buffer` after we exit the rect loop, it will be written before the
				// element rectangles are merged with the existing element data.
				// This saves gas by reducing the size of the strings we're concatenating
				// during most loops.
				uint256 cursor;
				string[16] memory buffer;

				// The element rectangles
				string memory element;
				for (uint256 i = 0; i < image.rects.length; i++) {
					Rect memory rect = image.rects[i];
					// Skip fully transparent rectangles. Transparent rectangles
					// always have a color index of 0.
					if (rect.colorIndex != 0) {
							// Load the rectangle data into the buffer
							buffer[cursor] = lookup[rect.length];          // width
							buffer[cursor + 1] = lookup[currentX];         // x
							buffer[cursor + 2] = lookup[currentY];         // y
							buffer[cursor + 3] = palette[rect.colorIndex]; // color

							cursor += 4;

							if (cursor >= 16) {
								// Write the rectangles from the buffer to a string
								// and concatenate with the existing element string.
								element = string.concat(element, _getChunk(cursor, buffer));
								cursor = 0;
							}
					}

					// Move the x coordinate `rect.length` pixels to the right
					currentX += rect.length;

					// If the right bound has been reached, reset the x coordinate
					// to the left bound and shift the y coordinate down one row.
					if (currentX == image.bounds.right) {
							currentX = image.bounds.left;
							currentY++;
					}
				}

				// If there are unwritten rectangles in the buffer, write them to a
   			// `chunk` and concatenate with the existing element data.
				if (cursor != 0) {
					element = string.concat(element, _getChunk(cursor, buffer));
				}

				// Concatenate the element with all previous elements
				rects = string.concat(rects, element);

			}
			return rects;
    }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  // prettier-ignore
  function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
		string memory chunk;
		for (uint256 i = 0; i < cursor; i += 4) {
			chunk = string.concat(
					chunk,
					'<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
			);
		}
		return chunk;
  }

  /**
   * @notice Decode a single RLE compressed image into a `DecodedImage`.
   */
  function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    uint8 paletteIndex = uint8(image[0]);
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });

    uint256 cursor;

    // why is it length - 5? and why divide by 2?
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);
    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
      cursor++;
    }
    return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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