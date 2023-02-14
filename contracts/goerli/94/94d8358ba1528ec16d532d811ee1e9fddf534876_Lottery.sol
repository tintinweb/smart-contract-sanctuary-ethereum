/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity ^0.8.17;


// SPDX-License-Identifier: MIT
contract Lottery {
    address payable[] public Users;
    uint256 public players;
    mapping(address => bool) public registered;
    address public lotteryOwner;
    address payable winner;

    constructor() {
        lotteryOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == lotteryOwner);
        _;
    }

    function register() public payable {
        require(
            lotteryOwner != msg.sender,
            "Owner can not registered for the lottery"
        );
        require(players < 3, "Insufficient seats available");
        require(registered[msg.sender] != true, "Already Regisrtered");
        require(msg.value == 1 ether, "Insufficent balance");
        players += 1;
        registered[msg.sender] = true;
        Users.push(payable(msg.sender));
    }

    function getAmount() public view returns (uint256) {
        require(msg.sender == lotteryOwner, "Can not call by users");
        return address(this).balance;
    }

    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        Users.length
                    )
                )
            );
    }

    function winnerDeclaration() public onlyOwner {
        require(getAmount() == 0, "Insuffcient balance");
        require(Users.length == 3, "Registration is in process");
        uint256 r = random();
        uint256 index = r % Users.length;
        winner = Users[index];
        winner.transfer(getAmount());
        Users = new address payable[](0);
    }
}