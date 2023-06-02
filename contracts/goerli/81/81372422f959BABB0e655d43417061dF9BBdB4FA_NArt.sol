// SPDX-License-Identifier: GPL-3.0

/// @title The Punks art storage contract

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IArt } from './interfaces/IArt.sol';
import { SSTORE2 } from './libs/SSTORE2.sol';
import { IInflator } from './interfaces/IInflator.sol';

contract NArt is IArt {
    /// @notice Current Punk Descriptor address
    address public override descriptor;

    /// @notice Current inflator address
    IInflator public override inflator;

    /// @notice Noun Backgrounds (Hex Colors)
//    string[] public override backgrounds;

    /// @notice Punk Color Palettes (Index => Hex Colors, stored as a contract using SSTORE2)
    mapping(uint8 => address) public palettesPointers;

    Trait public punkTypesTrait;
    Trait public hatsTrait;
    Trait public helmetsTrait;
    Trait public hairsTrait;
    Trait public beardsTrait;
    Trait public eyesesTrait;
    Trait public glassesesTrait;
    Trait public gogglesesTrait;
    Trait public mouthsTrait;
    Trait public teethsTrait;
    Trait public lipsesTrait;
    Trait public necksTrait;
    Trait public emotionsTrait;
    Trait public facesTrait;
    Trait public earsesTrait;
    Trait public nosesTrait;
    Trait public cheeksesTrait;

    /**
     * @notice Require that the sender is the descriptor.
     */
    modifier onlyDescriptor() {
        if (msg.sender != descriptor) {
            revert SenderIsNotDescriptor();
        }
        _;
    }

    constructor(address _descriptor, IInflator _inflator) {
        descriptor = _descriptor;
        inflator = _inflator;
    }

    /**
     * @notice Set the descriptor.
     * @dev This function can only be called by the current descriptor.
     */
    function setDescriptor(address _descriptor) external override onlyDescriptor {
        address oldDescriptor = descriptor;
        descriptor = _descriptor;

        emit DescriptorUpdated(oldDescriptor, descriptor);
    }

    /**
     * @notice Set the inflator.
     * @dev This function can only be called by the descriptor.
     */
    function setInflator(IInflator _inflator) external override onlyDescriptor {
        address oldInflator = address(inflator);
        inflator = _inflator;

        emit InflatorUpdated(oldInflator, address(_inflator));
    }

    /**
     * @notice Get the Trait struct for bodies.
     * @dev This explicit getter is needed because implicit getters for structs aren't fully supported yet:
     * https://github.com/ethereum/solidity/issues/11826
     * @return Trait the struct, including a total image count, and an array of storage pages.
     */
    function getPunkTypesTrait() external view override returns (Trait memory) {
        return punkTypesTrait;
    }
    function getHatsTrait() external view override returns (Trait memory) {
        return hatsTrait;
    }
    function getHelmetsTrait() external view override returns (Trait memory) {
        return helmetsTrait;
    }
    function getHairsTrait() external view override returns (Trait memory) {
        return hairsTrait;
    }
    function getBeardsTrait() external view override returns (Trait memory) {
        return beardsTrait;
    }
    function getEyesesTrait() external view override returns (Trait memory) {
        return eyesesTrait;
    }
    function getGlassesesTrait() external view override returns (Trait memory) {
        return glassesesTrait;
    }
    function getGogglesesTrait() external view override returns (Trait memory) {
        return gogglesesTrait;
    }
    function getMouthsTrait() external view override returns (Trait memory) {
        return mouthsTrait;
    }
    function getTeethsTrait() external view override returns (Trait memory) {
        return teethsTrait;
    }
    function getLipsesTrait() external view override returns (Trait memory) {
        return lipsesTrait;
    }
    function getNecksTrait() external view override returns (Trait memory) {
        return necksTrait;
    }
    function getEmotionsTrait() external view override returns (Trait memory) {
        return emotionsTrait;
    }
    function getFacesTrait() external view override returns (Trait memory) {
        return facesTrait;
    }
    function getEarsesTrait() external view override returns (Trait memory) {
        return earsesTrait;
    }
    function getNosesTrait() external view override returns (Trait memory) {
        return nosesTrait;
    }
    function getCheeksesTrait() external view override returns (Trait memory) {
        return cheeksesTrait;
    }

    /**
     * @notice Batch add Noun backgrounds.
     * @dev This function can only be called by the descriptor.
     */
    // function addManyBackgrounds(string[] calldata _backgrounds) external override onlyDescriptor {
    //     for (uint256 i = 0; i < _backgrounds.length; i++) {
    //         _addBackground(_backgrounds[i]);
    //     }

    //     emit BackgroundsAdded(_backgrounds.length);
    // }

    // /**
    //  * @notice Add a Noun background.
    //  * @dev This function can only be called by the descriptor.
    //  */
    // function addBackground(string calldata _background) external override onlyDescriptor {
    //     _addBackground(_background);

    //     emit BackgroundsAdded(1);
    // }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette.
     * @param paletteIndex the identifier of this palette
     * @param palette byte array of colors. every 4 bytes represent an RGBA color. max length: 256 * 4 = 1024
     * @dev This function can only be called by the descriptor.
     */
    function setPalette(uint8 paletteIndex, bytes calldata palette) external override onlyDescriptor {
        if (palette.length == 0) {
            revert EmptyPalette();
        }
        if (palette.length % 4 != 0 || palette.length > 1024) {
            revert BadPaletteLength();
        }
        palettesPointers[paletteIndex] = SSTORE2.write(palette);

        emit PaletteSet(paletteIndex);
    }

    /**
     * @notice Add a batch of body images.
     * @param encodedCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the descriptor.
     */
    function addPunkTypes(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(punkTypesTrait, encodedCompressed, decompressedLength, imageCount);

        emit PunkTypesAdded(imageCount);
    }
    function addHats(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(hatsTrait, encodedCompressed, decompressedLength, imageCount);

        emit HatsAdded(imageCount);
    }
    function addHelmets(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(helmetsTrait, encodedCompressed, decompressedLength, imageCount);

        emit HelmetsAdded(imageCount);
    }
    function addHairs(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(hairsTrait, encodedCompressed, decompressedLength, imageCount);

        emit HairsAdded(imageCount);
    }
    function addBeards(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(beardsTrait, encodedCompressed, decompressedLength, imageCount);

        emit BeardsAdded(imageCount);
    }
    function addEyeses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(eyesesTrait, encodedCompressed, decompressedLength, imageCount);

        emit EyesesAdded(imageCount);
    }
    function addGlasseses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(glassesesTrait, encodedCompressed, decompressedLength, imageCount);

        emit GlassesesAdded(imageCount);
    }
    function addGoggleses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(gogglesesTrait, encodedCompressed, decompressedLength, imageCount);

        emit GogglesesAdded(imageCount);
    }
    function addMouths(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(mouthsTrait, encodedCompressed, decompressedLength, imageCount);

        emit MouthsAdded(imageCount);
    }
    function addTeeths(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(teethsTrait, encodedCompressed, decompressedLength, imageCount);

        emit TeethsAdded(imageCount);
    }
    function addLipses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(lipsesTrait, encodedCompressed, decompressedLength, imageCount);

        emit LipsesAdded(imageCount);
    }
    function addNecks(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(necksTrait, encodedCompressed, decompressedLength, imageCount);

        emit NecksAdded(imageCount);
    }
    function addEmotions(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(emotionsTrait, encodedCompressed, decompressedLength, imageCount);

        emit EmotionsAdded(imageCount);
    }
    function addFaces(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(facesTrait, encodedCompressed, decompressedLength, imageCount);

        emit FacesAdded(imageCount);
    }
    function addEarses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(earsesTrait, encodedCompressed, decompressedLength, imageCount);

        emit EarsesAdded(imageCount);
    }
    function addNoses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(nosesTrait, encodedCompressed, decompressedLength, imageCount);

        emit NosesAdded(imageCount);
    }
    function addCheekses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(cheeksesTrait, encodedCompressed, decompressedLength, imageCount);

        emit CheeksesAdded(imageCount);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette. This function does not check for data length validity
     * (len <= 768, len % 3 == 0).
     * @param paletteIndex the identifier of this palette
     * @param pointer the address of the contract holding the palette bytes. every 3 bytes represent an RGB color.
     * max length: 256 * 3 = 768.
     * @dev This function can only be called by the descriptor.
     */
    function setPalettePointer(uint8 paletteIndex, address pointer) external override onlyDescriptor {
        palettesPointers[paletteIndex] = pointer;

        emit PaletteSet(paletteIndex);
    }

    /**
     * @notice Add a batch of body images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the descriptor.
     */
    function addPunkTypesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(punkTypesTrait, pointer, decompressedLength, imageCount);

        emit PunkTypesAdded(imageCount);
    }
    function addHatsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(hatsTrait, pointer, decompressedLength, imageCount);

        emit HatsAdded(imageCount);
    }
    function addHelmetsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(helmetsTrait, pointer, decompressedLength, imageCount);

        emit HelmetsAdded(imageCount);
    }
    function addHairsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(hairsTrait, pointer, decompressedLength, imageCount);

        emit HairsAdded(imageCount);
    }
    function addBeardsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(beardsTrait, pointer, decompressedLength, imageCount);

        emit BeardsAdded(imageCount);
    }
    function addEyesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(eyesesTrait, pointer, decompressedLength, imageCount);

        emit EyesesAdded(imageCount);
    }
    function addGlassesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(glassesesTrait, pointer, decompressedLength, imageCount);

        emit GlassesesAdded(imageCount);
    }
    function addGogglesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(gogglesesTrait, pointer, decompressedLength, imageCount);

        emit GogglesesAdded(imageCount);
    }
    function addMouthsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(mouthsTrait, pointer, decompressedLength, imageCount);

        emit MouthsAdded(imageCount);
    }
    function addTeethsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(teethsTrait, pointer, decompressedLength, imageCount);

        emit TeethsAdded(imageCount);
    }
    function addLipsesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(lipsesTrait, pointer, decompressedLength, imageCount);

        emit LipsesAdded(imageCount);
    }
    function addNecksFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(necksTrait, pointer, decompressedLength, imageCount);

        emit NecksAdded(imageCount);
    }
    function addEmotionsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(emotionsTrait, pointer, decompressedLength, imageCount);

        emit EmotionsAdded(imageCount);
    }
    function addFacesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(facesTrait, pointer, decompressedLength, imageCount);

        emit FacesAdded(imageCount);
    }
    function addEarsesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(earsesTrait, pointer, decompressedLength, imageCount);

        emit EarsesAdded(imageCount);
    }
    function addNosesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(nosesTrait, pointer, decompressedLength, imageCount);

        emit NosesAdded(imageCount);
    }
    function addCheeksesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        addPage(cheeksesTrait, pointer, decompressedLength, imageCount);

        emit CheeksesAdded(imageCount);
    }

    /**
     * @notice Get the number of available Punk `backgrounds`.
     */
    // function backgroundsCount() public view override returns (uint256) {
    //     return backgrounds.length;
    // }

    /**
     * @notice Get a head image bytes (RLE-encoded).
     */
    function punkTypes(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(punkTypesTrait, index);
    }
    function hats(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(hatsTrait, index);
    }
    function helmets(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(helmetsTrait, index);
    }
    function hairs(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(hairsTrait, index);
    }
    function beards(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(beardsTrait, index);
    }
    function eyeses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(eyesesTrait, index);
    }
    function glasseses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(glassesesTrait, index);
    }
    function goggleses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(gogglesesTrait, index);
    }
    function mouths(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(mouthsTrait, index);
    }
    function teeths(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(teethsTrait, index);
    }
    function lipses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(lipsesTrait, index);
    }
    function necks(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(necksTrait, index);
    }
    function emotions(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(emotionsTrait, index);
    }
    function faces(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(facesTrait, index);
    }
    function earses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(earsesTrait, index);
    }
    function noses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(nosesTrait, index);
    }
    function cheekses(uint256 index) public view override returns (bytes memory) {
        return imageByIndex(cheeksesTrait, index);
    }

    /**
     * @notice Get a color palette bytes.
     */
    function palettes(uint8 paletteIndex) public view override returns (bytes memory) {
        address pointer = palettesPointers[paletteIndex];
        if (pointer == address(0)) {
            revert PaletteNotFound();
        }
        return SSTORE2.read(palettesPointers[paletteIndex]);
    }

    // function _addBackground(string calldata _background) internal {
    //     backgrounds.push(_background);
    // }

    function addPage(
        Trait storage trait,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) internal {
        if (encodedCompressed.length == 0) {
            revert EmptyBytes();
        }
        address pointer = SSTORE2.write(encodedCompressed);
        addPage(trait, pointer, decompressedLength, imageCount);
    }

    function addPage(
        Trait storage trait,
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) internal {
        if (decompressedLength == 0) {
            revert BadDecompressedLength();
        }
        if (imageCount == 0) {
            revert BadImageCount();
        }
        trait.storagePages.push(
            NArtStoragePage({ pointer: pointer, decompressedLength: decompressedLength, imageCount: imageCount })
        );
        trait.storedImagesCount += imageCount;
    }

    function imageByIndex(IArt.Trait storage trait, uint256 index) internal view returns (bytes memory) {
        (IArt.NArtStoragePage storage page, uint256 indexInPage) = getPage(trait.storagePages, index);
        bytes[] memory decompressedImages = decompressAndDecode(page);
        return decompressedImages[indexInPage];
    }

    /**
     * @dev Given an image index, this function finds the storage page the image is in, and the relative index
     * inside the page, so the image can be read from storage.
     * Example: if you have 2 pages with 100 images each, and you want to get image 150, this function would return
     * the 2nd page, and the 50th index.
     * @return IArt.NArtStoragePage the page containing the image at index
     * @return uint256 the index of the image in the page
     */
    function getPage(IArt.NArtStoragePage[] storage pages, uint256 index)
        internal
        view
        returns (IArt.NArtStoragePage storage, uint256)
    {
        uint256 len = pages.length;
        uint256 pageFirstImageIndex = 0;
        for (uint256 i = 0; i < len; i++) {
            IArt.NArtStoragePage storage page = pages[i];

            if (index < pageFirstImageIndex + page.imageCount) {
                return (page, index - pageFirstImageIndex);
            }

            pageFirstImageIndex += page.imageCount;
        }

        revert ImageNotFound();
    }

    function decompressAndDecode(IArt.NArtStoragePage storage page) internal view returns (bytes[] memory) {
        bytes memory compressedData = SSTORE2.read(page.pointer);
        (, bytes memory decompressedData) = inflator.puff(compressedData, page.decompressedLength);
        return abi.decode(decompressedData, (bytes[]));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NArt

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Inflate } from '../libs/Inflate.sol';
import { IInflator } from './IInflator.sol';

