// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

/// @title DebtLockerStorage maps the storage layout of a DebtLocker.
contract DebtLockerStorage {

    address internal _liquidator;
    address internal _loan;
    address internal _pool;

    bool internal _repossessed;

    uint256 internal _allowedSlippage;
    uint256 internal _amountRecovered;
    uint256 internal _fundsToCapture;
    uint256 internal _minRatio;
    uint256 internal _principalRemainingAtLastClaim;

    address internal _loanMigrator;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDebtLockerV4Migrator } from "./interfaces/IDebtLockerV4Migrator.sol";

import { DebtLockerStorage } from "./DebtLockerStorage.sol";

/// @title DebtLockerV4Migrator is intended to initialize the storage of a DebtLocker proxy.
contract DebtLockerV4Migrator is IDebtLockerV4Migrator, DebtLockerStorage {

    function encodeArguments(address migrator_) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(migrator_);
    }

    function decodeArguments(bytes calldata encodedArguments_) public pure override returns (address migrator_) {
        ( migrator_ ) = abi.decode(encodedArguments_, (address));
    }

    fallback() external {

        // Taking the migrator_ address as argument for now, but ideally this would be hardcoded in the debtLocker migrator registered in the factory
        ( address migrator_ ) = decodeArguments(msg.data);

        _loanMigrator = migrator_;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

/// @title DebtLockerInitializer is intended to initialize the storage of a DebtLocker proxy.
interface IDebtLockerV4Migrator {

    function encodeArguments(address migrator_) external pure returns (bytes memory encodedArguments_);

    function decodeArguments(bytes calldata encodedArguments_) external pure returns (address migrator_);

}