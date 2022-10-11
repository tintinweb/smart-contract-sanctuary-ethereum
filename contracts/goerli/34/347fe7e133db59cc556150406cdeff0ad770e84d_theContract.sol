/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

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
    }

    // SECTION Machine Methods

    function destroy() public override onlyMachine {
        selfdestruct(payable(owner));
    }

    function set_authority(address addy, bool booly) 
                           public override onlyMachine {
        is_auth[addy] = booly;
    }

    function set_owner(address new_owner) 
                       public override onlyMachine {
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


// USAGE
// You can import this contract and use it as a base for your own contracts.
// For example:
// 
// import "thisContract.sol";
// contract yourContract is theContract {
//     [your code]
// }
//
// This way you already have a basic set of features and a simple way to
// add your own functions.
//
// You could also build your own contract from scratch, but you would have
// to implement all the features yourself, which is not recommended.
// It is anyway possible to do it if you want to have a more custom contract.