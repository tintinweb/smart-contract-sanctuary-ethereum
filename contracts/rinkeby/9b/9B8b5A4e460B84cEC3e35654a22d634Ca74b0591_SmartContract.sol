// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Question.sol";
import "./User.sol";

contract SmartContract is Ownable{
    uint public challengeCost = 0.0001 ether;
    uint public challengePrize = 0.0002 ether;
    uint public challengeAnswerCount = 2;
    uint public waitUserCount = 2;
    
    Question public newQuestion;
    User[] public Users;
    //mapping(address => User) ParticipantMap;
    address[] public Winners;

    //Creates Question
    function createQuestion(
        string memory _desc, 
        uint _date, 
        string[3] memory _hints,
        string memory _answer) public onlyOwner()
    {
        newQuestion = Question(_desc, challengePrize, _date, _hints, _answer, false, true);

        clearUsers();
    }

    function getQuestion() public view returns(Question memory)
    {
        return newQuestion;
    }

    function getUsers() public view returns(User[] memory)
    {
        return Users;
    }

    function getWinners() public view returns(address[] memory)
    {
        return Winners;
    }

    function clearUsers() public {
        //If users exist, clean up
        if(Users.length > 0){
            for(uint i=0;i<=Users.length;i++){
                Users.pop();
            }
        }
    }
    //Joins Challenge
    function joinChallenge() public payable
    {
        //Is challenge started or waiting participant?
        require((newQuestion.qState && !newQuestion.qWait) || (!newQuestion.qState && newQuestion.qWait), "Challenge not started yet!");
        //Is Participant exist?
        require(!checkParticipant(msg.sender).isJoined, "User is already joined!");
        require(msg.value >= challengeCost, "MATIC value sent not valid!");

        User memory newUser = User(msg.sender, 0, challengeAnswerCount, true);
        Users.push(newUser);

        if(Users.length >= waitUserCount){
            newQuestion.qState = true;
            newQuestion.qWait = false;
        }
    }
    
    //Checks Answer
    function checkAnswer(string memory _answer) public payable returns(bool)
    {   
        //Is challenge started or waiting participant?
        require(newQuestion.qState && !newQuestion.qWait, "Challenge not started yet!");
        //Is Participant exist?
        require(checkParticipant(msg.sender).isJoined, "User not joined!");
        require(checkParticipant(msg.sender).uAnswerCount > 0, "User has not answer count, enough!");


        //If answer true, stop the challenge and send the coin to winner
        if(keccak256(abi.encodePacked(newQuestion.qAnswer)) == keccak256(abi.encodePacked(_answer)))
        {
            //Sending prize to winner
            payable(msg.sender).transfer(newQuestion.qPrize);//0,00001

            //Challenge is ending
            newQuestion.qDesc = "";
            newQuestion.qPrize = 0;
            newQuestion.qDate = 0;
            newQuestion. qHints = ["","",""];
            newQuestion.qAnswer = "";
            newQuestion.qState = false;
            newQuestion.qWait = false;

            //Participants cleaning
            clearUsers();

            //Only the last 10 winner storing
            if(Winners.length == 10){
                for(uint i=0;i<10;i++)
                    Winners.pop();
            }
            Winners.push(msg.sender);
            return true;   
        }
        else{
            //Decreasing msg.sender answer count
            for(uint i=0;i<Users.length;i++){
                if(Users[i].uWallet == checkParticipant(msg.sender).uWallet)
                    Users[i].uAnswerCount--;
            }
            return false;
        }
    }

    function checkParticipant(address _userAddress) public view returns(User memory)
    {
        User memory user;
        for(uint i=0; i<Users.length; i++)
        {
            //If user exist and joined
            if(Users[i].uWallet == _userAddress && Users[i].isJoined)
                user = Users[i];
        }
        return user;
    }

    function isUserJoined(address _userAddress) public view returns(bool){
        for(uint i=0; i<Users.length; i++)
        {
            //If user exist and joined
            if(Users[i].uWallet == _userAddress && Users[i].isJoined)
                return true;
        }
        return false;
    }
    
    //Parameter type is must be wei
    function withdraw(uint _amount) public onlyOwner() {
        payable(msg.sender).transfer(_amount);
    }

    /*Set Functions*/
    function changeStartedState() public onlyOwner()
    {
        newQuestion.qState = !newQuestion.qState;
    }

    function changeWaitingState() public onlyOwner()
    {
        newQuestion.qWait = !newQuestion.qWait;
    }

    function setChallengeCost(uint _newCost) public onlyOwner(){
        challengeCost = _newCost;
    }

    function setAnswerCount(uint _newCount) public onlyOwner(){
        challengeAnswerCount = _newCount;
    }

    function setWaitUserCount(uint _newCount) public onlyOwner(){
        waitUserCount = _newCount;
    }
    /*Set Functions END*/
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

struct User{
    address uWallet;
    uint uHintCount;//0->3
    uint uAnswerCount;//2->0
    bool isJoined;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

struct Question{
    string qDesc;
    uint qPrize;//must be wei
    uint qDate;
    string[3] qHints;
    string qAnswer;
    bool qState;
    bool qWait;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}