// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * #######################################   ######################################
 * #####################################       ####################################
 * ###################################           ##################################
 * #################################               ################################
 * ################################################################################
 * ################################################################################
 * ################       ####                           ###        ###############
 * ################      ####        #############        ####      ###############
 * ################     ####          ###########          ####     ###############
 * ################    ###     ##       #######       ##    ####    ###############
 * ################  ####    ######      #####      ######    ####  ###############
 * ################ ####                                       #### ###############
 * ####################                #########                ###################
 * ################                     #######                     ###############
 * ################   ###############             ##############   ################
 * #################   #############               ############   #################
 * ###################   ##########                 ##########   ##################
 * ####################    #######                   #######    ###################
 * ######################     ###                     ###    ######################
 * ##########################                             #########################
 * #############################                       ############################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 *
 * The Mutytes have invaded Ethernia! We hereby extend access to the lab and
 * its facilities to any individual or party that may locate and retrieve a
 * Mutyte sample. We believe their mutated Bit Signatures hold the key to
 * unraveling many great mysteries.
 * Join our efforts in understanding these creatures and witness Ethernia's
 * future unfold.
 *
 * Founders: @nftyte & @tuyumoo
 */

import "../mutations/IMutationInterpreter.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/Buffers.sol";
import "./data/Labels.sol";
import "./data/Colors.sol";
import "./data/Materials.sol";
import "./data/Models.sol";
import "./data/Traits.sol";
import "./data/Renderable.sol";

