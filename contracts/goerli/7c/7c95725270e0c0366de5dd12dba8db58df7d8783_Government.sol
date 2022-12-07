/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

contract Government {

    enum Status{regist, voting, ok, cancel}

    struct bankUser{
        address adr;
        string name;
        uint amount;
        address bankAdr;
        uint vote;
    }
    //Bank bk;
    mapping(address => bankUser) public users;

    //안건
    struct item  {
        uint num;
        address writer;
        string title;
        string content;
        uint agree;
        uint disagree;
        Status status;
        uint registtime;
    }

    mapping(string => item) items;

    uint globalidx;
    function doRegit(string memory _title, string memory _content) public {
        require(users[msg.sender].amount >= 1);

        items[_title].num = globalidx+1;
        items[_title].writer = msg.sender;
        items[_title].title = _title;
        items[_title].content = _content;
        items[_title].status = Status.regist;
        items[_title].registtime = block.timestamp;

        //users[msg.sender].amount -= 0.25;
    }

    function Vote(string memory _title, bool agree) public {
        require(block.timestamp <= items[_title].registtime + 5 minutes);

        if(agree) items[_title].agree++;
        else items[_title].agree--;
    }
}