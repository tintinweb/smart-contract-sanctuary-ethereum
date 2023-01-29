// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMaster {

    enum TypeMetric {
        Unknown,
        Uint, 
        Int, 
        FloatUint, 
        FloatInt, 
        Address,
        Bool,
        String,
        Date,
        Bytes32,
        KYC
    }

    enum KarmaState {
        Default,
        Good,
        Bad
    }

    struct MetricInfo {
        address oracle;
        TypeMetric typeMetric;
        string label; 
        string name; 
    }

    struct OracleInfo {
        string[] allMetrics;
        string label;
        int ResultKarma;
        mapping(address => KarmaState) karmaStates;
        bool ban;
    }

    struct OracleProposal {
        bytes32 votingId;
        string[] metricNames;
        TypeMetric[] metricTypes;
        string description;
        address oracle;
        uint endTime;
        uint support;
    }

    struct MemberProposal {
        bytes32 votingId;
        address member;
        uint endTime;
        uint support;
    }

    function becomeOracle(string[] calldata _metricNames, TypeMetric[] calldata _typeMetric, string calldata _description) external; 

    function voteForOracle(uint _id) external;
    
    function finishOracleVoiting(uint _id) external;

    function becomeMember() external;

    function voteForMember(uint _id) external;

    function finishMemberVoiting(uint _id) external;

    function getMetricaInfo(bytes32 _metricId) external view returns(MetricInfo memory);

    // function getOracleInfo(address _oracle) external view returns(OracleInfo memory);

    function getMetricNamesByProposalId(uint _id) external view returns(string[] memory);

    function getOracleByMetricId(bytes32 _metricId) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/IMaster.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Master is ReentrancyGuard, IMaster {

    uint public proposalDuration;
    uint public memberQuantity;

    mapping(bytes32 => MetricInfo) public metrics;

    mapping(address => OracleInfo) public oracles;

    mapping(address => bool) public community; 

    mapping(bytes32 => mapping(address => bool)) public votes; 

    OracleProposal[] public OracleProposals;
    MemberProposal[] public MemberProposals;

    address[] public communityMembers;

    constructor(address[] memory _initMembers, uint _proposalDuration) {
        for(uint i = 0; i < _initMembers.length; i++) {
            community[_initMembers[i]] = true;
            communityMembers.push(_initMembers[i]);
            memberQuantity += 1;
        }
        proposalDuration = _proposalDuration;
    }

    function setOracleKarma(address _oracle, KarmaState _state) external {
        address sender = msg.sender;
        require(community[sender], 'You are not a member of the community');
        OracleInfo storage oracleInfo = oracles[_oracle];
        require(oracleInfo.karmaStates[sender] != _state, "The state is already set");
        if(_state == KarmaState.Good) {
            oracleInfo.karmaStates[sender] == KarmaState.Bad ? oracleInfo.ResultKarma += 2 : oracleInfo.ResultKarma += 1;
        } else if (_state == KarmaState.Bad) {
            oracleInfo.karmaStates[sender] == KarmaState.Default ? oracleInfo.ResultKarma -= 1 : oracleInfo.ResultKarma -= 2;
        } else {
            oracleInfo.karmaStates[sender] == KarmaState.Good ? oracleInfo.ResultKarma -= 1 : oracleInfo.ResultKarma += 1;
        }
        oracleInfo.karmaStates[sender] = _state;
        if (int((memberQuantity / 2)) < -oracleInfo.ResultKarma) {
            if(!oracleInfo.ban) oracleInfo.ban = true;
        } else {
            if(oracleInfo.ban) oracleInfo.ban = false;
        }
    }

    function setOracleLabel(string memory _label) external {
        address sender = msg.sender;
        require(!_isEmptyString(_label), 'The label cannot be empty');
        oracles[sender].label = _label;
    }

    function setMetricLabels(string[] memory _metricNames, string[] memory _metricLabels) external {
        address sender = msg.sender;
        require(_metricNames.length == _metricLabels.length, 'Arrays do not match in length');
        for(uint i = 0; i < _metricNames.length; i++) {
            bytes32 metricId = _stringToHash(_metricNames[i]);
            require(metrics[metricId].oracle == sender, 
                string(
                    abi.encodePacked(
                        "'",
                        _metricNames[i],
                        "' the name doesn't belong to you"
                    )
                )
            );
            metrics[metricId].label = _metricLabels[i];
        }
    }
 
    function becomeOracle(
        string[] calldata _metricNames, 
        TypeMetric[] calldata _metricTypes,
        string calldata _description
    ) external nonReentrant {
        address sender = msg.sender;
        uint endTime = block.timestamp + proposalDuration;
        OracleProposal memory currentProposal;
        require(!_isEmptyString(oracles[sender].label), "First set the oracle label");
        require(_metricNames.length == _metricTypes.length, "Arrays do not match in length");
        require(_metricNames.length > 0, "Empty array");
        currentProposal.votingId = keccak256(abi.encodePacked(sender, endTime));
        currentProposal.description = _description;
        currentProposal.oracle = sender;
        currentProposal.endTime = endTime;
        currentProposal.metricNames = new string[](_metricNames.length);
        currentProposal.metricTypes = new TypeMetric[](_metricNames.length);
        for(uint i = 0; i < _metricNames.length; i++) {
            require(_metricTypes[i] != TypeMetric.Unknown, "Invalid metric type");
            require(metrics[_stringToHash(_metricNames[i])].oracle == address(0), string(
                abi.encodePacked(
                    "'",
                    _metricNames[i],
                    "' already in use"
                )
            ));
            currentProposal.metricNames[i] = _metricNames[i];
            currentProposal.metricTypes[i] = _metricTypes[i];
        }
        OracleProposals.push(currentProposal);
    }

    function voteForOracle(uint _id) external {
        address sender = msg.sender;
        uint currentTime = block.timestamp;
        require(community[sender], 'You are not a member of the community');
        OracleProposal storage proposal = OracleProposals[_id];
        require(proposal.endTime >= currentTime, 'Time is over');
        require(!votes[proposal.votingId][sender], 'You already voted');
        proposal.support += 1;
        votes[proposal.votingId][sender] = true;
    }
    
    function finishOracleVoiting(uint _id) external {
        OracleProposal memory proposal = OracleProposals[_id];
        uint currentTime = block.timestamp;
        require(proposal.endTime <= currentTime, 'Time is not over yet');
        _removeOracleProposal(_id, OracleProposals);
        if (_isMoreThanHalf(memberQuantity, proposal.support)) {
            for(uint i = 0; i < proposal.metricNames.length; i++) {
                bytes32 metricId = _stringToHash(proposal.metricNames[i]);
                if(metrics[metricId].oracle == address(0)) {
                    metrics[metricId].oracle = proposal.oracle;
                    metrics[metricId].typeMetric = proposal.metricTypes[i];
                    metrics[metricId].name = proposal.metricNames[i];
                    oracles[proposal.oracle].allMetrics.push(proposal.metricNames[i]);
                }
            }
        }
    }

    function becomeMember() external nonReentrant {
        address sender = msg.sender;
        uint endTime = block.timestamp + proposalDuration;
        require(!community[sender], 'Sender is already a member of the community');
        MemberProposal memory currentProposal;
        currentProposal.votingId = keccak256(abi.encodePacked(sender, endTime));
        currentProposal.member = sender;
        currentProposal.endTime = endTime;
        MemberProposals.push(currentProposal);
    }

    function voteForMember(uint _id) external {
        address sender = msg.sender;
        uint currentTime = block.timestamp;
        require(community[sender], 'You are not a member of the community');
        MemberProposal storage proposal = MemberProposals[_id];
        require(proposal.endTime >= currentTime, 'Time is over');
        require(!votes[proposal.votingId][sender], 'You already voted');
        proposal.support += 1;
        votes[proposal.votingId][sender] = true;
    }

    function finishMemberVoiting(uint _id) external {
        MemberProposal memory proposal = MemberProposals[_id];
        uint currentTime = block.timestamp;
        require(proposal.endTime <= currentTime, 'Time is not over yet');
        _removeMemberProposal(_id, MemberProposals);
        if (_isMoreThanHalf(memberQuantity, proposal.support) && !community[proposal.member]) {
            community[proposal.member] = true;
            communityMembers.push(proposal.member);
            memberQuantity += 1;
        }
    }

    function getMetricaInfo(bytes32 _metricId) external view returns(MetricInfo memory) {
        return metrics[_metricId];
    }

    function getOracleInfo(address _oracle) external view returns(string[] memory, string memory, int, bool) {
        OracleInfo storage oracleInfo = oracles[_oracle];
        return (oracleInfo.allMetrics, oracleInfo.label, oracleInfo.ResultKarma, oracleInfo.ban);
    }

    function getMetricNamesByProposalId(uint _id) external view returns(string[] memory) { 
        return OracleProposals[_id].metricNames;
    }

    function getOracleByMetricId(bytes32 _metricId) external view returns(address) {
        address oracle = metrics[_metricId].oracle; 
        return oracles[oracle].ban ? address(0) : oracle;
    }

    function getLengthOracleProposals() external view returns(uint) {
        return OracleProposals.length;
    }

    function getLengthMemberProposals() external view returns(uint) {
        return MemberProposals.length;
    }

    function getOracleProposals() external view returns(OracleProposal[] memory) {
        return OracleProposals;
    }

    function getMemberProposals() external view returns(MemberProposal[] memory) {
        return MemberProposals;
    }

    function getCommunityMembers() external view returns(address[] memory) {
        return communityMembers;
    } 

    function _removeOracleProposal(uint _id, OracleProposal[] storage _array) private {
        require(_id < _array.length, "index out of bound");
        for (uint i = _id; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }
        _array.pop();
    }
     
    function _removeMemberProposal(uint _id, MemberProposal[] storage _array) private {
        require(_id < _array.length, "index out of bound");
        for (uint i = _id; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }
        _array.pop();
    }

    function _stringToHash(string memory _parameter) private pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked(_parameter));
    }

    function _isMoreThanHalf(uint _total, uint _target) private pure returns(bool) {
        uint half = _total / 2;
        return _target > half;
    }

    function _isEmptyString(string memory _string) private pure returns(bool){
        return bytes(_string).length == 0;
    }
}