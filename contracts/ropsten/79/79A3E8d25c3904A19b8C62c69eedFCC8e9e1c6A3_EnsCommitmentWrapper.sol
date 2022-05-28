/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.4.18;

contract EnsCommitmentWrapper {
    
    ETHRegistrarController c;

    address private owner;

    function EnsCommitmentWrapper() public {
        owner = msg.sender;
        c = ETHRegistrarController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);
    }

    function commit(bytes32 _commitment) public {
        return c.commit(_commitment);
    }

}

contract ETHRegistrarController {
    function commit(bytes32 commitment) public;
}