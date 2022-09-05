// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Base64} from "./libraries/Base64.sol";
import {IDetail} from "./interfaces/IDetail.sol";
import {NFTDescriptor} from "./NFTDescriptor.sol";
import {DetailHelper} from "./libraries/DetailHelper.sol";

contract OniiChainDescriptor is NFTDescriptor {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Max value for defining probabilities
    uint256 internal constant MAX = 100000;

    bytes32 internal constant SEQ =
        0xc2478f9160e5c21a7c5418d527e74e12cd57cd71dc5f3ee3399b47ca4bb61853;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    uint256[] internal BACKGROUND_ITEMS = [
        3130,
        2830,
        2600,
        2300,
        2050,
        1825,
        1500,
        0
    ];
    uint256[] internal SKIN_ITEMS = [20000, 10000, 0]; // 80%, 10%, 10%
    uint256[] internal NOSE_ITEMS = [500, 0]; // 99.5%, 0.5%
    uint256[] internal MARK_ITEMS = [
        70000, // 30%
        60000, // 10%
        50000, // 10%
        40000, // 10%
        32000, // 8%
        24000, // 8%
        16000, // 8%
        11000, // 5%
        8000, // 3%
        5000, // 3%
        3000, // 2%
        1000, // 2%
        0 // 1%
    ];
    uint256[] internal EYEBROW_ITEMS = [65000, 40000, 20000, 10000, 4000, 0]; // 35%, 25%, 20%, 10%, 6%, 4%
    uint256[] internal MASK_ITEMS = [
        20000, // 80%
        16000, // 4%
        12000, // 4%
        8000, // 4%
        4000, // 4%
        2000, // 2%
        1000, // 1%
        0 // 1%
    ];
    uint256[] internal EARRINGS_ITEMS = [
        70000, // 30%
        62000, // 8%
        54000, // 8%
        46000, // 8%
        38000, // 8%
        30000, // 8%
        22000, // 8%
        15000, // 7%
        10000, // 5%
        5000, // 5%
        1000, // 4%
        0 // 1%
    ];
    uint256[] internal ACCESSORY_ITEMS = [
        55000, // 45%
        48000, // 7%
        41000, // 7%
        34000, // 7%
        28000, // 6%
        24000, // 4%
        20000, // 4%
        16000, // 4%
        12000, // 4%
        8000, // 4%
        5000, // 3%
        2000, // 3%
        500, // 1.5%
        10, // 0.49%
        0 // 0.01%
    ];
    uint256[] internal MOUTH_ITEMS = [
        92000, // 8%
        84000, // 8%
        76000, // 8%
        68000, // 8%
        60000, // 8%
        52000, // 8%
        44000, // 8%
        36000, // 8%
        28000, // 8%
        20000, // 8%
        12000, // 8%
        6000, // 6%
        2000, // 4%
        0 // 2%
    ];
    uint256[] internal HAIR_ITEMS = [
        97000, // 3%
        94000, // 3%
        91000, // 3%
        88000, // 3%
        85000, // 3%
        82000, // 3%
        79000, // 3%
        76000, // 3%
        73000, // 3%
        70000, // 3%
        67000, // 3%
        64000, // 3%
        61000, // 3%
        58000, // 3%
        55000, // 3%
        52000, // 3%
        49000, // 3%
        46000, // 3%
        43000, // 3%
        40000, // 3%
        37000, // 3%
        34000, // 3%
        31000, // 3%
        28000, // 3%
        25000, // 3%
        22000, // 3%
        19000, // 3%
        16000, // 3%
        13000, // 3%
        10000, // 3%
        3000, // 7%
        1000, // 2%
        0 // 1%
    ];
    uint256[] internal EYE_ITEMS = [
        97000, // 3%
        94000, // 3%
        91000, // 3%
        88000, // 3%
        85000, // 3%
        82000, // 3%
        79000, // 3%
        76000, // 3%
        73000, // 3%
        70000, // 3%
        67000, // 3%
        64000, // 3%
        61000, // 3%
        58000, // 3%
        55000, // 3%
        52000, // 3%
        49000, // 3%
        46000, // 3%
        43000, // 3%
        40000, // 3%
        37000, // 3%
        34000, // 3%
        31000, // 3%
        28000, // 3%
        25000, // 3%
        22000, // 3%
        19000, // 3%
        16000, // 3%
        13000, // 3%
        10000, // 3%
        7000, // 3%
        4000, // 3%
        1000, // 1%
        0 // 1%
    ];

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        IDetail _bodyDetail,
        IDetail _hairDetail,
        IDetail _noseDetail,
        IDetail _eyesDetail,
        IDetail _markDetail,
        IDetail _maskDetail,
        IDetail _mouthDetail,
        IDetail _eyebrowDetail,
        IDetail _earringsDetail,
        IDetail _accessoryDetail,
        IDetail _backgroundDetail
    )
        NFTDescriptor(
            _bodyDetail,
            _hairDetail,
            _noseDetail,
            _eyesDetail,
            _markDetail,
            _maskDetail,
            _mouthDetail,
            _eyebrowDetail,
            _earringsDetail,
            _accessoryDetail,
            _backgroundDetail
        )
    {}

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Generate full SVG for a given tokenId
    /// @param tokenId The Onii tokenID
    /// @param owner Onii owner address
    /// @return The full SVG (image, name, description,...)
    function tokenURI(uint256 tokenId, address owner)
        external
        view
        returns (string memory)
    {
        // Get SVGParams based on tokenID
        NFTDescriptor.SVGParams memory params = getSVGParams(tokenId);

        // Generate SVG Image
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        string memory name = NFTDescriptor.generateName(params, tokenId);
        string memory description = NFTDescriptor.generateDescription(owner);
        string memory attributes = NFTDescriptor.generateAttributes(params);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "attributes":',
                                attributes,
                                ', "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getSVG(uint256 tokenId) external view returns (string memory) {
        // Get SVGParams based on tokenID
        NFTDescriptor.SVGParams memory params = getSVGParams(tokenId);

        // Compute background id based on items probabilities
        params.background = getBackgroundId(params);

        return NFTDescriptor.generateSVGImage(params);
    }

    /// @dev Get SVGParams struct from the tokenID
    /// @param tokenId The Onii TokenID
    /// @return The NFTDescription.SVGParams struct
    function getSVGParams(uint256 tokenId)
        public
        view
        returns (NFTDescriptor.SVGParams memory)
    {
        NFTDescriptor.SVGParams memory params = NFTDescriptor.SVGParams({
            hair: generateHairId(
                tokenId,
                uint256(keccak256(abi.encode("onii.hair", SEQ)))
            ),
            eye: generateEyeId(
                tokenId,
                uint256(keccak256(abi.encode("onii.eye", SEQ)))
            ),
            eyebrow: generateEyebrowId(
                tokenId,
                uint256(keccak256(abi.encode("onii.eyebrown", SEQ)))
            ),
            nose: generateNoseId(
                tokenId,
                uint256(keccak256(abi.encode("onii.nose", SEQ)))
            ),
            mouth: generateMouthId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mouth", SEQ)))
            ),
            mark: generateMarkId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mark", SEQ)))
            ),
            earring: generateEarringsId(
                tokenId,
                uint256(keccak256(abi.encode("onii.earrings", SEQ)))
            ),
            accessory: generateAccessoryId(
                tokenId,
                uint256(keccak256(abi.encode("onii.accessory", SEQ)))
            ),
            mask: generateMaskId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mask", SEQ)))
            ),
            skin: generateSkinId(
                tokenId,
                uint256(keccak256(abi.encode("onii.skin", SEQ)))
            ),
            background: 0
        });

        params.background = getBackgroundId(params);

        return params;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PRIVATE FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function generateHairId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, HAIR_ITEMS, tokenId);
    }

    function generateEyeId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EYE_ITEMS, tokenId);
    }

    function generateEyebrowId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EYEBROW_ITEMS, tokenId);
    }

    function generateNoseId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, NOSE_ITEMS, tokenId);
    }

    function generateMouthId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MOUTH_ITEMS, tokenId);
    }

    function generateMarkId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MARK_ITEMS, tokenId);
    }

    function generateEarringsId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EARRINGS_ITEMS, tokenId);
    }

    function generateAccessoryId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, ACCESSORY_ITEMS, tokenId);
    }

    function generateMaskId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MASK_ITEMS, tokenId);
    }

    function generateSkinId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, SKIN_ITEMS, tokenId);
    }

    /// @dev Compute background id based on the params probabilities
    function getBackgroundId(NFTDescriptor.SVGParams memory params)
        private
        view
        returns (uint8)
    {
        if (params.accessory == 15) {
            return 8; // Noface is unreal
        }

        uint256 score = itemScorePosition(params.hair, HAIR_ITEMS) +
            itemScoreProba(params.accessory, ACCESSORY_ITEMS) +
            itemScoreProba(params.earring, EARRINGS_ITEMS) +
            itemScoreProba(params.mask, MASK_ITEMS) +
            itemScorePosition(params.mouth, MOUTH_ITEMS) +
            (itemScoreProba(params.skin, SKIN_ITEMS) / 2) +
            itemScoreProba(params.skin, SKIN_ITEMS) +
            itemScoreProba(params.nose, NOSE_ITEMS) +
            itemScoreProba(params.mark, MARK_ITEMS) +
            itemScorePosition(params.eye, EYE_ITEMS) +
            itemScoreProba(params.eyebrow, EYEBROW_ITEMS);
        return DetailHelper.pickItems(score, BACKGROUND_ITEMS);
    }

    /// @dev Get item score based on his probability
    function itemScoreProba(uint8 item, uint256[] memory ITEMS)
        private
        pure
        returns (uint256)
    {
        uint256 raw = ((item == 1 ? MAX : ITEMS[item - 2]) - ITEMS[item - 1]);
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }

    /// @dev Get item score based on his index
    function itemScorePosition(uint8 item, uint256[] memory ITEMS)
        private
        pure
        returns (uint256)
    {
        uint256 raw = ITEMS[item - 1];
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @dev We need an interface to interact with legacy linked libraries
///      that we don't want to deploy again.
interface IDetail {
    function getItemNameById(uint8 id)
        external
        pure
        returns (string memory name);
}

// SPDX-License-Identifier: Unlicence
pragma solidity ^0.8.13;

import {Strings} from "./libraries/Strings.sol";
import {IDetail} from "./interfaces/IDetail.sol";
import {DetailHelper} from "./libraries/DetailHelper.sol";

/// @notice Helper to generate SVGs
abstract contract NFTDescriptor {
    IDetail public immutable bodyDetail;
    IDetail public immutable hairDetail;
    IDetail public immutable noseDetail;
    IDetail public immutable eyesDetail;
    IDetail public immutable markDetail;
    IDetail public immutable maskDetail;
    IDetail public immutable mouthDetail;
    IDetail public immutable eyebrowDetail;
    IDetail public immutable earringsDetail;
    IDetail public immutable accessoryDetail;
    IDetail public immutable backgroundDetail;

    constructor(
        IDetail _bodyDetail,
        IDetail _hairDetail,
        IDetail _noseDetail,
        IDetail _eyesDetail,
        IDetail _markDetail,
        IDetail _maskDetail,
        IDetail _mouthDetail,
        IDetail _eyebrowDetail,
        IDetail _earringsDetail,
        IDetail _accessoryDetail,
        IDetail _backgroundDetail
    ) {
        bodyDetail = _bodyDetail;
        hairDetail = _hairDetail;
        noseDetail = _noseDetail;
        eyesDetail = _eyesDetail;
        markDetail = _markDetail;
        maskDetail = _maskDetail;
        mouthDetail = _mouthDetail;
        eyebrowDetail = _eyebrowDetail;
        earringsDetail = _earringsDetail;
        accessoryDetail = _accessoryDetail;
        backgroundDetail = _backgroundDetail;
    }

    struct SVGParams {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 mark;
        uint8 earring;
        uint8 accessory;
        uint8 mask;
        uint8 background;
        uint8 skin;
    }

    /// @dev Combine all the SVGs to generate the final image
    function generateSVGImage(SVGParams memory params)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    generateSVGHead(),
                    DetailHelper.getDetailSVG(
                        address(backgroundDetail),
                        params.background
                    ),
                    generateSVGFace(params),
                    DetailHelper.getDetailSVG(
                        address(earringsDetail),
                        params.earring
                    ),
                    DetailHelper.getDetailSVG(address(hairDetail), params.hair),
                    DetailHelper.getDetailSVG(address(maskDetail), params.mask),
                    DetailHelper.getDetailSVG(
                        address(accessoryDetail),
                        params.accessory
                    ),
                    "</svg>"
                )
            );
    }

    /// @dev Combine face items
    function generateSVGFace(SVGParams memory params)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    DetailHelper.getDetailSVG(address(bodyDetail), params.skin),
                    DetailHelper.getDetailSVG(address(markDetail), params.mark),
                    DetailHelper.getDetailSVG(
                        address(mouthDetail),
                        params.mouth
                    ),
                    DetailHelper.getDetailSVG(address(noseDetail), params.nose),
                    DetailHelper.getDetailSVG(address(eyesDetail), params.eye),
                    DetailHelper.getDetailSVG(
                        address(eyebrowDetail),
                        params.eyebrow
                    )
                )
            );
    }

    /// @dev generate Json Metadata name
    function generateName(SVGParams memory params, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    backgroundDetail.getItemNameById(params.background),
                    " Onii ",
                    Strings.toString(tokenId)
                )
            );
    }

    /// @dev generate Json Metadata description
    function generateDescription(address owner)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Owned by ",
                    Strings.toHexString(uint256(uint160(owner)))
                )
            );
    }

    /// @dev generate SVG header
    function generateSVGHead() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
                    ' viewBox="0 0 420 420" style="enable-background:new 0 0 420 420;" xml:space="preserve">'
                )
            );
    }

    /// @dev generate Json Metadata attributes
    function generateAttributes(SVGParams memory params)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "[",
                    getJsonAttribute(
                        "Body",
                        bodyDetail.getItemNameById(params.skin),
                        false
                    ),
                    getJsonAttribute(
                        "Hair",
                        hairDetail.getItemNameById(params.hair),
                        false
                    ),
                    getJsonAttribute(
                        "Mouth",
                        mouthDetail.getItemNameById(params.mouth),
                        false
                    ),
                    getJsonAttribute(
                        "Nose",
                        noseDetail.getItemNameById(params.nose),
                        false
                    ),
                    getJsonAttribute(
                        "Eyes",
                        eyesDetail.getItemNameById(params.eye),
                        false
                    ),
                    getJsonAttribute(
                        "Eyebrow",
                        eyebrowDetail.getItemNameById(params.eyebrow),
                        false
                    ),
                    abi.encodePacked(
                        getJsonAttribute(
                            "Mark",
                            markDetail.getItemNameById(params.mark),
                            false
                        ),
                        getJsonAttribute(
                            "Accessory",
                            accessoryDetail.getItemNameById(params.accessory),
                            false
                        ),
                        getJsonAttribute(
                            "Earrings",
                            earringsDetail.getItemNameById(params.earring),
                            false
                        ),
                        getJsonAttribute(
                            "Mask",
                            maskDetail.getItemNameById(params.mask),
                            false
                        ),
                        getJsonAttribute(
                            "Background",
                            backgroundDetail.getItemNameById(params.background),
                            true
                        ),
                        "]"
                    )
                )
            );
    }

    /// @dev Get the json attribute as
    ///    {
    ///      "trait_type": "Skin",
    ///      "value": "Human"
    ///    }
    function getJsonAttribute(
        string memory trait,
        string memory value,
        bool end
    ) private pure returns (string memory json) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type" : "',
                    trait,
                    '", "value" : "',
                    value,
                    '" }',
                    end ? "" : ","
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Strings} from "./Strings.sol";

