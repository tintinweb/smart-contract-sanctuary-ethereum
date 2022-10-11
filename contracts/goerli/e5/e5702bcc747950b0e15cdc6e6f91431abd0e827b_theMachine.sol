/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

// INFO 
// theMachine is a framework on top of which you can build your own contract
// with a simple interface containing advanced safety, prebuilt functions and
// a simple way to add your own functions.
// With theMachine you can rely on proven methods and can ensure to your users
// a battle-proven basic set of features without having to rely on untested
// or unproven code.

// Features:
// - Automatic reentrancy protection
// - Ownable and authorizable methods and security
// - Common framework with mutual communication
// - Low gas expenses
// - Constant updates and improvements
//
// Examples:
// - You can create a standard iContract by using the method
//  `create_iContract` in theMachine, obtaining a standard iContract
//  owned by you. 
// - You can self-destruct your contract by calling `destroy` in theMachine.
// - You can set an authority to your contract by calling `set_authority` in
//  theMachine.
// - You can set the owner of your contract by calling `set_owner` 
//  in theMachine.

pragma solidity ^0.8.17;

// ANCHOR Base protection mechanism
contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

// ANCHOR Interface
// NOTE This will be used to interact with the machine
interface iMachine {
    function register_contract() external;
    function create_iContract() external returns(address);
    // SECTION Contract management
    function destroy(address _contract) external;
    function set_authority(address _contract, address addy, bool booly) external;
    function set_owner(address _contract, address addy) external;
    // !SECTION Contract management
}

// ANCHOR Contract interface
// NOTE This is the interface for the contract that will be registered
interface iContract {
    // SECTION Machine methods
    function destroy() external;
    function set_authority(address addy, bool booly) external;
    function set_owner(address addy) external;
    // !SECTION Machine methods
    // SECTION Contract methods
    function getOwner() external view returns(address);
    function set_machine(address addy) external;
    // !SECTION Contract methods
    // TODO
}


// ANCHOR - theMachine.sol
// NOTE This is theMachine itself and contains methods to register
// and use contracts that implement the iContract interface.
// NOTE theMachine is able to register multiple contracts and control them
// in a trustless way and in a single place, serving as a control panel for
// all the contracts it manages.
// NOTE theMachine is not capable of control contracts in place of their
// owners, so it is not possible to use it to steal funds or to control
// contracts that are not owned by the sender.
contract theMachine is protected, iMachine {

    // SECTION Global variables and types

    struct REGISTERED_CONTRACT {
        iContract Contract;
        address owner;
        mapping (address => bool) is_auth;
        bool is_active;
        // TODO
    }

    mapping (address => REGISTERED_CONTRACT) registered_contracts;

    // !SECTION Global variables and types

    constructor () {
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    // SECTION Methods

    function create_iContract() public override safe 
                                returns(address new_contract) {
        new_contract = address(new theContract(address(this)));
        iContract newContract = iContract(new_contract);
        newContract.set_owner(msg.sender);
        newContract.set_authority(msg.sender, true);
        newContract.set_machine(address(this));
        newContract.set_authority(msg.sender, true);
        register_internal_contract(new_contract);
        return new_contract;
    }

    function register_internal_contract(address _contract) internal {
        registered_contracts[_contract].Contract = iContract(_contract);
        registered_contracts[_contract].owner = iContract(_contract).getOwner();
        registered_contracts[_contract].is_active = true;
    }

    // !SECTION Methods

    // SECTION External functions

    function register_contract() public override safe {
        iContract Contract;
        Contract = iContract(msg.sender);
        registered_contracts[msg.sender].Contract = Contract;
        registered_contracts[msg.sender].owner = Contract.getOwner();
        registered_contracts[msg.sender].is_active = true;
    }

    function destroy(address _contract) public override safe {
        require(registered_contracts[_contract].is_active, "contract not registered");
        // NOTE destroy() can be called by the owner or the contract instance
        require(registered_contracts[_contract].owner == msg.sender, "not owner");
        registered_contracts[_contract].Contract.destroy();
        registered_contracts[_contract].is_active = false;
    }

    
    function set_authority(address _contract, address addy, bool booly) 
                           public override safe{
        require(registered_contracts[_contract].is_active, "contract not registered");
        // NOTE can be called by the owner or the contract instance
        require(registered_contracts[_contract].owner == msg.sender, "not owner");
        registered_contracts[_contract].Contract.set_authority(addy, booly);
    }

    function set_owner(address _contract, address new_owner) public override safe {
        require(registered_contracts[_contract].is_active, "contract not registered");
        // NOTE can be called by the owner or the contract instance
        require(registered_contracts[_contract].owner == msg.sender, "not owner");
        registered_contracts[_contract].Contract.set_owner(new_owner);
    }

    // !SECTION External functions

}

// SECTION theContract implementation

// ANCHOR - theContract.sol
// NOTE This is an example contract that will be registered with the machine
// NOTE This can be deployed by anyone using the machine itself
// NOTE Most of the methods are implemented in theMachine and are called
// through theMachine itself
contract theContract is protected, iContract {

    // SECTION Security

    modifier onlyMachine() {
        require(msg.sender==machine, "not machine");
        _;
    }

    // !SECTION Security

    // SECTION Global variables and types

    address machine;
    iMachine Machine;

    // !SECTION Global variables and types

    constructor (address _machine) {
        owner = msg.sender;
        is_auth[msg.sender] = true;
        machine = _machine;
        Machine = iMachine(machine);
        Machine.register_contract();
    }

    // SECTION Machine Methods

    function destroy() public override onlyMachine {
        selfdestruct(payable(owner));
    }

    function set_authority(address addy, bool booly) 
                           public override onlyMachine {
        is_auth[addy] = booly;
    }

    function set_owner(address new_owner) public override onlyMachine {
        owner = new_owner;
    }


    // !SECTION Machine Methods

    // SECTION Contract functions

    // SECTION Getters
    function getOwner() public override view returns(address) {
        return owner;
    }
    // !SECTION Getters

    // SECTION Setters
    function set_machine(address addy) 
                         public override onlyOwner {
        machine = addy;
    }
    // !SECTION Setters

    // !SECTION Contract functions

}


// !SECTION theContract implementation