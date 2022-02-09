/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// Credential : Issuer가 제기한 하나 이상의 Claim 집합.
// VC : 암호화된 검증을 생성할 수 있는 변조 방지 Credential.
// VP : VC를 사용하여 만들 수 도 있음. 

// 이 코드는 Issuer와 Credential을 포함.
// claimCredential 함수로 Credential을 발행하고,
// getCredential 함수를 통해 Credential을 발행한 주소에서 VC를 확인하는 구조.

abstract contract OwnerHelper {
    address private owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner, unicode"❗️ msg.sender가 owner가 아닙니다."); // msg.sender가 owner랑 맞는지 확인
		_;
  	}

  	constructor() { // 컨트랙트가 생성될 때 최초로 한 번만 실행
	    owner = msg.sender;
  	}

    // 컨트랙트의 소유권을 다른 주소에게 이전
  	function transferOwnership(address _to) onlyOwner public { 
        require(_to != owner);
        require(_to != address(0x0));
    	owner = _to;
    	emit OwnerTransferPropose(owner, _to);
  	}
}


// OwnerHelper(해당 컨트랙트 소유권 관리) 상속 
abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true, unicode"❗️ msg.sender가 Issuer가 아닙니다."); // 해당 호출자가 issuer가 맞는지 확인
        _;
    }

    constructor() { // 컨트랙트 생성시 최초 한 번만 실행
        issuers[msg.sender] = true; 
    }

    // 해당 주소(_addr)가 issuer인지 확인
    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    // Issuer를 추가. onlyOwner 제어자를 통해 해당 컨트랙트의 소유권을 가진 사람만 호출할 수 있도록 함.
    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false); // 추가하는건데 왜 true인지 검사하지 ? 
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    // Issuer를 삭제. onlyOwner 제어자를 통해 해당 컨트랙트의 소유권을 가진 사람만 호출할 수 있도록 함.
    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}


contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum; // 백신 종류. 어떤 종류의 백신을 맞았는지.
    uint8 vaccineCnt; // 백신 종류 개수


    // VC를 구현하기 위한 구조체.
    struct Credential{
        uint256 id; // index 순서를 표기하는 idCount.
        // address issuer; // 발급자. 검증 가능한 크리덴셜을 생성하며, 검증 가능한 크리덴셜을 보유자에게 전달하는 역할.
        string value; // 크리덴셜에 포함되어야 하는 암호화된 정보.
        mapping(uint8 => mapping(uint8 => uint256)) vaccineInfo;  // 백신 정보 mapping(n차 => (vaccineType => date) 구조)
        mapping(uint8 => address) vaccineIssuers; // issuer 정보(n차 => 해당 차수 issuer)
        uint8 lastVaccineNum;
    }

    struct Presentation{ // 예방 접종을 맞았는지 확인할 때 반환용
        address issuer;
        string vaccineType;
        uint8 vaccineNum; 
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "YC"; // 얀센
        vaccineEnum[1] = "MDN"; // 모더나
        vaccineEnum[2] = "HWZ"; // 화이자
        // vaccineEnum[3] = "AZ"; // 아스트라제네카
        vaccineCnt = 3;
    }

    // 이 함수를 통해 발급자(issuer)는 어떠한 주체(_humanAddress)에게 크리덴셜을 발행(claim) 가능하게 됌.
    function claimCredential(address _humanAddress, uint8 _vaccineNum, uint8 _vaccineType, string calldata _value) onlyIssuer public returns(bool){
        Credential storage credential = credentials[_humanAddress];
        require(credential.id == 0, unicode"❗️ 이전에 백신 증명서를 발급 받은 전적이 있습니다.");
        credential.id = idCount;
        credential.vaccineIssuers[_vaccineNum] = msg.sender;
        credential.value = _value;
        
        require(_vaccineNum == 1, unicode"❗️ n차 접종부터는 증명서 갱신 기능을 사용해주세요."); // 1차일때만 이거 발급할 수 있음(크리덴셜은 한 번만 발급 가능), 2차일때는 이미 발급된 게 있을거임.
        require(credential.vaccineInfo[_vaccineNum][_vaccineType] == 0, unicode"❗️ 이전에 백신 증명서를 발급 받은 전적이 있습니다.");
        credential.vaccineInfo[_vaccineNum][_vaccineType] = block.timestamp;
        credential.lastVaccineNum = 1;

        idCount += 1;

        return true;
    }

    // 어떤 주체(_humanAddress)가 발행한 크리덴셜을 확인할 수 있음.
    // mapping이 있는 구조체는 public으로 반환될 수 없는 것 같음.
    // function getCredential(address _humanAddress) public view returns (Credential memory){
    //     return credentials[_humanAddress];
    // }

    // 몇 차 접종에 대해 credential을 확인하고 싶은지 입력 -> 확인 후 구조체 리턴
    function checkVaccineCredential(address _humanAddress, uint8 _vaccineNum) public view returns(Presentation memory){
        require(credentials[_humanAddress].id != 0, unicode"❗️ 이전에 백신 증명서를 발급받은 전적이 없습니다."); // 백신을 맞은 적 있어야 함
        require(_vaccineNum <= credentials[_humanAddress].lastVaccineNum, unicode"❗️ 해당 차수의 백신 접종을 받은 적 없습니다."); // 확인하고자 하는 차수가 최종 접종 차수보다 크면 안됌.
        string memory vaccineType;

        for(uint8 i=0; i<vaccineCnt; i++){
            if(credentials[_humanAddress].vaccineInfo[_vaccineNum][i] != 0){
                vaccineType = getVaccineType(i);
                break;
            }
        }

        Presentation memory presentation = Presentation(
            credentials[_humanAddress].vaccineIssuers[_vaccineNum],
            vaccineType,
            _vaccineNum
        );

        return presentation;
    }
    

    function findVaccineType(address _humanAddress, uint8 _vaccineNum) public view returns(bool, uint8){
        for(uint8 i=0; i<vaccineCnt; i++){
            if(credentials[_humanAddress].vaccineInfo[_vaccineNum][i] != 0){
                return(true, i);
            }
        }
        return (false, vaccineCnt+1); // 일부러 존재할 수 없는 백신 타입 숫자를 넘겨줌
    }


    // VaccineType을 추가하는 함수.
    function addVaccineType(string calldata _vaccineType) onlyIssuer public returns (bool) {
        // 솔리디티에서 String을 검사하는 방법
        // 1. byte로 변환하여 길이로 null인지 확인하기
        // 2. keccak256 함수를 사용해 두 스트링을 해시로 변환하여 비교
        for(uint8 i=0; i<vaccineCnt; i++){ // 이미 vaccineEnum 안에 있는 백신 type인지 검사
            require(keccak256(bytes(_vaccineType)) != keccak256(bytes(vaccineEnum[i])), unicode"❗️ 이미 존재하는 백신 종류입니다.");
        }
        vaccineEnum[vaccineCnt] = _vaccineType;
        vaccineCnt++;
        return true;
    }

    // 번호에 해당하는 vaccine type 반환
    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    // n차 접종 후 credential 업데이트
    function updateCredential(address _humanAddress, uint8 _vaccineNum, uint8 _vaccineType, string calldata _value) onlyIssuer public returns(bool){
        require(credentials[_humanAddress].id != 0, unicode"❗️ 이전에 백신 증명서를 발급받은 전적이 없습니다."); // 이미 크레덴셜을 발급받은 적 있어야 함.
        require(_vaccineNum != 1, unicode"❗️ 올바른 접종 차수가 아닙니다."); // 꼭 n차 접종에 대한 정보를 업데이트 하는 것이어야 함.
        require(credentials[_humanAddress].lastVaccineNum == _vaccineNum-1, unicode"❗️ 올바른 접종 차수가 아닙니다."); // n-1차 접종을 맞은 이후여야 함
        require(_vaccineType < vaccineCnt, unicode"❗️ 올바른 백신 종류가 아닙니다."); // 기존에 존재하는 vaccine type number를 입력해야만 함
        credentials[_humanAddress].vaccineInfo[_vaccineNum][_vaccineType] = block.timestamp;
        credentials[_humanAddress].value = _value; // 암호화할 정보 업데이트
        credentials[_humanAddress].lastVaccineNum = _vaccineNum; // 최종 접종 차수 업데이트

        return true;
    }

}