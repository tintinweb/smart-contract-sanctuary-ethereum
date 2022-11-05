// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPepperStake.sol";

contract PepperStake is IPepperStake {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error MAX_PARTICIPANTS_REACHED();
    error INCORRECT_STAKE_AMOUNT();
    error ALREADY_PARTICIPATING();
    error RETURN_WINDOW_OVER();
    error RETURN_WINDOW_NOT_OVER();
    error CALLER_IS_NOT_SUPERVISOR();
    error INVALID_PARTICIPANT();
    error POST_RETURN_WINDOW_DISTRIBUTION_ALREADY_CALLED();

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    struct ParticipantData {
        bool participated;
        bool completed;
    }

    mapping(address => bool) public supervisors;
    uint256 public stakeAmount;

    address[] public unreturnedStakeBeneficiaries;
    uint256 public returnWindowDays;
    uint256 public maxParticipants;
    bool public shouldParticipantsShareUnreturnedStake;
    bool public shouldUseSupervisorInactionGuard;
    string public metadataURI;

    // Internal State
    address[] public participantList;
    mapping(address => ParticipantData) public participants;
    uint256 public returnWindowEndTimestamp;
    uint256 public participantCount;
    uint256 public completingParticipantCount;
    uint256 public totalSponsorContribution;
    bool public isReturnStakeCalled;
    bool public isPostReturnWindowDistributionCalled;

    constructor(
        address[] memory _supervisors,
        uint256 _stakeAmount,
        address[] memory _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string memory _metadataURI
    ) {
        for (uint256 i = 0; i < _supervisors.length; i++) {
            supervisors[_supervisors[i]] = true;
        }
        stakeAmount = _stakeAmount;
        unreturnedStakeBeneficiaries = _unreturnedStakeBeneficiaries;
        returnWindowDays = _returnWindowDays;
        maxParticipants = _maxParticipants;
        shouldParticipantsShareUnreturnedStake = _shouldParticipantsShareUnreturnedStake;
        shouldUseSupervisorInactionGuard = _shouldUseSupervisorInactionGuard;
        metadataURI = _metadataURI;

        returnWindowEndTimestamp =
            block.timestamp +
            (returnWindowDays * 1 days);
        participantCount = 0;
        completingParticipantCount = 0;
        totalSponsorContribution = 0;
        isReturnStakeCalled = false;
        isPostReturnWindowDistributionCalled = false;
    }

    function IS_SUPERVISOR(address _supervisor) external view returns (bool) {
        return supervisors[_supervisor];
    }

    function END_TIMESTAMP() public view returns (uint256) {
        return returnWindowEndTimestamp;
    }

    function TOTAL_SPONSOR_CONTRIBUTION() public view returns (uint256) {
        return totalSponsorContribution;
    }

    function PARTICIPANT_COUNT() external view returns (uint256) {
        return participantCount;
    }

    function COMPLETING_PARTICIPANT_COUNT() external view returns (uint256) {
        return completingParticipantCount;
    }

    function stake() external payable {
        if (participantCount >= maxParticipants)
            revert MAX_PARTICIPANTS_REACHED();
        if (msg.value != stakeAmount) revert INCORRECT_STAKE_AMOUNT();
        if (participants[msg.sender].participated)
            revert ALREADY_PARTICIPATING();
        if (block.timestamp > returnWindowEndTimestamp)
            revert RETURN_WINDOW_OVER();

        participantList.push(msg.sender);
        ParticipantData memory participantData = ParticipantData({
            participated: true,
            completed: false
        });
        participants[msg.sender] = participantData;
        participantCount++;

        emit Stake(msg.sender, msg.value);
    }

    function sponsor() external payable {
        if (block.timestamp > returnWindowEndTimestamp)
            revert RETURN_WINDOW_OVER();
        totalSponsorContribution += msg.value;

        emit Sponsor(msg.sender, msg.value);
    }

    function returnStake(address[] memory completingParticipants) external {
        if (!supervisors[msg.sender]) revert CALLER_IS_NOT_SUPERVISOR();
        if (block.timestamp > returnWindowEndTimestamp)
            revert RETURN_WINDOW_OVER();
        for (uint256 i = 0; i < completingParticipants.length; i++) {
            if (!participants[completingParticipants[i]].participated)
                revert INVALID_PARTICIPANT();
        }

        for (uint256 i = 0; i < completingParticipants.length; i++) {
            address payable participant = payable(completingParticipants[i]);
            participant.transfer(stakeAmount);
            participants[participant].completed = true;
            completingParticipantCount++;
        }
        isReturnStakeCalled = true;

        emit ReturnStake(msg.sender, completingParticipants, stakeAmount);
    }

    function _distributeUnreturnedStake() private {
        if (participantCount - completingParticipantCount > 0) {
            address[] memory beneficiaries;
            if (shouldUseSupervisorInactionGuard && !isReturnStakeCalled) {
                // Inaction Guard is true, no supervisor ever called returnStake()
                beneficiaries = participantList;
            } else {
                beneficiaries = unreturnedStakeBeneficiaries;
            }
            uint256 unreturnedStake = address(this).balance;
            uint256 beneficiaryShare = unreturnedStake /
                (participantCount - completingParticipantCount);
            for (uint256 i = 0; i < beneficiaries.length; i++) {
                payable(beneficiaries[i]).transfer(beneficiaryShare);
            }

            emit DistributeUnreturnedStake(
                msg.sender,
                beneficiaries,
                unreturnedStake,
                beneficiaryShare
            );
        }
    }

    function _distributeSponsorContribution() private {
        // TODO: Handle case with sponsor contribution but no completing participants
        if (completingParticipantCount > 0) {
            uint256 beneficiaryShare = totalSponsorContribution /
                completingParticipantCount;
            address[] memory beneficiaries = new address[](
                completingParticipantCount
            );
            uint256 beneficiaryIndex = 0;
            for (uint256 i = 0; i < participantCount; i++) {
                address participant = participantList[i];
                if (participants[participant].completed) {
                    payable(participant).transfer(beneficiaryShare);
                    beneficiaries[beneficiaryIndex] = participant;
                    beneficiaryIndex++;
                }
            }

            emit DistributeSponsorContribution(
                msg.sender,
                beneficiaries,
                totalSponsorContribution,
                beneficiaryShare
            );
        }
    }

    function postReturnWindowDistribution() external {
        if (block.timestamp <= returnWindowEndTimestamp)
            revert RETURN_WINDOW_NOT_OVER();
        if (isPostReturnWindowDistributionCalled)
            revert POST_RETURN_WINDOW_DISTRIBUTION_ALREADY_CALLED();
        _distributeSponsorContribution();
        _distributeUnreturnedStake();
        isPostReturnWindowDistributionCalled = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPepperStakeDeployer.sol";
import "./PepperStake.sol";

contract PepperStakeDeployer is IPepperStakeDeployer {
    uint256 public protocolFee;

    constructor(uint256 _protocolFee) {
        protocolFee = _protocolFee;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /** 
    @notice 
    Allows anyone to deploy a new PepperStake contract.
  */
    function deployPepperStake(
        address[] memory _supervisors,
        uint256 _stakeAmount,
        address[] memory _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string memory _metadataURI
    ) external returns (IPepperStake pepperStake) {
        pepperStake = new PepperStake(
            _supervisors,
            _stakeAmount,
            _unreturnedStakeBeneficiaries,
            _returnWindowDays,
            _maxParticipants,
            _shouldParticipantsShareUnreturnedStake,
            _shouldUseSupervisorInactionGuard,
            _metadataURI
        );
        emit DeployPepperStake(
            pepperStake,
            _supervisors,
            _stakeAmount,
            _unreturnedStakeBeneficiaries,
            _returnWindowDays,
            _maxParticipants,
            _shouldParticipantsShareUnreturnedStake,
            _shouldUseSupervisorInactionGuard,
            _metadataURI
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPepperStake {
    event Stake(address indexed participant, uint256 amount);
    event Sponsor(address indexed participant, uint256 amount);
    event ReturnStake(
        address indexed supervisor,
        address[] completingParticipants,
        uint256 amount
    );
    event DistributeUnreturnedStake(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalUnreturnedStake,
        uint256 sharePerBeneficiary
    );
    event DistributeSponsorContribution(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalSponsorContribution,
        uint256 sharePerBeneficiary
    );

    function stake() external payable;

    function sponsor() external payable;

    function returnStake(address[] memory completingParticipants) external;

    function postReturnWindowDistribution() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPepperStake.sol";

interface IPepperStakeDeployer {
    event DeployPepperStake(
        IPepperStake indexed pepperStake,
        address[] _supervisors,
        uint256 _stakeAmount,
        address[] _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string _metadataURI
    );

    function deployPepperStake(
        address[] memory _supervisors,
        uint256 _stakeAmount,
        address[] memory _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string memory _metadataURI
    ) external returns (IPepperStake pepperStake);
}