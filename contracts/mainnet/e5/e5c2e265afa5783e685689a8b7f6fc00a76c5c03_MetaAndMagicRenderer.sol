// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @dev Contract responsible for handling metadata requests for both Heroes and Items address
contract MetaAndMagicRenderer {

    mapping(uint256 => address) decks; // 
    mapping(bytes4 => address)  svgs; // svg to trait indicator to address that stores it

    string constant heroDesc = unicode"Meta & Magic Heroes is a collection of 3,000 genesis heroes to fight in a 100% on-chain NFT game. ⛓️ Can you defeat the bosses to win? 🏆 Season I 😈 Equip weapons 🗡️ Cast spells 🔥 ERC-721A standard 🍒";
    string constant itemDesc = unicode"Meta & Magic Items is a collection of 10,000 relics that can be equipped by genesis heroes to fight in a 100% on-chain NFT game. ⛓  Can you defeat the bosses to win? 🏆 Season I 😈 Equip weapons 🗡️ Cast spells 🔥 ERC-721A standard 🍒";

    string constant header = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="mm" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">';
    string constant footer = '<style>#hero{shape-rendering: crispedges;image-rendering: -webkit-crisp-edges;image-rendering: -moz-crisp-edges;image-rendering: crisp-edges;image-rendering: pixelated;-ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta) {
        meta = _getMetadata(id, traits, cat);
    }

    function getPlaceholder(uint256 cat) external pure returns (string memory meta){
        meta = _getPlaceholderMetadata(cat);
    }

    function setSvg(bytes4 sig, address impl) external {
            svgs[sig] = impl;   
    }

    function setSvgs(bytes4[] calldata sigs, address impl) external {
        for (uint256 i = 0; i < sigs.length; i++) {
            svgs[sigs[i]] = impl;   
        }
    }

    function setDeck(uint256 cat, address deck) external {
        decks[cat] = deck;
    }

    // Categories Documentation
    // 1 - Hero
    // 2 - Items
    // 3 - Hero Boss Drop
    // 4 - Items Boss Drop
    // 5 - 20 Are 1-of-1 following the order laid out in _getUniqueName

    function _getMetadata(uint256 id, uint256[6] calldata traits, uint256 cat) internal view returns (string memory meta) {
        string memory svg = _getSvg(id, cat, traits);

        meta = 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Strings.encode(
                        abi.encodePacked(
                            '{"name":',  _getName(id, cat),
                            ',"description":"',cat % 2 == 1 ? heroDesc : itemDesc,
                            '","image": "data:image/svg+xml;base64,', svg,
                            '","attributes":[', _getAttributes(id, cat, traits),']}')
                        )
                    )
                );
    }

    function _getPlaceholderMetadata(uint256 cat) internal pure returns (string memory meta) {
        meta = 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Strings.encode(
                        abi.encodePacked(
                            '{"name":"', cat == 1 ? 'Unrevealed Hero' : 'Unrevealed Item',
                            '","description":"',cat == 1 ? heroDesc : itemDesc,
                            '","image": "', cat == 1 ?'https://bafybeiejxuylnujaxbarjogla2fi7qhougbvuzrdhy6r4zhwqj7onbyz2i.ipfs.infura-ipfs.io/' : 'https://bafybeiftizk7brkixhhxbj3ooz7qnh46hdqligeg64m76fhkf54clnvk6i.ipfs.infura-ipfs.io/',
                            '","attributes":[]}')
                        )
                    )
                );
    }



    function _getName(uint256 id, uint256 cat) internal pure returns (string memory name) {
        string memory category;

        if (cat == 1) category = string(abi.encodePacked('Hero #', Strings.toString(id)));

        if (cat == 2) {
            uint class = id % 4;
            string memory className;
            if (class <= 1) className = class == 0 ? "Attack" : "Defense"; 
            if (class > 1)  className = class == 2 ? "Spell" : "Buff"; 
            category = string(abi.encodePacked(className, ' #', Strings.toString(id)));
        }


        if (cat == 3 || cat == 4) category = string(abi.encodePacked('Boss Drop #', Strings.toString(id)));
        if (cat >= 5) category = _getUniqueName(cat);

        name = string(abi.encodePacked('"',category,'"'));
    }

    function _getAttributes(uint256 id, uint256 cat, uint256[6] calldata traits) internal view returns (string memory atts) {
        if (cat > 4) return string(abi.encodePacked('{"trait_type":"One-of-One","value":"',_getUniqueName(cat),'"}'));

        string[6] memory names = IDecks(decks[cat % 2 == 0 ? 2 : 1]).getTraitsNames(id, traits);

        return string(abi.encodePacked(names[0],',', names[1],',', names[2],',', names[3],',', names[4],',', names[5]));
    }

    function _getUniqueName(uint256 cat) internal pure returns (string memory name) {
        if (cat == 5)  name = "Alexander the Great";
        if (cat == 6)  name = "Excalibur of King Arthur";
        if (cat == 7)  name = "Brahma";
        if (cat == 8)  name = "Mjolnir of Thor";
        if (cat == 9)  name = "Mutant Ape";
        if (cat == 10) name = "Headband of Wukong";
        if (cat == 11) name = "Fujibayashi Nagato";
        if (cat == 12) name = "Achilles Armor";
        if (cat == 13) name = "Hou Yi";
        if (cat == 14) name = "Avada Kedavra";
        if (cat == 15) name = "Merlin";
        if (cat == 16) name = "Kamehameha";
        if (cat == 17) name = "Rasputin";
        if (cat == 18) name = "Urim and Thummim";
        if (cat == 20) name = "Philosopher's Stone";
    }


    function _getSvg(uint256 id, uint256 cat, uint256[6] memory traits) internal view returns (string memory svg) {
        string memory content = cat > 4 ? _getSingleSvg(cat) : _getLayeredSvg(id, cat, traits);

        svg = Strings.encode(abi.encodePacked(header, content ,footer));
    }

    function _getSingleSvg(uint256 cat) internal view returns (string memory svg) {
        bytes4 sig = bytes4(keccak256(abi.encodePacked(string((abi.encodePacked("one", Strings.toString(cat), '()'))))));
        svg = wrapSingleTag(call(svgs[sig], sig));
    }

    function _getLayeredSvg(uint256 id, uint256 cat, uint256[6] memory traits) internal view returns (string memory svg) {
        bytes4[6] memory layers = [bytes4(0),bytes4(0),bytes4(0),bytes4(0),bytes4(0), bytes4(0)];

        for (uint256 i = 0; i < 6; i++) {
            // Hero
            if (cat == 1 || cat == 3) {
                layers[i] = bytes4(keccak256(abi.encodePacked((string(abi.encodePacked("hero", Strings.toString(i), Strings.toString(traits[i]),'()'))))));
                if (i == 2) {
                    // overriding rank trait
                    layers[i] = bytes4(keccak256(abi.encodePacked(string((abi.encodePacked("hero", Strings.toString(i), Strings.toString(traits[i - 1]), Strings.toString(traits[i]),'()'))))));
                }
            }
            if (cat == 2 || cat == 4) {
                layers[i] = bytes4(keccak256(abi.encodePacked(string((abi.encodePacked("item", Strings.toString(cat == 2 ? id % 4 : 4), Strings.toString(i), Strings.toString(traits[i]),'()'))))));
            }
        }

        svg =  string(abi.encodePacked(
            wrapTag(call(svgs[layers[0]], layers[0])),
            wrapTag(call(svgs[layers[1]], layers[1])),
            wrapTag(call(svgs[layers[2]], layers[2])),
            wrapTag(call(svgs[layers[3]], layers[3])),
            wrapTag(call(svgs[layers[4]], layers[4])),
            wrapTag(call(svgs[layers[5]], layers[5]))
        ));
    }

    function call(address source, bytes4 sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(abi.encodeWithSelector(sig));
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function wrapSingleTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }
    
}

library Strings {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
}

interface IDecks {
    function getTraitsNames(uint256 id, uint256[6] calldata atts) external pure returns(string[6] memory names);
}