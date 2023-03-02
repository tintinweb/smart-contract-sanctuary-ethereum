/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256 total);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


contract NFTsQuery {
    function query(address[] memory _subaddress, address _nftaddr) external view returns (uint256[][] memory) {
        require(_subaddress.length > 0, "Address array cannot be empty");
        require(_nftaddr != address(0), "NFT contract address cannot be empty");

        uint256[][] memory tokenids = new uint256[][](_subaddress.length);

        uint256 totalsupply = IERC721(_nftaddr).totalSupply();

        for(uint256 i = 0; i < totalsupply; i++){
            try IERC721(_nftaddr).ownerOf(i) returns (address owner){
                for(uint256 j = 0; j < _subaddress.length; j++){
                    if(_subaddress[j] == owner){
                        uint256 balance = IERC721(_nftaddr).balanceOf(owner);
                        if(balance > 0){
                            if(tokenids[j].length == 0){
                                tokenids[j] = new uint256[](balance);
                                tokenids[j][0] = i;
                            }else{
                                for (uint256 k = 0; k < balance; k++) {
                                    tokenids[j][k] = IERC721(_nftaddr).tokenOfOwnerByIndex(owner, k);
                                }
                            }
                        }
                    }
                }
            }catch{
                continue;
            }
        }

        return tokenids;
    }
}