// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {IOneWarDescriptor} from "./interfaces/IOneWarDescriptor.sol";
import {IOneWar} from "./interfaces/IOneWar.sol";
import {NFTDescriptor} from "./libs/NFTDescriptor.sol";
import {Strings} from "./libs/Strings.sol";

contract OneWarDescriptor is IOneWarDescriptor {
    IOneWar public oneWar;

    constructor(IOneWar _oneWar) {
        oneWar = _oneWar;
    }

    function tokenURI(uint256 _settlement) external view override returns (string memory) {
        bool hasWarCountdownBegun = oneWar.hasWarCountdownBegun();
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: string(abi.encodePacked("Settlement #", Strings.toString(_settlement))),
            description: string(
                abi.encodePacked("Settlement #", Strings.toString(_settlement), " is a location in OneWar.")
            ),
            attributes: oneWar.settlementTraits(_settlement),
            extraAttributes: NFTDescriptor.ExtraAttributes({
                redeemableGold: oneWar.redeemableGold(_settlement),
                hasWarCountdownBegun: hasWarCountdownBegun,
                blocksUntilSanctuaryEnds: hasWarCountdownBegun ? oneWar.blocksUntilSanctuaryEnds(_settlement) : 0
            })
        });

        return NFTDescriptor.constructTokenURI(params);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IOneWar} from "./IOneWar.sol";

interface IOneWarDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWar {
    struct Settlement {
        uint32 soldiers;
        uint32 towers;
        uint32 catapults;
        uint256 goldRedeemed;
        uint256 genesis;
        uint256 seed;
        address founder;
        string motto;
        uint32 glory;
        uint256 sanctuary;
        uint256 treasure;
        uint256 miners;
    }

    struct DefenderAssets {
        uint32 soldiers;
        uint32 towers;
    }

    struct AttackerAssets {
        uint32 soldiers;
        uint32 catapults;
    }

    struct ArmyMove {
        uint256 source;
        uint256 destination;
        uint32 soldiers;
        uint32 catapults;
    }

    event Scout(address _by, uint256 indexed _blockNumber);

    event Settle(address _by, uint256 indexed _settlement);

    event Burn(uint256 indexed _settlement);

    event BuildArmy(uint256 indexed _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults);

    event MoveArmy(
        uint256 indexed _sourceSettlement,
        uint256 indexed _destinationSettlement,
        uint32 _soldiers,
        uint32 _catapults
    );

    event SuccessfulAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event FailedAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event ChangeMotto(uint256 indexed _settlement, string _motto);

    function hasWarCountdownBegun() external view returns (bool);

    function scout() external payable;

    function settle() external;

    function burn(uint256 _settlement) external;

    function commenceWarCountdown() external;

    function redeemableGold(uint256 _settlement) external view returns (uint256);

    function redeemGold(uint256[] calldata _settlements) external;

    function armyCost(uint32 _soldiers, uint32 _towers, uint32 _catapults) external pure returns (uint256);

    function buildArmy(uint256 _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults) external;

    function moveArmy(uint256 _sourceSettlement, uint256 _destinationSettlement, uint32 _soldiers, uint32 _catapults) external;

    function multiMoveArmy(ArmyMove[] calldata _moves) external;

    function attack(uint256 _attackingSettlement, uint256 _defendingSettlement, uint32 _soldiers, uint32 _catapults) external;

    function blocksUntilSanctuaryEnds(uint256 _settlement) external view returns (uint256);

    function blocksUntilWarBegins() external view returns (uint256);

    function changeMotto(uint256 _settlement, string memory _newMotto) external;

    function redeemFundsToOneWarTreasury() external;

    function settlementTraits(uint256 _settlement) external view returns (Settlement memory);

    function isRulerOrCoruler(address _address, uint256 _settlement) external view returns (bool);

    function isSettled(uint256 _settlement) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Base64} from "base64-sol/base64.sol";
import {IOneWar} from "../interfaces/IOneWar.sol";
import {Strings} from "./Strings.sol";

