pragma solidity ^0.8.0;

contract Vault {
    string private transferStatus;

    function transfertoendvault() public {
        // Perform transfer logic here
        // ...

        transferStatus = "Transfersuccess";
    }

    function getTransferStatus() public view returns (string memory) {
        return transferStatus;
    }
}

// Example usage:
contract Test {
    Vault private vault;

    constructor() {
        vault = new Vault();
    }

    function testTransfer() public {
        vault.transfertoendvault();
        string memory status = vault.getTransferStatus();
        // Do something with the status
    }
}