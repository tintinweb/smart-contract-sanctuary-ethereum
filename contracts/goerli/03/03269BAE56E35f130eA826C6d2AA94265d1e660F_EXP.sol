// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20SB.sol";
import "./Ownable.sol";

//import "hardhat/console.sol";

error NotAuthorized();
error BalanceTooLow();

contract EXP is ERC20SB, Ownable {

  event TokenAdminSet(address indexed _adminAddr, bool indexed _isAdmin);

  mapping(address => bool) public tokenAdmins;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _owner
  ) ERC20SB(_name, _symbol, _decimals) Ownable(_owner) {
    tokenAdmins[msg.sender] = true;
  }

  function setApprovedMinter(address _adminAddr, bool _isAdmin) public {
    if (msg.sender != _owner) revert NotOwner();
    tokenAdmins[_adminAddr] = _isAdmin;
    emit TokenAdminSet(_adminAddr, _isAdmin);
  }

  function mint(address _to, uint256 _value) public {
    if (tokenAdmins[msg.sender] == false) revert NotAuthorized();
    _mint(_to, _value);
  }

  function burn(address _from, uint256 _value) public {
    if ((tokenAdmins[msg.sender] == false) && (msg.sender != _from))
      revert NotAuthorized();
    if (balanceOf[_from] < _value) revert BalanceTooLow();
    _burn(_from, _value);
  }
}