interface IArt {
    error SenderIsNotDescriptor();

    error EmptyPalette();

    error BadPaletteLength();

    error EmptyBytes();

    error BadDecompressedLength();

    error BadImageCount();

    error ImageNotFound();

    error PaletteNotFound();

    event DescriptorUpdated(address oldDescriptor, address newDescriptor);

    event InflatorUpdated(address oldInflator, address newInflator);

    event PaletteSet(uint8 paletteIndex);

    event PunkTypesAdded(uint16 count);
    event HatsAdded(uint16 count);
    event HelmetsAdded(uint16 count);
    event HairsAdded(uint16 count);
    event BeardsAdded(uint16 count);
    event EyesesAdded(uint16 count);
    event GlassesesAdded(uint16 count);
    event GogglesesAdded(uint16 count);
    event MouthsAdded(uint16 count);
    event TeethsAdded(uint16 count);
    event LipsesAdded(uint16 count);
    event NecksAdded(uint16 count);
    event EmotionsAdded(uint16 count);
    event FacesAdded(uint16 count);
    event EarsesAdded(uint16 count);
    event NosesAdded(uint16 count);
    event CheeksesAdded(uint16 count);

    struct NArtStoragePage {
        uint16 imageCount;
        uint80 decompressedLength;
        address pointer;
    }

