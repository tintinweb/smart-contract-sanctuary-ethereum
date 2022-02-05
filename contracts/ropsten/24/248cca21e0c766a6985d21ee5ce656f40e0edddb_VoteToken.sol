/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract VoteToken {
    struct vote{
        address voterAddress;
        uint voterPower;
        bool choice;
    }

    struct voter {
        address voterAddress;
        uint voterPower;
        bool voted;
    }

    address public contractOwner;
    address public maxIApprovedAddress;
    address public maxDisAddress;

    // tokenId => totalVote => vote (struct)
    mapping(uint => mapping(address => vote)) private votes;
    // tokenId => address => voter (struct)
    mapping(uint => mapping(address => voter))public voterRegister;
    // tokenId => total // 투표 참여한 인원수
    mapping(uint => uint) public tokenTotalVote;
    // tokenId => total // 투표 승인한 인원수
    mapping(uint => uint) public tokenTotalVoteResult;
    // 투표 찬반 전체
    mapping(uint => uint) public tokenYesNoVoteTotal;
    // tokenId => state
    mapping(uint => State) public currentTokenState;
    enum State { Created, Voting, Ended }
    State public state;

    // events
    event AgreeOrDisAgree(address indexed addr, bool result);
    event totalPower(uint indexed total);
    //modifiers

    modifier onlyOwner(){
        require(msg.sender == contractOwner);
        _;
    }

    modifier inState(uint _tokenId, State _state) {
        require(currentTokenState[_tokenId] == _state);
        _;
    }

    //functions
    constructor() {
        contractOwner = msg.sender;
    }
    function addVoter(address _voterAddress, uint _voterPower, uint _tokenId) public inState(_tokenId, State.Created) onlyOwner {
        voter memory v;
        v.voterAddress = _voterAddress;
        v.voterPower = _voterPower;
        v.voted = false;
        voterRegister[_tokenId][_voterAddress] = v;
        if(tokenTotalVote[_tokenId] == 0){
            tokenTotalVote[_tokenId] = 1;
        } else {
            tokenTotalVote[_tokenId]++; // 투표에 참여하는 총 인원
        }
    }

    function initialState(uint _tokenId) public onlyOwner payable{
        currentTokenState[_tokenId] = State.Created;
    }

    function startState(uint _tokenId) public inState(_tokenId, State.Ended) onlyOwner {
        currentTokenState[_tokenId] = State.Created;
    }

    function  startVote(uint _tokenId) public inState(_tokenId, State.Created) onlyOwner{
        currentTokenState[_tokenId] = State.Voting;
    }
    function doVote(uint _tokenId, uint _voterPower, bool _choice) public inState(_tokenId, State.Voting) returns(bool voted){
        bool found = false;

        if(voterRegister[_tokenId][msg.sender].voterAddress != address(0x0) && !voterRegister[_tokenId][msg.sender].voted) {
            voterRegister[_tokenId][msg.sender].voted = true;
            vote memory v;
            v.voterAddress = msg.sender;
            v.voterPower = _voterPower;
            v.choice = _choice;
            if(_choice == true) {
                if(tokenTotalVoteResult[_tokenId] == 0){
                    tokenTotalVoteResult[_tokenId] = 1;
                } else {
                    tokenTotalVoteResult[_tokenId]++;
                }
            }


            votes[_tokenId][msg.sender] = v;
            if(tokenYesNoVoteTotal[_tokenId] == 0) {
                tokenYesNoVoteTotal[_tokenId] = 1;
            } else {
                tokenYesNoVoteTotal[_tokenId]++;
            }
            found = true;

        }
        return found;
    }
    function endVote(uint _tokenId, address [] memory allUsersAddress) public inState(_tokenId, State.Voting) onlyOwner returns(bool){
        currentTokenState[_tokenId] = State.Ended;
        uint approvedTotalPower = 0;
        uint maxApprovedPower = 0;
        uint disapprovedTotalPower = 0;
        uint maxDisPower = 0;
        bool maxApprovedChoice;
        bool maxDisChoice;



        for(uint i = 0; i < tokenTotalVote[_tokenId]; i++) {

            if(votes[_tokenId][allUsersAddress[i]].choice == true) {
                approvedTotalPower += votes[_tokenId][allUsersAddress[i]].voterPower;
                if(votes[_tokenId][allUsersAddress[i]].voterPower > maxApprovedPower ) {
                    maxApprovedPower = votes[_tokenId][allUsersAddress[i]].voterPower;
                    maxIApprovedAddress = allUsersAddress[i];
                    maxApprovedChoice = true;
                }
            } else {
                disapprovedTotalPower += votes[_tokenId][allUsersAddress[i]].voterPower;
                if(votes[_tokenId][allUsersAddress[i]].voterPower > maxDisPower) {
                    maxDisPower = votes[_tokenId][allUsersAddress[i]].voterPower;
                    maxDisAddress = allUsersAddress[i];
                    maxDisChoice = false;
                }
            }
        }

        uint total = tokenTotalVote[_tokenId];
        for (uint i = 0; i < total; i++) {
            delete votes[_tokenId][allUsersAddress[i]];
            delete voterRegister[_tokenId][allUsersAddress[i]];

        }
        delete tokenTotalVote[_tokenId];
        delete tokenTotalVoteResult[_tokenId];
        delete tokenYesNoVoteTotal[_tokenId];
        if(approvedTotalPower >= disapprovedTotalPower) {
            bool result = votes[_tokenId][maxIApprovedAddress].choice;
            emit AgreeOrDisAgree(maxIApprovedAddress, maxApprovedChoice);
            emit totalPower(approvedTotalPower);
            return result;
        } else {
            bool result = votes[_tokenId][maxDisAddress].choice;
            emit AgreeOrDisAgree(maxDisAddress, maxDisChoice);
            emit totalPower(disapprovedTotalPower);
            return result;
        }
    }

    function getTotalVote(uint _tokenId) public view returns(uint) {
        return tokenYesNoVoteTotal[_tokenId];
    }
    function check(uint _tokenId, address _userAddress) public view returns(bool) {
        return votes[_tokenId][_userAddress].choice;
    }
}