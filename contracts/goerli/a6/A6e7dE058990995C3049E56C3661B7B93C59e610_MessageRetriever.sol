pragma solidity ^0.8.17;

import "./msgGreper.sol";

contract MessageRetriever {
    function getMessage(address msgContractAddr) public view returns (string memory, address, uint) {
        // Get the Message contract at the given address
        DeployMessage msgContract = DeployMessage(msgContractAddr);
        
        // Return the message stored in the contract
        return (msgContract.Message(), msgContract.Address(), msgContract.Time());
    }
}

//grep-er.eth grep-er.me 🄯