/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity 0.8.16;

contract lottery{

    uint256 public lastBlockNo;
    uint256 public myNo;
    address public myAddress;
    bytes32 public myByte32;

    mapping (address => uint256) public rewardamount;




    function myInfo(uint256 _myNo, address _myAddr, bytes32 _mybyte )public returns(bool){
       
        lastBlockNo = block.number;
        myNo = _myNo ;
        myAddress = _myAddr;
        myByte32 = _mybyte;
        return true ;
    }

     function getMyLuckyNo() public view returns (uint){
         require(block.number > lastBlockNo, "wait");
         bytes32 temphash = keccak256(abi.encode(lastBlockNo, myNo, myAddress, myByte32));
         uint luckyNo = uint256(temphash) % 100 ;
         return luckyNo;

     }  
     }