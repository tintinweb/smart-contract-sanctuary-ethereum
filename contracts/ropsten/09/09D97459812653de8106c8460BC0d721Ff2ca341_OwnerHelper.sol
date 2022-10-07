/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

// 관리자만 사용할 수 있는 함수, public으로 공개된 함수 중, 관리자만 접근 가능한 함수
contract OwnerHelper { // 추상 컨트랙트 : contract, interface 기능 모두 포함, 실제 contract에서 사용하지 않는다면 추상으로 표시되어 사용하지 않음
  // 관리자가 변경되었을 때 주소와 새로운 관리자의 주소 로그를 남김
  	event OwnershipTransferred(address indexed preOwner, address indexed nextOwner); 
      
  	address private _theOwner; // 최초 관리자

    // 투표의 상태
    enum VoteStatus {
        STATUS_NOT_VOTED, STATUS_VOTED
    }

    // 각 관리자가 찬성, 반대 상태
    enum Vote {
        disagree, agree
    }

    // 투표 결과 상태
    enum VoteResult {
        STATUS_END, STATUS_PENDING
    }

    struct Voting {
        // address Candidate; // 후보자
        address Dismsissal; // 해임 대상
        VoteResult voteResult; // 투표 결과 상태
    }

    // 전체 투표
    Voting _voting;
    
    // 관리자 구조체
    struct Owner {
        address addr;  // 관리자 주소
        VoteStatus voteStatus; // 관리자 투표 상태
        Vote vote; // 관리자 투표 
    }

    // 관리자 배열 
    Owner [] _ownerGroup;

    // 이 계약을 배포한 사람은 최초 관리자가 됨
    constructor() { 
		_theOwner = msg.sender;
        // 관리자 배열에 넣고 기본값은 반대
        Owner memory _firstOwner = Owner({
            addr: _theOwner,
            vote: Vote.disagree,
            voteStatus: VoteStatus.STATUS_NOT_VOTED
        });
        _ownerGroup.push(_firstOwner);
  	}

    
    //관리자가 세명인지 아닌지 검사 : 세 명일 경우 해임 대상이 있어야 하고 세 명 미만일 경우 해임 대상 불필요
    //3명 이상일때 false
    function ownerGroupLengthCheck() view private returns (bool){
        if(_ownerGroup.length >=3) return false;
        else return true;
    }

    modifier ownerUnderThree() {
        require(ownerGroupLengthCheck(),"ownerGroup Length Over 3! Please use Function");
        _;
    }

    modifier ownerOverThree() {
        require(!ownerGroupLengthCheck(),"ownerGroup Length Under 3! Please use Function");
        _;
    }

    // 관리자 그룹 안에 있는지 조회
    // 관리자이면 true
    function ownerGroupInclude(address _candidate) view private returns (bool){
        for(uint i=0; i<_ownerGroup.length; i++) {
            if(_ownerGroup[i].addr == _candidate) return true;
        } return false;
    }

    modifier ownerGroupNotInCheck(address _candidate) {
        require(!ownerGroupInclude(_candidate),"Already Candidate Includes OwnerGroup");
        _;
    }

    modifier onlyOwner(address _sender) {
        require(ownerGroupInclude(_sender), "Not Includes OwnerGroup! Permission Denied");
        _;
    }

    //1) 관리자 추천
        //1. 제안자는 관리자 그룹에 존재, 
        //2. 후보자는 ownerGroup에 없어야 하고 
        //3. 관리자 그룹은 세 명미만이여야 함.
        //4. 투표 진행중이 아니어야함
    function recommandOnlyCandidate(address _candidate) public 
        onlyOwner(msg.sender) 
        ownerGroupNotInCheck(_candidate) 
        ownerUnderThree() {

        require(_voting.voteResult != VoteResult.STATUS_PENDING,"Already Voting is in progress");

        Owner memory _newOwner = Owner({
            addr: _candidate,
            vote: Vote.disagree,
            voteStatus: VoteStatus.STATUS_NOT_VOTED
        });

        _ownerGroup.push(_newOwner);
    }

    //2) 해임자 투표
        //1. 제안자는 관리자 그룹에 존재
        //2. 해임자는 ownerGroup에 존재(제안자가 스스로 해임가능)
        //3. 관리자 그룹은 세명 이상이어야 함
        //4. 투표중인 상태여야함
    function recommandCandidateWithDismissal(address _target) public 
        onlyOwner(msg.sender) 
        ownerOverThree() {

        //해임자는 ownerGroup에 있어야 함
        require(ownerGroupInclude(_target), "Dismissed Person Not In OwnerGroup");

        // 후보자가 이미 있는 경우 투표가 이미 시작한 경우 필터
        require(_voting.voteResult != VoteResult.STATUS_PENDING,"Already Voting is in progress");

        //투표 시작
        _voting  = Voting({
            // Candidate : _candidate,
            Dismsissal : _target,
            voteResult : VoteResult.STATUS_PENDING 
        });
    }

    //찬,반 유효성 검사
    modifier isVaildVote(Vote _vote) {
        require((_vote == Vote.agree) || (_vote == Vote.disagree));
        _;
    }

    //현재 투표가 진행 중인지 확인
    modifier votingIsVaild() {
        require(_voting.voteResult == VoteResult.STATUS_PENDING, "The vote is not in progress.");
        _;
    }

    //3) 관리자 개인 투표 
        //1. 투표자는 관리자 그룹에 존재, 
        //2. 유효한 투표(찬,반)해야 되고(무효표 불가)
        //3. 현재 투표가 진행중이어야 함
    function ownerVoting (Vote _vote) public 
        onlyOwner(msg.sender) 
        isVaildVote(_vote) 
        votingIsVaild() {

        //자신의 투표 상태와 투표를 바꿈
        for(uint i=0;i<_ownerGroup.length;i++) {
            if(msg.sender == _ownerGroup[i].addr) {
                _ownerGroup[i].vote = _vote;
                _ownerGroup[i].voteStatus = VoteStatus.STATUS_VOTED;
                break;
            }
        }
        
    }

    //개표 요청 전 모든 관리자가 투표를 마쳤어야 함
    function ownerFinishVotingCheck () private view returns (bool){
        for(uint i=0;i<_ownerGroup.length;i++) {
            //투표를 안한 놈 있으면 
            if(_ownerGroup[i].voteStatus != VoteStatus.STATUS_VOTED) {
                return false; // 안댐
            }
        }
        return true; // 다 투표 했을 경우 허가
    }

    // 관리자들이 투표를 마쳤는지 확인
    modifier ownerFinishVoting () {
        require(ownerFinishVotingCheck(),"Voting is still in progress");
        _;
    }

    //4) 개표
        //1. 개표 요청 또한 OwnerGroup에 속한 사람만 가능, 
        //2. 투표가 진행중인 상태
        //3. 개표 요청 시 모든 관리자들이 투표를 마친 상태여야 함
    function requestBallotCounting() public 
        onlyOwner(msg.sender) 
        ownerFinishVoting() {

        uint agree = 0; // 찬성
        uint disagree = 0; // 반대

        for(uint i=0;i<_ownerGroup.length;i++) {
            if(_ownerGroup[i].vote == Vote.agree) {
                agree++;
            } else {
                disagree++;
            }
        }

        //관반수 찬성시 해임
        if(agree >= disagree) {
            for(uint i=0; i<_ownerGroup.length; i++) {
                if(_voting.Dismsissal == _ownerGroup[i].addr) {
                    delete _ownerGroup[i];
                    //삭제 후 하나씩 당기기 : delete만 하면 0x00,0,0으로 남음
                    for(uint j=i;j<_ownerGroup.length-1;j++) {
                        _ownerGroup[j] = _ownerGroup[j+1];
                    }
                    //마지막값 pop
                    _ownerGroup.pop();
                    break;
                }   
            }
        } 

        //_voting 투표진행상태 초기화
        _voting.voteResult = VoteResult.STATUS_END;
        _voting.Dismsissal = address(0x00); //해임자

        //owner 투표 상태 및 투표 초기화
        for(uint i=0;i<_ownerGroup.length;i++) {
            _ownerGroup[i].voteStatus = VoteStatus.STATUS_NOT_VOTED;
            _ownerGroup[i].vote = Vote.disagree;
        }
    }

    // 투표(_voting) : 후보자 + 투표 결과 상태 리턴 
  	function votingStatus() public view virtual returns (Voting memory) {
		return _voting;
  	}

    // function sameAddress(address _candidate) public view returns (bool) {
	// 	if (msg.sender == _candidate) return true;
    //     else return false;
  	// }
    
    // function sender() public view returns (address) {
    //     return msg.sender;
  	// }

    // 관리자 배열 리턴
  	function ownerGroup() public view virtual returns (Owner [] memory) {
		return _ownerGroup;
  	}
}