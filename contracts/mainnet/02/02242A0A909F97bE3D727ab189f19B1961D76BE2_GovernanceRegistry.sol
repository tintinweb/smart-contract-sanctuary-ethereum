// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernanceRegistry.sol";
import "./interfaces/IGovernance.sol";

/**
 * @title Kapital DAO Governance Registry
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Holds the latest address of the Kapital DAO governance contract.
 * Changing {governance} is a method of updating the Kapital DAO governance
 * structure if needed.
 */
contract GovernanceRegistry is IGovernanceRegistry {
    address public governance; // address of latest governance contract
    address public appointedGovernance; // address of newly appointed governance contract

    /// @param initialGovernance Address of governance contract at deployment
    constructor(address initialGovernance) {
        require(initialGovernance != address(0), "Registry: Zero address");
        governance = initialGovernance;
    }

    /**
     * @dev Called by the latest governance contract to update to a new address
     * if needed.
     * @dev This will only take effect after {newGovernance} executes {confirmChanged}
     * to verify that the valid address was appointed as a {newGovernance}.
     * @dev New governance contract should implement {votingPeriod}, being used by {Vesting} and {Staking}.
     * @param newGovernance Address of the new governance contract
     */
    function changeGovernance(address newGovernance) external {
        require(msg.sender == governance, "Registry: Only governance");
        require(
            newGovernance != address(0) && newGovernance != governance,
            "Registry: Invalid new governance"
        );

        IGovernance _newGovernance = IGovernance(newGovernance);
        require(_newGovernance.votingPeriod() > 0, "Registry: Invalid voting period");

        appointedGovernance = newGovernance;
    }

    /**
     * @dev Called by the new governance contract to verify the account ownership.
     * This will finally update the governance contract address.
     */
    function confirmChanged() external {
        require(appointedGovernance != address(0), "Registry: Invalid appointed");
        require(appointedGovernance == msg.sender, "Registry: Only appointed");

        governance = appointedGovernance;
        appointedGovernance = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for GovernanceRegistry
 * @author Playground Labs
 */
interface IGovernanceRegistry {
    function governance() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Kapital DAO Governance
 * @author Playground Labs
 * @custom:security-contact [email protected]
 */
interface IGovernance {
    function votingPeriod() external view returns (uint256); // used when reporting voting weight to prevent double-voting

    struct Proposal {
        bytes32 paramsHash; // hash of proposal data
        uint56 time; // proposal timestamp
        uint96 yays; // votes for proposal
        uint96 nays; // votes against proposal
        bool executed; // to make sure a proposal is only executed once
        bool vetoed; // vetoed proposal cannot be executed or voted on 
    }

    event Propose(
        address indexed proposer,
        uint256 indexed proposalId,
        address[] targets,
        uint256[] values,
        bytes[] data
    );
    event Vote(
        address indexed voter,
        uint256 indexed proposalId,
        bool yay,
        uint256 votingWeight
    );
    event Execute(address indexed executor, uint256 indexed proposalId);
    event Veto(uint256 indexed proposalId);
}