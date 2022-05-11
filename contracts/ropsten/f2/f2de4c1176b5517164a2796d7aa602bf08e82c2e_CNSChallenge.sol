pragma solidity ^0.4.22;

import "./CNSToken.sol";

// interfaces that will be used
interface IFlashLoanReceiver {
    // Note: approve lender to tranfer your token in order to return the fund.
    function execute(address tokenAddr, address lender, uint256 amount) external returns (bool);
}

interface ICafeRacer {
    function name() external view returns (bytes32);
}

// the main challenge contract
contract CNSChallenge {
    address owner;
    CNSToken cnsToken;
    address public tokenAddr;

    struct Student {
        mapping (uint => bool) solved;
        uint score;
    }

    // studentID: lowercase and number. ex: r09902001
    mapping (string => Student) students;

    // challenge 0: call me, 2 points
    function callMeFirst(string studentID) public {
        uint challengeID = 0;
        uint point = 2;
        require(students[studentID].solved[challengeID] != true);
        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }

    // challenge 1: bribe me ether, 3 points
    function bribeMe(string studentID) public payable {
        uint challengeID = 1;
        uint point = 3;
        require(students[studentID].solved[challengeID] != true);
        require(msg.value == 1 ether);
        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }

    // challenge 2: guess random number, 5 points
    uint16 private next;
    uint public numberOfTry = 0;

    function random() internal returns (uint16) {
        next = next * 8191 + 12347;
        numberOfTry += 1;
        return next;
    }

    function guessRandomNumber(string studentID, uint16 numberGuessed) public {
        uint challengeID = 2;
        uint point = 7;
        require(students[studentID].solved[challengeID] != true);
        
        uint16 randomNumber = random();
        if (numberGuessed == randomNumber) {
            students[studentID].solved[challengeID] = true;
            students[studentID].score += point;
        }
    }
    
    // challenge 3: easy reentry, 5 points
    uint16 c3Flag = 0; 
    function reentry(string studentID) public {
        uint challengeID = 3;
        uint point = 8;
        require(students[studentID].solved[challengeID] != true);
        c3Flag += 1;
        msg.sender.call.value(0)();
        if(c3Flag == 2) {
            students[studentID].solved[challengeID] = true;
            students[studentID].score += point;
        }
        c3Flag = 0;
    }
    
    // challenge 4: prove that you have enough CNS tokens but not using flash loan!? 10 points
    uint8 public flashloaning = 0;
    function flashloan(uint256 amount) public {
        require(amount <= cnsToken.balanceOf(address(this)));
        flashloaning += 4;
        cnsToken.transfer(msg.sender,amount);
        require(IFlashLoanReceiver(msg.sender).execute(address(cnsToken), address(this), amount), "Flash loan execute error!");
        require(cnsToken.transferFrom(msg.sender,address(this),amount), "You need to return fund!");
        flashloaning -= 4;
    }
    
    function giveMeToken(string studentID) public {
        uint challengeID = 4;
        uint point = 10;
        require(flashloaning == 0, "You are doing flashloan!");
        require(students[studentID].solved[challengeID] != true);
        if(cnsToken.balanceOf(msg.sender) >= 10000) {
            students[studentID].solved[challengeID] = true;
            students[studentID].score += point;
            // give you one CNS token as reward!
            cnsToken.transfer(msg.sender,1);
        }
    }

    // bonus: only the TRUE cafe racer one can exectue this funciton! - 10 points
    bytes32 private password;
    function checkName(address _addr) view public returns (bool) {
        return ICafeRacer(_addr).name() == bytes32("cafe racer");
    }

    function checkAddress(address _addr) pure public returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 mask = hex"ffff000000000000000000000000000000000000";
        bytes20 prefix = hex"cafe000000000000000000000000000000000000";
        return addr & mask == prefix;
    }

    function secretFunction(string studentID, bytes32 _password) public {
        uint challengeID = 5;
        uint point = 10;
        require(checkName(msg.sender), "You are not a cafe racer!");
        require(checkAddress(msg.sender), "Your address is not cafe enough!");
        require(_password == password, "Incorrect password");
        students[studentID].solved[challengeID] = true;
        students[studentID].score += point;
    }

    // utilities
    function getScore(string studentID) view public returns (uint) {
        return students[studentID].score;
    }
    
    function getSolvedStatus(string studentID) view public returns (bool[]) {
        bool[] memory ret = new bool[](6);
        for(uint i = 0; i < 6; i++) {
            ret[i] = students[studentID].solved[i];
        }
        return ret;
    }
    
    function setTokenAddr(address _tokenAddr) public {
        require(msg.sender == owner);
        tokenAddr = _tokenAddr;
        cnsToken = CNSToken(_tokenAddr);
    }

    // contract initialization
    function CNSChallenge(bytes32 _password) public {
        owner = msg.sender;
        password = _password;
        next = uint16(keccak256(block.blockhash(block.number - 1), block.timestamp));
    }
    
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}