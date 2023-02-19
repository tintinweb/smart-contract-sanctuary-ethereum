// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Freeze {
    
    mapping(address => Lock[]) private locks;

    struct Lock {
        uint256 amount;
        uint unlockTime;
        bool withdrawn;
    }

    event Withdrawal(address sender, uint amount, uint when);
    event FreezeETH(address sender, uint amount, uint unlockTime);

    constructor() {}

   function freeze(uint unlockTime) public payable {
        require(msg.value > 0, "You must send some ether");
        require(
            block.timestamp < unlockTime,
            "You must set a future unlock time"
        );

        emit FreezeETH(msg.sender, msg.value, unlockTime);

        locks[msg.sender].push(Lock(msg.value, unlockTime, false));
    }

    function withdraw() public {
        uint256 total = 0;
        for (uint i = 0; i < locks[msg.sender].length; i++) {
            Lock memory lock = locks[msg.sender][i];
            if (block.timestamp >= lock.unlockTime && !lock.withdrawn) {
                total += lock.amount;
                locks[msg.sender][i].withdrawn = true;
            }
        }

        require(total > 0, "You can't withdraw yet");

        emit Withdrawal(msg.sender,total, block.timestamp);

        address payable sender = payable(msg.sender);

        sender.transfer(total);
    }

    function getLocks(address user, uint i) public view returns (uint256, uint, bool) {
        return (locks[user][i].amount, locks[user][i].unlockTime, locks[user][i].withdrawn);
    }
}