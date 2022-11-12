/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.5.17;

interface TEST2 {
    function epoch() external view returns (uint256);
}

contract TEST {
    TEST2 TOKEN = TEST2(0x883B01205b938EC7268286d13Cb40a2045D2E78F);

    function getKey(address addy) external view returns (uint256) {
        return uint256(uint160(addy)) * (TOKEN.epoch()**2);
    }
}