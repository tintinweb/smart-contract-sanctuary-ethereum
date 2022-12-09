/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity ^0.8.0;
// 매핑 대체 버전
contract B {
    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
        PollStatus pollStatus;
    }

    enum PollStatus {ing ,pass, fail}

    // poll[] Polls;
    mapping(string => poll) Polls; // 매핑으로 대체
    uint index;
    
    struct user {
        string name;
        string[] poll_list; // 내가 올린 안건
        mapping(string => uint) voted; // 투표 ( 찬성1, 반대2 )

    }

    mapping(address => user) users;

    function setPoll(string memory _title, string memory _contents) public {
        Polls[_title] = poll(index++, _title, _contents, msg.sender, 0,0, PollStatus.ing);
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

    function getUser2(string memory _a) public view returns(uint) {
        return users[msg.sender].voted[_a];
    }

    function vote(string memory _title, bool _b) public {
        // 진행중인 투표인가?
        require(Polls[_title].pollStatus == PollStatus.ing);
        // 한번 투표한 안건에는 중복으로 투표 불가능
        require(users[msg.sender].voted[_title]==0);

        // 입력한 _title과 각 요소의 title이 일치하는지 확인 (for 문은 이제 필요 없음)
        if(keccak256(bytes(Polls[_title].title)) == keccak256(bytes(_title))) { //title과 _title 비교, string은 직접 비교가 아닌 hash값으로
            // 비교 후 통과하면 찬반여부 판단
            // 찬성이면 
            if(_b == true) {
                // Polls array의 i번 요소의 poll 구조체 내 agree에 숫자 1 추가
                Polls[_title].agree++;
                // user도 자신이 투표한 안건의 결과 데이터를 업데이트 해야함. users mapping을 address로 타고 들어가 user 구조체 내 voted mapping을 건드림.
                users[msg.sender].voted[_title] = 1; 
            } else {
                Polls[_title].disag++;
                users[msg.sender].voted[_title] = 2;
            }
        }


    }

    // 안건의 투표자가 10명 이상이며 찬성 비율이 70% 이상이면 안건이 통과되도록, 이하면 기각되도록 구현하세요
    function endVote(string memory _title) public {

        uint totalPollCount = Polls[_title].agree + Polls[_title].disag;
        //총 투표수 10건 이상만
        require(totalPollCount>=10);
        
        uint agreeRate = Polls[_title].agree*10/totalPollCount;
        if(agreeRate>=7) {
            Polls[_title].pollStatus = PollStatus.pass;
        }else{
            Polls[_title].pollStatus = PollStatus.fail;
        }
    }


}