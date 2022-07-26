/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity ^0.4.8;

contract slotEvent {
    
    mapping (address => uint) public playerList; 
    uint256 public contractBalance;

    //events
    event reward(uint value, address winner);
    
    function slotEvent() public {
    }
    
    function () payable public {
        start();
    }
    
    function start() public payable {
        
        uint256 userBalance = msg.value;
        require(userBalance > 0);
        uint randomValue = random();
        playerList[msg.sender] = randomValue;
        contractBalance = address(this).balance;
            
        if(randomValue > 50){    
            
            uint256 winBalance = userBalance * 2;
            if(contractBalance < winBalance){
                winBalance = contractBalance;
            }
            msg.sender.transfer(winBalance); 
            contractBalance = address(this).balance;  
            emit reward(winBalance, msg.sender);   //winner event    
        }
        
    }
    
    function random() view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp)) % 100) + 1; // 1 ~ 100 (Only for testing.)
    }
}