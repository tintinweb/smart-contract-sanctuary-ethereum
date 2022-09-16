/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Lottery {

    receive() external payable{}
    
    address public owner;

    // variable store multiple winning Number

    uint[4] private  winningNumber;


    mapping (address => bool) private  records; // uint => lottery number, bool => is used or not
    mapping (address => uint[4]) private  userDetails;



    constructor(address _admin){
        owner = _admin;
    }

    modifier checkEthVal(uint _amount){
        require(msg.value>=_amount, "Provide valid amount");
        _; // like continue 
    }

    // check only owner can do this
    modifier checkOwner(){
        require(msg.sender==owner,"Only owner has access");
        _;
    }

    modifier checkValidVal(uint[4] calldata _arr){
        require(_arr.length==4,"please provide valid number");
        _;
    }


    function buyTicket(uint[4] memory val) external payable  checkEthVal(10000) validateNum(val){

        require(!records[msg.sender],"user already registered.");

        uint[4] memory newArr;

        newArr = val;
        userDetails[msg.sender] = newArr;

    }

    modifier validateNum(uint[4] memory val){
        for(uint i=0; i<val.length;i++){
            require(val[i]>0 && val[i]<15,"please choose number between 0 to 15.");
        }
        _;
    }

    

    function winningNum(uint[4] memory num) external checkOwner validateNum(num){
        require((winningNumber[0]<=0),"lottery number already decided");
        winningNumber = num;
    }

    function withDrawAmount() public {
        require(address(this).balance>0,"lottery is over");
        require(userDetails[msg.sender][0]>0,"you are not authorized user");
        
        uint rewardPer = checkWinNum(userDetails[msg.sender]);
        require(rewardPer>1,"try next time.");
        uint amount =  (address(this).balance*rewardPer*10)/100;
        (bool status, )= (msg.sender).call{value:amount}("");
        require(status,"eth not sent");
    }

    function checkWinNum(uint[4] memory val) private view returns (uint){
        uint counter;
        for(uint i=0; i<winningNumber.length;i++){
            if(val[i]==winningNumber[i]){
                counter++;
            }
        }
        return  counter;
    }

    function checkEthBal() view public  returns (uint){
        return  address(this).balance;
    }


 }