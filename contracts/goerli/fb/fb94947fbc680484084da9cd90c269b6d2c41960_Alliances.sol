/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface IBalances{
    function _joinToAlliance(address _who, uint _landId)external;
}

interface INuclear{
    function _createAllianceCheck(address _who, uint _landId)external;
}

interface ILands{
    function _resultWar(address _winner)external;

    function ownerLandSupply(address _who)external view returns(uint);  

    function warNow()external view returns(bool);  
}

contract Alliances { 
    uint public totalSupply;
    uint private totalProposals;
    uint public allianceWinner;
    uint private allianceWinnerPower;
    uint private constant residenceTimeToVote = 1 minutes;
    uint private constant proposalLifeTime = 1 minutes;
    uint private memberWinnerLostPower;
    bool public warResultingStatus;
    address public memberWinner;
    address private lands;
    address private balances;
    address private nuclear;
    mapping(address => bool) private roleCall;
    mapping(address => mapping(uint => bool)) private memberVoted;
    mapping(uint => uint) private alliancePower;
    mapping(address => uint) private memberPower;
    mapping(address => uint) private memberLostPower;
    mapping(address => bool) public memberStatus;
    mapping(address => uint) public allianceStatus;
    mapping(address => uint) private memberResidenceStart;
    mapping(uint => mapping (address => bool)) private allianceMember;

    event allianceCreated(address indexed _who, uint _allianceId, uint _time);
    event joinedToAlliance(address indexed _who, uint indexed _allianceId, uint _time);
    event abandonedAlliance(address indexed _who, uint  indexed _allianceId, uint _time);

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "3x00");
        _;
    }

    modifier warTime(){
        bool _war = ILands(lands).warNow();
        require (_war == false, "3x01");
        require (warResultingStatus == false, "3x01");
        _;
    }

    modifier allianceExist(uint _id){
        require (_id < totalSupply, "3x02");
        _;
    }

    modifier proposalExist(uint _id){
        require (_id < totalProposals, "3x03");
        _;
    }

    constructor (){
        roleCall[msg.sender] = true;
    }

    Alliance[] public alliances;
    Proposal[] public proposals;

    struct Alliance {
        uint id;
        string name;
        uint members;
        uint lands;
    }

    struct Proposal {
        uint id;
        uint alliance;
        string name;
        address aimToKick;
        uint startTime;
        uint confirmations;
        uint endTime;
        bool ended;
        bool executed;
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function setAddresses(address _lands, address _balances, address _nuclear)external onlyRole(msg.sender){
        lands = _lands;
        balances = _balances;
        nuclear = _nuclear;
    }

    function createAlliance(string memory _name, uint _landId)external warTime(){
        require (memberStatus[msg.sender] == false, "3x04");
        address _who = msg.sender;
        if (totalSupply > 0 ) {
            INuclear(nuclear)._createAllianceCheck(_who, _landId);
        }
        uint _lands = ILands(lands).ownerLandSupply(msg.sender);
        Alliance memory alliance = Alliance(totalSupply, _name, 1, _lands); 
        alliances.push(alliance);        
        memberStatus[msg.sender] = true;
        allianceStatus[msg.sender] = totalSupply;
        allianceMember[totalSupply][_who] = true;
        totalSupply += 1;
        memberResidenceStart[msg.sender] = block.timestamp;

        emit allianceCreated(_who, totalSupply - 1, block.timestamp);
        emit joinedToAlliance(_who, totalSupply - 1, block.timestamp);
    }

    function joinToAlliance(uint _allianceId, uint _landId)external warTime() allianceExist(_allianceId){
        require (memberStatus[msg.sender] == false, "3x04");
        require (_allianceId > 0, "3x05");
        address _who = msg.sender;
        IBalances(balances)._joinToAlliance(_who, _landId);
        alliances[_allianceId].members += 1;
        uint _lands = ILands(lands).ownerLandSupply(_who);
        alliances[_allianceId].lands += _lands;
        memberStatus[_who] = true;
        allianceStatus[_who] = _allianceId;
        allianceMember[_allianceId][_who] = true;
        memberResidenceStart[_who] = block.timestamp;

        emit joinedToAlliance(_who, _allianceId, block.timestamp);
    }

    function abandonAlliance()external warTime() allianceExist(allianceStatus[msg.sender]){
        require (memberStatus[msg.sender] == true, "3x06");
        address _who = msg.sender;
        _kickFromAlliance(_who);        
    }

    function createProposal(address _aimToKick, uint _allianceId)external warTime() allianceExist(_allianceId){
        require (memberStatus[msg.sender] == true, "3x06");
        require (memberStatus[_aimToKick] == true, "3x07");
        require (allianceStatus[msg.sender] == _allianceId, "3x08");
        require (allianceStatus[_aimToKick] == _allianceId, "3x09");
        require (block.timestamp >= (memberResidenceStart[msg.sender] + residenceTimeToVote), "3x10");
        require (block.timestamp >= (memberResidenceStart[_aimToKick] + residenceTimeToVote), "3x11");
        require (allianceMember[_allianceId][msg.sender] == true, "3x12");
        require (allianceMember[_allianceId][_aimToKick] == true, "3x13");
        Proposal memory proposal = 
        Proposal(
            totalProposals, 
            _allianceId, 
            "Kick player", 
            _aimToKick, 
            block.timestamp, 
            1,
            block.timestamp + proposalLifeTime,
            false,
            false 
        ); 
        proposals.push(proposal);
        memberVoted[msg.sender][totalProposals] = true;
        totalProposals += 1;
    }
        
    function confirmProposal(uint _id)external warTime() allianceExist(proposals[_id].alliance) proposalExist(_id){
        require (memberStatus[msg.sender] == true, "3x06");
        require (allianceStatus[msg.sender] == proposals[_id].alliance, "3x08");
        require (block.timestamp >= (memberResidenceStart[msg.sender] + residenceTimeToVote), "3x10");
        require (allianceMember[proposals[_id].alliance][msg.sender] == true, "3x12");
        require (proposals[_id].ended == false, "3x14");
        require (memberVoted[msg.sender][_id] == false, "3x15");
        proposals[_id].confirmations += 1;
        memberVoted[msg.sender][_id] = true;
        if (block.timestamp >= proposals[_id].endTime) {
            proposals[_id].ended = true;
        }
        if (proposals[_id].confirmations >= (alliances[proposals[_id].alliance].members / 2)){
            proposals[_id].endTime = block.timestamp;
            proposals[_id].ended = true;
            proposals[_id].executed = true;
            _kickFromAlliance(proposals[_id].aimToKick);        
        }
    }

    function warResult()external onlyRole(msg.sender){
        alliances[allianceStatus[memberWinner]].lands += 1;
        ILands(lands)._resultWar(memberWinner);
        warResultingStatus = false;   
        alliancePower[allianceStatus[memberWinner]] = 0;
        memberPower[memberWinner] = 0;
        memberLostPower[memberWinner] = 0;
        allianceWinner = 0;
        allianceWinnerPower = 0;
        memberWinnerLostPower = 0;
        memberWinner = address(0);
    }

    function _kickFromAlliance(address _who)internal warTime() allianceExist(allianceStatus[_who]){
        uint _allianceId = allianceStatus[_who];
        alliances[_allianceId].members -= 1;
        uint _lands = ILands(lands).ownerLandSupply(_who);
        alliances[_allianceId].lands -= _lands;
        memberStatus[_who] = false;
        allianceStatus[_who] = 0;
        allianceMember[_allianceId][_who] = false;

        emit abandonedAlliance(_who, _allianceId, block.timestamp);
    }

    function _finishWar()external onlyRole(msg.sender){
        warResultingStatus = true;
    }

    function _joinToWar(address _who, uint _shipPower)external onlyRole(msg.sender){
        require (memberStatus[_who] == true, "3x06");
        alliancePower[allianceStatus[_who]] += _shipPower;
        memberPower[_who] += _shipPower;
        if (alliancePower[allianceStatus[_who]] > allianceWinnerPower) {
            allianceWinnerPower = alliancePower[allianceStatus[_who]];
            allianceWinner = allianceStatus[_who];
        }
    }

    function _returnShipFromWar(address _who, uint _lostPower)external onlyRole(msg.sender){
        if (allianceStatus[_who] == allianceWinner){
            memberLostPower[_who] += _lostPower;
            if (memberLostPower[_who] > memberWinnerLostPower) {
                memberWinnerLostPower = memberLostPower[_who];
                memberWinner = _who;
            }
        } else {
            alliancePower[allianceStatus[_who]] = 0; 
            memberPower[_who] = 0;
        }
    } 

    function _changeNumberOfLands(address _seller, address _buyer)external onlyRole(msg.sender){
        alliances[allianceStatus[_seller]].lands -= 1;
        alliances[allianceStatus[_buyer]].lands += 1;
    }
}