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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

/**
                                                                                               
                                       THE DECENTRALISTS                                       
                                                                                               
                                ·.::::iiiiiiiiiiiiiiiiiii::::.·                                
                           .:::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii::.·                          
                       .::iiiiiiiii:::::..···      ··..:::::iiiiiiiiii::·                      
                   .::iiiiiii:::.·                            .:::iiiiiii::.                   
                .:iiiiiii::                                         .:iiiiiii:.                
             ·:iiiiii::·                                                ::iiiiii:·             
            :iiiiii:·                 ·.::::::::::::::..                   :iiiiii:·           
          :iiiii::               .:::iiiii:::::::::::iiiii:::.               .:iiiii:·         
        :iiiii:·            ·::iii:::·                   .:::iii::·             :iiiii:·       
      ·iiiii:·            ::iii:·                             .::ii::            ·:iiiii:      
     :iiiii:           ·:ii::·                                   ·:iii:·           .iiiii:     
    :iiiii·          ·:ii:.                                         ·:ii:           ·:iiii:    
   :iiii:          ·:ii:              ·.:::::::i:::::::.·             ·:ii:           :iiiii   
  :iiii:          ·iii:            .::iiiiiiiiiiiiiiiiii:::·            .ii:           .iiii:  
 ·iiiii          ·iii            .:ii:::::::iiiiiiiiiiiiiii::.           ·:i:·          :iiii: 
 :iiii:         ·:i:·          .:iii:      .:iiiiiiiiiiiiiiiii:.           iii           iiiii 
:iiii:          :ii           :iiiii:·     ::iiiiiiiiiiiiiiiiiii:          ·ii:          :iiii:
iiiii·         ·ii:          ::iiiiii::::::iiiiiiiiiiiiiiiiiiiiii.          :ii.         ·iiiii
iiiii          :ii           :iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:·         .ii:          :iiii
iiiii          :ii          .iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii.          ii:          :iiii
iiiii          :ii          .iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:.          ii:          :iiii
iiiii          :ii           :iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:·         .ii:          :iiii
iiiii·         ·ii:          ::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:.          :ii.         ·iiiii
:iiii:          :ii           .:iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:          ·ii:          :iiii:
 :iiii:         ·:i:·          ·::iiiiiiiiiiiiiiiiiiiiiiiiiiii:·           ii:           iiiii 
 ·iiiii           iii·           ·::iiiiiiiiiiiiiiiiiiiiiii::.           .ii:·          :iiii: 
  :iiii:           iii:            ·:::iiiiiiiiiiiiiiiii:::·            :ii:           .iiii:  
   :iiii:           :ii:·              .::::::::::::::..              .:ii:           :iiii:   
    :iiiii·           :iii:                                         .:ii:           ·:iiii:    
     :iiiii:            :iii:·                                   .:iii:·           .iiiii:     
      ·iiiii:·            .:iii:.·                            ::iii::            ·:iiiii:      
        :iiiii:·             .:iiii::.·                 ·:::iiii:.              :iiiii:·       
          :iiiii::               ·:::iiiiiii:::::::iiiiiii:::·               .:iiiii:·         
            :iiiiii:·                   ..:::::::::::..·                   :iiiiii:·           
             ·:iiiiii::·                                                ::iiiiii:·             
                .:iiiiiii::                                         .:iiiiiii:.                
                   .::iiiiiii:::.·                            .:::iiiiiii::.                   
                       .::iiiiiiiii:::::..···      ··..:::::iiiiiiiiii::·                      
                           .:::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii::.·                          
                                ·.::::iiiiiiiiiiiiiiiiiii::::.·                                


A Decentralist is represented by a set of eight traits:
  0 - Base
    [0] Human Male Black       [8] Vampire Male       [10] Metahuman Male       [12] Ape Male
    [1] Human Female Black     [9] Vampire Female     [11] Metahuman Female
    [2] Human Male Dark
    [3] Human Female Dark
    [4] Human Male Pale
    [5] Human Female Pale
    [6] Human Male White
    [7] Human Female White
  1 - Necklace
    [0] None        [2] Golden
    [1] Diamond     [3] Silver
  2 - Facial Male
    [0] None             [10] Long Gray           [20] Sideburns Blonde
    [1] Chivo Black      [11] Long Red            [21] Sideburns Brown
    [2] Chivo Blonde     [12] Long White          [22] Sideburns Gray
    [3] Chivo Brown      [13] Regular Black       [23] Sideburns Red
    [4] Chivo Gray       [14] Regular Blonde      [24] Sideburns White
    [5] Chivo Red        [15] Regular Brown
    [6] Chivo White      [16] Regular Gray
    [7] Long Black       [17] Regular Red
    [8] Long Blonde      [18] Regular White
    [9] Long Brown       [19] Sideburns Black
  2 - Facial Female
    [0]  None
  3 - Earring
    [0]  None      [2]  Diamond     [4]  Silver
    [1]  Cross     [3]  Golden
  4 - Head Male
    [0] None                [10] CapFront Red     [20] Punky Brown      [30] Short White
    [1] Afro                [11] Hat Black        [21] Punky Gray       [31] Trapper
    [2] CapUp Green         [12] Long Black       [22] Punky Purple     [32] Wool Blue
    [3] CapUp Red           [13] Long Blonde      [23] Punky Red        [33] Wool Green
    [4] Kangaroo Black      [14] Long Brown       [24] Punky White      [34] Wool Red
    [5] CapBack Blue        [15] Long Gray        [25] Short Black
    [6] CapBack Orange      [16] Long Red         [26] Short Blonde
    [7] Conspiracist        [17] Long White       [27] Short Brown
    [8] Cop                 [18] Punky Black      [28] Short Gray
    [9] CapFront Purple     [19] Punky Blonde     [29] Short Red
  4 - Head Female
    [0] None                [10] CapFront Red     [20] Punky Brown      [30] Short White           [40] Trapper
    [1] Afro                [11] Hat Black        [21] Punky Gray       [31] Straight Black        [41] Wool Blue
    [2] CapUp Green         [12] Long Black       [22] Punky Purple     [32] Straight Blonde       [42] Wool Green
    [3] CapUp Red           [13] Long Blonde      [23] Punky Red        [33] Straight Brown        [43] Wool Red
    [4] Kangaroo Black      [14] Long Brown       [24] Punky White      [34] Straight Gray
    [5] CapBack Blue        [15] Long Gray        [25] Short Black      [35] Straight Orange
    [6] CapBack Orange      [16] Long Red         [26] Short Blonde     [36] Straight Platinum
    [7] Conspiracist        [17] Long White       [27] Short Brown      [37] Straight Purple
    [8] Cop                 [18] Punky Black      [28] Short Gray       [38] Straight Red
    [9] CapFront Purple     [19] Punky Blonde     [29] Short Red        [39] Straight White
  5 - Glasses
    [0] None       [2] Nerd      [4] Pilot     [6] VR
    [1] Beetle     [3] Patch     [5] Surf
  6 - Lipstick Male
    [0] None
  6 - Lipstick Female
    [0] None      [2] Orange     [4] Purple
    [1] Green     [3] Pink       [5] Red
  7 - Smoking
    [0] None      [2] Cigarette
    [1] Cigar     [3] E-Cigarette

 */

