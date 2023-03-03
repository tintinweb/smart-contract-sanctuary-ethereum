/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256 total);
}

contract NFquea {
    function query(address[] memory _subaddress, address _nftaddr) external view returns (address[] memory, uint256[][] memory) {
        address[] memory subaddress = new address[](_subaddress.length);
        uint256[][] memory tokenids = new uint256[][](_subaddress.length);
        uint256 totalsupply = IERC721(_nftaddr).totalSupply();
        // 查询地址下最后一个nft的tokenid
        for (uint256 i = 0; i < totalsupply; i++) {
            try IERC721(_nftaddr).ownerOf(i) returns (address owner){
                for (uint256 j = 0; j < _subaddress.length; j++) {
                    if (_subaddress[j] == owner) {
                        if (tokenids[j].length == 0) {
                            tokenids[j] = new uint256[](IERC721(_nftaddr).balanceOf(owner));
                        }
                        tokenids[j][tokenids[j].length-1] = i;
                        if (i == totalsupply - 1) {
                            subaddress[j] = owner;
                        }
                    }
                }
            } catch {
                continue;
            }
        }

        require(subaddress.length == tokenids.length, "#1 length not match");
        uint256 len;
        for (uint256 i = 0; i < subaddress.length; i++) {
            if(subaddress[i] != address(0)){
                len++;
            }
        }
        address[] memory newsubaddress = new address[](len);
        uint256[][] memory newtokenids = new uint256[][](len);
        uint256 index;
        for (uint256 i = 0; i < subaddress.length; i++) {
            if(subaddress[i] != address(0)){
                newsubaddress[index] = subaddress[i];
                newtokenids[index] = tokenids[i];
                index++;
            }
        }
        return (newsubaddress, newtokenids);
    }
}