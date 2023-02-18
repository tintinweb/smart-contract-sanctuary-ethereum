// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "../../libraries/Utils.sol";
import "../interfaces/IMessageOwner.sol";

// only allow set MsgFee and PreExecuteMessageGasUsage
// disable contract upgrade or token bridge address updates
contract MessageBusOwner {
    uint256 public constant THRESHOLD_DECIMAL = 100;
    uint256 public constant MIN_ACTIVE_PERIOD = 3600; // one hour
    uint256 public constant MAX_ACTIVE_PERIOD = 2419200; // four weeks

    enum ParamName {
        ActivePeriod,
        QuorumThreshold // threshold for votes to pass
    }

    enum ProposalType {
        External,
        InternalParamChange,
        InternalVoterUpdate
    }

    enum MsgFeeType {
        PerByte,
        Base
    }

    mapping(ParamName => uint256) public params;

    struct Proposal {
        bytes32 dataHash; // hash(proposalType, targetAddress, calldata)
        uint256 deadline;
        mapping(address => bool) votes;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    address[] public voters;
    mapping(address => uint256) public voterPowers; // voter addr -> voting power

    event Initiated(address[] voters, uint256[] powers, uint256 activePeriod, uint256 quorumThreshold);

    event ProposalCreated(
        uint256 proposalId,
        ProposalType proposalType,
        address target,
        bytes data,
        uint256 deadline,
        address proposer
    );
    event ParamChangeProposalCreated(uint256 proposalId, ParamName name, uint256 value);
    event VoterUpdateProposalCreated(uint256 proposalId, address[] voters, uint256[] powers);
    event SetMsgFeeProposalCreated(uint256 proposalId, address target, MsgFeeType feeType, uint256 fee);
    event SetPreExecuteMessageGasUsageProposalCreated(uint256 proposalId, address target, uint256 usage);

    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    constructor(
        address[] memory _voters,
        uint256[] memory _powers,
        uint256 _activePeriod,
        uint256 _quorumThreshold
    ) {
        require(_voters.length > 0 && _voters.length == _powers.length, "invalid init voters");
        require(_activePeriod <= MAX_ACTIVE_PERIOD && _activePeriod >= MIN_ACTIVE_PERIOD, "invalid active period");
        require(_quorumThreshold < THRESHOLD_DECIMAL, "invalid init thresholds");
        for (uint256 i = 0; i < _voters.length; i++) {
            _setVoter(_voters[i], _powers[i]);
        }
        params[ParamName.ActivePeriod] = _activePeriod;
        params[ParamName.QuorumThreshold] = _quorumThreshold;
        emit Initiated(_voters, _powers, _activePeriod, _quorumThreshold);
    }

    /*********************************
     * External and Public Functions *
     *********************************/

    function proposeParamChange(ParamName _name, uint256 _value) external returns (uint256) {
        bytes memory data = abi.encode(_name, _value);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalParamChange);
        emit ParamChangeProposalCreated(proposalId, _name, _value);
        return proposalId;
    }

    function proposeVoterUpdate(address[] calldata _voters, uint256[] calldata _powers) external returns (uint256) {
        require(_voters.length == _powers.length, "voters and powers length not match");
        bytes memory data = abi.encode(_voters, _powers);
        uint256 proposalId = _createProposal(msg.sender, address(0), data, ProposalType.InternalVoterUpdate);
        emit VoterUpdateProposalCreated(proposalId, _voters, _powers);
        return proposalId;
    }

    function proposeSetMsgFee(
        address _target,
        MsgFeeType _feeType,
        uint256 _fee
    ) external returns (uint256) {
        bytes4 selector;
        if (_feeType == MsgFeeType.PerByte) {
            selector = IMessageOwner.setFeePerByte.selector;
        } else if (_feeType == MsgFeeType.Base) {
            selector = IMessageOwner.setFeeBase.selector;
        } else {
            revert("invalid fee type");
        }
        bytes memory data = abi.encodeWithSelector(selector, _fee);
        uint256 proposalId = _createProposal(msg.sender, _target, data, ProposalType.External);
        emit SetMsgFeeProposalCreated(proposalId, _target, _feeType, _fee);
        return proposalId;
    }

    function proposeSetPreExecuteMessageGasUsage(address _target, uint256 _usage) external {
        bytes memory data = abi.encodeWithSelector(IMessageOwner.setPreExecuteMessageGasUsage.selector, _usage);
        uint256 proposalId = _createProposal(msg.sender, _target, data, ProposalType.External);
        emit SetPreExecuteMessageGasUsageProposalCreated(proposalId, _target, _usage);
    }

    function voteProposal(uint256 _proposalId, bool _vote) external {
        require(voterPowers[msg.sender] > 0, "invalid voter");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        p.votes[msg.sender] = _vote;
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(
        uint256 _proposalId,
        ProposalType _type,
        address _target,
        bytes calldata _data
    ) external {
        require(voterPowers[msg.sender] > 0, "only voter can execute a proposal");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "deadline passed");
        require(keccak256(abi.encodePacked(_type, _target, _data)) == p.dataHash, "data hash not match");
        p.deadline = 0;

        p.votes[msg.sender] = true;
        (, , bool pass) = countVotes(_proposalId);
        require(pass, "not enough votes");

        if (_type == ProposalType.External) {
            (bool success, bytes memory res) = _target.call(_data);
            require(success, Utils.getRevertMsg(res));
        } else if (_type == ProposalType.InternalParamChange) {
            (ParamName name, uint256 value) = abi.decode((_data), (ParamName, uint256));
            params[name] = value;
            if (name == ParamName.ActivePeriod) {
                require(value <= MAX_ACTIVE_PERIOD && value >= MIN_ACTIVE_PERIOD, "invalid active period");
            } else if (name == ParamName.QuorumThreshold) {
                require(value < THRESHOLD_DECIMAL && value > 0, "invalid threshold");
            }
        } else if (_type == ProposalType.InternalVoterUpdate) {
            (address[] memory addrs, uint256[] memory powers) = abi.decode((_data), (address[], uint256[]));
            for (uint256 i = 0; i < addrs.length; i++) {
                if (powers[i] > 0) {
                    _setVoter(addrs[i], powers[i]);
                } else {
                    _removeVoter(addrs[i]);
                }
            }
        }
        emit ProposalExecuted(_proposalId);
    }

    /**************************
     *  Public View Functions *
     **************************/

    function getVoters() public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](voters.length);
        uint256[] memory powers = new uint256[](voters.length);
        for (uint32 i = 0; i < voters.length; i++) {
            addrs[i] = voters[i];
            powers[i] = voterPowers[voters[i]];
        }
        return (addrs, powers);
    }

    function getVote(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].votes[_voter];
    }

    function countVotes(uint256 _proposalId)
        public
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        uint256 yesVotes;
        uint256 totalPower;
        for (uint32 i = 0; i < voters.length; i++) {
            if (getVote(_proposalId, voters[i])) {
                yesVotes += voterPowers[voters[i]];
            }
            totalPower += voterPowers[voters[i]];
        }
        uint256 threshold = params[ParamName.QuorumThreshold];
        bool pass = (yesVotes >= (totalPower * threshold) / THRESHOLD_DECIMAL);
        return (totalPower, yesVotes, pass);
    }

    /**********************************
     * Internal and Private Functions *
     **********************************/

    // create a proposal and vote yes
    function _createProposal(
        address _proposer,
        address _target,
        bytes memory _data,
        ProposalType _type
    ) private returns (uint256) {
        require(voterPowers[_proposer] > 0, "only voter can create a proposal");
        uint256 proposalId = nextProposalId;
        nextProposalId += 1;
        Proposal storage p = proposals[proposalId];
        p.dataHash = keccak256(abi.encodePacked(_type, _target, _data));
        p.deadline = block.timestamp + params[ParamName.ActivePeriod];
        p.votes[_proposer] = true;
        emit ProposalCreated(proposalId, _type, _target, _data, p.deadline, _proposer);
        return proposalId;
    }

    function _setVoter(address _voter, uint256 _power) private {
        require(_power > 0, "zero power");
        if (voterPowers[_voter] == 0) {
            // add new voter
            voters.push(_voter);
        }
        voterPowers[_voter] = _power;
    }

    function _removeVoter(address _voter) private {
        require(voterPowers[_voter] > 0, "not a voter");
        uint256 lastIndex = voters.length - 1;
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _voter) {
                if (i < lastIndex) {
                    voters[i] = voters[lastIndex];
                }
                voters.pop();
                voterPowers[_voter] = 0;
                return;
            }
        }
        revert("voter not found"); // this should never happen
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library Utils {
    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageOwner {
    function setFeePerByte(uint256 _fee) external;

    function setFeeBase(uint256 _fee) external;

    function setLiquidityBridge(address _addr) external;

    function setPegBridge(address _addr) external;

    function setPegVault(address _addr) external;

    function setPegBridgeV2(address _addr) external;

    function setPegVaultV2(address _addr) external;

    function setPreExecuteMessageGasUsage(uint256 _usage) external;
}