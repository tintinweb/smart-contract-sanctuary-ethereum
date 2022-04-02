/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// Matt Gawin - Waste24.net Smart Contract

pragma solidity ^0.8.4;

contract Waste24IotContract {

    uint[]  listOfValidContracts;
    uint[]  private tempListOfContracts;


    function addNewContract(uint num) public {
        listOfValidContracts.push(num);
    }

    function removeContract(uint num) public {
        for (uint i; i< listOfValidContracts.length;i++) {
            if(listOfValidContracts[i]!=num)
            tempListOfContracts.push(listOfValidContracts[i]);
        }
        listOfValidContracts = tempListOfContracts;
        delete tempListOfContracts;
    }


    function getMyAddress() private returns (address) {
        address myAddress = msg.sender;
        return myAddress;
    }

    function checkContractExpired(uint number) public view returns (bool) {
        for (uint i; i< listOfValidContracts.length;i++){
            return listOfValidContracts[i]==number;
        }
        return false;
    }
}