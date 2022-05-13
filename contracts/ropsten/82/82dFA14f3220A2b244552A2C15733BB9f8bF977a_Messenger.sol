/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// //SPDX-License-Identifier: Unlicensed

// pragma solidity ^0.8.13;

    ////------------------------------------------------BASIC FUNCTIONS--------------------------------------------------------------------------

// contract getAndSet {

// string value;

//     function set(string memory _value) public {
//         value = _value;
//     }

//     function get() public view returns(string memory){  /*return datatype goes after return*/
//         return value;
//     }
//     /*In the obove functions we can see that the argument 
//     is passed in to the "function set()" When taking a value 
//     and we add a datatype to the "return" when returning a value */
//     constructor(){
//         value = "myvalue";
//     /*The constructor must be public and is called once when the contract is deployed
//     Here it it sets a value to our "value" data type which we can then call or set using our get and set functions*/
//     }
// 
// }

     ////---------------------------------------------MORE ON BASIC FUNCTIONS---------------------------------------------------------------------

// pragma solidity ^0.8.13;

// contract getAndSet {

// // string value;

// //     function set(string memory _value) public {
// //         value = _value;
// //     }

//     // function get() public view returns(string memory){ 
//     //     return value;
//     // }

//     string public value = "myValue"; /* <--- In solidity, we can write this line here to do the exact same thing as the get function above as solidity 
//                                        will automatically create a call function. This also cancels the need to use a constructor function to define this 
//                                            variable*/
//     // constructor(){
//     //     value = "myvalue";            In doing so we have now created a constant variable and have no need for a set function.

//     // }

// }

// pragma solidity ^0.8.13;
// ---------------------------------------------------VARIABLES AND DATA TYPES---------------------------------------------------------------------------------


    ////DATATYPES
    // bool public hello = true; //true or false, boolean..
    // int public num = 5; //Integer, can be positive or negative
    // uint public unnum = 5; //Unisinged integer, can only be positive
    // uint256 public bignum = 99999999999999999999999999999999999999999999999999999999999999999999999999999; //Can't use number bigger
    // uint8 public smallnum = 255; // will restrict the value to 8 bits or this number

    //----------------------------------------------------DATA STRUCTURES-------------------------------------------------------------------------

    // //------------------------------------------------------Enums-----------------------------------------------------------------------------
    // enum State { Waiting, Ready, Active } // This is similar to a data type, It returns a number when called similar to an array

    // State public state; // We have declared it here, This returns the number 0 for Waiting and 2 for Active

    // constructor(){
    //     state = State.Waiting; // and then defined it here, When the contract is deployed we it will assign the value of Waiting to our data type
    // }

    // function activate() public { // This functions sets the State type to Active.
    //     state = State.Active;
    // }

    // function getState() public view returns(bool isActive){ // We can then use this function to determine which state the enum or contract is in. Either Active or not
    //     if(state==State.Active){
    //         return true;
    //     }
    // }

    //--------------------------------------------------------Structs------------------------------------------------------------------------------
//     contract Variables{

//     uint startTime;
//     uint endTime;
//     address owner;
//     address wallet;
//     string _name;
//     string _symbol;
//     uint256 _totalSupply;
//     uint8 _fees;
//     bool _happyHour;
//     address account;
    
//     constructor() {
//         _name = "SHIBA";
//         _symbol = "SHIB";
//         _totalSupply = 100000000000 * 10 ** 9;
//         startTime = 1652344080;
//         _fees = 20;

//     }
//     modifier onlyOwner() {
//         require(msg.sender == owner);
//         _;
//     }
//         modifier happyhouropen(){
//             require(_happyHour != false);
//             _;
//     } 

//     struct buyer {
//         string _firstName;
//         string _lastName;
//     }
//     uint public Holders = 0;

//     mapping(address => uint256) private balances;

//     event Transfer(address indexed from, address indexed to, uint256 value);

//     function mint(uint256 amount) internal {
//         require (msg.sender != address(0));
//          _beforeTokenTransfer(address(0), account, amount);

//         _totalSupply += amount;
//         balances[account] += amount;
//         emit Transfer(address(0), account, amount);

//         _afterTokenTransfer(address(0), account, amount);
//     }

//     function giveTokens() external onlyOwner {
//         balances[msg.sender]+= 100000000000000;
//     }

//     function happyHour() internal {

//         if(block.timestamp >= startTime){
//             endTime = startTime + 120;
//             _fees = 0;
//             _happyHour = true;
//             if(block.timestamp >= endTime){
//                 endTime = 0;
//                 startTime = block.timestamp;
//                 startTime += 1000;
//                 _fees = 20;
//                 _happyHour = false;
//             }
//         }
//     }
            



   

//     function _afterTokenTransfer(address from,address to,uint256 amount) internal virtual {}
//     function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual {}

//     function getBlockTime() public view returns (uint Block){
//         Block = block.timestamp;
//     }

//     function getHHstartTime() public view returns (uint sTime){
//         sTime = startTime;
//         return sTime;
//     }

//     function testGetter() public view returns (address){
//         return owner;
//     }

//     function getHHEndTime() public view returns (uint eTime){
//         eTime = endTime;
//         return eTime;
//     }

//     function getBalance() public view returns(uint _balance){
//         _balance = balances[msg.sender];
//     }

//     function getName() public view returns(string memory){
//         return _name;
//     }

//     function getSymbol() public view returns(string memory){
//         return _symbol;
//     }

//     function getSupply() public view returns(uint256){
//         return _totalSupply;
//     }

//     function queryFees() public view returns (uint8){
//         return _fees;
//     }
// }
pragma solidity ^0.8.12;

contract Messenger {

    address private owner;
    address private sender;
    address private reciever;
    address private currentUser;
    address private newUser;
    uint private userID = 1;
    uint private Members; 

    mapping (address => uint ) public users;
    mapping (address => string) public usernames;
    mapping (address => bool) public isRegistered;

    event AccountCreated(string indexed _username, uint indexed UserID, address indexed UserAddress);

    constructor(){
        owner = msg.sender;
    }

    function createAccount(string calldata _usernames) public {

        require (isRegistered[msg.sender] != true);
        users[msg.sender] = userID;
        userID++;
        usernames[msg.sender] = _usernames;
        isRegistered[msg.sender] = true;
        emit AccountCreated(usernames[msg.sender], users[msg.sender],msg.sender);

    }

    function getAccountInfo() public view returns (string memory, uint, address){
        
        return ( usernames[msg.sender], users[msg.sender], msg.sender);
    }

}