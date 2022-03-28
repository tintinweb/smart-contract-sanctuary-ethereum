/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * 
 *    
 *   the_coin "Issuance" Bitcoin Halving Clock Updater by Takens Theorem
 * 
 *   Terms, conditions: Experimental, use at your own risk. Contract and tokens are
 *   as-is and as-available without any and all warranty. By using this contract 
 *   you accept sole responsibility for any and all transactions involving 
 *   the_coin, including this updater contract. 
 *
 *   NB: Make sure you setApprovalForAll() for this contract on the_coin contract
 * 
 * 
 */

contract the_coin {
    function changeStyleMode(uint256 tokenId, string memory styleMode) public returns (string memory) {}
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
}

contract TCTTMOD1 {
    
    address coin_address = 0xf76c5d925b27a63a3745A6b787664A7f38fA79bd;

    string part1 = "path{fill:none;}circle{fill:";
    string part2 = "}text{fill:var(--f);}rect{fill:var(--b);}circle:nth-child(-3n+";
    string part3 = "){stroke-width:2pt;stroke:var(--f);}";

    /**
     * @notice Updates Bitcoin Halving Clock on the_coin
     * @param tokenId The tokenId must point to "Issuance" token on the_coin (1, 2, 3, 4, 17, ...)
     * @param btcBlockHeight The current BTC block height in integer form (no commas)
     * @param htmlColor Leave htmlColor blank for default BTC orange + alpha (#f2a90033). Otherwise, use an HTML color with hash character.
     * @param colorMode Set colorMode = 1 for light mode; 2 for dark mode
     * @return Success of style modification
    **/ 
    function setHalvingClock(uint256 tokenId, uint256 btcBlockHeight, string memory htmlColor, uint256 colorMode) public returns (string memory) {         
        require(colorMode==1 || colorMode==2, "Color mode must be 1 or 2");
        require(the_coin(coin_address).ownerOf(tokenId)==msg.sender,"You do not own this token");

        string memory rootStyle;
        if (colorMode==1) {
            rootStyle = ":root{--f:black;--b:white;}";
        } else {
            rootStyle = ":root{--f:white;--b:black;}";
        }

        if (keccak256(abi.encodePacked(htmlColor)) == keccak256(abi.encodePacked(""))) {
            htmlColor = "#f2a90033";
        }

        uint256 halvingRing = (btcBlockHeight / 210000) * 3;
        string memory cssString = string(abi.encodePacked(rootStyle,part1,htmlColor,part2,
                                            toString(halvingRing),part3));

        return the_coin(coin_address).changeStyleMode(tokenId,cssString); 
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // cf. OraclizeAPI's implementation - MIT licence
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

    constructor() {}    
}