//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721G.sol";

//species, eyes, nose, mouth, background, accessories, accesoriesCount, first Name, last Name, sex,

contract AiAlbumMint is ERC721G, Ownable, ReentrancyGuard {
    address private NEO;
    bytes public baseURI = "https://oca.mypinata.cloud/ipfs/";

    address private The_Dude = 0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b;

    uint8 bgTypeCount = 2;
    uint8 eyesCount = 1;
    uint8 eyeColorCount = 10;
    uint8 gradientColorCount = 22;
    uint8 speciesCount = 4;
    uint8 speciesColorCount = 5;
    uint256 lastTokenId;

    string bgViewBox = "0 0 1280 1280";

    //     bgSvg[0],
    // c1,
    // bgSvg[1],
    // c2,
    // bgSvg[2],
    // generateHead(),
    // bgSvg[3]

    string[2] private bgSvg = [
        "<svg id='villager' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' overflow='visible'  shape-rendering='geometricPrecision' text-rendering='geometricPrecision' viewBox='",
        "'><style>.hide {animation: showhide 1s ease;opacity:1;}.hide:hover {animation: hideshow .5s ease;opacity:0;}@keyframes hideshow {0% { opacity: 1; }10% { opacity: 0.9; }15% { opacity: 0.7; }30%{opacity:0.5;}100%{opacity:0;}}@keyframes showhide{0%{opacity:0;}10%{opacity:0.2;}15%{opacity:0.4;}30%{opacity:0.6;}100%{opacity: 1;}} </style>"
    ];
    string[] private svg = [
        "<svg x='",
        "' y='",
        "' overflow='visible'>",
        "</svg>"
    ];

    string[] private bgSvgGrad = [
        "<defs><linearGradient id='d' y2='1' x2='0'><stop stop-color='",
        "' offset='0'/><stop stop-color='",
        "' offset='1'/></linearGradient></defs><rect width='100%' height='100%' fill='url(#d)'/>"
    ];

    string[] private bodySvg = [
        "<path transform='matrix(1 0 .001512 1 -1.8639 -196.71)' d='m853.22 1144.8 632.11 213.51h-1264.2l632.11-213.51z' fill='url(#s)' stroke='#000' stroke-width='7' paint-order='stroke'/>"
    ];

    string[] private mouthSVG = [
        "<path d='M502.5 900h298.951v75.869H502.5z' stroke='#000' stroke-width='5' fill='",
        "' />"
    ];

    string[] private headSvg = [
        "<path d='M805-5v810H-5V-5'/><path d='M0 0v800h800V0' fill='url(#s)'/>"
    ];

    string[] private eyeSvg = [
        "<svg fill='",
        "' stroke='#000' stroke-width='4'><path d='M650 500h100v100H650z' fill='#fff'/><path d='m676.7 526.15h45.283v45.283h-45.283z'/><path d='m690.9 539.7h16.898v16.898h-16.898z' fill='#000'/><path d='m1e3 500h100v100h-100z' fill='#fff'/><path d='m1026.7 526.15h45.283v45.283h-45.283z'/><path d='m1040.9 539.7h16.898v16.898h-16.898z' fill='#000'/></svg>"
    ];

    string[] private shirtSVG = [
        "<path d='m1852.4 196.54h230.12v3.455h-230.12z'/><svg fill='",
        "' overflow='visible'><path d='m1874.2 200h95.397l630.42 174.6h-1264.3l516.11-174.6h22.359z'/><path d='m1961.3 200 638.74 174.4-514.61-174.4h-123.13z'/></svg>"
    ];

    string[] private hairSVG = [
        "<defs><linearGradient id='h'><stop stop-color='",
        "'/></linearGradient></defs><path d='M500 500.334h104.4v4.545H500z'/><path d='M599.788783 501.028577v-99.362h4.581v99.362z'/><path d='M599.788 401.664h600.143v4.555H599.788z'/><path d='M1199.931141 401.664008v100h-4.534v-100z'/><path d='M1301.87 505.443h-106.473v-4.559h106.473z'/><path fill='url(#h)' d='M500.145 247.757h799.767v153.711H500.145z' data-bx-origin='0.397 0.801'/><path fill='url(#h)' d='M500.145 401h100v100h-100zm699.767 0h100v100h-100z'/>"
    ];

    string[] private ponyTailSVG = [
        "<defs><linearGradient id='h' ><stop stop-color='",
        "'/></linearGradient></defs><path d='M1300 605.948h-103.62v-5H1300zM500 700h100v4.043H500zm103.9596-199.9996v204.043h-3.959v-204.043zm0-.0015 99.8119-.1033.0042 4.066-99.8119.1033z'/><path d='m700.13 499.9v-99.791h3.64v99.791z'/><path d='m700 400 300 0.105-0.0015 4.307-300-0.105z'/><path d='m1002 400.11v99.895h-4.492v-99.895zm-4.3237 99.898 206.25-0.02 4e-4 4.119-206.25 0.02z'/><path d='m1199.9 499.98 0.4586 100.2-4.001 0.0183-0.4585-100.2z'/><svg fill='url(#h)' overflow='visible'><path d='M500 248h800v153H500z'/><path d='m1e3 400h300v101h-300z'/><path d='M1200 500h100v101.5h-100zM500 400h200v101H500z'/><path d='M500 500h100v200H500z'/><path d='m497.49 1053h175v227h-175z' stroke='#000' stroke-width='6'/></svg>"
    ];

    string[] private eyelidsSVG = [
        "<path d='M650 498h100v26.154H650zm350 0h100v26.154h-100z' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='w' begin='0s;b.end' dur='3.5s' from='0' to='0'/><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -500.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path><svg y='5.9%'><path d='M650 498h100v26.154H650zm350 0h100v26.14h-100z' class='blinkBotto' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -520.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path></svg>"
    ];

    string[] private eyebrowsSVG = [
        "<path d='M650 468h100v21.658H650zm350 0h100v21.658h-100z' fill='url(#h)' stroke='#000' stroke-width='5'/>"
    ];

    string[] private noseSVG = [
        "<path d='m424.37 720.47 75.633 131h-151.27l75.634-131z'  fill-opacity='0.035' stroke='#000' stroke-width='4' data-bx-shape='triangle 348.733 720.474 151.267 131.002 0.5 0 [email protected]'/>"
    ];

    string[] private earSVG = [
        "<defs><linearGradient id='s' ><stop stop-color='",
        "'/></linearGradient></defs><path id='c' d='m428.4 406.29a43.415 43.415 0 1 1 0 43.415 21.809 21.809 0 0 0 0-43.415z' stroke='#000' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]'/><svg width='909.76' height='113.77' fill='url(#s)' viewBox='513.126 535.454 909.759 113.767'><use transform='matrix(-.020544 1.0313 -.9438 -.018801 969.89 130.91)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]696' href='#c'/><path d='m517.02 541.73h80.115v64.604h-80.115z'/><path d='m513.13 536.52h4.652v70.911h-4.652z' fill='#000'/><path d='m513.4 536.36h86.471v5.369h-86.471z' fill='#000'/><use transform='matrix(.020544 1.0311 .9438 -.03106 966.12 135.93)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]' href='#c'/><path d='m1419 540.87-80.115 1.0406v64.604l80.115-1.0406z'/><path d='m1422.9 535.61-4.6516 0.0604v70.911l4.6516-0.0605z' fill='#000'/><path d='m1422.6 535.45-86.471 1.1231v5.3695l86.471-1.1232z' fill='#000'/></svg>"
    ];

    string[] private glassesSVG = [
        "<svg class='hide' fill='",
        "' stroke='#000' stroke-width='4' overflow='visible'><path id='a' d = 'M596.99 343.333a89.677 89.677 0 1 0 179.354 0 89.677 89.677 0 1 0-179.354 0Zm11.715 0a77.962 77.962 0 0 1 155.924 0 77.962 77.962 0 0 1-155.924 0Z' transform = 'matrix(0 1 -1 .006581 980.105379 -107.225916)' /> <use href='#a' transform = 'matrix(0 1.02 -1 .006581 1569.4 -72.789584)' /> <path fill='#000' d = 'M 724.62 558.604 L 725.347 562.943 L 899.897 561.465 L 899.988 558.987' /> <path stroke='none' d = 'M 723.157 573.059 L 717.611 563.6 L 797.188 562.877 L 847.521 563.092 L 902.257 562.955 L 900.21 572.654' /> <path fill='#000' stroke = 'none' d = 'M 725.12 573.169 L 814.429 568.607 L 900.089 572.782 L 899.564 578.436 C 899.564 578.436 902.76 577.146 881.588 576.006 C 866.636 575.201 832.73 573.088 814.588 573.066 C 799.307 573.047 783.958 574.454 770.486 575.385 C 726.313 578.439 726.018 576.404 726.018 576.818' /> <path d='M 1067.375 544.94 L 1214.175 509.35 L 1213.788 509.164 L 1073.393 560.666 M 561.189 538.644 L 556.386 536.943 L 518.62 527.298 L 409.5 501.267 L 414.616 500.766 L 555.071 552.439' /> <svg fill='",
        "' opacity='",
        "%'><circle cx='637' cy='582' r='79'/><circle cx='988' cy='580.5' r='79'/></svg></svg>"
    ];

    //        uint256 svgId;
    //    uint256 colorId;
    //    uint256 varCount;

    //        colorMapping2[0] = 0;
    // svgLayers[_id].attributes[listId] = SVGAttributes(
    //     1,
    //     0,
    //     1,
    //     colorMapping2
    // );

    struct AddAttribute {
        uint32 id;
        string[] svg;
        uint256[] colorMapping;
    }

    struct TokenLayers {
        uint256[] attributes;
        mapping(uint256 => bytes) colors;
    }

    struct TokenRevealInfo {
        bool revealed;
        uint256 seed;
        uint256 season;
        uint256 count;
        mapping(uint256 => TokenLayers) layers;
    }
    struct TokenLayerInfo {
        uint32 layer;
    }

    struct Eyes {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) eyeColors;
    }

    struct Drops {
        bytes ipfsHash;
        bytes ipfsPreview;
        uint16 id;
        uint16 revealStage;
        uint256 snapshot;
    }

    struct Backgrounds {
        mapping(uint256 => bytes32) backgroundType;
        mapping(uint256 => bytes) gradientColors;
    }

    struct Species {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) speciesColors;
    }

    Backgrounds private backgrounds;
    Species private species;
    Eyes private eyes;

    struct GradientBGs {
        bytes color;
    }

    // struct DropInfo {
    //     uint16 id;
    //     uint256 snapshot;
    //     uint256 baseIPFS;
    //     uint256 previewIPFS;
    //     mapping(uint256 => HashInfo) hashes;
    // }

    struct TokenInfo {
        uint16 stage;
        uint256 lastToken;
        uint256 hash;
    }

    struct RevealToken {
        uint8 v;
        uint256 drop;
        uint256 index;
        bytes32 r;
        bytes32 s;
        uint256 tokenId;
    }

    struct SVGInfo {
        bytes name;
        uint256 count;
        mapping(uint256 => SVGLayer) layer;
    }

    struct SVGLayer {
        bool inactive;
        uint256 remaining;
        string x;
        string y;
        string[] svg;
    }

    struct SVGLayers {
        bytes name;
        uint256 layerCount;
        mapping(uint256 => SVGAttributes) attributes;
    }

    struct Colors {
        bytes name;
        uint256 count;
        mapping(uint256 => bytes) list;
    }

    struct SVGAttributes {
        uint256 svgId;
        uint256 colorId;
        uint256 varCount;
        uint256[] colorMapping;
    }

    struct AttributeMapping {
        bytes name;
        uint256 attributeCount;
        mapping(uint256 => Attribute) info;
    }

    struct Attribute {
        mapping(uint256 => bool) isNumber;
        mapping(uint256 => uint256[2]) range;
        bool inactive;
        uint256 remaining;
        uint256 colorId;
        uint256 varCount;
        string x;
        string y;
        string[] svg;
    }

    //     struct SVGInfo {
    //     bytes name;
    //     uint256 count;
    //     mapping(uint256 => SVGLayer) layer;
    // }

    // struct SVGLayer {
    //     bool inactive;
    //     uint256 remaining;
    //     string x;
    //     string y;
    //     string[] svg;
    // }

    // mapping(uint32 => SVGInfo) private svgList;

    mapping(address => uint256) public nonces;
    mapping(uint256 => Drops) private drops;
    mapping(uint256 => TokenRevealInfo) public tokens;

    mapping(uint256 => Colors) private colors;
    mapping(uint256 => SVGLayers) public svgLayers;

    mapping(uint256 => AttributeMapping) public attributes;

    constructor(address _NEO) ERC721G("AIAlbumsMint", "AIA", 0, 10000) {
        // attributes[0].colorId = 0;
        // attributes[0].svgId = 0;

        //        bool isNumber;
        // bool inactive;
        // uint256 remaining;
        // uint256 colorId;
        // uint256 varCount;
        // uint256[2] range;
        // string x;
        // string y;
        // string[] svg;
        attributes[0].name = "Backgrounds";
        attributes[0].attributeCount = 1;
        attributes[0].info[0].varCount = 2;
        attributes[0].info[0].svg = bgSvgGrad;
        svgLayers[0].layerCount = 1;
        attributes[0].info[0].range[0] = [0, 21];
        attributes[0].info[0].range[1] = [0, 21];

        attributes[1].name = "Ears";
        attributes[1].attributeCount = 1;
        attributes[1].info[0].varCount = 1;
        attributes[1].info[0].svg = earSVG;
        attributes[1].info[0].colorId = 1;
        attributes[1].info[0].x = "15.6%";
        attributes[1].info[0].y = "42.5%";
        svgLayers[1].layerCount = 1;

        attributes[2].name = "Head";
        attributes[2].attributeCount = 1;
        attributes[2].info[0].varCount = 0;
        attributes[2].info[0].svg = headSvg;
        attributes[2].info[0].colorId = 1;
        attributes[2].info[0].x = "20%";
        attributes[2].info[0].y = "20%";
        svgLayers[2].layerCount = 1;

        // attributes[12].name = "Glasses";
        // attributes[12].attributeCount = 1;
        // attributes[12].info[0].varCount = 3;
        // attributes[12].info[0].svg = glassesSVG;
        // attributes[12].info[0].colorId = 0;
        // attributes[12].info[0].x = "-12.2%";
        // attributes[12].info[0].y = "3.8%";
        // attributes[12].info[0].range[2] = [75, 98];
        // svgLayers[12].layerCount = 1;
        // attributes[12].info[0].isNumber[2] = true;

        // attributes[3].info[0] = Attribute(
        //     false,
        //     1,
        //     1,
        //     [uint256(0), uint256(0)]
        // );

        // svgLayers[3].layerCount = 1;

        attributes[3].name = "Eyes";
        attributes[3].attributeCount = 1;
        attributes[3].info[0].varCount = 1;
        attributes[3].info[0].svg = eyeSvg;
        attributes[3].info[0].colorId = 5;
        attributes[3].info[0].x = "-17.35%";
        attributes[3].info[0].y = "5.5%";
        svgLayers[3].layerCount = 1;

        attributes[4].name = "Brows";
        attributes[4].attributeCount = 1;
        attributes[4].info[0].varCount = 0;
        attributes[4].info[0].svg = eyebrowsSVG;
        attributes[4].info[0].colorId = 7;
        attributes[4].info[0].x = "-17.35%";
        attributes[4].info[0].y = "5.5%";
        svgLayers[4].layerCount = 1;

        attributes[5].name = "Eye Lids";
        attributes[5].attributeCount = 0;
        attributes[5].info[0].varCount = 0;
        attributes[5].info[0].svg = eyelidsSVG;
        attributes[5].info[0].colorId = 1;
        attributes[5].info[0].x = "-17.35%";
        attributes[5].info[0].y = "5.5%";
        svgLayers[5].layerCount = 1;

        attributes[6].name = "Glasses";
        attributes[6].attributeCount = 1;
        attributes[6].info[0].varCount = 3;
        attributes[6].info[0].svg = glassesSVG;
        attributes[6].info[0].x = "-12.2%";
        attributes[6].info[0].y = "3.8%";
        attributes[6].info[0].range[2] = [75, 98];
        svgLayers[6].layerCount = 1;
        attributes[6].info[0].isNumber[2] = true;
        attributes[6].info[0].range[0] = [22, 30];
        attributes[7].info[0].range[1] = [0, 21];

        attributes[7].name = "Hair";
        attributes[7].attributeCount = 2;
        attributes[7].info[0].varCount = 1;
        attributes[7].info[0].svg = hairSVG;
        attributes[7].info[1].svg = ponyTailSVG;
        attributes[7].info[0].colorId = 7;
        attributes[7].info[1].colorId = 7;
        attributes[7].info[0].x = "-19.065%";
        attributes[7].info[0].y = "0.5%";
        attributes[7].info[1].x = "-19.065%";
        attributes[7].info[1].y = "0.5%";
        svgLayers[7].layerCount = 2;

        attributes[8].name = "Body";
        attributes[8].attributeCount = 1;
        attributes[8].info[0].varCount = 1;
        attributes[8].info[0].svg = bodySvg;
        attributes[8].info[0].colorId = 1;
        attributes[8].info[0].x = "-17.2%";
        attributes[8].info[0].y = "8.9%";
        svgLayers[8].layerCount = 1;

        attributes[9].name = "Mouth";
        attributes[9].attributeCount = 1;
        attributes[9].info[0].varCount = 1;
        attributes[9].info[0].svg = mouthSVG;
        attributes[9].info[0].colorId = 8;
        svgLayers[9].layerCount = 1;

        attributes[10].name = "Shirt";
        attributes[10].attributeCount = 1;
        attributes[10].info[0].varCount = 1;
        attributes[10].info[0].svg = shirtSVG;
        attributes[10].info[0].colorId = 6;
        attributes[10].info[0].x = "-104.3%";
        attributes[10].info[0].y = "70.425%";
        svgLayers[10].layerCount = 1;

        attributes[11].name = "Nose";
        attributes[11].attributeCount = 1;
        attributes[11].info[0].varCount = 0;
        attributes[11].info[0].svg = noseSVG;
        attributes[11].info[0].colorId = 1;
        attributes[11].info[0].x = "18%";
        svgLayers[11].layerCount = 1;

        attributes[12].name = "Earings";
        attributes[12].attributeCount = 1;
        attributes[12].info[0].varCount = 0;
        attributes[12].info[0].colorId = 1;
        attributes[12].info[0].svg = [""];
        attributes[12].info[0].x = "16.9%";
        attributes[12].info[0].y = "47.5%";
        svgLayers[12].layerCount = 1;

        // uint256[] memory colorMapping1 = new uint256[](2);
        // colorMapping1[0] = 0;
        // colorMapping1[1] = 1;
        // uint256[] memory colorMapping2 = new uint256[](1);
        // // colorMapping2[0] = 0;
        // uint256[] memory colorMapping3 = new uint256[](1);

        // uint256[] memory colorMapping5 = new uint256[](0);

        // uint256[] memory colorMapping4 = new uint256[](3);

        // uint256[] memory colorMapping6 = new uint256[](6);

        // svgList[0].count = 1;
        // svgList[0].name = "Backgrounds";
        // svgList[0].layer[0].svg = bgSvgGrad;
        // // svgList[0].list[1] = bgSvgSolid;

        // svgLayers[0].name = "background";
        // svgLayers[0].attributes[0] = SVGAttributes(0, 0, 2, colorMapping1);
        // colorMapping1[1] = 0;

        // svgList[1].count = 1;
        // svgList[1].name = "Ears";
        // svgList[1].layer[0].svg = earSVG;
        // svgList[1].layer[0].x = "15.6%";
        // svgList[1].layer[0].y = "42.5%";
        // svgLayers[1].name = "ears";
        // svgLayers[1].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[2].count = 1;
        // svgList[2].name = "Head";
        // svgList[2].layer[0].svg = headSvg;
        // svgList[2].layer[0].x = "20%";
        // svgList[2].layer[0].y = "20%";
        // svgLayers[2].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // //    svgList[1].layer[0].list[0];
        // // svgLayers[1].name = "head";

        // // svgList[3].count = 1;
        // // svgList[3].name = "Glasses";
        // // svgList[3].layer[0].svg = [""];
        // // svgList[3].layer[0].x = "-19.5%";
        // // svgList[3].layer[0].y = "-0.5%";
        // // svgLayers[3].name = "glasses";
        // // // svgLayers[3].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // // svgLayers[3].attributes[0] = SVGAttributes(0, 0, 3, colorMapping4);

        // svgList[3].count = 2;
        // svgList[3].name = "Hair";
        // svgList[3].layer[0].svg = hairSVG;
        // svgList[3].layer[1].svg = ponyTailSVG;

        // svgList[3].layer[0].x = "-19.065%";
        // svgList[3].layer[0].y = "0.5%";
        // svgList[3].layer[1].x = "-19.065%";
        // svgList[3].layer[1].y = "0.5%";
        // svgLayers[3].name = "hair";
        // svgLayers[3].attributes[0] = SVGAttributes(0, 7, 1, colorMapping3);
        // svgLayers[3].attributes[1] = SVGAttributes(1, 7, 1, colorMapping3);

        // svgList[4].count = 1;
        // svgList[4].name = "Body";
        // svgList[4].layer[0].svg = bodySvg;
        // svgList[4].layer[0].x = "-17.2%";
        // svgList[4].layer[0].y = "8.9%";
        // svgLayers[4].name = "body";
        // svgLayers[4].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[5].count = 1;
        // svgList[5].name = "Eyes";
        // svgList[5].layer[0].svg = eyeSvg;
        // svgList[5].layer[0].x = "-17.35%";
        // svgList[5].layer[0].y = "5.5%";
        // svgLayers[5].name = "eyes";
        // svgLayers[5].attributes[0] = SVGAttributes(0, 5, 1, colorMapping3);

        // svgList[6].count = 1;
        // svgList[6].name = "Mouth";
        // svgList[6].layer[0].svg = mouthSVG;
        // svgLayers[6].name = "mouths";
        // svgLayers[6].attributes[0] = SVGAttributes(0, 8, 1, colorMapping3);

        // svgList[7].count = 1;
        // svgList[7].name = "Shirt";
        // svgList[7].layer[0].svg = shirtSVG;
        // svgList[7].layer[0].x = "-104.3%";
        // svgList[7].layer[0].y = "70.425%";
        // svgLayers[7].name = "shirt";
        // svgLayers[7].attributes[0] = SVGAttributes(0, 6, 1, colorMapping3);

        // svgList[9].count = 1;
        // svgList[9].name = "Eye Lids";
        // svgList[9].layer[0].svg = eyelidsSVG;
        // svgList[9].layer[0].x = "-17.35%";
        // svgList[9].layer[0].y = "5.5%";
        // svgLayers[9].name = "eyelids";
        // svgLayers[9].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[8].count = 1;
        // svgList[8].name = "Brows";
        // svgList[8].layer[0].svg = eyebrowsSVG;
        // svgList[8].layer[0].x = "-17.35%";
        // svgList[8].layer[0].y = "5.5%";
        // svgLayers[8].name = "brows";
        // svgLayers[8].attributes[0] = SVGAttributes(0, 7, 0, colorMapping5);

        // svgList[10].count = 1;
        // svgList[10].name = "Nose";
        // svgList[10].layer[0].svg = noseSVG;
        // svgList[10].layer[0].x = "18%";
        // svgLayers[10].name = "nose";
        // svgLayers[10].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[11].count = 1;
        // svgList[11].name = "Earings";
        // svgList[11].layer[0].svg = ["erk"];
        // svgList[11].layer[0].x = "16.9%";
        // svgList[11].layer[0].y = "47.5%";
        // svgLayers[11].name = "earings";

        //svgLayers[11].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        //<svg x="-87.3%" y="61.5%"

        //make new array with 2 elements

        //        svgLayers[0].attributes[1] = SVGAttributes(1, 0, 1, colorMapping2);

        colors[0].name = "bg";
        colors[0].count = 21;
        colors[0].list[0] = "#FF0000"; //red
        colors[0].list[1] = "#EDB9B9"; //light red (pink)
        colors[0].list[2] = "#8F2323"; //dark red
        colors[0].list[3] = "#FF7F7F"; //pink
        colors[0].list[4] = "#E7E9B9"; //yellow-green
        colors[0].list[5] = "#8F6A23"; //yellow-brown
        colors[0].list[6] = "#737373"; //grey
        colors[0].list[7] = "#FFD400"; //dark-yellow
        colors[0].list[8] = "#B9EDE0"; //pastel blue
        colors[0].list[9] = "#4F8F23"; //dark green
        colors[0].list[10] = "#CCCCCC"; //light grey
        colors[0].list[11] = "#FFFF00"; //yellow
        colors[0].list[12] = "#B9D7ED"; //light blue
        colors[0].list[13] = "#23628F"; // dark cyan
        colors[0].list[14] = "#BFFF00"; //lime green
        colors[0].list[15] = "#DCB9ED"; //light purple
        colors[0].list[16] = "#6B238F"; //dark purple
        colors[0].list[17] = "#6AFF00"; //neon reen
        colors[0].list[18] = "#00EAFF"; //cyan
        colors[0].list[19] = "#0095FF"; //blue
        colors[0].list[20] = "#0040FF"; //dark blue

        //glass rim colors (for glasses)

        colors[0].list[21] = "#000000"; //black
        colors[0].list[22] = "#FFFFFF"; //white
        colors[0].list[23] = "#FF0000"; //red
        colors[0].list[24] = "#FFFF00"; //yellow
        colors[0].list[25] = "#00FF00"; //green
        colors[0].list[26] = "#00FFFF"; //cyan
        colors[0].list[27] = "#0000FF"; //blue
        colors[0].list[28] = "#FF00FF"; //magenta
        colors[0].list[29] = "#FF7F7F"; //pink

        species.name[0] = "Human";
        species.name[1] = "Alien";
        species.name[2] = "Robot";
        species.name[3] = "Nanik";
        species.speciesColors[0] = "#C58C85";
        species.speciesColors[1] = "#ECBCB4";
        species.speciesColors[2] = "#D1A3A4";
        species.speciesColors[3] = "#A1665e";
        species.speciesColors[4] = "#503335";

        colors[4].name = "Nanik";
        colors[4].count = 5;
        colors[4].list[0] = "#C58C85";
        colors[4].list[1] = "#ECBCB4";
        colors[4].list[2] = "#D1A3A4";
        colors[4].list[3] = "#A1665e";
        colors[4].list[4] = "#503335";

        colors[3].name = "Robot";
        colors[3].count = 5;
        colors[3].list[0] = "#C58C85";
        colors[3].list[1] = "#ECBCB4";
        colors[3].list[2] = "#D1A3A4";
        colors[3].list[3] = "#A1665e";
        colors[3].list[4] = "#503335";

        colors[2].name = "Alien";
        colors[2].count = 5;
        colors[2].list[0] = "#C58C85";
        colors[2].list[1] = "#ECBCB4";
        colors[2].list[2] = "#D1A3A4";
        colors[2].list[3] = "#A1665e";
        colors[2].list[4] = "#503335";

        colors[1].name = "humans";
        colors[1].count = 5;
        colors[1].list[0] = "#C58C85";
        colors[1].list[1] = "#ECBCB4";
        colors[1].list[2] = "#D1A3A4";
        colors[1].list[3] = "#A1665e";
        colors[1].list[4] = "#503335";

        colors[8].name = "human-lips";
        colors[8].count = 5;
        colors[8].list[0] = "#D99E96";
        colors[8].list[1] = "#F2C7C2";
        colors[8].list[2] = "#E2B2B0";
        colors[8].list[3] = "#B17F7A";
        colors[8].list[4] = "#5F3F3B";

        colors[9].name = "lipstick";
        colors[9].count = 5;
        colors[9].list[0] = "#E35D6A";
        colors[9].list[1] = "#F7A5B0";
        colors[9].list[2] = "#F28E9B";
        colors[9].list[3] = "#C65E6A";
        colors[9].list[4] = "#6F2F35";

        colors[5].name = "eyes";
        colors[5].count = 10;
        colors[5].list[0] = "#76C4AE";
        colors[5].list[1] = "#9FC2BA";
        colors[5].list[2] = "#BEE9E4";
        colors[5].list[3] = "#7CE0F9";
        colors[5].list[4] = "#CAECCF";
        colors[5].list[5] = "#D3D2B5";
        colors[5].list[6] = "#CABD80";
        colors[5].list[7] = "#E1CEB1";
        colors[5].list[8] = "#DDB0A0";
        colors[5].list[9] = "#D86C70";

        colors[6].name = "shirt";
        colors[6].count = 17;
        colors[6].list[0] = "#FFFBA8";
        colors[6].list[1] = "#693617";
        colors[6].list[2] = "#650C17";
        colors[6].list[3] = "#7BDE4E";
        colors[6].list[4] = "#EB9B54";
        colors[6].list[5] = "#FF5E00";
        colors[6].list[6] = "#202020";
        colors[6].list[7] = "#3E3433";
        colors[6].list[8] = "#FFB300";
        colors[6].list[9] = "#FFCFE7";
        colors[6].list[10] = "#AFAFAF";
        colors[6].list[11] = "#032D49";
        colors[6].list[12] = "#193D24";
        colors[6].list[13] = "#CE051f";
        colors[6].list[14] = "#101C86";
        colors[6].list[15] = "#1BCEfA";
        colors[6].list[16] = "#FFFFFF";

        colors[7].name = "hair";
        colors[7].count = 10;
        colors[7].list[0] = "#AA8866";
        colors[7].list[1] = "#DEBE99";
        colors[7].list[2] = "#241C11";
        colors[7].list[3] = "#4F1A00";
        colors[7].list[4] = "#9A3300";
        colors[7].list[5] = "#505050";
        colors[7].list[6] = "#3264C8";
        colors[7].list[7] = "#FFFF5A";
        colors[7].list[8] = "#DC95DC";
        colors[7].list[9] = "#FE5CAA";

        NEO = _NEO;
        drops[0].id = 0;
        drops[0].snapshot = 0;
        drops[0].ipfsHash = "";
        drops[0].ipfsPreview = "QmcSQvWdTF38norhnXwcGLuCqkqY9Rfty4SfVrfBUNnpGp";

        //loop through and create tokens but low gas
    }

    modifier adminAccess() {
        require(
            msg.sender == NEO ||
                msg.sender == The_Dude ||
                msg.sender == owner(),
            "Admin Access Required"
        );
        _;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _nonce,
        uint256 _drop,
        uint256 _index,
        address _signer
    ) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonce, _drop, _index)
        );
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        require(sender == The_Dude, "Invalid access message.");
        nonces[msg.sender]++;
        _;
    }

    function addAttribute(AddAttribute memory _addAttribute)
        external
        adminAccess
    {
        attributes[_addAttribute.id]
            .info[_addAttribute.colorMapping.length]
            .svg = _addAttribute.svg;
        svgLayers[_addAttribute.id].attributes[
            attributes[_addAttribute.id].attributeCount
        ] = SVGAttributes(
            _addAttribute.colorMapping.length,
            _addAttribute.id,
            _addAttribute.colorMapping.length,
            _addAttribute.colorMapping
        );
        attributes[_addAttribute.id].attributeCount += 1;
    }

    function updateAttribute(
        uint32 id,
        uint32 layerId,
        string[] memory _svg
    ) public adminAccess {
        attributes[id].info[layerId].svg = _svg;
    }

    // function randomSpeciesColor(uint256 _seed)
    //     private
    //     view
    //     returns (bytes memory)
    // {
    //     return
    //         species.speciesColors[
    //             uint256(keccak256(abi.encodePacked(_seed, "speciesColor"))) %
    //                 speciesColorCount
    //         ];
    // }

    // function randomBackgroundType(uint256 _seed)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     return _seed % bgTypeCount;
    // }

    // function generateSVG(uint32 id, uint256 _seed)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     uint256 svgNumber = _seed % svgList[id].count;

    //     uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //     uint32 oddFound = 0;
    //     uint256[] memory colorMapping = svgLayers[id]
    //         .attributes[svgNumber]
    //         .colorMapping;
    //     string[] memory _svg = svgList[id].layer[svgNumber].svg;

    //     //loop through string to create svg with required colors
    //     bytes memory svgBytes = abi.encodePacked(_svg[0]);

    //     bytes[] memory colorsArray = new bytes[](varCount);

    //     for (uint256 i = 1; i < _svg.length + varCount; i++) {
    //         //if odd then color is found
    //         if (i % 2 == 1) {
    //             colorsArray[oddFound] = colors[
    //                 svgLayers[id].attributes[svgNumber].colorId
    //             ].list[
    //                     uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                         colors[id].count
    //                 ];
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 colorsArray[colorMapping[oddFound]]
    //             );
    //             oddFound++;
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, _svg[i - oddFound]);
    //         }
    //     }
    //     if (id != 0) {
    //         svgBytes = abi.encodePacked(
    //             svg[0],
    //             svgList[id].layer[svgNumber].x,
    //             svg[1],
    //             svgList[id].layer[svgNumber].y,
    //             svg[2],
    //             svgBytes,
    //             svg[3]
    //         );
    //     }
    //     return svgBytes;
    // }

    // function generateHead(uint256 _seed) internal view returns (bytes memory) {
    //     return
    //         abi.encodePacked(
    //             headSvg[0],
    //             randomSpeciesColor(_seed),
    //             headSvg[1],
    //             randomEye(69),
    //             headSvg[1],
    //             bodySvg[0],
    //             randomSpeciesColor(_seed),
    //             bodySvg[1]
    //         );
    // }

    // function generateGradientBG(bool isSolid)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     //pick two random colors
    //     uint256 index1 = block.timestamp % gradientColorCount;
    //     uint256 index2 = (block.timestamp + 420) % gradientColorCount;

    //     if (isSolid) index2 = index1;

    //     if (index1 == index2 && !isSolid) {
    //         index2 = (index2 + 1) % gradientColorCount;
    //     }
    //     bytes memory c1 = backgrounds.gradientColors[index1];

    //     bytes memory c2 = backgrounds.gradientColors[index2];

    //     return
    //         abi.encodePacked(
    //             bgSvg[0],
    //             c1,
    //             bgSvg[1],
    //             c2,
    //             bgSvg[2],
    //             generateHead(block.timestamp),
    //             bgSvg[2]
    //         );
    // }

    function singatureClaimHash(
        uint256 _drop,
        uint256 _index,
        uint256 _nonce
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _nonce,
                    _drop,
                    _index
                )
            );
    }

    function mint(address _to, uint32 _amount) public {
        require(msg.sender == NEO, "Admin access only.");
        uint256 _amountToMint = _amount;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(_to, maxBatchSize);
        }
        _mintInternal(_to, _amountToMint);
    }

    function mintTest(address _to, uint32 _amount) public {
        uint256 _amountToMint = _amount;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(_to, maxBatchSize);
        }
        _mintInternal(_to, _amountToMint);
    }

    // set last index to receiver

    //_mint(_to, _amount);

    function randomNumber(uint256 _seed, uint256[2] memory range)
        internal
        pure
        returns (uint256)
    {
        //select random number from range
        uint256 start = range[0];
        uint256 end = range[1];

        uint256 random = (_seed % (end - start + 1)) + start;

        return random;
    }

    //delete random token from array

    //display length of token array to public
    // function getLength() public view returns (uint256) {
    //     return tokenIds.length;
    // }

    // uint8 _v,
    // bytes32 _r,
    // bytes32 _s,
    // uint16 _drop,
    // uint32 _index,
    // uint256 _tokenId

    //  function generateTraits(TokenRevealInfo calldata token) external {}

    // function revealArtTest(RevealToken calldata _revealToken)
    //     external
    // // onlyValidAccess(
    // //     _revealToken.v,
    // //     _revealToken.r,
    // //     _revealToken.s,
    // //     nonces[msg.sender],
    // //     _revealToken.drop,
    // //     _revealToken.index,
    // //     msg.sender
    // // )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];

    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgLayers[i].layerCount;

    //             //create new array of 9 empty

    //             if (i == 7 && svgNumber == 1) {
    //                 female = true;
    //                 // token.count += 1;
    //             }

    //             //attributes[i].info[svgNumber].colorId;

    //             // if (!female && svgNumber == 10) break;

    //             // uint256[] memory colorMapping = attributes[i]
    //             //     .info[svgNumber]
    //             //     .range;

    //             for (
    //                 uint32 j = 0;
    //                 j < attributes[i].info[svgNumber].svg.length - 1;
    //                 j++
    //             ) {
    //                 uint256 start = attributes[i].info[svgNumber].range[j][0];
    //                 uint256 end = attributes[i].info[svgNumber].range[j][1];
    //                 uint256 colorId = attributes[i].info[j].colorId;

    //                 if (end == 0) end = colors[colorId].count;

    //                 if (female && i == 9) {
    //                     colorId++;
    //                 }

    //                 // bytes memory color = colors[colorId].list[
    //                 //     (_seed + j) % colors[colorId].count
    //                 // ];
    //                 //colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colors[colorId].list[
    //                     randomNumber(
    //                         _seed + ((i + 69) * (j + 420)),
    //                         [start, end]
    //                     )
    //                 ];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    function revealArtTest(RevealToken calldata _revealToken)
        external
    // onlyValidAccess(
    //     _revealToken.v,
    //     _revealToken.r,
    //     _revealToken.s,
    //     nonces[msg.sender],
    //     _revealToken.drop,
    //     _revealToken.index,
    //     msg.sender
    // )
    {
        TokenRevealInfo storage token = tokens[_revealToken.tokenId];

        require(_exists(_revealToken.tokenId), "Token does not exist");
        require(!token.revealed, "Token already revealed");

        unchecked {
            // this.generateTraits(token);
            uint256 _seed = block.timestamp + block.difficulty + block.number;

            token.seed = _seed;

            bool female;
            token.count = 12;

            //make new array of bytes

            //generate random traits here and store in token forloop 9 for basic traits

            for (uint32 i = 0; i < 13; i++) {
                uint256 svgNumber = _seed % svgLayers[i].layerCount;

                //create new array of 9 empty

                if (i == 7 && svgNumber == 1) {
                    female = true;
                    // token.count += 1;
                }

                //attributes[i].info[svgNumber].colorId;

                // if (!female && svgNumber == 10) break;

                // uint256[] memory colorMapping = attributes[i]
                //     .info[svgNumber]
                //     .range;

                for (
                    uint32 j = 0;
                    j < attributes[i].info[svgNumber].svg.length - 1;
                    j++
                ) {
                    uint256 start = attributes[i].info[svgNumber].range[j][0];
                    uint256 end = attributes[i].info[svgNumber].range[j][1];
                    uint256 colorId = attributes[i].info[j].colorId;

                    if (end == 0) end = colors[colorId].count;

                    if (female && i == 9) {
                        colorId++;
                    }

                    // bytes memory color = colors[colorId].list[
                    //     (_seed + j) % colors[colorId].count
                    // ];
                    //colorsArray[j] = color;

                    token.layers[i].colors[j] = colors[colorId].list[
                        randomNumber(
                            _seed + ((i + 69) * (j + 420)),
                            [start, end]
                        )
                    ];
                }
                token.revealed = true;
            }

            //  uint32[] memory layers = new uint32[](8);
            // token.layers = new uint32[](10);

            // layers[0] = 0;
            // layers[1] = 1;
            // layers[2] = 2;
            // layers[3] = 3;
            // layers[4] = 4;
            // layers[5] = 5;
            // layers[6] = 6;
            // layers[7] = 8;
            // layers[8] = 8;

            //loop and add 2,1,3,4 layers 1000 times to test size and reveal

            //token.layers = layers;

            //token.layer[0].colors = new uint32[](1);
        }
    }

    // function revealArt(RevealToken calldata _revealToken)
    //     external
    //     onlyValidAccess(
    //         _revealToken.v,
    //         _revealToken.r,
    //         _revealToken.s,
    //         nonces[msg.sender],
    //         _revealToken.drop,
    //         _revealToken.index,
    //         msg.sender
    //     )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];
    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgList[i].count;
    //             uint256 varCount = svgLayers[i].attributes[svgNumber].varCount;

    //             //create new array of 9 empty

    //             if (i == 4 && svgNumber == 1) {
    //                 female = true;
    //                 token.count += 1;
    //             }

    //             if (!female && svgNumber == 12) break;

    //             uint256[] memory colorMapping = svgLayers[i]
    //                 .attributes[svgNumber]
    //                 .colorMapping;
    //             bytes[] memory colorsArray = new bytes[](varCount);
    //             for (uint32 j = 0; j < varCount; j++) {
    //                 uint256 colorId = svgLayers[i].attributes[j].colorId;

    //                 if (female && i == 7) {
    //                     colorId++;
    //                 }

    //                 bytes memory color = colors[colorId].list[
    //                     (_seed + j) % colors[colorId].count
    //                 ];
    //                 colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colorsArray[colorMapping[j]];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    //TODO: create metadata system
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!tokens[_tokenId].revealed) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "animation_url":"',
                                string(
                                    abi.encodePacked(
                                        baseURI,
                                        drops[0].ipfsPreview
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                );
        }

        // uint256 _seed = tokens[_tokenId].seed;

        // uint256 loopCount = tokens[_tokenId].layers.length;

        // //loop through count and generate svg
        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);
        // for (uint256 i = 0; i < loopCount; i++) {
        //     uint32 layer = tokens[_tokenId].layers[i];
        //     _svg = abi.encodePacked(_svg, generateSVG(layer, _seed));
        // }

        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);

        // uint32 layer = tokens[_tokenId].layers[0];

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "image":"data:image/svg+xml;base64,',
                Base64.encode(
                    this.recursiveGenerateSVG(
                        abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]),
                        0,
                        _tokenId
                    )
                ),
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function recursiveGenerateSVG(
        bytes memory svgBytes,
        uint32 id,
        uint256 _tokenId
    ) external view returns (bytes memory) {
        uint256 _seed = tokens[_tokenId].seed;
        uint256 svgNumber = _seed % svgLayers[id].layerCount;

        uint32 oddFound = 0;

        //loop through string to create svg with required colors

        bytes memory newSvg = abi.encodePacked(
            attributes[id].info[svgNumber].svg[0]
        );

        // string[3] private bgSvgGrad = [
        //     '<defs><linearGradient id="d" y2="1" x2="0"><stop stop-color="',
        //     '" offset="0"/><stop stop-color="',
        //     '" offset="1"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#d)"/>'
        // ];

        for (
            uint256 i = 1;
            i < attributes[id].info[svgNumber].svg.length * 2 - 1;
            i++
        ) {
            //if odd then color is found
            if (i % 2 == 1) {
                //check if number or color
                if (attributes[id].info[svgNumber].isNumber[oddFound]) {
                    newSvg = abi.encodePacked(
                        newSvg,
                        Strings.toString(
                            randomNumber(
                                _seed,
                                attributes[id].info[svgNumber].range[oddFound]
                            )
                        )
                    );
                } else
                    newSvg = abi.encodePacked(
                        newSvg,
                        tokens[_tokenId].layers[id].colors[oddFound]
                    );
                oddFound++;
            } else {
                newSvg = abi.encodePacked(
                    newSvg,
                    attributes[id].info[svgNumber].svg[i - oddFound]
                );
            }
        }
        if (id != 0) {
            svgBytes = abi.encodePacked(
                svgBytes,
                svg[0],
                attributes[id].info[svgNumber].x,
                svg[1],
                attributes[id].info[svgNumber].y,
                svg[2],
                newSvg,
                svg[3]
            );
        } else {
            svgBytes = abi.encodePacked(svgBytes, newSvg);
        }

        if (id < tokens[_tokenId].count) {
            return this.recursiveGenerateSVG(svgBytes, id + 1, _tokenId);
        } else return abi.encodePacked(svgBytes, "</svg>");
    }

    // function recursiveGenerateSVG(
    //         bytes memory svgBytes,
    //         uint32 id,
    //         uint256 _tokenId
    //     ) external view returns (bytes memory) {
    //         id = tokens[_tokenId].layers[id];
    //         uint256 _seed = tokens[_tokenId].seed;

    //         uint256 svgNumber = _seed % svgList[id].count;

    //         uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //         uint32 oddFound = 0;

    //         //loop through string to create svg with required colors

    //         bytes[] memory colorsArray = new bytes[](varCount);
    //         bytes memory newSvg = abi.encodePacked(
    //             svgList[id].layer[svgNumber].svg[0]
    //         );
    //         for (
    //             uint256 i = 1;
    //             i < svgList[id].layer[svgNumber].svg.length + varCount;
    //             i++
    //         ) {
    //             //if odd then color is found
    //             if (i % 2 == 1) {
    //                 colorsArray[oddFound] = colors[
    //                     svgLayers[id].attributes[svgNumber].colorId
    //                 ].list[
    //                         uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                             colors[id].count
    //                     ];
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     colorsArray[
    //                         svgLayers[id].attributes[svgNumber].colorMapping[
    //                             oddFound
    //                         ]
    //                     ]
    //                 );
    //                 oddFound++;
    //             } else {
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     svgList[id].layer[svgNumber].svg[i - oddFound]
    //                 );
    //             }
    //         }
    //         if (id != 0) {
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 svg[0],
    //                 svgList[id].layer[svgNumber].x,
    //                 svg[1],
    //                 svgList[id].layer[svgNumber].y,
    //                 svg[2],
    //                 newSvg,
    //                 svg[3]
    //             );
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, newSvg);
    //         }

    //         if (id < tokens[_tokenId].layers.length - 1) {
    //             return this.recursiveGenerateSVG(svgBytes, id + 1, _tokenId);
    //         } else return svgBytes;
    //     }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.0;

