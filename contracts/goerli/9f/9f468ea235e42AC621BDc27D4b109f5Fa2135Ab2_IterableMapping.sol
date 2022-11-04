// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Models.sol";

library IterableMapping {
  struct ListingsMap {
    uint[] keys;
    mapping(uint => Models.ListingInfo) values;
    mapping(uint => uint) indexOf;
    mapping(uint => bool) inserted;
    Models.ListingInfo[] listingValues;
  }

  function contains(ListingsMap storage map, uint key) public view returns(bool) {
    return map.inserted[key];
  }

  function get(ListingsMap storage map, uint key) public view returns (Models.ListingInfo memory) {
      return map.values[key];
  }

  function getKeyAtIndex(ListingsMap storage map, uint index) public view returns (uint) {
      return map.keys[index];
  }

  function size(ListingsMap storage map) public view returns (uint) {
      return map.keys.length;
  }

  function getlistingValues(ListingsMap storage map) public view returns (Models.ListingInfo[] memory) {
    return map.listingValues;
  }

  function set(
    ListingsMap storage map,
    uint key,
    Models.ListingInfo memory val
  ) public {
    if (map.inserted[key]) {
        map.values[key] = val;
        map.listingValues[map.indexOf[key]] = val;
    } else {
        map.inserted[key] = true;
        map.values[key] = val;
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
        map.listingValues.push(val);
    }
  }

  function remove(ListingsMap storage map, uint key) public {
    if (!map.inserted[key]) {
        return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    uint lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
    map.listingValues[index] = map.listingValues[lastIndex];
    map.listingValues.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Models {
  struct ListingInfo {
    uint256 listingId;
    address listingAddr;
    address player1;
    address token1;
    uint256 token1Amt;
    address player2;
    address token2;
    uint256 token2Amt;

    bool fulfilled;
  }

  // Additionally, we want to keep a record of all player's movements on chain.
  // That is, we want to record everytime a player bets (buys a position), or sells his position (and to who), or withdraws his winnings
  struct Activity {
    // Common fields
    uint256 trxId;
    string activityType;  // "BET", "SELL", "WITHDRAW"
    uint256 gameId;
    uint256 trxAmt;
    uint256 trxTime; // when the trx was initiated
    uint8 gameSide; // 1 - YES, 2 - NO
    address from;
    address to;
  }

  struct GameMetadata {
    uint256 id;
    uint256 createdTime;
    address addr;
    string tag;
    string title;
    address oracleAddr;
    uint256 resolveTime;
    int256 threshold;

    uint256 totalAmount;
    uint256 betYesAmount;
    uint256 betNoAmount;
    uint8 gameOutcome;
  }

  struct AllGames {
    address[] ongoingGames;
    address[] closedGames;
  }

  struct TokenInfo {
    address tokenAddr;
    uint8 betSide;

    uint256 gameId;
    address gameAddr;
    string gameTag;
    string gameTitle;
    address gameOracleAddr;
    uint256 gameResolveTime;
    int256 gameThreshold;
  }

  // for every record, we track a list of transactions
  struct Trx {
    // Common fields
    uint256 trxId;
    string activityType;  // "BET", "SELL"
    uint256 trxAmt;
    uint256 trxTime; // when the trx was initiated
    uint8 gameSide;

    // if BET, from = game contract addr, to = player addr
    // if SELL, from = seller addr, to = buyer addr
    address from;
    address to;
  }
}