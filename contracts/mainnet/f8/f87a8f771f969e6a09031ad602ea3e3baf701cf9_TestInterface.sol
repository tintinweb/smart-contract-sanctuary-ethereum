/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRayRay {
  function ownerOf(uint256 tokenId) external returns (address);
  function balanceOf(address owner) external returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
}

contract TestInterface {

    address public RAY_RAYS_CONTRACT = 0x8d4E2435c262eB6df10E5e4672A8f07E42D8d67e;

    function ownerOfRayRay(uint256 id) external returns (address) {
        return IRayRay(RAY_RAYS_CONTRACT).ownerOf(id);
    }

    function rayRayBalance(address _a) external returns (uint256) {
        return IRayRay(RAY_RAYS_CONTRACT).balanceOf(_a);
    }

    function walletOfOwner(address _a) external returns (uint256[] memory) {
        IRayRay rr = IRayRay(RAY_RAYS_CONTRACT);
        uint256 tokenCount = rr.balanceOf(_a);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = rr.tokenOfOwnerByIndex(_a, i);
        }

        return tokensId;
    }

}