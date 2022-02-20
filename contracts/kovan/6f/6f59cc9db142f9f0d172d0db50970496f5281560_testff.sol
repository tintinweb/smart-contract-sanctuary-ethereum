/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract testff{
    struct af{
        string aa;
        uint bb;
        uint cc;
        uint dd;
    }

    mapping(uint=>af) testF;
    function test2(uint ama,uint amb) external{
        for (uint i=ama; i<=amb; i++){
            testF[i].aa = "aaaa";
            testF[i].bb = block.timestamp;
            testF[i].cc = block.timestamp;
            testF[i].dd = i;
        }
    }

    function test3(uint am,uint ab)external view returns(uint){
        uint ac = 1;
        for (uint i=0; i<=am; i++) {
            if (testF[i].dd == ab) {
                ac = 123456;
            }
        }
        return ac;
    }
    

    function testaa(uint amm) external view returns(string memory){
        return testF[amm].aa;
    }

    function testbb(uint amm) external view returns(uint){
        return testF[amm].bb;
    }

    function testcc(uint amm) external view returns(uint){
        return testF[amm].cc;
    }

    function testdd(uint amm) external view returns(uint){
        return testF[amm].dd;
    }
}