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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StringUtilsLib.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

contract FashionHatPunksData is Ownable {
    using StringUtils for string;
    using Strings for uint16;
    using Strings for uint8;
    using Strings for uint256;
    
    PunkDataInterface immutable punkDataContract;
    
    enum HatType { BASEBALL, BUCKET, COWBOY, VISOR }
    enum HatSize { REGULAR, SMALL }
    enum HatColor { BLACK, GREY, RED, WHITE, TAN, BROWN }
    enum HatPosition { REGULAR, FLIPPED }
    
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    constructor(address punkDataContractAddress) {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
    }
    
    function punkHatType(Punk memory punk) public view returns (HatType result) {
        uint[] memory choiceWeights = new uint[](4);
        
        for (uint i; i < 4; i++) {
            choiceWeights[i] = 25e8;
        }
        
        if (!visorLooksGood[punk.hair][punk.sex]) { 
            choiceWeights[uint(HatType.VISOR)] = 5e8;
        }
        
        if (punk.hair == PunkAttributeValue.COWBOY_HAT) {
            return HatType.COWBOY;
        }
        if (punk.hair == PunkAttributeValue.CAP ||
            punk.hair == PunkAttributeValue.BEANIE ||
            (punk.sex != PunkAttributeValue.FEMALE && originalEyePixelGap(punk) == 2)
        ) {
            return HatType.BASEBALL;
        }
        
        if ((punk.sex == PunkAttributeValue.FEMALE || originalEyePixelGap(punk) == 1) &&
            punk.mouth == PunkAttributeValue.CIGARETTE &&
            (canWearHat(punk, HatType.BUCKET) ||
            (canWearHat(punk, HatType.BASEBALL) && canFlipHat(punk)))
        ) {
            choiceWeights[uint(HatType.COWBOY)] /= 5;
            choiceWeights[uint(HatType.VISOR)] /= 5;
            
            if (!canFlipHat(punk)) {
                choiceWeights[uint(HatType.BASEBALL)] /= 5;
            }
        }
        
        if (punk.seed < 55 && canWearHat(punk, HatType.BASEBALL) &&
            punk.sex != PunkAttributeValue.FEMALE &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
            originalEyePixelGap(punk) != 1
        ) {
            return HatType.BASEBALL;
        }
        
        if (punk.seed < 75 &&
           punk.sex != PunkAttributeValue.FEMALE &&
           (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
           (canWearHat(punk, HatType.COWBOY) || canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.BASEBALL)] = 0;
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (!visibleHairAttribute(punk) && 
            (canWearHat(punk, HatType.COWBOY) ||
             canWearHat(punk, HatType.BASEBALL) ||
             canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (punk.sex != PunkAttributeValue.FEMALE &&
            punk.hair == PunkAttributeValue.CLOWN_HAIR_GREEN &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES)
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (punk.eyes == PunkAttributeValue.WELDING_GOGGLES && 
            (canWearHat(punk, HatType.COWBOY) ||
             canWearHat(punk, HatType.BASEBALL) ||
             canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        for (uint i; i < 4; i++) {
            if (!canWearHat(punk, HatType(i))) {
                choiceWeights[i] = 0;
            }
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_type");
        return HatType(choiceIndex);
    }
    
    function punkHatColor(Punk memory punk) public view returns (HatColor result) {
        HatType hatType = punkHatType(punk);
        
        uint[] memory choiceWeights = new uint[](6);
        
        if (hatType == HatType.BASEBALL) {
            choiceWeights[uint(HatColor.BLACK)] = 22.5e8;
            choiceWeights[uint(HatColor.GREY)] = 25e8;
            choiceWeights[uint(HatColor.RED)] = 20e8;
            choiceWeights[uint(HatColor.WHITE)] = 25e8;
            choiceWeights[uint(HatColor.TAN)] = 20e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        } else if (hatType == HatType.BUCKET) {
            choiceWeights[uint(HatColor.BLACK)] = 50e8;
            choiceWeights[uint(HatColor.GREY)] = 0;
            choiceWeights[uint(HatColor.RED)] = 0;
            choiceWeights[uint(HatColor.WHITE)] = 0;
            choiceWeights[uint(HatColor.TAN)] = 50e8;
            choiceWeights[uint(HatColor.BROWN)] = 50e8;
        } else if (hatType == HatType.COWBOY) {
            choiceWeights[uint(HatColor.BLACK)] = 60e8;
            choiceWeights[uint(HatColor.GREY)] = 20e8;
            choiceWeights[uint(HatColor.RED)] = 0;
            choiceWeights[uint(HatColor.WHITE)] = 0;
            choiceWeights[uint(HatColor.TAN)] = 40e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        } else if (hatType == HatType.VISOR) {
            choiceWeights[uint(HatColor.BLACK)] = 22.5e8;
            choiceWeights[uint(HatColor.GREY)] = 25e8;
            choiceWeights[uint(HatColor.RED)] = 20e8;
            choiceWeights[uint(HatColor.WHITE)] = 25e8;
            choiceWeights[uint(HatColor.TAN)] = 20e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.HOODIE) {
            choiceWeights[uint(HatColor.BLACK)] = 0;
            choiceWeights[uint(HatColor.GREY)] = 0;
            choiceWeights[uint(HatColor.RED)] = 10e8;
            choiceWeights[uint(HatColor.WHITE)] = 30e8;
            choiceWeights[uint(HatColor.TAN)] = 30e8;
        }
        
        if (punk.eyes == PunkAttributeValue.THREE_D_GLASSES || punk.hair == PunkAttributeValue.WILD_WHITE_HAIR) {
            choiceWeights[uint(HatColor.WHITE)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.DARK_HAIR && hatType == HatType.BUCKET) {
            choiceWeights[uint(HatColor.BLACK)] /= 10;
        }
        
        if (hatType == HatType.VISOR) {
            if (punk.hair == PunkAttributeValue.WILD_HAIR || punk.hair == PunkAttributeValue.HALF_SHAVED ||
               ((punk.hair == PunkAttributeValue.HEADBAND && punk.sex == PunkAttributeValue.FEMALE))) {
                choiceWeights[uint(HatColor.BLACK)] = 0;
            }
            
            if (punk.hair == PunkAttributeValue.WILD_BLONDE) {
                choiceWeights[uint(HatColor.TAN)] = 0;
            }
        }
        
        if (hatType == HatType.COWBOY || hatType == HatType.BUCKET) {
            if (
                eyesWithBlackTop(punk) ||
                punk.hair == PunkAttributeValue.FRUMPY_HAIR ||
                punk.hair == PunkAttributeValue.WILD_HAIR ||
                punk.hair == PunkAttributeValue.HALF_SHAVED
            ) {
                choiceWeights[uint(HatColor.BLACK)] = 0;
            }
        }
        
        if (punk.sex != PunkAttributeValue.FEMALE && (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES)) {
            choiceWeights[uint(HatColor.BLACK)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.CRAZY_HAIR && (punk.sex == PunkAttributeValue.FEMALE || hatType == HatType.VISOR)) {
            choiceWeights[uint(HatColor.RED)] = 0;
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_color");
        return HatColor(choiceIndex);
    }
    
    function punkHatPosition(Punk memory punk) public view returns (HatPosition result) {
        HatType hatType = punkHatType(punk);
        
        if (hatType != HatType.BASEBALL) {
            return HatPosition.REGULAR;
        }
        
        uint[] memory choiceWeights = new uint[](2);
        
        choiceWeights[uint(HatPosition.REGULAR)] = 50e8;
        choiceWeights[uint(HatPosition.FLIPPED)] = 50e8;
        
        if (punk.hair == PunkAttributeValue.HALF_SHAVED) {
            return HatPosition.FLIPPED;
        }
        
        if (!canFlipHat(punk)) {
            return HatPosition.REGULAR;
        }
        
        if (
            punk.sex != PunkAttributeValue.FEMALE &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
            hatEyePixelGap(punk) == 1
        ) {
            return (punk.eyes == PunkAttributeValue.BIG_SHADES ? HatPosition.REGULAR : HatPosition.FLIPPED);
        }
        
        if ((punk.sex == PunkAttributeValue.FEMALE || originalEyePixelGap(punk) == 1) &&
            punk.mouth == PunkAttributeValue.CIGARETTE
        ) {
            choiceWeights[uint(HatPosition.REGULAR)] /= 10;
        }
        
        if (
            punk.hair == PunkAttributeValue.HOODIE ||
            punk.hair == PunkAttributeValue.BEANIE ||
            originalEyePixelGap(punk) == 2
        ) {
            return HatPosition.REGULAR;
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_position");
        return HatPosition(choiceIndex);
    }
    
    function hatEyePixelGap(Punk memory punk) public view returns (uint8 gap) {
        HatType currentHat = punkHatType(punk);
        
        if (
            currentHat == HatType.VISOR ||
            currentHat == HatType.BUCKET ||
            currentHat == HatType.COWBOY
        ) {
            return 1;
        }
        
        if (punk.hair == PunkAttributeValue.BANDANA) {
            if (punk.sex == PunkAttributeValue.FEMALE) {
                return 1;
            } else {
                if (punk.eyes == PunkAttributeValue.BIG_SHADES || punk.eyes == PunkAttributeValue.VR) {
                    return 2;
                } else {
                    return 1;
                }
            }
        }
        
        uint8 originalGap = originalEyePixelGap(punk);
        
        if (punk.sex != PunkAttributeValue.FEMALE) {
            if (
                punk.hair == PunkAttributeValue.CLOWN_HAIR_GREEN ||
                punk.hair == PunkAttributeValue.HOODIE
            ) {
                return 1;
            } else {
                return (originalGap > 0 ? originalGap : 2);
            }
        }
        
        if (
            (currentHat == HatType.BASEBALL &&
            (punk.hair == PunkAttributeValue.DARK_HAIR || punk.hair == PunkAttributeValue.ORANGE_SIDE)) ||
            (punk.hair == PunkAttributeValue.PINK_WITH_HAT || punk.hair == PunkAttributeValue.STRAIGHT_HAIR ||
             punk.hair == PunkAttributeValue.STRAIGHT_HAIR_BLONDE || punk.hair == PunkAttributeValue.STRAIGHT_HAIR_DARK)
        ) {
            return 1;
        }
        
        return (originalGap > 0 ? originalGap : 2);
    }
    
    function punkHatSize(Punk memory punk) public view returns (HatSize result) {
        HatType currentHat = punkHatType(punk);

        if (punk.sex != PunkAttributeValue.FEMALE) {
            return HatSize.REGULAR;
        }
        
        if (currentHat == HatType.BASEBALL && punk.hair == PunkAttributeValue.CRAZY_HAIR) {
            return HatSize.REGULAR;
        }
        
        if (currentHat == HatType.BUCKET && punk.hair == PunkAttributeValue.WILD_HAIR) {
            return HatSize.REGULAR;
        }
        
        if (
            currentHat == HatType.BUCKET ||
            currentHat == HatType.BASEBALL
        ) {
            if (
                punk.hair == PunkAttributeValue.BLONDE_BOB ||
                punk.hair == PunkAttributeValue.BLONDE_SHORT
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            currentHat == HatType.COWBOY ||
            currentHat == HatType.BUCKET ||
            currentHat == HatType.BASEBALL
        ) {
            if (
                punk.hair == PunkAttributeValue.FRUMPY_HAIR
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            currentHat == HatType.COWBOY ||
            currentHat == HatType.BUCKET
        ) {
            if (
                punk.hair == PunkAttributeValue.HALF_SHAVED ||
                punk.hair == PunkAttributeValue.WILD_BLONDE
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR_BLONDE ||
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR ||
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR_DARK
        ) {
            return HatSize.REGULAR;
        }
        
        return HatSize.SMALL;
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public canFlipHatMapping;
    
    function setcanFlipHatMapping(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            canFlipHatMapping[hair][sex] = true;
        }
    }
    
    function canFlipHat(Punk memory punk) public view returns (bool) {
        if (!canWearHat(punk, HatType.BASEBALL)) {
            return false;
        }
        
        return canFlipHatMapping[punk.hair][punk.sex];
    }
    
    function randomNumber(Punk memory punk, uint lessThanNumb, string memory seedAddition) public pure returns (uint) {
        uint16 seed = punk.seed;
        uint256 randomNum = uint256(
            keccak256(abi.encodePacked(punk.id.toString(), ":", seed.toString(), seedAddition))
        );
        
        return uint(randomNum % lessThanNumb);
    }
    
    function weightedChoice(Punk memory punk, uint[] memory choiceWeights, string memory seedAddition) public pure returns (uint8) {
        uint sumOfWeights;
        uint numChoices = choiceWeights.length;

        for (uint i; i < numChoices; i++) {
            sumOfWeights += choiceWeights[i];
        }
        
        uint randomNumberInstance = randomNumber(punk, sumOfWeights, seedAddition);
        
        for (uint8 i; i < numChoices; i++) {
            if (randomNumberInstance < choiceWeights[i]) {
                return i;
            } else {
                randomNumberInstance -= choiceWeights[i];
            }
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public visorLooksGood;
    
    function setVisorLooksGood(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            visorLooksGood[hair][sex] = true;
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public lacksVisibleHairAttribute;
    
    function setLacksVisibleHairAttribute(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            lacksVisibleHairAttribute[hair][sex] = true;
        }
    }
    
    function visibleHairAttribute(Punk memory punk) public view returns (bool) {
        return !lacksVisibleHairAttribute[punk.hair][punk.sex];
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => uint8)) public originalEyePixelGapMapping;
    
    function setOriginalEyePixelGap(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes, uint8[] memory gaps) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            originalEyePixelGapMapping[hair][sex] = gaps[i];
        }
    }
    
    function originalEyePixelGap(Punk memory punk) public view returns (uint8 gap) {
        return originalEyePixelGapMapping[punk.hair][punk.sex];
    }
    
    function eyesWithBlackTop(Punk memory punk) public pure returns (bool) {
        if (punk.sex == PunkAttributeValue.FEMALE && punk.eyes == PunkAttributeValue.REGULAR_SHADES) {
            return true;
        }
        
        return (
            punk.eyes == PunkAttributeValue.NERD_GLASSES ||
            punk.eyes == PunkAttributeValue.HORNED_RIM_GLASSES ||
            punk.eyes == PunkAttributeValue.EYE_PATCH ||
            punk.eyes == PunkAttributeValue.EYE_MASK ||
            punk.eyes == PunkAttributeValue.CLASSIC_SHADES ||
            punk.eyes == PunkAttributeValue.BIG_SHADES ||
            punk.eyes == PunkAttributeValue.VR
        );
    }
    
    struct Punk {
        uint16 id;
        uint16 seed;
        PunkAttributeValue sex;
        PunkAttributeValue hair;
        PunkAttributeValue eyes;
        PunkAttributeValue beard;
        PunkAttributeValue ears;
        PunkAttributeValue lips;
        PunkAttributeValue mouth;
        PunkAttributeValue face;
        PunkAttributeValue emotion;
        PunkAttributeValue neck;
        PunkAttributeValue nose;
        PunkAttributeValue cheeks;
        PunkAttributeValue teeth;
    }
    
    function initializePunk(uint16 punkId, uint16 punkSeed) public view returns (Punk memory) {
        Punk memory punk = Punk({
            id: punkId,
            seed: punkSeed,
            sex: PunkAttributeValue.NONE,
            hair: PunkAttributeValue.NONE,
            eyes: PunkAttributeValue.NONE,
            beard: PunkAttributeValue.NONE,
            ears: PunkAttributeValue.NONE,
            lips: PunkAttributeValue.NONE,
            mouth: PunkAttributeValue.NONE,
            face: PunkAttributeValue.NONE,
            emotion: PunkAttributeValue.NONE,
            neck: PunkAttributeValue.NONE,
            nose: PunkAttributeValue.NONE,
            cheeks: PunkAttributeValue.NONE,
            teeth: PunkAttributeValue.NONE
        });
        
        string memory attributes = punkDataContract.punkAttributes(punk.id);

        string[] memory attributeArray = attributes.split(",");
        
        for (uint i = 0; i < attributeArray.length; i++) {
            string memory untrimmedAttribute = attributeArray[i];
            string memory trimmedAttribute;
            
            if (i < 1) {
                trimmedAttribute = untrimmedAttribute.split(' ')[0];
            } else {
                trimmedAttribute = untrimmedAttribute._substring(int(bytes(untrimmedAttribute).length - 1), 1);
            }
            
            PunkAttributeValue attrValue = attrStringToEnumMapping[trimmedAttribute];
            PunkAttributeType attrType = attrValueToTypeEnumMapping[attrValue];
            
            if (attrType == PunkAttributeType.SEX) {
                punk.sex = attrValue;
            } else if (attrType == PunkAttributeType.HAIR) {
                punk.hair = attrValue;
            } else if (attrType == PunkAttributeType.EYES) {
                punk.eyes = attrValue;
            } else if (attrType == PunkAttributeType.BEARD) {
                punk.beard = attrValue;
            } else if (attrType == PunkAttributeType.EARS) {
                punk.ears = attrValue;
            } else if (attrType == PunkAttributeType.LIPS) {
                punk.lips = attrValue;
            } else if (attrType == PunkAttributeType.MOUTH) {
                punk.mouth = attrValue;
            } else if (attrType == PunkAttributeType.FACE) {
                punk.face = attrValue;
            } else if (attrType == PunkAttributeType.EMOTION) {
                punk.emotion = attrValue;
            } else if (attrType == PunkAttributeType.NECK) {
                punk.neck = attrValue;
            } else if (attrType == PunkAttributeType.NOSE) {
                punk.nose = attrValue;
            } else if (attrType == PunkAttributeType.CHEEKS) {
                punk.cheeks = attrValue;
            } else if (attrType == PunkAttributeType.TEETH) {
                punk.teeth = attrValue;
            }
        }
        
        return punk;
    }
    
    function punkAttributesAsJSON(uint16 punkId, uint16 punkSeed) public view returns (string memory json) {
        Punk memory punk = initializePunk(punkId, punkSeed);
        
        PunkAttributeValue none = PunkAttributeValue.NONE;
        bytes memory output = "[";
        
        HatType hat = punkHatType(punk);
        HatColor hatColor = punkHatColor(punk);
        HatPosition hatPosition = punkHatPosition(punk);
        
        PunkAttributeValue[13] memory attrArray = [
            punk.sex,
            (visibleHair(punk) ? punk.hair : none),
            punk.eyes,
            punk.beard,
            punk.ears,
            punk.lips,
            punk.mouth,
            punk.face,
            punk.emotion,
            punk.neck,
            punk.nose,
            punk.cheeks,
            punk.teeth
        ];
        
        bytes memory hatColorBytes;
        
        if (hatColor == HatColor.BLACK) {
            hatColorBytes = "Black";
        } else if (hatColor == HatColor.GREY) {
            hatColorBytes = "Grey";
        } else if (hatColor == HatColor.RED) {
            hatColorBytes = "Red";
        } else if (hatColor == HatColor.WHITE) {
            hatColorBytes = "White";
        } else if (hatColor == HatColor.TAN) {
            hatColorBytes = "Tan";
        } else if (hatColor == HatColor.BROWN) {
            hatColorBytes = "Brown";
        }
        
        bytes memory hatTypeBytes;
        
        if (hat == HatType.BASEBALL) {
            hatTypeBytes = "Baseball Cap";
        } else if (hat == HatType.BUCKET) {
            hatTypeBytes = "Bucket Hat";
        } else if (hat == HatType.COWBOY) {
            hatTypeBytes = "Cowboy Hat";
        } else if (hat == HatType.VISOR) {
            hatTypeBytes = "Visor";
        }
        
        for (uint i = 0; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];
            
            if (attrVal != none) {
                output = abi.encodePacked(output, punkAttributeAsJSON(attrVal), ",");
            }
        }
        
        bytes memory hatName = abi.encodePacked(hatColorBytes, " ", hatTypeBytes);
        
        if (hatPosition == HatPosition.FLIPPED) {
            hatName = abi.encodePacked("Backwards ", hatName);
        }
        
        bytes memory hatTrait = abi.encodePacked(
            '{"trait_type":"Fashion Hat", "value":"', hatName, '"}'
        );
        
        return string(abi.encodePacked(output, hatTrait, "]"));
    }
    
    function punkAttributeAsJSON(PunkAttributeValue attribute) internal view returns (string memory json) {
        require(attribute != PunkAttributeValue.NONE);
        
        string memory attributeAsString = attrEnumToStringMapping[attribute];
        string memory attributeTypeAsString;
        
        PunkAttributeType attrType = attrValueToTypeEnumMapping[attribute];
        
        if (attrType == PunkAttributeType.SEX) {
            attributeTypeAsString = "Sex";
        } else if (attrType == PunkAttributeType.HAIR) {
            attributeTypeAsString = "Hair";
        } else if (attrType == PunkAttributeType.EYES) {
            attributeTypeAsString = "Eyes";
        } else if (attrType == PunkAttributeType.BEARD) {
            attributeTypeAsString = "Beard";
        } else if (attrType == PunkAttributeType.EARS) {
            attributeTypeAsString = "Ears";
        } else if (attrType == PunkAttributeType.LIPS) {
            attributeTypeAsString = "Lips";
        } else if (attrType == PunkAttributeType.MOUTH) {
            attributeTypeAsString = "Mouth";
        } else if (attrType == PunkAttributeType.FACE) {
            attributeTypeAsString = "Face";
        } else if (attrType == PunkAttributeType.EMOTION) {
            attributeTypeAsString = "Emotion";
        } else if (attrType == PunkAttributeType.NECK) {
            attributeTypeAsString = "Neck";
        } else if (attrType == PunkAttributeType.NOSE) {
            attributeTypeAsString = "Nose";
        } else if (attrType == PunkAttributeType.CHEEKS) {
            attributeTypeAsString = "Cheeks";
        } else if (attrType == PunkAttributeType.TEETH) {
            attributeTypeAsString = "Teeth";
        }
        
        return string(abi.encodePacked('{"trait_type":"', attributeTypeAsString, '", "value":"', attributeAsString, '"}'));
    }
    
    function visibleHair(Punk memory punk) public view returns (bool) {
        HatType hat = punkHatType(punk);

        if (visibleHairAttribute(punk)) { return true; }
        
        if (punk.hair == PunkAttributeValue.BEANIE && hat == HatType.BASEBALL) {
            return true;
        }
        
        bool tiaraBlocked = punk.eyes == PunkAttributeValue.REGULAR_SHADES ||
                            punk.eyes == PunkAttributeValue.CLASSIC_SHADES ||
                            punk.eyes == PunkAttributeValue.HORNED_RIM_GLASSES ||
                            punk.eyes == PunkAttributeValue.THREE_D_GLASSES ||
                            punk.eyes == PunkAttributeValue.EYE_PATCH ||
                            punk.eyes == PunkAttributeValue.EYE_MASK;
                             
        if (punk.hair == PunkAttributeValue.TIARA && (!tiaraBlocked || hatEyePixelGap(punk) == 2)) {
            return true;
        }
        
        return false;
    }
    
    mapping(PunkAttributeValue => PunkAttributeType) public attrValueToTypeEnumMapping;
    
    function setAttrValueToTypeEnumMapping(uint8[][] memory attrValuesAndTypes) external onlyOwner {
        for (uint i; i < attrValuesAndTypes.length; i++) {
            PunkAttributeValue attrVal = PunkAttributeValue(attrValuesAndTypes[i][0]);
            PunkAttributeType attrType = PunkAttributeType(attrValuesAndTypes[i][1]);
            
            attrValueToTypeEnumMapping[attrVal] = attrType;
        }
    }
    
    mapping(string => PunkAttributeValue) public attrStringToEnumMapping;
    mapping(PunkAttributeValue => string) public attrEnumToStringMapping;
    
    function setAttrStringToEnumMapping(string[] memory attrStrs, PunkAttributeValue[] memory attrEnums) external onlyOwner {
        for (uint i; i < attrStrs.length; i++) {
            string memory attrString = attrStrs[i];
            PunkAttributeValue attrEnum = attrEnums[i];
            
            attrStringToEnumMapping[attrString] = attrEnum;
            attrEnumToStringMapping[attrEnum] = attrString;
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => mapping(HatType => bool))) public hatAvailableBySexAndHair;
    
    function canWearHat(Punk memory punk, HatType hat) public view returns (bool) {
        return hatAvailableBySexAndHair[punk.hair][punk.sex][hat];
    }
    
    function setAvailableHats(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes, HatType[] memory hats) external onlyOwner {
        for (uint i; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            HatType hat = hats[i];
            
            hatAvailableBySexAndHair[hair][sex][hat] = true;
        }
    }
}

pragma solidity ^0.8.0;

/**
 * Strings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */
library StringUtils {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }


    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}