/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TokenURICustom {

    address public constant mainContract = 0x0e847aAd9B5b25CEa58613851199484BE3C4Fa13;
    uint256 public constant selectedId = 1;

    string public constant uri_1 = "ipfs://QmfADNamguQa9b6bh1gWeT2QCK3ZjJzCVe39XnNSqz6dXG";
    string public constant uri_2 = "ipfs://QmWFhnubQxpuuxunigKSAXFFDJ7d61KygtDbfBYzzHWigq";

    uint256 public activeView = 1;

    function changeView() public {
        address owner = IERC721(mainContract).ownerOf(selectedId);
        require(msg.sender == owner, "Not the owner");
        if (activeView == 1) {
            activeView++;
        }
        else {
            activeView--;
        }
    }

    function constructTokenURI(uint256 tokenId) external view returns (string memory) {
        require(tokenId == selectedId, "Wrong Id");

        if (activeView == 1) {
            return uri_1;
        }
        else {
            return uri_2;
        }
            
    }

}