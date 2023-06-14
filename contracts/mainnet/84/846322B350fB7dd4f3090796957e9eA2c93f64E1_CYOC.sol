// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract CYOC {

    // struct for NFT
    struct Citation {
        Type _type; // NFT type
        string word1; // cited 
        string word2; // citing 
    }
    // enum for NFT type
    enum Type {
        Proposed,
        Accepted,
        Rejected
    }

    // function for generating svg images
    function generateSVGImage(Citation memory citation) public pure returns (string memory) {
        string memory textcolor;
        string memory backgroundcolor;
        textcolor = "#FFFFFF";
        // set text color and background color 
        if (citation._type == Type.Proposed) {
            //textcolor = "#000000";
            backgroundcolor = "#282c34";
        } else if (citation._type == Type.Accepted) {
            //textcolor = "#FFFFFF";
            backgroundcolor = "#008000";
        } else if (citation._type == Type.Rejected) {
            //textcolor = "#FFFFFF";
            backgroundcolor = "#FF0000";
        }

        // generate svg images 
        string memory svgImage = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 350">',
                '<rect x="0" y="0" width="350" height="350" fill="', backgroundcolor, '"/>',
                '<g fill="', textcolor, '">',
                '<text x="5%" y="25%" font-size="15" font-weight="bold" font-family="roboto">', nftTypeToString(citation), '&#x3A; </text>',
                '<text x="5%" y="43%" font-size="30" font-weight="bold" font-family="roboto">', citation.word1, '</text>',
                '<text x="5%" y="55%" font-size="20" font-weight="bold" font-family="roboto"> &#0060;&#45;&#45; </text>',
                '<text x="5%" y="67%" font-size="30" font-weight="bold" font-family="roboto">', citation.word2, '</text>',
                '<text x="66.5%" y="90%" font-size="5.5" font-family="Times New Roman" font-style="italic"> Conceive Yourself of Your Own Context (alpha)</text>',
                '<text x="66.5%" y="92%" font-size="5" font-family="Times New Roman"> 2023 </text>',
                '<text x="66.5%" y="94%" font-size="5" font-family="Times New Roman"> Non-Fungible Token </text>',
                '<text x="66.5%" y="96%" font-size="5" font-family="Times New Roman"> 350*350 px </text>',
                '<text x="66.5%" y="98%" font-size="5" font-family="Times New Roman"> BUILDING BLOCKS at EUKARYOTE, Tokyo, Japan </text>',               
                '</g>'
                '</svg>'
            )
        );
        return svgImage;
    }

    // other examples for citation sign: &#8656;

    // function for changing NFT type to string 
    function nftTypeToString(Citation memory citation) public pure returns (string memory) {
        if (citation._type == Type.Proposed) {
            return "proposed";
        } else if (citation._type == Type.Accepted) {
            return "accepted";
        } else if (citation._type == Type.Rejected) {
            return "rejected";
        } else {
            return "";
        }
    }

    // fallback function
    receive() external payable {}
    // self destcruct fuction
    // only owner transfer function

}