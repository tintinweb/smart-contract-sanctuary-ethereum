/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity 0.8.0;

contract A {
    enum Status {registered, voting, passed, failed}

    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
        address[] voters;
        Status status;
    }

    poll[] Polls;

    struct user {
        string name;
        string[] poll_list; // 내가 올린 안건
        mapping(string => bool) voted; // 문제
    }

    mapping(address => user) users;

    function setPoll(string memory _title, string memory _contents) public {
        Polls.push(poll(Polls.length+1, _title, _contents, msg.sender, 0, 0, new address[](0), Status.registered)); // Polls에 poll을 새로 추가
        // users는 mapping으로 설정. 지갑주소를 key 값으로 넣으면 value값으로 user 구조체가 반환
        users[msg.sender].poll_list.push(_title); // user 구조체 안에 poll_list에 추가하는 코드
    }

    // poll의 정보 받아오기
    function getPoll(uint _a) public view returns(poll memory) {
        return (Polls[_a-1]);
    }

		// poll 전체 받아오기
    function getPollAll() public view returns(poll[] memory) {
        return Polls;
    }

    // user 설정
    function setUser(string memory _name) public {
        users[msg.sender].name = _name; // users라는 매핑에 msg.sender를 key 값으로 주고 _name을 value값으로 설정
    }

    // user 정보 받아오기, 자기 지갑과 연결된 정보 받아오기
    function getUser() public view returns(string memory, uint) {
        // users 매핑에 msg.sender를 key 값으로 주고 name과 poll_list의 길이(poll_list.length)를 output값으로 설정
        return (users[msg.sender].name, users[msg.sender].poll_list.length);
    }

    function getUser2(string memory _a) public view returns(bool) {
        return users[msg.sender].voted[_a];
    }

    function vote(string memory _title, bool _b) public {
        //Polls의 전 요소들을 1개씩 훑어보는 for 문
        for(uint i; i<Polls.length;i++) {
            // 입력한 _title과 각 요소의 title이 일치하는지 확인
            if(keccak256(bytes(Polls[i].title)) == keccak256(bytes(_title))) { //title과 _title 비교, string은 직접 비교가 아닌 hash값으로
                // 안건의 상태가 투표중이거나 등록된 상태여야 함.
                require(Polls[i].status == Status.voting || Polls[i].status == Status.registered);
                // 중복 투표 확인
                for(uint j; j<Polls[i].voters.length; j++) {
                    if(Polls[i].voters[j] == msg.sender) {
                        break;
                    } else {
                        // "투표중"으로 상태 변화
                        Polls[i].status = Status.voting;
                        // 비교 후 통과하면 찬반여부 판단
                        // 찬성이면 
                        if(_b == true) {
                            // Polls array의 i번 요소의 poll 구조체 내 agree에 숫자 1 추가
                            Polls[i].agree++;
                            // user도 자신이 투표한 안건의 결과 데이터를 업데이트 해야함. users mapping을 address로 타고 들어가 user 구조체 내 voted mapping을 건드림.
                            users[msg.sender].voted[_title] = true;  // voted는 string과 bool로 구성(key -value), _title을 key값으로 넣고 _b를 value 값으로 넣음.
                            // 투표자 명단에 msg.sender 추가
                            Polls[i].voters.push(msg.sender);
                        } else {
                            Polls[i].disag++;
                            users[msg.sender].voted[_title] = false;
                            Polls[i].voters.push(msg.sender);
                        }
                    }
                }
                
            } 
        }
    } // function vote()

    function finish(string memory _title) public returns(Status) {
        //Polls의 전 요소들을 1개씩 훑어보는 for 문
        for(uint i; i<Polls.length;i++) {
            // 입력한 _title과 각 요소의 title이 일치하는지 확인
            if(keccak256(bytes(Polls[i].title)) == keccak256(bytes(_title))) { //title과 _title 비교, string은 직접 비교가 아닌 hash값으로
                // 안건의 상태가 투표중이거나 등록된 상태여야 함.
                require(Polls[i].status == Status.voting || Polls[i].status == Status.registered);

                // 안건의 투표자가 10명 이상이며 찬성 비율이 70% 이상이면
                if(Polls[i].agree + Polls[i].disag >= 10 && (100 * Polls[i].agree) / Polls[i].agree + Polls[i].disag >= 70) {
                    Polls[i].status = Status.passed; // 안건 통과
                } else {
                    Polls[i].status = Status.failed; // 안건 기각
                }
                return Polls[i].status;
            }
        }     
    }
}