pragma solidity 0.8.10;

import {Ownable} from '../openzeppelin/Ownable.sol';
import {Strings} from '../openzeppelin/Strings.sol';
import {Base64} from '../utils/Base64.sol';
import {IDescriptor} from './IDescriptor.sol';
import {ITokenIdResolver} from './ITokenIdResolver.sol';
import {LibSvg} from './LibSvg.sol';

contract DecentralistsDescriptor is Ownable, IDescriptor {
  // SVG Types
  bytes32 private constant SVG_TYPE_BASE = 'BASE'; // 0x4241534500000000000000000000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_NECKLACE_MALE = 'NECKLACE_MALE'; // 	0x4e45434b4c4143455f4d414c4500000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_NECKLACE_FEMALE = 'NECKLACE_FEMALE'; // 	0x4e45434b4c4143455f46454d414c450000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_FACIAL_MALE = 'FACIAL_MALE'; // 	0x46414349414c5f4d414c45000000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_FACIAL_FEMALE = 'FACIAL_FEMALE'; // 	0x46414349414c5f46454d414c4500000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_EARRING_MALE = 'EARRING_MALE'; // 	0x45415252494e475f4d414c450000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_EARRING_FEMALE = 'EARRING_FEMALE'; // 	0x45415252494e475f46454d414c45000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_HEAD_MALE = 'HEAD_MALE'; // 	0x484541445f4d414c450000000000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_HEAD_FEMALE = 'HEAD_FEMALE'; // 	0x484541445f46454d414c45000000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_GLASSES_MALE = 'GLASSES_MALE'; // 	0x474c41535345535f4d414c450000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_GLASSES_FEMALE = 'GLASSES_FEMALE'; // 	0x474c41535345535f46454d414c45000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_LIPSTICK_MALE = 'LIPSTICK_MALE'; // 	0x4c4950535449434b5f4d414c4500000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_LIPSTICK_FEMALE = 'LIPSTICK_FEMALE'; // 	0x4c4950535449434b5f46454d414c450000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_SMOKING_MALE = 'SMOKING_MALE'; // 	0x534d4f4b494e475f4d414c450000000000000000000000000000000000000000
  bytes32 private constant SVG_TYPE_SMOKING_FEMALE = 'SMOKING_FEMALE'; // 	0x534d4f4b494e475f46454d414c45000000000000000000000000000000000000

  // Set of traits
  string[] private TRAIT_BASE = [
    'Human Male Black',
    'Human Female Black',
    'Human Male Dark',
    'Human Female Dark',
    'Human Male Pale',
    'Human Female Pale',
    'Human Male White',
    'Human Female White',
    'Vampire Male',
    'Vampire Female',
    'Metahuman Male',
    'Metahuman Female',
    'Ape Male'
  ];
  string[] private TRAIT_NECKLACE = ['None', 'Diamond', 'Golden', 'Silver'];
  string[] private TRAIT_FACIAL_MALE = [
    'None',
    'Chivo Black',
    'Chivo Blonde',
    'Chivo Brown',
    'Chivo Gray',
    'Chivo Red',
    'Chivo White',
    'Long Black',
    'Long Blonde',
    'Long Brown',
    'Long Gray',
    'Long Red',
    'Long White',
    'Regular Black',
    'Regular Blonde',
    'Regular Brown',
    'Regular Gray',
    'Regular Red',
    'Regular White',
    'Sideburns Black',
    'Sideburns Blonde',
    'Sideburns Brown',
    'Sideburns Gray',
    'Sideburns Red',
    'Sideburns White'
  ];
  string[] private TRAIT_FACIAL_FEMALE = ['None'];
  string[] private TRAIT_EARRING = ['None', 'Cross', 'Diamond', 'Golden', 'Silver'];
  string[] private TRAIT_HEAD_MALE = [
    'None',
    'Afro',
    'CapUp Green',
    'CapUp Red',
    'Kangaroo Black',
    'CapBack Blue',
    'CapBack Orange',
    'Conspiracist',
    'Cop',
    'CapFront Purple',
    'CapFront Red',
    'Hat Black',
    'Long Black',
    'Long Blonde',
    'Long Brown',
    'Long Gray',
    'Long Red',
    'Long White',
    'Punky Black',
    'Punky Blonde',
    'Punky Brown',
    'Punky Gray',
    'Punky Purple',
    'Punky Red',
    'Punky White',
    'Short Black',
    'Short Blonde',
    'Short Brown',
    'Short Gray',
    'Short Red',
    'Short White',
    'Trapper',
    'Wool Blue',
    'Wool Green',
    'Wool Red'
  ];
  string[] private TRAIT_HEAD_FEMALE = [
    'None',
    'Afro',
    'CapUp Green',
    'CapUp Red',
    'Kangaroo Black',
    'CapBack Blue',
    'CapBack Orange',
    'Conspiracist',
    'Cop',
    'CapFront Purple',
    'CapFront Red',
    'Hat Black',
    'Long Black',
    'Long Blonde',
    'Long Brown',
    'Long Gray',
    'Long Red',
    'Long White',
    'Punky Black',
    'Punky Blonde',
    'Punky Brown',
    'Punky Gray',
    'Punky Purple',
    'Punky Red',
    'Punky White',
    'Short Black',
    'Short Blonde',
    'Short Brown',
    'Short Gray',
    'Short Red',
    'Short White',
    'Straight Black',
    'Straight Blonde',
    'Straight Brown',
    'Straight Gray',
    'Straight Orange',
    'Straight Platinum',
    'Straight Purple',
    'Straight Red',
    'Straight White',
    'Trapper',
    'Wool Blue',
    'Wool Green',
    'Wool Red'
  ];
  string[] private TRAIT_GLASSES = ['None', 'Beetle', 'Nerd', 'Patch', 'Pilot', 'Surf', 'VR'];
  string[] private TRAIT_LIPSTICK_MALE = ['None'];
  string[] private TRAIT_LIPSTICK_FEMALE = ['None', 'Green', 'Orange', 'Pink', 'Purple', 'Red'];
  string[] private TRAIT_SMOKING = ['None', 'Cigar', 'Cigarette', 'E-Cigarette'];

  // Store of SVG layers
  mapping(bytes32 => LibSvg.SvgLayer[]) private svgLayers;

  // TokenId Resolver, used to get corresponding tokenId of a set of traits
  ITokenIdResolver public tokenIdResolver;

  /**
   * @dev Constructor
   * @param tokenIdResolver_ address of the contract resolver of token ids
   */
  constructor(address tokenIdResolver_) {
    tokenIdResolver = ITokenIdResolver(tokenIdResolver_);
  }

  /**
   * @notice Returns the amount of stored SVGs of a given type
   * @param svgType type of SVG
   * @return amount of stored SVGs
   */
  function getSizeOfSvgType(bytes32 svgType) external view returns (uint256) {
    return svgLayers[svgType].length;
  }

  /**
   * @notice Returns a SVG of a given type and id
   * @param svgType type of SVG
   * @param id id of SVG
   * @return SVG
   */
  function getSvg(bytes32 svgType, uint256 id) public view returns (bytes memory) {
    return LibSvg._getSvg(svgLayers[svgType], id);
  }

  /**
   * @notice Store a set of SVGs with the given types and sizes
   * @dev Only callable by owner
   * @param svgs set of SVGs
   * @param typesAndSizes array of types and sizes of the SVGs
   */
  function storeSvg(string calldata svgs, LibSvg.SvgTypeAndSizes[] calldata typesAndSizes)
    external
    onlyOwner
  {
    LibSvg._storeSvg(svgLayers, svgs, typesAndSizes);
  }

  /**
   * @notice Update a set of SVGs with the given types, ids and sizes
   * @dev Only callable by owner
   * @param svgs set of SVGs
   * @param typesAndIdsAndSizes array of types, ids and sizes of the SVGs
   */
  function updateSvg(
    string calldata svgs,
    LibSvg.SvgTypeAndIdsAndSizes[] calldata typesAndIdsAndSizes
  ) external onlyOwner {
    LibSvg._updateSvg(svgLayers, svgs, typesAndIdsAndSizes);
  }

  /**
   * @notice Returns the Uniform Resource Identifier (URI) given a set of traits
   * @param traits set of traits
   * @return token uri
   */
  function tokenURI(uint256[8] calldata traits) external view override returns (string memory) {
    uint256 tokenId = tokenIdResolver.getTokenId(traits);
    string memory traitsString = _buildAttributes(
      _traitsToAttributesString(traits),
      _getBreedAndSexString(traits[0])
    );
    string memory svg = _buildSvg(traits);
    return _buildTokenURI(tokenId, traitsString, svg);
  }

  /**
   * @notice Returns a base64 SVG given a set of traits
   * @param traits set of traits
   * @return SVG in base64 format
   */
  function _buildSvg(uint256[8] calldata traits) internal view returns (string memory) {
    bytes memory linesRendered;

    if (traits[0] % 2 == 0) {
      linesRendered = abi.encodePacked(
        getSvg(SVG_TYPE_BASE, traits[0]),
        getSvg(SVG_TYPE_NECKLACE_MALE, traits[1]),
        getSvg(SVG_TYPE_FACIAL_MALE, traits[2]),
        getSvg(SVG_TYPE_HEAD_MALE, traits[4]),
        getSvg(SVG_TYPE_EARRING_MALE, traits[3]),
        getSvg(SVG_TYPE_GLASSES_MALE, traits[5]),
        getSvg(SVG_TYPE_LIPSTICK_MALE, traits[6]),
        getSvg(SVG_TYPE_SMOKING_MALE, traits[7])
      );
    } else {
      linesRendered = abi.encodePacked(
        getSvg(SVG_TYPE_BASE, traits[0]),
        getSvg(SVG_TYPE_NECKLACE_FEMALE, traits[1]),
        getSvg(SVG_TYPE_FACIAL_FEMALE, traits[2]),
        getSvg(SVG_TYPE_HEAD_FEMALE, traits[4]),
        getSvg(SVG_TYPE_EARRING_FEMALE, traits[3]),
        getSvg(SVG_TYPE_GLASSES_FEMALE, traits[5]),
        getSvg(SVG_TYPE_LIPSTICK_FEMALE, traits[6]),
        getSvg(SVG_TYPE_SMOKING_FEMALE, traits[7])
      );
    }

    return
      Base64.encode(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" viewBox="0 -0.5 24 24" shape-rendering="crispEdges">',
          string(linesRendered),
          '</svg>'
        )
      );
  }

  /**
   * @notice Returns a stringify json of attributes given a set of attributes
   * @param attributes string array of attributes
   * @param breedAndSex breed and sex string
   * @return stringify json of attributes
   */
  function _buildAttributes(string[] memory attributes, string memory breedAndSex)
    internal
    pure
    returns (string memory)
  {
    string memory firstPart = string(
      abi.encodePacked(
        '"attributes":[{"trait_type":"Tier","value":"',
        attributes[0],
        '"},{"trait_type":"Sex","value":"',
        attributes[1],
        '"},{"trait_type":"Base","value":"',
        attributes[2],
        '"},{"trait_type":"Necklace","value":"',
        attributes[3],
        breedAndSex,
        '"},{"trait_type":"Facial","value":"',
        attributes[4],
        breedAndSex,
        '"},{"trait_type":"Earring","value":"',
        attributes[5]
      )
    );
    string memory secondPart = string(
      abi.encodePacked(
        breedAndSex,
        '"},{"trait_type":"Head","value":"',
        attributes[6],
        breedAndSex,
        '"},{"trait_type":"Glasses","value":"',
        attributes[7],
        breedAndSex,
        '"},{"trait_type":"Lipstick","value":"',
        attributes[8],
        breedAndSex,
        '"},{"trait_type":"Smoking","value":"',
        attributes[9],
        breedAndSex,
        '"}]'
      )
    );

    return string(abi.encodePacked(firstPart, secondPart));
  }

  /**
   * @notice Returns the token uri
   * @param tokenId id of the token
   * @param traits string array of traits
   * @param imageSVG SVG
   * @return token uri in base64
   */
  function _buildTokenURI(
    uint256 tokenId,
    string memory traits,
    string memory imageSVG
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"Decentralist #',
                Strings.toString(tokenId),
                '","description":"Decentralists is the collection for those who believe in the revolutionary power of crypto technology. Each one represents a customizable and unique combination stored 100% in the Ethereum blockchain.",',
                traits,
                ',"background_color":"12223B","image":"',
                'data:image/svg+xml;base64,',
                imageSVG,
                '"}'
              )
            )
          )
        )
      );
  }

  /**
   * @notice Returns the array of attributes in string for a given set of traits
   * @param traits set of traits
   * @return string array of attributes
   */
  function _traitsToAttributesString(uint256[8] calldata traits)
    internal
    view
    returns (string[] memory)
  {
    string[] memory traitsToString = new string[](10);
    traitsToString[0] = traits[0] < 8 ? 'Standard' : 'Premium';
    traitsToString[1] = traits[0] % 2 == 0 ? 'Male' : 'Female';
    if (traits[0] % 2 == 0) {
      traitsToString[2] = TRAIT_BASE[traits[0]];
      traitsToString[3] = TRAIT_NECKLACE[traits[1]];
      traitsToString[4] = TRAIT_FACIAL_MALE[traits[2]];
      traitsToString[5] = TRAIT_EARRING[traits[3]];
      traitsToString[6] = TRAIT_HEAD_MALE[traits[4]];
      traitsToString[7] = TRAIT_GLASSES[traits[5]];
      traitsToString[8] = TRAIT_LIPSTICK_MALE[traits[6]];
      traitsToString[9] = TRAIT_SMOKING[traits[7]];
    } else {
      traitsToString[2] = TRAIT_BASE[traits[0]];
      traitsToString[3] = TRAIT_NECKLACE[traits[1]];
      traitsToString[4] = TRAIT_FACIAL_FEMALE[traits[2]];
      traitsToString[5] = TRAIT_EARRING[traits[3]];
      traitsToString[6] = TRAIT_HEAD_FEMALE[traits[4]];
      traitsToString[7] = TRAIT_GLASSES[traits[5]];
      traitsToString[8] = TRAIT_LIPSTICK_FEMALE[traits[6]];
      traitsToString[9] = TRAIT_SMOKING[traits[7]];
    }
    return traitsToString;
  }

  /**
   * @notice Returns an string indicating the breed and sex given the base trait
   * @param base base trait
   * @return breed and sex string
   */
  function _getBreedAndSexString(uint256 base) internal pure returns (string memory) {
    string memory breed;
    if (base / 2 < 4) {
      breed = ' (Human ';
    } else if (base / 2 == 4) {
      breed = ' (Vampire ';
    } else if (base / 2 == 5) {
      breed = ' (Metahuman ';
    } else {
      breed = ' (Ape ';
    }
    return string(abi.encodePacked(breed, base % 2 == 0 ? 'Male)' : 'Female)'));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
  string internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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
pragma solidity 0.8.10;

interface IDescriptor {
  function tokenURI(uint256[8] calldata) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITokenIdResolver {
  /**
   * @notice Returns the token id of a given set of traits
   * @param traits set of traits of the token
   * @return token id
   */
  function getTokenId(uint256[8] calldata traits) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// This is a modified version of LibSvg.sol of aavegotchi-contracts
// https://github.com/aavegotchi/aavegotchi-contracts/blob/80f4031b65ae8a16831879cd40b00796892860fe/contracts/Aavegotchi/libraries/LibSvg.sol
library LibSvg {
  event StoreSvg(SvgTypeAndSizes[] typesAndSizes);
  event UpdateSvg(SvgTypeAndIdsAndSizes[] typesAndIdsAndSizes);

  struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
  }

  struct SvgTypeAndSizes {
    bytes32 svgType;
    uint256[] sizes;
  }

  struct SvgTypeAndIdsAndSizes {
    bytes32 svgType;
    uint256[] ids;
    uint256[] sizes;
  }

  function _getSvg(SvgLayer[] storage svgLayers, uint256 id)
    internal
    view
    returns (bytes memory svg)
  {
    require(id < svgLayers.length, 'LibSvg: SVG type or id does not exist');

    SvgLayer storage svgLayer = svgLayers[id];
    address svgContract = svgLayer.svgLayersContract;
    uint256 size = svgLayer.size;
    uint256 offset = svgLayer.offset;
    svg = new bytes(size);
    assembly {
      extcodecopy(svgContract, add(svg, 32), offset, size)
    }
  }

  function _storeSvg(
    mapping(bytes32 => SvgLayer[]) storage svgLayers,
    string calldata svg,
    SvgTypeAndSizes[] calldata typesAndSizes
  ) internal {
    emit StoreSvg(typesAndSizes);
    address svgContract = _storeSvgInContract(svg);
    uint256 offset;
    for (uint256 i; i < typesAndSizes.length; i++) {
      SvgTypeAndSizes calldata svgTypeAndSizes = typesAndSizes[i];
      for (uint256 j; j < svgTypeAndSizes.sizes.length; j++) {
        uint256 size = svgTypeAndSizes.sizes[j];
        svgLayers[svgTypeAndSizes.svgType].push(
          SvgLayer(svgContract, uint16(offset), uint16(size))
        );
        offset += size;
      }
    }
  }

  function _updateSvg(
    mapping(bytes32 => SvgLayer[]) storage svgLayers,
    string calldata svg,
    SvgTypeAndIdsAndSizes[] calldata typesAndIdsAndSizes
  ) internal {
    emit UpdateSvg(typesAndIdsAndSizes);
    address svgContract = _storeSvgInContract(svg);
    uint256 offset;
    for (uint256 i; i < typesAndIdsAndSizes.length; i++) {
      SvgTypeAndIdsAndSizes calldata svgTypeAndIdsAndSizes = typesAndIdsAndSizes[i];
      for (uint256 j; j < svgTypeAndIdsAndSizes.sizes.length; j++) {
        uint256 size = svgTypeAndIdsAndSizes.sizes[j];
        uint256 id = svgTypeAndIdsAndSizes.ids[j];
        svgLayers[svgTypeAndIdsAndSizes.svgType][id] = SvgLayer(
          svgContract,
          uint16(offset),
          uint16(size)
        );
        offset += size;
      }
    }
  }

  function _storeSvgInContract(string calldata svg) internal returns (address svgContract) {
    require(bytes(svg).length < 24576, 'SvgStorage: Exceeded 24,576 bytes max contract size');
    // 610000 -- PUSH2 (size)
    // 6000 -- PUSH1 (code position)
    // 6000 -- PUSH1 (mem position)
    // 39 CODECOPY
    // 610000 PUSH2 (size)
    // 6000 PUSH1 (mem position)
    // f3 RETURN
    bytes memory init = hex'610000600e6000396100006000f3';
    bytes1 size1 = bytes1(uint8(bytes(svg).length));
    bytes1 size2 = bytes1(uint8(bytes(svg).length >> 8));
    init[2] = size1;
    init[1] = size2;
    init[10] = size1;
    init[9] = size2;
    bytes memory code = abi.encodePacked(init, svg);

    assembly {
      svgContract := create(0, add(code, 32), mload(code))
      if eq(svgContract, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
}