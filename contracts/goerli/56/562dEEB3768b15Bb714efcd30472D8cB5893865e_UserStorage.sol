// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PlayerData} from "../types/Structs.sol";

contract UserStorage {
    mapping(address => PlayerData) private s_userMapStorage;
    address[] private s_raffleEntered;

    function set(address _userAddress, PlayerData calldata _user) external {
        s_userMapStorage[_userAddress] = _user;
    }

    function set(address _raffleAddress) external {
        s_raffleEntered.push(_raffleAddress);
    }

    function get(address _userAddress) external view returns (PlayerData memory) {
        return s_userMapStorage[_userAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {RaffleState} from "./Enums.sol";

struct RaffleData {
    uint256 id;
    uint256 entryPrice;
    uint256[] winningNumbers;
    // address[] players;
    address[] winners;
    RaffleState state;
    PlayerData[] players;
}

struct PlayerData {
    address playerAddress;
    address[] enteredRaffles;
    address[] wonRaffles;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum RaffleState {
    NotAvailable,
    Created,
    Open,
    Drawing,
    Complete,
    Closed,
    Cancelled
}