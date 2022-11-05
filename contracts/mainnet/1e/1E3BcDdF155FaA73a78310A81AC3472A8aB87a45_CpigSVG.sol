// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CpigParts.sol";
import "./CpigParts2.sol";
import "./CpigBG.sol";

struct Cpig {
    uint8 bg;
    uint8 bg_s;
    uint8 eyes;
    uint8 eyes_s;
    uint8 glasses;
    uint8 hat;
    uint8 hat_s;
    uint8 neck;
    uint8 neck_s;
    uint8 earring;
}

contract CpigSVG {
    address addrParts;
    address addrParts2;
    address addrBG;

    constructor(
        address _addrParts,
        address _addrParts2,
        address _addrBG
    ) {
        addrParts = _addrParts;
        addrParts2 = _addrParts2;
        addrBG = _addrBG;
    }

    uint8[] private bg_ = [114, 74, 63, 55, 54, 38, 27, 11, 11];
    string[] private bg_t = [
        "Balloons",
        "Clouds",
        "Starry Sky",
        "Star Trails",
        "Radar",
        "Saturn",
        "Meteor Shower",
        "DNA",
        "ECG"
    ];
    uint8[] private es_ = [112, 73, 69, 58, 54, 51, 39, 22, 5];
    string[] private es_t = [
        "Galaxy",
        "Blink",
        "Rolling",
        "Cute",
        "Red Heart",
        "Star",
        "Wink",
        "Cyborg",
        "Laser"
    ];
    uint8[] private gl_ = [194, 175, 142, 128, 107, 65];
    string[] private gl_t = ["None", "Circle", "3D", "Polygon", "Smart", "LED"];
    uint8[] private hs_ = [136, 84, 68, 64, 61, 60, 41, 37, 36, 17, 9];
    string[] private hs_t = [
        "Pinwheel",
        "Party Hat",
        "Black Standing Hair",
        "Black Side Parting",
        "Antenna",
        "Green Lollipop",
        "Blue Lollipop",
        "Gold Standing Hair",
        "Gold Side Parting",
        "Red Lollipop",
        "Crown"
    ];
    uint8[] private bt_ = [253, 232, 201, 170, 36];
    string[] private bt_t = ["Bowtie", "Bowknot", "Tie", "Scarf", "Bat"];
    uint8[] private er_ = [145, 118, 101, 83, 58, 33, 7];
    string[] private er_t = [
        "None",
        "Silver",
        "Gold",
        "Diamond",
        "Spiral",
        "Neon",
        "Alien"
    ];
    uint8[] si_ = [6, 8, 8, 4, 8, 8, 8, 8, 3];
    string private ts0 = '{"trait_type": "Background","value": "';
    string private ts1 = '"},{"trait_type": "Eyes","value": "';
    string private ts2 = '"},{"trait_type": "Glasses","value": "';
    string private ts3 = '"},{"trait_type": "Hat","value": "';
    string private ts4 = '"},{"trait_type": "Neck","value": "';
    string private ts5 = '"},{"trait_type": "Earring","value": "';
    string private r0 = "C";
    string private r1 = "U";
    string private r2 = "B";
    string private r3 = "E";
    string private r4 = "P";
    string private r5 = "G";
    string private ns =
        '<path d="M80,360 l160,-150 a25,30 -20,0,1 -120,200 z M920,360 l-160,-150 a25,30 20,0,0 120,200 z" style="fill:#feb3af;stroke:#343238;stroke-width:10"/><path d="M380,730 q0,-120 120,-120 q120,0 120,120 a70,30 0,0,1 -240,0 z" style="fill:#feb3af;stroke:#343238;stroke-width:10" /><ellipse cx="455" cy="700" rx="20" ry="36" fill="#343238"/><ellipse cx="545" cy="700" rx="20" ry="36" fill="#343238"/>';
    string private ns1 =
        '<defs><g id="n1r"><circle cx="0" cy="0" r="25" fill="#ec6a5f"/><path d="M0,0 l0,600" style="stroke:#ec6a5f;stroke-width:30;opacity:0.8"/><circle cx="0" cy="0" r="10" fill="#fef9ee"/><path d="M0,0 l0,600" style="stroke:#fef9ee;stroke-width:12;opacity:0.8"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="30,0,0;-30,0,0;30,0,0" dur="10s" repeatCount="indefinite"/></g></defs><g id="n1l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#343238"/><g><use href="#n1r" x="300" y="510"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;40,0;0,0" dur="10s" repeatCount="indefinite"/></g></g><use href="#n1l" x="360"/>';

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    function getIdx(uint8[] memory a, uint256 i) internal pure returns (uint8) {
        uint8 idx = 0;
        uint256 j = a[0];
        while (j < i) {
            idx += 1;
            j += uint256(a[idx]);
        }
        return idx;
    }

    function randomT(uint256 tokenId) external view returns (Cpig memory) {
        Cpig memory cpig;
        tokenId = 10252 - tokenId;
        uint256 r = uint256(
            (random(string(abi.encodePacked(r0, toString(tokenId))))) % 447
        );
        cpig.bg = getIdx(bg_, r);
        if (cpig.bg == 0) {
            cpig.bg_s = uint8(r % si_[0]);
        }

        r = uint256(
            (random(string(abi.encodePacked(r1, toString(tokenId))))) % 483
        );
        cpig.eyes = getIdx(es_, r);
        if (cpig.eyes == 0) {
            cpig.eyes_s = uint8(r % si_[1]);
        }

        cpig.glasses = getIdx(
            gl_,
            uint256(
                (random(string(abi.encodePacked(r2, toString(tokenId))))) % 811
            )
        );

        r = uint256(
            (random(string(abi.encodePacked(r3, toString(tokenId))))) % 613
        );
        cpig.hat = getIdx(hs_, r);
        if (cpig.hat == 0) {
            cpig.hat_s = uint8(r % si_[2]);
        }
        if (cpig.hat == 1) {
            cpig.hat_s = uint8(r % si_[3]);
        }

        r = uint256(
            (random(string(abi.encodePacked(r4, toString(tokenId))))) % 892
        );
        if (cpig.eyes == 8) {
            cpig.glasses = 0;
            cpig.neck = 4;
        } else cpig.neck = getIdx(bt_, r);
        cpig.neck_s = uint8(r % si_[cpig.neck + 4]);

        cpig.earring = getIdx(
            er_,
            uint256(
                (random(string(abi.encodePacked(r5, toString(tokenId))))) % 545
            )
        );
        if (tokenId == 7260 || tokenId == 9067) {
            cpig.earring += 2;
        }

        return cpig;
    }

    function getTraits(Cpig memory cpig) external view returns (string memory) {
        string[6] memory ts;
        ts[0] = string(abi.encodePacked(ts0, bg_t[cpig.bg]));
        ts[1] = string(abi.encodePacked(ts1, es_t[cpig.eyes]));
        ts[2] = string(abi.encodePacked(ts2, gl_t[cpig.glasses]));
        ts[3] = string(abi.encodePacked(ts3, hs_t[cpig.hat]));
        ts[4] = string(
            abi.encodePacked(
                ts4,
                bt_t[cpig.neck],
                " ",
                toString(cpig.neck_s + 1)
            )
        );
        ts[5] = string(abi.encodePacked(ts5, er_t[cpig.earring]));
        if (cpig.bg == 0) {
            ts[0] = string(
                abi.encodePacked(ts[0], " ", toString(cpig.bg_s + 1))
            );
        }
        if (cpig.eyes == 0) {
            ts[1] = string(
                abi.encodePacked(ts[1], " ", toString(cpig.eyes_s + 1))
            );
        }
        if (cpig.glasses == 0) {
            ts[2] = "";
        }
        if (cpig.hat <= 1) {
            ts[3] = string(
                abi.encodePacked(ts[3], " ", toString(cpig.hat_s + 1))
            );
        }
        if (cpig.earring == 0) {
            ts[5] = "";
        }
        return (
            string(abi.encodePacked(ts[0], ts[1], ts[2], ts[3], ts[4], ts[5]))
        );
    }

    function genSVG(uint256 tokenId, Cpig memory cpig)
        external
        view
        returns (string memory)
    {
        CpigParts cp = CpigParts(addrParts);
        CpigParts2 cp2 = CpigParts2(addrParts2);
        CpigBG cbg = CpigBG(addrBG);

        string
            memory ss = '<svg width="1000px" height="1000px" viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg">';
        ss = string(
            abi.encodePacked(
                ss,
                cbg.genBG(cpig.bg, cpig.bg_s),
                '<rect x="150" y="260" rx="200" ry="200" width="700" height="600" style="fill:#feb3af;stroke:#343238;stroke-width:10"/>'
            )
        );
        ss = string(
            abi.encodePacked(
                ss,
                cp.genEyes(toString(tokenId), cpig.eyes, cpig.eyes_s)
            )
        );
        ss = string(abi.encodePacked(ss, cp2.genGls(cpig.glasses)));
        ss = string(
            abi.encodePacked(
                ss,
                cp.genHat(toString(tokenId), cpig.hat, cpig.hat_s)
            )
        );
        ss = string(abi.encodePacked(ss, cp2.genNeck(cpig.neck, cpig.neck_s)));
        ss = string(abi.encodePacked(ss, ns));
        ss = string(abi.encodePacked(ss, toString(tokenId)));
        if (cpig.eyes == 8) {
            ss = string(abi.encodePacked(ss, ns1));
        }
        ss = string(abi.encodePacked(ss, cp2.genErs(cpig.earring)));
        ss = string(abi.encodePacked(ss, "</svg>"));

        return ss;
    }
}