/// @title Helper for details generation
library DetailHelper {
    /// @notice Call the library item function
    /// @param lib The library address
    /// @param id The item ID
    function getDetailSVG(address lib, uint8 id)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = lib.staticcall(
            abi.encodeWithSignature(
                string(abi.encodePacked("item_", Strings.toString(id), "()"))
            )
        );
        require(success);
        return abi.decode(data, (string));
    }

    /// @notice Generate a random number and return the index from the
    ///         corresponding interval.
    /// @param max The maximum value to generate
    /// @param seed Used for the initialization of the number generator
    /// @param intervals the intervals
    /// @param tokenId the current tokenId
    function generate(
        uint256 max,
        uint256 seed,
        uint256[] memory intervals,
        uint256 tokenId
    ) internal pure returns (uint8) {
        uint256 generated = (uint256(
            keccak256(abi.encodePacked(seed, tokenId))
        ) % (max + 1)) + 1;
        return pickItems(generated, intervals);
    }

    /// @notice Pick an item for the given random value
    /// @param val The random value
    /// @param intervals The intervals for the corresponding items
    /// @return the item ID where : intervals[] index + 1 = item ID
    function pickItems(uint256 val, uint256[] memory intervals)
        internal
        pure
        returns (uint8)
    {
        require(intervals.length <= type(uint8).max, "INTERVAL_NOT_8BITS");

        for (uint256 i; i < intervals.length; i++) {
            if (val > intervals[i]) {
                return uint8(i + 1);
            }
        }
        revert("DetailHelper::pickItems: No item");
    }
}

// SPDX-License-Identifier: Unlicence
pragma solidity ^0.8.13;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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