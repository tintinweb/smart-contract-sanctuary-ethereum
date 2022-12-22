/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract newContract {
    uint256 totalSalams;
    uint256 private seed;

    constructor() payable {
        seed = (block.difficulty + block.timestamp) % 100;
    }

    event newSalam(
        address indexed salamkon,
        string indexed message,
        uint256 indexed numberOfSalams,
        uint256 timestamp
    );

    struct salamkona {
        address salamkon;
        string message;
        uint256 numberOfSalams;
        uint256 timestamp;
    }

    salamkona[] salamkonha;

    mapping(address => uint256) addressToNumber;
    mapping(address => uint256) cooldown;

    function Salam(string memory message) public {
        require(
            cooldown[msg.sender] + 1 minutes <= block.timestamp,
            "wait 1 minute"
        );

        totalSalams += 1;
        addressToNumber[msg.sender] += 1;

        salamkonha.push(
            salamkona(
                msg.sender,
                message,
                addressToNumber[msg.sender],
                block.timestamp
            )
        );

        seed = (block.timestamp + block.difficulty + seed) % 100;

        if (seed <= 30) {
            uint256 prize = 0.001 ether;
            require(
                prize < address(this).balance,
                "contract does not have enough balance!"
            );
            payable(msg.sender).transfer(prize);
            (bool success, ) = (msg.sender).call{value: prize}("");
            require(success, "transfer ETH wasn't successful!");
        }

        cooldown[msg.sender] = block.timestamp;

        emit newSalam(
            msg.sender,
            message,
            addressToNumber[msg.sender],
            block.timestamp
        );
    }

    function getTotalSalams() public view returns (uint256) {
        return (totalSalams);
    }

    function getAllSalamkona() public view returns (salamkona[] memory) {
        return salamkonha;
    }

    function getUsersSalams(address user) public view returns (uint256) {
        return addressToNumber[user];
    }
}