/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.8.12;

interface IERC721{
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract bulkTokenURIReader {

    function read(uint256 start, uint256 end, address collection) external view returns (string[] memory) {
        IERC721 token = IERC721(collection);
        string[] memory returnData = new string[] (end-start+1);
        for (uint i = start; i<=end; i++) {
                try token.tokenURI(i) returns (string memory tokenURI) {
                    returnData[i]=string.concat(tokenURI);
                } catch {
                    returnData[i]=string.concat("null");               
                }

            }
        return returnData;
    }

 
}