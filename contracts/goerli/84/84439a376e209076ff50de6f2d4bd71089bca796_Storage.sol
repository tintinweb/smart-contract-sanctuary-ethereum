/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 tokenID;
    bytes32 f;


    mapping(int => bool) public testClaim;

    function calculate() public {
        testClaim[1] = true;
        testClaim[2] = true;
        
        //tokenID = ERC721Enumerable(0xB4E570232D3E55D2ee850047639DC74DA83C7067).tokenOfOwnerByIndex(0x57233d0dc42888addcae4288f63670a3f18fe35d, 0);
        tokenID = 1154;
        f =  keccak256(abi.encodePacked(0xB4E570232D3E55D2ee850047639DC74DA83C7067, tokenID));
    }

    function retrieveFF() public view returns (bytes32){   
        return f;
    }

    function getClaim() public view returns (bool){
        return testClaim[1];
    }
}