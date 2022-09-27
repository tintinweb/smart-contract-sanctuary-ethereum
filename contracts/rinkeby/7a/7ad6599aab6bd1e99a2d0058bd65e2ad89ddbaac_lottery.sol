/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.16;

contract lottery{

    uint256 public lastBlockNo;
    uint256 public myNo;
    address public myAddress;
    bytes32 public myByte32;
    
struct userInfo {

    uint lastBlockNo;
    uint myNo;
    address myAddress;
    bytes32 myByte32;

}
    mapping (address => userInfo) public userInfos;




    function myInfo(uint256 _myNo, address _myAddr, bytes32 _mybyte )public returns(bool){

        userInfo memory temp ;

       temp.lastBlockNo = block.number ;
       temp.myNo = _myNo ;
       temp.myAddress = _myAddr ;
       temp.myByte32 = _mybyte ;
       userInfos[msg.sender] = temp ; //it is not indexed array so i did this way
       return true ;
    }

     function getMyLuckyNo(address _user) public view returns (uint){
         userInfo memory temp = userInfos[_user];
         require(block.number > temp.lastBlockNo, "wait");
         bytes32 temphash = keccak256(abi.encode(temp.lastBlockNo, temp.myNo, temp.myAddress, temp.myByte32));
         uint luckyNo = uint256(temphash) % 100 ;
         return luckyNo;

     }  
     }