// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Chance {
    function balanceOf(address, uint256) public view returns (uint256) {}

    function burn(
        address,
        uint256,
        uint256
    ) external {}
}

contract Redemption {
    address public owner;
    address public chanceAddress;
    Chance chance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this!");
        _;
    }

    function setContract(address _contract) public onlyOwner {
        chanceAddress = _contract;
        chance = Chance(chanceAddress);
    }

    modifier onlyOwnerWithTokens() {
        require(
            chance.balanceOf(msg.sender, 3) > 0,
            "Tokens: No tokens to be burnt"
        );
        _;
    }

    function redeem() public onlyOwnerWithTokens {
        uint256 balance = chance.balanceOf(msg.sender, 3);
        if (balance > 0) {
            chance.burn(msg.sender, 3, balance);
        }
    }

    function balanceOf(uint256 id) public view returns (uint256) {
        return chance.balanceOf(msg.sender, id);
    }

    function accountBalance(address account) public view returns (uint256) {
        return account.balance;
    }

    function generateRandom(
        uint256 seed,
        uint256 salt,
        uint256 sugar
    ) public view onlyOwner returns (uint8) {
        bytes32 bHash = blockhash(block.number - 1);
        uint8 randomNumber = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, bHash, seed, salt, sugar)
                )
            ) % 100
        );
        return randomNumber;
    }
}