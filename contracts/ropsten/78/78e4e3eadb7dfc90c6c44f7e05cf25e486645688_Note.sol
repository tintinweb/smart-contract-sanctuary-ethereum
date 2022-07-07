/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity ^0.8.10;

contract Note {
    address public immutable owner = msg.sender;

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner.");
        _;
    }

    function rand() private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % 10000000000;
    }

    struct _Note {
        uint id;
        uint timestamp;
        string content;
    }

    struct Commit {
        uint timestamp;
        string content;
    }

    _Note[] private notes;
    mapping(uint => Commit[]) private commits;

    function add(string memory content) public onlyOwner {
        notes.push(_Note({
            id: rand(),
            timestamp: block.timestamp,
            content: content
        }));
    }

    function del(uint id) public onlyOwner {
        for (uint i = 0; i < notes.length; i++) {
            if (notes[i].id == id) {
                notes[i] = notes[notes.length - 1];
                notes.pop();
                break;
            }
        }
    }

    function all() public view onlyOwner returns(_Note[] memory) {
        return notes;
    }

    function addCommit(uint id, string memory content) public onlyOwner {
        commits[id].push(Commit({
            timestamp: block.timestamp,
            content: content
        }));
    }

    function delCommit(uint id, uint timestamp) public onlyOwner {
        uint len = commits[id].length;
        for (uint i = 0; i < len; i++) {
            if (commits[id][i].timestamp == timestamp) {
                commits[id][i] = commits[id][len - 1];
                commits[id].pop();
                break;
            }
        }
    }

    function allCommit(uint id) public view onlyOwner returns(Commit[] memory) {
        return commits[id];
    }
}