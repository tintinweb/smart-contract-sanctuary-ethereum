// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
  function addr(bytes32 node) public view virtual returns (address);
}

contract Registry {
  ENS public constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  mapping(address => address) public accounts;
  mapping(address => address) public burnerAccounts;

  event Register(address account, address burnerAccount);
  event UpdateBurnerAccount(address account, address burnerAccount);

  constructor() {}

  // given a namehash of an ENS name like 'olias.eth', this function returns the
  // address that 'olias.eth' points to
  function resolve(bytes32 node) public view returns (address) {
    Resolver resolver = ens.resolver(node);
    return resolver.addr(node);
  }

  function register(bytes32 ensNameHash, address burnerAccount) external {
    require(
      accounts[burnerAccount] == address(0),
      'burner account is already registered to another account'
    );
    require(
      burnerAccounts[msg.sender] == address(0),
      'sender has already registered a burner account'
    );
    require(msg.sender == resolve(ensNameHash), 'sender must have an ENS name');

    accounts[burnerAccount] = msg.sender;
    burnerAccounts[msg.sender] = burnerAccount;

    emit Register(msg.sender, burnerAccount);
  }

  function updateBurnerAccount(address burnerAccount) external {
    require(
      accounts[burnerAccount] == address(0),
      'burner account is already registered to another account'
    );
    require(burnerAccounts[msg.sender] != address(0), 'sender has not registered a burner account');

    accounts[burnerAccount] = msg.sender;
    burnerAccounts[msg.sender] = burnerAccount;

    emit UpdateBurnerAccount(msg.sender, burnerAccount);
  }
}