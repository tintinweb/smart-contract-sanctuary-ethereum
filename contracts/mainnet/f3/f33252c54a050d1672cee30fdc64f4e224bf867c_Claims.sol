/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/**
 *Submitted for verification at optimistic.etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// interface mintNFT{
   
//       function mint(
//         uint256 _category,
//         bytes memory _data,
//         bytes memory _signature
//     ) external ;
// }

contract Claims {
     //address constant nftContra = address(0xA0BB4c422D003C517D18cAB8cDaA87B03982Ab43);//测试网
     
     address constant nftContra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);//主网合约

    // 定义事件
    event mintEvent(address indexed sender, bool indexed success,bytes indexed data);

    // function three_call(address addr) public {
    //         //addr.call(bytes4(keccak256("test()")));                 // 情况1 msg.sender= 合约B调用地址
    //         addr.delegatecall(bytes4(keccak256("test()")));       // 情况2  msg.sender= 钱包调用地址
    //        // addr.callcode(bytes4(keccak256("test()")));           // 情况3   msg.sender= 合约A地址
    // } 


     function singleMint( uint256 _category,bytes memory _data,
                       bytes memory _signature) public  {
        (bool success, bytes memory data) = nftContra.delegatecall(
             abi.encodeWithSignature("mint(uint256,bytes,bytes)", _category, _data, _signature)
        );
        // 触发事件
        emit mintEvent(msg.sender, success,data);
    }





    function mulMint( bytes[] memory _data, bytes[] memory _signature) public  {


        for (uint256 i = 0; i < _data.length; i++) {
            (bool success, bytes memory data) = nftContra.delegatecall(
             abi.encodeWithSignature("mint(uint256,bytes,bytes)", i+1, _data[i], _signature[i])
            );
              // 触发事件
            // emit mintEvent(msg.sender, success,data);
        }
       
       
    }


    // address constant contra = address(0xFD43D1dA000558473822302e1d44D81dA2e4cC0d);
    //   function mulccc(  bytes[]  memory datas , bytes[]  memory signatures  )  public {
    //     mintNFT(contra).mint(1, datas[0], signatures[0] ) ;
    //     mintNFT(contra).mint(2,datas[1], signatures[1] ) ;
    //     mintNFT(contra).mint(3,datas[2], signatures[2] ) ;
    //     mintNFT(contra).mint(4,datas[3], signatures[3] ) ;
    //     mintNFT(contra).mint(5,datas[4], signatures[4] ) ;
    //     mintNFT(contra).mint(6,datas[5], signatures[5] ) ;
    //     mintNFT(contra).mint(7,datas[6], signatures[6] ) ;
    //     mintNFT(contra).mint(8,datas[7], signatures[7] ) ;
    //     mintNFT(contra).mint(9,datas[8], signatures[8] ) ;
    // } 



}