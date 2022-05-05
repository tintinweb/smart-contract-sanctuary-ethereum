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
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
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
        uint denominator = uint(getLatestPrice()); 
        uint256 ethInUsdAmount = _value * 1000000000000000000000/denominator * 100000; 
        (bool sent,)=_to.call{value: ethInUsdAmount}("");
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