// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.0;

contract NFTList {

//    function NFTList(){
//
//    }

    struct tokenInfo{
        uint256 price;
        string name;
        address nftAddress; 
    }
    tokenInfo[] internal nftList;

    function allNFT() public view returns(tokenInfo[] memory){
    return nftList;
}
    function addNFT(uint256 price, string memory name, address newNft) public returns(bool){
        
        tokenInfo memory newToken = tokenInfo(price, name, newNft);
        nftList.push(newToken);
        return true;


}

}