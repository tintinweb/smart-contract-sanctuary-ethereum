pragma solidity ^0.5.8;

/**
 * @title GovernERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract GovernERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/arbitration/IArbitrator.sol

pragma solidity ^0.5.8;

interface IArbitrator {
    /**
     * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
     * @param _possibleRulings Number of possible rulings allowed for the dispute
     * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
     * @return Dispute identification number
     */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata)
        external
        returns (uint256);

    /**
     * @dev Submit evidence for a dispute
     * @param _disputeId Id of the dispute in the Protocol
     * @param _submitter Address of the account submitting the evidence
     * @param _evidence Data submitted for the evidence related to the dispute
     */
    function submitEvidence(
        IArbitrable _subject,
        uint256 _disputeId,
        address _submitter,
        bytes calldata _evidence
    ) external;

    /**
     * @dev Close the evidence period of a dispute
     * @param _disputeId Identification number of the dispute to close its evidence submitting period
     */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId)
        external;

    /**
     * @notice Rule dispute #`_disputeId` if ready
     * @param _disputeId Identification number of the dispute to be ruled
     * @return subject Arbitrable instance associated to the dispute
     * @return ruling Ruling number computed for the given dispute
     */
    function rule(uint256 _disputeId)
        external
        returns (IArbitrable subject, uint256 ruling);

    /**
     * @dev Tell the dispute fees information to create a dispute
     * @return recipient Address where the corresponding dispute fees must be transferred to
     * @return feeToken GovernERC20 token used for the fees
     * @return feeAmount Total amount of fees that must be allowed to the recipient
     */
    function getDisputeFees()
        external
        view
        returns (
            address recipient,
            GovernERC20 feeToken,
            uint256 feeAmount
        );
}

// File: contracts/lib/os/SafeGovernERC20.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeGovernERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.8;

library SafeGovernERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    /**
     * @dev Same as a standards-compliant GovernERC20.transfer() that never reverts (returns false).
     *      Note that this makes an external call to the token.
     */
    function safeTransfer(
        GovernERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
     * @dev Same as a standards-compliant GovernERC20.transferFrom() that never reverts (returns false).
     *      Note that this makes an external call to the token.
     */
    function safeTransferFrom(
        GovernERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
     * @dev Same as a standards-compliant GovernERC20.approve() that never reverts (returns false).
     *      Note that this makes an external call to the token.
     */
    function safeApprove(
        GovernERC20 _token,
        address _spender,
        uint256 _amount
    ) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            let success := call(
                gas, // forward all gas
                _addr, // address
                0, // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata), // calldata length
                ptr, // write output over free memory
                0x20 // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize
                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }
                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }
                // Not sure what was returned: don't mark as success
                default {

                }
            }
        }
        return ret;
    }
}

contract IArbitrable {
    /**
     * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
     * @param arbitrator IArbitrator instance ruling the dispute
     * @param disputeId Identification number of the dispute being ruled by the arbitrator
     * @param ruling Ruling given by the arbitrator
     */
    event Ruled(
        IArbitrator indexed arbitrator,
        uint256 indexed disputeId,
        uint256 ruling
    );
}

// File: contracts/ownable-celeste/OwnableCeleste.sol

pragma solidity ^0.5.8;

