// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


//纯日志输出函数
contract LogLib {
   
    event debugstr(string msg,address addr,address user,string exec,uint256 num);
    event debugnum(string msg,address addr,address user,uint256 exec,uint256 num);

    //字符串日志
    function LogStr (string memory value,string memory exec,uint256 num )  public {
        emit debugstr(value, tx.origin,address(msg.sender),exec,num);
    }

    //数字日志
    function LogNum (string memory value,uint256 exec,uint256 num )  public {
        emit debugnum(value, tx.origin,address(msg.sender),exec,num);
    }

    function hashAddressNTokenId(address addr, uint tokenId) public pure returns (uint){
        return uint(keccak256(abi.encodePacked(addr, tokenId)));
    }

}


/*

interface Transfer is LogLib {
    function LogStr(string memory value,string memory exec,uint256 num) public;
    function LogNum (string memory value,uint256 exec,uint256 num )  public ;
    function hashAddressNTokenId(address addr, uint tokenId) public pure returns (uint);
}

*/