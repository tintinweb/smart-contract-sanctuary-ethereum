/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

pragma solidity ^0.5.17;

contract Todo {
    struct Task {
        string text;
        string status;
    }
    mapping(address => Task[]) public task;
    address public owner;

    constructor() public {
      //run one time after deploy
      owner = msg.sender;
    }

    function lentask() public view returns (uint) {
        return task[msg.sender].length;
    }

    function addtask(string memory _text) public {
        task[msg.sender].push(Task(_text,"doing"));
    }

    function edittask(uint256 index,string memory _text) public {
        require(keccak256(bytes(task[msg.sender][index].status)) == keccak256(bytes("doing")),"The status is not 'doing'.");
        task[msg.sender][index].text = _text;
        task[msg.sender][index].status = "doing";
    }

    function deletetask(uint256 index) public {
        task[msg.sender][index].status = "delete";
    }

    function donetask(uint256 index) public {
        require(keccak256(bytes(task[msg.sender][index].status)) == keccak256(bytes("doing")),"The status is not 'doing'.");
        task[msg.sender][index].status = "done";
    }

    function redoingtask(uint256 index) public {
        require(keccak256(bytes(task[msg.sender][index].status)) == keccak256(bytes("done")),"The status is not 'done'.");
        task[msg.sender][index].status = "doing";
    }

    function destroytask(uint256 index) public {
        require(keccak256(bytes(task[msg.sender][index].status)) == keccak256(bytes("delete")),"The status is not 'delete'.");
        delete task[msg.sender][index];
    }
}