contract OwnableCeleste is IArbitrator {
    using SafeGovernERC20 for GovernERC20;

    // DisputeManager module ID - keccak256(abi.encodePacked("DISPUTE_MANAGER"))
    bytes32 internal constant DISPUTE_MANAGER = 0x14a6c70f0f6d449c014c7bbc9e68e31e79e8474fb03b7194df83109a2d888ae6;

    // Treasury module ID - keccak256(abi.encodePacked("TREASURY"))
    bytes32 internal constant TREASURY = 0x06aa03964db1f7257357ef09714a5f0ca3633723df419e97015e0c7a3e83edb7;

    // Voting module ID - keccak256(abi.encodePacked("VOTING"))
    bytes32 internal constant VOTING = 0x7cbb12e82a6d63ff16fe43977f43e3e2b247ecd4e62c0e340da8800a48c67346;

    // JurorsRegistry module ID - keccak256(abi.encodePacked("JURORS_REGISTRY"))
    bytes32 internal constant JURORS_REGISTRY = 0x3b21d36b36308c830e6c4053fb40a3b6d79dde78947fbf6b0accd30720ab5370;

    // Subscriptions module ID - keccak256(abi.encodePacked("SUBSCRIPTIONS"))
    bytes32 internal constant SUBSCRIPTIONS = 0x2bfa3327fe52344390da94c32a346eeb1b65a8b583e4335a419b9471e88c1365;

    // BrightIDRegister module ID - keccak256(abi.encodePacked("BRIGHTID_REGISTER"))
    bytes32 internal constant BRIGHTID_REGISTER = 0xc8d8a5444a51ecc23e5091f18c4162834512a4bc5cae72c637db45c8c37b3329;

    // Note that Aragon Court treats the possible outcomes as arbitrary numbers, leaving the Arbitrable (us) to define how to understand them.
    // Some outcomes [0, 1, and 2] are reserved by Aragon Court: "missing", "leaked", and "refused", respectively.
    // This Arbitrable introduces the concept of the challenger/submitter (a binary outcome) as 3/4.
    // Note that Aragon Court emits the lowest outcome in the event of a tie, and so for us, we prefer the challenger.
    uint256 private constant DISPUTES_NOT_RULED = 0;
    uint256 private constant DISPUTES_RULING_CHALLENGER = 3;
    uint256 private constant DISPUTES_RULING_SUBMITTER = 4;

    enum State {
        NOT_DISPUTED,
        DISPUTED,
        DISPUTES_NOT_RULED,
        DISPUTES_RULING_CHALLENGER,
        DISPUTES_RULING_SUBMITTER
    }

    struct Dispute {
        IArbitrable subject;
        State state;
    }

    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    enum AdjudicationState {
        Invalid,
        Committing,
        Revealing,
        Appealing,
        ConfirmingAppeal,
        Ended
    }

    /**
     * @dev Ensure a dispute exists
     * @param _disputeId Identification number of the dispute to be ensured
     */
    modifier disputeExists(uint256 _disputeId) {
        require(_disputeId <= currentId, "DM_DISPUTE_DOES_NOT_EXIST");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR:NOT_OWNER");
        _;
    }

    GovernERC20 public feeToken;
    uint256 public feeAmount;
    uint256 public currentId;
    address public owner;
    // Last ensured term id
    uint64 private termId;
    mapping(uint256 => Dispute) public disputes;
    address governorFeesUpdater;
    address governorFunds;
    address governorModules;
    address governorConfig;
    uint64 termDuration;
    // List of modules registered for the system indexed by ID
    mapping (bytes32 => address) internal modules;

    address private constant ZERO_ADDRESS = address(0);

    // Events
    event Heartbeat(uint64 previousTermId, uint64 currentTermId);
    event StartTimeDelayed(uint64 previousStartTime, uint64 currentStartTime);

    event DisputeStateChanged(
        uint256 indexed disputeId,
        DisputeState indexed state
    );
    event EvidenceSubmitted(
        uint256 indexed disputeId,
        address indexed submitter,
        bytes evidence
    );
    event EvidencePeriodClosed(
        uint256 indexed disputeId,
        uint64 indexed termId
    );
    event NewDispute(
        uint256 indexed disputeId,
        IArbitrable indexed subject,
        uint64 indexed draftTermId,
        uint64 jurorsNumber,
        bytes metadata
    );
    event JurorDrafted(
        uint256 indexed disputeId,
        uint256 indexed roundId,
        address indexed juror
    );
    event RulingAppealed(
        uint256 indexed disputeId,
        uint256 indexed roundId,
        uint8 ruling
    );
    event RulingAppealConfirmed(
        uint256 indexed disputeId,
        uint256 indexed roundId,
        uint64 indexed draftTermId,
        uint256 jurorsNumber
    );
    event RulingComputed(uint256 indexed disputeId, uint8 indexed ruling);
    event PenaltiesSettled(
        uint256 indexed disputeId,
        uint256 indexed roundId,
        uint256 collectedTokens
    );
    event RewardSettled(
        uint256 indexed disputeId,
        uint256 indexed roundId,
        address juror,
        uint256 tokens,
        uint256 fees
    );
    event AppealDepositSettled(
        uint256 indexed disputeId,
        uint256 indexed roundId
    );
    event MaxJurorsPerDraftBatchChanged(
        uint64 previousMaxJurorsPerDraftBatch,
        uint64 currentMaxJurorsPerDraftBatch
    );
    event ModuleSet(bytes32 id, address addr);
    event FundsGovernorChanged(
        address previousGovernor,
        address currentGovernor
    );
    event ConfigGovernorChanged(
        address previousGovernor,
        address currentGovernor
    );
    event FeesUpdaterChanged(
        address previousFeesUpdater,
        address currentFeesUpdater
    );
    event ModulesGovernorChanged(
        address previousGovernor,
        address currentGovernor
    );

    constructor(GovernERC20 _feeToken, uint256 _feeAmount) public {
        owner = msg.sender;
        feeToken = _feeToken;
        feeAmount = _feeAmount;
    }

    /**
    * @dev Tell the term duration of the Court
    * @return Duration in seconds of the Court term
    */
    function getTermDuration() external view returns (uint64) {
        return termDuration;
    }

    /**
    * @dev Tell the address of the Treasury module
    * @return Address of the Treasury module
    */
    function getTreasury() external view returns (address) {
        return modules[TREASURY];
    }

    /**
    * @dev Tell the address of the Voting module
    * @return Address of the Voting module
    */
    function getVoting() external view returns (address) {
        return modules[VOTING];
    }

    /**
    * @dev Tell the address of the JurorsRegistry module
    * @return Address of the JurorsRegistry module
    */
    function getJurorsRegistry() external view returns (address) {
        return modules[JURORS_REGISTRY];
    }

    /**
    * @dev Tell the address of the Subscriptions module
    * @return Address of the Subscriptions module
    */
    function getSubscriptions() external view returns (address) {
        return modules[SUBSCRIPTIONS];
    }

        /**
    * @dev Tell the address of the BrightId register
    * @return Address of the BrightId register
    */
    function getBrightIdRegister() external view returns (address) {
        return modules[BRIGHTID_REGISTER];
    }

    /**
    * @dev Set the term duration of the Court
    * @return Duration in seconds of the Court term
    */
    function setTermDuration(uint64 _termDuration) external {
        termDuration = _termDuration;
    }

    /**
    * @dev Tell address of a module based on a given ID
    * @param _id ID of the module being queried
    * @return Address of the requested module
    */
    function getModule(bytes32 _id) external view returns (address) {
        return modules[_id];
    }

    /**
     * @dev Tell the address of the modules governor
     * @return Address of the modules governor
     */
    function getConfig(uint64 _termId)
        external
        view
        returns (
            ERC20 _feeToken,
            uint256[3] memory fees,
            uint8 maxRulingOptions,
            uint64[9] memory roundParams,
            uint16[2] memory pcts,
            uint256[2] memory appealCollateralParams,
            uint256[4] memory jurorsParams
        )
    {
        _feeToken = ERC20(address(feeToken));
        fees = [feeAmount, feeAmount, feeAmount];
        maxRulingOptions = 100;
        roundParams = [
            uint64(0),
            uint64(1),
            uint64(2),
            uint64(3),
            uint64(4),
            uint64(5),
            uint64(6),
            uint64(7),
            uint64(8)
        ];
        pcts = [uint16(0), uint16(0)];
        appealCollateralParams = [uint256(0), uint256(0)];
        jurorsParams = [uint256(0), uint256(1), uint256(2), uint256(3)];
    }

    /**
     * @dev Tell the current term identification number. Note that there may be pending term transitions.
     * @return Identification number of the current term
     */
    function getCurrentTermId() external view returns (uint64) {
        return termId;
    }

    /**
     * @dev Tell the information related to a term based on its ID. Note that if the term has not been reached, the
     *      information returned won't be computed yet. This function allows querying future terms that were not computed yet.
     * @param _termId ID of the term being queried
     * @return startTime Term start time
     * @return randomnessBN Block number used for randomness in the requested term
     * @return randomness Randomness computed for the requested term
     * @return celesteTokenTotalSupply Total supply of the Celeste token
     */
    function getTerm(uint64 _termId)
        external
        view
        returns (
            uint64 startTime,
            uint64 randomnessBN,
            bytes32 randomness,
            uint256 celesteTokenTotalSupply
        )
    {
        startTime = 0;
        randomnessBN = 0;
        randomness = 0;
        celesteTokenTotalSupply = 0;
    }

    /**
     * @dev Tell the address of the funds governor
     * @return Address of the funds governor
     */
    function getFundsGovernor() external view returns (address) {
        return governorFunds;
    }

    /**
     * @dev Tell the address of the config governor
     * @return Address of the config governor
     */
    function getConfigGovernor() external view returns (address) {
        return governorConfig;
    }

    /**
     * @dev Tell the address of the fees updater
     * @return Address of the fees updater
     */
    function getFeesUpdater() external view returns (address) {
        return governorFeesUpdater;
    }

    /**
     * @dev Tell the address of the modules governor
     * @return Address of the modules governor
     */
    function getModulesGovernor() external view returns (address) {
        return governorModules;
    }

    /**
     * @notice Change funds governor address to `_newFundsGovernor`
     * @param _newFundsGovernor Address of the new funds governor to be set
     */
    function changeFundsGovernor(address _newFundsGovernor) public {
        emit FundsGovernorChanged(governorFunds, _newFundsGovernor);
        governorFunds = _newFundsGovernor;
    }

    /**
     * @notice Change config governor address to `_newConfigGovernor`
     * @param _newConfigGovernor Address of the new config governor to be set
     */
    function changeConfigGovernor(address _newConfigGovernor) public {
        emit ConfigGovernorChanged(governorConfig, _newConfigGovernor);
        governorConfig = _newConfigGovernor;
    }

    /**
     * @notice Change fees updater to `_newFeesUpdater`
     * @param _newFeesUpdater Address of the new fees updater to be set
     */
    function changeFeesUpdater(address _newFeesUpdater) public {
        emit FeesUpdaterChanged(governorFeesUpdater, _newFeesUpdater);
        governorFeesUpdater = _newFeesUpdater;
    }

    /**
     * @notice Change modules governor address to `_newModulesGovernor`
     * @param _newModulesGovernor Address of the new governor to be set
     */
    function changeModulesGovernor(address _newModulesGovernor) public {
        emit ModulesGovernorChanged(governorModules, _newModulesGovernor);
        governorModules = _newModulesGovernor;
    }

    /**
     * @notice Remove the funds governor. Set the funds governor to the zero address.
     * @dev This action cannot be rolled back, once the funds governor has been unset, funds cannot be recovered from recoverable modules anymore
     */
    function ejectFundsGovernor() public {
        emit FundsGovernorChanged(governorModules, ZERO_ADDRESS);
        governorModules = ZERO_ADDRESS;
    }

    /**
     * @notice Remove the modules governor. Set the modules governor to the zero address.
     * @dev This action cannot be rolled back, once the modules governor has been unset, system modules cannot be changed anymore
     */
    function ejectModulesGovernor() public {
        emit ModulesGovernorChanged(address(this), ZERO_ADDRESS);
    }

    /**
     * @notice Set module `_id` to `_addr`
     * @param _id ID of the module to be set
     * @param _addr Address of the module to be set
     */
    function setModule(bytes32 _id, address _addr) public {
        modules[_id] = _addr;
        emit ModuleSet(_id, _addr);
    }

    /**
     * @dev Draft jurors for the next round of a dispute
     * @param _disputeId Identification number of the dispute to be drafted
     */
    function draft(uint256 _disputeId) external disputeExists(_disputeId) {
        emit JurorDrafted(_disputeId, 0, address(this));
        emit DisputeStateChanged(_disputeId, DisputeState.Adjudicating);
    }

    /**
     * @notice Transition up to `_maxRequestedTransitions` terms
     * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
     * @return Identification number of the term ID after executing the heartbeat transitions
     */
    function heartbeat(uint64 _maxRequestedTransitions)
        external
        returns (uint64)
    {
        uint64 previousTermId = termId;
        uint64 currentTermId = previousTermId + _maxRequestedTransitions;
        termId = currentTermId;
        emit Heartbeat(previousTermId, currentTermId);
        return termId;
    }

    /**
     * @notice Delay the Court start time to `_newFirstTermStartTime`
     * @param _newFirstTermStartTime New timestamp in seconds when the court will open
     */
    function delayStartTime(uint64 _newFirstTermStartTime) public {
        emit StartTimeDelayed(0, _newFirstTermStartTime);
    }

    /**
     * @notice Close the evidence period of dispute #`_disputeId`
     * @param _subject IArbitrable instance requesting to close the evidence submission period
     * @param _disputeId Identification number of the dispute to close its evidence submitting period
     */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId)
        external
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.subject == _subject, "DM_SUBJECT_NOT_DISPUTE_SUBJECT");
        emit EvidencePeriodClosed(_disputeId, 0);
    }

    /**
     * @notice Submit evidence for a dispute #`_disputeId`
     * @param _subject Arbitrable instance submitting the dispute
     * @param _disputeId Identification number of the dispute receiving new evidence
     * @param _submitter Address of the account submitting the evidence
     * @param _evidence Data submitted for the evidence of the dispute
     */
    function submitEvidence(
        IArbitrable _subject,
        uint256 _disputeId,
        address _submitter,
        bytes calldata _evidence
    ) external disputeExists(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.subject == _subject, "DM_SUBJECT_NOT_DISPUTE_SUBJECT");
        emit EvidenceSubmitted(_disputeId, _submitter, _evidence);
    }

    /**
     * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
     * @param _possibleRulings Number of possible rulings allowed for the dispute
     * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
     * @return Dispute identification number
     */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata)
        external
        returns (uint256)
    {
        uint256 disputeId = currentId;
        disputes[disputeId] = Dispute(IArbitrable(msg.sender), State.DISPUTED);
        currentId++;

        require(
            feeToken.safeTransferFrom(msg.sender, address(this), feeAmount),
            "ERR:DEPOSIT_FAILED"
        );

        emit NewDispute(disputeId, IArbitrable(msg.sender), 0, 3, _metadata);

        return disputeId;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function decideDispute(uint256 _disputeId, State _state)
        external
        onlyOwner
    {
        require(
            _state != State.NOT_DISPUTED && _state != State.DISPUTED,
            "ERR:OUTCOME_NOT_ASSIGNABLE"
        );

        Dispute storage dispute = disputes[_disputeId];
        require(dispute.state == State.DISPUTED, "ERR:NOT_DISPUTED");

        dispute.state = _state;
    }

    /**
     * @notice Rule dispute #`_disputeId` if ready
     * @param _disputeId Identification number of the dispute to be ruled
     * @return subject Arbitrable instance associated to the dispute
     * @return ruling Ruling number computed for the given dispute
     */
    function rule(uint256 _disputeId)
        external
        returns (IArbitrable subject, uint256 ruling)
    {
        Dispute storage dispute = disputes[_disputeId];

        if (dispute.state == State.DISPUTES_RULING_CHALLENGER) {
            return (dispute.subject, DISPUTES_RULING_CHALLENGER);
        } else if (dispute.state == State.DISPUTES_RULING_SUBMITTER) {
            return (dispute.subject, DISPUTES_RULING_SUBMITTER);
        } else if (dispute.state == State.DISPUTES_NOT_RULED) {
            return (dispute.subject, DISPUTES_NOT_RULED);
        } else {
            revert("UNEXPECTED_STATE");
        }
    }

    /**
     * @dev Tell the dispute fees information to create a dispute
     * @return recipient Address where the corresponding dispute fees must be transferred to
     * @return feeToken GovernERC20 token used for the fees
     * @return feeAmount Total amount of fees that must be allowed to the recipient
     */
    function getDisputeFees()
        external
        view
        returns (
            address,
            GovernERC20,
            uint256
        )
    {
        return (address(this), feeToken, feeAmount);
    }

    function getDisputeManager() external view returns (address) {
        return address(this);
    }

    function computeRuling(uint256 _disputeId)
        external
        returns (IArbitrable subject, State finalRuling)
    {
        Dispute storage dispute = disputes[_disputeId];
        subject = dispute.subject;
        finalRuling = dispute.state;
    }
}