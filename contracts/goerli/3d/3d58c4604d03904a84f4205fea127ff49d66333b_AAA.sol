/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract AAA {
    function a1(string memory _a) public view returns(string memory){
        bytes memory bb = new bytes(4);
        for(uint i=0; i<4; i++) {
            bb[i] = bytes(_a)[0];
        }

        return string(bb);
    }
    uint[] list;
    function a2(uint a,uint b, uint c, uint d) public returns(uint[] memory){
        list.push(a);
        list.push(b);
        list.push(c);
        list.push(d);
        for(uint i=0;i<3;i++){
            for(uint j =i+1;j<4;j++){
                if(list[i] < list[j]){
                    uint temp = list[i];
                    list[i] = list[j];
                    list[j] = temp;
                }
                
            }
        }

        return list;
        
    }
    // uint[] list1;
    // function a5(uint a) public returns(uint[] memory){
    //     for(uint i=2;i<10;i++){
    //         uint temp=0;
    //         for(uint j=2;j<i+1;j++){
    //             if(i%j == 0){
    //                 temp++;
    //             }
    //         }
    //         if(temp==1){
    //             list1.push(i);
    //         }
    //     }
 

    //     return list1;
    // }
}