// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "UsersGroups.sol";
import "Bank.sol";

contract Blog {


    uint256 totalPostsNumber;
    UsersGroups roles;
    Bank bank;

    event PostAdded(uint _value);
    event PostUpdated(bool _value);
    
    // This is a comment!
    struct Posts {
        string hash;
        address account;
    }

    constructor (address roleContract, address payable bankContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
    }

    Posts[] public posts;
    mapping(address => Posts) peopleMap;

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyPost()
    {
        require(roles.isPost(msg.sender), "Restricted to posts.");
        _;
    }

    //add single post
    function addPost(string memory _hash, address payable _account)
    public
    onlyPost
    returns (uint256) {
        //address _account = msg.sender;
        posts.push(Posts(_hash, _account));
        totalPostsNumber++;
        uint _id= posts.length -1;
        bank.internaltransfer(_account,0.0001 ether);
        emit PostAdded(_id);
        return _id;
    }

    //total number of posts
    function getTotalPostsNumber()
    public
    view
    returns (uint256)  {
        return totalPostsNumber;
    }

    //change hash of single post
    function updateSinglePostHash(uint id,string memory _hash)
    public
    onlyPost {
        posts[id].hash =_hash;
        emit PostUpdated(true);
    }

    //delete single post
    function deleteSinglePost(uint _id)
    public
    onlyPost
    {
        //delete posts[_id];
        for(uint i = _id; i < posts.length-1; i++){
            posts[i] = posts[i+1];      
        }
        posts.pop();
    }

    //get hash to IPFS of single post
    function getSinglePostHash(uint256 id)
    public
    view
    returns (string memory) {
        return posts[id].hash;
    }
    

    //get account who created posts
    function getSinglePostAccount(uint256 id)
    public
    view
    returns (address) {
        return posts[id].account;
    }

    function getSinglePost(uint256 id)
    public
    view
    returns (  string memory, address) {
        return ( posts[id].hash, posts[id].account) ;
    }

    // return arrays of id and hash of all posts
    function getAllPosts()
    public
    view
    returns (Posts[] memory) {
        return posts;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Roles.sol";

contract UsersGroups {

  bytes32[] private static_group = [
    bytes32("Admin"),
    bytes32("DAO_EXECUTE"),
    bytes32("Bank"),
    bytes32("Integration"),
    bytes32("Member")
  ];

  event GroupAdd(bool status, string message,bytes32 group);
  event GroupRemove(bool status, string message,bytes32 group);
  event GroupCalculate(bool status, string message,bytes32 group);
  event GroupCalculateBlock(bool status, string message,uint256 timestamp);

  event UserAdd(bool status, string message,address user);
  event UserToGroupAdd(bool status, string message,address user,bytes32 group);
  event UserRemove(bool status, string message,address user);

  address private owner;
  Group[] private groups; 
  User[] private users;
  uint256 private UserCount=0;
  uint256 private GroupCount=0;

  mapping(address => mapping(bytes32 => bool)) userToGroupMap;
  mapping(address => bool) usersMap; 
  mapping(address => uint256) userIndex; 

  mapping(bytes32 => bool) groupsMap; 
  mapping(bytes32 => uint256) groupIndex; 
  mapping(bytes32 => address[]) groupToUserAddressMap; 

  struct Group {
      bytes32 group_name;
      uint256 current_balance;
      uint256 blocked_balance;
      uint256 timestamp_created;
      uint256 timestamp_last_integration;
  }

  struct User {
      address userID;
      uint256 current_balance;
      uint256 blocked_balance;
      uint256 timestamp_created;
      bool timestamp_status;
  }

  constructor (address _owner) public  {
    owner = _owner;
    addUser(owner);
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      addGroup(static_group[i]);
    }
    setUserToGroup(owner, static_group[0]);
    //addUser(owner);
    //setUserToGroup(owner, static_group[0]);
  }

  function initializer (address _owner) public {
    //owner = _owner;
    //addUser(owner);
    //addUser(msg.sender);

    static_group.push(keccak256("Admin"));
    static_group.push(keccak256("DAO_EXECUTE"));
    static_group.push(keccak256("Bank"));
    static_group.push(keccak256("Integration"));
    static_group.push(keccak256("Member"));

    //address user = msg.sender;
    //users.push(User(user,0 ,0,block.timestamp, false));
    //usersMap[user] = true;
    //userIndex[user] = UserCount;
    //userToGroupMap[user][keccak256("Member")] = true;
    //UserCount=UserCount+1;

    users.push(User(_owner,0 ,0,block.timestamp, false));
    usersMap[_owner] = true;
    userIndex[_owner] = UserCount;
    userToGroupMap[_owner][keccak256("Member")] = true;
    UserCount=UserCount+1;
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      groups.push(Group(static_group[i],0,0,block.timestamp,0));
      groupsMap[static_group[i]] = true;
      groupIndex[static_group[i]] = GroupCount;
      GroupCount=GroupCount+1;
    }

    userToGroupMap[_owner][static_group[0]]=true;
    groupToUserAddressMap[static_group[0]].push(_owner);

    //userToGroupMap[msg.sender][static_group[0]]=true;
    //groupToUserAddressMap[static_group[0]].push(msg.sender);
    
  }

  modifier onlyAdmin()
  {
    require((owner == msg.sender || isAdmin(msg.sender)), "Restricted to admins or owner.");
    _;
  }

  modifier onlyPost()
  {
    require((isPost(msg.sender)), "Restricted to posts.");
    _;
  }
  function ifUserExist(address user)
  public
  view
  returns (bool)
  {
    return usersMap[user];
  }

  function ifGroupExist(bytes32 group)
  public
  view
  returns (bool)
  {
    return groupsMap[group];
  }

  function ifUserHasGroup(address user,bytes32 group)
  internal
  view
  returns (bool)
  {
    if(!ifUserExist(user)||!ifGroupExist(group))
    {
      return false;
    }

    return userToGroupMap[user][group];
  }

  function getUser(address user)
  public
  view
  onlyAdmin
  returns (uint256,uint256,uint256,bool)
  {
    require(ifUserExist(user),"User not exist");
    return (users[userIndex[user]].current_balance,users[userIndex[user]].blocked_balance,users[userIndex[user]].timestamp_created,users[userIndex[user]].timestamp_status);
  }

  function getUserByIndex(uint256 _index)
  public
  view
  onlyAdmin
  returns (address)
  {
    return (users[_index].userID);
  }

  function getUserindex(address user)
  public
  view
  onlyAdmin
  returns (uint256)
  {
    require(ifUserExist(user),"User not exist");
    return userIndex[user];
  }

  function getUsers()
  public
  view 
  onlyAdmin
  returns (User[] memory)
  {
    return users;
  }

  function getUsersInGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (address[] memory)
  {
    return groupToUserAddressMap[group];
  }

  function getUsersCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return UserCount;
  }

  function getGroupsCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return GroupCount;
  }

  function getGroups()
  public
  view
  onlyAdmin
  returns (Group[] memory)
  {
    return groups;
  }

  function getGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (bytes32,uint256,uint256)
  {
    //require(ifGroupExist(group),"Group not exist");
    return (groups[groupIndex[group]].group_name,
    groups[groupIndex[group]].timestamp_created,
    groups[groupIndex[group]].timestamp_last_integration);
  }

  function addGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifGroupExist(group)){
      emit GroupAdd(false,"Group Exist.",group);
      return false;
    }
    groups.push(Group(group,0,0,block.timestamp,0));
    groupsMap[group] = true;
    groupIndex[group] = GroupCount;
    GroupCount=GroupCount+1;
    emit GroupAdd(true,"Group added successfully.",group);
    return true;
  }

  function removeGroup(bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {
    for(uint256 i=0;i<static_group.length;i++)
    {
      if(static_group[i] == group)
      {
        emit GroupRemove(false,"Group can't be removed.",group);
        return false;
      }
    }
    if(ifGroupExist(group))
    {
      
      for(uint256 i=0;i<users.length;i++)
      {
        if(ifUserHasGroup(users[i].userID,group))
        {
          emit GroupRemove(false,"Group has members, Please delete members from group.",group);
          return false;
        }
      }

      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        for(uint256 i=groupIndex[group];i<groups.length-1;i++)
        {
          groups[i]=groups[i+1];
          groupIndex[groups[i+1].group_name]=i;
        }
        groups.pop();
      }
        delete groupIndex[group];
        delete groupsMap[group];
        GroupCount=GroupCount-1;
        emit GroupRemove(false,"group removed successfully.",group);
        return true;
    }
    else
    {
      emit GroupRemove(false,"Group Not Exist.",group);
      return false;
    }
  }

  function addUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user)){
      emit UserAdd(false,"User Exist.",user);
      return false;
    }
    
    users.push(User(user,0,0,block.timestamp, false));
    usersMap[user] = true;
    userIndex[user] = UserCount;
    userToGroupMap[user][static_group[4]] = true;
    groupToUserAddressMap[static_group[4]].push(user);
    UserCount=UserCount+1;
    emit UserAdd(true,"User added successfully.",user);
    return true;
  }

  function removeUser(address user)
  public
  onlyAdmin
  returns (bool)
  {
    if(ifUserExist(user))
    {
      if(users.length== 1)
      {
        users.pop();
      }
      else
      {
        uint256 user_index = userIndex[user];
        for(uint256 i=user_index;i<users.length-1;i++)
        {
          users[i]=users[i+1];
          userIndex[users[i+1].userID]=i;
        }
        users.pop();
      }
        delete userIndex[user];
        delete usersMap[user];
        for(uint i=0;i<groups.length;i++){
          if(ifUserHasGroup(user,groups[i].group_name))
          {
            delete userToGroupMap[user][groups[i].group_name];
          }
        }
        
        UserCount=UserCount-1;
        emit UserRemove(false,"User removed.",user);
        return true;
    }
    else
    {
      emit UserRemove(false,"User Not Exist.",user);
      return false;
    }
  }

  function setUserToGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupAdd(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupAdd(false,"Group not Exist.",user,group);
      return false;
    }

    if(ifUserHasGroup(user,group))
    {
      emit UserToGroupAdd(false,"User is in group.",user,group);
      return false;
    }

    userToGroupMap[user][group]=true;
    groupToUserAddressMap[group].push(user);
    emit UserToGroupAdd(true,"User added to group successfully.",user,group);
    return true;
  }

  function removeUserFromGroup(address user,bytes32 group)
  public
  onlyAdmin
  returns (bool)
  {

    if(!ifUserExist(user)){
      emit UserToGroupAdd(false,"User not Exist.",user,group);
      return false;
    }

    if(!ifGroupExist(group)){
      emit UserToGroupAdd(false,"Group not Exist.",user,group);
      return false;
    }

    if(!ifUserHasGroup(user,group)){
      emit UserToGroupAdd(false,"User is not in group.",user,group);
      return false;
    }

    userToGroupMap[user][group]=false;
    for(uint i=0;i<groupToUserAddressMap[group].length;i++)
    {
      if(groupToUserAddressMap[group][i] == user){
        for(uint ii=i; ii<groupToUserAddressMap[group].length -1;ii++){
            groupToUserAddressMap[group][ii] == groupToUserAddressMap[group][ii+1];
        }
        groupToUserAddressMap[group].pop();
      }
      
    }
    emit UserToGroupAdd(true,"User added to group successfully.",user,group);
    return true;
  }

  function isAdmin(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[0].group_name);
  }

  function isIntegration(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[3].group_name);
  }

  function isPost(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[1].group_name);
  }

  function isBank(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[2].group_name);
  }

  function isMember(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[4].group_name);
  }

  function isRole(address account,bytes32 group)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,group);
  }

  function groupCalculate(bytes32 group,uint256 future_integration_timestamp, uint256 integration_budget)
  public
  onlyPost
  returns (bool)
  {
    //if date was in past
    if(future_integration_timestamp < block.timestamp)
    {
      //uint256 diff_time = future_integration_timestamp - block.timestamp;
      emit GroupCalculate(false,"Integration timestamp is wrong.",group);
      //emit GroupCalculateBlock(false,"Timestamp block.",block.timestamp);
      //emit GroupCalculateBlock(false,"Timestamp integration.",future_integration_timestamp);
      //emit GroupCalculateBlock(false,"Timestamp difference.",diff_time);
      return false;
    }

    //if less than 60days
    uint diff = (future_integration_timestamp - groups[groupIndex[group]].timestamp_last_integration) / 60 / 60 / 24;
    //emit GroupCalculateBlock(false,"Timestamp difference day.",diff);
    if(diff < 60){
      emit GroupCalculate(false,"Beetween integrations is less than 60days.",group);
      return false;
    }

    //if budget is to hight
    if(integration_budget > groupToUserAddressMap[group].length * 25)
    {
      emit GroupCalculate(false,"Budget is too hight.",group);
      return false;
    }


    emit GroupCalculate(true,"Group can organize integration.",group);
    return true;
  }






}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// remowed
contract Roles {

  bytes32[] public static_group = [
    keccak256("UserGroupView"),
    keccak256("AddUser"),
    keccak256("AddGroup"),
    keccak256("RemoveUser"),
    keccak256("RemoveGroup"),
    keccak256("SetUserGroup"),
    keccak256("SetGroupRole")
  ];

  event RolesAdd(bool status, string message,bytes32 role);
  event RolesRemove(bool status, string message,bytes32 role);

  address owner;
  bytes32[] public roles; 

  mapping(bytes32 => uint256) rolesIndex; 
  mapping(bytes32 => bool) rolesExist; 

  constructor (address _owner) public  {
    owner = _owner;
    
    for(uint256 i=0;i<static_group.length;i++)
    {
      setRole(static_group[i]);
    }
    //setUserToGroup(owner, static_group[0]);
    //addUser(owner);
    //setUserToGroup(owner, static_group[0]);
  }

  modifier onlyAdmin()
  {
    require((owner == msg.sender), "Restricted to admins or owner.");
    _;
  }

  function ifRoleExist(bytes32 role)
  public
  view
  returns (bool)
  {
    return rolesExist[role];
  }

  function setRole(bytes32 role_name)
  public
  onlyAdmin
  returns (bool)
  {
    if(!ifRoleExist(role_name)){
      emit RolesAdd(false,"Group Not Exist.",role_name);
      return false;
    }
    roles.push(role_name);
    rolesIndex[role_name] = roles.length -1;
    rolesExist[role_name] = true;
    emit RolesAdd(true,"Role added successfully.",role_name);
    return true;
  }



}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "UsersGroups.sol";

contract Bank {
    UsersGroups roles;
    address payable public owner;
    uint public contractbalance;//contract value 
    uint public ownerbalance;
    uint public balanceto;
    event Received(address, uint);

    constructor (address roleContract)  {
        owner=payable(msg.sender);   
        roles = UsersGroups(roleContract);
    }
    
    modifier onlyBank()
    {
        require(roles.isBank(msg.sender), "Restricted to bank.");
        _;
    }

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }
    
    function internaltransfer(address payable _to,uint _value)
    public
    payable
    onlyBank
    {
        (bool sent,)=_to.call{value: _value}("");
        ownerbalance=owner.balance;
        balanceto=_to.balance;
        contractbalance=address(this).balance;
        require(sent,"failed to send");
    }

    receive()
    external
    payable
    {
        emit Received(msg.sender, msg.value);
    }

    function getCurrentStatus()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

}