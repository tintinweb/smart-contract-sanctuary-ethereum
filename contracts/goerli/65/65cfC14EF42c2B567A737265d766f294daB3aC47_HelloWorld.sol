// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;


//memmory is a key variable for storing data
//You want your smart contract to have two compoents: state variables and functions that allow you read/write/modifify the state
contract HelloWorld{
    event UpdatedMessages(string oldStr, string newStr);
        //memmory is temporyary sstorage...hold temprotary values...it is erased between external calls
    string public message; /// this variable will be stored permantely on the blockchain
                ///message is the state variable we update
    constructor (string memory initMessage){

        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);


    } //access level
}