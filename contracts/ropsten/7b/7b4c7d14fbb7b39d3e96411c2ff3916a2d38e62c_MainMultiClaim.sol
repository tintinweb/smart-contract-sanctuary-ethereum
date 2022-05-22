/**
 *Submitted for verification at Etherscan.io on 2022-05-22
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


    uint public countNumber ;
     address public nowAdr;

       uint256[] public ids =     [1,2,3,4,5,6,7,8,9];
        uint256[]  public amounts = [1,1,1,1,1,1,1,1,1];
        bytes public  data ="0x";
  

   // address constant contra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);
    // uint256[]  ids =     [1,2,3,4,5,6,7,8,9];
    // uint256[]  amounts = [1,1,1,1,1,1,1,1,1];
    //  bytes  data ="0x";

    // constructor(bytes[]  memory datas , bytes[]  memory signatures){

    //       // 触发事件
    //     emit adressEvent(tx.origin, msg.sender,  address(this));


    //     MultiClaim.getDatas()


    //     mintNFT(contra).mint(1, datas[0], signatures[0] ) ;
    //     mintNFT(contra).mint(2,datas[1], signatures[1] ) ;
    //     mintNFT(contra).mint(3,datas[2], signatures[2] ) ;
    //     mintNFT(contra).mint(4,datas[3], signatures[3] ) ;
    //     mintNFT(contra).mint(5,datas[4], signatures[4] ) ;
    //     mintNFT(contra).mint(6,datas[5], signatures[5] ) ;
    //     mintNFT(contra).mint(7,datas[6], signatures[6] ) ;
    //     mintNFT(contra).mint(8,datas[7], signatures[7] ) ;
    //     mintNFT(contra).mint(9,datas[8], signatures[8] ) ;
    //     transNFT(contra).safeBatchTransferFrom( 
    //        address(this), 
    //        address(tx.origin) ,
    //        ids,
    //        amounts,
    //        data
    //     );
    //     selfdestruct(payable(address(tx.origin)));
    // } 

    constructor(uint num){
          // 触发事件
        emit adressEvent(tx.origin, msg.sender,  address(this));
        countNumber = num ;
        nowAdr = address(this);
    } 


   function doMint(address  contra ,bytes[] memory datas, bytes[] memory signatures) public  {
      
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

contract MainMultiClaim {
     //状态变量
    //  mapping(uint => bytes) public datas;
    //  mapping(uint => bytes) public signatures;
    address constant contra = address(0xA0BB4c422D003C517D18cAB8cDaA87B03982Ab43);
  //  address constant nftContra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);//主网合约
  // address constant nftContra = address(0xA0BB4c422D003C517D18cAB8cDaA87B03982Ab43);//测试网

    // pure:不能读取也不能改变状态变量
    // function pureName(uint tokenNumber) public pure returns(bytes){
    //   return datas[tokenNumber];
    // }

    // function getSignatures(uint tokenNumber) public view returns (bytes) {
    //     return signatures[tokenNumber];
    // }

     address public nowAdr;
     address public prenowAdr;

   function mulMint(uint countNumber,  bytes[] memory _data, bytes[] memory _signature) public  {
           bytes32 salt ="0x123";
           Claims claims = new Claims{salt: salt}(countNumber);
           claims.doMint(  contra , _data,  _signature) ;
   } 



   function testCreateDSalted(bytes32 salt, uint arg) public {
        /// 这个复杂的表达式只是告诉我们，如何预先计算地址。
        /// 这里仅仅用来说明。
        /// 实际上，你仅仅需要 ``new D{salt: salt}(arg)``.
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(Claims).creationCode,
                arg
            ))
        )))));

        Claims d = new Claims{salt: salt}(arg);
        nowAdr = address(d);
        prenowAdr = predictedAddress;
        //require(address(d) == predictedAddress);
    }


       function createDSalted(bytes32 salt, uint arg) public {
        nowAdr = address(0);
        prenowAdr = address(0);
        /// 这个复杂的表达式只是告诉我们，如何预先计算地址。
        /// 这里仅仅用来说明。
        /// 实际上，你仅仅需要 ``new D{salt: salt}(arg)``.
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(Claims).creationCode,
                arg
            ))
        )))));

        // Claims d = new Claims{salt: salt}(arg);
        // nowAdr = address(d);
        prenowAdr = predictedAddress;
        //require(address(d) == predictedAddress);
    }

}