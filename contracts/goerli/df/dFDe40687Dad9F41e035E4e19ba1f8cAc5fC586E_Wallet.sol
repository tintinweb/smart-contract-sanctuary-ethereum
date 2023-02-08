/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wallet {

    mapping(address => uint) balances;
    mapping(address => string) passwords;
    mapping(address => bool) loggedIn;
    mapping(string => uint) stringToInt;
    mapping(uint => string) intToString;
    mapping(address => uint) secretRecoveryPhrases;
    mapping(address => bool) secretRecoveryPhraseExists;
    mapping (address => uint) plan;
    mapping (address => uint) depositTime;
    string[12][] sentencesAsWords;


    constructor() {
        sentencesAsWords.push(["Mr","and","Mrs","Dursley,","of","number","four,","Privet","Drive,","were","proud","to"]);
        sentencesAsWords.push(["say","that","they","were","perfectly","normal,thank","you","very","much.","They","were","the"]);
        sentencesAsWords.push(["last","people","you would","expect","to","be","involved","in","anything","strange","or","mysterious,"]);
        sentencesAsWords.push(["because","they","just","did not","hold","with","such","nonsense.Mr","Dursley","was","the","director"]);
        sentencesAsWords.push(["of","a","firm","called","Grunnings,","which","made","drills.","He","was","a","big,"]);
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        msg.sender))) % sentencesAsWords.length;
    }

    function getSecretRecoveryPhrase() public view returns (string[12] memory){
        require(secretRecoveryPhraseExists[msg.sender],"Please generate your secret recovery phrase first");
        return sentencesAsWords[secretRecoveryPhrases[msg.sender]];
    }


    function generateSecretRecoveryPhrase() private {
        uint r = random();
        secretRecoveryPhraseExists[msg.sender] = true;
        secretRecoveryPhrases[msg.sender] = r;
    }

    function deposit(uint _plan) public payable {
        require(loggedIn[msg.sender] == true, "User not logged in");
        require( _plan == 3 || _plan == 6 || _plan == 12, "Please enter a valid plan");
        require(msg.value > 0,"Please enter a valid amount to deposit");
        uint numPeriods = block.timestamp - depositTime[msg.sender];
        uint interestRate;
        if(plan[msg.sender]!=0){
            if(plan[msg.sender]==3){
                numPeriods /= (90 days);
                interestRate = 105;
            }
            if(plan[msg.sender]==6){
                numPeriods /= (180 days);
                interestRate = 107;
            }
            if(plan[msg.sender]==12){
                numPeriods /= (360 days);
                interestRate = 111;
            }
            balances[msg.sender] = (balances[msg.sender]*(interestRate**numPeriods))/(100**numPeriods);
        }
        balances[msg.sender] += msg.value;
        depositTime[msg.sender] = block.timestamp;
        plan[msg.sender] = _plan;
    }

    function withdraw(uint _amountInWei) public {
        require(loggedIn[msg.sender] == true, "User not logged in");
        require(_amountInWei > 0 && _amountInWei <= balances[msg.sender],"Insufficient balance");
        (bool success, ) = msg.sender.call{value:_amountInWei}("");
        require(success, "Withdrawal failed.");
        balances[msg.sender] -= _amountInWei;
    }

    function checkBalance() public view returns (uint256) {
        require(loggedIn[msg.sender] == true, "User not logged in");
        uint numPeriods = block.timestamp - depositTime[msg.sender];
        uint interestRate;
        if(plan[msg.sender]!=0){
            if(plan[msg.sender]==3){
                numPeriods /= (90 days);
                interestRate = 105;
            }
            if(plan[msg.sender]==6){
                numPeriods /= (180 days);
                interestRate = 107;
            }
            if(plan[msg.sender]==12){
                numPeriods /= (360 days);
                interestRate = 111;
            }
            return (balances[msg.sender]*(interestRate**numPeriods))/(100**numPeriods);
        }
        return 0;
    }

    function transfer(address _to, uint _amountInWei) public {
        require(loggedIn[msg.sender] == true, "User not logged in");
        require(balances[msg.sender] >= _amountInWei && _amountInWei > 0,"Transfer failed insufficient balance");
        balances[msg.sender] -= _amountInWei;
        balances[_to] += _amountInWei;
    }

    function register(string memory _password) public {
        passwords[msg.sender] = _password;
        generateSecretRecoveryPhrase();
    }

    // used to check if 2 strings are equal
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function login(string memory _password) public {
        require (compareStrings(passwords[msg.sender],_password),"please enter the correct password");
        loggedIn[msg.sender] = true;

    }

    function logout() public {
        require(loggedIn[msg.sender],"You are not logged in");
        loggedIn[msg.sender] = false;
    }

}