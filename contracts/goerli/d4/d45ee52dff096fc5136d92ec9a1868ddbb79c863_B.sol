/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

contract B {
    enum Status{voting, pass, cancel}   //안건 통과, 기각을 위해 추가가
    struct poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
        Status status;
        mapping(address => bool) isVote;
    }

    mapping(string => poll) Polls;
    uint index;

    struct user {
        string name;
        string[] poll_list; 
        mapping(string => bool) voted; 
    }

    mapping(address => user) users;

    function setPoll(string memory _title, string memory _contents) public {
        //Polls[_title] = poll(index++, _title, _contents, msg.sender, 0,0, Status.voting); -> mapping(address => bool) isVote 추가로 밑에 형식으로 디폴트값 주는 방식 변경
        Polls[_title].number = index++;
        Polls[_title].title = _title;
        Polls[_title].contents = _contents;
        Polls[_title].by = msg.sender;
        // Polls[_title].agree = 0;
        // Polls[_title].disag = 0;
        Polls[_title].status = Status.voting;

        users[msg.sender].poll_list.push(_title); 
    }

    // poll의 정보 받아오기
    function getPoll(string memory _title) public view returns(uint, string memory, string memory, address, uint, uint, Status) {
        return (Polls[_title].number, Polls[_title].title, Polls[_title].contents, Polls[_title].by, Polls[_title].agree, Polls[_title].disag, Polls[_title].status);
    }

    // user 설정
    function setUser(string memory _name) public {
        users[msg.sender].name = _name; // users라는 매핑에 msg.sender를 key 값으로 주고 _name을 value값으로 설정
    }

   
    function getUser() public view returns(string memory, uint) {
       
        return (users[msg.sender].name, users[msg.sender].poll_list.length);
    }

    function getUser2(string memory _a) public view returns(bool) {
        return users[msg.sender].voted[_a];
    }

    function vote(string memory _title, bool _b) public {
        // 입력한 _title과 각 요소의 title이 일치하는지 확인
        if(keccak256(bytes(Polls[_title].title)) == keccak256(bytes(_title))) { 
            require(!Polls[_title].isVote[msg.sender], "already voted");   //한번 투표한 안건에는 중복으로 투표할 수 없도록 하세요.

            Polls[_title].isVote[msg.sender] = true;    //투표처리
            if(_b == true) {
                // Polls array의 i번 요소의 poll 구조체 내 agree에 숫자 1 추가
                Polls[_title].agree++;
                
                users[msg.sender].voted[_title] = true; 
            } else {
                Polls[_title].disag++;
                users[msg.sender].voted[_title] = false;
            }
        } 

        VoteDone(_title);   //투표시마다 총 개수 체크해서 10개일떄 실행
    }

    // + 안건의 투표자가 10명 이상이며 찬성 비율이 70% 이상이면 안건이 통과되도록, 이하면 기각되도록 구현하세요.
    function VoteDone(string memory _title) private {
        uint total = Polls[_title].agree + Polls[_title].agree;
        if(total < 10) return;
        if(Polls[_title].agree * 100 / total < 70) Polls[_title].status = Status.cancel;
        else Polls[_title].status = Status.pass;
    }
}