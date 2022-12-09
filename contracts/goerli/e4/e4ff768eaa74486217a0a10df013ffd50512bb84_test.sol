/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
// 20220928
pragma solidity 0.8.0;
contract test {

    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
    }

    poll [] Polls;

    struct user {
        string name;
        string[] poll_list; // 내가만든 안건
        mapping(string => bool) voted; // 내가 투표한 안건에 대한 찬반 
    }
    
    mapping(address => user) users; 

    // 안건만들기
    function setPoll(string memory _title, string memory _contents) public {
        Polls.push(poll(Polls.length+1, _title, _contents, msg.sender, 0, 0)); // Polls의 poll을 추가
        users[msg.sender].poll_list.push(_title); // 키값인 주소와 연결된 user의 구조체로 들어가서 그안에 poll_list라는 배열에 _title이라는 값을 넣겟다
    }

    function getPoll(uint _a) public view returns(uint, string memory, string memory, address, uint, uint) {
        return (Polls[_a-1].number, Polls[_a-1].title, Polls[_a-1].contents, Polls[_a-1].by, Polls[_a-1].agree, Polls[_a-1].disag);
    }

    function setUser(string memory _name) public {
        users[msg.sender].name = _name;
    }


    function getUser() public view returns(string memory, uint) {
        return(users[msg.sender].name, users[msg.sender].poll_list.length); // 유저의 이름과, 유저가 만든 안건배열 길이

    }

    function getUser2(string memory _a) public view returns(bool) {
        return users[msg.sender].voted[_a]; // 내가 안건에대해 어떻게 투표했는가를 보여주는 함수
    }

    function getPollall() public view returns(poll[] memory) {
        return Polls;
    }

    // 찬반투표기능
    function vote(string memory _title, bool _b) public { // 숫자가아닌 문자, 주소면 매핑으로관리
        for(uint i; i<Polls.length; i++)  {
           if(keccak256(bytes(Polls[i].title)) == keccak256(bytes(_title))) {
                   // Polls의 i번째(0부터 배열의 길이까지 순회)에 title을 받아서 내가 입력한 타이틀이랑 맞는지 확인
               if(_b == true) {
                   Polls[i].agree++;
                   users[msg.sender].voted[_title] = true; // 
               } else {
                   Polls[i].disag++;
                   users[msg.sender].voted[_title] = false;
               }
           }
        
        }
    }
}



// 안건을 올리고 이에 대한 찬성과 반대를 할 수 있는 기능을 구현하세요. 안건은 번호, 제목, 내용, 제안자 그리고 찬성자 수와 반대자 수로 이루어져 있습니다.(구조체)

// 안건들을 모아놓은 array도 같이 구현하세요. 각 안건의 현재상황(찬,반 투표수)을 알려주는 함수를 구현하세요.

// 사용자는 자신의 이름과 자신이 만든 안건 그리고 자신이 투표한 안건과 어떻게 투표했는지(찬/반)에 대한 정보로 이루어져 있습니다.(구조체)

// 투표는 누구나 할 수 있습니다. 투표하는 사람은 제목으로 검색하고 투표를 할 수 있습니다. 제목과 의사표현을 입력값으로 구현하세요.

// 아래는 추가문제입니다. 위의 기본문제를 모두 해결한 후에 시간이 남는다면 구현해주세요.

// +1) 한번 투표한 안건에는 중복으로 투표할 수 없도록 하세요. (기존의 자료구조를 변경시켜도 됩니다.)

// +2) 안건의 투표자가 10명 이상이며 찬성 비율이 70% 이상이면 안건이 통과되도록, 이하면 기각되도록 구현하세요. (추가 배열 등을 구현하셔도 됩니다.)
// 09:35까지입니다