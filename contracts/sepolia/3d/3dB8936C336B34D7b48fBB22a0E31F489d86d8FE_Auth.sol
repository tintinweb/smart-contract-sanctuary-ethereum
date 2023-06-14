// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";

/// @title Auth
contract Auth {

    /// @dev Emitted when the Golem Foundation multisig address is set.
    /// @param oldValue The old Golem Foundation multisig address.
    /// @param newValue The new Golem Foundation multisig address.
    event MultisigSet(address oldValue, address newValue);

    /// @dev Emitted when the deployer address is set.
    /// @param oldValue The old deployer address.
    event DeployerRenounced(address oldValue);

    /// @dev The deployer address.
    address public deployer;

    /// @dev The multisig address.
    address public multisig;

    /// @param _multisig The initial Golem Foundation multisig address.
    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    /// @dev Sets the multisig address.
    /// @param _multisig The new multisig address.
    function setMultisig(address _multisig) external {
        require(msg.sender == multisig, CommonErrors.UNAUTHORIZED_CALLER);
        emit MultisigSet(multisig, _multisig);
        multisig = _multisig;
    }

    /// @dev Leaves the contract without a deployer. It will not be possible to call
    /// `onlyDeployer` functions. Can only be called by the current deployer.
    function renounceDeployer() external {
        require(msg.sender == deployer, CommonErrors.UNAUTHORIZED_CALLER);
        emit DeployerRenounced(deployer);
        deployer = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library DepositsErrors {
    /// @notice Thrown when transfer operation fails in GLM smart contract.
    /// @return HN:Deposits/cannot-transfer-from-sender
    string public constant GLM_TRANSFER_FAILED =
    "HN:Deposits/cannot-transfer-from-sender";

    /// @notice Thrown when trying to withdraw more GLMs than are in deposit.
    /// @return HN:Deposits/deposit-is-smaller
    string public constant DEPOSIT_IS_TO_SMALL =
    "HN:Deposits/deposit-is-smaller";
}

library EpochsErrors {
    /// @notice Thrown when calling the contract before the first epoch started.
    /// @return HN:Epochs/not-started-yet
    string public constant NOT_STARTED = "HN:Epochs/not-started-yet";

    /// @notice Thrown when getFinalizedEpoch function is called before any epoch has been finalized.
    /// @return HN:Epochs/not-finalized
    string public constant NOT_FINALIZED = "HN:Epochs/not-finalized";

    /// @notice Thrown when getPendingEpoch function is called during closed decision window.
    /// @return HN:Epochs/not-pending
    string public constant NOT_PENDING = "HN:Epochs/not-pending";

    /// @notice Thrown when updating epoch props to invalid values (decision window bigger than epoch duration.
    /// @return HN:Epochs/decision-window-bigger-than-duration
    string public constant DECISION_WINDOW_TOO_BIG = "HN:Epochs/decision-window-bigger-than-duration";
}

library ProposalsErrors {
    /// @notice Thrown when trying to change proposals that could already have been voted upon.
    /// @return HN:Proposals/only-future-proposals-changing-is-allowed
    string public constant CHANGING_PROPOSALS_IN_THE_PAST =
    "HN:Proposals/only-future-proposals-changing-is-allowed";
}

library VaultErrors {
    /// @notice Thrown when trying to set merkle root for an epoch multiple times.
    /// @return HN:Vault/merkle-root-already-set
    string public constant MERKLE_ROOT_ALREADY_SET = "HN:Vault/merkle-root-already-set";

    /// @notice Thrown when trying to withdraw without providing valid merkle proof.
    /// @return HN:Vault/invalid-merkle-proof
    string public constant INVALID_MERKLE_PROOF = "HN:Vault/invalid-merkle-proof";

    /// @notice Thrown when trying to withdraw multiple times.
    /// @return HN:Vault/already-claimed
    string public constant ALREADY_CLAIMED = "HN:Vault/already-claimed";
}

library CommonErrors {
    /// @notice Thrown when trying to call as an unauthorized account.
    /// @return HN:Common/unauthorized-caller
    string public constant UNAUTHORIZED_CALLER =
    "HN:Common/unauthorized-caller";
}