contract MutyteInterpreter is IMutationInterpreter, Ownable {
    using Strings for uint256;
    using Buffers for Buffers.Writer;
    using Paths for Paths.Path;

    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external pure override returns (string memory) {
        Renderable.Mutyte memory mutyte = Renderable.fromDNA(
            token.dna.length > 0 ? token.dna[0] : 0
        );
        (string memory image, string memory attrs) = _render(mutyte, mutation);
        (
            string memory name,
            string memory description,
            string memory url
        ) = _getInfo(token, mutation, externalURL);

        return _encodeMetaData(name, description, url, image, attrs);
    }

    function _getInfo(
        TokenData memory token,
        MutationData memory mutation,
        string memory externalURL
    )
        private
        pure
        returns (
            string memory name,
            string memory description,
            string memory url
        )
    {
        string memory tokenIdStr = token.id.toString();
        string memory mutyteName = bytes(token.name).length > 0
            ? token.name
            : string.concat("Mutyte #", tokenIdStr);

        return (
            mutyteName,
            string.concat(
                bytes(token.info).length == 0
                    ? "The Mutytes are a collection of 10,101 severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities."
                    : token.info,
                "\\n\\n",
                mutyteName,
                " is exhibiting signs of mutation ",
                bytes(mutation.name).length > 0
                    ? mutation.name
                    : string.concat("#", (mutation.id + 1).toString3()),
                ".",
                bytes(mutation.info).length == 0
                    ? ""
                    : string.concat("\\n", mutation.info)
            ),
            string.concat(externalURL, tokenIdStr)
        );
    }

    function _encodeMetaData(
        string memory name,
        string memory description,
        string memory url,
        string memory image,
        string memory attributes
    ) private pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '","description":"',
                        description,
                        '","external_url":"',
                        url,
                        '","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(image)),
                        '","attributes":[',
                        attributes,
                        "]}"
                    )
                )
            );
    }

    function _render(
        Renderable.Mutyte memory mutyte,
        MutationData memory mutation
    ) private pure returns (string memory, string memory) {
        Buffers.Writer memory attrs = Buffers.getWriter(3200);
        Buffers.Writer memory image = Buffers.getWriter(24000);

        _addMutationAttribute(attrs, mutation.id + 1);
        _addAttribute(attrs, "Mutation Level", mutyte.mutationLevel + 1);
        _addAttribute(attrs, "Unlocked Mutations", mutation.count);

        image.write(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><style>rect:not([fill]){transition:opacity .25s .25s}rect:not([fill]):hover{transition-delay:0s;opacity:.3}</style>'
        );
        _renderBackground(mutyte, image);
        image.write(
            '<g stroke-linecap="round" stroke-linejoin="round" stroke="#000" stroke-width="2">'
        );
        if (!mutyte.legs[0] || mutyte.legs[1]) {
            _renderLegs(0, mutyte, image, attrs);
        }
        _renderEars(mutyte, image, attrs);
        _renderBody(mutyte, image, attrs);
        _renderCheeks(mutyte, image, attrs);
        _renderMouth(mutyte, image, attrs);
        _renderTeeth(mutyte, image, attrs);
        _renderNose(mutyte, image, attrs);
        _renderEyes(mutyte, image, attrs);
        if (mutyte.legs[0] || mutyte.legs[1]) {
            _renderLegs(1, mutyte, image, attrs);
        }
        _renderArms(mutyte, image, attrs);
        image.writeWord("</g></svg>");

        return (image.toString(), attrs.toString());
    }

    function _renderBackground(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image
    ) private pure {
        Materials.Variant memory variant = Materials.get(0).variants[
            mutyte.mutationLevel
        ];
        string memory color1 = Colors.get(variant.colorIds[0]);
        string memory color2 = Colors.get(variant.colorIds[1]);
        image.write('<rect width="256" height="256" fill="', color1, '"/>');

        uint256 shapes = mutyte.bgShapes;
        _renderBackgroundShape((shapes >> 4) & 0xF, color2, image);
        _renderBackgroundShape(shapes & 0xF, color1, image);
        _renderBackgroundPattern(mutyte, image);
    }

    function _renderBackgroundShape(
        uint256 shape,
        string memory color,
        Buffers.Writer memory image
    ) private pure {
        image.writeWords('<path opacity=".5" fill="', color, '" d="M0 128');

        if (shape >> 3 == 1) {
            image.writeWord("V0H128");
        } else {
            image.writeWord("L128 0");
        }

        if ((shape >> 2) & 1 == 1) {
            image.writeWord("H256V128");
        } else {
            image.writeWord("L256 128");
        }

        if ((shape >> 1) & 1 == 1) {
            image.writeWord("V256H128");
        } else {
            image.writeWord("L128 256");
        }

        if (shape & 1 == 1) {
            image.writeWord("H0");
        }

        image.writeWord('Z"/>');
    }

    function _renderBackgroundPattern(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image
    ) private pure {
        image.writeWord('<g fill="#000" opacity=".2">');
        uint256 pid = 64;
        uint256 dna = mutyte.dna;
        uint256 pattern = ((dna << 10) & 0xFFFFE00000000000) |
            ((dna << 8) & 0x7E000000000) |
            ((dna << 6) & 0x7C0000000) |
            ((dna << 2) & 0x3E00000) |
            (dna & 0x7FFFF);

        for (uint256 i; i < 8; i++) {
            string memory y = ((i << 5) + 1).toString3();

            for (uint256 j; j < 8; j++) {
                if ((pattern >> --pid) & 1 == 1) {
                    image.writeWords(
                        '<rect width="30" height="30" x="',
                        ((j << 5) + 1).toString3(),
                        '" y="',
                        y,
                        (pattern >> (63 - pid)) & 1 == 1
                            ? '" opacity=".5"/>'
                            : '"/>'
                    );
                }
            }
        }

        image.writeWord("</g>");
    }

    function _renderBody(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory body = Traits.getBody(mutyte.bodyId);
        Traits.Model[] memory tModels = body.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getBody(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, body, "Body", mutyte.colorId);
    }

    function _renderCheeks(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory cheeks = Traits.getCheeks(mutyte.cheeksId);
        Traits.Model[] memory tModels = cheeks.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getCheeks(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Cheeks", Labels.get(cheeks.nameId));
    }

    function _renderLegs(
        uint256 pid,
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory legs = Traits.getLegs(mutyte.legsId);
        Traits.Model[] memory tModels = legs.parts[pid].models;

        for (uint256 j; j < tModels.length; j++) {
            Traits.Model memory tModel = tModels[j];
            _renderModel(
                image,
                Models.getLegs(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(
            attrs,
            legs,
            pid == 0 ? "Back Legs" : "Front Legs",
            mutyte.colorId
        );
    }

    function _renderArms(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory arms = Traits.getArms(mutyte.armsId);

        for (uint256 i; i < ARMS_PART_COUNT; i++) {
            if (mutyte.arms[i]) {
                Traits.Model[] memory tModels = arms.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getArms(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(
                    attrs,
                    arms,
                    i == 0 ? "Bottom Arms" : "Top Arms",
                    mutyte.colorId
                );
            }
        }
    }

    function _renderEars(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory ears = Traits.getEars(mutyte.earsId);
        string[EARS_PART_COUNT] memory tTypes = [
            "Bottom Left Ear",
            "Bottom Right Ear",
            "Left Ear",
            "Right Ear",
            "Middle Ear"
        ];

        for (uint256 i; i < EARS_PART_COUNT; i++) {
            if (mutyte.ears[i]) {
                Traits.Model[] memory tModels = ears.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getEars(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(attrs, ears, tTypes[i], mutyte.colorId);
            }
        }
    }

    function _renderEyes(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory eyes = Traits.getEyes(mutyte.eyesId);
        string[EYES_PART_COUNT] memory tTypes = [
            "Bottom Left Eye",
            "Bottom Right Eye",
            "Left Eye",
            "Right Eye",
            "Middle Eye",
            "Top Left Eye",
            "Top Right Eye",
            "Top Middle Eye"
        ];

        for (uint256 i; i < EYES_PART_COUNT; i++) {
            if (mutyte.eyes[i]) {
                Traits.Model[] memory tModels = eyes.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getEyes(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(attrs, eyes, tTypes[i], mutyte.colorId);
            }
        }
    }

    function _renderNose(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory nose = Traits.getNose(mutyte.noseId);
        Traits.Model[] memory tModels = nose.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getNose(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Nose", Labels.get(nose.nameId));
    }

    function _renderMouth(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory mouth = Traits.getMouth(mutyte.mouthId);
        Traits.Model[] memory tModels = mouth.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getMouth(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Mouth", Labels.get(mouth.nameId));
    }

    function _renderTeeth(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory teeth = Traits.getTeeth(mutyte.teethId);
        Traits.Model[] memory tModels = teeth.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getTeeth(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Teeth", Labels.get(teeth.nameId));
    }

    function _renderModel(
        Buffers.Writer memory image,
        Models.Model memory model,
        Traits.Model memory tModel,
        uint256 variantId
    ) private pure {
        Materials.Variant[] memory variants = Materials
            .get(model.materialId)
            .variants;
        Materials.Variant memory variant = variants[
            variantId % variants.length
        ];
        image.writeWords(
            '<g transform="translate(',
            tModel.x.toString3(),
            ",",
            tModel.y.toString3(),
            tModel.flip ? ') scale(-1,1)">' : ')">'
        );

        for (uint256 i; i < model.paths.length; i++) {
            Paths.Path memory path = model.paths[i];
            image.writeWord('<path d="');
            image.write(path.d);
            image.writeWords(
                path.stroke ? "" : '" stroke="none',
                '" fill="',
                path.fill ? Colors.get(variant.colorIds[path.fillId]) : "none",
                '"/>'
            );
        }

        image.writeWord("</g>");
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        Traits.Trait memory trait,
        string memory tType,
        uint256 colorId
    ) private pure {
        string memory label = Labels.get(trait.nameId);
        Materials.Variant[] memory variants = Materials
            .get(trait.materialId)
            .variants;

        label = string.concat(
            Labels.get(variants[colorId % variants.length].nameId),
            " ",
            label
        );

        _addAttribute(attrs, tType, label);
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        string memory tType,
        string memory value
    ) private pure {
        attrs.writeWords(',{"trait_type":"', tType, '","value":"');
        attrs.write(value);
        attrs.writeWord('"}');
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        string memory tType,
        uint256 value
    ) private pure {
        attrs.writeWords(',{"trait_type":"', tType, '","value":');
        attrs.write(value.toString());
        attrs.writeWord("}");
    }

    function _addMutationAttribute(
        Buffers.Writer memory attrs,
        uint256 mutation
    ) private pure {
        attrs.write(
            '{"display_type":"number","trait_type":"Mutation Type","value":'
        );
        attrs.writeWord(mutation.toString3());
        attrs.writeChar("}");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMutationInterpreter {
    struct TokenData {
        uint256 id;
        string name;
        string info;
        uint256[] dna;
    }

    struct MutationData {
        uint256 id;
        string name;
        string info;
        uint256 count;
    }

    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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

library Buffers {
    struct Writer {
        uint256 length;
        string buffer;
    }

    bytes1 private constant _SPACE = " ";

    function getWriter(uint256 size) internal pure returns (Writer memory) {
        Writer memory writer;
        writer.buffer = new string(size);

        return writer;
    }

    function write(Writer memory writer, string memory input) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        uint256 length = bytes(input).length;

        assembly {
            for {
                let k := 0
            } lt(k, length) {

            } {
                k := add(k, 0x20)
                mstore(add(add(buffer, offset), k), mload(add(input, k)))
            }
        }

        unchecked {
            writer.length += length;
        }
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        write(writer, a);
        write(writer, b);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
        write(writer, e);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
        write(writer, e);
        write(writer, f);
    }

    function writeChar(Writer memory writer, bytes1 input) internal pure {
        string memory buffer = writer.buffer;

        assembly {
            mstore(add(add(buffer, mload(writer)), 0x20), input)
        }

        unchecked {
            writer.length++;
        }
    }

    function writeWord(Writer memory writer, string memory input)
        internal
        pure
    {
        string memory buffer = writer.buffer;
        uint256 length = bytes(input).length;

        assembly {
            mstore(
                add(add(buffer, mload(writer)), 0x20),
                mload(add(input, 0x20))
            )
        }

        unchecked {
            writer.length += length;
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(bufferPtr, mload(add(f, 0x20)))
            bufferPtr := add(bufferPtr, mload(f))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(f, 0x20)))
            bufferPtr := add(bufferPtr, mload(f))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function toString(Writer memory writer)
        internal
        pure
        returns (string memory)
    {
        string memory buffer = writer.buffer;

        assembly {
            mstore(buffer, mload(writer))
        }

        return buffer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Data.sol";

library Labels {
    using Data for Data.Reader;

    function get(uint256 i) internal pure returns (string memory) {
        bytes
            memory data = "DogOrangeRedGreenBluePurpleYellowWhiteBlackFluffySlimeGreySludgeStoneTreeCrystalCheesePointyRoundStacheBeardHumanoidBullCrabSpiderOctopusMushroomPigBunnyCatEtherealPinkBrownClosedSmilingStokedShockedAnxiousAnguishedHungryPantingNoneSharpGappedFangsLeft FangRight FangBuckStraightLevel 1Level 2Level 3Level 4Level 5Level 6Level 7Level 8";
        bytes
            memory index = "\x00\x00\x00\x03\x00\x09\x00\x0c\x00\x11\x00\x15\x00\x1b\x00\x21\x00\x26\x00\x2b\x00\x31\x00\x36\x00\x3a\x00\x40\x00\x45\x00\x49\x00\x50\x00\x56\x00\x5c\x00\x61\x00\x67\x00\x6c\x00\x74\x00\x78\x00\x7c\x00\x82\x00\x89\x00\x91\x00\x94\x00\x99\x00\x9c\x00\xa4\x00\xa8\x00\xad\x00\xb3\x00\xba\x00\xc0\x00\xc7\x00\xce\x00\xd7\x00\xdd\x00\xe4\x00\xe8\x00\xed\x00\xf3\x00\xf8\x01\x01\x01\x0b\x01\x0f\x01\x17\x01\x1e\x01\x25\x01\x2c\x01\x33\x01\x3a\x01\x41\x01\x48";
        Data.Reader memory reader = Data.Reader(i << 1);

        uint256 start = reader.nextUint16(index);
        uint256 end = ((i + 1) << 1) < index.length
            ? reader.nextUint16(index)
            : data.length;

        return reader.set(start).nextString32(data, end - start);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Data.sol";

library Colors {
    using Data for Data.Reader;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length of 6.
     */
    function _toHexString(uint256 value) private pure returns (string memory) {
        bytes memory buffer = new bytes(7);
        buffer[0] = "#";
        for (uint256 i = 6; i > 0; i--) {
            buffer[i] = _HEX_SYMBOLS[value & 0xF];
            value >>= 4;
        }
        return string(buffer);
    }

    function get(uint256 i) internal pure returns (string memory) {
        bytes
            memory data = "\xec\x8f\x51\xfc\xd6\xbb\xf4\x52\x52\x1e\xdc\x70\x49\xa4\xe9\xc9\xa4\xff\xff\xff\x00\xe0\xf0\xff\x43\x49\x56\xff\x9a\x57\xff\x78\x1f\xff\x7a\x7a\xed\x34\x34\x7a\xff\x95\xa3\xf4\xff\x24\xa0\xff\x9a\x57\xff\xff\xff\x61\xbd\xcf\xe0\xc3\xd1\xbe\x9d\xa8\x99\xc2\xac\x99\xc2\x99\x99\x99\xc2\x9c\x99\x9e\xc2\xa9\xa1\xd1\xc2\xbe\x99\x8e\xa4\xb8\xff\xae\x52\xff\x70\x70\x61\xba\xff\xa4\x72\xee\x56\x5e\x71\xff\x96\x1f\x8f\x4e\x19\xff\x52\x52\x9c\x30\x30\x00\xff\x6e\x2a\xac\x62\x47\xc2\xff\x2a\x62\xac\xd6\x99\xff\x93\x3e\xcc\xab\xa2\x29\x00\x00\x00\xc4\xbc\xa5\xea\xb3\xb3\xd2\xe6\xad\xba\xc2\xfd\xd0\xc7\xff\xe6\xe1\xb3\xff\x9e\x9e\x8f\xce\xff\xfd\xf7\xba\xff\xff\xff\xff\xcd\x1e\x73\x29\x87\x29\x2a\x2e\xe4\xff\xb3\xff\xc2\xc2\x81\x86\x92\xeb\xa7\xe8\xff\x81\xff\xb0\x6d\x00\xff\x36\x7c\x9c\xcd\xe2\x00\x31\x45\x00\x30\x44\x45\xcf\xf2\x00\x4f\x63\x47\xa6\xff\x00\x2f\x5c\x2e\x6d\xff\x0d\x23\x54\x91\xf2\xaa\x00\x3d\x26\x17\xcf\x7f\x00\x4d\x36\xec\xdd\x7e\x63\x5a\x36\x61\x58\x35\xfb\xcd\x28\x5c\x42\x2d";
        Data.Reader memory reader = Data.Reader(i * 3);

        return _toHexString(reader.nextUint24(data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Data.sol";

library Materials {
    using Data for Data.Reader;

    struct Variant {
        uint256 nameId;
        uint256[] colorIds;
    }

    struct Material {
        uint256 colorCount;
        Variant[] variants;
    }

    function _load(uint256 i, bytes memory data)
        private
        pure
        returns (Material memory)
    {
        Material memory mat;
        Data.Reader memory reader = Data.Reader(i);
        uint256 header = reader.nextUint8(data);

        mat.variants = new Variant[](header >> 4);
        mat.colorCount = header & 0xF;

        for (uint256 j; j < mat.variants.length; j++) {
            mat.variants[j].nameId = reader.nextUint8(data);
            mat.variants[j].colorIds = reader.nextUint8Array(
                data,
                mat.colorCount
            );
        }

        return mat;
    }

    function get(uint256 i) internal pure returns (Material memory) {
        bytes
            memory data = "\x83\x31\x41\x42\x43\x32\x44\x45\x36\x33\x46\x47\x47\x34\x48\x49\x36\x35\x4a\x4b\x4b\x36\x4c\x4d\x36\x37\x4e\x4f\x50\x38\x51\x52\x36\x82\x01\x00\x01\x02\x02\x01\x03\x03\x01\x04\x04\x01\x05\x05\x01\x06\x06\x01\x07\x07\x01\x08\x08\x01\x81\x01\x00\x02\x02\x03\x03\x04\x04\x05\x05\x06\x06\x07\x07\x08\x08\x82\x01\x09\x0a\x02\x0b\x0c\x03\x0d\x03\x04\x0e\x0f\x05\x05\x10\x06\x11\x06\x07\x07\x12\x0b\x13\x14\x81\x01\x0a\x02\x0c\x03\x03\x04\x0f\x05\x10\x06\x06\x07\x07\x08\x08\x81\x01\x15\x02\x16\x03\x17\x04\x18\x05\x19\x06\x1a\x07\x12\x0b\x14\x82\x01\x0a\x15\x02\x0c\x16\x03\x03\x17\x04\x0f\x18\x05\x10\x19\x06\x06\x1a\x07\x1b\x07\x08\x08\x14\x83\x01\x1c\x1c\x0a\x02\x1d\x1d\x0c\x03\x0d\x0d\x03\x04\x1e\x1e\x0f\x05\x05\x05\x1f\x06\x11\x11\x06\x07\x07\x07\x12\x08\x08\x20\x14\x82\x01\x21\x22\x02\x23\x24\x03\x25\x26\x04\x27\x28\x05\x29\x2a\x06\x06\x2b\x07\x07\x1b\x08\x08\x14\x81\x01\x00\x02\x02\x03\x03\x04\x04\x05\x05\x06\x06\x07\x07\x08\x08\x85\x01\x00\x01\x03\x2c\x2d\x02\x02\x01\x03\x2c\x2e\x03\x03\x01\x03\x2c\x2f\x04\x04\x01\x03\x2c\x30\x05\x05\x01\x03\x2c\x31\x06\x06\x01\x03\x2c\x32\x07\x07\x01\x03\x2c\x12\x08\x08\x01\x03\x2c\x13\x82\x01\x0a\x15\x02\x0c\x16\x03\x03\x17\x04\x0f\x18\x05\x10\x19\x06\x06\x1a\x07\x07\x1b\x08\x08\x14\x81\x01\x15\x02\x16\x03\x17\x04\x18\x05\x19\x06\x1a\x07\x07\x0b\x14\x82\x01\x0a\x01\x02\x0c\x33\x03\x03\x0d\x04\x0f\x34\x05\x10\x05\x06\x06\x35\x07\x07\x1b\x08\x08\x14\x84\x01\x15\x0a\x01\x36\x02\x16\x0c\x2e\x36\x03\x17\x03\x2f\x36\x04\x18\x0f\x30\x36\x05\x19\x10\x31\x36\x06\x1a\x06\x32\x36\x07\x1b\x07\x12\x08\x08\x14\x08\x13\x36\x82\x01\x00\x01\x02\x02\x01\x03\x03\x01\x04\x04\x01\x05\x05\x01\x06\x06\x01\x07\x07\x01\x08\x08\x01\x82\x01\x00\x01\x02\x02\x01\x03\x03\x01\x04\x04\x01\x05\x05\x01\x06\x06\x01\x07\x07\x01\x08\x08\x01\x42\x07\x36\x2c\x08\x08\x36\x02\x0c\x36\x06\x37\x2c\x32\x06\x37\x2c\x03\x0d\x2c\x02\x23\x2c\x41\x03\x0d\x05\x38\x02\x0c\x06\x37\x32\x08\x08\x03\x03\x03\x39\x07\x36\x39\x42\x03\x03\x3a\x05\x10\x31\x02\x0c\x3b\x0b\x3c\x36\x11\x08\x2c\x11\x01\x00\x12\x1f\x3d\x2c\x11\x1f\x3e\x11\x20\x3f\x11\x1f\x40\x12\x08\x0c\x2c\x11\x07\x36";
        bytes
            memory index = "\x00\x00\x00\x21\x00\x3a\x00\x4b\x00\x64\x00\x75\x00\x86\x00\x9f\x00\xc0\x00\xd9\x00\xea\x01\x1b\x01\x34\x01\x45\x01\x5e\x01\x87\x01\xa0\x01\xb9\x01\xc6\x01\xd0\x01\xd9\x01\xe3\x01\xf0\x01\xf3\x01\xf6\x01\xfa\x01\xfd\x02\x00\x02\x03\x02\x07";
        Data.Reader memory reader = Data.Reader(i << 1);

        return _load(reader.nextUint16(index), data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * #######################################   ######################################
 * #####################################       ####################################
 * ###################################           ##################################
 * #################################               ################################
 * ################################################################################
 * ################################################################################
 * ################       ####                           ###        ###############
 * ################      ####        #############        ####      ###############
 * ################     ####          ###########          ####     ###############
 * ################    ###     ##       #######       ##    ####    ###############
 * ################  ####    ######      #####      ######    ####  ###############
 * ################ ####                                       #### ###############
 * ####################                #########                ###################
 * ################                     #######                     ###############
 * ################   ###############             ##############   ################
 * #################   #############               ############   #################
 * ###################   ##########                 ##########   ##################
 * ####################    #######                   #######    ###################
 * ######################     ###                     ###    ######################
 * ##########################                             #########################
 * #############################                       ############################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 *
 * The Mutytes have invaded Ethernia! We hereby extend access to the lab and
 * its facilities to any individual or party that may locate and retrieve a
 * Mutyte sample. We believe their mutated Bit Signatures hold the key to
 * unraveling many great mysteries.
 * Join our efforts in understanding these creatures and witness Ethernia's
 * future unfold.
 *
 * Founders: @nftyte & @tuyumoo
 */

import "./Paths.sol";
import "../utils/Data.sol";
import "../utils/Buffers.sol";
import "../utils/Strings.sol";

library Models {
    using Strings for uint256;
    using Data for Data.Reader;
    using Buffers for Buffers.Writer;

    bytes private constant _PATH_OP_COORDS =
        "\x00\x00\x01\x01\x01\x01\x01\x00\x00\x01\x03\x03\x02\x02";

    struct Model {
        Paths.Path[] paths;
        uint256 materialId;
    }

    function _loadPath(
        Paths.Path memory path,
        bytes memory data,
        Data.Reader memory reader
    ) private pure {
        (
            uint256 opCount,
            uint256[] memory size,
            uint256 xMin,
            uint256 yMin
        ) = _loadPathHeader(path, data, reader);

        uint256[] memory ops = reader.nextUint3Array(data, opCount);
        bytes memory opTable = _PATH_OP_COORDS;

        uint256 xCount = 1;
        uint256 yCount = 1;

        assembly {
            let table := mload(add(opTable, 0x20))
            for {
                let opsPtr := add(ops, 0x20)
                let endPtr := add(opsPtr, shl(5, opCount))
            } lt(opsPtr, endPtr) {
                opsPtr := add(opsPtr, 0x20)
            } {
                let opi := shl(1, mload(opsPtr))
                xCount := add(xCount, byte(opi, table))
                yCount := add(yCount, byte(add(opi, 1), table))
            }
        }

        uint256[] memory x = reader.nextUintArray(size[0], data, xCount, xMin);
        uint256[] memory y = reader.nextUintArray(size[1], data, yCount, yMin);

        path.d = Paths.getDescription(ops, x, y);
    }

    function _loadPathHeader(
        Paths.Path memory path,
        bytes memory data,
        Data.Reader memory reader
    )
        private
        pure
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        uint256 h1 = reader.nextUint8(data);
        uint256 h2 = reader.nextUint8(data);

        uint256 opCount = h1 >> 3;
        uint256[] memory size = new uint256[](2);
        size[0] = (h1 & 7) + 1;
        size[1] = (h2 >> 5) + 1;
        uint256 xMin;
        uint256 yMin;

        if (size[0] < 8) {
            xMin = reader.nextUint8(data);
        }

        if (size[1] < 8) {
            yMin = reader.nextUint8(data);
        }

        path.fill = (h2 >> 4) & 1 == 1;
        path.fillId = (h2 >> 1) & 7;
        path.stroke = h2 & 1 == 1;

        return (opCount, size, xMin, yMin);
    }

    function _getModel(Data.Reader memory reader, bytes memory data)
        private
        pure
        returns (Model memory)
    {
        Model memory model;

        Paths.Path[] memory paths = model.paths = new Paths.Path[](
            reader.nextUint8(data)
        );
        model.materialId = reader.nextUint8(data);

        for (uint256 j; j < paths.length; j++) {
            _loadPath(paths[j], data, reader);
        }

        return model;
    }

    function getBody(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x01\x01\x4e\xf1\x00\xb6\xdd\x6d\x00\x76\x58\x10\x20\x02\x08\x15\x36\x95\x6b\x97\x72\x68\xdb\xc3\x9b\x77\x6e\x9d\x30\x3b\x9d\x9d\x93\x8b\x50\x2a\x19\x10\x08\x04\x00\x00\x00\x00\x04\x08\x10\x19\x2a\x50\x8b\x93\x9d\x9d\x01\x01\x1d\x93\x00\x00\xb6\x80\xd3\x4a\x28\x75\x83\x0c\x00\x00\x00\x29\x4a\xd6\x94\x00\x00\x01\x02\x8f\xf1\xb6\xdb\xad\xb6\xdd\x55\x00\x79\x7b\x86\x71\x71\x82\x64\x64\x70\x47\x47\x47\x40\x3a\x2d\x2d\x1e\x19\x16\x1f\x1f\x1f\x03\x16\x16\x00\x12\x12\x02\x0f\x0c\x0b\x0c\x0c\x20\x45\x7e\x7e\x7f\x7d\x7b\x7b\x89\x79\x79\x3d\x3c\x3b\x26\x26\x19\x14\x14\x00\x0b\x0b\x04\x03\x02\x10\x10\x0e\x13\x17\x1c\x1c\x1c\x25\x2e\x2e\x42\x40\x40\x55\x52\x64\x7b\x96\x9e\xa8\xa8\x9e\x96\x7b\x64\x52\x52\x53\x3d\x3d\x01\x03\xb6\xf1\x00\xb6\xdb\x6d\xb6\xdb\x6d\xb6\xda\x00\xed\xd7\x9f\x5e\xdd\xb8\xec\xdf\xbf\x86\x9c\xb8\x6f\xde\xb9\x56\x7c\x48\xcf\x19\x34\x52\x8c\xe1\xa3\x25\xc9\x8f\x10\x24\x48\xc0\xe0\x81\x03\x0a\x0c\x10\x00\xe4\x0c\x17\x48\x9d\x6b\x26\xcf\xe3\x4b\xa3\x53\x0e\x0d\x1c\x7c\x76\x81\x7a\x58\x4f\x47\x41\x39\x32\x2e\x2b\x1e\x19\x17\x15\x11\x0e\x07\x04\x05\x07\x00\x00\x00\x07\x05\x04\x07\x0e\x11\x15\x17\x19\x1e\x2b\x2e\x32\x39\x41\x47\x4f\x58\x7a\x81\x94\x97\x99\x9c\xa4\xa0\x9f\x9f\xa3\xa5\xa8\xa3\x9f\x9f\xa0\xa4\x9c\x99\x97\x94\x81\x01\x01\x17\x93\x00\xb8\x2c\x2c\x28\x16\x00\x00\x00\x33\x90\x00\x06\x04\xbf\xf1\xb6\xab\x6d\xb6\xdb\x6d\xb6\xdb\x40\x85\x85\x82\x7d\x74\x6e\x68\x5d\x56\x53\x53\x4a\x42\x3d\x3a\x33\x28\x23\x1a\x13\x0f\x0d\x0d\x00\x00\x09\x10\x13\x12\x12\x0d\x0b\x08\x0f\x17\x1d\x1c\x1c\x19\x19\x1b\x1d\x24\x2f\x40\x58\x68\x70\x74\x76\x7c\x82\x85\x8a\x86\x80\x80\x7e\x86\x8a\x8d\x8d\x8d\x89\x85\x95\x95\x9a\x9c\xa0\x9a\x9d\xa3\xa1\x9f\x9f\x9c\x9d\x9f\xa1\xa3\x9d\x9a\x9f\x9c\x9a\x96\x96\x98\x88\x7a\x6e\x5b\x49\x49\x48\x42\x39\x33\x2b\x25\x22\x22\x21\x1e\x1a\x15\x0e\x09\x02\x00\x0d\x13\x1d\x20\x28\x2b\x31\x3b\x43\x46\x46\x66\x7d\x87\x8c\x90\x94\x97\x95\x0f\x41\x45\xa0\x2f\x22\x1d\x12\x83\xc0\x0b\x21\x1c\x20\xa0\xaa\x40\x0e\x0b\x21\x72\x46\xa0\x00\x8e\x0c\x1c\x61\x0d\x91\xb6\x80\x00\x48\x74\x2d\xf1\xa6\xc0\x55\x32\x20\x46\x97\x14\x61\x6a\x91\xb4\x00\x12\xe9\x63\x60\x77\xa5\x03\x40\x01\x01\x25\x93\x00\x00\x56\xa0\x01\x25\xdb\x7e\x39\xec\xf8\x05\xeb\x4a\x52\xb7\x00\x0b\x05\xae\xf1\x00\x56\xdb\x6d\xae\xdb\x6d\xb5\x30\x68\xad\x5a\x33\x66\xc6\x8c\x16\x10\x10\x00\x61\x02\x82\x02\x04\x10\xa1\x45\xcd\x9d\x5c\xba\x54\xab\x77\x70\xee\xdd\xdb\xbf\x7e\xdd\x3a\x75\xf1\xdb\xa6\xdd\x9a\xee\xdd\xab\x36\x6c\x46\x80\x00\x07\x07\x09\x0f\x0f\x1f\x26\x33\x3a\x44\x49\x51\x5d\x61\x7c\x8d\x8d\x95\x9b\x9b\x9d\x9d\x9e\xa2\xa2\xa2\x9e\x9d\x9d\x9b\x9b\x95\x8d\x8d\x7c\x61\x5d\x51\x49\x44\x3a\x33\x26\x1f\x0f\x0f\x09\x07\x07\x00\x13\xe1\x44\xb0\x00\x19\x01\x01\x17\x1b\x07\x08\xe1\x5d\xa0\x20\x0f\x0f\x20\x2f\x09\xe1\x69\xa0\xa2\x24\x24\x30\x41\x0a\xe1\x68\xa0\xb4\x00\x9b\x81\x83\x76\x09\x61\x5e\x90\xa0\x06\xdd\x50\x13\xe1\x2b\xb0\x99\x90\x01\x01\x17\x1b\x07\x09\xe1\x1a\xa0\x52\x10\x10\x20\x2f\x09\xe1\x0d\xa0\x08\x23\x23\x30\x41\x0a\xe1\x0b\xa0\x03\x50\x9b\x81\x83\x76\x09\x61\x18\x90\xa0\xa4\xdd\x50\x01\x01\x1f\xf3\x49\x00\x34\x27\x0d\x00\x00\x16\x16\x00\x0a\x06\x76\xf3\x00\xb6\xdb\x6d\xb6\xda\x00\x32\x38\x10\x10\x00\x43\x06\x16\x3c\xa1\x63\x67\x68\x59\xbd\x76\xf6\x6c\xf9\xf4\xec\xd9\xbb\xb7\x3e\x38\xad\xd2\x9f\x26\x2b\x15\xaa\x15\x99\x99\x99\x91\x8c\x87\x59\x25\x1d\x1d\x1a\x14\x0c\x04\x00\x00\x03\x05\x0e\x0e\x14\x1c\x1c\x1d\x20\x24\x33\x85\x8d\x92\x99\x99\x99\x99\x9b\x9e\x9e\x9c\x9b\x99\x99\x09\xe1\x67\xa0\x02\x1c\x1c\x20\x40\x09\xe1\x5e\xa0\x1a\x0e\x16\x29\x52\x08\x61\x61\x88\xa0\x20\x00\x8f\x08\x61\x12\x89\xa0\x00\x00\xaf\x08\xe1\x4b\xa0\x30\x02\x02\x09\x16\x08\xe1\x28\xa0\x00\x02\x02\x08\x14\x08\xe1\x3b\xa0\x00\x01\x01\x19\x23\x0a\xe1\x0c\xa0\x11\x20\x1c\x27\x58\x58\x08\xe1\x1b\xa0\x20\x04\x04\x1f\x28\x01\x01\x1d\x93\x00\x00\xb6\x80\xdb\x4a\xe8\x8d\x43\x8b\x08\x00\x02\x2d\x6c\x62\xd5\x40\x00\x04\x07\x66\xf1\x00\xa9\x24\x92\x56\x80\x56\x94\x99\x30\x01\x4d\xbb\xb7\xc7\xb6\x3c\x74\x65\xc3\x66\xac\xa9\xa8\xa4\xa4\x9b\x2c\x13\x00\x13\x2c\x9b\xa4\xa4\xa8\xa9\xaa\xaa\xa9\x2f\x61\x2c\x49\x24\x71\x61\x4b\x2b\x15\x05\x06\x99\x60\x27\xe1\x49\x20\x13\x15\x1b\x2b\x2c\xa4\x32\x13\x35\xa9\x27\xe1\x49\x20\x63\x61\x5b\x4b\x4a\xa4\x32\x13\x35\xa9\x01\x01\x1f\x93\x00\x55\x00\x00\x0b\x0b\x1c\x29\x34\x07\x7b\xfe\x80\x11\x08\xe6\xf1\x00\xb6\xdb\x75\xb6\xeb\x6d\xb6\xeb\x6d\xba\x80\xeb\xd7\xa7\x4e\xbd\x7a\x6f\xf1\xd3\x97\x6e\x7c\x7a\x71\xdf\xbb\x76\x5b\xb5\x64\xbd\x64\xbd\x52\x44\x46\xc9\x0a\x14\x24\x30\x40\xc1\x01\x06\x08\x00\x40\x40\x40\x00\x81\x00\x00\x00\x30\x81\x84\x08\x24\x60\xe9\xd4\xaa\x56\x39\x87\x26\x85\xab\x37\x71\xed\xdb\xbf\x8f\x2e\xbd\x40\x92\x92\x8f\x8d\x86\x47\x43\x36\x37\x2b\x25\x23\x1d\x18\x14\x10\x0d\x07\x07\x0a\x06\x02\x09\x05\x00\x05\x07\x09\x05\x07\x0b\x07\x07\x0c\x10\x13\x18\x1d\x22\x25\x2b\x36\x36\x42\x47\x86\x8d\x90\x93\x93\x93\x93\x96\x9a\x9d\x9d\x9d\x9e\x9f\xa2\xa2\xa2\x9f\xa2\xa4\xa0\xa0\xa1\x9f\x9e\x9d\x9c\x9c\x9a\x96\x93\x93\x92\x3a\xe1\x6a\xb7\x6b\x68\x90\x02\x88\x45\xcc\x81\x4d\xb0\x07\x07\x15\x1b\x22\x23\x27\x2f\x35\x44\x4b\x53\x7f\x8a\x8f\x91\x94\x98\x9c\x9c\x24\x72\x17\x25\xb6\x80\x39\x40\x33\x31\xae\x81\xc0\x22\x49\xeb\x97\x02\x2c\x92\x18\x0b\xb7\x50\x08\x02\x88\xca\x55\x60\xc4\x10\x7a\xc6\x20\x21\x10\x9d\xa2\xf0\x1c\x72\x30\x07\xb4\x00\x73\x04\x10\x41\xc0\x41\x03\xa9\x40\x23\x52\x4d\x0c\xb6\x80\x43\x01\x38\x99\x84\xda\xb0\x14\xd8\x2c\x92\x44\x13\xb6\xe0\x51\xc0\x54\xc2\x53\xb4\xd8\xa0\xa4\xda\x60\x15\x0a\x74\xab\x40\x22\x52\x6c\x19\xb6\x80\x24\x15\x6c\x64\x4a\x5f\xe2\x08\x1a\x72\x6b\x2a\xb4\x00\x7f\xd6\x18\x10\x9a\xa4\x10\x21\x52\x08\x19\xba\x80\xf8\x2b\xc0\x2b\x40\x00\x20\x22\x72\x06\x40\xb6\x80\x44\x00\x53\x88\x66\x85\x10\x01\x46\x22\x72\x05\x27\xb6\x80\xb1\x90\x5e\xd4\x67\x86\x50\x00\x46\x23\x72\x55\x29\xb6\x80\x23\x47\x98\x53\x02\x78\xa9\x75\x20\x47\x23\x72\x5d\x8a\xb6\x80\x00\x13\x79\x51\x00\xab\xdd\xd3\x10\x8a\x23\x72\x0b\x8f\xb7\x00\x44\x03\x5a\xa8\x40\x99\x52\x01\x3d\x90\x3b\xe1\x05\xbb\x5b\x68\x55\x98\x78\x46\x76\x65\x04\x55\x43\x33\x07\x07\x13\x19\x22\x27\x2f\x38\x40\x43\x4b\x5c\x7f\x8b\x8f\x91\x95\x98\x9c\x9c\x22\x72\x6e\x42\xb6\x80\x00\xbb\x10\x00\x43\x01\x49\x87\x54\x01\x01\x25\x93\x00\x00\xb6\xd0\xd3\x4a\xe8\x91\xf6\x13\x30\xc2\x00\x00\x00\x21\x4a\xda\xb4\x9c\xde\x00\x00";
        bytes
            memory index = "\x00\x00\x00\x36\x00\x4d\x00\xb2\x01\x38\x01\x48\x02\x11\x02\x26\x02\xf3\x03\x01\x03\xa7\x03\xbe\x04\x14\x04\x25\x05\xef";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getCheeks(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x01\x01\x2f\xf3\xb6\xd0\x66\x29\x04\x00\x04\x3a\x66\x92\xc8\xcc\xc8\xa3\x66\x51\x51\x32\x2e\x2b\x00\x00\x00\x2b\x2e\x32\x51\x51\x01\x01\x3f\xd3\x00\xb6\xdb\x40\x60\x37\x18\x08\x01\x00\x08\x1b\x40\x60\x80\xa5\xb8\xc0\xbf\xb8\xa8\x89\x60\xa3\x46\x1b\x96\x8a\x52\x16\x00\x00\x01\x64\x8a\x5a\x39\x87\x46\x88\x01\x01\x3f\xd3\x00\xb6\xdb\x40\x6c\x3a\x01\x00\x12\x3b\x4a\x54\x60\x6c\x78\x84\x8e\x9d\xc6\xd8\xd7\x9e\x6c\xa3\x45\xe9\x34\x03\xc4\x03\x00\x00\x00\x31\x03\xd0\x13\x7b\x46\x88\x01\x01\x3f\xd3\x00\xb6\xeb\x40\x6c\x60\x53\x46\x29\x12\x00\x02\x3f\x6c\xd6\xd8\xc6\xaf\x92\x85\x78\x6c\xa5\x4a\x8c\xd8\xac\xa0\x19\x00\x00\xcc\x06\x51\x66\xd1\xa5\x48";
        bytes memory index = "\x00\x00\x00\x20\x00\x4c\x00\x78";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getLegs(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x04\x01\x1c\x73\x02\x2e\xb5\x00\x10\x82\x00\x1e\x30\x00\x26\x69\x60\x24\xb1\x00\x00\xb6\xd0\x9c\xe3\x29\x24\x84\x29\x44\x10\x00\x18\x6a\x2e\xbb\x0b\xae\xae\xa7\xd4\x00\x0f\xe1\x40\x0e\x0d\x30\x35\x0f\xe1\x40\x07\x08\x30\x35\x04\x01\x1c\x73\x01\x2c\x56\x80\x8c\x90\x00\x00\x42\x28\xa8\x85\x00\x34\xb1\x00\x00\xb6\xda\x00\x18\xc8\x40\x80\x48\x8d\x29\x29\x49\x63\xba\xba\x28\x64\x61\x00\x08\x82\x26\xba\xec\x2e\x0f\xe1\x40\x06\x07\x2f\x34\x0f\xe1\x40\x0e\x0c\x2f\x34\x01\x09\x35\xb1\x00\x00\xb6\xdb\x40\x3c\xe4\xd2\x44\xc1\x40\x0c\xf6\x15\x6a\x17\x5d\x72\x27\x80\x01\x05\x62\xb2\xcb\xf2\xe7\x7d\x72\xc7\x09\xe5\x70\xd0\x80\x01\x09\x44\xb1\x00\x00\xb6\xdb\x68\x73\xca\x20\x00\xd0\x7d\xb7\xcd\x5f\xbc\xe3\x96\x97\x38\x9e\xfc\xb5\xdf\xcf\x7e\xdb\x5c\xf1\xae\x55\x8c\x0c\x02\x53\x6e\x70\x02\x0a\x44\x76\x01\x2d\x56\xdb\x68\x90\x80\x00\x00\x24\x29\xce\x63\x19\xb3\x9c\xe9\x20\x10\x6a\xab\xdd\x65\x58\xce\xfc\xbb\xa1\x24\xb1\x00\x00\xb5\x50\x9c\xe3\x29\x1c\x85\x10\x40\x18\x6a\x6f\xbf\x3b\xaa\x7d\x40\x00\x02\x0a\x44\x96\x01\x28\x56\xdb\x68\x90\x80\x00\x00\x25\x29\xce\x73\x1d\x70\x9c\xe9\x20\x10\x0c\xa5\xb1\xcf\x41\x8c\x96\xbe\x0f\x6b\x56\x20\x34\xb1\x00\x00\xb6\xda\x00\x19\x08\x40\x80\x48\x8d\x29\x29\x49\x03\xae\x9a\x28\x64\x61\x00\x08\x82\x24\xb2\xcc\x2b\x02\x0b\x14\x91\x00\x1f\xb4\x76\xe7\xde\x81\x00\x10\x1f\x9c\xac\x20\x1d\xb1\x04\x00\xb6\x80\x82\x04\xc6\x10\x00\x41\x14\xe0\x14\x58\xe4\x92\x37\x5b\x2c\x00\x02\x0b\x1c\x91\x00\x1b\xb6\x80\x73\xa5\x4b\x5b\x39\x01\xc0\x10\x80\x65\xe3\xbd\x81\x00\x34\xb1\x02\x00\xb6\xda\x00\x9d\x2b\x49\xc1\x05\x10\x40\x01\x95\xb3\x10\x51\xcc\x46\x28\xa2\x79\xa5\x48\x10\x10\x04\x01\x0c\x25\xb1\x00\x00\xba\xd0\x81\x44\x10\x55\x86\x04\x00\x00\x0e\x21\x48\x20\xc7\x6d\xa5\x79\xe6\x00\x01\x0c\x34\xb1\x00\x00\xb6\xda\x00\xa5\x0c\x31\x00\x22\x4d\x6a\xe7\x3e\x74\x2c\x30\x07\x25\xe9\x67\xc3\x9e\x67\x8d\xf3\x4b\x02\x0d\x27\xb1\x00\xb6\xd0\x51\x4b\x2c\x21\x06\x00\x00\x05\x0c\x2d\x3f\x41\x42\x27\x8e\x35\xb5\x55\x54\xd6\xa9\x0f\x00\x17\xf3\xb4\x58\x51\x21\x21\x3c\x4a\x4c\x08\x43\x35\x35\x3b\x1e\x05\x02\x0d\x3e\xb1\x00\x00\xb6\xdb\x40\x6a\x7c\x98\x30\x20\x00\x82\x18\x99\xbc\x18\x10\x27\x52\xa5\x45\xa8\xd3\x7c\xe0\x71\x96\x16\xbe\xfb\xe1\x18\x10\x05\x17\x1d\x00\x3e\xb3\x02\x05\xb6\xdb\x40\x86\xfd\xc3\x02\xc1\x00\x00\x24\xc5\xfc\xd9\xf3\xe8\xd1\xa5\x3a\x18\xb3\x0c\xf4\xda\x66\x18\xd6\xfb\x1e\x00\x00\x42\x36\x2b\x00\x01\x0e\x1c\xb1\x00\x00\xb6\x80\xc6\xb7\x8a\x10\x40\x42\x00\x2a\x1b\xb3\xe7\xab\xdc\x00\x00\x01\x0e\x2c\xb1\x00\x00\xb6\xd0\xc5\x52\x72\x00\x65\xb6\x77\xac\x00\x14\x00\x05\x2e\x8c\x77\xe7\x0a\xca\x14\x01\x06\x3d\xb3\x00\x00\xb6\xdb\x68\x41\x04\x10\x40\x00\x14\x51\xb7\xdf\x8a\xac\x71\x8e\x28\xa2\x8a\x20\x00\x08\x27\xbb\x5d\x77\xaa\xaa\xad\xbf\x5c\xf3\xae\x38\x1d\x1c\x70\x02\x06\x24\x93\x00\x0f\xb6\xd0\x6a\x8a\x41\x90\x00\x31\xd0\xe8\x00\x00\x8f\x0a\x63\xbd\xf4\xd8\x83\x80\x4d\xb3\x00\x00\xb6\xdb\x75\x00\x51\x23\xc0\x00\xa3\x51\x2c\xe5\x1f\x82\x07\x21\x8e\xcb\x24\x71\x85\x94\xc3\x2d\xf6\xdb\x3a\xe3\x20\x50\x04\x24\xa8\xab\xc3\x5d\x77\xc2\xdb\xb0";
        bytes
            memory index = "\x00\x00\x00\x38\x00\x74\x00\x9b\x00\xc3\x00\xf9\x01\x39\x01\x60\x01\x93\x01\xad\x01\xcc\x01\xfb\x02\x4b\x02\x62\x02\x7d\x02\xa8";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getArms(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x04\x01\x3e\xb1\x00\x00\xb6\xdb\x40\xa0\xfd\x08\xf1\x81\x41\x80\x02\x10\x6c\x6a\x35\xec\xd8\xaf\x42\x80\x51\x34\x82\x00\x10\xc7\x41\x49\xa5\x8e\x28\x19\x4d\x45\x00\x0f\xe1\x40\x04\x09\x04\x05\x0f\xe1\x40\x03\x09\x11\x0f\x24\x93\x0e\x07\xb6\x80\x18\x1f\x29\xbd\x47\x20\xc0\x1a\xa2\xa3\x10\x40\x08\xc0\x04\x01\x3e\xd1\x00\x00\xb6\xdb\x40\x76\xcc\xf1\x01\x00\x00\x82\x10\x34\x81\xa3\x88\x97\x3f\x87\x0d\xd8\xc1\x86\xc4\x47\x07\xc7\x06\x00\x00\x00\x62\xb0\xe4\x51\xa5\x7b\x00\x0f\xe1\x40\x05\x08\x05\x0d\x0f\xe1\x40\x13\x12\x04\x0c\x24\x93\x03\x15\xb6\x80\x75\x6b\x38\xb5\x60\x2b\x80\x9c\x8e\x40\x00\x02\xa4\xc0\x02\x09\x86\xb1\x00\x00\xb6\xdd\x6e\xb6\xdb\x68\x3e\x7c\xc9\xa3\x44\x05\x89\x0c\x24\x61\x02\x02\x83\x83\x00\x14\x48\xd1\xa1\x42\x03\x06\x14\x49\xa8\x12\x6c\x5b\xc1\x82\xd5\x7a\x34\x64\xac\x4c\x80\xf9\xf0\x04\x10\x0b\x2c\x61\x45\x24\xc3\xd1\x45\x03\xce\x55\x76\x5b\x6d\xa7\x1e\x82\x18\xa9\xae\xca\xea\xa5\xd7\x1c\x6d\xb6\x96\x3c\x60\x41\x0a\x61\x16\x10\xa0\x90\x10\x00\x3d\x02\x09\x96\xd1\x00\x00\xb6\xeb\x75\xb6\xdb\x6d\xa0\x3c\x78\xe9\xc3\x65\x8a\x94\x26\x4c\x91\x01\xe2\x44\x8a\x14\x28\x38\x40\x60\x00\x00\x0a\x1c\x48\xe4\x6b\x5b\x3a\x7d\x0e\x24\x58\xb0\x1c\xa1\x3e\x7d\x3a\xb5\x6a\x53\x24\x40\x78\x2a\x54\x40\x40\x40\x02\x89\x1c\x38\x40\x30\x20\x83\x0d\x20\x40\x40\x70\xe1\xc5\x8b\x42\xa1\x7c\x6a\xb6\xef\x5f\xc1\x82\xd5\x7a\x53\xe5\xc3\x4a\x88\xb9\x32\x64\x08\x10\x26\x54\x0b\x41\x0b\x13\xa0\xee\x80\x6c\x60\x04\x0b\x25\x93\x3b\x00\xba\xd0\x00\x00\x4a\x76\x08\xe5\x68\xc2\x83\x5a\xd0\x40\x10\xee\x9e\x31\x40\x24\x93\x2c\x08\xb6\xd0\x08\x48\xc9\x52\xd7\xd4\x90\x60\x00\x4a\x44\x10\x0c\xc9\x84\xef\x67\x80\x1c\x91\x14\x16\xba\x80\x63\x40\x0d\x7b\xff\xb8\x3d\x7b\xde\xb1\x21\x00\x2d\xb1\x00\x06\xb6\xd0\xae\x33\x08\x20\x04\x59\x9e\xec\x35\xac\x55\x99\x2f\xbd\x72\x01\x00\x72\x4f\x54\x04\x0b\x35\x93\x3b\x50\xb6\xda\x00\x18\x83\x93\x5e\x28\xe6\x91\xd5\xd0\x34\x30\x06\x30\xc0\x21\xa9\x6f\xc6\x31\x6a\xc9\xc6\x1d\xb3\x28\x3e\xb6\x80\x0c\x03\x11\x76\x27\xde\x4c\xb0\x31\x17\x5e\x85\x33\xce\x00\x60\x1c\xf1\x1f\xb6\x80\x00\x10\x10\xbe\xdd\xfb\x40\x1f\x1f\x12\x04\x04\x0e\x1d\x2b\x43\x4b\x2f\xf1\xb6\xd0\x30\x2a\x22\x1a\x0b\x00\x0e\x0e\x0f\x1b\x2a\x44\x30\x48\x4e\x4e\x4a\x42\x21\x00\x00\x0f\x17\x21\x36\x48\x01\x0c\x2e\xb1\x00\x00\xb6\xda\x40\x80\xb0\x00\x03\x0a\x98\x7f\x12\x34\x77\xee\x54\x9d\x6d\xb5\x80\x02\x3a\xed\x85\xd6\xd0\x3c\xd5\x18\x01\x0c\x37\xf1\xb6\xea\x00\x22\x32\x40\x42\x44\x45\x38\x21\x16\x16\x0a\x00\x00\x11\x22\x2c\x36\x39\x3b\x3e\x4c\x49\x42\x36\x36\x1b\x00\x00\x0e\x2c\x02\x0d\x3e\xb1\x00\x00\xb6\xdb\x40\xad\x4e\x7c\x97\xc9\x09\x05\x00\x00\x6a\x25\x2e\xa0\x49\xab\x62\xb0\x82\x69\xea\xbb\x39\x5d\x00\x08\x22\x8a\x15\xd5\x49\xb8\x00\x2f\xb3\x00\xb6\xd0\x49\x49\x34\x20\x11\x01\x00\x00\x03\x1b\x25\x3a\x49\xaa\xad\x70\xb1\xe0\x00\x76\x9b\xb1\xa8\x02\x0d\x3e\xd1\x00\x00\xb6\xdb\x40\x8c\xed\x19\xd1\x60\x00\x05\x1c\x58\xd1\xe4\xac\xa0\xc9\x9f\x36\x30\xb5\x6e\xa4\x21\xa0\xc1\x80\x1a\x7d\x4b\x37\x72\x63\xca\x9d\x66\xd0\x2f\xf3\xb6\xd0\x46\x23\x17\x13\x0b\x00\x00\x0f\x15\x1e\x2b\x46\x46\x5a\x5a\x45\x32\x0c\x03\x03\x0e\x30\x41\x58\x5a\x5a\x01\x03\x4e\xb3\x00\x00\xb6\xeb\x6d\x00\x6d\x0e\x55\x0a\xb5\x24\x3a\x48\x60\x78\x50\x20\x01\x05\x16\x3c\x99\x52\xe6\x90\xb6\x7d\xb4\x97\x6a\x29\xec\xca\x54\x0c\x28\x71\x00\x00\x31\x8a\x51\xd9\x9f\x01\x03\x4e\xd3\x00\x00\xb6\xdb\x6d\x00\x8b\x42\xd5\xcb\xb6\x60\x2e\x50\x99\x22\x41\x02\x00\x01\x04\x30\xaa\xb5\xcc\x1a\x3b\x8a\x95\x32\x5d\x2b\x38\x6c\xd2\x7c\xd1\x41\x92\x44\x88\x8a\x06\x00\x20\xd4\xec\x20\xc8\x94\x0c\x0e\x3d\x91\x23\x23\xb6\xab\x40\xc3\xef\xfb\xe5\xe5\x10\x1c\x01\x89\x39\x17\x61\xc0\x28\x21\x2a\x73\x9c\xc3\x12\xc8\xc1\xcb\x28\x0b\x41\x30\x32\xa0\xdd\x50\x4a\x00\x3d\xb3\x00\x00\xb6\xdb\x68\x8a\x35\x4e\x08\x51\x46\x00\x82\xd1\x55\xc7\x6c\xc7\xcd\xb2\xa2\x80\xb6\xcd\xb4\xc6\x38\x59\x28\x40\x40\x04\x31\xca\x2d\x07\x22\xa6\x90\x1d\x91\x0d\x15\xb6\x80\x59\x6a\xa4\x78\x40\x80\x11\x20\x94\x86\x20\x4b\x1b\xe5\x40\x0b\x61\x10\x26\xa0\xff\xa0\x33\x09\x0b\x41\x14\x23\xa0\xaa\x70\x48\x40\x0a\x61\x22\x1a\xa0\x00\x50\x88\x40\x0b\x61\x25\x18\xa0\x00\x1d\xbb\x60\x1b\x77\x09\x02\xb4\x00\x96\x05\x8b\x90\x50\x6a\xca\x50\x23\x77\x09\x11\xb6\x80\x31\x03\x58\x89\x63\xcb\x31\x01\x49\xdc\x23\x77\x15\x08\xb6\x80\x89\xdd\xd7\x30\x28\x99\x96\x30\x24\x99\x4c\x95\x1c\x22\xa9\x25\x6d\x00\x4b\xa9\x57\x41\x49\x49\xc8\x10\x10\xe9\x48\x11\x98\xc6\x49\xf6\xb4\x9a\x72\x88\x02\x10\x0b\x0e\x45\xb3\x00\x00\xb6\xdb\x6d\x79\x62\x86\x00\x62\xce\x3d\x25\x5c\x7e\x29\xaa\xb6\xfd\xba\xff\xbe\x71\x9c\xbe\xfc\x2a\x89\xc5\x93\x48\x90\x40\x00\x00\x47\x35\x15\x98\x7e\x6a\xad\xb8\x25\x71\x0c\x20\xb6\xd0\x4d\x30\x00\x00\x55\xa1\xb2\xaa\x18\x60\xaa\xc8\x52\x10\x14\x9a\xa0\x46\xb1\x20\x31\xb6\xda\xa8\x16\x5d\x83\x87\x90\x20\xc2\x80\xf5\xd1\xa2\x83\x03\x87\x00\x00\x18\xb0\x9f\x1e\xfd\xfb\xdd\xb3\xbe\xeb\x61\x79\x80\x00\x04\x18\x67\x0f\x41\x24\xa0\x1e\x1e\x1b\x0c\xb4\x40\x0a\x41\x19\x22\xa0\xfe\x80\xb4\x80\x09\x41\x24\x21\xa0\x2f\xa4\x00\x0b\x41\x27\x24\xa0\x00\x2f\x90\x00\x44\x95\x1c\x26\xb5\x24\xa8\x21\xd6\xc7\x42\x0b\x49\x44\x10\x10\x08\x00\x45\x4e\x6f\xb4\x2a\xb1\x04\x1b\x77\x0d\x0a\xb4\x00\xdb\x05\x9f\xd0\xbe\xa4\x09\xb0\x1c\x77\x21\x09\xb4\x00\x19\x60\xa3\x00\x60\xbd\x94\x09\xb0\x1b\x77\x17\x01\xb4\x00\xaa\x05\x6a\xa0\x60\x19\xbc\x60\x04\x06\x9d\xd1\x00\x00\xb6\xdb\x6d\xb6\xdb\x6d\xba\x80\x79\xe5\xd4\x50\x81\x45\x10\x51\x40\x14\x50\x81\x00\x11\x05\x08\x10\x42\x14\x80\x89\x24\x74\x13\x69\xc7\x1f\x86\x38\xe4\x92\x8a\x28\xba\xaa\xaf\xba\xca\x6a\xbe\xb9\xe4\x90\x81\x02\x6c\x58\xb3\xa3\xc7\x88\xf9\xf3\xc6\xcd\x9a\xb3\x5e\xad\x3a\x64\xa8\x4f\x9c\x34\x60\x81\x12\x22\xc3\x05\x04\x10\x20\x00\x40\xc3\x87\x10\x28\x68\xd1\xa5\x4a\x97\x3a\x89\x3a\x85\x0b\x9a\x3a\x74\x66\xb3\x10\x23\xb6\xd5\x6a\xb6\x80\x9b\x46\x84\x27\xc9\x52\x9e\x28\x44\x68\xd1\xa1\xc3\x8f\x12\x0c\x18\x30\x00\x04\x0c\x20\x75\x0a\x68\xf3\x40\xaa\x86\x1c\x7a\xaa\xa3\x65\x01\xc0\x00\x10\x52\x40\xd2\x8a\x41\x04\x59\x87\x7d\xf7\xbe\xa0\x13\x41\x12\x20\xb4\xff\xc7\x76\x00\x02\x25\x60\x12\x61\x0f\x2a\xb4\xb6\x92\x80\x00\x45\x58\xa0\x04\x06\xad\xd1\x00\x00\xb6\xdd\x6d\xda\xdb\x6d\xd6\xdc\x6d\xb6\x55\x41\x23\x8b\x14\x51\x82\x04\x30\x40\x00\x41\x01\x08\x21\x86\x08\x71\xcb\x35\x35\x96\x61\x86\x17\x72\x28\xa3\x9a\xcb\x6f\xba\xec\x31\xca\xdb\x2c\xcf\x0b\xaa\xaa\xd8\x40\xa3\x46\x9d\x19\xd4\xe8\xd0\x97\x1e\x1c\x17\xce\x5b\x34\x62\xa5\x4a\x44\x27\x4e\x9d\x2e\x40\x40\x40\x40\x01\x83\x0a\x28\x60\xd1\x83\x09\x14\x34\x70\xfa\x34\xe9\xd4\x2a\x64\xd5\xc3\x96\xef\xe1\xc6\x8d\x2e\x80\x5e\xd3\x10\x2f\xb5\x25\x55\xb8\x00\x97\x56\x74\x67\xa8\x8c\x00\x04\x24\x48\xa1\x83\xc7\x8c\x1e\x49\x0a\x19\x12\xc0\xa1\x53\x1e\x0b\xd3\xa2\x0d\x12\x58\xb0\x40\x00\x40\x8f\x38\x95\xf3\xe9\xf4\x00\x13\x41\x17\x2e\xb4\xdd\x96\x62\x00\x26\x00\xd0\x13\x71\x0d\x35\xb4\x88\x72\x23\x00\x00\x45\x57\x90";
        bytes
            memory index = "\x00\x00\x00\x4b\x00\x98\x00\xf5\x01\x63\x01\xc0\x02\x29\x02\x4b\x02\x70\x02\xb5\x02\xfe\x03\x2f\x03\x65\x04\x3d\x05\x13\x05\xd1";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getEars(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x02\x01\x17\xf1\xb4\x38\x38\x1b\x00\x00\x0f\x2f\x08\x08\x00\x0f\x0f\x2b\x2e\x17\x93\x0b\xb4\x32\x32\x1e\x0d\x0d\x1a\x32\x29\x40\x84\x6b\x40\x02\x01\x17\xf1\xb4\x3b\x3b\x31\x00\x00\x02\x1a\x1d\x1d\x04\x00\x00\x24\x33\x17\xf3\xb4\x30\x30\x2a\x09\x09\x0e\x21\x21\x21\x0f\x09\x09\x23\x2d\x02\x01\x17\xf1\xb4\x2d\x2d\x32\x19\x00\x05\x05\x32\x32\x19\x00\x19\x32\x32\x14\xf3\x0c\xb4\xc6\x34\xd0\x08\x40\x2e\x2e\x19\x0a\x1a\x2e\x2e\x02\x0f\x25\xb1\x00\x00\xb7\x50\xca\x05\x0d\x1c\x00\x08\x49\xdb\x79\xb7\x6a\x60\x5d\x24\x91\x30\x60\x10\x25\xb3\x10\x0a\xb7\x50\x9e\x24\x09\x08\x00\x02\x35\x79\xe7\x55\xf8\x57\x34\xc3\x0c\x18\x02\x95\x02\x0f\x25\xb1\x00\x00\xb7\x50\x84\xd2\x06\x10\x00\x08\x4d\xfc\x34\xbe\xf7\x92\x20\x00\x03\x0c\x21\x18\x25\xb3\x0d\x0a\xb7\x50\x7d\x61\x03\x04\x00\x01\x39\xa9\x1f\x6e\x16\x8e\x08\x10\x42\x04\x04\x1a\x02\x0f\x25\xb1\x00\x00\xb7\x50\xaf\x8b\xa6\x7d\xc7\x19\x48\xa0\x0d\xe2\x86\x90\x20\x00\x08\x41\xaa\x38\x25\xb3\x0b\x11\xb7\x50\x45\xc8\x9a\x45\x14\x51\x20\x01\x91\xa2\x55\x0b\x08\x00\x02\x2d\x49\x68\x02\x10\x2d\xb1\x00\x00\xb7\x2a\x51\x11\xc7\x08\x00\x19\xff\x8e\x22\x44\x5e\xee\x79\xa9\xb6\xc0\x33\x1c\x73\x98\x1d\x93\x13\x0e\xaa\x80\xa6\x94\x41\x00\x04\x66\x39\xc0\x99\x4b\xbb\x02\x10\x1f\xf1\xb6\x80\x57\x4f\x0f\x00\x00\x14\x1f\x2c\x33\x42\x28\x09\x00\x07\x07\x16\x28\x3d\x40\x42\x1d\xb3\x0f\x0b\xb6\x80\xfb\xef\xf4\x80\x00\x1e\x63\x50\xa2\x87\x53\x04\x00\x16\xb2\xe0\x02\x10\x35\xb1\x00\x00\xb6\xd7\x40\x5a\x2d\xb6\xca\xba\xdf\x55\x44\x00\x06\xba\xea\xa0\x29\xa8\xa2\x44\x41\x00\x04\x20\xd6\xd2\xa8\x9b\x14\xf3\x0b\xb8\xb5\x96\xb0\x00\x31\x13\x0a\x0a\x13\x31\x02\x0a\x17\xf3\xa8\x35\x35\x16\x00\x36\x22\x22\x21\x11\x15\x17\x91\x00\xb8\x3a\x24\x00\x00\x28\x35\x01\x23\x1b\x64\x01\x0a\x27\xf9\xb6\xe0\x49\x49\x1a\x0e\x04\x0e\x0d\x0b\x00\x01\x0e\x29\x25\x25\x2d\x20\x14\x01\x01\x00\x12\x22\x41\x3f\x01\x0a\x34\xf5\x00\x49\x24\x80\x94\xb8\xe0\x29\x40\x2c\x18\x1b\x00\x1b\x18\x2c\x0b\x0e\x3d\xb3\x00\x00\xb6\xdb\x68\x61\x83\x48\x00\x82\x4d\x35\x97\xe1\x92\x6a\x2b\xbb\x2c\x2e\x7d\xf0\x8a\x28\xdf\x69\x34\x4c\x00\x00\x03\x20\xb3\x90\x49\x56\xa1\x86\x10\x1d\x71\x07\x14\xb6\x80\x61\x89\x24\x90\xa1\x40\x41\x00\x99\x85\x01\x6b\xaa\x0b\x01\x0c\x1a\xa0\xb6\x00\xb0\x0a\x21\x13\x17\xa0\xd4\x00\xd0\x0a\x21\x1d\x16\xa0\x0a\xd0\xd0\x0b\x01\x20\x19\xa0\x04\xaa\x80\x2d\xb1\x19\x23\xb5\x5a\x86\x16\x11\x34\x91\xc0\x00\x42\x90\x79\xe0\x71\xc6\xd7\x54\x90\x02\x09\xb8\x26\xa6\x90\x43\x95\x17\x18\xb6\xa5\x68\x98\x00\x00\x02\x33\x68\x8b\xdd\xb9\x18\x02\x45\x46\x31\x5a\xe0\xa5\x35\xce\x40\xc0\x22\x57\x17\x04\xb6\x80\xb6\x34\x0a\xb4\x44\x00\x5e\xc8\x1b\x57\x1a\x0a\xb4\x00\x89\x74\x06\x80\xb0\x17\xe8\x1b\x57\x11\x0a\xb4\x00\x20\x35\x94\x20\xd4\x17\xf0\x0b\x0e\x35\xb3\x00\x00\xb6\xdb\x40\x71\xca\x2c\xc2\xb9\xe0\x8d\x84\xcf\x34\x90\x04\x21\x45\x00\x86\x18\x5c\x5d\x33\xc8\x00\x00\x03\x21\x25\x1c\x8a\x18\x40\x1d\x71\x05\x13\xb6\x80\x5d\x79\xa4\x7c\x01\x06\x4d\x30\xaa\xa6\x03\x9c\xaa\x0b\x01\x09\x1a\xa0\xcc\x60\xc0\x0a\x21\x11\x17\xa0\xd0\x00\x90\x0a\x41\x1b\x16\xa0\x01\x40\x90\x80\x0b\x21\x1e\x19\xa0\x00\x4a\xa0\x2c\xb1\x14\x20\xb5\xdc\x94\x98\xa4\xa1\x02\x10\x04\xb5\x80\x59\x65\x50\x30\x00\x00\x4d\x88\x61\x43\x75\x13\x18\xb7\x25\x68\xba\x32\x10\x01\x46\x88\xad\xdc\xb0\x31\x03\x6e\xef\x9f\x99\xee\xe9\x30\x1b\x57\x11\x0a\xb4\x00\x47\x87\x30\x40\x01\xdc\x40\x1a\x77\x1d\x08\xb4\x00\xa8\x17\xa8\x30\x57\x85\x30\x1a\x57\x18\x05\xb4\x00\x60\xbb\x58\x02\xd8\x00\x0b\x0e\x1c\x91\x0f\x1e\xae\x80\x94\x98\xe2\x10\xc0\x9c\xdc\x00\x36\x60\x35\x93\x00\x00\xb6\xdb\x40\x7a\x7a\xed\xc2\xda\xa2\x91\x82\xce\x18\x30\x03\x14\x94\xc0\xff\xfb\xbb\xce\x2b\x00\x00\xb8\xce\xfb\xef\xfe\x1d\x71\x06\x13\xb6\x80\x49\x29\x63\x84\x20\x40\x49\x20\x99\x95\x00\x59\x99\x0b\x21\x1c\x17\xa0\x00\x4c\xf0\x0a\x21\x1a\x15\xa0\x00\xd0\xf8\x0b\x21\x08\x17\xa0\xcc\x80\xf0\x0a\x21\x11\x15\xa0\xb5\x80\xf4\x43\x75\x11\x17\xb9\x2b\x68\xcc\xee\xb9\x74\x43\x00\x12\x3a\xc0\x47\xdd\xc8\xe8\x8c\xdd\x93\x10\x40\x1b\x57\x0d\x07\xb4\x00\x47\x97\x60\x40\x22\xef\x08\x1b\x57\x1a\x07\xb4\x00\x10\x25\x83\x10\xd4\x19\xf0\x1a\x77\x15\x02\xb4\x00\x23\x58\x88\x40\x04\x87\x40\x04\x06\x8e\xd1\x00\x00\xbb\x6b\x6e\xb6\xdd\x75\xc0\x44\x88\xc1\x82\xa3\xc6\x0a\x02\x10\x20\x00\x81\x00\x87\x12\x28\x51\x03\x46\xce\x1f\x48\x95\x33\x06\xee\x1c\xb8\x71\x06\x14\x37\xcf\xa1\x32\x64\xd9\x72\x85\x00\x66\xcd\xc3\xc8\x70\x5e\xba\x6c\xc5\x8a\xc5\x4a\x8e\x99\x30\x64\xc8\xa1\x83\x04\x87\x08\x24\x48\x10\x00\xc2\x06\x0c\x14\x40\xc1\xe3\xca\x1f\x3e\x81\x42\xf5\xe0\x55\xd3\x16\x1b\xb6\xab\x55\xb4\xaa\xa8\x9f\x71\x24\x91\x4d\x33\x4d\x3c\xb2\x04\x10\x00\x09\x2c\xe4\x95\x62\x79\xc0\x74\xe9\xb3\x36\x06\x48\x8a\x02\x04\x00\x01\xc3\xc7\x8a\x14\x38\x71\x32\xc7\x56\x35\x7b\x22\x40\x13\x61\x11\x21\xb4\xaa\xc4\x47\x00\x00\x47\x7a\xc0\x13\x41\x1e\x19\xb4\xff\xc9\x74\x00\x26\x21\x10\x04\x06\x86\xb1\x00\x00\xb6\xdb\x6d\xb6\xdb\x68\x38\x71\x22\xb5\xeb\x57\xb2\x76\xf1\xec\x58\xd2\x20\x3d\x76\xfd\xf3\xe6\x6b\x90\x9a\x34\x60\x58\xa1\x42\xc4\x01\x00\x0c\x20\x50\xc2\x05\x09\x10\x28\x81\x93\x67\x00\x1c\x80\x02\x0c\x51\x87\x0c\x93\x4a\x35\x15\x56\x61\x76\xdd\x96\x59\x26\x9a\x3b\xe5\x92\x28\xe4\x6d\x85\xd6\x59\x55\x13\x40\xe2\x84\x18\x70\x54\xb3\x15\x18\xb6\xab\x55\xb4\x5a\x06\x10\x08\xa7\x08\x4e\x74\x29\xb2\x95\xee\xc4\xa4\xe9\x5d\x6a\xc2\x89\xe3\x85\x42\x84\x04\x10\x00\x10\x51\x82\x08\x41\x08\x4d\x36\xde\x82\x28\x80\x13\x41\x12\x16\xb4\xdd\x96\x64\x00\x02\x13\x60\x13\x41\x23\x18\xb4\xbb\x87\x73\x00\xb6\xa5\x00\x04\x06\x76\xb1\x00\x00\xb6\xdb\x75\xb7\x5a\x00\x60\xdd\xcc\x28\xf4\x26\xc9\xb1\x46\x6c\x28\x30\x61\x39\x60\xa5\x49\xb3\x26\x4a\x10\x18\x38\x70\x02\x85\x06\x11\x2a\x79\x1a\x96\x0c\x00\x8a\x07\xe4\x9e\x06\xd5\x40\xa1\x8d\x14\x40\x00\x04\x61\x84\x2c\xb2\x8c\x39\x04\x1d\x75\xd7\xe3\x9e\x89\xa5\x8a\x20\x44\x93\x20\x12\xb5\x5a\xad\xa5\x23\x18\xcb\x74\xa4\x1a\xa5\x18\x00\x32\x98\xb5\x80\xef\x68\xf6\x98\x20\x01\x8e\x73\x0c\xc6\x33\xed\xde\x80\x13\x41\x31\x10\xb4\x00\x47\x7a\xd0\x02\x01\x58\x13\x61\x1c\x12\xb4\xee\xb8\x86\x00\x00\x42\x28\x50\x01\x03\x3d\xd3\x00\x00\xb6\xdb\x68\x88\xc3\xd7\x6d\xf6\x10\x5d\x54\xcf\x34\xb3\x51\x4d\x74\x0a\x01\xc0\x9d\x29\xea\xf5\x47\x8a\x8b\x0c\x0c\x00\x01\x03\x49\x18\x34\x89\x6b\x69\x76\x00\x01\x03\x3c\xb3\x00\x00\xb6\xdb\xa8\x7b\xce\xa7\x45\xed\x53\x1e\x93\x0c\x66\x51\x80\x04\x00\xcf\x3b\xa8\x85\xe6\x11\x3c\x80\x40\x14\xa3\xd5\x7a\x3b\x32\xe4\x01\x03\x2c\xb3\x00\x00\xb6\xda\x73\xa4\xf6\xa1\x6e\x62\x0a\x02\xa5\x65\xb6\xd8\x9a\x51\x12\x83\x00\x10\x8e\x5d\xd9\x2c\x0b\x07\x2f\x95\x00\x49\x24\x41\x27\x27\x21\x2c\x44\xc3\x9c\x40\x4c\x0f\xe1\x40\x42\x27\x14\x06\x0f\xe1\x40\x27\x22\x06\x04\x17\xe1\x48\x27\x27\x2c\x0e\x06\x00\x27\xf3\x49\x20\x41\x12\x00\x12\x44\x20\x1e\x12\x09\x15\x17\xe1\x48\x00\x0e\x42\x12\x16\x1a\x17\xe1\x48\x12\x0e\x12\x09\x16\x1e\x2f\x95\x1a\x49\x24\x42\x28\x28\x1d\x22\x42\x2c\x20\xc1\x00\x0f\xe1\x40\x42\x23\x1c\x24\x0f\xe1\x40\x23\x1d\x24\x26\x17\xe1\x48\x28\x23\x22\x2a\x24\x1c\x0b\x07\x2f\x95\x1f\x49\x24\x25\x0d\x0d\x07\x12\x27\xc3\x9c\x30\x4c\x0f\xe1\x40\x26\x0d\x34\x25\x0f\xe1\x40\x0d\x08\x25\x22\x17\xe1\x48\x0d\x0d\x12\x2d\x25\x1f\x27\xf3\x49\x20\x25\x06\x00\x14\x2e\x34\x16\x00\x06\x2b\x17\xe1\x48\x00\x08\x2a\x00\x0d\x31\x17\xe1\x48\x14\x08\x06\x06\x0d\x16\x2c\xf5\x1a\x49\x24\x88\x00\x05\xd8\x30\x19\x19\x0d\x10\x2e\x0f\xe1\x40\x2e\x1e\x2e\x13\x0f\xe1\x40\x1e\x1a\x13\x0d\x17\xe1\x48\x1a\x1e\x25\x19\x13\x10\x14\x07\x1f\xf3\x49\x00\x0d\x10\x21\x23\x03\x2e\x2e\x03\x0f\xe1\x40\x1c\x1d\x2e\x07\x34\x53\x0d\x00\x49\x24\x00\x38\x0f\x0b\x3c\x0f\xf6\x00\x0f\xe1\x40\x15\x14\x2e\x07\x1f\xf5\x49\x00\x1d\x1c\x2c\x31\x0f\x36\x37\x11\x0f\xe1\x40\x28\x2b\x37\x14\x34\x55\x1d\x0c\x49\x24\x00\x38\x0a\xea\x38\x0f\xfa\x00\x0f\xe1\x40\x21\x22\x36\x13\x1f\xf5\x49\x00\x14\x14\x04\x00\x0f\x36\x37\x11\x0f\xe1\x40\x09\x06\x37\x14\x34\x55\x00\x0c\x49\x24\x00\x6d\x1c\x60\x18\x0f\xfa\x00\x0f\xe1\x40\x0f\x0e\x36\x13\x1f\xf3\x49\x00\x0f\x11\x20\x22\x1a\x3f\x3f\x1a\x0f\xe1\x40\x1b\x1c\x3f\x1d\x34\x53\x0f\x16\x49\x24\x00\x30\x0a\xd9\xb4\x13\xf8\x00\x0f\xe1\x40\x15\x14\x3f\x1d\x1f\xf5\x49\x00\x00\x04\x12\x11\x24\x45\x44\x23\x0f\xe1\x40\x0e\x0c\x44\x26\x34\x55\x00\x20\x49\x24\x00\x28\x0a\xc8\xb0\x13\x66\x00\x0f\xe1\x40\x08\x05\x45\x26";
        bytes
            memory index = "\x00\x00\x00\x23\x00\x47\x00\x6a\x00\x9c\x00\xce\x01\x00\x01\x2d\x01\x5d\x01\x8d\x01\xaa\x01\xc8\x01\xdc\x02\x9a\x03\x4c\x03\xf3\x04\x9e\x05\x3c\x05\xc3\x05\xf1\x06\x18\x06\x36\x06\xa4\x07\x12";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getEyes(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x01\x11\x25\x91\x00\x00\xb6\x80\x41\x56\x9c\x81\x83\x80\x01\x00\x00\x04\x89\xeb\x37\x08\x00\x01\x11\x1a\x52\x00\x00\xb4\x00\x77\x32\x18\xb4\x01\x68\x01\x11\x25\x91\x00\x00\xb6\x80\x48\x50\x0b\x55\xe7\xe0\x6d\x20\x00\x27\x9e\xe6\x06\x00\x00\x01\x11\x1a\x52\x00\x00\xb4\x00\x60\x3b\x58\x03\x6c\x00\x01\x11\x2d\x91\x00\x00\xb6\xd0\x44\xc1\xc5\x00\x44\x5e\x89\xd6\xd6\x44\xde\xf3\x56\x80\x00\x6d\x73\xbd\x80\x01\x11\x22\x52\x00\x00\xb6\x80\x56\xa2\x00\x28\xd8\x00\x5c\xd8\x01\x11\x1c\x91\x00\x00\xb4\x00\x6e\x36\xc1\x81\xa0\x08\x29\x39\x8c\x20\x01\x11\x1a\x52\x00\x00\xb4\x00\x52\x20\x10\x90\x01\x20\x01\x11\x2c\x91\x00\x00\xb6\xd0\x48\x80\x00\x11\x2d\x94\xa4\xe4\x80\x00\x0a\x97\x46\x31\x72\x46\x00\x00\x01\x11\x1a\x52\x00\x00\xb4\x00\x52\x20\x10\x02\x48\x00\x02\x12\x2c\x91\x00\x00\xb7\x50\xe7\x2a\xa1\x80\x03\x34\x69\xc0\x4a\x40\x32\xb5\xad\x7d\x5a\x90\x12\x72\x09\x03\xb4\x91\xda\x00\x00\x7c\xea\x00\x02\x12\x2c\x91\x00\x00\xb6\xd0\xef\x6c\xb1\x00\x05\x3b\xab\x7e\x80\x52\x80\x22\x31\x8e\x8c\x62\xc5\x00\x12\x92\x09\x01\xb4\xb5\xca\x08\x00\x0e\xe8\x30\x40\x02\x12\x2d\x91\x00\x00\xb6\xd0\x41\x96\xe0\x81\xa4\x06\x00\x01\x47\x40\x8c\x56\xa5\x00\x00\x52\x97\x18\x80\x12\x72\x0e\x01\xb4\x92\x22\x00\x00\xee\xe0\x00\x02\x12\x2c\x71\x00\x00\xb6\xd0\xc6\x24\x91\x80\x05\x3b\xa3\x3c\x00\x88\x02\x3a\xaa\xed\xc9\x80\x12\x72\x08\x01\xb4\x91\x38\x00\x00\x59\xba\x10\x02\x12\x2c\x71\x00\x00\xb7\x50\x5c\x67\x6b\x4d\x60\x00\xca\xb0\xbb\x87\x70\x07\x78\xbb\x11\x72\x0a\x01\xb4\x01\xbc\x00\x88\x80\x00\x02\x0c\x3d\xb1\x00\x00\xb6\xdd\x40\x65\xb7\x1a\x54\x00\x00\x20\xc7\xaa\xa9\xe6\xd9\x61\x90\x48\xe2\xc8\x00\x73\xd7\x96\x6a\x1f\x7e\x07\x19\x55\x20\x0b\x61\x14\x14\xa0\x00\x1a\x00\x7a\x01\x13\x23\x71\x00\x00\xba\x80\xb8\x42\x05\xff\xb0\x10\x25\xdd\xb3\x10\x01\x13\x24\x91\x00\x00\xb6\x80\x4b\x6d\x7c\x51\x42\x02\x40\x9d\x24\xc3\x80\x44\x8c\xc0\x01\x13\x23\x91\x00\x00\xb6\x80\xde\xfb\x70\x01\xad\x21\x50\xc8\x45\x42\x01\x00\x01\x13\x24\x71\x00\x00\xb6\x80\x7c\x1e\x91\x00\x44\x73\xc0\x57\xbc\xd8\x51\x05\x01\x11\x2c\x52\x00\x00\xb6\xd0\x08\xd2\xc7\xc1\x89\x20\x42\x00\x80\xfa\xee\x88\x09\x7e\x01\x11\x2b\x52\x00\x00\xb6\xd0\xa7\x41\x00\x03\x7b\xee\xa0\x20\x15\x35\xbb\x22\x01\x11\x2c\x72\x00\x00\xb6\xd0\x28\x80\x44\xbe\x98\xb4\xde\x92\x80\x89\x32\x00\x23\x98\x66\x80\x01\x11\x2b\x52\x00\x00\xb6\xd0\x85\x21\x10\x02\x58\xab\x80\x20\x12\xac\x96\xa2\x01\x11\x2b\x52\x00\x00\xb6\xd0\x31\x03\x59\xbe\xdb\x95\x30\xb5\x10\x0a\xb6\x4a\x02\x14\x24\x91\x00\x00\xaa\x80\xd6\x9e\x70\x01\x9a\x31\x8c\x0a\x52\x86\x2a\x93\x07\x00\xaa\xa0\xd1\x90\x9d\xc0\x7c\x23\x10\x04\x43\x78\x02\x14\x24\x91\x00\x00\xaa\x80\xb5\x98\x60\x01\x56\x29\x4a\x09\x4a\x25\x2a\x73\x06\x01\x55\x50\x05\x4b\x5a\x00\x0e\xed\xc2\x11\x00\x02\x14\x25\x91\x00\x00\xb6\xd0\x4d\x33\x40\x00\x94\xde\x9a\x66\x53\x4c\x00\x0e\xe7\x46\x31\x73\x8e\x00\x00\x33\x93\x0f\x00\xaa\xe4\x00\x02\x68\x85\x44\x30\x00\x84\x63\x02\x08\x00\x11\x20\x02\x14\x24\x71\x00\x00\xaa\x80\x9c\xda\x40\x01\x33\x11\x20\xcc\xc1\x2a\x73\x05\x01\x55\x50\x00\x39\x19\x00\x0a\xa9\x81\x00\x00\x02\x14\x24\x71\x00\x00\xb6\xd0\x63\x10\x00\x15\x93\xc6\x20\xc6\x00\x00\x59\x9b\xbb\x99\x50\x00\x32\x73\x09\x00\xaa\xe4\x00\x26\xed\x1b\x40\x80\xbb\xbb\x31\x00\x13\xb0\x01\x0b\x35\xb1\x00\x00\xb6\xda\x00\x14\x52\xce\x4e\x28\x20\x69\x95\x49\x10\x20\x05\x49\x26\x9c\x81\xf5\x54\x24\x70\x40\x18\x83\x52\x02\x11\x1c\x91\x00\x00\xb4\x00\x18\x29\x5b\x94\x60\x58\x00\x78\x45\x60\x22\x52\x05\x05\xb7\x00\x00\x2b\x18\x00\x6f\x6c\x88\x60\x01\x0b\x2d\xb1\x00\x00\xb6\xd0\x4d\x7a\x26\x9a\x17\x99\x00\x62\x10\x4c\x8e\x79\x9b\x68\xf2\x80\x0d\x46\x61\x8c\x02\x11\x24\x91\x00\x00\xb6\x80\xad\xa6\xd2\x80\x00\xa5\x40\x43\x61\x19\x45\x61\x02\x00\x22\x52\x03\x06\xb7\x00\xb6\xb0\x0d\xa0\x93\x6c\x88\x80\x01\x0b\x3d\x91\x00\x00\xb6\xdb\x40\x4d\x97\x5e\x7a\x29\x25\x99\x30\x01\x08\x42\x08\x24\xd4\xc0\xff\xfd\xbd\xd6\x0c\x00\x00\xc8\x57\x7b\xf7\xfe\x02\x11\x2c\x91\x00\x00\xb7\x50\x6c\x35\xad\x59\xa0\x00\x14\xd0\x84\x20\x81\x00\x02\x44\x21\x00\x22\x52\x0a\x03\xb6\x80\x40\x3d\xb6\x68\x2b\xff\x20\x04\x01\x0b\x2d\xb1\x00\x00\xb6\xd0\x45\x58\x60\x81\xc6\x55\x00\x61\xcf\x44\x7e\x28\x58\x60\xe2\x40\x09\x15\x5d\x7c\x02\x11\x2c\x71\x00\x00\xb6\xd0\x08\x06\x64\xc6\x53\x8a\xca\x20\x80\x84\x21\x00\x69\xcd\xeb\x80\x22\x52\x04\x03\xb6\x80\x00\x29\x1a\x00\x6f\x6c\x88\x0c\x01\x0b\x3d\x91\x00\x00\xb6\xdb\x40\x45\x46\x19\x69\xd7\x9f\x89\x10\x03\x10\x52\x09\x28\xf4\x40\xe7\x37\xab\xc5\xcc\x00\x00\xc7\x46\xfa\xdf\x38\x02\x11\x2c\x71\x00\x00\xb6\xd0\x55\x29\x49\xad\x49\x08\x00\x05\x00\xdd\x86\x00\x00\x06\x8d\xd0\x22\x52\x07\x02\xb6\x80\x24\x2b\xac\x44\x6e\xef\x10\x0c\x01\x11\x24\x92\x00\x00\xb6\x80\x71\x40\x53\xb2\x15\xc3\x80\x9d\x98\x50\x80\x45\x8c\xc0\x01\x11\x24\x92\x00\x00\xb6\x80\xa5\x22\xa0\x81\x2c\xa5\x00\x5c\x29\x39\x90\x20\x02\xc0\x01\x11\x24\x92\x00\x00\xb6\x80\x20\x07\x0c\xea\x0d\x39\x00\x93\x40\x32\xce\xd7\xb4\x80\x01\x11\x23\x72\x00\x00\xb6\x80\x8e\xb7\x30\x00\x68\x14\xdd\xeb\x70\x01\x01\x11\x23\x72\x00\x00\xb6\x80\xcc\xa6\x00\x58\xcc\x7a\xcc\xc3\x10\x17\x04\x15\x17\xf1\x48\x00\x13\x0c\x0d\x00\x0c\x17\xf1\x48\x10\x13\x0b\x16\x00\x0d\x27\x73\x0d\x49\x00\x00\x0b\x10\x04\x00\x99\x27\xf1\x49\x00\x04\x00\x00\x10\x16\x0d\x1f\x16\x03\x15\x17\xf1\x48\x17\x00\x08\x0b\x1a\x0b\x17\xf1\x48\x03\x00\x08\x00\x1a\x0c\x27\x73\x00\x49\x00\x17\x09\x03\x11\xbb\x00\x03\x15\x1f\xf1\x48\x00\x0b\x0b\x00\x0e\x1c\x07\x1f\xf1\x48\x00\x0b\x0b\x17\x0e\x1c\x07\x27\x73\x00\x49\x00\x0b\x17\x0b\x00\xe7\x07\x01\x15\x27\xf1\x49\x00\x10\x11\x0b\x00\x00\x12\x09\x09\x01\x15\x27\xf1\x49\x00\x0a\x00\x0a\x14\x00\x10\x0b\x10";
        bytes
            memory index = "\x00\x00\x00\x17\x00\x25\x00\x3c\x00\x4a\x00\x65\x00\x75\x00\x87\x00\x95\x00\xaf\x00\xbd\x00\xe1\x01\x08\x01\x2f\x01\x53\x01\x74\x01\xa2\x01\xb4\x01\xca\x01\xde\x01\xf2\x02\x08\x02\x1c\x02\x34\x02\x48\x02\x5c\x02\x7e\x02\x9f\x02\xce\x02\xee\x03\x18\x03\x39\x03\x59\x03\x75\x03\x99\x03\xbd\x03\xe3\x03\xff\x04\x25\x04\x49\x04\x6f\x04\x85\x04\x9b\x04\xb1\x04\xc3\x04\xd5\x05\x00\x05\x1f\x05\x40\x05\x4e";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getNose(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x01\x16\x14\x81\x00\x00\xb4\x08\x40\x15\x3e\xa0\x00\x1e\xf8\x4a\x00\x01\x16\x2c\x70\x00\x00\xb6\xd0\x38\xc0\x03\xd3\x9c\xcd\x6a\x73\x80\xea\x22\x00\x22\xae\xee\xe0\x02\x17\x3c\x91\x00\x00\xb6\xeb\x40\x39\x48\x20\x14\xaa\x7b\xe9\x28\xbd\xac\x49\xc0\x83\xa0\xf6\x04\x20\x08\x58\xf8\x3a\x11\x8c\x00\x13\x21\x05\x0e\xb4\x00\x25\x8a\xa0\x0f\xc0\x01\x16\x24\x70\x00\x00\xb6\x80\x00\x31\x8c\x39\x8a\x00\x00\x31\x03\x6f\xff\x63\x01\x18\x2d\x91\x00\x00\xb6\xd0\x48\xb1\x02\x00\x94\x9b\x92\x28\x19\x48\x8c\x5c\x81\x80\x00\x1a\x1d\x18\x80\x01\x18\x23\x72\x00\x00\xb6\x80\x10\x25\x7b\x97\x21\x53\x01\x27\x9a\x75\x01\x16\x2b\x70\x00\x00\xb6\xd0\xed\x95\x43\x10\x37\xce\xe0\x7a\x94\x36\x54\x01\x16\x70\x01\x19\x24\x51\x00\x00\xb7\x00\x00\x14\xc7\x63\x0c\x00\x03\xfe\x03\x00\x03\x1a\x25\x91\x00\x00\xb6\x80\x42\x07\xdf\x5c\x70\x41\x01\x00\x8c\x44\x20\x00\x42\x8c\x40\x14\x61\x05\x02\xb4\xad\x6c\xb0\x04\x20\x00\xbb\xb0\x00\x13\x41\x0a\x02\xb8\xbb\xd6\x00\x03\x60\x00\x08\x1b\x37\x71\x00\x49\x24\x00\x00\x08\x18\x20\x18\x08\x7e\xe7\x00\x0f\xe1\x40\x08\x0a\x00\x04\x0f\xe1\x40\x18\x16\x00\x04\x0f\xe1\x40\x1a\x1f\x07\x07\x0f\xe1\x40\x01\x06\x07\x07\x0f\xe1\x40\x08\x0a\x0e\x0a\x0f\xe1\x40\x18\x16\x0e\x0a\x34\x51\x06\x04\x49\x24\x00\x01\x21\x48\x10\x60\x3d\x80";
        bytes
            memory index = "\x00\x00\x00\x11\x00\x29\x00\x55\x00\x69\x00\x84\x00\x96\x00\xac\x00\xbe\x00\xee";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getMouth(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x02\x1c\x45\xb3\x00\x00\xaa\xe5\x58\x50\x81\x86\x00\x65\x14\x8a\x88\xa2\x81\x45\x00\xa2\x89\x24\x04\x40\x00\x10\x19\x24\xa2\x80\x3c\x71\x06\x1b\xaa\xe5\x40\x71\xc6\x00\x84\x4e\xde\xf9\x9a\xb8\x00\x35\x99\xcc\x99\x53\x00\x02\x1c\x3d\xb3\x00\x00\xb6\xeb\x40\x71\x20\x02\x10\x82\x0e\x61\xca\xb0\xc3\x4d\xb8\x99\xc0\xa6\x99\x19\x34\x10\x45\x00\x01\x41\x04\xd6\x64\xa6\x90\x2d\x71\x09\x1a\xb6\xd0\x9a\x06\x13\x38\x60\x01\x15\x38\x25\x98\xad\xff\xfd\xa6\x00\x07\xa0\x02\x1c\x3d\xb3\x00\x00\xb6\xeb\x40\x6e\xdd\xb6\xda\xfb\xea\x6d\xb3\x07\x1c\x00\x00\x25\xb0\x92\x4a\x68\x38\x10\x44\x00\x01\x01\x04\xea\x29\x92\x40\x2d\x71\x07\x1a\xba\xe0\x50\xb0\x00\x05\x49\xe8\xa1\xd5\x00\xaa\xcc\x00\x0c\xca\xa0\x01\x16\x3f\xb1\x00\xb6\xeb\x40\x47\x47\x35\x1d\x1d\x02\x00\x00\x11\x47\x8e\x8e\x8c\x71\x71\x59\x47\x47\x1c\x73\x40\x00\xaa\x28\x82\x0a\x28\x28\x00\x0d\x1c\x70\x01\x16\x47\xb1\x00\xb7\x5b\x68\x85\x78\x5f\x58\x4f\x48\x48\x41\x38\x31\x18\x0b\x00\x0b\x1f\x1f\x49\x71\x85\x90\x85\x38\x02\xcb\x30\x92\x4c\x2c\xb0\x0e\x6e\xda\x28\x7e\x8b\x5b\x38\x02\x1c\x3f\xb3\x00\xb6\xdb\x40\x46\x25\x00\x01\x05\x1c\x1c\x33\x45\x46\x47\x59\x70\x70\x87\x8b\x8c\x67\x46\xcb\x28\xe0\x28\x00\x10\x20\x82\x10\x00\x02\xa0\x8f\x2c\x80\x2d\x71\x29\x22\xb7\x50\x74\xe1\x40\x29\x37\x71\xeb\x5b\x1d\x00\x7c\xef\xfe\xc7\x00\x02\x1c\x3f\xb3\x00\xb7\x5b\x80\x0b\x11\x28\x36\x3d\x49\x49\x55\x5d\x6a\x81\x87\x92\x79\x49\x00\x0b\x30\x10\x06\x24\x51\x49\x18\x00\x4c\x7e\xeb\x9f\x30\x2d\x71\x2c\x20\xba\xe0\x00\xa4\xdd\xc3\xad\x6c\x74\x50\x00\xbd\xee\xdb\x60\x06\xb0";
        bytes
            memory index = "\x00\x00\x00\x37\x00\x73\x00\xad\x00\xd5\x01\x02\x01\x41";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }

    function getTeeth(uint256 i) public pure returns (Model memory) {
        bytes
            memory data = "\x02\x1d\x13\x71\x00\x00\xb4\xaa\x76\x40\x00\x13\xbf\xa0\x00\x13\x71\x0a\x00\xb4\xa9\x65\x41\x00\x03\xcf\xb3\x10\x02\x1d\x1a\x51\x0a\x00\x49\x00\x03\x60\x3f\x80\x1a\x51\x00\x01\x49\x00\x03\xf0\x1b\x00\x01\x1d\x13\x91\x00\x00\xb4\x99\x76\x40\x00\x08\x67\x79\x00\x00\x01\x1d\x13\x71\x00\x00\xb4\x98\x65\x30\x00\x13\xbf\xa0\x00\x01\x1d\x2b\x71\x00\x00\x6a\xc0\x08\x94\x00\xe2\x10\x0e\x01\x1d\x3d\x71\x00\x00\xaa\xe5\x40\x4d\x97\xe5\x9a\x06\x13\x18\x00\x47\x35\x30\xbb\xa9\x24\x00\x42\x9a\xbb";
        bytes memory index = "\x00\x00\x00\x1c\x00\x32\x00\x42\x00\x51\x00\x5f";
        Data.Reader memory reader;

        return
            _getModel(reader.set(reader.set(i << 1).nextUint16(index)), data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Data.sol";

uint256 constant ARMS_PART_COUNT = 2;
uint256 constant LEGS_PART_COUNT = 2;
uint256 constant EARS_PART_COUNT = 5;
uint256 constant EYES_PART_COUNT = 8;

library Traits {
    using Data for Data.Reader;

    struct Model {
        uint256 id;
        uint256 x;
        uint256 y;
        bool flip;
    }

    struct Part {
        Model[] models;
    }

    struct Trait {
        uint256 nameId;
        uint256 materialId;
        Part[] parts;
    }

    function _getTrait(
        bytes memory data,
        uint256 pos,
        uint256 partCount
    ) private pure returns (Trait memory) {
        Data.Reader memory reader = Data.Reader(pos);
        Trait memory trait = Trait(
            reader.nextUint8(data),
            reader.nextUint8(data),
            new Part[](partCount)
        );

        for (uint256 i; i < partCount; i++) {
            uint256 modelCount = reader.nextUint8(data);
            Part memory part = trait.parts[i];
            part.models = new Model[](modelCount);

            for (uint256 j; j < modelCount; j++) {
                part.models[j] = Model(
                    reader.nextUint8(data),
                    reader.nextUint8(data),
                    reader.nextUint8(data),
                    reader.nextUint8(data) == 1
                );
            }
        }

        return trait;
    }

    function getBody(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x00\x01\x02\x00\x45\x30\x00\x01\x66\xb8\x00\x09\x02\x02\x02\x3b\x25\x00\x01\x66\xb8\x00\x0a\x03\x02\x03\x44\x2c\x00\x04\x6a\xb9\x00\x0c\x04\x02\x05\x38\x2c\x00\x06\x61\xb5\x00\x0d\x05\x02\x07\x44\x2c\x00\x08\x66\xb8\x00\x0e\x06\x02\x09\x46\x30\x00\x0a\x65\xb6\x00\x0f\x07\x02\x0b\x45\x26\x00\x0c\x66\xb2\x00\x10\x08\x02\x0d\x45\x2b\x00\x0e\x66\xb8\x00";
        bytes8 index = "\x00\x0b\x16\x21\x2c\x37\x42\x4d";

        return _getTrait(data, uint8(index[i]), 1);
    }

    function getCheeks(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x11\x01\x01\x00\x1a\x6b\x00\x12\x01\x01\x01\x20\x6b\x00\x13\x01\x01\x02\x14\x6b\x00\x14\x01\x01\x03\x14\x6b\x00";
        bytes4 index = "\x00\x07\x0e\x15";

        return _getTrait(data, uint8(index[i]), 1);
    }

    function getLegs(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x00\x01\x02\x00\x47\xb8\x00\x00\xb9\xb8\x01\x02\x01\x5d\xc4\x00\x01\xa3\xc4\x01\x15\x09\x02\x02\x38\xb6\x00\x02\xc8\xb6\x01\x02\x03\x54\xc1\x00\x03\xac\xc1\x01\x16\x0a\x02\x04\x47\xb8\x00\x04\xb9\xb8\x01\x02\x05\x5d\xc4\x00\x05\xa3\xc4\x01\x17\x0b\x02\x06\x36\xbb\x00\x06\xca\xbb\x01\x02\x07\x5a\xc5\x00\x07\xa6\xc5\x01\x18\x0c\x02\x08\x3b\xba\x00\x08\xc5\xba\x01\x02\x09\x5c\xc2\x00\x09\xa4\xc2\x01\x19\x0d\x02\x0a\x05\xba\x00\x0a\xfb\xba\x01\x02\x0b\x1e\xc5\x00\x0b\xe2\xc5\x01\x1a\x0e\x02\x0c\x40\xb7\x00\x0c\xc0\xb7\x01\x02\x0d\x58\xc5\x00\x0d\xa8\xc5\x01\x0e\x06\x02\x0e\x37\xb9\x00\x0e\xc9\xb9\x01\x02\x0f\x51\xc3\x00\x0f\xaf\xc3\x01";
        bytes8 index = "\x00\x14\x28\x3c\x50\x64\x78\x8c";

        return _getTrait(data, uint8(index[i]), LEGS_PART_COUNT);
    }

    function getArms(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x00\x01\x02\x00\x0a\xa6\x00\x00\xf6\xa6\x01\x02\x01\x22\x69\x00\x01\xde\x69\x01\x15\x09\x02\x02\x04\x9e\x00\x02\xfc\x9e\x01\x02\x03\x1f\x69\x00\x03\xe1\x69\x01\x17\x0b\x02\x04\x04\xb8\x00\x04\xfc\xb8\x01\x02\x05\x04\x60\x00\x05\xfc\x60\x01\x18\x0c\x02\x06\x1c\xaa\x00\x06\xe4\xaa\x01\x02\x07\x20\x7f\x00\x07\xe0\x7f\x01\x19\x0d\x02\x08\x0d\xa5\x00\x08\xf3\xa5\x01\x02\x09\xe9\x6f\x01\x09\x17\x6f\x00\x0a\x03\x02\x0a\x0d\xa3\x00\x0a\xf3\xa3\x01\x02\x0b\x07\x6c\x00\x0b\xf9\x6c\x01\x1a\x0e\x02\x0c\x01\x92\x00\x0c\xff\x92\x01\x02\x0d\x02\x5a\x00\x0d\xfe\x5a\x01\x0e\x06\x02\x0e\x02\x7a\x00\x0e\xfe\x7a\x01\x02\x0f\x04\x39\x00\x0f\xfc\x39\x01";
        bytes8 index = "\x00\x14\x28\x3c\x50\x64\x78\x8c";

        return _getTrait(data, uint8(index[i]), ARMS_PART_COUNT);
    }

    function getEars(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x00\x01\x01\x00\x1c\x4c\x00\x01\x00\xe4\x4c\x01\x01\x01\x37\x1f\x00\x01\x01\xc9\x1f\x01\x01\x02\x67\x03\x00\x1b\x0f\x01\x03\x1f\x49\x00\x01\x03\xe1\x49\x01\x01\x04\x39\x23\x00\x01\x04\xc7\x23\x01\x01\x05\x64\x04\x00\x1c\x10\x01\x06\x15\x48\x00\x01\x06\xeb\x48\x01\x01\x07\x15\x11\x00\x01\x07\xeb\x11\x01\x01\x08\x6a\x03\x00\x16\x0a\x01\x09\x1a\x4d\x00\x01\x09\xe6\x4d\x01\x01\x0a\x2d\x0d\x00\x01\x0a\xd3\x0d\x01\x01\x0b\x72\x07\x00\x1a\x0e\x01\x0c\x16\x21\x00\x01\x0c\xea\x21\x01\x01\x0d\x38\x07\x00\x01\x0d\xc8\x07\x01\x01\x0e\x68\x02\x00\x0e\x06\x01\x0f\x0c\x10\x00\x01\x0f\xf3\x10\x01\x01\x10\x33\x04\x00\x01\x10\xcd\x04\x01\x01\x11\x52\x03\x00\x0a\x03\x01\x12\x2f\x1d\x00\x01\x12\xd1\x1d\x01\x01\x13\x54\x08\x00\x01\x13\xac\x08\x01\x01\x14\x77\x05\x00\x0f\x07\x01\x15\x12\x4d\x00\x01\x15\xee\x4d\x01\x01\x16\x37\x13\x00\x01\x16\xc9\x13\x01\x01\x17\x68\x03\x00";
        bytes8 index = "\x00\x1b\x36\x51\x6c\x87\xa2\xbd";

        return _getTrait(data, uint8(index[i]), EARS_PART_COUNT);
    }

    function getEyes(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x15\x11\x02\x00\x3e\x87\x00\x01\x46\x90\x00\x02\x00\xc2\x87\x01\x01\xba\x90\x01\x02\x02\x4d\x53\x00\x03\x57\x5c\x00\x02\x02\xb3\x53\x01\x03\xa9\x5c\x01\x02\x04\x6f\x4c\x00\x05\x7e\x56\x00\x02\x06\x5c\x3a\x00\x07\x63\x41\x00\x02\x06\xa4\x3a\x01\x07\x9d\x41\x01\x02\x08\x77\x34\x00\x09\x7e\x3a\x00\x1d\x12\x01\x0a\x41\x8b\x00\x01\x0a\xbf\x8b\x01\x01\x0b\x51\x5a\x00\x01\x0b\xaf\x5a\x01\x01\x0c\x70\x4e\x00\x01\x0d\x5d\x40\x00\x01\x0d\xa3\x40\x01\x01\x0e\x75\x35\x00\x18\x13\x01\x0f\x44\x82\x00\x01\x0f\xbc\x82\x01\x01\x10\x53\x5e\x00\x01\x10\xad\x5e\x01\x02\x11\x65\x52\x00\x11\x9b\x52\x01\x01\x12\x5c\x43\x00\x01\x12\xa4\x43\x01\x02\x13\x6d\x36\x00\x13\x93\x36\x01\x19\x11\x02\x00\x3e\x87\x00\x14\x42\x8e\x00\x02\x00\xc2\x87\x01\x14\xbe\x8e\x01\x02\x02\x4d\x53\x00\x15\x53\x5b\x00\x02\x02\xb3\x53\x01\x15\xad\x5b\x01\x02\x04\x6f\x4c\x00\x16\x74\x53\x00\x02\x06\x5c\x3a\x00\x17\x61\x40\x00\x02\x06\xa4\x3a\x01\x17\x9f\x40\x01\x02\x08\x77\x34\x00\x18\x79\x39\x00\x16\x14\x01\x19\x44\x89\x00\x01\x19\xbc\x89\x01\x01\x1a\x51\x5e\x00\x01\x1a\xaf\x5e\x01\x01\x1b\x6d\x53\x00\x01\x1c\x59\x48\x00\x01\x1c\xa7\x48\x01\x01\x1d\x74\x3e\x00\x17\x11\x02\x1e\x3b\x7e\x00\x1f\x3b\x81\x00\x02\x1e\xc5\x7e\x01\x1f\xc5\x81\x01\x02\x20\x40\x46\x00\x21\x46\x4b\x00\x02\x20\xc0\x46\x01\x21\xba\x4b\x01\x02\x22\x6d\x47\x00\x23\x73\x4b\x00\x02\x24\x4e\x27\x00\x25\x52\x2d\x00\x02\x24\xb2\x27\x01\x25\xae\x2d\x01\x02\x26\x6f\x25\x00\x27\x76\x28\x00\x1a\x11\x02\x00\x3e\x87\x00\x28\x42\x89\x00\x02\x00\xc2\x87\x01\x28\xbe\x89\x01\x02\x02\x4d\x53\x00\x29\x52\x56\x00\x02\x02\xb3\x53\x01\x29\xae\x56\x01\x02\x04\x6f\x4c\x00\x2a\x73\x4d\x00\x02\x06\x5c\x3a\x00\x2b\x63\x3d\x00\x02\x06\xa4\x3a\x01\x2b\x9d\x3d\x01\x02\x08\x77\x34\x00\x2c\x79\x36\x00\x1e\x15\x01\x2d\x48\x84\x00\x01\x2d\xb8\x84\x01\x01\x2e\x53\x56\x00\x01\x2e\xad\x56\x01\x01\x2f\x75\x4b\x00\x01\x30\x5d\x43\x00\x01\x30\xa3\x43\x01\x01\x31\x76\x36\x00";
        bytes
            memory index = "\x00\x00\x00\x4a\x00\x74\x00\xa6\x00\xf0\x01\x1a\x01\x64\x01\xae";
        Data.Reader memory reader = Data.Reader(i << 1);

        return _getTrait(data, reader.nextUint16(index), EYES_PART_COUNT);
    }

    function getNose(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x00\x16\x03\x00\x7f\x78\x00\x00\x81\x78\x01\x01\x72\x6a\x00\x15\x17\x03\x00\x7f\x78\x00\x00\x81\x78\x01\x02\x76\x6b\x00\x1d\x16\x03\x00\x7f\x78\x00\x00\x81\x78\x01\x03\x74\x69\x00\x1b\x18\x05\x00\x7f\x78\x00\x00\x81\x78\x01\x04\x6e\x6b\x00\x05\x73\x6f\x00\x05\x8d\x6f\x01\x16\x16\x04\x00\x7f\x78\x00\x00\x81\x78\x01\x06\x6c\x70\x00\x06\x94\x70\x01\x1c\x19\x03\x00\x81\x78\x01\x00\x7f\x78\x00\x07\x74\x73\x00\x0e\x1a\x03\x00\x7f\x78\x00\x00\x81\x78\x01\x08\x70\x6b\x00\x0f\x1b\x03\x00\x7f\x78\x00\x00\x81\x78\x01\x09\x70\x6c\x00";
        bytes8 index = "\x00\x0f\x1e\x2d\x44\x57\x66\x75";

        return _getTrait(data, uint8(index[i]), 1);
    }

    function getMouth(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x21\x16\x00\x22\x1c\x01\x00\x6c\x87\x00\x23\x1c\x01\x01\x64\x87\x00\x24\x1c\x01\x02\x65\x87\x00\x25\x16\x01\x03\x39\x7f\x00\x26\x16\x01\x04\x38\x7c\x00\x27\x1c\x01\x05\x3a\x7e\x00\x28\x1c\x01\x06\x37\x81\x00";
        bytes8 index = "\x00\x03\x0a\x11\x18\x1f\x26\x2d";

        return _getTrait(data, uint8(index[i]), 1);
    }

    function getTeeth(uint256 i) internal pure returns (Trait memory) {
        bytes
            memory data = "\x29\x1d\x00\x2a\x1d\x02\x00\x6c\x88\x00\x00\x94\x88\x01\x2b\x1d\x02\x01\x6e\x88\x00\x01\x92\x88\x01\x2c\x1d\x02\x02\x6c\x88\x00\x02\x94\x88\x01\x2d\x1d\x01\x03\x6c\x88\x00\x2e\x1d\x01\x03\x94\x88\x01\x2f\x1d\x02\x04\x80\x87\x00\x04\x80\x87\x01\x30\x1d\x01\x05\x6d\x87\x00";
        bytes8 index = "\x00\x03\x0e\x19\x24\x2b\x32\x3d";

        return _getTrait(data, uint8(index[i]), 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Renderable {
    struct Mutyte {
        uint256 dna;
        uint256 colorId;
        uint256 bodyId;
        uint256 cheeksId;
        uint256 legsId;
        bool[2] legs;
        uint256 armsId;
        bool[2] arms;
        uint256 earsId;
        bool[5] ears;
        uint256 eyesId;
        bool[8] eyes;
        uint256 noseId;
        uint256 mouthId;
        uint256 teethId;
        uint256 bgShapes;
        uint256 mutationLevel;
    }

    function fromDNA(uint256 dna) internal pure returns (Mutyte memory) {
        Mutyte memory mutyte;
        dna >>= 202;
        mutyte.dna = dna;
        mutyte.colorId = (dna >> 51) & 7;
        mutyte.bodyId = (dna >> 48) & 7;
        mutyte.cheeksId = (dna >> 46) & 3;
        mutyte.legsId = (dna >> 43) & 7;
        mutyte.legs = [(dna >> 42) & 1 == 1, (dna >> 41) & 1 == 1];
        mutyte.armsId = (dna >> 38) & 7;
        mutyte.arms = [(dna >> 37) & 1 == 1, (dna >> 36) & 1 == 1];
        mutyte.earsId = (dna >> 33) & 7;
        mutyte.ears = [
            (dna >> 32) & 1 == 1,
            (dna >> 31) & 1 == 1,
            (dna >> 30) & 1 == 1,
            (dna >> 29) & 1 == 1,
            (dna >> 28) & 1 == 1
        ];
        mutyte.eyesId = (dna >> 25) & 7;
        mutyte.eyes = [
            (dna >> 24) & 1 == 1,
            (dna >> 23) & 1 == 1,
            (dna >> 22) & 1 == 1,
            (dna >> 21) & 1 == 1,
            (dna >> 20) & 1 == 1,
            (dna >> 19) & 1 == 1,
            (dna >> 18) & 1 == 1,
            (dna >> 17) & 1 == 1
        ];
        mutyte.noseId = (dna >> 14) & 7;
        mutyte.mouthId = (dna >> 11) & 7;
        mutyte.teethId = (dna >> 8) & 7;
        mutyte.bgShapes = (dna) & 0xFF;

        uint256 variation = (((dna >> 41) & 1) +
            ((dna >> 37) & 1) +
            ((dna >> 36) & 1)) +
            (((dna >> 32) & 1) +
                ((dna >> 31) & 1) +
                ((dna >> 30) & 1) +
                ((dna >> 29) & 1) +
                ((dna >> 28) & 1)) +
            (((dna >> 24) & 1) +
                ((dna >> 23) & 1) +
                ((dna >> 22) & 1) +
                ((dna >> 21) & 1) +
                ((dna >> 20) & 1) +
                ((dna >> 19) & 1) +
                ((dna >> 18) & 1) +
                ((dna >> 17) & 1));

        if (variation > 7) {
            mutyte.mutationLevel = variation - 7;
            if (mutyte.mutationLevel > 7) {
                mutyte.mutationLevel = 7;
            }
        }

        return mutyte;
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

library Data {
    struct Reader {
        uint256 _pos;
    }

    function set(Reader memory reader, uint256 pos)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos = pos;
        return reader;
    }

    function skip(Reader memory reader, uint256 count)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos += count;
        return reader;
    }

    function rewind(Reader memory reader, uint256 count)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos -= count;
        return reader;
    }

    function next(Reader memory reader, bytes memory data)
        internal
        pure
        returns (bytes1)
    {
        return data[reader._pos++];
    }

    function nextUint8(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 1)
            num := and(mload(add(data, pos)), 0xFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint16(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 2)
            num := and(mload(add(data, pos)), 0xFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint24(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 3)
            num := and(mload(add(data, pos)), 0xFFFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint56(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 7)
            num := and(mload(add(data, pos)), 0xFFFFFFFFFFFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextString32(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (string memory) {
        string memory res = new string(32);

        assembly {
            mstore(add(res, 0x20), mload(add(add(data, mload(reader)), 0x20)))
            mstore(res, length)
        }

        skip(reader, length);

        return res;
    }

    function nextUintArray(
        Reader memory reader,
        uint256 bitSize,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (bitSize * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)
            let filter := shr(sub(8, bitSize), 0xFF)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, bitSize)
                let input := mload(dataPtr)
                mstore(add(resPtr, 0xE0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xC0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xA0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x80), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x60), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x40), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x20), and(input, filter))
                input := shr(bitSize, input)
                mstore(resPtr, and(input, filter))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUintArray(
        Reader memory reader,
        uint256 bitSize,
        bytes memory data,
        uint256 length,
        uint256 offset
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (bitSize * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)
            let filter := shr(sub(8, bitSize), 0xFF)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, bitSize)
                let input := mload(dataPtr)
                mstore(add(resPtr, 0xE0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xC0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xA0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x80), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x60), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x40), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x20), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(resPtr, add(offset, and(input, filter)))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUint3Array(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (3 * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, byteLength)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resPtr, and(shr(21, input), 0x7))
                mstore(add(resPtr, 0x20), and(shr(18, input), 0x7))
                mstore(add(resPtr, 0x40), and(shr(15, input), 0x7))
                mstore(add(resPtr, 0x60), and(shr(12, input), 0x7))
                mstore(add(resPtr, 0x80), and(shr(9, input), 0x7))
                mstore(add(resPtr, 0xA0), and(shr(6, input), 0x7))
                mstore(add(resPtr, 0xC0), and(shr(3, input), 0x7))
                mstore(add(resPtr, 0xE0), and(input, 0x7))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUint8Array(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](length);

        assembly {
            let resPtr := add(res, 0x20)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x20)
            } {
                dataPtr := add(dataPtr, 1)
                mstore(resPtr, and(mload(dataPtr), 0xFF))
            }
        }

        skip(reader, length);

        return res;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Strings.sol";
import "../utils/Buffers.sol";

library Paths {
    using Strings for uint256;
    using Buffers for Buffers.Writer;

    bytes private constant _PATH_OPS = "ZMLHVCS";

    struct Path {
        bool fill;
        bool stroke;
        uint256 fillId;
        string d;
    }

    function getDescription(
        uint256[] memory ops,
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (string memory) {
        uint256 xi = 1;
        uint256 yi = 1;
        bytes1 op;
        Buffers.Writer memory d = Buffers.getWriter(800);
        d.writeWords("M", x[0].toString3(), " ", y[0].toString3());

        unchecked {
            for (uint256 i; i < ops.length; ) {
                d.writeChar(op = _PATH_OPS[ops[i++]]);

                if (op == "C") {
                    d.writeSentence(
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3()
                    );
                } else if (op == "L" || op == "M") {
                    d.writeSentence(x[xi++].toString3(), y[yi++].toString3());
                } else if (op == "H") {
                    d.writeWord(x[xi++].toString3());
                } else if (op == "V") {
                    d.writeWord(y[yi++].toString3());
                } else if (op == "S") {
                    d.writeSentence(
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3()
                    );
                }
            }
        }

        return d.toString();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
            unchecked {
                digits++;
                temp /= 10;
            }
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation of up to 3 characters.
     */
    function toString3(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        string memory buffer;

        if (value > 99) {
            buffer = new string(3);
            assembly {
                mstore8(add(buffer, 0x20), add(div(value, 100), 0x30))
                value := mod(value, 100)
                mstore8(add(buffer, 0x21), add(div(value, 10), 0x30))
                mstore8(add(buffer, 0x22), add(mod(value, 10), 0x30))
            }
        } else if (value > 9) {
            buffer = new string(2);
            assembly {
                mstore8(add(buffer, 0x20), add(div(value, 10), 0x30))
                mstore8(add(buffer, 0x21), add(mod(value, 10), 0x30))
            }
        } else {
            buffer = new string(1);
            assembly {
                mstore8(add(buffer, 0x20), add(value, 0x30))
            }
        }

        return buffer;
    }
}