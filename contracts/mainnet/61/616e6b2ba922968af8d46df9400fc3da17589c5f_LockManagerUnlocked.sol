// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ILockManager.sol";

/// @title Solarbots Lock Manager Unlocked
/// @author Solarbots (https://solarbots.io)
contract LockManagerUnlocked is ILockManager {
    function isLocked(address /*collection*/, address /*operator*/, address /*from*/, address /*to*/, uint256 /*id*/) external pure returns (bool) {
        return false;
    }

    function isLocked(address /*collection*/, address /*operator*/, address /*from*/, address /*to*/, uint256[] calldata /*ids*/) external pure returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Solarbots Lock Manager Interface
/// @author Solarbots (https://solarbots.io)
interface ILockManager {
    function isLocked(address collection, address operator, address from, address to, uint256 id) external returns (bool);
    function isLocked(address collection, address operator, address from, address to, uint256[] calldata ids) external returns (bool);
}