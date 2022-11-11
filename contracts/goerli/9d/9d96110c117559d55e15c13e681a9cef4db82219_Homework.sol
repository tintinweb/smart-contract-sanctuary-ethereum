//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
contract Homework{
function GetRandomNumber()public pure returns(uint){return 7;}

function PayMeHomework() external payable{
    uint256 randomnumber=GetRandomNumber();
    if (randomnumber%2==0){
    uint256 ethrefund=(msg.value);
    payable (msg.sender).transfer(ethrefund);
}
    else if (randomnumber%2!=0){
    uint256 ethrefund=(msg.value/2);
    payable (msg.sender).transfer(ethrefund);
}

    else{ 
        require (randomnumber==9, "9 doesn't work");
}  
}}