//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0; //enforcing compiler version 0.8 or above

interface IOwnable {
    // Event emitted when ownership is transferred
    event OwnershipTransferred(address newOwner);

    // Transfers ownership to a new address
    function transferOwnership(address newOwner) external;

    // Returns the current owner of this contract
    function owner() external view returns (address);
}

interface IPausable {
    // Toggles the pause status of the contract
    // Hint: Who should be able to call this?
    function togglePause() external;

    // Returns if the contract is currently paused
    function paused() external view returns (bool);
}

interface ISplitter {
    // Event emitted when funds are deposited and split
    event DidDepositFunds(uint256 amount, address[] recipients);
    // Event emitted when funds are withdrawn
    event DidWithdrawFunds(uint256 amount, address recipient);

    // The caller deposits some amount of Ether and splits it among recipients evenly
    // This function cannot be called if the contract is paused
    function deposit(address[] calldata recipients) external payable;

    // The caller can withdraw a valid amount of Ether from the contract
    // This function cannot be called if the contract is paused
    function withdraw(uint256 amount) external;

    // Returns the current balance of an address
    function balanceOf(address addr) external view returns (uint256);
}

contract HW4 is IOwnable, IPausable, ISplitter {
    // solhint-disable ordering
    function getMax(uint256[] calldata array) external pure returns (uint256) {
        //declaring a function named getMaximum that takes in an array of uint256 named "array". Setting it to external and pure , and telling it to return a uint256.
        // Write your code here
        uint256 largestNum = 0; //declare a uint256 variable, name it largestNum and set it equal to 0.
        for (uint256 i = 0; i < array.length; i++) {
            //declare a for-loop that declares a uint256 called i and initializes it to 0 (we set i to 0 because 0 is the first spot in the index always (from left to right)). When i is still smaller than the length of this array, I am going to increment it by 1 and then run the following code.
            if (array[i] > largestNum) {
                //if or when the current value of i (which points at the index spot in the array) is greater than the largestNum in the array,
                largestNum = array[i]; //then for whatever value index spot i points to in the new array created, set it equal to the largestNum variable
            }
        }
        return largestNum; //return the variable largestNum
    }

    // Declare any necessary variables here
    address private _owner; //declaring an address that represents the owners address
    bool private _paused; //declaring a boolean variable called paused (default boolean value is false). This is in order to keep tracking of the contract being paused or not.
    mapping(address => uint256) private _balanceOf; //declaring a mapping that maps an address to a uint256 and naming it _balanceOf. This is in order to keep track of all the users.

    //private visibility for the declared variables

    // What goes in here?
    constructor() {
        //constructor is run the moment the contract is deployed and runs once.
        _owner = msg.sender; //set variable _owner, which is an address, to the owner of the contract.
    }

    // Add any modifiers here
    modifier onlyOwnerAccess() {
        //declaring a modifier and naming it onlyOwnerAccess. This modifier will check if the person deploying is the owner.
        require(_owner == msg.sender, "Not the owner"); //require the address that is deploying the contract to be the owner of the contract. If it is not then give message, "Not the owner".
        _; //signifies end of modifier
    }

    modifier onlyNotPaused() {
        //declaring a modifier and naming it onlyNotPaused. This is for checking if the contract is not paused.
        require(!_paused, "Need to unpause to call"); //require not paused to be true (i.e., the contract is unpaused). If this contract is paused, then display message, "Neeed to unpause to call".
        _; //signifies end of modidier
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyOwnerAccess
    {
        //add onlyOwnerAccess modifier to this declared function so only the owner can call this function.
        // Write your code here
        _owner = newOwner; //set the variable _owner to equal newOwner. Initiating transfer of ownership.
        emit OwnershipTransferred(newOwner); //we are emmitting this event now because a state change happened and we want to communicate that with the outside world.
    }

    function togglePause() external override {
        // ...
        _paused = !_paused; //this is how you flip the boolean. This is so you can toggle the pause. SO if the pause variable is true then change it to false and if it is false then change it to true.
    }

    function deposit(address[] calldata recipients)
        external
        payable
        override
        onlyNotPaused
    {
        //added onlyNotPaused modifier in order to require that the function is called only when the contract is not paused.
        uint256 depositWeiAmount = msg.value; //declaring a unit256 variable called depositWeiAmount and setting it equal to msg.value. Msg.value denotes the amount of wei sent in the transaction.
        uint256 numOfRecipients = recipients.length; //decalring a uint256 variable that basically represents the number of recipients. I do this by setting it equal to the length of the array of addresses that is taken in in the function parameter. For example, if there is 5 addressess (i.e., 5 recipients), then this variable will equal the length of the array, which would be 5 in this case.
        //now I must divide the deposit of Wei evenly among the number of recipients there are. I'll declare a unit256 variable that represents each share. Shown on next line:
        uint256 weiAmountForRecipient = depositWeiAmount / numOfRecipients;
        //Now I must loop through the array of addresses. I have the mapping _balanceOf in order to keep track of the balance. For each recipient, we increase there balance in the mapping by the weiAmountForRecipient.
        for (uint256 i = 0; i < recipients.length; i++) {
            //typical declaration of a for-loop. Initializes i to 0 and saying that when i is less than the length of the recipients array then increment i and run the following code:
            _balanceOf[recipients[i]] += weiAmountForRecipient; // Again, for each recipient, we increase there balance in the mapping by the weiAmountForRecipient.
        }
        emit DidDepositFunds(depositWeiAmount, recipients); //emitting the event to notify state change, that the funds have been deposited. The two thinmgs taken in the parameter suggest
    }

    function withdraw(uint256 amount) external override onlyNotPaused {
        //Again, added onlyNotPaused modifier in order to require that the contract not be paused when calling this function. Also, notice that this function is taking in a uint256 named "amount".
        require(_balanceOf[msg.sender] >= amount, "Balance too low."); //creating a require statement that ensures that the balance of the address of the person deploying the contract is greater than or equal to the amount (i.e., then number or value withdrawn). If what is withdrawn is greater than the balance of the address calling than display message that Balance too low.
        //I must minus the withdrawn amount from the balance of the address of the person calling the contract. Shown right below this line:
        _balanceOf[msg.sender] -= amount; //There. IN the mapping _balanceOf, the balance that msg.sender points to must have the amount (which represents the amount withdrawn) subtracted from it.
        //Now I must transfer the requested amount to the person who is calling. Shown below:
        payable(msg.sender).transfer(amount); //
        emit DidWithdrawFunds(amount, msg.sender); //emitting the event of funds being withdrawn.
    }

    function owner() external view override returns (address) {
        return _owner; //return the _owner variable
    }

    function paused() external view override returns (bool) {
        return _paused; //return the _paused variable
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _balanceOf[addr]; //returns the balance of any given user that the address maps to in the mappping.
    }
}