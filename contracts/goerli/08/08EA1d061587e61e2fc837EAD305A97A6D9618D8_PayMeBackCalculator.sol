//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
contract PayMeBackCalculator{
uint256  private number;
string private text;

function PayMeHomework(uint256 newNumber) external payable{
    number=newNumber;
    if(newNumber==9){
    text="9 doesn't work";
    }
    
    else if(newNumber%2==0){
    uint256 ethrefund=(msg.value);
    payable (msg.sender).transfer(ethrefund);
}
    else {
    uint256 ethrefund=(msg.value/2);
    payable (msg.sender).transfer(ethrefund);
}
}  
}