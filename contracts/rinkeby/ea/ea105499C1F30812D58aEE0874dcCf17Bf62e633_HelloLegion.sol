/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MEVArmyTraitData {

    function getLegionDecoded(uint256 tokenId) external view returns (string memory) {}

}

contract HelloLegion {

    address constant MEV_ARMY_TRAIT_CONTRACT = 0x7c2Dd85e0529D02b7CCF0Bd17F22693FCf5AE135;

    // Quest Part 1: You'll need to implement this function to return "Hello, Legion!"
    function sayHello() public pure returns (string memory) {
        // Add your code below here
        return formattedLegionOutput("Legion");
        // Add your code above here
    }

    // Quest Part 2: You'll need to implement this function to return the legion name for any given tokenId
    // Note: It must return the correct legion for every possible `tokenId`.
    // E.g. If using tokenId 1, it should return "generalized frontrunner"
    // E.g. If using tokenId 2, it should return "searcher"
    function sayLegion(uint256 tokenId) public view returns (string memory) {
        // Add your code below here
        return getLegionName(tokenId);
        // Add your code above here
    }

    // Quest Part 3: You'll need to implement this function to return "Hello, <legion name>!"
    // based on the provided `tokenId`.
    // Note: It must return the correct legion for every possible `tokenId`.
    // E.g. If using tokenId 1, it should return "Hello, generalized frontrunner!"
    // E.g. If using tokenId 2, it should return "Hello, searcher!"
    // 
    // Hint: You'll want to make use of some of the other private functions below and combine some
    // of the lessons you've learned in parts 1 and 2.
    function sayHelloLegion(uint256 tokenId) public view returns (string memory) {
        // Add your code below here
        return formattedLegionOutput(getLegionName(tokenId));
        // Add your code above here
    }

    // --------------------------------------------------------------------------

    // Private Functions
    // Hint: You'll be able to use some of these functions to help complete the two quests above.

    // This function will take a `legion` string and output "Hello, <legion>!" fully formatted.
    // E.g. If you call 'formattedLegionOutput("searcher")`, it will return "Hello, searcher!"
    function formattedLegionOutput(string memory legion) private pure returns (string memory) {
        return concatenate('Hello,', string(abi.encodePacked(legion, '!')));
    }

    // This function will concatenate two provided strings, `a` and `b` with a space character in between.
    // E.g. If you call `concatenate("x0r", "art")`, it will return "x0r art"
    function concatenate(string memory a, string memory b) private pure returns (string memory) {
        return string(abi.encodePacked(a,' ',b));
    } 

    // This function will lookup the legion for a provided `tokenId` based on MEV Army Trait Data.
    // E.g. If you call `getLegionName(1)`, it will return "generalized frontrunner"
    function getLegionName(uint256 tokenId) private view returns (string memory) {
        // Load the deployed MEVArmyTraitData contract
        MEVArmyTraitData traitData = MEVArmyTraitData(MEV_ARMY_TRAIT_CONTRACT);

        // Call the `getLegionDecoded()` function off of the MEVArmyTraitData contract to get the legion name
        string memory legion = traitData.getLegionDecoded(tokenId);

        // Return the found legion
        return legion;
    }

}