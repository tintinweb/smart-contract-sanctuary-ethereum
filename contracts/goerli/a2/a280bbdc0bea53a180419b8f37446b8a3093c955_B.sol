/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract B {
    enum PollStatus { on, passed, failed }
    struct Poll {
        uint number;
        string title;
        string contents;
        address by;
        uint agree;
        uint disag;
        PollStatus status;
    }

    mapping(string => Poll) pollMap;
    uint index;

    struct User {
        string name;
        string[] poll_list; 
        mapping(string => uint) voted; 
    }

    mapping(address => User) userMap;

    function setPoll(string memory _title, string memory _contents) public {
        pollMap[_title] = Poll(index++, _title, _contents, msg.sender, 0,0, PollStatus.on);
        userMap[msg.sender].poll_list.push(_title); 
    }

    function getPoll(string memory _title) public view returns(uint, string memory, string memory, address, uint, uint) {
		return (pollMap[_title].number, pollMap[_title].title, pollMap[_title].contents, pollMap[_title].by, pollMap[_title].agree, pollMap[_title].disag);
    }

    function setUser(string memory _name) public {
        userMap[msg.sender].name = _name;
    }

    function getUser() public view returns(string memory, uint) {
        return (userMap[msg.sender].name, userMap[msg.sender].poll_list.length);
    }

    function getUser2(string memory _title) public view returns(string memory) {
        if(userMap[msg.sender].voted[_title] == 1){
            return 'pass';
        }else if(userMap[msg.sender].voted[_title] == 2){
            return 'fail';
        }else {
            return 'not voted';
        }
        
    }

    function vote(string memory _title, bool _b) public {
        require(pollMap[_title].status == PollStatus.on);
        require(userMap[msg.sender].voted[_title] < 1);
        if(keccak256(bytes(pollMap[_title].title)) == keccak256(bytes(_title))) { 
            if(_b == true) {
                pollMap[_title].agree++;
                userMap[msg.sender].voted[_title] = 1; // 찬성은 1 저장
            } else {
                pollMap[_title].disag++;
                userMap[msg.sender].voted[_title] = 2; // 반대는 2 저장
            }
        } 
    }

    function endVote(string memory _title) public returns(bool){
        require(pollMap[_title].by == msg.sender);
        require(pollMap[_title].status == PollStatus.on);
        require(pollMap[_title].agree + pollMap[_title].disag >= 10);

        uint ratio = pollMap[_title].agree * 100 / (pollMap[_title].agree + pollMap[_title].disag);
        if(ratio < 70){
            pollMap[_title].status = PollStatus.failed;
            return false;
        }else{
            pollMap[_title].status = PollStatus.passed;
            return true;
        }
    }
}