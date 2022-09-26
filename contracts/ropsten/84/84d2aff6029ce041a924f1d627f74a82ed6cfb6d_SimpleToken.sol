/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

// 이더리움에서의 오버플로, 언더플로에 대한 오류 방지 -> 이더리움에서는 가스비를 이용해 자동으로 판단
// 프로그래밍 상에서 가스비로 해당 함수의 실행이 실패되는 경우를 자동으로 예외 처리
library SafeMath {
  	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256) {
	    uint256 c = a / b;
		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

// 관리자만 사용할 수 있는 함수, public으로 공개된 함수 중, 관리자만 접근 가능한 함수
abstract contract OwnerHelper { // 추상 컨트랙트 : contract, interface 기능 모두 포함, 실제 contract에서 사용하지 않는다면 추상으로 표시되어 사용하지 않음
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

    struct Voting {
        address Candidate; // 후보자
        address Dismsissal; // 해임 대상
        VoteResult voteResult; // 투표 결과 상태
    }

    // 전체 투표
    Voting _voting;

    //관리자가 세명인지 아닌지 검사 : 세 명일 경우 해임 대상이 있어야 하고 세 명 미만일 경우 해임 대상 불필요
    function ownerGroupLengthCheck() view private returns (bool){
        if(_ownerGroup.length >=3) return false;
        else return true;
    }

    modifier ownerUnderThree() {
        require(ownerGroupLengthCheck(),"ownerGroup Length Over 3! Please use Function recommandCandidateWithDismissal");
        _;
    }

    modifier ownerOverThree() {
        require(!ownerGroupLengthCheck(),"ownerGroup Length Under 3! Please use Function recommandOnlyCandidate");
        _;
    }


    // 관리자 그룹 안에 있는지 조회
    function ownerGroupInclude(address _candidate) view private returns (bool){
        for(uint i=0;i<_ownerGroup.length;i++) {
            if(_ownerGroup[i].addr == _candidate) return true;
        }
        return false;
    }
    modifier ownerGroupNotInCheck(address _candidate) {
        require(!ownerGroupInclude(_candidate),"Already Candidate Includes OwnerGroup");
        _;
    }

    modifier onlyOwner(address _sender) {
        require(ownerGroupInclude(_sender), "Not Includes OwnerGroup! Permission Denied");
        _;
    }



    // 해임자 없이 관리자만 추천 : 제안자는 관리자 그룹에 존재, 후보자는 ownerGroup에 없어야 하고 관리자 그룹은 세 명미만이여야 함.
    function recommandOnlyCandidate(address _candidate) public onlyOwner(msg.sender) ownerGroupNotInCheck(_candidate) ownerUnderThree() {
        // 후보자가 이미 있는 경우 투표가 이미 시작한 경우 필터
        require(_voting.voteResult != VoteResult.STATUS_PENDING,"Already Voting is in progress");

        //투표 시작
        _voting  = Voting({
            Candidate : _candidate,
            Dismsissal : address(0x00),
            voteResult : VoteResult.STATUS_PENDING 
        });

    }

    // 해임자와 관리자만 추천 : 제안자는 관리자 그룹에 존재, 후보자는 ownerGroup에 없어야 하고 해임자는 ownerGroup에 있어야 함 + 관리자 그룹은 세명 이상이어야 함
    function recommandCandidateWithDismissal(address _candidate, address _target) public onlyOwner(msg.sender) ownerGroupNotInCheck(_candidate) ownerOverThree() {
        //해임자는 ownerGroup에 있어야 함
        require(ownerGroupInclude(_target), "Dismissed Person Not In OwnerGroup");

        // 후보자가 이미 있는 경우 투표가 이미 시작한 경우 필터
        require(_voting.voteResult != VoteResult.STATUS_PENDING,"Already Voting is in progress");


        //투표 시작
        _voting  = Voting({
            Candidate : _candidate,
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

    //관리자 개인 투표 : 투표자는 관리자 그룹에 존재, 유효한 투표(찬,반)해야 되고 현재 투표가 진행중이어야 함
    function ownerVoting (Vote _vote) public onlyOwner(msg.sender) isVaildVote(_vote) votingIsVaild() {

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


    //개표 : 개표 요청 또한 OwnerGroup에 속한 사람만 가능, 개표 요청 시 모든 관리자들이 투표를 마친 상태여야 함
    function requestBallotCounting() public onlyOwner(msg.sender) ownerFinishVoting() {
        uint agree = 0; // 찬성
        uint disagree = 0; // 반대

        for(uint i=0;i<_ownerGroup.length;i++) {
            if(_ownerGroup[i].vote == Vote.agree) {
                agree++;
            } else {
                disagree++;
            }
        }

        //찬성이 더 많을 경우 관리자로 등록
        if(agree >= disagree) {
            Owner memory _toBeOwner = Owner({
                addr : _voting.Candidate,
                vote : Vote.disagree,
                voteStatus : VoteStatus.STATUS_NOT_VOTED
            });
            _ownerGroup.push(_toBeOwner);

            //해임 대상이 존재할 경우, 해임까지
            if(_voting.Dismsissal != address(0x00)) {
                for(uint i=0;i<_ownerGroup.length;i++) {
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

        } 

        //_voting 초기화
        _voting.Candidate = address(0x00);
        _voting.voteResult = VoteResult.STATUS_END;
        _voting.Dismsissal = address(0x00);

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

    // 관리자 배열 리턴
  	function ownerGroup() public view virtual returns (Owner [] memory) {
		return _ownerGroup;
  	}
}



interface ERC20Interface { // 함수의 형태만 선언하고 함수의 내용은 SimpleToken 컨트랙트에서 사용
    // 해당 스마트 컨트랙트 기반 ERC-20 토큰의 총 발행량 확인
    function totalSupply() external view returns (uint256);

    // owner가 가지고 있는 토큰 보유량 확인
    function balanceOf(address account) external view returns (uint256);

    // 토큰을 전송
    function transfer(address recipient, uint256 amount) external returns (bool);

    // 여기서부터는 owner가 토큰을 양도할만큼 등록해두고, 필요할 때 제삼자를 통해 토큰을 양도할 수 있다.
    //spender가 제삼자
    // spender에 value 만큼의 토큰을 인출할 권리를 부여, 이 함수를 이용할 때는 반드시 Approval 이벤트 함수를 호출해야 함
    // owner의 토큰 창고에서 인출할 수 있는 토큰 수량 제한 기능도(함수 오작동과 자금 탈취 위험 방지)
    function approve(address spender, uint256 amount) external returns (bool);

    // owner가 spender에 양도 설정한 토큰의 양 확인
    function allowance(address owner, address spender) external view returns (uint256);

    // speneder가 거래할 수 있도록 양도받은 토큰을 전송(판매)
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}

contract SimpleToken is ERC20Interface, OwnerHelper {
    using SafeMath for uint256; // SafeMath 라이브러리 사용 선언(uint256에 대한)

    mapping (address => uint256) private _balances; // balanceof : 해당 주소가 보유한 토큰 수 
    mapping (address => mapping (address => uint256)) public _allowances; // approve : 양도

    uint256 public _totalSupply; // 토큰 총량
    string public _name; // 토큰 이름(ex. MySimpleToken)
    string public _symbol; // 토큰 기호(ex. MST)
    uint8 public _decimals; // 사용자 표현에 사용되는 소수 자릿수
    uint private E18 = 1000000000000000000; // 1ether - > wei
    bool public _tokenLock; // 토큰의 전체 락에 대한 처리
    mapping (address => bool) public _personalTokenLock; // 토큰 개인 락에 대한  : 초기값 false 따라서 false가 잠금 상태여야 함

    constructor(string memory getName, string memory getSymbol) {
      _name = getName;
      _symbol = getSymbol;
      _decimals = 18;
      _totalSupply = 100000000e18;
      _balances[msg.sender] = _totalSupply;
      _tokenLock = false; //초기 토큰 전체 락(주소가 아닌 토큰에 대한 락)
      _personalTokenLock[msg.sender] = true; // 관리자의 토큰 락은 열어놔야 개인 락 제거 가능
    }


    // 전체 락과 보내는 사람의 락을 검사하여 확인
    function isTokenLock(address from, address to) public view returns (bool lock) {
        lock = true; // 초기 잠금 해제(default)

        if(_tokenLock == false) // 전체 토큰에 대한 잠금 상태
        {
             lock = false;
        }

        if(_personalTokenLock[from] == false || _personalTokenLock[to] == false) { // 계정에 대한 토큰 잠금 상태
             lock = false;
        }
    }

    // 전체 락 제거(관리자만 실행 가능: OwnerHelper - onlyOwner)
    function removeTokenLock() onlyOwner(msg.sender) public {
        require(_tokenLock == false); // 잠금 상태면
        _tokenLock = true; // 잠금 해제
    }

    // 전체 락 (관리자만 실행 가능: OwnerHelper - onlyOwner)
    function TokenLock() onlyOwner(msg.sender) public {
        require(_tokenLock == true); // 잠금 해제 상태면
        _tokenLock = false; // 다시 잠금
    }

    // 개인 락 제거(관리자만 실행 가능: OwnerHelper - onlyOwner)
    function removePersonalTokenLock(address _who) onlyOwner(msg.sender) public {
        require(_personalTokenLock[_who] == false); //락이 되어있으면 
        _personalTokenLock[_who] = true; // 해제
    }

    // 개인 락(관리자만 실행 가능: OwnerHelper - onlyOwner)
    function PersonalTokenLock(address _who) onlyOwner(msg.sender) public {
        require(_personalTokenLock[_who] == true); //락 해제이 되어있으면 
        _personalTokenLock[_who] = false; // 다시 잠금
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //토큰의 총발행량을 반환
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    // _balances 에서 입력한 address인 account가 가지고 있는 토큰의 수 반환
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount); // 조건 체크(보내는 사람의 주소, 받는 사람의 주소, 충분한 양의 토큰) 및 토큰 양 관리
        emit Transfer(msg.sender, recipient, amount); // Transfer 이벤트 실행
        return true;
    }

    // transfer 조건 체크 및 토큰 양 관리
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address"); // sender가 유효한 주소인지
        require(recipient != address(0), "ERC20: transfer to the zero address"); // resipient가 유효한 주소인지
        require(isTokenLock(sender, recipient) == true, "TokenLock: invalid token transfer"); // 보내는 사람과 받는 사람 중 락이 걸려있는지 확인
        uint256 senderBalance = _balances[sender];  // sender가 보유한 토큰 
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance"); // 의 양이 amount(보낼 양)보다 적은지
        // 위의 조건이 충족된다면
        _balances[sender] = senderBalance.sub(amount); // sender의 보유 토큰 양에서 보낼 토큰 양 빼고 + SafeMath를 활용한 메모리 이상 방지
        _balances[recipient] += _balances[recipient].add(amount); // recipent의 보유 토큰에서 받는 토큰 양 더하고 + SafeMath를 활용한 메모리 이상 방지
    }

    // spender에 value 만큼의 토큰을 인출할 권리를 부여, 이 함수를 이용할 때는 반드시 Approval 이벤트 함수를 호출해야 함
    // amount spender가 owner로부터 amount 한도 하에 여러 번 출금하는 것을 허용 이 한도가 amount
    function approve(address spender, uint amount) external virtual override returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];  //msg.sender가 spender에게 양도 한도 기록 변수 초기화
        require(_balances[msg.sender] >= amount,"ERC20: The amount to be transferred exceeds the amount of tokens held by the owner."); // msg.sender 보유 토큰 유효성 검사
        _approve(msg.sender, spender, currentAllowance, amount); // 조건 체크 및 msg.sender가 spender에게 양도 한도를 allowances에 기록
        return true;
    }

    // 조건 체크 및 msg.sender가 spender에게 양도할 값을 allowances에 기록 (실제 양도 X)    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address"); // owner 주소 유효성 검사
        require(spender != address(0), "ERC20: approve to the zero address"); // spender 주소 유효성 검사
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount"); //msg.sender(owner)가 spender에게 양도 기록 한도 스토리지 유효성 검사
        _allowances[owner][spender] = amount;  // msg.sender(owener)가 spender에게 양도한 기록 스토리지에 양도 한도 기록
        emit Approval(owner, spender, currentAmount, amount); // Approval 이벤트 실행
    }

    // approve를 통해 기록한 owner가 spender에게 설정한 한도를 반환
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // 양도를 수행하는 거래 대행자(msg.sender)가 sender가 허락해 준 값만큼 상대방(recipent)에게 토큰을 이동
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        //transfer : 전송
        _transfer(sender, recipient, amount); 
        emit Transfer(msg.sender, sender, recipient, amount); 

        // _approve를 통해 allowance 기록 : 양도한 기록 스토리지 업데이트
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance - amount);
        return true;
    }



}