// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error UserRegistry_AccountExists();
error UserRegistry_NoAccount();

contract UserRegistry {
    mapping(address => bool) public accountCreated;
    mapping(address => string) private accountData;
    mapping(string => bool) private ppsExists;
    mapping(address => address) private managingContract;

    event createEvent(address indexed from, string message, bool indexed success);

    function createAccount(string memory msgArg, string memory pps) public {
        if (accountCreated[msg.sender] == true || ppsExists[pps] == true) {
            emit createEvent(msg.sender, "account Exists", false);
        } else{
            emit createEvent(msg.sender, "created Account", true);
            accountCreated[msg.sender] = true;
            accountData[msg.sender] = msgArg;
            ppsExists[pps] = true;
        }
    }

    function signIn() public view returns (string memory) {
        if (accountCreated[msg.sender] != true) {
            revert UserRegistry_NoAccount();
        }
        return accountData[msg.sender];
    }

    function changeDetails(string memory msgArgs) public {
        if (accountCreated[msg.sender] != true) {
            revert UserRegistry_NoAccount();
        }
        accountData[msg.sender] = msgArgs;
    }
}