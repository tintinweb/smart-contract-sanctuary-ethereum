/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity = 0.4.25;
contract EncodePackedExample {
    function example() external pure returns (bytes memory) {
        bytes32 x = 0x5600a165627a7a7230582012312312312312312312312312312312312312312;
        bytes8 z = 0x1112312312310029;
        return abi.encodePacked(x, z);
    }
}