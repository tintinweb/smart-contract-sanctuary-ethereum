/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

pragma solidity ^0.8.0;

contract QnaBoard {

    enum Status{post, cancel, process, done} 

    uint index;

    struct Post {
        uint no;
        string title;
        string content;
        address creator;
        Status status;
        mapping(address => string) reply;
    }

    // Post[] Posts;
    mapping(uint => Post) Posts;
    
    //질문작성
    function post(string memory _title, string memory _content) public payable {
        require(msg.value==200000000000000000);

        index = index+1;

        Posts[index].no = index;
        Posts[index].title = _title;
        Posts[index].title = _content;
        Posts[index].creator = msg.sender;
        Posts[index].status = Status.post;
    }

    //질문 확인
    function getPost(uint _no) public returns(uint, string memory, string memory) {
        return (Posts[_no].no, Posts[_no].title, Posts[_no].content);
    }

    //취소
    function cancelPost(uint _no) public {
        require (Posts[_no].creator == msg.sender);
        require (Posts[_no].status == Status.post);
        Posts[index].status == Status.cancel;
    }


    //답변
    function reply(uint _no, string memory _title, string memory _content) public payable {
        require(msg.value==100000000000000000);
        require(msg.sender!= Posts[_no].creator );
        Posts[_no].reply[msg.sender] = _content;

        //상태변경
        Posts[_no].status == Status.process;

    }

    //답변채택
    function choice(uint _no, address _replier) public {
        require (Posts[_no].creator == msg.sender);
        Posts[_no].reply[_replier]; // 0.125eth 돌려받는 주소
        Posts[_no].status == Status.done; //상태변경
    }

    //충전하기 




}