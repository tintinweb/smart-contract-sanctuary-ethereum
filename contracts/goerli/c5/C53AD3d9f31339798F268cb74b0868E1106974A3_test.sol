// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract test {
function isEqual(string memory a) public pure returns (bool) {
        string memory c = "0D3EF99960272E1EDACE13B4E346CA5C";
        bytes memory bb = bytes(c);
        bytes memory aa = bytes(a);
        // 如果长度不等，直接返回
        if (aa.length != bb.length) return false;
        // 按位比较
        for(uint i = 0; i < aa.length; i ++) {
            if(aa[i] != bb[i]) return false;
        }
        return true;
}
}