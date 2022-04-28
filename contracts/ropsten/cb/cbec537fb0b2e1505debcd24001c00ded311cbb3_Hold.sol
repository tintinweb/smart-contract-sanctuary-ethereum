// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bank.sol";
import "./IERC20.sol";

contract Hold {
    mapping(address => address) bank;

    function getBank(address _addr) public view returns (address) {
        return bank[_addr];
    }

    function createBank(uint256 _unlockDate)
        public
        payable
        returns (address wallet)
    {
        address myBank = bank[msg.sender];

        if (myBank != address(0)) {
            return myBank;
        }

        Bank newBank = new Bank(msg.sender, _unlockDate);

        bank[msg.sender] = address(newBank);

        // Send ether from this transaction to the created contract.
        payable(address(newBank)).transfer(msg.value);

        // Emit event.
        emit CreateBank(
            wallet,
            msg.sender,
            block.timestamp,
            _unlockDate,
            msg.value
        );

        return address(newBank);
    }

    // Prevents accidental sending of ether to the factory
    fallback() external {
        revert();
    }

    event CreateBank(
        address wallet,
        address from,
        uint256 createdAt,
        uint256 unlockDate,
        uint256 amount
    );
}