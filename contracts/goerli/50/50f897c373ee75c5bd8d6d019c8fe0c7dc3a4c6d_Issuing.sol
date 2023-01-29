/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Factory {
    address public CreditAgricoleAddress;
    struct Contract {
        uint time;
        address owner;
    }
    Contract[] public contracts;
    address[] public contractsDeployed;

    modifier onlyCA(){
        require(msg.sender == CreditAgricoleAddress);
        _;
    }

    constructor() {
        CreditAgricoleAddress = msg.sender;
    }

    function createContract(uint time) public  {
        Contract memory newContract;
        newContract.time = time;
        newContract.owner = msg.sender; 
        contracts.push(newContract);
    }


    function deployContract(address owner) public onlyCA{
        Contract storage contractOwner = contracts[0]; 
        uint256 i;

        for(i = 0; i < contracts.length; i++){
            Contract storage contratto = contracts[i];
            if(contratto.owner == owner){
                contractOwner = contratto;
            }
        }
        
        address newIssuing = address ( new Issuing(contractOwner.time, contractOwner.owner));

        contractsDeployed.push((newIssuing));
    }
}

contract Issuing {
    uint tempo;
    address public owner;
    constructor (uint time,address propietario) {
        tempo = time;
        owner = propietario;
    }
}