/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
interface XetaVesting {
  function emission() external view returns (uint256);
  function getPercentage(string calldata name, uint256 step) external view returns (uint256);
}
interface IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}
contract Vesting{
  address public vesting;
  address public owner;
  address[] public userAddress;
  address public xeta;
  bool public pause;
  uint256 public decimals;
  string public name;
  struct user {
    bool valid;
    uint256 amount;
    uint256 claimed;
    uint256 emission;
  }
  mapping (address => user) public users;
  constructor() {
    owner = msg.sender;
    decimals = 20;
    name = "seed";
  }
  receive() external payable {}
  modifier onlyOwner() {
    require(msg.sender == owner, "x");
    _;
  }
  modifier whenNotPaused(){
    require(pause == false, "xx");
    _;
  }
  function setToken(address _token) external onlyOwner{
    xeta = _token;
  }
  function setOwner(address _owner) external onlyOwner{
    owner = _owner;
  }
  function setName(string calldata _name) external onlyOwner{
    name = _name;
  }
  function setVesting(address _vesting) external onlyOwner{
    vesting = _vesting;
  }
  function setDecimals(uint256 _decimals) external onlyOwner{
    decimals = _decimals;
  }
  function setUsers(address[] calldata  _userAddress, uint256[] calldata _amount) external onlyOwner{
    require(_userAddress.length == _amount.length , "Invalid params");
    for(uint i = 0; i < _userAddress.length; i++){
      require(!isContract(_userAddress[i]),"Not an EOA");
      if(!users[_userAddress[i]].valid){
      users[_userAddress[i]].valid = true;
      userAddress.push(_userAddress[i]);
      }
      users[_userAddress[i]].amount = _amount[i] * 10 **18;
    }
  }
  function deleteUser(address _user) external onlyOwner{
     require(users[_user].valid == true , "Invalid user");
    delete users[_user];
    for (uint256 i = 0; i < userAddress.length; i++){
      if(userAddress[i] == _user){
        userAddress[i] = userAddress[userAddress.length-1];
        userAddress.pop();
        break;
      }
    }
  }
  function claim(address _beneficiary) public whenNotPaused{
    address beneficiary;
    if(msg.sender == owner) beneficiary = _beneficiary;
    else beneficiary = msg.sender;
    require(users[beneficiary].valid, "Invalid user");
    uint256 totalEmissions = XetaVesting(vesting).emission();
    require(totalEmissions > 0, "Emission is at 0");
    require(users[beneficiary].emission < totalEmissions, "Already claimed");
    uint256 distributed;
    uint256 amount;
    for (uint256 i = users[beneficiary].emission; i < totalEmissions; i++){
      distributed = XetaVesting(vesting).getPercentage(name,i);
      if(distributed > 0) amount += distributed;
    }
    amount = (amount * users[beneficiary].amount) / 10 ** decimals;
    users[beneficiary].emission = totalEmissions;
    users[beneficiary].claimed += amount;
    require(IERC20(xeta).transfer(beneficiary, amount));
  }
  function emergencyWithdraw(address _address) external onlyOwner{
    uint256 balance =  IERC20(xeta).balanceOf(address(this));
    require(IERC20(xeta).transfer(_address, balance));
  }
  function setPause(bool status) external onlyOwner{
    pause = status;
  }
  function isContract(address _address) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(_address) }
    return size > 0;
  }
}