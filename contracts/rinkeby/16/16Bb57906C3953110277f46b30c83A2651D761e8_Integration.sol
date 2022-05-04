// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "UsersGroups.sol";
import "Bank.sol";
import "IntegrationApprove.sol";

/// @title Integration
/// @notice store integrations
/// @dev
contract Integration {

    /// @notice total number of Integrations
    /// @dev 
    uint256 totalNumber;

    /// @notice reference to UsersGroups Contract
    /// @dev 
    UsersGroups roles;

    /// @notice reference to Bank Contract
    /// @dev 
    Bank bank;

    /// @notice reference to IntegrationApprove Contract
    /// @dev 
    IntegrationApprove integration_approve;


    /// @notice event emmited when Integration is Added
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return amount Amount of Money for Integration
    /// @return id Integration ID
    event IntegrationAdded(bool status,string message,uint256 amount, uint256 id);

    /// @notice event emmited when Integration CID IPFS is updated
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return id Integration ID
    event IntegrationUpdated(bool status,string message, uint256 id);

    /// @notice event emmited when Integration CID IPFS is deleted
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return id Integration ID
    event IntegrationDelete(bool status,string message, uint256 id);
    
    /// @notice structure of single Integration
    /// @dev
    /// @param ipfs_hash IPFS CID of Proposal
    struct Integrations {
        string ipfs_hash;
    }

    /// @notice array of Integration
    /// @dev
    Integrations[] public integrations;

    /// @notice array of Integration
    /// @dev
    /// @param roleContract address of UsersGroups Contract
    /// @param bankContract  address of Bank Contract
    /// @param integration_approveContract  address of IntegrationApprove Contract

    constructor (address roleContract,address payable bankContract, address integration_approveContract) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
        integration_approve = IntegrationApprove(integration_approveContract);
    }

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    modifier onlyPost()
    {
        require(roles.isPost(msg.sender), "Restricted to posts.");
        _;
    }
    
    /// @notice array of Integration
    /// @dev
    /// @param _hash_integration IPFS CID of Interation
    /// @param _hash_integration_approve  IPFS CID of Interation Approve
    /// @param _account Account sended Proposal for this Integration
    /// @param amount_integration Wei to be sended to account, when proposal for integration is succesfull executed
    /// @param amount_approve Wei to be sended, when approve will be confirmed
    /// @param groups Array of groups, when one member from group must confirm Integration Approve
    /// @param group_for_vote  Group for whote on Integraion Approve, when 51% of members must Confirm Approve
    /// @param timestamp_inegration_approve Block when Integration Approve shoud start
    /// @return _id Id of integration
    function addIntegration(string memory _hash_integration,string memory _hash_integration_approve,
     address payable _account, uint256 amount_integration,
     uint256 amount_approve, bytes32[] memory groups,bytes32 group_for_vote, uint256 timestamp_inegration_approve)
    public
    onlyPost
    returns (uint256) {
        integrations.push(Integrations(_hash_integration));
        totalNumber++;
        uint _id= integrations.length -1;
        bank.internaltransfer(_account,amount_integration);
        integration_approve.addIntegrationApprove(_hash_integration_approve,_account,amount_approve, groups,group_for_vote,timestamp_inegration_approve+1,timestamp_inegration_approve+1000);
        emit IntegrationAdded(true,"Integration added",amount_integration,_id);
        return _id;
    }

    /// @notice Total number of Integration
    /// @dev
    /// @return totalNumber Total number of Integration
    function getTotalIntegrationsNumber()
    public
    view
    returns (uint256)  {
        return totalNumber;
    }

    /// @notice Update Integration
    /// @dev
    /// @param id Id of Integration
    /// @param _hash New IPFS CID 
    /// @return status Status of execution
    function updateSingleIntegrationHash(uint id,string memory _hash)
    public
    onlyPost
    returns (bool) {
        if(id < totalNumber)
        {   
            integrations[id].ipfs_hash =_hash;
            emit IntegrationUpdated(true,"Integration updated",id);
            return true;
        }
        else
        {
            emit IntegrationUpdated(false,"Integration not exist",id);
            return false;
        }
    }

    /// @notice Delete Integration
    /// @dev
    /// @param id Id of Integration
    /// @return status Status of execution
    function deleteSingleIntegration(uint id)
    public
    onlyPost
    returns (bool)
    {
        if(id < totalNumber)
        {   
            for(uint i = id; i < integrations.length-1; i++)
            {
                integrations[i] = integrations[i+1];      
            }
            integrations.pop();
            emit IntegrationDelete(true,"Inegration deleted",id);
            return true;
        }
        else
        {
            emit IntegrationDelete(false,"Inegration not exist",id);
            return false;
        }        
    }

    /// @notice get IPFS CID Integration
    /// @dev
    /// @param id Id of Integration
    /// @return CID IPFS CID
    function getSingleIntegrationHash(uint256 id)
    public
    view
    returns (string memory) {
        return integrations[id].ipfs_hash;
    }

    /// @notice get all Integration
    /// @dev
    /// @return Integration Array of integrations
    function getAllIntegrations()
    public
    view
    returns (Integrations[] memory) {
        return integrations;
    }

    /// @notice get single Integration
    /// @dev
    /// @param id Id of Integration
    /// @return Integration Array of integrations
    function getIntegration(uint256 id)
    public
    view
    returns (Integrations memory) {
        return integrations[id];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Roles.sol";

/// @title RequestMembers
/// @notice Contract stored User and groum membership.
/// @dev 
contract UsersGroups {

    /// @notice array of static group 
    /// @dev
    bytes32[] private static_group = [
      bytes32("Admin"),
      bytes32("DAO_EXECUTE"),
      bytes32("Bank"),
      bytes32("Integration"),
      bytes32("Member")
    ];

    /// @notice Event emmited when new group is added.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name
    event GroupAdd(bool status, string message,bytes32 group);

    /// @notice Event emmited when new group is deleted.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name
    event GroupRemove(bool status, string message,bytes32 group);

    /// @notice Event emmited when new group budget is calculated.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return group Group Name
    event GroupCalculate(bool status, string message,bytes32 group);
    event GroupCalculateBlock(bool status, string message,uint256 timestamp);

    /// @notice Event emmited when new user is added.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address
    event UserAdd(bool status, string message,address user);

    /// @notice Event emmited when new user is added to group.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address
    /// @return group Group Name
    event UserToGroupAdd(bool status, string message,address user,bytes32 group);

    /// @notice Event emmited when new user is deleted.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return user User Address
    event UserRemove(bool status, string message,address user);

    /// @notice owner address
    /// @dev
    address private owner;

    /// @notice array of groups
    /// @dev
    Group[] private groups; 

    /// @notice array of users 
    /// @dev
    User[] private users;

    /// @notice user count 
    /// @dev
    uint256 private UserCount=0;

    /// @notice group count
    /// @dev
    uint256 private GroupCount=0;

    /// @notice map user address to: map group to status if added to this group
    /// @dev
    mapping(address => mapping(bytes32 => bool)) userToGroupMap;

    /// @notice map user address to status if exist
    /// @dev
    mapping(address => bool) usersMap; 

     /// @notice map user address to index in users array
    /// @dev
    mapping(address => uint256) userIndex; 

    /// @notice map group to status if exist
    /// @dev
    mapping(bytes32 => bool) groupsMap; 

    /// @notice map group to index in group array
    /// @dev
    mapping(bytes32 => uint256) groupIndex; 

    /// @notice map group to array of membership users
    /// @dev
    mapping(bytes32 => address[]) groupToUserAddressMap; 

    /// @notice structure of group
    /// @dev
    /// @param group_name Group name
    /// @param current_balance for future use
    /// @param blocked_balance for future use
    /// @param timestamp_created Timestamp Creation.
    /// @param timestamp_last_integration Timestamp for last integration.
    struct Group {
        bytes32 group_name;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        uint256 timestamp_last_integration;
    }

    /// @notice structure of users
    /// @dev
    /// @param userID User Address
    /// @param current_balance for future use
    /// @param blocked_balance for future use
    /// @param timestamp_status Timestamp Creation.
    /// @param timestamp_last_integration for future use
    struct User {
        address userID;
        uint256 current_balance;
        uint256 blocked_balance;
        uint256 timestamp_created;
        bool timestamp_status;
    }

  /// @notice Contructor
  /// @dev
  /// @param _owner Owner Address 
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

  /// @notice initializer for proxy contract migration - future release
  /// @dev
  /// @param _owner Owner Address 
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

  /// @notice Check if User exist
  /// @dev
  /// @param user Account Address
  /// @return status True/False if exist.
  function ifUserExist(address user)
  public
  view
  returns (bool)
  {
    return usersMap[user];
  }

  /// @notice Check if group exist
  /// @dev
  /// @param group Group Name
  /// @return status True/False if exist.
  function ifGroupExist(bytes32 group)
  public
  view
  returns (bool)
  {
    return groupsMap[group];
  }

  /// @notice Check if User is in Group
  /// @dev
  /// @param user Account Address
  /// @param group Group Name
  /// @return status True/False if exist.
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

  /// @notice Get data of user
  /// @dev
  /// @param user Account Address
  /// @return [balance,blocked_balance,timestamp_created,timestamp_status]
  function getUser(address user)
  public
  view
  onlyAdmin
  returns (uint256,uint256,uint256,bool)
  {
    require(ifUserExist(user),"User not exist");
    return (users[userIndex[user]].current_balance,users[userIndex[user]].blocked_balance,users[userIndex[user]].timestamp_created,users[userIndex[user]].timestamp_status);
  }

  /// @notice Get data of user by index
  /// @dev
  /// @param user Account Address
  /// @return [userID,balance,blocked_balance,timestamp_created,timestamp_status]
  function getUserByIndex(uint256 _index)
  public
  view
  onlyAdmin
  returns (address)
  {
    return (users[_index].userID);
  }

  /// @notice Get user by ID in array
  /// @dev
  /// @param user Account Address
  /// @return [balance,blocked_balance,timestamp_created,timestamp_status]
  function getUserindex(address user)
  public
  view
  onlyAdmin
  returns (uint256)
  {
    require(ifUserExist(user),"User not exist");
    return userIndex[user];
  }

  /// @notice Get all users
  /// @dev
  /// @param user Account Address
  /// @return [balance,blocked_balance,timestamp_created,timestamp_status][]
  function getUsers()
  public
  view 
  onlyAdmin
  returns (User[] memory)
  {
    return users;
  }

  /// @notice Get group members
  /// @dev
  /// @param group Group Name
  /// @return [account1, account2, ...] Array of accounts
  function getUsersInGroup(bytes32 group)
  public
  view
  onlyAdmin
  returns (address[] memory)
  {
    return groupToUserAddressMap[group];
  }

  /// @notice Get total number of users
  /// @dev
  /// @return count Number Of Users 
  function getUsersCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return UserCount;
  }

  /// @notice Get total number of groups
  /// @dev
  /// @return count Number Of Groups 
  function getGroupsCount()
  public
  view
  onlyAdmin
  returns (uint256)
  {
    return GroupCount;
  }

  /// @notice Get All Group
  /// @dev
  /// @return [group_name,current_balance,blocked_balance,timestamp_created,timestamp_last_integration] 
  function getGroups()
  public
  view
  onlyAdmin
  returns (Group[] memory)
  {
    return groups;
  }
  /// @notice Get All Group
  /// @dev
  /// @return [group_name,timestamp_created,timestamp_last_integration][]
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

  /// @notice Add group
  /// @dev
  /// @param group Group Name
  /// @return status True/False - status of excution
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

  /// @notice Remove group
  /// @dev
  /// @param group Group Name
  /// @return status True/False - status of excution
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

  /// @notice Add User
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
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

  /// @notice Remove group
  /// @dev
  /// @param user User Address.
  /// @return status True/False - status of excution
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

  /// @notice Add user to group.
  /// @dev
  /// @param user User Address
  /// @param group Group Name
  /// @return status True/False - status of excution
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

  /// @notice Remove user from group
  /// @dev
  /// @param user User Address
  /// @param group Group Name
  /// @return status True/False - status of excution
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

  /// @notice Check if user is admin.
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
  function isAdmin(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[0].group_name);
  }

  /// @notice Check if user is in group Integration.
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
  function isIntegration(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[3].group_name);
  }

  /// @notice Check if user is in group who can add Blog Post.
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
  function isPost(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[1].group_name);
  }

  /// @notice Check if user is in group who can transfer from Bank.
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
  function isBank(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[2].group_name);
  }

  /// @notice Check if user is in group Member.
  /// @dev
  /// @param user User Address
  /// @return status True/False - status of excution
  function isMember(address account)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,groups[4].group_name);
  }

  /// @notice Check if user is in this group.
  /// @dev
  /// @param user User Address
  /// @param group Group Name
  /// @return status True/False - status of excution
  function isRole(address account,bytes32 group)
  public
  view
  returns (bool)
  {
    return ifUserHasGroup(account,group);
  }

  /// @notice Calculate, if group can add Integration.
  /// @dev
  /// @param user User Address
  /// @param future_integration_timestamp Future Integration timestamp.
  /// @param integration_budget Budget needed for integration.
  /// @return status True/False - status of excution
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

