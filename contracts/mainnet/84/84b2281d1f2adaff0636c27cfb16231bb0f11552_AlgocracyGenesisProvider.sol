// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyProvider.sol";

abstract contract Utils {
    function _formatDerivation(uint256 id)
    internal pure returns (string memory) {
        string memory strId = _toString(id);
        if (id < 10) return string(abi.encodePacked("0.0", strId));
        if (id < 100) return string(abi.encodePacked("0.", strId));
        if (id < 629) {
            bytes memory tmp = bytes(strId);
            return string(abi.encodePacked(
                string(abi.encodePacked(tmp[0])),
                ".",
                string(abi.encodePacked(tmp[1])),
                string(abi.encodePacked(tmp[2]))
            ));
        }
        revert();
    }

    function _toString(uint256 value)
    internal pure returns (string memory ptr) {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for {
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)
        }
    }

    function _encode(bytes memory data)
    internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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
}

contract AlgocracyGenesisProvider is Utils {
    iAlgocracyProvider public RegexColor;
    iAlgocracyProvider public NFT;

    string public CID;

    struct Param {
        string background;
        string color;
        uint256 thickness;
        uint256 zoom;
    }

    mapping(uint256 => Param) ParamRegistry;
    mapping(uint256 => bool) ParamActivationRegistry;

    mapping(uint256 => uint256) MergeRegistry;
    mapping(uint256 => bool) MergeActivationRegistry;

    string generatorScript = string(abi.encodePacked(
        "const generatePath = (",
            "derivation, zoom, angle, points, x, y",
        ") => {",
            "let i = -1;",
            "while (++i < 1000) {",
                "angle = derivation * i;",
                "x = 7500 + (zoom * (angle)) * Math.cos((angle));",
                "y = 7500 + (zoom * (angle)) * Math.sin((angle));",
                "points.push(`${x} ${y}`);",
            "};",
            "return points;",
        "};"
    ));

    constructor(
        address _RegexColor,
        string memory _CID
    ) {
        CID = _CID;
        RegexColor = iAlgocracyProvider(_RegexColor);
        ParamRegistry[0] = Param("#000", "#fff", 1, 2);
    }

    function setProviderInterface(address _NFT)
    public {
        require(
            address(NFT) == address(0),
            "AlgocracyProvider::setNFT() - NFT Contract is already set"
        );
        NFT = iAlgocracyProvider(_NFT);
    }

    function setParam(
        uint256 id, uint256 mergeId,
        string memory background, string memory color,
        uint thickness, uint zoom
    ) public {
        require(
            NFT.exist(id),
            "AlgocracyGenesisProvider::setParam() - id do not exist"
        );
        require(
            NFT.ownerOf(id) == msg.sender,
            "AlgocracyGenesisProvider::setParam() - msg.sender is not owner of id"
        );
        require(
            RegexColor.matches(background),
            "AlgocracyGenesisProvider::setParam() - background do not match regex"
        );
        require(
            RegexColor.matches(color),
            "AlgocracyGenesisProvider::setParam() - color do not match regex"
        );
        require(
            thickness >= 1,
            "AlgocracyGenesisProvider::setParam() - thickness is out of bound"
        );
        require(
            zoom >= 1,
            "AlgocracyGenesisProvider::setParam() - zoom is out of bound"
        );
        
        if (mergeId > 0) {
            require(
                NFT.exist(mergeId),
                "AlgocracyGenesisProvider::setParam() - id do not exist"
            );
            require(
                NFT.ownerOf(mergeId) == msg.sender,
                "AlgocracyGenesisProvider::setParam() - msg.sender is not owner of id"
            );
            MergeRegistry[id] = mergeId;
            MergeActivationRegistry[id] = true;
        }

        ParamRegistry[id] = Param(background, color, thickness, zoom);
        ParamActivationRegistry[id] = true;
    }

    function unsetParam(uint256 id)
    public {
        require(
            NFT.exist(id),
            "AlgocracyGenesisProvider::unsetParam() - id do not exist"
        );
        require(
            NFT.ownerOf(id) == msg.sender,
            "AlgocracyGenesisProvider::unsetParam() - msg.sender is not owner of id"
        );
        delete ParamActivationRegistry[id];
        delete MergeActivationRegistry[id];
        delete ParamRegistry[id];
        delete MergeRegistry[id];
    }

    function modulusAsHTML(
        uint256 id, uint256 mergeId,
        string memory background, string memory color, 
        uint256 thickness, uint256 zoom
    ) public view returns (string memory) {
        require(
            NFT.exist(id),
            "AlgocracyGenesisProvider::modulusAsHTML() - id do not exist"
        );
        require(
            NFT.exist(mergeId),
            "AlgocracyGenesisProvider::modulusAsHTML() - mergeId do not exist"
        );
        require(
            RegexColor.matches(background),
            "AlgocracyGenesisProvider::modulusAsHTML() - background do not match regex"
        );
        require(
            RegexColor.matches(color),
            "AlgocracyGenesisProvider::modulusAsHTML() - color do not match regex"
        );
        require(
            thickness >= 1,
            "AlgocracyGenesisProvider::modulusAsHTML() - thickness is out of bound"
        );
        require(
            zoom >= 1,
            "AlgocracyGenesisProvider::modulusAsHTML() - zoom is out of bound"
        );
        return string(abi.encodePacked(
            'data:text/html;base64,',
            Utils._encode(bytes(
                string(abi.encodePacked(
                    "<title>ALGOCRACY #",Utils._toString(id),"</title>",
                    "<svg ",
                        "viewBox='0 0 15000 15000' ",
                        "style='background:",background,";width:100vw;height:100vh;margin:auto;position:absolute;inset:0;'>",
                        "<path ",
                            "id='algocracy' ",
                            "stroke='",color,"' ",
                            "fill='none' ",
                            "stroke-width='",Utils._toString(thickness),"'/>",
                        (id == mergeId ? 
                            '':
                            string(abi.encodePacked(
                                "<animate ",
                                    "href='#algocracy' ",
                                    "id='handlerX' ",
                                    "attributeName='d' ",
                                    "dur='10s' ",
                                    "begin='0s; handlerY.end'/>",
                                "<animate ",
                                    "href='#algocracy' ",
                                    "id='handlerY' ",
                                    "attributeName='d' ",
                                    "dur='10s' ",
                                    "begin='handlerX.end'/>"
                        ))),
                    "</svg>",
                    "<script>",
                        generatorScript,
                        (id == mergeId ? 
                            string(abi.encodePacked(
                                "let path = document.getElementById('algocracy');",
                                "let derivation = generatePath(",Utils._formatDerivation(id),", ",Utils._toString(zoom),", 0, [], 0, 0);",
                                "path.setAttribute(",
                                    "'d',",
                                    "`M ${derivation.shift()} L ${derivation.join(' ')}`",
                                ");"
                            )) :
                            string(abi.encodePacked(
                                "let handlers = [",
                                    "document.getElementById('handlerX'),",
                                    "document.getElementById('handlerY')",
                                "];",
                                "let derivations = [",
                                    "generatePath(",Utils._formatDerivation(id),", ",Utils._toString(zoom),", 0, [], 0, 0),",
                                    "generatePath(",Utils._formatDerivation(mergeId),", ",Utils._toString(zoom),", 0, [], 0, 0)",
                                "];",
                                "derivations = [",
                                    "`M ${derivations[0].shift()} L ${derivations[0].join(' ')}`,",
                                    "`M ${derivations[1].shift()} L ${derivations[1].join(' ')}`",
                                "];",
                                "handlers[0].setAttribute('from', derivations[0]);",
                                "handlers[0].setAttribute('to', derivations[1]);",
                                "handlers[1].setAttribute('from', derivations[1]);",
                                "handlers[1].setAttribute('to', derivations[0]);"
                        ))),
                    "</script>"
                ))
            ))
        ));
    }

    function generateAsHTML(uint256 id)
    public view returns (string memory) {
        require(
            NFT.exist(id),
            "AlgocracyGenesisProvider::generateAsHTML() - id do not exist"
        );

        uint256 registryId = ParamActivationRegistry[id] ? id : 0;
        return modulusAsHTML(
            id, MergeActivationRegistry[id] ? MergeRegistry[id] : id,
            ParamRegistry[registryId].background,
            ParamRegistry[registryId].color,
            ParamRegistry[registryId].thickness,
            ParamRegistry[registryId].zoom
        );
    }

    function generateMetadata(uint256 id)
    public view returns (string memory) {
        require(
            NFT.exist(id),
            "AlgocracyGenesisProvider::exist() - id do not exist"
        );

        uint256 registryId = ParamActivationRegistry[id] ? id : 0;
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Utils._encode(bytes(
                string(abi.encodePacked(
                    "{",
                        '"name":"',NFT.name(),' #',Utils._toString(id),'",',
                        '"image":"ipfs://',CID,'/',Utils._toString(id),'.png",',
                        '"animation_url":"',(
                            generateAsHTML(id)
                        ),'",',
                        '"attributes":[',
                            '{"trait_type":"Animation","value":"',(
                                MergeActivationRegistry[id] ? "True" : "False"
                            ),'"},',
                            (
                                MergeActivationRegistry[id] ? 
                                string(abi.encodePacked(
                                    '{"trait_type":"Merge","value":"',Utils._formatDerivation(MergeRegistry[id]),'"},'
                                )) : ''
                            ),
                            '{"trait_type":"Derivation","value":"',Utils._formatDerivation(id),'"},',
                            '{"trait_type":"Background","value":"',ParamRegistry[registryId].background,'"},',
                            '{"trait_type":"Stroke","value":"',ParamRegistry[registryId].color,'"},',
                            '{"trait_type":"Thickness","value":"',Utils._toString(ParamRegistry[registryId].thickness),'"},',
                            '{"trait_type":"Zoom","value":"',Utils._toString(ParamRegistry[registryId].zoom),'"}',
                        ']',
                    "}"
                ))
            ))
        ));
    }
}