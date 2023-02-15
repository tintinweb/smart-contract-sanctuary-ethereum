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

    function getImageData(HeartColor color) public view returns (string memory) {
        require(uint8(color) < uint8(HeartColor.Length), "c");
        string memory colorStr = colorToHex[uint256(color)];

        string memory toReturn = string(
            abi.encodePacked(
                "<svg width=\"1008\" height=\"1008\" viewBox=\"0 0 1008 1008\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\">",
                "<rect width=\"1008\" height=\"1008\" fill=\"#1E1E1E\"/>",
                "<g filter=\"url(#filter0_d_0_1)\">",
                "<rect width=\"1000\" height=\"1000\" transform=\"translate(4)\" fill=\"#BD1313\"/>",
                "<rect width=\"1000\" height=\"1000\" transform=\"translate(4)\" fill=\"#E00E0E\"/>",
                "<rect x=\"4.5\" y=\"0.5\" width=\"999\" height=\"999\" fill=\"#232323\" stroke=\"white\"/>",
                "<rect x=\"354\" y=\"350\" width=\"300\" height=\"300\" rx=\"3\" fill=\"white\"/>",
                "<rect x=\"354.9\" y=\"350.9\" width=\"298.2\" height=\"298.2\" rx=\"2.1\" fill=\"#1E1E1E\" stroke=\"white\" stroke-width=\"1.8\"/>"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                    "<rect x=\"433.355\" y=\"506.421\" width=\"100\" height=\"100\" transform=\"rotate(-45 433.355 506.421)\" fill=\"#", colorStr, "\"/>",
                    "<circle cx=\"468.711\" cy=\"471.066\" r=\"50\" transform=\"rotate(-45 468.711 471.066)\" fill=\"#", colorStr, "\"/>",
                    "<circle cx=\"539.421\" cy=\"471.066\" r=\"50\" transform=\"rotate(-45 539.421 471.066)\" fill=\"#", colorStr, "\"/>",
                    "<g clip-path=\"url(#clip0_0_1)\">"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                    "<path d=\"M650.1 350.9H357.9C356.243 350.9 354.9 352.243 354.9 353.9V646.1C354.9 647.757 356.243 649.1 357.9 649.1H650.1C651.757 649.1 653.1 647.757 653.1 646.1V353.9C653.1 352.243 651.757 350.9 650.1 350.9Z\" fill=\"#1E1E1E\" stroke=\"white\" stroke-width=\"1.8\" stroke-linejoin=\"round\"/>",
                    "<path d=\"M504.066 435.71L433.355 506.421L504.066 577.132L574.777 506.421L504.066 435.71Z\" fill=\"#", colorStr, "\"/>",
                    "<path d=\"M504.066 506.421C523.592 486.895 523.592 455.237 504.066 435.711C484.54 416.184 452.882 416.184 433.356 435.711C413.829 455.237 413.829 486.895 433.356 506.421C452.882 525.948 484.54 525.948 504.066 506.421Z\" fill=\"#", colorStr, "\"/>",
                    "<path d=\"M574.776 506.421C594.303 486.895 594.303 455.237 574.776 435.711C555.25 416.184 523.592 416.184 504.066 435.711C484.54 455.237 484.54 486.895 504.066 506.421C523.592 525.948 555.25 525.948 574.776 506.421Z\" fill=\"#", colorStr, "\"/>"
            )
        );

        return string(
            abi.encodePacked(
                toReturn,
                    "</g></g><defs>",
                    "<filter id=\"filter0_d_0_1\" x=\"0\" y=\"0\" width=\"1008\" height=\"1008\" filterUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">",
                    "<feFlood flood-opacity=\"0\" result=\"BackgroundImageFix\"/>",
                    "<feColorMatrix in=\"SourceAlpha\" type=\"matrix\" values=\"0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0\" result=\"hardAlpha\"/>",
                    "<feOffset dy=\"4\"/><feGaussianBlur stdDeviation=\"2\"/><feComposite in2=\"hardAlpha\" operator=\"out\"/>",
                    "<feColorMatrix type=\"matrix\" values=\"0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0\"/>",
                    "<feBlend mode=\"normal\" in2=\"BackgroundImageFix\" result=\"effect1_dropShadow_0_1\"/>",
                    "<feBlend mode=\"normal\" in=\"SourceGraphic\" in2=\"effect1_dropShadow_0_1\" result=\"shape\"/>",
                    "</filter><clipPath id=\"clip0_0_1\">",
                    "<rect x=\"354\" y=\"350\" width=\"300\" height=\"300\" rx=\"6\" fill=\"white\"/>",
                    "</clipPath></defs></svg>"
            )
        );
    }
}