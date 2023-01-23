// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISBVHook {
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISBVHook } from "../SBVHook/ISBVHook.sol";
import { MetaModifiers } from "../../Meta/MetaModifiers.sol";
import { TreasuryStorage } from "../Treasury/TreasuryStorage.sol";
import { TreasuryGetters } from "../Treasury/TreasuryGetters.sol";

contract SBVHookFacet is ISBVHook, MetaModifiers, TreasuryGetters {
  function SBV_hook(uint id, address newOwner, bool mint) external ifIsSBV {
    TreasuryStorage.state().villageOwner[id] = newOwner;
    if (mint == true) { TreasuryStorage.state().villageAmount++; }
    emit VillageInfoUpdated(id, newOwner, _villageAmount());
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITreasuryEvents {
  event BeneficiaryUpdated(uint village, address beneficiary);
  event NewTaxSet(uint tax);
}

interface ITreasuryErrors {
  error TreasuryModifiers_OnlyCallableByCastleHolder();
  error TreasuryFacet_CantSetTaxAboveThreshold(uint8 threshold);
}

interface ITreasuryGetters {
  function getCastleTax() external view returns(uint);
  function getLastBlock() external view returns(uint);
  function getRewardPerBlock() external view returns(uint);
}

interface ITreasury is ITreasuryEvents, ITreasuryErrors, ITreasuryGetters {
  function claimRewards() external;
  function setTax(uint8 tax) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { TreasuryStorage } from "../Treasury/TreasuryStorage.sol";
import { ITreasuryGetters } from "../Treasury/ITreasury.sol";

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

abstract contract TreasuryGettersExternal is ITreasuryGetters, TreasuryGetters {
  function getCastleTax() public view returns(uint) {
    return _castleTax();
  }

  function getLastBlock() public view returns(uint) {
    return _lastBlock();
  }

  function getRewardPerBlock() public view returns(uint) {
    return _rewardPerBlock();
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

enum Pool { NONE, TEST, AAVE }

enum Coin { NONE, TEST, USDT, USDC, EURS }

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

enum gearSlot { NONE, WEAPON, SHIELD, HELMET, ARMOR, PANTS, SLEEVES, GLOVES, BOOTS, JEWELRY, CLOAK }

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

enum Role { NONE, ADMIN }

enum ClanRole { NONE, PRIVATE, MOD, ADMIN, OWNER }

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";
import { MetaStorage } from "../Meta/MetaStorage.sol";

abstract contract MetaModifiers {
  error InvalidPool(Pool pool);
  
  function isVaildPool(Pool pool) internal view virtual returns(bool) {
    return pool != Pool.NONE ? true : false;
  }

  modifier ifIsVaildPool(Pool pool) {
    if (!isVaildPool(pool)) {
      revert InvalidPool(pool);
    }
    _;
  }

  error InvalidCoin(Coin coin);

  function isValidCoin(Coin coin) internal view virtual returns(bool) {
    return coin != Coin.NONE ? true : false;
  }

  modifier ifIsValidCoin(Coin coin) {
    if (!isValidCoin(coin)) {
      revert InvalidCoin(coin);
    }
    _;
  }

  error IncompatiblePoolCoin(Pool pool, Coin coin);

  function isCompatible(Pool pool, Coin coin) internal view virtual returns(bool) {
    return MetaStorage.state().compatible[pool][coin];
  }

  modifier ifIsCompatible(Pool pool, Coin coin) {
    if (!isCompatible(pool, coin)) {
      revert IncompatiblePoolCoin(pool, coin);
    }
    _;
  }

  error CallerNotSBV();

  function isSBV() internal view virtual returns(bool) {
    return MetaStorage.state().SBV == msg.sender;
  }

  modifier ifIsSBV {
    if (!isSBV()) {
      revert CallerNotSBV();
    }
    _;
  }

  error CallerNotSBT();

  function isSBT() internal view virtual returns(bool) {
    return MetaStorage.state().SBT == msg.sender;
  }

  modifier ifIsSBT {
    if (!isSBT()) {
      revert CallerNotSBT();
    }
    _;
  }

  error CallerNotSBD();

  function isSBD() internal view virtual returns(bool) {
    return address(this) == msg.sender;
  }

  modifier ifIsSBD {
    if (!isSBD()) {
      revert CallerNotSBD();
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address SBT;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Coin => address) acoin;
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