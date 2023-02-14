/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wallet {

    mapping(address => uint) balances;
    mapping(address => string) passwords;
    mapping(address => string[12]) secretRecoveryPhrases;
    mapping (address => uint) plan;
    mapping (address => uint) depositTime;
    string[] words;


    constructor() {
        words.push("sticky");
        words.push("gruesome");
        words.push("ban");
        words.push("abundant");
        words.push("frequent");
        words.push("yellow");
        words.push("behavior");
        words.push("blush");
        words.push("poised");
        words.push("cluttered");
        words.push("kettle");
        words.push("alcoholic");
        words.push("print");
        words.push("loving");
        words.push("alluring");
        words.push("spare");
        words.push("doctor");
        words.push("planes");
        words.push("buzz");
        words.push("shy");
        words.push("inject");
        words.push("rest");
        words.push("weary");
        words.push("hypnotic");
        words.push("cook");
        words.push("teeny-tiny");
        words.push("craven");
        words.push("push");
        words.push("husky");
        words.push("tan");
        words.push("tacit");
        words.push("giants");
        words.push("disturbed");
        words.push("noisy");
        words.push("orange");
        words.push("ordinary");
        words.push("lewd");
        words.push("rhyme");
        words.push("harsh");
        words.push("uncle");
        words.push("analyze");
        words.push("fumbling");
        words.push("used");
        words.push("zealous");
        words.push("zippy");
        words.push("complain");
        words.push("damp");
        words.push("unknown");
        words.push("tedious");
        words.push("direful");
        words.push("sleet");
        words.push("squealing");
        words.push("label");
        words.push("madly");
        words.push("soggy");
        words.push("jail");
        words.push("unequaled");
        words.push("needless");
        words.push("quiver");
        words.push("kick");
        words.push("receptive");
        words.push("mix");
        words.push("borrow");
        words.push("scene");
        words.push("moon");
        words.push("mint");
        words.push("defective");
        words.push("disgusting");
        words.push("cowardly");
        words.push("pour");
        words.push("tight");
        words.push("fertile");
        words.push("astonishing");
        words.push("refuse");
        words.push("spiritual");
        words.push("obeisant");
        words.push("valuable");
        words.push("park");
        words.push("haunt");
        words.push("wilderness");
        words.push("rural");
        words.push("determined");
        words.push("burn");
        words.push("excite");
        words.push("pear");
        words.push("unique");
        words.push("machine");
        words.push("insidious");
        words.push("juggle");
        words.push("tendency");
        words.push("vase");
        words.push("concentrate");
        words.push("terrific");
        words.push("advertisement");
        words.push("busy");
        words.push("pigs");
        words.push("playground");
        words.push("alive");
        words.push("tomatoes");
        words.push("distinct");
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        msg.sender))) % words.length;
    }

    function getSecretRecoveryPhrase() public view returns (string[12] memory){
        return secretRecoveryPhrases[msg.sender];
    }

    function shuffle() private view returns (uint256[12] memory) {
        uint256[12] memory _arr = [uint256(0),uint256(1),uint256(2),uint256(3),uint256(4),uint256(5),uint256(6),uint256(7),uint256(8),uint256(9),uint256(10),uint256(11)];
        for (uint256 i = 0; i < 12; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (12 - i);
            uint256 temp = _arr[n];
            _arr[n] = _arr[i];
            _arr[i] = temp;
        }
        return _arr;
    }

    function generateSecretRecoveryPhrase() private {
        uint r = random();
        for(uint i=0;i<12;i++){
            secretRecoveryPhrases[msg.sender][i] = words[(r+i)%words.length];
        }
        string[12] memory temp = secretRecoveryPhrases[msg.sender];
        uint256[12] memory ind = shuffle();
        for(uint256 i=0;i<12;i++){
            secretRecoveryPhrases[msg.sender][i] = temp[ind[i]]; 
        }
    }

    function deposit(uint _plan) public payable {
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

    function withdraw(uint _amountInGwei) public {
        uint256 _amountInWei = _amountInGwei*(10**9);
        require(_amountInWei > 0 && _amountInWei <= balances[msg.sender],"Insufficient balance");
        (bool success, ) = msg.sender.call{value:_amountInWei}("");
        require(success, "Withdrawal failed.");
        balances[msg.sender] = checkBalance();
        depositTime[msg.sender] = block.timestamp;
        balances[msg.sender] -= _amountInWei;
    }

    function checkBalance() public view returns (uint256) {
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
        return balances[msg.sender];
    }

    function checkBalance(address _account) private view returns (uint256) {
        uint numPeriods = block.timestamp - depositTime[_account];
        uint interestRate;
        if(plan[_account]!=0){
            if(plan[_account]==3){
                numPeriods /= (90 days);
                interestRate = 105;
            }
            if(plan[_account]==6){
                numPeriods /= (180 days);
                interestRate = 107;
            }
            if(plan[_account]==12){
                numPeriods /= (360 days);
                interestRate = 111;
            }
            return (balances[_account]*(interestRate**numPeriods))/(100**numPeriods);
        }
        return 0;
    }


    function transfer(address _to, uint _amountInGwei) public {
        uint256 _amountInWei = _amountInGwei*(10**9);
        require(balances[msg.sender] >= _amountInWei && _amountInWei > 0,"Transfer failed insufficient balance");

        balances[msg.sender] = checkBalance();
        depositTime[msg.sender] = block.timestamp;
        balances[msg.sender] -= _amountInWei;

        balances[_to] = checkBalance(_to);
        depositTime[_to] = block.timestamp;
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

    function login(string memory _password) public view returns (bool) {
        if(compareStrings(passwords[msg.sender],_password)){
            return true;
        }else return false;
    }

}