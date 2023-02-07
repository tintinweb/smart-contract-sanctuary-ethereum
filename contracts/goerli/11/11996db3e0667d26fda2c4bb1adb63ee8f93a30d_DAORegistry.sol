// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract DAORegistry {
  event DAORegistered(address indexed dao, address indexed creator, string subdomain);

  function emitTestEvent(address _dao, address _creator, string memory _subdomain) public {
    emit DAORegistered(_dao, _creator, _subdomain);
  }
}