/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PayForMinting {
    address payable public owner = payable(msg.sender);

    // FIXME using small testnet values, figure out real values!
    uint256 private constant costToCustomizeVal = 400;
    uint256 private constant costToMintVal = 200;

    event PaidForMinting(string indexed _dragon_wallet, uint8 _payment_level);
    event CollectedFunds(uint256 _amount);

    /// @param _dragon_wallet The Dragon Wallet string that is receiving payment.
    function payForMinting(string calldata _dragon_wallet) external payable {
        require(msg.value == costToCustomizeVal || msg.value == costToMintVal);

        emit PaidForMinting(_dragon_wallet, msg.value == costToCustomizeVal ? 2 : 1);
    }

    function claimFunds() external {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit CollectedFunds(balance);
    }

    function costs() external pure returns (uint256 mint, uint256 customize) {
        mint = costToMintVal;
        customize = costToCustomizeVal;
    }
}