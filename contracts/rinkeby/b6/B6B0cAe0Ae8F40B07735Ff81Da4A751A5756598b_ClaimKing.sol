// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClaimKing {
    address public kingAdddress;

    constructor(address king) payable {}

    function claimKing() public {
        (bool sent, ) = kingAdddress.call{value: address(this).balance}("");
        require(sent, "failed to claim the kingship");
    }

    function setKingAddress(address newKingAddress) external {
        kingAdddress = newKingAddress;
    }

    receive() external payable {
        claimKing();
    }
}