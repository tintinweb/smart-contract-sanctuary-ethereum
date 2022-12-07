/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
// 20221207

pragma solidity 0.8.0;

contract VOTE {
    struct user {
        string name;
        uint depo;
        mapping(string => bool) voted;
    }

    struct poll {
        uint number;
        string title;
        string name;
        string contents;
        uint agree;
        uint disag;
        string state;
    }
    
    poll[] Polls;

    mapping(address => user) users;

    address payable bank;
    address payable tax;
}

    /*
    function setPoll(string memory _title, string memory _name, string memory _contents) public {
        Polls.push(poll(Polls.length+1, _title, _name, _contents, 0, 0, 0)); 
    }

    function getPoll(uint _a) public view returns(uint, string memory, string memory, address, uint, uint) {
        return (Polls[_a-1].number, Polls[_a-1].title, Polls[_a-1].name, Polls[_a-1].contents, Polls[_a-1].agree, Polls[_a-1].disag, Polls[_a-1].state);
    }

    function setUser(string memory _name) public {
        users[msg.sender].name = _name;
    }

    function getUser() public view returns(string memory, uint) {
        return (users[msg.sender].name, users[msg.sender].poll_list.length);
    }

    function getUser2(string memory _a) public view returns(bool) {
        return users[msg.sender].voted[_a];
    }
    
    function vote(string memory _title, bool _b) public {
        for(uint i; i<Polls.length;i++) {
            if(keccak256(bytes(Polls[i].title)) == keccak256(bytes(_title))) { 
                if(_b == true) {
                    Polls[i].agree++;
                    users[msg.sender].voted[_title] = true; 
                } else {
                    Polls[i].disag++;
                    users[msg.sender].voted[_title] = false;
                }
            } 
        }
    }
}
*/