// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import "./IRenderer.sol";

pragma solidity ^0.8.0;

contract Moonbirds {
    IRenderer private renderer;

    struct AdjustedIds {
        uint256 bodyId;
        uint256 beakId;
        uint256 eyeId;
        uint256 accessoryId;
    }

    uint8 constant X_DIM = 27;
    uint8 constant Y_DIM = 40;
    uint256 constant TOTAL_PIXELS = 1080;

    uint256[] private body;
    uint256[][4] private bodyPalettes;

    uint256[][2] private beaks;
    uint256[][4] private beakPalettes;
    uint8[5] idToPalette;
    uint8[5] idToLayer;

    uint256[][2] private eyes;
    uint256[][4] private eyePalettes;

    uint256[][2] private accessories;
    uint256[][4] private accessoryPalettes;

    uint256[5] backgrounds;

    constructor(address _renderer) {
        renderer = IRenderer(_renderer);

        // Body
        body = [
            0x0528357241108112252825624110a1254815423120d12562113020f1716a0084,
            0x2311031141765476312411041163725663713124110511225382582511061122,
            0x773172317841312111031176317431773221110311747f312211031178527831,
            0x1102117932763323110211737f3223110211747f3222110211747f3222110211,
            0x5222392253241102112332783322512411021121327c332511021131717f3224,
            0x1221535f261221535f261221535f261221535f26110111215429552511011121,
            0x1121535f261221535f26
        ];
        bodyPalettes[0] = [0x63676bebe4daf5efe633394072706aa4a09924282e000000];
        bodyPalettes[1] = [0x694b6be3aaf0e9c8f730183b492d6b7549ab3b235c000000];
        bodyPalettes[2] = [0x63676bebe4daf5efe633394072706aa4a09924282e000000];
        bodyPalettes[3] = [0x694b6be3aaf0e9c8f730183b492d6b7549ab3b235c000000];

        beaks[0] = [0x1128f4614883d1c614493d22b20034];
        beaks[1] = [0x88a1e4848f22c5091103c8b2424438f23058a122207932cd0044];

        beakPalettes[0] = [0x818a8e63676b000000];
        beakPalettes[1] = [0xc45a6c7d414b361616];
        beakPalettes[2] = [0xfabb72f68f52d7681c963519];
        beakPalettes[3] = [0xda72fae652f6b21cd7811996];

        eyes[0] = [
            0x08549086430a921108632108863210e8591264842216449921105c21828e0054,
            0x241090521
        ];

        eyes[1] = [
            0x022108a2a3051110e450b1484421142c521110452110c45211145041423f0054,
            0x144595222188b2a4444116c442116c4439145091110845142444439145460a2,
            0x050414
        ];

        // red eyes
        eyePalettes[0] = [0xffffff000000f89a77e14249581412];
        // purple eyes
        eyePalettes[1] = [0xffffffdd9eff8965d12d1166000000];
        // green eyes
        eyePalettes[2] = [0xffffff0000008af8774fe1421d5812];
        // yellow eyes
        eyePalettes[3] = [0xfffffffffa9ed1cc65665f11000000];

        // beanie
        accessories[0] = [
            0x022148a26709d22221c9216509ca222289216505ba1243493726087971190044,
            0x64458c1230890325088c223088c223088c12884883228489f484429142c5fa3,
            0x444509102458914445111444511144451114446091024609164459116445911,
            0x048192023caa122048a1247d091
        ];

        // hair
        accessories[1] = [
            0x082860d184468911a45341a30890d22c5342a24408f2285ac2220c7980c80054,
            0x08a8881e928861e452510b4488e229215622348a48b460d122308a4
        ];

        // red beanie
        accessoryPalettes[0] = [0xef6a70e14249a22f2e581412];
        // blue beanie
        accessoryPalettes[1] = [0x6a6cef4542e12e38a2191258];
        // pink hair
        accessoryPalettes[2] = [0xc628c6de58def8cff8f4a0f4582159];
        // green hair
        accessoryPalettes[3] = [0x28c64558de68cff8d9a0f4a321592a];

        idToLayer[0] = 0;
        idToLayer[1] = 0;
        idToLayer[2] = 1;
        idToLayer[3] = 1;

        idToPalette[0] = 0;
        idToPalette[1] = 1;
        idToPalette[2] = 2;
        idToPalette[3] = 3;

        backgrounds[1] = 0xfbb7db;
        backgrounds[2] = 0xf4cc71;
        backgrounds[3] = 0x9bcefe;
        backgrounds[4] = 0x95daae;
    }

    function render(
        uint256 bodyId,
        uint256 beakId,
        uint256 eyeId,
        uint256 accessoryId,
        uint256 backgroundId
    ) external view returns (string memory svg) {
        require(bodyId > 0 && bodyId < 5, "body ID must be between 1 and 4");
        require(beakId > 0 && bodyId < 5, "beak ID must be between 1 and 4");
        require(eyeId > 0 && bodyId < 5, "eye ID must be between 1 and 4");
        require(accessoryId < 5, "accessory ID must be 4 or less");
        require(backgroundId < 5, "accessory ID must be 4 or less");

        AdjustedIds memory ids = AdjustedIds(
            bodyId - 1,
            beakId - 1,
            eyeId - 1,
            accessoryId - 1
        );

        uint256[] memory palette = bodyPalettes[idToPalette[ids.bodyId]];

        // start with body canvas
        uint256[] memory canvas = body;

        // combine current canvas palette with beak palette
        palette = renderer.composePalettes(
            palette,
            beakPalettes[idToPalette[ids.beakId]],
            renderer.getColorCount(canvas),
            renderer.getColorCount(beaks[idToLayer[ids.beakId]])
        );

        // combine current canvas with beak
        canvas = renderer.composeLayers(
            canvas,
            beaks[idToLayer[ids.beakId]],
            TOTAL_PIXELS
        );

        // combine current canvas palette with eye palette
        palette = renderer.composePalettes(
            palette,
            eyePalettes[idToPalette[ids.eyeId]],
            renderer.getColorCount(canvas),
            renderer.getColorCount(eyes[idToLayer[ids.eyeId]])
        );

        // combine current canvas with eyes
        canvas = renderer.composeLayers(
            canvas,
            eyes[idToLayer[ids.eyeId]],
            TOTAL_PIXELS
        );

        if (accessoryId > 0) {
            // combine current canvas palette with accessory palette
            palette = renderer.composePalettes(
                palette,
                accessoryPalettes[idToPalette[ids.accessoryId]],
                renderer.getColorCount(canvas),
                renderer.getColorCount(accessories[idToLayer[ids.accessoryId]])
            );

            // combine current canvas with accessory
            canvas = renderer.composeLayers(
                canvas,
                accessories[idToLayer[ids.accessoryId]],
                TOTAL_PIXELS
            );
        }

        return
            renderer.uriSvg(
                renderer.render(
                    canvas,
                    palette,
                    X_DIM,
                    Y_DIM,
                    backgrounds[backgroundId]
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRenderer {
    /**
     * @dev Returns an svg from a "pixels" array (produced by encodeColorArray)
     */
    function render(
        uint256[] memory pixels,
        uint256[] memory pallette,
        uint256 xDim,
        uint256 yDim,
        uint256 backgroundColor
    ) external view returns (string memory svg);

    /**
     * @dev Compresses and encodes an array of pixels into an array of uint256s".
     */
    function encodeColorArray(
        uint256[] memory colors,
        uint256 pixelCompression,
        uint256 colorCount
    ) external pure returns (uint256[] memory encoded);

    /**
     * @dev Composes 2 palettes together into one palette.
     */

    function composePalettes(
        uint256[] memory palette1,
        uint256[] memory palette2,
        uint256 colorCount1,
        uint256 colorCount2
    ) external view returns (uint256[] memory composedPalette);

    /**
     * @dev Composes 2 encodeded layers together into one image encoding.
     */

    function composeLayers(
        uint256[] memory layer1,
        uint256[] memory layer2,
        uint256 totalPixels
    ) external pure returns (uint256[] memory comp);

    function getColorCount(uint256[] memory layer)
        external
        view
        returns (uint256 colorCount);

    function toString(uint256 value) external pure returns (string memory);

    function toHexString(uint256 value) external pure returns (string memory);

    function base64Encode(bytes memory data)
        external
        pure
        returns (string memory);

    function uri(string memory data) external pure returns (string memory);

    function uriSvg(string memory data) external pure returns (string memory);
}