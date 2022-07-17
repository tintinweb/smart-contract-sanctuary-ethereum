// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.20;

contract admin_manufacture {
  address public owner;
  uint256 public creationTime;
  bytes32 a;
  // uint role;
  // mapping(address=>uint) role_Id;
  mapping(address => User) private usersdetail;
  address[] private userarray; // array of address of all users
  uint256 count = userarray.length;

  constructor() {
    owner = msg.sender;
    creationTime = block.timestamp;
    // usersdetail[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4].userName='manager';
    // usersdetail[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].userName='supplier';
    // usersdetail[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].userName='retailer';
  }

  function isUser(address _userAddress) public view returns (bool isIndeed) {
    if (userarray.length == 0) return false;

    return (userarray[usersdetail[_userAddress].index] == _userAddress);
  }

  // struct user_roles{
  //    uint user_role;
  // }
  mapping(address => uint256) user_role;

  struct User {
    uint256 role; // store
    string password;
    string userName;
    address createdBy; // store
    uint256 creationTime;
    string location;
    uint256 index;
    string email;
  }
  event LogUpdateUser(
    address indexed _userAddress,
    uint256 index,
    string email,
    string location,
    string password
  );
  event LogNewUser(
    address indexed _userAddress,
    uint256 index,
    string name,
    string password,
    string email,
    uint256 userrole,
    bytes32 _hash
  );

  function setUser(
    address _userAddress,
    string memory userName,
    string memory password,
    string memory email,
    string memory location,
    uint256 _role
  ) public returns (bytes32 _a, uint256 index) {
    require(isUser(_userAddress) == false);
    usersdetail[_userAddress].createdBy = msg.sender;
    usersdetail[_userAddress].creationTime = block.timestamp;
    usersdetail[_userAddress].location = location;
    usersdetail[_userAddress].role = _role;
    user_role[_userAddress] = _role;
    userarray.push(_userAddress);
    usersdetail[_userAddress].index = userarray.length - 1;
    a = sha256(
      abi.encodePacked(_userAddress, userName, location, password, email, _role)
    );

    emit LogNewUser(
      _userAddress,
      usersdetail[_userAddress].index,
      userName,
      password,
      email,
      user_role[_userAddress],
      a
    );

    return (a, userarray.length - 1);
  }

  function updateUser(
    address _userAddress,
    string memory email,
    string memory location,
    string memory password
  ) public returns (bool success) {
    require(isUser(_userAddress) == true);
    usersdetail[_userAddress].email = email;
    usersdetail[_userAddress].location = location;
    usersdetail[_userAddress].password = password;

    emit LogUpdateUser(
      _userAddress,
      usersdetail[_userAddress].index,
      email,
      location,
      password
    );
    return true;
  }

  function showRole(uint256 role) public returns (string memory _role) {
    if (
      usersdetail[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4].createdBy ==
      msg.sender
    ) {
      usersdetail[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4].role = 1;
      return 'maufacturer';
    }
  }
}