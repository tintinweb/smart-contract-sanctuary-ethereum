//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract ExampleNFT {

    uint256 VALUE;
    address owner;

    constructor(
        uint256 _MINTvalue,
        address _owner
    ) {
        VALUE = _MINTvalue;
        owner = _owner;
    }


    function mint(uint256 amount) 
        external
        pure
        returns (string memory)
    {
        return "testing return";
    }
}