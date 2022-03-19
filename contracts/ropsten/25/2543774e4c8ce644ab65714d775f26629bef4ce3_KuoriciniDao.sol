/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
//import "./KuoriciniGroup.sol";

contract KuoriciniDao {

  struct DaoGroup {
    string name;
    address[] members;
  }

  mapping (address => uint) balances;
  mapping (address => string) names;
  DaoGroup[] daoGroups ;
  event newGroup(uint id);

  string public symbol="KUORI";
  event Transfer(address indexed from, address indexed to, uint value);

  constructor() public {
    balances[msg.sender] = 3500;
    names[msg.sender] = "asdrubale";
  }

  function addGroup(string calldata _name) public returns(bool){
    address[] memory addr = new address[](1);
    addr[0] = msg.sender;
    DaoGroup memory new_group = DaoGroup({ name: _name, members: addr });
    daoGroups.push(new_group);
    emit newGroup(daoGroups.length);
    return true;
  }

  function getGroupNamefromId(uint _id) public view returns(string memory) {
    return daoGroups[_id].name;
  }

  function getGroupAddressfromId(uint _id) public view returns(address[] memory) {
    return daoGroups[_id].members;
  }

  function addAddresstoMembers(uint _id, address _addr) public returns(bool) {
    uint l = daoGroups[_id].members.length;
    address[] memory members = new address[](l+1);
    for (uint i = 0; i < l; i++) {
      members[i] = daoGroups[_id].members[i];
    }
    members[l] = _addr;
    daoGroups[_id].members = members;
    return true;
  }

  function myGroups() public view returns(uint[] memory) {
    uint lg = daoGroups.length;
    uint[] memory myGroups;
    for (uint i = 0; i < lg; i++) {
      uint lm = daoGroups[i].members.length;
      for (uint q = 0; q < lm; q++) {
        if(daoGroups[i].members[q] == msg.sender) {
          uint gl = myGroups.length;
          uint[] memory groups = new uint[](gl+1);
          for (uint w = 0; w < gl; w++) {
            groups[w] = myGroups[w];
          }
          groups[gl] = i;
          myGroups = groups;
        }
      }
    }
    return myGroups;
  }

  function balanceOf(address owner) public view returns(uint) {
    return balances[owner];
  }

  function nameOf(address owner) public view returns(string memory) {
    return names[owner];
  }

  function nameSet(string calldata name) public returns(bool) {
    names[msg.sender]=name;
    balances[msg.sender] += 100;
    return true;
  }

  function transfer(address to, uint value) public returns(bool) {
    require(balances[msg.sender] >= value, "non hai abbastanza kuori");
    balances[to] += value;
    balances[msg.sender] -= value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

}