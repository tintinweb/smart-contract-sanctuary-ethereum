/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

pragma solidity ^0.8.0;

contract SecretPassword {
    mapping(address => uint) balances;
    mapping(address => bytes32) hashedPasswords;

    event Deposit(address indexed from, uint value);
    event Withdraw(address indexed to, uint value);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function setPassword(string memory password) public {
        require(bytes(password).length >= 10, "Password must be at least 10 characters long");
        require(hasLowerCase(password), "Password must contain at least one lowercase letter");
        require(hasUpperCase(password), "Password must contain at least one uppercase letter");
        require(hasSymbol(password), "Password must contain at least one symbol");
        bytes32 hashedPassword = keccak256(bytes(password));
        hashedPasswords[msg.sender] = hashedPassword;
    }

    function withdraw(uint amount, string memory password) public {
        bytes32 hashedPassword = keccak256(bytes(password));
        require(hashedPasswords[msg.sender] == hashedPassword, "Incorrect password");
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function hasLowerCase(string memory str) private pure returns (bool) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bytes1 char = bStr[i];
            if (char >= 0x61 && char <= 0x7A) {
                return true;
            }
        }
        return false;
    }

    function hasUpperCase(string memory str) private pure returns (bool) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bytes1 char = bStr[i];
            if (char >= 0x41 && char <= 0x5A) {
                return true;
            }
        }
        return false;
    }

    function hasSymbol(string memory str) private pure returns (bool) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bytes1 char = bStr[i];
            if (char < 0x30 || (char > 0x39 && char < 0x41) || (char > 0x5A && char < 0x61) || char > 0x7A) {
                return true;
            }
        }
        return false;
    }
}