//////////////////////////////////////////////
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//★    _______  _____  _______ ___  _____  ★//
//★   / __/ _ \/ ___/ /_  /_  <  / / ___/  ★//
//★  / _// , _/ /__    / / __// / / (_ /   ★//
//★ /___/_/|_|\___/   /_/____/_/  \___/    ★//
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//  by: 0xInuarashi                         //
//////////////////////////////////////////////
//  Audits: 0xAkihiko, 0xFoobar             //
//////////////////////////////////////////////
//  Default: Staking Disabled               //
//////////////////////////////////////////////

contract ERC721G {
    // Standard ERC721 Events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId
    uint256 public immutable startTokenId; // Bytes Storage for the starting TokenId
    uint256 public immutable maxBatchSize;

    // ERC721G Staking Address Target
    function stakingAddress() public view returns (address) {
        return address(this);
    }

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startId_,
        uint256 maxBatchSize_
    ) {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf
        uint32 lastTransfer; // stores the last transfer of the token
        uint32 stakeTimestamp; // stores the stake timestamp in _setStakeTimestamp()
        uint32 totalTimeStaked; // stores the total time staked accumulated
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveall

    // Time Expansion and Compression by 0xInuarashi
    /** @dev Time Expansion and Compression extends the usage of ERC721G from
     *  Year 2106 (end of uint32) to Year 3331 (end of uint32 with time expansion)
     *  the trade-off is that staking accuracy is scoped within 10-second chunks
     */
    function _getBlockTimestampCompressed()
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(block.timestamp / 10);
    }

    function _compressTimestamp(uint256 timestamp_)
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(timestamp_ / 10);
    }

    function _expandTimestamp(uint32 timestamp_)
        public
        view
        virtual
        returns (uint256)
    {
        return uint256(timestamp_) * 10;
    }

    function getLastTransfer(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).lastTransfer);
    }

    function getStakeTimestamp(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).stakeTimestamp);
    }

    function getTotalTimeStaked(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).totalTimeStaked);
    }

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public view virtual returns (uint256) {
        return tokenIndex - startTokenId;
    }

    function balanceOf(address address_) public view virtual returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////

    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     *
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_)
        public
        view
        virtual
        returns (OwnerStruct memory)
    {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");

        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (
            _tokenData[tokenId_].owner != address(0) || tokenId_ >= tokenIndex
        ) {
            return _tokenData[tokenId_];
        }
        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else {
            unchecked {
                uint256 _lowerRange = tokenId_;
                while (mintIndex[_lowerRange].owner == address(0)) {
                    _lowerRange--;
                }
                return mintIndex[_lowerRange];
            }
        }
    }

    /** @dev explanation:
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public view virtual returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return
            _OwnerStruct.stakeTimestamp == 0
                ? _OwnerStruct.owner
                : stakingAddress();
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks.
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_)
        public
        view
        virtual
        returns (address)
    {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////

    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not.
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(
        uint256 tokenId_,
        OwnerStruct memory _OwnerStruct
    ) internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    /** @dev explanation:
     *  _setStakeTimestamp() is our staking / unstaking logic.
     *  If timestamp_ is > 0, the action is "stake"
     *  If timestamp_ is == 0, the action is "unstake"
     *
     *  We grab the tokenData using _getTokenDataOf and then read its values.
     *  As this function requires INITIALIZED tokens only, we call _initializeTokenIf()
     *  to initialize any token using this function first.
     *
     *  Processing of the function is explained in in-line comments.
     */
    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_)
        internal
        virtual
        returns (address)
    {
        // First, call _getTokenDataOf and grab the relevant tokenData
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        // _setStakeTimestamp requires initialization
        _initializeTokenIf(tokenId_, _OwnerStruct);

        // Clear any token approvals
        delete getApproved[tokenId_];

        // if timestamp_ > 0, the action is "stake"
        if (timestamp_ > 0) {
            // Make sure that the token is not staked already
            require(
                _stakeTimestamp == 0,
                "ERC721G: _setStakeTimestamp() already staked"
            );

            // Callbrate balances between staker and stakingAddress
            unchecked {
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }

            // Emit Transfer event from trueOwner
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }
        // if timestamp_ == 0, the action is "unstake"
        else {
            // Make sure the token is not staked
            require(
                _stakeTimestamp != 0,
                "ERC721G: _setStakeTimestamp() already unstaked"
            );

            // Callibrate balances between stakingAddress and staker
            unchecked {
                _balanceData[_owner].balance++;
                _balanceData[stakingAddress()].balance--;
            }

            // we add total time staked to the token on unstake
            uint32 _timeStaked = _getBlockTimestampCompressed() -
                _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;

            // Emit Transfer event to trueOwner
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        // Set the stakeTimestamp to timestamp_
        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        // We save internal gas by returning the owner for a follow-up function
        return _owner;
    }

    /** @dev explanation:
     *  _stake() works like an extended function of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the staking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _stake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to block.timestamp and return the owner
        return _setStakeTimestamp(tokenId_, block.timestamp);
    }

    /** @dev explanation:
     *  _unstake() works like an extended unction of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the unstaking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _unstake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to 0 and return the owner
        return _setStakeTimestamp(tokenId_, 0);
    }

    /** @dev explanation:
     *  _mintAndStakeInternal() is the internal mintAndStake function that is called
     *  to mintAndStake tokens to users.
     *
     *  It populates mintIndex with the phantom-mint data (owner, lastTransferTime)
     *  as well as the phantom-stake data (stakeTimestamp)
     *
     *  Then, it emits the necessary phantom events to replicate the behavior as canon.
     *
     *  Further logic explained in in-line comments.
     */
    function _mintAndStakeInternal(address to_, uint256 amount_)
        internal
        virtual
    {
        // we cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintAndStakeInternal to 0x0");

        // we limit max mints per SSTORE to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintAndStakeInternal over maxBatchSize"
        );

        // process the required variables to write to mintIndex
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;
        uint32 _currentTime = _getBlockTimestampCompressed();

        // write to the mintIndex to store the OwnerStruct for uninitialized tokenData
        mintIndex[_startId] = OwnerStruct(
            to_, // the address the token is minted to
            _currentTime, // the last transfer time
            _currentTime, // the curent time of staking
            0 // the accumulated time staked
        );

        unchecked {
            // we add the balance to the stakingAddress through our staking logic
            _balanceData[stakingAddress()].balance += uint32(amount_);

            // we add the mintedAmount to the to_ through our minting logic
            _balanceData[to_].mintedAmount += uint32(amount_);

            // emit phantom mint to to_, then emit a staking transfer
            do {
                emit Transfer(address(0), to_, _startId);
                emit Transfer(to_, stakingAddress(), _startId);
            } while (++_startId < _endId);
        }

        // set the new tokenIndex to the _endId
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mintAndStake() calls _mintAndStakeInternal() but calls it using a while-loop
     *  based on the required minting amount to stay within the bounds of
     *  max mints per batch (maxBatchSize)
     */
    function _mintAndStake(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintAndStakeInternal(to_, maxBatchSize);
        }
        _mintAndStakeInternal(to_, _amountToMint);
    }

    ///// ERC721G Range-Based Internal Minting Logic /////

    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic.
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintInternal over maxBatchSize"
        );

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        mintIndex[_startId].owner = to_;
        mintIndex[_startId].lastTransfer = _getBlockTimestampCompressed();

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked {
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do {
                emit Transfer(address(0), to_, _startId);
            } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     *
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *
     *  this results in INITIALIZATION of the token, if it has not been initialized yet.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

        // update the balance data
        unchecked {
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    ///// Note: You may implement your own staking functionality     /////
    /////       by using _stake() and _unstake() functions instead   /////
    /////       These are merely out-of-the-box standard functions   /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev clarification:
    //  *  As a developer, you DO NOT have to enable these functions, or use them
    //  *  in the way defined in this section.
    //  *
    //  *  The functions in this section are just out-of-the-box plug-and-play staking
    //  *  which is enabled IMMEDIATELY.
    //  *  (As well as some useful view-functions)
    //  *
    //  *  You can choose to call the internal staking functions yourself, to create
    //  *  custom staking logic based on the section (n-2) above.
    //  */
    // /** @dev explanation:
    // *  this is a staking function that receives calldata tokenIds_ array
    // *  and loops to call internal _stake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    // function stake(uint256[] calldata tokenIds_) public virtual {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     while (i < l) {
    //         // stake and return the owner's address
    //         address _owner = _stake(tokenIds_[i]);
    //         // make sure the msg.sender is the owner
    //         require(msg.sender == _owner, "You are not the owner!");
    //         unchecked {++i;}
    //     }
    // }
    // /** @dev explanation:
    // *  this is an unstaking function that receives calldata tokenIds_ array
    // *  and loops to call internal _unstake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    // function unstake(uint256[] calldata tokenIds_) public virtual {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     while (i < l) {
    //         // unstake and return the owner's address
    //         address _owner = _unstake(tokenIds_[i]);
    //         // make sure the msg.sender is the owner
    //         require(msg.sender == _owner, "You are not the owner!");
    //         unchecked {++i;}
    //     }
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    /////      ERC721G: User-Enabled Staking Helper Functions        /////
    /////      Note: You MUST enable staking functionality           /////
    /////            To make use of these functions below            /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev explanation:
    //  *  balanceOfStaked loops through the entire tokens using
    //  *  startTokenId as the start pointer, and
    //  *  tokenIndex (current-next tokenId) as the end pointer
    //  *
    //  *  it checks if the _trueOwnerOf() is the address_ or not
    //  *  and if the owner() is not the address, indicating the
    //  *  state that the token is staked.
    //  *
    //  *  if so, it increases the balance. after the loop, it returns the balance.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function balanceOfStaked(address address_) public virtual view
    // returns (uint256) {
    //     uint256 _balance;
    //     uint256 i = startTokenId;
    //     uint256 max = tokenIndex;
    //     while (i < max) {
    //         if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
    //             _balance++;
    //         }
    //         unchecked { ++i; }
    //     }
    //     return _balance;
    // }
    // /** @dev explanation:
    //  *  walletOfOwnerStaked calls balanceOfStaked to get the staked
    //  *  balance of a user. Afterwards, it runs staked-checking logic
    //  *  to figure out the tokenIds that the user has staked
    //  *  and then returns it in walletOfOwner fashion.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function walletOfOwnerStaked(address address_) public virtual view
    // returns (uint256[] memory) {
    //     uint256 _balance = balanceOfStaked(address_);
    //     uint256[] memory _tokens = new uint256[] (_balance);
    //     uint256 _currentIndex;
    //     uint256 i = startTokenId;
    //     while (_currentIndex < _balance) {
    //         if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
    //             _tokens[_currentIndex++] = i;
    //         }
    //         unchecked { ++i; }
    //     }
    //     return _tokens;
    // }
    // /** @dev explanation:
    //  *  balanceOf of the address returns UNSTAKED tokens only.
    //  *  to get the total balance of the user containing both STAKED and UNSTAKED tokens,
    //  *  we use this function.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function totalBalanceOf(address address_) public virtual view returns (uint256) {
    //     return balanceOf(address_) + balanceOfStaked(address_);
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfToken returns the accumulative total time staked of a tokenId
    //  *  it reads from the totalTimeStaked of the tokenId_ and adds it with
    //  *  a calculation of pending time staked and returns the sum of both values.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes.
    //  */
    // function totalTimeStakedOfToken(uint256 tokenId_) public virtual view
    // returns (uint256) {
    //     OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
    //     uint256 _totalTimeStakedOnToken = _expandTimestamp(_OwnerStruct.totalTimeStaked);
    //     uint256 _totalTimeStakedPending =
    //         _OwnerStruct.stakeTimestamp > 0 ?
    //         _expandTimestamp(
    //             _getBlockTimestampCompressed() - _OwnerStruct.stakeTimestamp) :
    //             0;
    //     return _totalTimeStakedOnToken + _totalTimeStakedPending;
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfTokens just returns an array of totalTimeStakedOfToken
    //  *  based on tokenIds_ calldata.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes... however
    //  *  BE CAREFUL and USE IT CORRECTLY.
    //  *  (dont pass in 5000 tokenIds_ in a write function)
    //  */
    // function totalTimeStakedOfTokens(uint256[] calldata tokenIds_) public
    // virtual view returns (uint256[] memory) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     uint256[] memory _totalTimeStakeds = new uint256[] (l);
    //     while (i < l) {
    //         _totalTimeStakeds[i] = totalTimeStakedOfToken(tokenIds_[i]);
    //         unchecked { ++i; }
    //     }
    //     return _totalTimeStakeds;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Staking Helper Functions             /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    ///// Note: You do not need to enable these. It makes querying   /////
    /////       things cheaper in GAS at around 1.5k per token       /////
    ////        if you choose to query things as such                /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using ownerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (ownerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using _trueOwnerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isTrueOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (_trueOwnerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        address _owner = ownerOf(tokenId_);
        return (// "i am the owner of the token, and i am transferring it"
        _owner == spender_ ||
            // "the token's approved spender is me"
            getApproved[tokenId_] == spender_ ||
            // "the owner has approved me to spend all his tokens"
            isApprovedForAll[_owner][spender_]);
    }

    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender ||
                // "i am isApprovedForAll, so i can approve this token too."
                isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
    {
        // this function can only be used as self-approvalforall for others.
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized"
        );
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from_,
                    tokenId_,
                    data_
                )
            );
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(
                _selector == 0x150b7a02,
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!"
            );
        }
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function supportsInterface(bytes4 iid_) public view virtual returns (bool) {
        return
            iid_ == 0x01ffc9a7 ||
            iid_ == 0x80ac58cd ||
            iid_ == 0x5b5e139f ||
            iid_ == 0x7f5828d0;
    }

    /** @dev description: walletOfOwner to query an array of wallet's
     *  owned tokens. A view-intensive alternative ERC721Enumerable function.
     */
    function walletOfOwner(address address_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) {
                _tokens[_currentIndex++] = i;
            }
            unchecked {
                ++i;
            }
        }
        return _tokens;
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////

    /** @dev requirement: You MUST implement your own tokenURI logic here
     *  recommended to use through an override function in your main contract.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {}
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