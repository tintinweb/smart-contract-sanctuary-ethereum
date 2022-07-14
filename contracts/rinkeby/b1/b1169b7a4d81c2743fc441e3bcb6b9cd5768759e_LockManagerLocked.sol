// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ILockManager.sol";

/// @title Solarbots Lock Manager Locked
/// @author Solarbots (https://solarbots.io)
contract LockManagerLocked is ILockManager {
    function isLocked(address /*collection*/, address /*operator*/, address /*from*/, address /*to*/, uint256 /*id*/) external pure returns (bool) {
        return true;
    }

    function isLocked(address /*collection*/, address /*operator*/, address /*from*/, address /*to*/, uint256[] calldata /*ids*/) external pure returns (bool) {
        return true;
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