library NFTDescriptor {
    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    struct ExtraAttributes {
        uint256 redeemableGold;
        bool hasWarCountdownBegun;
        uint256 blocksUntilSanctuaryEnds;
    }

    struct TokenURIParams {
        string name;
        string description;
        IOneWar.Settlement attributes;
        ExtraAttributes extraAttributes;
    }

    enum AttributeType {
        PROPERTY,
        RANKING,
        STAT
    }

    struct Attribute {
        AttributeType attributeType;
        string svgHeading;
        string attributeHeading;
        string value;
        bool onSVG;
    }

    function constructTokenURI(TokenURIParams memory _params) internal pure returns (string memory) {
        Attribute[] memory formattedAttributes = formatAttributes(_params.attributes, _params.extraAttributes);
        string memory motto = _params.attributes.motto;
        string memory image = generateSVGImage(formattedAttributes, motto);
        string memory attributes = generateAttributes(formattedAttributes, motto);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _params.name,
                                '","description":"',
                                _params.description,
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '","attributes":',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function formatGold(uint256 _gold) internal pure returns (string memory) {
        string memory integer = string(abi.encodePacked(Strings.toString(_gold / GOLD_DENOMINATION)));
        string memory decimal;
        for (uint8 i = 0; i < GOLD_DECIMALS; i++) {
            uint256 digit = (_gold / 10**i) % 10;
            if (digit != 0 || bytes(decimal).length != 0) {
                decimal = string(abi.encodePacked(Strings.toString(digit), decimal));
            }
        }

        if (bytes(decimal).length != 0) {
            return string(abi.encodePacked(integer, ".", decimal));
        }

        return integer;
    }

    function formatAttributes(IOneWar.Settlement memory _attributes, ExtraAttributes memory _extraAttributes)
        internal
        pure
        returns (Attribute[] memory)
    {
        Attribute[] memory attributes = new Attribute[](_extraAttributes.hasWarCountdownBegun ? 12 : 11);
        attributes[0] = Attribute(
            AttributeType.STAT,
            "Soldiers",
            "Soldiers",
            Strings.toString(_attributes.soldiers),
            true
        );
        attributes[1] = Attribute(AttributeType.STAT, "Towers", "Towers", Strings.toString(_attributes.towers), true);
        attributes[2] = Attribute(
            AttributeType.STAT,
            "Catapults",
            "Catapults",
            Strings.toString(_attributes.catapults),
            true
        );
        attributes[3] = Attribute(
            AttributeType.STAT,
            "Treasure",
            "$GOLD Treasure",
            formatGold(_attributes.treasure),
            true
        );
        attributes[4] = Attribute(
            AttributeType.STAT,
            "Miners",
            "$GOLD Miners",
            Strings.toString(_attributes.miners),
            true
        );
        attributes[5] = Attribute(
            AttributeType.STAT,
            "Redeemed",
            "$GOLD Redeemed",
            formatGold(_attributes.goldRedeemed),
            false
        );
        attributes[6] = Attribute(
            AttributeType.STAT,
            "Redeemable",
            "$GOLD Redeemable",
            formatGold(_extraAttributes.redeemableGold),
            true
        );
        attributes[7] = Attribute(
            AttributeType.PROPERTY,
            "Genesis",
            "Genesis Block",
            Strings.toString(_attributes.genesis),
            true
        );
        attributes[8] = Attribute(
            AttributeType.PROPERTY,
            "Founder",
            "Founder",
            Strings.toString(_attributes.founder),
            true
        );
        attributes[9] = Attribute(AttributeType.RANKING, "Glory", "Glory", Strings.toString(_attributes.glory), true);
        attributes[10] = Attribute(
            AttributeType.STAT,
            "Sanctuary",
            "Sanctuary Duration",
            Strings.toString(_attributes.sanctuary),
            false
        );

        if (_extraAttributes.hasWarCountdownBegun) {
            attributes[11] = Attribute(
                AttributeType.STAT,
                "Sanctuary Remaining",
                "Blocks Until Sanctuary Ends",
                Strings.toString(_extraAttributes.blocksUntilSanctuaryEnds),
                false
            );
        }

        return attributes;
    }

    function generateSVGImage(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" '
        'preserveAspectRatio="xMinYMin meet" '
        'viewBox="0 0 300 300">'
        "<style>"
        'text { fill: #646464; font-family: "Courier New", monospace; font-size: 12px; } '
        ".motto { font-size: 8px; text-anchor: middle; font-style: italic; font-weight: bold; } "
        ".right { text-transform: uppercase; } "
        ".left > text { text-anchor: end; }"
        "</style>"
        "<rect "
        'width="100%" '
        'height="100%" '
        'fill="#eee"'
        "/>";

        if (bytes(_motto).length > 0) {
            svg = string(abi.encodePacked(svg, '<text x="150" y="22" class="motto">', _motto, "</text>"));
        }

        string memory headings = '<g class="right" transform="translate(170,55)">';
        string memory values = '<g class="left" transform="translate(130,55)">';

        uint16 _y = 0;
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            if (!attribute.onSVG) {
                continue;
            }

            string memory textOpen = string(abi.encodePacked('<text y="', Strings.toString(_y), '">'));

            headings = string(abi.encodePacked(headings, textOpen, attribute.svgHeading, "</text>"));

            string memory value = Strings.equal(attribute.svgHeading, "Founder")
                ? Strings.truncateAddressString(attribute.value)
                : attribute.value;

            values = string(abi.encodePacked(values, textOpen, value, "</text>"));

            _y += 25;
        }

        headings = string(abi.encodePacked(headings, "</g>"));
        values = string(abi.encodePacked(values, "</g>"));

        svg = string(
            abi.encodePacked(
                svg,
                "<path "
                'stroke="#696969" '
                'stroke-width="1.337" '
                'stroke-dasharray="10,15" '
                'stroke-linecap="round" '
                'd="M150 46 L150 256"'
                "/>",
                headings,
                values,
                "</svg>"
            )
        );

        return Base64.encode(bytes(svg));
    }

    /**
     * @notice Parse Settlement attributes into a string.
     */
    function generateAttributes(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory attributes = "[";
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            attributes = string(
                abi.encodePacked(
                    attributes,
                    "{",
                    AttributeType.STAT == attribute.attributeType ? '"display_type":"number",' : "",
                    '"trait_type":"',
                    attribute.attributeHeading,
                    '","value":',
                    AttributeType.STAT == attribute.attributeType || AttributeType.RANKING == attribute.attributeType
                        ? attribute.value
                        : string(abi.encodePacked('"', attribute.value, '"')),
                    "},"
                )
            );
        }

        attributes = string(abi.encodePacked(attributes, '{"trait_type":"Motto","value":"', _motto, '"}]'));

        return attributes;
    }
}

