//Specifies the version of solidity , using semantic versioning.
//Learn more: 
pragma solidity >= 0.7.3;

//Defines a contract named `HelloWorld`.
//A contract is a colletion of functions and data (its state).
//Once deployed, a contract resides at a specific address on the Ethereum blockchain 
contract HelloWorld {

    //Emitted when update function is called
    //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
    event UpdatedMessages(string oldStr, string newStr);

    //Declares a state variable `message` of type `string`.
    //State variables are variables whose values are permanently stored in a contract sotrage.
    //The keyword `public ` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
    string public message;

    constructor(string memory initMessage){
        //Accepts a string argument `initMessage` and sets the value into the contract
        message = initMessage;
    }

    //A public function that accepts a string argument and updates the `message` storage variable.
    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}