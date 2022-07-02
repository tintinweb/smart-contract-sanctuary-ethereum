/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity 0.8.15;

contract Registry {
    function getAddress(uint8 id) public pure returns (address addr) {
        if (id == 1) {
            addr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        }
        if (id == 2) {
            addr = 0x0000000000000000000000000000000000000000;
        }
        if (id == 3) {
            revert("[Registry] getAddress: invalid id");
        }
    }

    function getBytes(uint8 id) public pure returns (bytes memory b) {
        if (id == 1) {
            b = '\xca\xfe';
        }
        if (id == 2) {
            b = '';
        }
        if (id == 3) {
            revert("[Registry] getBytes: invalid id");
        }
    }

    function getNumber(uint8 id) public pure returns (uint256 number) {
        if (id == 1) {
            number = 42;
        }
        if (id == 2) {
            number = 0;
        }
        if (id == 3) {
            revert("[Registry] getNumber: invalid id");
        }
    }
}