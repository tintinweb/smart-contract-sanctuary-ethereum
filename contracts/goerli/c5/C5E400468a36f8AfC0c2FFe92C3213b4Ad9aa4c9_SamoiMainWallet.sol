// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract SamoiMainWallet {
    struct VerifyInfo {
        uint256 method;
        address target;
        address user;        
        uint256 tokenId;
        uint256 id;
        uint256 value;
    }

    function verifyUser(VerifyInfo memory verifyInfo) external view returns (bool) {
        if (verifyInfo.method == 0) {
            return 
                IERC721(verifyInfo.target).ownerOf(verifyInfo.tokenId) == verifyInfo.user;
        } 
        if (verifyInfo.method == 1) {
            return 
                IERC1155(verifyInfo.target).balanceOf(verifyInfo.user, verifyInfo.id) >= verifyInfo.value;
        }                                               
    }
}