// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "./Constant.sol";
// import "./Constant2.sol";

contract Test {
    string private constant IFDFS = "dsfsdfsdsffds";

    string private boxIPFS;
    uint private openDate;
    uint private salesId;
    string private ipfs;

    constructor(uint _fee) {
        salesId = _fee;        
    }

    function mint(uint _salesId, string memory _ipfs) public {
        salesId = _salesId;
        ipfs = _ipfs; 
    }

    function getValues() public view returns (uint, string memory, string memory) {
        // string memory url = (openDate > block.timestamp)? '' : ipfs;

        return (
            salesId,
            ipfs,
            ipfs
        );
    }

    function gettttTTTwf() public pure returns (string memory) {
        return (
            IFDFS
        );
    }
}