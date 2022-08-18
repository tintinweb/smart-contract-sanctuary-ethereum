// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title Emiting events from within contract functions
/// @author kokocodes
/// @dev Contract emits profileupdated & fundsdeposited events in logic
/// @dev Contract extends logic from 03-TaskStructs.sol

contract miniDatabase{

    /// @dev UserInfo struct stores name, age and balance (in wei) of a specific user
    struct UserInfo{
        string name;
        uint8 age;
        uint256 balance;
    }

    /// @dev throw error if balance is less than withdrawal requested by user
    error Structs__NotEnoughBalance(address user, uint256 balance);

    /// @dev define events ProfileUpdated and FundsDeposited
    event FundsDeposited(address indexed user, uint256);
    event ProfileUpdated(address user);
    event ProfileDeleted(address user);


    /// @dev maps address against UserInfo for all users. Variable stored in Storage.
    mapping(address => UserInfo) public g_userDetails;

    // SET FUNCTIONS (CHANGE STATE)

    /// @dev assign balance against given address in mapping. Note that its a dummy transfer 
    /// @param _amount amount in wei
    function deposit(uint256 _amount) public {
        g_userDetails[msg.sender].balance += _amount;

        // Emitting FundsDeposited event on deposit
        emit FundsDeposited(msg.sender, _amount);
    }

    /// @dev withdraw existing balance against given address in mapping. Note that its a dummy transfer 
    /// @dev revert with an error if withdrawal amount is more than current balance
    /// @param _amount amount in wei
    function withdraw(uint256 _amount) public {
        if(_amount > g_userDetails[msg.sender].balance){
            revert Structs__NotEnoughBalance(msg.sender, g_userDetails[msg.sender].balance);
        }
        // Subtracting withdrawal amount from user balance
        g_userDetails[msg.sender].balance -= _amount;
    }
    
    /// @dev sets user details including name & age for a given address
    /// @dev note that _name is stored in calldata and not memory - because it is a payload of msg.sender
    /// @param _name name of user (string)
    /// @param _age age of user (note its in uint8 type)
    function setUserDetails(string calldata _name, uint8 _age) public {
        g_userDetails[msg.sender].name = _name;
        g_userDetails[msg.sender].age = _age;

        // Emitting ProfileUpdated event when updating user details for first time
        emit ProfileUpdated(msg.sender);
    }


   /// @dev Modifies user data for given user
   /// @dev emits ProfileUpdated event
   /// @param _name name of user. Stored in calldata
   /// @param _age age of use (uint8)
    function modifyUserDetails(string calldata _name, uint8 _age) public {
         g_userDetails[msg.sender].name = _name;
         g_userDetails[msg.sender].age = _age;

         //Emitting ProfileUpdated event when details are modified
         emit ProfileUpdated(msg.sender);
    }

    /// @dev Deletes all data stored in mapping for user address
    /// @dev emits ProfileDeleted event
    function deleteUserDetails() public {
        delete g_userDetails[msg.sender];

        //Emitting ProfileDeleted event when details are deleted for a given user
        emit ProfileDeleted(msg.sender);
    }

    // GET FUNCTIONS (PURE/VIEW)

    /// @dev Check balance for a given user address
    /// @return balance returns balance in wei 
    function checkBalance() public view returns(uint256 balance) {
        balance = g_userDetails[msg.sender].balance;
        return balance;
    }

    /// @dev Returns user details for a given address
    /// @return info user info that includes name, age and balance
    function getUserDetails() public view returns(UserInfo memory info){
        return g_userDetails[msg.sender];
    }

}