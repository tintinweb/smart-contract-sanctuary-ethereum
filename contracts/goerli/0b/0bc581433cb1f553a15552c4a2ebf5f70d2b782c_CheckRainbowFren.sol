/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenFrensInterface {
    function totalSupply() public view returns (uint256) {}
    function _tokenIdToHash(uint256 _tokenId) public view returns (string memory) {}
}

contract CheckRainbowFren {
    
    address genFrensAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
    GenFrensInterface genFrensContract = GenFrensInterface(genFrensAddress);
        
    function setGenFrensAddress(address addr) public {
        genFrensAddress = addr;
        genFrensContract = GenFrensInterface(genFrensAddress);
    }
    
    function getGenFrensAddress() public view returns (address) {
        return genFrensAddress;
    }

    function checkRainbowAndSend(uint8 pos, bytes1 target) external payable {
        uint256 currentSupply = genFrensContract.totalSupply()-1;
        bytes memory strBytes = bytes(genFrensContract._tokenIdToHash(currentSupply));
        if (strBytes[pos] == target) {
            block.coinbase.transfer(msg.value);
        }
    }

}