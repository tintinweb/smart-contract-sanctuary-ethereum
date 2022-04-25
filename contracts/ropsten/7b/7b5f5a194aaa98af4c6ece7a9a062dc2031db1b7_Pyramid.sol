// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";

contract Pyramid is Ownable {
    event event_buy(address playerAddress, uint256 value);
    event event_withdraw(address playerAddress, uint256 value);

    constructor() {
        last_transaction_time = block.timestamp;
    }

    address[] all_player_address;
    uint256 last_transaction_time;

    mapping(address => uint256) address_balance;

    modifier ValidateValue(uint256 value) {
        require(value > 0, "Invalid value");
        _;
    }

    modifier ValidateTime() {
        if (block.timestamp > last_transaction_time + 1 days) {
            GameOver();
        } else {
            _;
        }
    }

    function Buy(address payable playerAddress, uint256 value)
        internal
        ValidateValue(value)
        ValidateTime
    {
        uint256 price = (value * 25) / 100;
        for (uint256 i = 0; i < all_player_address.length; i++) {
            address currentPlayer = all_player_address[i];
            address_balance[currentPlayer] +=
                ((value - price) * address_balance[currentPlayer]) /
                address(this).balance;
        }
        address_balance[playerAddress] += price;
        last_transaction_time = block.timestamp;

        emit event_buy(playerAddress, value);
    }

    function GetBalance() external view returns (uint256) {
        return address_balance[msg.sender];
    }

    function CheckRemainingTime() external view returns (uint256) {
        return (last_transaction_time + 1 days - block.timestamp) / 60;
    }

    function Withdraw() external {
        address payable player = payable(msg.sender);
        uint256 balance = address_balance[player];
        require(balance > 0, "Insufficient balance");
        player.transfer(balance);
        address_balance[player] = 0;

        emit event_withdraw(player, balance);
    }

    function GameOver() internal {
        for (uint256 i = 0; i < all_player_address.length; i++) {
            address payable currentPlayer = payable(all_player_address[i]);
            currentPlayer.transfer(address_balance[currentPlayer]);
        }
        last_transaction_time = block.timestamp;
    }

    receive() external payable {
        address payable playerAddress = payable(msg.sender);

        if (address_balance[playerAddress] == 0) {
            all_player_address.push(playerAddress);
        }
        Buy(playerAddress, msg.value);
    }

    function Destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}