/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface Temple {
    function chambers() external view returns (bytes20[] memory);

    function write(uint256 i, bytes32 data) external;
}

contract AvatarMoverV2 {
    Temple temple;

    constructor(address _templeAddress) {
        temple = Temple(_templeAddress);
    }

    function moveToMainHall() public {
        temple.write(1, bytes32(abi.encode(msg.sender)));
    }

    function moveToGarden(uint256 garden0, uint256 garden1) public {
        uint256 x = uint256(keccak256(abi.encode(garden0, 2)));
        temple.write(
            uint256(keccak256(abi.encode(garden1, x))),
            bytes32(abi.encode(msg.sender))
        );
    }

    function moveToChamber(uint256 chamberPos) public {
        uint256 chambersLen = temple.chambers().length;

        if (chambersLen < chamberPos + 1) {
            temple.write(3, bytes32(uint256(chamberPos + 1)));
        }

        temple.write(
            uint256(keccak256(abi.encode(chamberPos, 3))),
            bytes32(abi.encode(msg.sender))
        );
    }
}