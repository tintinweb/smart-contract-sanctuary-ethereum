// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISBVHook } from "../SBVHook/ISBVHook.sol";
import { MetaModifiers } from "../Meta/MetaModifiers.sol";
import { TreasuryStorage } from "../Treasury/TreasuryStorage.sol";
import { TreasuryGetters } from "../Treasury/TreasuryGetters.sol";

contract SBVHookFacet is ISBVHook, MetaModifiers, TreasuryGetters {
  using TreasuryStorage for TreasuryStorage.State;

  function SBV_hook(uint id, address newOwner, bool mint) external ifIsSBV {
    TreasuryStorage.state().villageOwner[id] = newOwner;
    if (mint == true) { TreasuryStorage.state().villageAmount++; }
    emit VillageInfoUpdated(id, newOwner, _villageAmount());
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISBVHook {
  
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin, MetaStorage } from "./MetaStorage.sol";

abstract contract MetaModifiers {
  using MetaStorage for MetaStorage.State;
  
  function isVaildPool(Pool pool) internal view virtual returns(bool) {
    return pool != Pool.NONE ? true : false;
  }

  modifier ifIsVaildPool(Pool pool) {
    require(isVaildPool(pool), "MetaModifiers: This is not a valid pool");
    _;
  }

  function isValidCoin(Coin coin) internal view virtual returns(bool) {
    return coin != Coin.NONE ? true : false;
  }

  modifier ifIsValidCoin(Coin coin) {
    require(isValidCoin(coin), "MetaModifiers: This is not a valid coin");
    _;
  }

  function isCompatible(Pool p, Coin c) internal view virtual returns(bool) {
    return MetaStorage.state().compatible[p][c];
  }

  modifier ifIsCompatible(Pool p, Coin c) {
    require(isCompatible(p, c), "MetaModifiers: This token is incompatible with this pool");
    _;
  }

  function isSBV() internal view virtual returns(bool) {
    return MetaStorage.state().SBV == msg.sender;
  }

  modifier ifIsSBV {
    require(isSBV(), "MetaModifiers: can only be called by SBV");
    _;
  }

  function isSBT() internal view virtual returns(bool) {
    return MetaStorage.state().SBT == msg.sender;
  }

  modifier ifIsSBT {
    require(isSBT(),
      "MetaModifiers: can only be called by SBT");
    _;
  }

  function isSBD() internal view virtual returns(bool) {
    return address(this) == msg.sender;
  }

  modifier ifIsSBD {
    require(isSBD(), "MetaModifiers: can only be called by StableBattle");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

library TreasuryStorage {
  struct State {
    uint8 castleTax;
    uint lastBlock;
    uint rewardPerBlock;

    //Villages information
    uint256 villageAmount;
    mapping (uint256 => address) villageOwner;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Treasury.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { TreasuryStorage } from "../Treasury/TreasuryStorage.sol";

abstract contract TreasuryGetters {
  function _castleTax() internal view virtual returns(uint) {
    return TreasuryStorage.state().castleTax;
  }
  
  function _lastBlock() internal view virtual returns(uint) {
    return TreasuryStorage.state().lastBlock;
  }

  function _rewardPerBlock() internal view virtual returns(uint) {
    return TreasuryStorage.state().rewardPerBlock;
  }

  function _villageAmount() internal view virtual returns(uint256) {
    return TreasuryStorage.state().villageAmount;
  }

  function _villageOwner(uint256 villageId) internal view virtual returns(address) {
    return TreasuryStorage.state().villageOwner[villageId];
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Pool {
  NONE,
  AAVE,
  TEST
}

enum Coin {
  NONE,
  USDT,
  USDC,
  TEST
}

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address SBT;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Pool => mapping (Coin => bool)) compatible;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Meta.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}