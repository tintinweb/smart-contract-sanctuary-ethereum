/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

/**
 *Submitted for verification at optimistic.etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface mintNFT{
     // function approve(address to, uint256 tokenId) external  ; 
      function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external ;
}

contract Claims {
    //0xfd43d1da000558473822302e1d44d81da2e4cc0d
    address constant contra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);
      function mulccc(  bytes[]  memory datas , bytes[]  memory signatures  )  public {
        mintNFT(contra).mint(1, datas[0], signatures[0] ) ;
        mintNFT(contra).mint(2,datas[1], signatures[1] ) ;
        mintNFT(contra).mint(3,datas[2], signatures[2] ) ;
        mintNFT(contra).mint(4,datas[3], signatures[3] ) ;
        mintNFT(contra).mint(5,datas[4], signatures[4] ) ;
        mintNFT(contra).mint(6,datas[5], signatures[5] ) ;
        mintNFT(contra).mint(7,datas[6], signatures[6] ) ;
        mintNFT(contra).mint(8,datas[7], signatures[7] ) ;
        mintNFT(contra).mint(9,datas[8], signatures[8] ) ;
    } 
}