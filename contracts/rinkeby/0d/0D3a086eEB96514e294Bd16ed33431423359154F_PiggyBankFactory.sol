// SPDX-License-Identifier:MIT
pragma solidity ^0.8.3;

import "./PiggyBank.sol";

contract PiggyBankFactory {
    address[] public banks;

    function bankCount() external view returns (uint totalBank) {
        totalBank = banks.length;
    }

    function getBanks() external view returns (address[] memory allBanks) {
        allBanks = banks;
    }

    function createBank() external returns (address newPiggyBank) {
        bytes memory bytecode = type(PiggyBank).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

        assembly {
            newPiggyBank := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        banks.push(newPiggyBank);
    }
}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.3;

contract PiggyBank {
    event Deposit(uint amount);
    event Withdraw(uint amount);

    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "no funds deposited");
        // payable(msg.sender).transfer(address(this).balance);
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    function getContractBalance() external view returns (uint bal) {
        bal = address(this).balance;
    }
}