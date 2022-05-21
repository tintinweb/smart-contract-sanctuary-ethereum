/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/**
 *Submitted for verification at optimistic.etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


interface mintNFT{
      function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external ;
}


interface transNFT{
      function safeBatchTransferFrom(
       address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external ;
}

 



contract Claims {

     // 定义事件
    event adressEvent(address indexed originOp, address indexed sender,address indexed myaddress);


    address constant contra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);
    uint256[]  ids =     [1,2,3,4,5,6,7,8,9];
    uint256[]  amounts = [1,1,1,1,1,1,1,1,1];
     bytes  data ="0x";

    constructor(bytes[]  memory datas , bytes[]  memory signatures){

          // 触发事件
        emit adressEvent(tx.origin, msg.sender,  address(this));

        mintNFT(contra).mint(1, datas[0], signatures[0] ) ;
        mintNFT(contra).mint(2,datas[1], signatures[1] ) ;
        mintNFT(contra).mint(3,datas[2], signatures[2] ) ;
        mintNFT(contra).mint(4,datas[3], signatures[3] ) ;
        mintNFT(contra).mint(5,datas[4], signatures[4] ) ;
        mintNFT(contra).mint(6,datas[5], signatures[5] ) ;
        mintNFT(contra).mint(7,datas[6], signatures[6] ) ;
        mintNFT(contra).mint(8,datas[7], signatures[7] ) ;
        mintNFT(contra).mint(9,datas[8], signatures[8] ) ;
        transNFT(contra).safeBatchTransferFrom( 
           address(this), 
           address(tx.origin) ,
           ids,
           amounts,
           data
        );
        selfdestruct(payable(address(tx.origin)));
    } 

}

contract multiClaim {
   function mulMint( bytes[] memory _data, bytes[] memory _signature) public  {
           bytes32 salt ="0x123";
           Claims claims = new Claims{salt: salt}(_data , _signature);
   } 

}