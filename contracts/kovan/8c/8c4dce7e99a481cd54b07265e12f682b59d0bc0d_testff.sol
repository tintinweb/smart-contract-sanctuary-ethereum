/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function liquidateList(uint start,uint end)public pure returns(string memory){
        string memory reLiqui;
        for (uint i=start; i<=end; i++){
            reLiqui = string(abi.encodePacked(reLiqui,","));
            reLiqui = string(abi.encodePacked(reLiqui,uint2str(i)));
        }
        return reLiqui;
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}