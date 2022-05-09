// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * Author: Kumar Abhirup (kumareth)
 * Version: 2.0.0
 * Compiles best with: 0.8.4

 * Many contracts have ownerOnly functions, 
 * but I believe it's safer to have multiple owner addresses
 * to fallback to, in case you lose one.

 * You can inherit this PermissionManagement contract
 * to let multiple people do admin operations on your contract effectively.

 * You can add & remove admins and moderators.
 * You can transfer ownership (basically you can change the founder).
 * You can change the beneficiary (the prime payable wallet) as well.

 * Use modifiers like "founderOnly", "adminOnly", "moderatorOnly"
 * in your contract to put the permissions to use.
 */

/// @title PermissionManagement Contract
/// @author [email protected]
/// @notice Like Openzepplin Ownable, but with many Admins and Moderators.
/// @dev Like Openzepplin Ownable, but with many Admins and Moderators.
/// In Monument.app context, It's recommended that all the admins except the Market Contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.
contract PermissionManagement {
  address public founder = msg.sender;
  address payable public beneficiary = payable(msg.sender);

  mapping(address => bool) public admins;
  mapping(address => bool) public moderators;

  enum RoleChange { 
    MADE_FOUNDER, 
    MADE_BENEFICIARY, 
    PROMOTED_TO_ADMIN, 
    PROMOTED_TO_MODERATOR, 
    DEMOTED_TO_MODERATOR, 
    KICKED_FROM_TEAM
  }

  event PermissionsModified(address _address, RoleChange _roleChange);

  constructor (
    address[] memory _admins, 
    address[] memory _moderators
  ) {
    // require more admins for safety and backup
    uint256 adminsLength = _admins.length;
    require(adminsLength > 0, "no admin addresses");

    // make founder the admin and moderator
    admins[founder] = true;
    moderators[founder] = true;
    emit PermissionsModified(founder, RoleChange.MADE_FOUNDER);

    // give admin privileges, and also make admins moderators.
    for (uint256 i = 0; i < adminsLength; i++) {
      admins[_admins[i]] = true;
      moderators[_admins[i]] = true;
      emit PermissionsModified(_admins[i], RoleChange.PROMOTED_TO_ADMIN);
    }

    // give moderator privileges
    uint256 moderatorsLength = _moderators.length;
    for (uint256 i = 0; i < moderatorsLength; i++) {
      moderators[_moderators[i]] = true;
      emit PermissionsModified(_moderators[i], RoleChange.PROMOTED_TO_MODERATOR);
    }
  }

  modifier founderOnly() {
    require(
      msg.sender == founder,
      "not a founder."
    );
    _;
  }

  modifier adminOnly() {
    require(
      admins[msg.sender] == true,
      "not an admin"
    );
    _;
  }

  modifier moderatorOnly() {
    require(
      moderators[msg.sender] == true,
      "not a moderator"
    );
    _;
  }

  modifier addressMustNotBeFounder(address _address) {
    require(
      _address != founder,
      "address is founder"
    );
    _;
  }

  modifier addressMustNotBeAdmin(address _address) {
    require(
      admins[_address] != true,
      "address is admin"
    );
    _;
  }

  modifier addressMustNotBeModerator(address _address) {
    require(
      moderators[_address] != true,
      "address is moderator"
    );
    _;
  }

  modifier addressMustNotBeBeneficiary(address _address) {
    require(
      _address != beneficiary,
      "address is beneficiary"
    );
    _;
  }

  function founderOnlyMethod(address _address) external view {
    require(
      _address == founder,
      "not a founder."
    );
  }

  function adminOnlyMethod(address _address) external view {
    require(
      admins[_address] == true,
      "not an admin"
    );
  }

  function moderatorOnlyMethod(address _address) external view {
    require(
      moderators[_address] == true,
      "not a moderator"
    );
  }

  function addressMustNotBeFounderMethod(address _address) external view {
    require(
      _address != founder,
      "address is founder"
    );
  }

  function addressMustNotBeAdminMethod(address _address) external view {
    require(
      admins[_address] != true,
      "address is admin"
    );
  }

  function addressMustNotBeModeratorMethod(address _address) external view {
    require(
      moderators[_address] != true,
      "address is moderator"
    );
  }

  function addressMustNotBeBeneficiaryMethod(address _address) external view {
    require(
      _address != beneficiary,
      "address is beneficiary"
    );
  }

  function transferFoundership(address payable _founder) 
    external 
    founderOnly
    addressMustNotBeFounder(_founder)
    returns(address)
  {
    require(_founder != msg.sender, "not yourself");
    
    founder = _founder;
    admins[_founder] = true;
    moderators[_founder] = true;

    emit PermissionsModified(_founder, RoleChange.MADE_FOUNDER);

    return founder;
  }

  function changeBeneficiary(address payable _beneficiary) 
    external
    adminOnly
    returns(address)
  {
    require(_beneficiary != msg.sender, "not yourself");
    
    beneficiary = _beneficiary;
    emit PermissionsModified(_beneficiary, RoleChange.MADE_BENEFICIARY);

    return beneficiary;
  }

  function addAdmin(address _admin) 
    external 
    adminOnly
    returns(address) 
  {
    admins[_admin] = true;
    moderators[_admin] = true;
    emit PermissionsModified(_admin, RoleChange.PROMOTED_TO_ADMIN);
    return _admin;
  }

  function removeAdmin(address _admin) 
    external 
    adminOnly
    addressMustNotBeFounder(_admin)
    returns(address) 
  {
    require(_admin != msg.sender, "not yourself");
    delete admins[_admin];
    emit PermissionsModified(_admin, RoleChange.DEMOTED_TO_MODERATOR);
    return _admin;
  }

  function addModerator(address _moderator) 
    external 
    adminOnly
    returns(address) 
  {
    moderators[_moderator] = true;
    emit PermissionsModified(_moderator, RoleChange.PROMOTED_TO_MODERATOR);
    return _moderator;
  }

  function removeModerator(address _moderator) 
    external 
    adminOnly
    addressMustNotBeFounder(_moderator)
    addressMustNotBeAdmin(_moderator)
    returns(address) 
  {
    require(_moderator != msg.sender, "not yourself");
    delete moderators[_moderator];
    emit PermissionsModified(_moderator, RoleChange.KICKED_FROM_TEAM);
    return _moderator;
  }
}