/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity = 0.4.25;
contract EncodePackedExample {
    function example() external pure returns (bytes memory) {
        bytes32 x = 0x5600a165627a7a72305820123123123123123123123123123123123123123122;
        bytes8 z = 0x11231231230029;
        return abi.encodePacked(x, z);
    }
}