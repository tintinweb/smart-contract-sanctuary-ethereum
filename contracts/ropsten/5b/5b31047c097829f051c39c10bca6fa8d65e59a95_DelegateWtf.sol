/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
     _      _                  _                _    __ 
    | |    | |                | |              | |  / _|
  __| | ___| | ___  __ _  __ _| |_ _____      _| |_| |_ 
 / _` |/ _ \ |/ _ \/ _` |/ _` | __/ _ \ \ /\ / / __|  _|
| (_| |  __/ |  __/ (_| | (_| | ||  __/\ V  V /| |_| |  
 \__,_|\___|_|\___|\__, |\__,_|\__\___(_)_/\_/  \__|_|  
                    __/ |                               
                   |___/                                
*/

contract DelegateWtf {

  event DelegationSet(address _delegator, address _delegatee);
  event DelegationRemoved(address _delegator, address _delegatee);
  event LockSet(address _delegator, address _delegatee);

  // Storing delegations in both directions
  mapping(address => address) public delegatorToDelegatee;
  mapping(address => address) public delegateeToDelegator;

  //Lock allows to set the only address as a delegator; delegatee => delegator
  mapping(address => address) public delegatorLock;


  // Main delegation function
  function delegate(address _to) public {

    /*
      Delegation can be done if at least one of the conditions:
      1. No delegator set for given address + no lock set for given address
      2. No delegator set for given address + lock is set to the given address
    */
    require(delegateeToDelegator[_to] == address(0), "Delegator has already been set for this address");
    require(delegatorLock[_to] == address(0) || delegatorLock[_to] == msg.sender, "Given address has a lock for a different delegator");
    
    delegatorToDelegatee[msg.sender] = _to;
    delegateeToDelegator[_to] = msg.sender;

    emit DelegationSet(msg.sender, _to);
  }

  // Called by either delegator or delegatee
  function resetDelegation() public {

    address _delegatee = delegatorToDelegatee[msg.sender];
    address _delegator = delegateeToDelegator[msg.sender];

    // If delegatee  called the smart contract
    if (_delegatee != address(0)) {
      _delegator = delegateeToDelegator[_delegatee];
      emit DelegationRemoved(_delegator, _delegatee);

      delegatorToDelegatee[_delegator] = address(0);
      delegateeToDelegator[_delegatee] = address(0);
      return;
    }
    
    // If delegator called the smart contract
    if (_delegator != address(0)) {
      _delegatee = delegatorToDelegatee[_delegator];
      emit DelegationRemoved(_delegator, _delegatee);

      delegateeToDelegator[delegatorToDelegatee[_delegatee]] = address(0);
      delegatorToDelegatee[_delegatee] = address(0);
      return;
    }
  }

  /*
    Called by delegatee;
    Sets lock to certain address; if delegator is set for this delegatee and differs from
    the lock address -- delegation is being reset
  */ 
  function setLock(address _lockAddress) public {

    if (delegateeToDelegator[msg.sender] != address(0) && delegateeToDelegator[msg.sender] != _lockAddress) {
      delegatorToDelegatee[delegateeToDelegator[msg.sender]] = address(0);
      delegateeToDelegator[msg.sender] = address(0);
    }

    delegatorLock[msg.sender] = _lockAddress;
    emit LockSet(_lockAddress, msg.sender);
  }


  // Returns delegatee or zero address
  function getDelegatee(address _delegator) public view returns(address) {
    return delegatorToDelegatee[_delegator];
  }

  // Returns delegatee or zero address
  function getDelegator(address _delegatee) public view returns(address) {
    return delegateeToDelegator[_delegatee];
  }

}