// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";

contract FirnLunarDAOEscrow {
    address public constant LUNAR_DAO = payable(0x59F77dC848C2E45B5954975ee1969e7A22fA25F6);
    address public constant FIRN_MULTISIG = payable(0xa14664a2E58e804669E9fF1DFbC1bD981E13B0dC);
    ERC20 public immutable firnToken = ERC20(0xDDEA19FCE1E52497206bf1969D2d56FeD85aFF5c);

    uint256 public constant VESTING_DATE = 1717214400; // 01-06-2024, at 04:00:00 GMT. 1 year from vote date.

    uint256 public constant ETHER_AMOUNT = 36417 * 1e15; // 36.417 ether.
    uint256 public constant FIRN_AMOUNT = 4888 * 1e18; // FIRN: $13.81. take $67,500 / that. round up.
    bool public dealStatus = false;

    receive() external payable { // receive ether, i.e. as a payout from Firn fees.

    }

    function sweepFunds() external { // callable by anyone; sweeps balance to the LunarDAO
        (bool success, ) = payable(LUNAR_DAO).call{value: address(this).balance}(""); // will throw on failure
        require(success, "Transfer failed.");
    }

    function executeDeal() external payable {
        require(!dealStatus, "Deal already done."); // this can easily be avoided, just as an additional safety measure
        require(msg.value == ETHER_AMOUNT, "Wrong amount of ether supplied.");
        require(firnToken.balanceOf(address(this)) == FIRN_AMOUNT, "Token balance is wrong."); // can also be checked explicitly, just to be safe
        dealStatus = true; // prevents Firn from exiting on line 36

        (bool success, ) = payable(FIRN_MULTISIG).call{value: msg.value}(""); // will throw on failure
        require(success, "Transfer failed.");
    }

    function earlyExit() external { // Firn calls this to reclaim token if there is no deal.
        require(!dealStatus, "Deal has been completed.");
        firnToken.transfer(FIRN_MULTISIG, firnToken.balanceOf(address(this)));
    }

    function vest() external { // LunarDAO calls this after a year to claim their token.
        require(block.timestamp >= VESTING_DATE, "Hasn't vested yet.");
        firnToken.transfer(LUNAR_DAO, firnToken.balanceOf(address(this)));
    }
}