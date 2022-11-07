/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.13;

contract EdContracts {
  
  uint public taskCount = 0;
  uint public userCount = 0;

  struct User {
    uint id;
    string email;
    uint rewardBalance;
  }

  struct Task {
    uint id;
    string content;
    string deadlineDate;
    string subject;
    string project;
    uint baselineGrade;
    uint rewardGrade;
    uint assignedGrade;
    uint reward;
    uint userid;
    bool completed;
  }

  mapping(uint => Task) public tasks;
  // mapping(string => mapping(uint => Task)) public  alldata;
  mapping(string => mapping(string => mapping(uint => Task))) public alldata;
  mapping(uint => User) public users;

// assign items to users and users to items

  Task[] public allTasks; // Necessario??
  User[] public allUsers;

  mapping (uint => uint[]) private userItemsIds;
  mapping (uint => uint) private itemIdToUser;
  
// Create user

  function createUser(string memory _email, uint _rewardBalance) public {
     userCount ++;
     users[userCount] = User(userCount, _email, _rewardBalance);
     User memory user = User(userCount, _email, _rewardBalance);
     allUsers.push(user);
  }

// Events
event UserCreated(
    uint id,
    string email,
    bool completed
  );

event TaskCreated(
    uint id,
    string content,
    bool completed
  );

  event TaskCompleted(
    uint id,
    bool completed
  );

// create new task - create all default tasks through this function - assignedGrade tem que ser sempre 0 aqui
  function createTask(string memory _content, string memory _deadlineDate, string memory _subject, string memory _project, uint _baselineGrade, uint _rewardGrade, uint _assignedGrade, uint _reward, uint _userid, bool _completed) public _ownerOnly {
    taskCount ++;
    tasks[taskCount] = Task(taskCount, _content, _deadlineDate, _subject, _project, _baselineGrade, _rewardGrade, _assignedGrade, _reward, _userid, false);
    Task memory task = Task(taskCount, _content, _deadlineDate, _subject, _project, _baselineGrade, _rewardGrade, _assignedGrade, _reward, _userid, false);
    allTasks.push(task);  
    userItemsIds[_userid].push(taskCount);
    itemIdToUser[taskCount] = _userid;
    emit TaskCreated(taskCount, _content, false);
  }

function createTaskwithemail(string memory _content, string memory _deadlineDate, string memory _subject, string memory _project, uint _baselineGrade, uint _rewardGrade, uint _assignedGrade, uint _reward, uint _userid, bool _completed , string memory mail) public _ownerOnly {
    taskCount ++;
    alldata[mail][_subject][taskCount] = Task(taskCount, _content, _deadlineDate, _subject, _project, _baselineGrade, _rewardGrade, _assignedGrade, _reward, _userid, false);
    Task memory task = Task(taskCount, _content, _deadlineDate, _subject, _project, _baselineGrade, _rewardGrade, _assignedGrade, _reward, _userid, false);
    allTasks.push(task);  
    userItemsIds[_userid].push(taskCount);
    itemIdToUser[taskCount] = _userid;
    emit TaskCreated(taskCount, _content, false);
  }

  address payable public owner;

  // Payable constructor can receive Ether
  constructor() payable {
    owner = payable(msg.sender);
  }


// see https://ethereum.stackexchange.com/questions/49812/how-can-i-create-a-modifier-that-requires-the-msg-sender-be-one-of-multiple-addr to have multiple owners that can update
  modifier _ownerOnly() {
    _;
    require(msg.sender == owner);
  }

    function getTaskId(uint _userid, uint _taskIndex) public view returns (uint){
      return userItemsIds[_userid][_taskIndex-1];
    }

    function getUserTaskInfo(uint _userid, uint _taskIndex) public view returns (Task memory){
      Task storage task = tasks[userItemsIds[_userid][_taskIndex-1]];
      return task;
    }

    function getTaskCount(uint _user) public view returns (uint){
      return userItemsIds[_user].length;
    } 

    // Para teste - sem fazer login de user

    function getTask(uint _taskIndex) public view returns (Task memory){
      Task storage task = tasks[_taskIndex];
      return task;
    }
      function getTaskwithmail(uint _taskIndex , string memory mail , string memory subject ) public view returns (Task memory){
      Task storage task = alldata[mail][subject][_taskIndex];
      return task;
    }



}