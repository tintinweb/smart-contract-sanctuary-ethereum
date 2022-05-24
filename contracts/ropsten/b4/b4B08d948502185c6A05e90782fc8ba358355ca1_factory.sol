/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity ^0.8.7;



contract factory {
    uint256 public lastID = 0;
    address public addresses;

    function NewContract() public {
        address NewC = address(new test());
        addresses = NewC;
        lastID = lastID + 1;
    }

    
}



contract test {
    string public How = "ThisWorked";
}