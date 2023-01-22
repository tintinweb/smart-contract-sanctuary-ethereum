pragma solidity ^0.8.17;

import "./msgGreper.sol";

contract MessageRetriever {

 event LogMsg(
    address sender,
    string message,
	uint time
);
    function getMessage(address msgContractAddr) public {
        // Get the Message contract at the given address
        DeployMessage msgContract = DeployMessage(msgContractAddr);
        // Return the message stored in the contract
        emit LogMsg(msgContract.Address(), msgContract.Message(), msgContract.Time());
    }
}

//grep-er.eth grep-er.me 🄯