/// @title RequestMembers
/// @notice Contract stored User and groum membership.
/// @dev 
contract Roles {

    /// @notice list of static group used by Contract
    /// @dev
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

import "AggregatorV3Interface.sol";
import "UsersGroups.sol";

/// @title Bank
/// @notice Contract, who store ether and transfer it to winner
/// @dev
contract Bank {
    /// @notice address UserRoles Account
    UsersGroups roles;
    
    address payable public owner;
    uint public contractbalance;//contract value 
    uint public ownerbalance;
    uint public balanceto;

    event Received(address, uint);

    AggregatorV3Interface internal priceFeed;


    /// @notice constructor Bank Contract
    /// @dev
    /// @param roleContract - address of UserRoles
    constructor (address roleContract)  {
        owner=payable(msg.sender);   
        roles = UsersGroups(roleContract);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
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

    /// @notice internaltransfer - transfer ether from bank to another account
    /// @dev
    /// @param _to - account for transfer
    /// @param _value - amount for transfer, for now it is WEI, but in future is will be USD
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
    /// @notice receive - for receive money for another account 
    /// @dev
    receive()
    external
    payable
    {
        emit Received(msg.sender, msg.value);
    }

    /// @notice getCurrentStatus - display current balance of bank
    /// @dev
    function getCurrentStatus()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

    /// @notice chainlink implementation of data feed
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "UsersGroups.sol";
import "Bank.sol";


/// @title IntegrationApprove
/// @notice IntegrationApprove Contract stored Integration Approve.
/// @dev 
contract IntegrationApprove {

    /// @notice Total Number of Integration
    /// @dev
    uint256 totalNumber=0;

    /// @notice reference to UsersGroups contract
    /// @dev
    UsersGroups roles;

    /// @notice reference to Bank contract
    /// @dev
    Bank bank;

    /// @notice event emmited when Integration Approve is added.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveAdded(bool status,string message,uint id);

    /// @notice event emmited when Integration Approve is approved by user.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveApproved(bool status,string message,uint id);

    /// @notice event emmited when Integration Approve is updated.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveUpdated(bool status,string message,uint id);

    /// @notice event emmited when Integration Approve is approved by one user group required group.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    /// @return group Group confirmed.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveGroup(bool status,string message,uint id, bytes32 group, bool confirmation_status);

    /// @notice event emmited when Integration Approve is executed.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveExecute(bool status,string message,uint id);

    /// @notice event emmited when Integration Approve when confirmation status is checked.
    /// @dev
    /// @return status True/False - status of excution.
    /// @return message Information with Error or Successfull execution.
    /// @return id ID of integraition approve.
    event IntegrationApproveStatus(bool status,string message,uint id);

    /// @notice event emmited when user send confirmation.
    /// @dev
    /// @return status True/False - status of excution
    /// @return message Information with Error or Successfull execution.
    /// @return account ID of integraition approve.
    /// @return confirmation_status Status of confirmation.
    event IntegrationApproveUser(bool status,string message,address account, bool confirmation_status);

    /// @notice structure of integration Approve
    /// @dev
    /// @param status Status
    /// @param ipfs_hash IPFS CID of integration Approve
    /// @param to_user User to transfer money, when integration approve is confirmed.
    /// @param amount Amount of WEI to transfer
    /// @param group Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Block for Start Confirmation Process
    /// @param block_end Block for End Confirmation Process
    /// @param confirmation_status Current Status
    struct IntegrationsApprove {
        bool status; //if its blocked
        string ipfs_hash; // ipfs CID
        address payable to_user; // user transfer ether
        uint256 amount; // amoun to tranfer to that user
        bytes32[] groups; // groups should all confirm
        bytes32 group_for_vote; // group for vote on integration events
        uint256 block_start; // when start confirm
        uint256 block_end; // when stop confirm
        Confirmation confirmation_status;
    }

    /// @notice Current status of confirmation
    /// @dev
    enum Confirmation {
        Pending,
        Active,
        Confirmed,
        Execute,
        Defeted
    }

    /// @notice constructor
    /// @dev
    /// @param roleContract Address UsersGroups contract
    /// @param bankContract Address Bank contract
    /// @param groups for future
    constructor (address roleContract,address payable bankContract,bytes32[] memory groups) public  {
        roles = UsersGroups(roleContract);
        bank = Bank(bankContract);
    }

    /// @notice Array of Integration Approve
    /// @dev
    IntegrationsApprove[] public integrationsApprove;

    /// @notice map ID to index in array in integration Approve
    /// @dev
    mapping(uint256 => uint256) integrationIndexMap;

    /// @notice map ID to status if exist
    /// @dev
    mapping(uint256 => bool) integrationExistMap;

    /// @notice mapping id of integration approve to group and bool; //true - confirmed
    /// @dev
    mapping(uint256 => mapping(bytes32 => bool)) groupStatusMap; //mapping id of integration approve to group and bool; //true - confirmed
    
    /// @notice mapping id of integration approve to user and bool; //true - confirmed
    /// @dev
    mapping(uint256 => mapping(address => bool)) userStatusMap; //mapping id of integration approve to user and bool; //true - confirmed
    
    /// @notice mapping  of integration approve to its approved status
    /// @dev
    mapping(uint256 => bool) groupApprovedMap; // mapping  of integration approve to its status
    
    /// @notice mapping  of integration approve to its xecution status
    /// @dev
    mapping(uint256 => bool) groupApprovedExecutionMap; // mapping  of integration approve to its status

    modifier onlyAdmin()
    {
        require(roles.isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMember()
    {
        require(roles.isMember(msg.sender), "Restricted to members.");
        _;
    }

    modifier onlyIntegration()
    {
        require(roles.isIntegration(msg.sender), "Restricted to integration contract.");
        _;
    }

    /// @notice add integration approve
    /// @dev 
    /// @param _hash CID IPFS to integration Approve
    /// @param _account Account to transfer WEI, when integration approve is confirmed
    /// @param amount Amount WEI to transfer
    /// @param groups Array of groups, when one user from group must confirm and after that all group is confirmed. 
    /// @param group_for_vote Group for users, who can confirm.
    /// @param block_start Timestamp of Start Confirmation Process
    /// @param block_end Timestamp of Emd Confirmation Process
    /// @return integratipnApproveID ID of integration Approve
    function addIntegrationApprove(string memory _hash, address payable _account, uint256 amount, bytes32[] memory groups,bytes32 group_for_vote,uint256 block_start,uint256 block_end)
    public
    onlyIntegration
    returns (uint256) {
        
        integrationsApprove.push(IntegrationsApprove(false,_hash,_account,amount,groups,group_for_vote,block_start,block_end,Confirmation.Pending));
        totalNumber++;
        uint256 _id= integrationsApprove.length -1;
        integrationIndexMap[_id] = _id;
        groupApprovedExecutionMap[_id] = false;
        integrationExistMap[_id] = true;
        for(uint256 i=0;i<groups.length;i++){
            groupStatusMap[_id][groups[i]] = false;
        }
        emit IntegrationApproveAdded(true,"IntegrationApprove added",_id);
        return _id;
    }

    /// @notice update IPFS CID
    /// @dev
    /// @param _id ID Integration Approve
    /// @param _hash New IPFS CID
    function updateHash(uint _id,string memory _hash)
    public
    onlyMember {
        if(integrationsApprove[integrationIndexMap[_id]].status== false)
        {
            integrationsApprove[integrationIndexMap[_id]].status== true;
            integrationsApprove[integrationIndexMap[_id]].ipfs_hash = _hash;
            emit IntegrationApproveUpdated(true,"IntegrationApproved updated",_id);
            integrationsApprove[integrationIndexMap[_id]].status== false;
        }
        else
        {
            emit IntegrationApproveUpdated(false,"IntegrationApproved update blocked by other task.",_id);
        }
    }

    /// @notice Total Integration Approve
    /// @dev
    /// @return count Count oF Integration Approve
    function getTotalIntegrationsNumber()
    public
    view
    returns (uint256)  {
        return totalNumber;
    }

    /// @notice Get Integration Approve By ID
    /// @dev
    /// @return struct of Integration
    function getIntegration(uint256 _id)
    public
    view
    returns (IntegrationsApprove memory)  {
        return integrationsApprove[integrationIndexMap[_id]];
    }

    /// @notice Get Integration Approve CID IPFS
    /// @dev
    /// @param _id ID of Integration Approve
    /// @return cid_ipfs IPFS CID
    function getIntegrationHash(uint256 _id)
    public
    view
    returns (string memory) {
        return integrationsApprove[integrationIndexMap[_id]].ipfs_hash;
    }

    /// @notice Get All Integration Approve
    /// @dev
    /// @return [] Array of Struct integration Approve
    function getAllIntegrations()
    public
    view
    returns (IntegrationsApprove[] memory) {
        return integrationsApprove;
    }

    /// @notice Get Groups for Integration Approve
    /// @dev
    /// @param _id ID of Integration Approve
    /// @return array Array fo Groups Names
    function getGroupsAll(uint256 _id)
    public
    view
    returns (bytes32[] memory) {
        return integrationsApprove[integrationIndexMap[_id]].groups;
    }

    /// @notice Validate if Inetgration Approve Exist
    /// @dev
    /// @param _id ID of Integration Approve
    /// @return status Status of Integration Approve
    function ifIntegrationExist(uint256 _id)
    public
    view
    returns (bool) {
        return integrationExistMap[_id];
    }

    /// @notice Get Process status - not use, because of bug
    /// @dev
    /// @param _id ID of Integration Approve
    /// @return status Status of Integration Approve
    function getProcessStatus(uint256 _id)
    public
    view
    returns (Confirmation) {
        return integrationsApprove[integrationIndexMap[_id]].confirmation_status;
    }

    /// @notice Get Status of Confirmation
    /// @dev
    /// @param _id ID of Integration Approve
    /// @return status Status of Integration Approve
    function getConfirmStatus(uint256 _id)
    public
    returns (bool) {
        //emit IntegrationApproveStatus(false, "Block start.",integrationsApprove[integrationIndexMap[_id]].block_start);
        //emit IntegrationApproveStatus(false, "Block Stop.",integrationsApprove[integrationIndexMap[_id]].block_end);
        //emit IntegrationApproveStatus(false, "Current Block.",block.number);
        if( block.number >= integrationsApprove[integrationIndexMap[_id]].block_start && block.number <=integrationsApprove[integrationIndexMap[_id]].block_end )
        {
            emit IntegrationApproveStatus(true, "Confirmation started.",_id);
            return true;
        }
        else
        {
            if( block.number < integrationsApprove[integrationIndexMap[_id]].block_end && block.number < integrationsApprove[integrationIndexMap[_id]].block_start)
            {
                emit IntegrationApproveStatus(false, "Confirmation not started.",_id);
                return false;
            }
            else
            {
                emit IntegrationApproveStatus(false, "Confirmation was ended.",_id);
                return false;
            }
        }
    }

    /// @notice Validate if group is confirmed
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @return status Status of confirmation.
    function ifGroupConfirmed(uint256 _id,bytes32 _group)
    public
    view
    returns (bool) {
        return groupStatusMap[_id][_group];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }
    
    /// @notice Confirm Integration Approve by Group.
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @param _group Group name.
    /// @param status True - For, False - Against
    /// @return status Status of execution.
    function setGroupMap(uint256 _id,bytes32 _group,bool status)
    public
    
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveGroup(false,"Integration not exist.",_id,_group,status);
            return false;
        }
        
        if(ifGroup(_id, _group))
        {
            if(!getConfirmStatus(_id))
            {
                emit IntegrationApproveGroup(false,"Confirmation not ready.",_id,_group,status);
                return false;
            }

            if(!roles.isRole(msg.sender, _group)){
                emit IntegrationApproveGroup(false,"User is not in required group.",_id,_group,status);
                return false;
            }

            groupStatusMap[_id][_group] = status;
            emit IntegrationApproveGroup(true,"Group was changed",_id,_group,status);
            return true;
        }
        else
        {
            //walidate if one from given group, who should vote can vote
            emit IntegrationApproveGroup(false,"This group not exist for this IntegrationApprove.",_id,_group,status);
            return false;
        }    
    }

    /// @notice Execute Integration Approve by User.
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @return status Status of execution.
    function execute(uint256 _id)
    public
    onlyMember
    returns (bool){

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveExecute(false,"Integration not exist.",_id);
            return false;
        }

        if(block.number > integrationsApprove[integrationIndexMap[_id]].block_end && block.number > integrationsApprove[integrationIndexMap[_id]].block_start)
        {  
            if(groupApprovedExecutionMap[_id]){
                emit IntegrationApproveExecute(false,"Approve already executed.",_id);
                return false;
            }
            
            for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){            
                if(groupStatusMap[_id][integrationsApprove[_id].groups[i]] == false)            
                {         
                    groupApprovedExecutionMap[_id] = true;  
                    integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;     
                    emit IntegrationApproveExecute(false,"Not all group approved.",_id);
                    return false;
                
                }            
            }

            address[] memory users = roles.getUsersInGroup(integrationsApprove[integrationIndexMap[_id]].group_for_vote);
            uint256 confirmed_Status = 0;

            for(uint i=0; i<users.length;i++){          
                if(userStatusMap[_id][users[i]] == true)            
                {                
                    confirmed_Status=confirmed_Status+1;
                }            
            }

            if((confirmed_Status *100)/(users.length) < 50)
            {
                groupApprovedExecutionMap[_id] = true;
                integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Defeted;
                emit IntegrationApproveExecute(false,"Required number of users not confirmed this approve.",confirmed_Status/users.length);
                return false;
            }

            groupApprovedExecutionMap[_id] = true;
            integrationsApprove[integrationIndexMap[_id]].confirmation_status = Confirmation.Confirmed;
            bank.internaltransfer(integrationsApprove[_id].to_user,integrationsApprove[_id].amount);
            //integrationsApprove[_id].amount
            emit IntegrationApproveExecute(true,"Execute completed.",_id);
            return true;
        }
        else
        {
            emit IntegrationApproveExecute(false,"Confirmation in not ended.",_id);
            return false;
        }
    }
    
    /// @notice Validate if all Groups is confirmed
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @param group Group Name.
    /// @return status Status of execution.
    function ifGroup(uint256 _id,bytes32 group)
    public
    view
    returns (bool) {
        if( _id > integrationsApprove[integrationIndexMap[_id]].groups.length-1)
        {
            return false;
        }
        for(uint i=0; i<integrationsApprove[integrationIndexMap[_id]].groups.length;i++){
            if(integrationsApprove[_id].groups[i] == group)
            {
                return true;
            }
        }
        return false;
    }

    /// @notice Get if User is confirm application approve
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @param _user Group Name.
    /// @return status Status of execution.
    function ifUserConfirmed(uint256 _id,address _user)
    public
    view
    returns (bool) {
        return userStatusMap[_id][_user];
        //return groupStatusMap[0][integrationsApprove[0].groups[0]];
    }

    /// @notice Confirm Integration Approve by user
    /// @dev
    /// @param _id ID of Integration Approve.
    /// @param status True - yes, False - no
    /// @return status Status of execution.
    function setConfirmUser(uint256 _id,bool status)
    public
    onlyMember
    returns (bool) {

        if(!ifIntegrationExist(_id)){
            emit IntegrationApproveUser(false,"Integration not exist.",msg.sender,status);
            return false;
        }
        
            if(!getConfirmStatus(_id))
            {
                emit IntegrationApproveUser(false,"Confirmation not ready.",msg.sender,status);
                return false;
            }

            if(!roles.isRole(msg.sender, integrationsApprove[integrationIndexMap[_id]].group_for_vote)){
                 emit IntegrationApproveUser(false,"User is not in required group for confirmation.",msg.sender,status);
                return false;
            }

            userStatusMap[_id][msg.sender] = status;
            emit IntegrationApproveUser(true,"User was changed",msg.sender,status);
            return true;
        
    }


    


}