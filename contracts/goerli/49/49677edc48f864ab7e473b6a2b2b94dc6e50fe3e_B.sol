/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract A {
    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
    }

    poll[] Polls;

    struct user {
        string name;
        string[] poll_list; // 내가 올린 안건
        mapping(string => bool) voted; // 문제
    }

    mapping(address => user) users;

    function setPoll(string memory _title, string memory _contents) public {
        Polls.push(poll(Polls.length+1, _title, _contents, msg.sender, 0, 0)); // Polls에 poll을 새로 추가
        // users는 mapping으로 설정. 지갑주소를 key 값으로 넣으면 value값으로 user 구조체가 반환
        users[msg.sender].poll_list.push(_title); // user 구조체 안에 poll_list에 추가하는 코드
    }

    // poll의 정보 받아오기
    function getPoll(uint _a) public view returns(uint, string memory, string memory, address, uint, uint) {
        return (Polls[_a-1].number, Polls[_a-1].title, Polls[_a-1].contents, Polls[_a-1].by, Polls[_a-1].agree, Polls[_a-1].disag);
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
                // 비교 후 통과하면 찬반여부 판단
                // 찬성이면 
                if(_b == true) {
                    // Polls array의 i번 요소의 poll 구조체 내 agree에 숫자 1 추가
                    Polls[i].agree++;
                    // user도 자신이 투표한 안건의 결과 데이터를 업데이트 해야함. users mapping을 address로 타고 들어가 user 구조체 내 voted mapping을 건드림.
                    users[msg.sender].voted[_title] = true;  // voted는 string과 bool로 구성(key -value), _title을 key값으로 넣고 _b를 value 값으로 넣음.
                } else {
                    Polls[i].disag++;
                    users[msg.sender].voted[_title] = false;
                }
            } 
        }
    }
}

// 매핑 대체 버전
contract B {
    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
    }

    poll[] public PassedPools;
    poll[] public DroppedPools;

    // poll[] Polls;
    mapping(string => poll) Polls; // 매핑으로 대체
    uint index;

    struct user {
        string name;
        string[] poll_list; // 내가 올린 안건
        mapping(string => bool) voted; // 문제
        mapping(string => bool) whetherToVote;
    }

    mapping(address => user) users;

    function setPoll(string memory _title, string memory _contents) public {
        Polls[_title] = poll(index++, _title, _contents, msg.sender, 0,0);
        // users는 mapping으로 설정. 지갑주소를 key 값으로 넣으면 value값으로 user 구조체가 반환
        users[msg.sender].poll_list.push(_title); // user 구조체 안에 poll_list에 추가하는 코드
    }

    // poll의 정보 받아오기
    function getPoll(string memory _title) public view returns(uint, string memory, string memory, address, uint, uint) {
        // 매핑으로 대체되어 _title로 바로 검색
				return (Polls[_title].number, Polls[_title].title, Polls[_title].contents, Polls[_title].by, Polls[_title].agree, Polls[_title].disag);
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
        // 입력한 _title과 각 요소의 title이 일치하는지 확인 (for 문은 이제 필요 없음)
        if(keccak256(bytes(Polls[_title].title)) == keccak256(bytes(_title))) { //title과 _title 비교, string은 직접 비교가 아닌 hash값으로
            // 비교 후 통과하면 찬반여부 판단
            // 찬성이면 
            require(!users[msg.sender].whetherToVote[_title]);
            if(_b == true) {
                // Polls array의 i번 요소의 poll 구조체 내 agree에 숫자 1 추가
                Polls[_title].agree++;
                // user도 자신이 투표한 안건의 결과 데이터를 업데이트 해야함. users mapping을 address로 타고 들어가 user 구조체 내 voted mapping을 건드림.
                users[msg.sender].voted[_title] = true;  // voted는 string과 bool로 구성(key -value), _title을 key값으로 넣고 _b를 value 값으로 넣음.
            } else {
                Polls[_title].disag++;
                users[msg.sender].voted[_title] = false;
            }
            users[msg.sender].whetherToVote[_title]=true;

            }

        }

    function passPolls(string memory _title)public{

        if(keccak256(bytes(Polls[_title].title)) == keccak256(bytes(_title))){

            uint all = Polls[_title].agree+Polls[_title].disag;
        
            if(all>10 && 100*(Polls[_title].agree/all)>70) {
                PassedPools.push(Polls[_title]);
                delete Polls[_title];
            }else if(all>10){
            DroppedPools.push(Polls[_title]);
               delete Polls[_title];
            }
        }
    }


}
/*
실습과정
1 - user 등록 : A,B,C
2 - A 지갑으로 aa,bb,cc poll 등록
3 - B 지갑으로 각각 찬,반,찬 투표
4 - C 지갑으로 각각 찬,찬,찬 투표
5 - B,C 지갑으로 각각 getUser1,2 해보기
*/