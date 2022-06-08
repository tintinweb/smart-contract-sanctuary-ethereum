pragma solidity ^0.5.15;

library TestLibrary {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }

    function libID() pure external returns (string memory) {
        return "0x28Ff8cD963F6193dAFCabD0f199d246C71cb68C8";
    }
}