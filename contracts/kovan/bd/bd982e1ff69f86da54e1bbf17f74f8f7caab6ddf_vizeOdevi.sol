/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.26;

contract vizeOdevi{
    int age = 17;
    function accessControl() public view returns (string) {  
        
        if(age < 18){
            return "You Can't Enter Here!!!";
        }
        else{
            return "You Can Enter Here!!!";
        }
}

    function accessControl_2() public view returns (string) {  
        age = age + 1;
        if(age < 18){
            return "You Can't Enter Here!!!";
        }
        else{
            return "You Can Enter Here!!!";
        }
}

}