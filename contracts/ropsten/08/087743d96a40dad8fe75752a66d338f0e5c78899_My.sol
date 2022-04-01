// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./IDataTypesPractice.sol";

contract My is IDataTypesPractice {


    function getInt256() external view returns(int256){
        int256 dnaDigits = 169;
        return dnaDigits;
     }

    function getUint256() external view returns(uint256){
        uint256 dnaDigits = 16;
        return dnaDigits;
    }


    function getIint8() external view returns(int8){
        int8 dnaDigits = 10;
        return dnaDigits;

    }
    function getUint8() external view returns(uint8){
        uint8 dnaDigits = 6;
        return dnaDigits;

    }
    function getBool() external view returns(bool){
        bool dnaDigits = true;
        return dnaDigits;

    }
    function getAddress() external view returns(address){
        address myAddress = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
        return myAddress;

    }
    function getString() external view returns(string memory){

        string memory dnaDigits = "Hello World!";

        return dnaDigits;

    }

    function getBytes32() external view returns(bytes32){
        bytes32 a = "HelloArmen";
        return a;

    }

    function getArrayUint() external view returns(uint256[] memory){
        uint256[] memory a = new uint[](1);
        a[0] = 8;

        return a;

    }


    function getArrayUint5() external view returns(uint256[5] memory){

        uint256[5] memory fixedArray;
        fixedArray[0]=2;
        fixedArray[1]=2;
        fixedArray[2]=2;
        fixedArray[3]=2;
        fixedArray[4]=2;


        return fixedArray;

    }

    function getBigUint() external pure returns(uint256){
        uint256 x=1;
        uint256 y=2;
        return y ** (y << (x*y + y));

    }

}