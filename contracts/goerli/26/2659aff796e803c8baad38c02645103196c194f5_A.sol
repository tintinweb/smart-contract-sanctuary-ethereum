/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;

contract A {

    function makeRepeat4(string memory _a) public pure returns(string memory) {
        bytes memory result = new bytes(4);
        for(uint i; i<4; i++){
            result[i]= bytes(_a)[0];
        }
        return string(result);
    }

    function decending(uint _a,uint _b, uint _c, uint _d) public pure returns(uint[4] memory){
        uint[4] memory result = [_a,_b,_c,_d];
        for(uint i; i<3; i++){
            for(uint j=i+1; j<4; j++){
                if(result[i] < result[j]){
                    uint temp = result[i];
                    result[i] = result[j];
                    result[j] = temp;
                }
            }
        }
        return result;
    }

    function yearToCentury(uint _year) public pure returns(uint){
        return _year / 100 + 1;
    }

    uint[] makeSeriesResult;
    function makeSeries(uint first, uint end, uint count) public returns(uint[] memory){
        makeSeriesResult = new uint[](0);
        makeSeriesResult.push(first);
        uint interval = (end - first) / (count - 1);
        for(uint i=1; i<count; i++){
            makeSeriesResult.push(makeSeriesResult[i-1] + interval);
        }
        return makeSeriesResult;
    }

    // uint[] primeFactorizationResult;
    // function primeFactorization(uint num) public returns(uint[] memory){
    //     primeFactorizationResult = new uint[](0);
    //     uint i = 2;
    //     uint temp = num;
    //     bool isGo = true;
    //     while(isGo){
    //         if(temp == 1){
    //             isGo = false;
    //         }else if(temp % i == 0){
    //             temp = temp / 2;
    //             primeFactorizationResult.push(i);
    //         }else {
    //             i++;
    //         }
    //     }
    //     return primeFactorizationResult;
    // }

}