// SPDX-License-Identifier: Unlicense
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol) - MODIFIED
pragma solidity ^0.8.0;

library Strings {
    function toString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (_value == 0) {
            return "0";
        }

        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }

        return string(buffer);
    }

    // Source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string (MODIFIED)
    function toString(address _addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(40);
        for (uint8 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - i)))));
            bytes1 high = bytes1(uint8(b) / 16);
            bytes1 low = bytes1(uint8(b) - 16 * uint8(high));
            buffer[2 * i] = char(high);
            buffer[2 * i + 1] = char(low);
        }

        return string(abi.encodePacked("0x", string(buffer)));
    }

    function char(bytes1 _byte) internal pure returns (bytes1) {
        if (uint8(_byte) < 10) {
            return bytes1(uint8(_byte) + 0x30);
        } else {
            return bytes1(uint8(_byte) + 0x57);
        }
    }

    function truncateAddressString(string memory _str) internal pure returns (string memory) {
        bytes memory b = bytes(_str);
        return
            string(
                abi.encodePacked(
                    string(abi.encodePacked(b[0], b[1], b[2], b[3], b[4], b[5])),
                    "...",
                    string(abi.encodePacked(b[36], b[37], b[38], b[39], b[40], b[41]))
                )
            );
    }

    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
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