// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

pragma solidity ^0.8.17;

enum HeartColor {
    Red,
    Blue,
    Green,
    Yellow,
    Orange,
    Purple,
    Black,
    White,
    Length
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "./HeartColors.sol";

contract IDG {
    mapping(uint256 => string) private colorToHex;

    constructor() {
        colorToHex[0] = "DD2E44"; // red
        colorToHex[1] = "5CADED"; // blue
        colorToHex[2] = "77B05A"; // green
        colorToHex[3] = "FCCB58"; // yellow
        colorToHex[4] = "F2900D"; // orange
        colorToHex[5] = "A98FD5"; // purple
        colorToHex[6] = "31383C"; // black
        colorToHex[7] = "E6E7E8"; // white
    }

//    width='100%25' height='100%25'

//    function getImageData(HeartColor color) public view returns (string memory) {
//        require(uint8(color) < uint8(HeartColor.Length), "c");
//        string memory colorStr = colorToHex[uint256(color)];
//
//        string memory toReturn = string(
//            abi.encodePacked(
//                "<svg%2520width='1000'%2520height='1000'%2520viewBox='0%25200%25201000%25201000'%2520fill='none'%2520xmlns='http://www.w3.org/2000/svg'>",
//                "<rect%2520width='1000'%2520height='1000'%2520fill='%25231E1E1E'/>",
//                "<g%2520filter='url(%2523filter0_d_0_1)'>",
//                "<rect%2520width='1000'%2520height='1000'%2520transform='translate(4)'%2520fill='%2523BD1313'/>",
//                "<rect%2520width='1000'%2520height='1000'%2520transform='translate(4)'%2520fill='%2523E00E0E'/>",
//                "<rect%2520x='0.5'%2520y='0.5'%2520width='999'%2520height='999'%2520fill='%2523232323'%2520stroke='white'/>",
//                "<rect%2520x='354'%2520y='350'%2520width='300'%2520height='300'%2520rx='3'%2520fill='white'/>",
//                "<rect%2520x='354.9'%2520y='350.9'%2520width='298.2'%2520height='298.2'%2520rx='2.1'%2520fill='%25231E1E1E'%2520stroke='white'%2520stroke-width='1.8'/>"
//            )
//        );
//
//        toReturn = string(
//            abi.encodePacked(
//                toReturn,
//                    "<rect%2520x='433.355'%2520y='506.421'%2520width='100'%2520height='100'%2520transform='rotate(-45%2520433.355%2520506.421)'%2520fill='%2523", colorStr, "'/>",
//                    "<circle%2520cx='468.711'%2520cy='471.066'%2520r='50'%2520transform='rotate(-45%2520468.711%2520471.066)'%2520fill='%2523", colorStr, "'/>",
//                    "<circle%2520cx='539.421'%2520cy='471.066'%2520r='50'%2520transform='rotate(-45%2520539.421%2520471.066)'%2520fill='%2523", colorStr, "'/>",
//                    "<g%2520clip-path='url(%2523clip0_0_1)'>"
//            )
//        );
//
//        toReturn = string(
//            abi.encodePacked(
//                toReturn,
//                    "<path%2520d='M650.1%2520350.9H357.9C356.243%2520350.9%2520354.9%2520352.243%2520354.9%2520353.9V646.1C354.9%2520647.757%2520356.243%2520649.1%2520357.9%2520649.1H650.1C651.757%2520649.1%2520653.1%2520647.757%2520653.1%2520646.1V353.9C653.1%2520352.243%2520651.757%2520350.9%2520650.1%2520350.9Z'%2520fill='%25231E1E1E'%2520stroke='white'%2520stroke-width='1.8'%2520stroke-linejoin='round'/>",
//                    "<path%2520d='M504.066%2520435.71L433.355%2520506.421L504.066%2520577.132L574.777%2520506.421L504.066%2520435.71Z'%2520fill='%2523", colorStr, "'/>",
//                    "<path%2520d='M504.066%2520506.421C523.592%2520486.895%2520523.592%2520455.237%2520504.066%2520435.711C484.54%2520416.184%2520452.882%2520416.184%2520433.356%2520435.711C413.829%2520455.237%2520413.829%2520486.895%2520433.356%2520506.421C452.882%2520525.948%2520484.54%2520525.948%2520504.066%2520506.421Z'%2520fill='%2523", colorStr, "'/>",
//                    "<path%2520d='M574.776%2520506.421C594.303%2520486.895%2520594.303%2520455.237%2520574.776%2520435.711C555.25%2520416.184%2520523.592%2520416.184%2520504.066%2520435.711C484.54%2520455.237%2520484.54%2520486.895%2520504.066%2520506.421C523.592%2520525.948%2520555.25%2520525.948%2520574.776%2520506.421Z'%2520fill='%2523", colorStr, "'/>"
//            )
//        );
//
//        return string(
//            abi.encodePacked(
//                toReturn,
//                    "</g></g><defs>",
//                    "<filter%2520id='filter0_d_0_1'%2520x='0'%2520y='0'%2520width='1008'%2520height='1008'%2520filterUnits='userSpaceOnUse'%2520color-interpolation-filters='sRGB'>",
//                    "<feFlood%2520flood-opacity='0'%2520result='BackgroundImageFix'/>",
//                    "<feColorMatrix%2520in='SourceAlpha'%2520type='matrix'%2520values='0%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%2520127%25200'%2520result='hardAlpha'/>",
//                    "<feOffset%2520dy='4'/><feGaussianBlur%2520stdDeviation='2'/><feComposite%2520in2='hardAlpha'%2520operator='out'/>",
//                    "<feColorMatrix%2520type='matrix'%2520values='0%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200%25200.25%25200'/>",
//                    "<feBlend%2520mode='normal'%2520in2='BackgroundImageFix'%2520result='effect1_dropShadow_0_1'/>",
//                    "<feBlend%2520mode='normal'%2520in='SourceGraphic'%2520in2='effect1_dropShadow_0_1'%2520result='shape'/>",
//                    "</filter><clipPath%2520id='clip0_0_1'>",
//                    "<rect%2520x='354'%2520y='350'%2520width='300'%2520height='300'%2520rx='6'%2520fill='white'/>",
//                    "</clipPath></defs></svg>"
//            )
//        );
//    }

    function getImageData(HeartColor color) public view returns (string memory) {
        require(uint8(color) < uint8(HeartColor.Length), "c");
        string memory colorStr = colorToHex[uint256(color)];

        string memory toReturn = string(
            abi.encodePacked(
                "<svg width='100%25' height='100%25' viewBox='0 0 1000 1000' fill='none' xmlns='http://www.w3.org/2000/svg'>",
                "<rect width='1000' height='1000' fill='%231E1E1E'/>",
                "<g filter='url(%23filter0_d_0_1)'>",
                "<rect x='0.5' y='0.5' width='999' height='999' fill='%23232323' stroke='white'/>",
                "<rect x='354' y='350' width='300' height='300' rx='3' fill='white'/>",
                "<rect x='354.9' y='350.9' width='298.2' height='298.2' rx='2.1' fill='%231E1E1E' stroke='white' stroke-width='1.8'/>"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                "<rect x='433.355' y='506.421' width='100' height='100' transform='rotate(-45 433.355 506.421)' fill='%23", colorStr, "'/>",
                "<circle cx='468.711' cy='471.066' r='50' transform='rotate(-45 468.711 471.066)' fill='%23", colorStr, "'/>",
                "<circle cx='539.421' cy='471.066' r='50' transform='rotate(-45 539.421 471.066)' fill='%23", colorStr, "'/>",
                "<g clip-path='url(%23clip0_0_1)'>"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                "<path d='M650.1 350.9H357.9C356.243 350.9 354.9 352.243 354.9 353.9V646.1C354.9 647.757 356.243 649.1 357.9 649.1H650.1C651.757 649.1 653.1 647.757 653.1 646.1V353.9C653.1 352.243 651.757 350.9 650.1 350.9Z' fill='%231E1E1E' stroke='white' stroke-width='1.8' stroke-linejoin='round'/>",
                "<path d='M504.066 435.71L433.355 506.421L504.066 577.132L574.777 506.421L504.066 435.71Z' fill='%23", colorStr, "'/>",
                "<path d='M504.066 506.421C523.592 486.895 523.592 455.237 504.066 435.711C484.54 416.184 452.882 416.184 433.356 435.711C413.829 455.237 413.829 486.895 433.356 506.421C452.882 525.948 484.54 525.948 504.066 506.421Z' fill='%23", colorStr, "'/>",
                "<path d='M574.776 506.421C594.303 486.895 594.303 455.237 574.776 435.711C555.25 416.184 523.592 416.184 504.066 435.711C484.54 455.237 484.54 486.895 504.066 506.421C523.592 525.948 555.25 525.948 574.776 506.421Z' fill='%23", colorStr, "'/>"
            )
        );

        return string(
            abi.encodePacked(
                toReturn,
                "</g></g><defs>",
                "<filter id='filter0_d_0_1' x='0' y='0' width='1008' height='1008' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'>",
                "<feFlood flood-opacity='0' result='BackgroundImageFix'/>",
                "<feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/>",
                "<feOffset dy='4'/><feGaussianBlur stdDeviation='2'/><feComposite in2='hardAlpha' operator='out'/>",
                "<feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0'/>",
                "<feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow_0_1'/>",
                "<feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow_0_1' result='shape'/>",
                "</filter><clipPath id='clip0_0_1'>",
                "<rect x='354' y='350' width='300' height='300' rx='6' fill='white'/>",
                "</clipPath></defs></svg>"
            )
        );
    }
}