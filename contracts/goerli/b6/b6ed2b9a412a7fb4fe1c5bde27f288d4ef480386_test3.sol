// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "./Icontract2.sol";

contract test3 {

    uint public sha;
    uint public ab;
    string public teststring;
    bytes32 public testbytes;
    uint32 public testuint32;
    address test2 = 0x1E023285574FFeFfc3304964aad31225f85e6880;

    Itest2 previuse = Itest2(test2);

    function doall(string memory _z11, uint _y22, uint _x33) external returns (uint) {
        previuse.setb(_x33);
        previuse.setalltogetherabc(_y22, _z11);
        return sha = previuse.aaa(_z11);
    }

    function add(string memory _abc) external {
        uint aaa = previuse.aaa(_abc); 
        uint a = previuse.a();
        bool b = previuse.readb();
        ab = uint(keccak256(abi.encodePacked(a, b)));
        testbytes = keccak256(abi.encodePacked(aaa));
    }

    function readaddress() external view returns (address) {
        return test2;
    }

}