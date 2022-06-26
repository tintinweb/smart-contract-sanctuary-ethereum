/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

contract test1 {
    uint256 a;
    bool b;
    string c;
    uint d;

    function seta(uint _a) public {
        a = _a;
    }

    function setb(bool _b) external {
        b = _b;
    }

    function setc(string memory _c) private {
        c = _c;
    }

    function readabc() private returns(uint) {
        d = uint(keccak256(abi.encodePacked(a, b, c)));
        return d;
    }

    function setalltogetherabc(uint _a, string memory _c255) private {
        seta(_a);
        setc(_c255);        
    }

}