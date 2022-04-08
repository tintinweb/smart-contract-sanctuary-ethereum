pragma solidity >= 0.7;

contract Vault {

    address sender;
    uint256 depositTime;

    receive() external payable {
        // mi segno chi ha mandato i soldi
        // mi segno a che ora/data li ha depositati
        sender = msg.sender;
        depositTime = block.timestamp;
    }

    function redeem() external {
        // controlla che sia passato il tempo giusto
        // controlla che il chiamante sia quello
        // che aveva depositato
        require(block.timestamp >= depositTime + 5 minutes, "il vault e' ancora bloccato");
        require(msg.sender == sender);
        payable(msg.sender).send(address(this).balance);
    }

}