/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

pragma solidity ^0.8.7;


contract BlaizePassport {

    struct Person {
        string firstName;
        string secondName;
        string governmentId;
        bool verified;
    }

    address public owner;
    uint public taskNo ;
    mapping(address => Person) public persons;
    
    // event userAdded(string task) ;
    // event userVerified(string task);

    constructor() {
        owner = msg.sender ; 
    }

    function register(string memory firstName, string memory secondName, string memory governmentId) public {
        persons[msg.sender] = Person(firstName, secondName, governmentId, false);
    }

    function getUser(address _addr) public view returns (Person memory) {
        return persons[_addr];
    }

    // modifier onlyOwner() {
    //     require(msg.sender==owner, "caller is not owner") ;
    //     _; 
    // } 

    // function addTask(string calldata _task, uint _taskNo) public onlyOwner {
    //     taskNo = _taskNo ;
    //     Tasks[taskNo] = _task ;
    //     completedTask[taskNo] = false ;
    //     emit taskAdded(_task);
    // }

    // function completeTask(uint _taskNo ) public onlyOwner {
    //     taskNo = _taskNo ;
    //     completedTask[taskNo] = true ;
    //     string memory task_ = Tasks[taskNo] ;
    //     emit taskCompleted(task_);
    // }

    // function getTask(uint _taskNo) public view returns(string memory task){
    //     return Tasks[_taskNo] ;
    // }
}