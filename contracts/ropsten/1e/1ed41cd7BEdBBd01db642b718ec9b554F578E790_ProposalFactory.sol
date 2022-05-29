pragma solidity ^0.6.0;

import "./ContractFeeProposal.sol";
import "./MemberProposal.sol";

contract ProposalFactory {
    /**
     * @notice creates a new contractFee proposal
     * @param _proposedFee the suggested new fee
     * @param _minimumNumberOfVotes the minimum number of votes needed to execute the proposal
     * @param _majorityMargin the percentage of positive votes needed for proposal to pass
     */
    function newContractFeeProposal(
        uint256 _proposedFee,
        uint16 _minimumNumberOfVotes,
        uint8 _majorityMargin
    ) external returns(address proposal) {
        proposal = address(
            new ContractFeeProposal(
                _proposedFee,
                _minimumNumberOfVotes,
                _majorityMargin,
                msg.sender
            )
        );
    }

    /**
     * @notice creates a new member proposal
     * @param _memberAddress address of the member
     * @param _adding true to add member - false to remove member
     * @param _trusteeCount the current number of TrustToken-Holders
     * @param _majorityMargin the percentage of positive votes needed for proposal to pass
     */
    function newMemberProposal(
        address _memberAddress,
        bool _adding,
        uint256 _trusteeCount,
        uint8 _majorityMargin
    ) external returns (address proposal) {
        // calculate minimum number of votes for member proposal
        uint256 minVotes = _trusteeCount / 2;

        // ensure that minVotes > 0
        minVotes = minVotes == 0 ? (minVotes + 1) : minVotes;

        proposal = address(
            new MemberProposal(
                _memberAddress,
                _adding,
                minVotes,
                _majorityMargin,
                msg.sender
            )
        );
    }
}

pragma solidity ^0.6.0;

contract MemberProposal {
    mapping(address => bool) private voted;

    address private management;
    address public memberAddress;
    bool public proposalPassed;
    bool public proposalExecuted;
    bool public adding;
    uint8 private majorityMargin;
    uint16 public numberOfVotes;
    uint16 public numberOfPositiveVotes;
    uint256 private minimumNumberOfVotes;

    constructor(
        address _memberAddress,
        bool _adding,
        uint256 _minimumNumberOfVotes,
    // TODO Unused variable: majorityMargin
        uint8 _majorityMargin,
        address _managementContract
    ) public {
        memberAddress = _memberAddress;
        adding = _adding;
        minimumNumberOfVotes = _minimumNumberOfVotes;
        majorityMargin = _majorityMargin;
        management = _managementContract;
    }

    /**
     * @notice destroys the proposal contract and forwards the remaining funds to the management contract
     */
    function kill() external {
        require(msg.sender == management, "invalid caller");
        require(proposalExecuted, "!executed");
        selfdestruct(msg.sender);
    }

    /**
     * @notice Registers a vote for the proposal and triggers execution if conditions are met
     * @param _stance True for a positive vote; false otherwise
     * @param _origin The address of the initial function call
     * @return propPassed True if proposal met the required number of positive votes - false otherwise
     * @return propExecuted True if proposal met the required minimum number of votes - false otherwise
     */
    function vote(bool _stance, address _origin) external returns (bool propPassed, bool propExecuted) {
        // Check input parameters.
        require(msg.sender == management, "invalid caller");
        require(!proposalExecuted, "proposal already executed");
        require(!voted[_origin], "address has already voted on this proposal");

        // Count the vote, updating state variables.
        voted[_origin] = true;
        numberOfVotes += 1;
        if (_stance) {
            numberOfPositiveVotes++;
        }

        // Pass the proposal if it has enough votes.
        bool _propPassed = (numberOfVotes >= minimumNumberOfVotes && (numberOfPositiveVotes / numberOfVotes) >= majorityMargin);

        // Execute the proposal if it was passed.
        bool _propExecuted = proposalExecuted;
        if (_propPassed && !_propExecuted) {
            execute();
            _propExecuted = true;
        }

        // Update state variables.
        propPassed = _propPassed;
        proposalPassed = _propPassed;
        propExecuted = _propExecuted;
        proposalExecuted = _propExecuted;
    }

    /**
     * @notice Executes the proposal and updates the internal state.
     */
    function execute() private view {
        // Ensure proposal wasn't already executed.
        require(!proposalExecuted, "proposal already executed");

        // TODO Add _origin to a variable somewhere in ProposalManagement? The last dev didn't provide any logic for this.
    }
}

pragma solidity ^0.6.0;

contract ContractFeeProposal {
    mapping(address => bool) private voted;

    address payable private management;
    uint8 private majorityMargin;
    uint16 private minimumNumberOfVotes;
    uint16 public numberOfVotes;
    uint16 public numberOfPositiveVotes;
    uint256 public proposedFee;
    bool public proposalPassed;
    bool public proposalExecuted;

    constructor(
        uint256 _proposedFee,
        uint16 _minimumNumberOfVotes,
        uint8 _majorityMargin,
        address payable _managementContract
    ) public {
        proposedFee = _proposedFee;
        minimumNumberOfVotes = _minimumNumberOfVotes;
        majorityMargin = _majorityMargin;
        management = _managementContract;
    }

    /**
     * @notice destroys the proposal contract and forwards the remaining funds to the management contract
     */
    function kill() external {
        require(msg.sender == management, "invalid caller");
        require(proposalExecuted, "proposal hasn't been executed");
        selfdestruct(management);
    }

    /**
     * @notice registers a vote for the proposal and triggers execution if conditions are met
     * @param _stance true for a positive vote - false otherwise
     * @param _origin the address of the initial function call
     * @return propPassed true if proposal met the required number of positive votes - false otherwise
     * @return propExecuted true if proposal met the required minimum number of votes - false otherwise
     */
    function vote(bool _stance, address _origin) external returns (bool propPassed, bool propExecuted) {
        // check input parameters
        require(msg.sender == management, "invalid caller");
        require(!proposalExecuted, "executed");
        require(!voted[_origin], "second vote");

        // update internal state
        voted[_origin] = true;
        numberOfVotes += 1;
        if (_stance) numberOfPositiveVotes++;

        // check if execution of proposal should be triggered and update return values
        if ((numberOfVotes >= minimumNumberOfVotes)) {
            execute();
            propExecuted = true;
            propPassed = proposalPassed;
        }
    }

    /**
     * @notice executes the proposal and updates the internal state
     */
    function execute() private view {
        // Ensure proposal wasn't already executed.
        require(!proposalExecuted, "proposal already executed");

        // TODO Add _origin to a variable somewhere in ProposalManagement? The last dev didn't provide any logic for this.
    }
}