    struct Trait {
        NArtStoragePage[] storagePages;
        uint256 storedImagesCount;
    }

    function descriptor() external view returns (address);

    function inflator() external view returns (IInflator);

    function setDescriptor(address descriptor) external;

    function setInflator(IInflator inflator) external;

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addPunkTypes(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHats(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHelmets(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHairs(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addBeards(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEyeses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addGlasseses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addGoggleses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addMouths(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addTeeths(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addLipses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addNecks(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEmotions(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addFaces(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEarses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addNoses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addCheekses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addPunkTypesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHatsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHelmetsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addHairsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addBeardsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEyesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addGlassesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addGogglesesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addMouthsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addTeethsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addLipsesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addNecksFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEmotionsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addFacesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addEarsesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addNosesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;
    function addCheeksesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;


    function punkTypes(uint256 index) external view returns (bytes memory);
    function hats(uint256 index) external view returns (bytes memory);
    function helmets(uint256 index) external view returns (bytes memory);
    function hairs(uint256 index) external view returns (bytes memory);
    function beards(uint256 index) external view returns (bytes memory);
    function eyeses(uint256 index) external view returns (bytes memory);
    function glasseses(uint256 index) external view returns (bytes memory);
    function goggleses(uint256 index) external view returns (bytes memory);
    function mouths(uint256 index) external view returns (bytes memory);
    function teeths(uint256 index) external view returns (bytes memory);
    function lipses(uint256 index) external view returns (bytes memory);
    function necks(uint256 index) external view returns (bytes memory);
    function emotions(uint256 index) external view returns (bytes memory);
    function faces(uint256 index) external view returns (bytes memory);
    function earses(uint256 index) external view returns (bytes memory);
    function noses(uint256 index) external view returns (bytes memory);
    function cheekses(uint256 index) external view returns (bytes memory);

    function getPunkTypesTrait() external view returns (Trait memory);
    function getHatsTrait() external view returns (Trait memory);
    function getHelmetsTrait() external view returns (Trait memory);
    function getHairsTrait() external view returns (Trait memory);
    function getBeardsTrait() external view returns (Trait memory);
    function getEyesesTrait() external view returns (Trait memory);
    function getGlassesesTrait() external view returns (Trait memory);
    function getGogglesesTrait() external view returns (Trait memory);
    function getMouthsTrait() external view returns (Trait memory);
    function getTeethsTrait() external view returns (Trait memory);
    function getLipsesTrait() external view returns (Trait memory);
    function getNecksTrait() external view returns (Trait memory);
    function getEmotionsTrait() external view returns (Trait memory);
    function getFacesTrait() external view returns (Trait memory);
    function getEarsesTrait() external view returns (Trait memory);
    function getNosesTrait() external view returns (Trait memory);
    function getCheeksesTrait() external view returns (Trait memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.6;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*///////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex'00', data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex'60_0B_59_81_38_03_80_92_59_39_F3', // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), 'DEPLOYMENT_FAILED');
    }

    /*///////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, 'OUT_OF_BOUNDS');

        return readBytecode(pointer, start, end - start);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Inflator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Inflate } from '../libs/Inflate.sol';

interface IInflator {
    function puff(bytes memory source, uint256 destlen) external pure returns (Inflate.ErrorCode, bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
/// @dev Modified the original code for gas optimizations
/// 1. Disable overflow/underflow checks
/// 2. Chunk some loop iterations
library Inflate {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need) private pure returns (uint256) {
        unchecked {
            // Bit accumulator (can use up to 20 bits)
            uint256 val;

            // Load at least need bits into val
            val = s.bitbuf;
            while (s.bitcnt < need) {
                require(s.incnt < s.input.length, "Inflate: ErrorCode.ERR_NOT_TERMINATED");

                // Load eight bits
                // val |= uint256(uint8(s.input[s.incnt])) << s.bitcnt;
                // array length check is skipped
                assembly {
                    val := or(val, shl(mload(add(s, 0xa0)), shr(0xf8, mload(add(add(mload(add(s, 0x40)), 0x20), mload(add(s, 0x60)))))))
                }
                s.incnt++;
                s.bitcnt += 8;
            }

            // Drop need bits and update buffer, always zero to seven bits left
            s.bitbuf = val >> need;
            s.bitcnt -= need;

            // Return need bits, zeroing the bits above that
            uint256 ret = (val & ((1 << need) - 1));
            return ret;
        }
    }

    function bits1(State memory s) private pure returns (uint256) {
        unchecked {
            uint256 val;
            if (s.bitcnt > 0) {
                val = s.bitbuf & 0x1;
                s.bitbuf >>= 1;
                s.bitcnt--;
            } else {
                require(s.incnt < s.input.length, "Inflate: ErrorCode.ERR_NOT_TERMINATED");
                // val = uint256(uint8(s.input[s.incnt]));
                // array length check is skipped
                assembly {
                    val := shr(0xf8, mload(add(add(mload(add(s, 0x40)), 0x20), mload(add(s, 0x60)))))
                }
                s.bitbuf = val >> 1;
                val &= 0x1;
                s.bitcnt = 7;
                s.incnt++;
            }
            return val;
        }
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length of stored block
            uint256 len;

            // Discard leftover bits from current byte (assumes s.bitcnt < 8)
            s.bitbuf = 0;
            s.bitcnt = 0;

            // Get length and check against its one's complement
            if (s.incnt + 4 > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            len = uint256(uint8(s.input[s.incnt++]));
            len |= uint256(uint8(s.input[s.incnt++])) << 8;

            if (uint8(s.input[s.incnt++]) != (~len & 0xFF) || uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)) {
                // Didn't match complement!
                return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
            }

            // Copy len bytes from in to out
            if (s.incnt + len > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            if (s.outcnt + len > s.output.length) {
                // Not enough output space
                return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            while (len != 0) {
                // Note: Solidity reverts on underflow, so we decrement here
                len -= 1;
                s.output[s.outcnt++] = s.input[s.incnt++];
            }

            // Done with a valid stored block
            return ErrorCode.ERR_NONE;
        }
    }

    function _decode(State memory s, Huffman memory h) private pure returns (uint256) {
        unchecked {
            // Current number of bits in code
            uint256 len;
            // Len bits being decoded
            uint256 code = 0;
            // First code of length len
            uint256 first = 0;
            // Number of codes of length len
            uint256 count;
            // Index of first code of length len in symbol table
            uint256 index = 0;

            for (len = 1; len <= MAXBITS; len += 5) {
                // Get next bit
                code |= bits1(s);
                count = h.counts[len];

                // If length len, return symbol
                if (code < first + count) {
                    return h.symbols[index + (code - first)];
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                code |= bits1(s);
                count = h.counts[len + 1];

                // If length len, return symbol
                if (code < first + count) {
                    return h.symbols[index + (code - first)];
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                code |= bits1(s);
                count = h.counts[len + 2];

                // If length len, return symbol
                if (code < first + count) {
                    return h.symbols[index + (code - first)];
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                code |= bits1(s);
                count = h.counts[len + 3];

                // If length len, return symbol
                if (code < first + count) {
                    return h.symbols[index + (code - first)];
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                code |= bits1(s);
                count = h.counts[len + 4];

                // If length len, return symbol
                if (code < first + count) {
                    return h.symbols[index + (code - first)];
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;
            }

            // Ran out of codes
            revert("Inflate: ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE");
        }
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        unchecked {
            // Current symbol when stepping through lengths[]
            uint256 symbol;
            // Current length when stepping through h.counts[]
            uint256 len;
            // Number of possible codes left of current length
            uint256 left;
            // Offsets in symbol table for each length
            uint256[MAXBITS + 1] memory offs;

            // Count number of codes of each length
            for (len = 0; len <= MAXBITS; ++len) {
                h.counts[len] = 0;
            }
            for (symbol = 0; symbol < n; ++symbol) {
                // Assumes lengths are within bounds
                ++h.counts[lengths[start + symbol]];
            }
            // No codes!
            if (h.counts[0] == n) {
                // Complete, but decode() will fail
                return (ErrorCode.ERR_NONE);
            }

            // Check for an over-subscribed or incomplete set of lengths

            // One possible code of zero length
            left = 1;

            for (len = 1; len <= MAXBITS; len += 5) {
                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 1]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 1];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 2]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 2];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 3]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 3];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 4]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 4];
            }

            // Generate offsets into symbol table for each length for sorting
            offs[1] = 0;
            for (len = 1; len < MAXBITS; ++len) {
                offs[len + 1] = offs[len] + h.counts[len];
            }

            // Put symbols in table sorted by length, by symbol order within each length
            for (symbol = 0; symbol < n; ++symbol) {
                if (lengths[start + symbol] != 0) {
                    h.symbols[offs[lengths[start + symbol]]++] = symbol;
                }
            }

            // Left > 0 means incomplete
            return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
        }
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        unchecked {
            // Decoded symbol
            uint256 symbol;
            // Length for copy
            uint256 len;
            // Distance for copy
            uint256 dist;
            // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
            uint16[118] memory fixedTabs = [
            // Size base for length codes 257..285
            // uint16[29] memory lens = [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258,
            // ];
            // Extra bits for length codes 257..285
            // uint8[29] memory lext = [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0,
            // ];
            // Offset base for distance codes 0..29
            // uint16[30] memory dists = [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577,
            // ];
            // Extra bits for distance codes 0..29
            // uint8[30] memory dext = [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];

            // Decode literals and length/distance pairs
            while (symbol != 256) {
                symbol = _decode(s, lencode);

                if (symbol < 256) {
                    // Literal: symbol is the byte
                    // Write out the literal
                    if (s.outcnt == s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    // s.output[s.outcnt] = bytes1(uint8(symbol));
                    // array length check is skipped
                    // symbol range trimming is skipped because symbol < 256
                    assembly {
                        mstore8(add(add(mload(s), 0x20), mload(add(s, 0x20))), symbol)
                    }
                    ++s.outcnt;
                } else if (symbol > 256) {
                    // Length
                    // Get and compute length
                    symbol -= 257;
                    if (symbol >= 29) {
                        // Invalid fixed code
                        return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                    }

                    len = fixedTabs[symbol] + bits(s, fixedTabs[29 + symbol]);

                    // Get and check distance
                    symbol = _decode(s, distcode);
                    dist = fixedTabs[58 + symbol] + bits(s, fixedTabs[88 + symbol]);
                    if (dist > s.outcnt) {
                        // Distance too far back
                        return ErrorCode.ERR_DISTANCE_TOO_FAR;
                    }

                    // Copy length bytes from distance bytes back
                    if (s.outcnt + len > s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    uint256 pointer;
                    assembly {
                        pointer := add(add(mload(s), 0x20), mload(add(s, 0x20)))
                    }
                    s.outcnt += len;
                    if (dist < len && dist < 32) {  // copy dist bytes
                        uint256 mask;
                        assembly {
                            mask := shr(mul(dist, 8), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                        }
                        while (len > dist) {
                            assembly {
                                mstore(pointer,
                                    or(
                                        and(mload(sub(pointer, dist)), not(mask)),
                                        and(mload(pointer), mask)
                                    )
                                )
                            }
                            pointer += dist;
                            len -= dist;
                        }
                    } else {  // copy 32 bytes
                        while (len > 32) {
                            assembly {
                                mstore(pointer, mload(sub(pointer, dist)))
                            }
                            pointer += 32;
                            len -= 32;
                        }
                    }
                    assembly {  // copy left
                        let mask := shr(mul(len, 8), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                        mstore(pointer,
                            or(
                                and(mload(sub(pointer, dist)), not(mask)),
                                and(mload(pointer), mask)
                            )
                        )
                    }
                } else {
                    s.outcnt += len;
                }
            }

            // Done with a valid fixed or dynamic block
            return ErrorCode.ERR_NONE;
        }
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Build fixed Huffman tables

            // _construct(s.lencode, lengths, FIXLCODES, 0);
            for (uint256 symbol = 0; symbol < 144; ++symbol) { // 8
                s.lencode.symbols[symbol + 24] = symbol;
            }
            for (uint256 symbol = 144; symbol < 256; ++symbol) { // 9
                s.lencode.symbols[symbol + FIXLCODES - 256] = symbol;
            }
            for (uint256 symbol = 256; symbol < 280; ++symbol) { // 7
                s.lencode.symbols[symbol - 256] = symbol;
            }
            for (uint256 symbol = 280; symbol < FIXLCODES; ++symbol) { // 8
                s.lencode.symbols[symbol - 112] = symbol;
            }
            s.lencode.counts[7] = 280 - 256;
            s.lencode.counts[8] = 144 + FIXLCODES - 280;
            s.lencode.counts[9] = 256 - 144;

            // _construct(s.distcode, lengths, MAXDCODES, 0);
            for (uint256 symbol = 0; symbol < MAXDCODES; ++symbol) {
                s.distcode.symbols[symbol] = symbol;
            }
            s.distcode.counts[5] = MAXDCODES;

            return ErrorCode.ERR_NONE;
        }
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Decode data until end-of-block code
            return _codes(s, s.lencode, s.distcode);
        }
    }

    function _build_dynamic_lengths(State memory s) private pure returns (ErrorCode, uint256[] memory) {
        unchecked {
            uint256 ncode;
            // Index of lengths[]
            uint256 index;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Permutation of code length codes
            uint8[19] memory order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

            ncode = bits(s, 4) + 4;

            // Read code length code lengths (really), missing lengths are zero
            for (index = 0; index < ncode; ++index) {
                lengths[order[index]] = bits(s, 3);
            }
            for (; index < 19; ++index) {
                lengths[order[index]] = 0;
            }

            return (ErrorCode.ERR_NONE, lengths);
        }
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        unchecked {
            // Number of lengths in descriptor
            uint256 nlen;
            uint256 ndist;
            // Index of lengths[]
            uint256 index;
            // Error code
            ErrorCode err;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Length and distance codes
            Huffman memory lencode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
            Huffman memory distcode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));

            // Get number of lengths in each table, check lengths
            nlen = bits(s, 5) + 257;
            ndist = bits(s, 5) + 1;

            if (nlen > MAXLCODES || ndist > MAXDCODES) {
                // Bad counts
                return (ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, lencode, distcode);
            }

            (err, lengths) = _build_dynamic_lengths(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }

            // Build huffman table for code lengths codes (use lencode temporarily)
            err = _construct(lencode, lengths, 19, 0);
            if (err != ErrorCode.ERR_NONE) {
                // Require complete code set here
                return (ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE, lencode, distcode);
            }

            // Read length/literal and distance code length tables
            index = 0;
            while (index < nlen + ndist) {
                // Decoded value
                uint256 symbol;
                // Last length to repeat
                uint256 len;

                symbol = _decode(s, lencode);

                if (symbol < 16) {
                    // Length in 0..15
                    lengths[index++] = symbol;
                } else {
                    // Repeat instruction
                    // Assume repeating zeros
                    len = 0;
                    if (symbol == 16) {
                        // Repeat last length 3..6 times
                        if (index == 0) {
                            // No last length!
                            return (ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH, lencode, distcode);
                        }
                        // Last length
                        len = lengths[index - 1];
                        symbol = 3 + bits(s, 2);
                    } else if (symbol == 17) {
                        // Repeat zero 3..10 times
                        symbol = 3 + bits(s, 3);
                    } else {
                        // == 18, repeat zero 11..138 times
                        symbol = 11 + bits(s, 7);
                    }

                    if (index + symbol > nlen + ndist) {
                        // Too many lengths!
                        return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                    }
                    while (symbol != 0) {
                        // Note: Solidity reverts on underflow, so we decrement here
                        symbol -= 1;

                        // Repeat last or zero symbol times
                        lengths[index++] = len;
                    }
                }
            }

            // Check for end-of-block code -- there better be one!
            if (lengths[256] == 0) {
                return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
            }

            // Build huffman table for literal/length codes
            err = _construct(lencode, lengths, nlen, 0);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    nlen != lencode.counts[0] + lencode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, lencode, distcode);
            }

            // Build huffman table for distance codes
            err = _construct(distcode, lengths, ndist, nlen);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    ndist != distcode.counts[0] + distcode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS, lencode, distcode);
            }

            return (ErrorCode.ERR_NONE, lencode, distcode);
        }
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length and distance codes
            Huffman memory lencode;
            Huffman memory distcode;
            // Error code
            ErrorCode err;

            (err, lencode, distcode) = _build_dynamic(s);
            if (err != ErrorCode.ERR_NONE) {
                return err;
            }

            // Decode data until end-of-block code
            return _codes(s, lencode, distcode);
        }
    }

    function puff(bytes memory source, uint256 destlen) internal pure returns (ErrorCode, bytes memory) {
        unchecked {
            // Input/output state
            State memory s = State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
            // Temp: last bit
            uint256 last;
            // Temp: block type bit
            uint256 t;
            // Error code
            ErrorCode err;

            // Build fixed Huffman tables
            err = _build_fixed(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Process blocks until last block or error
            while (last == 0) {
                // One if last block
                last = bits1(s);

                // Block type 0..3
                t = bits(s, 2);

                err = (
                    t == 0
                        ? _stored(s)
                        : (t == 1 ? _fixed(s) : (t == 2 ? _dynamic(s) : ErrorCode.ERR_INVALID_BLOCK_TYPE))
                );
                // type == 3, invalid

                if (err != ErrorCode.ERR_NONE) {
                    // Return with error
                    break;
                }
            }

            return (err, s.output);
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}