/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256 total);
}
contract NFTsQuery {
    function query(address[] memory _subaddress, address _nftaddr) external view returns (uint256[][] memory) {
        uint256[][] memory tokenids = new uint256[][](_subaddress.length);

        // 获取初始总供应量并存储到本地变量中
        uint256 totalsupply = IERC721(_nftaddr).totalSupply();
        uint256 initialTotalsupply = totalsupply;

        // 循环查询代币所有者，并将代币ID存储到二维数组中
        for(uint256 i = 0; i < initialTotalsupply; i++){
            try IERC721(_nftaddr).ownerOf(i) returns (address owner){
                for(uint256 j = 0; j < _subaddress.length; j++){
                    if(_subaddress[j] == owner){
                        if(tokenids[j].length == 0){
                            tokenids[j] = new uint256[](IERC721(_nftaddr).balanceOf(owner));
                            tokenids[j][0] = i;
                        }else{
                            for (uint256 k = 0; k < tokenids[j].length; k++) {
                                if(tokenids[j][k] == 0){
                                    tokenids[j][k] = i;
                                    break;
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