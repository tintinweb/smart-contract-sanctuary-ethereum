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
    /// @dev Address of latest governance contract
    address public governance;

    /// @dev Address of new governance contract
    address public appointedNewGovernance;

    /// @param initialGovernance Address of governance contract at deployment
    constructor(address initialGovernance) {
        require(initialGovernance != address(0), "Zero address");

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
        require(msg.sender == governance, "Only governance");
        require(
            newGovernance != address(0) && newGovernance != governance,
            "Invalid governance"
        );

        IGovernance _newGovernance = IGovernance(newGovernance);
        require(_newGovernance.votingPeriod() > 0);

        appointedNewGovernance = newGovernance;
    }

    /**
     * @dev Called by the new governance contract to verify the account ownership.
     * This will finally update the governance contract address.
     */
    function confirmChanged() external {
        require(appointedNewGovernance != address(0), "No change request yet");
        require(appointedNewGovernance == msg.sender, "Only appointed address");

        governance = appointedNewGovernance;
        appointedNewGovernance = address(0);
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
 * @title Interface for Governance
 * @author Playground Labs
 */
interface IGovernance {
    function votingPeriod() external view returns (uint256);

    struct Proposal {
        // hash of data required for the _transact function
        uint256 transactParamsHash;
        uint64 proposeTime;
        // Counters for the for/against votes. These votes will be used to determine if proposal passes.
        uint96 yaysKAP;
        uint96 naysKAP;
        uint112 yaysLP;
        uint112 naysLP;
        // Record if proposal has been executed
        bool executed;
        // Team multisig can veto malicious proposals
        bool vetoed;
        // Record values for TWAP
        uint256 priceCumulativeLast;
        // Mapping to keep track of who's voted
        mapping(address => bool) hasVoted;
    }

    struct WaitTo {
        uint24 startVote;
        uint24 endVote;
        uint24 execute;
        uint24 expire;
    }

    struct PoolParams {
        address kapToken;
        address otherToken;
        address poolAddress;
    }

    struct WeightSources {
        // indices of weightSourcesKAP for pulling voting weight
        uint256[] kapSourceIDs;
        // indices of weightSourcesLP for pulling voting weight
        uint256[] lpSourceIDs;
    }

    event Veto(
        uint256 indexed proposalId
    );
    event ProposalCreated(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 proposeTime,
        address[] targets,
        uint256[] values,
        bytes[] data,
        string description
    );
    event Voted(
        address indexed voter,
        uint256 indexed proposalID,
        bool yay,
        uint256 weightKAP,
        uint256 weightLP
    );
    event ProposalExecuted(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 time
    );
}