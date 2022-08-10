/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title BountyBucksEscrow
 * @dev Manages fund transfers between two parties
 */
contract BountyBucksEscrow {
    // Wallet address of the payer
    address public daofund;
    // Wallet address of the intended bountyhunter
    address public bountyhunter;

    /// Lock Up Defined Crypto Value
    /// @param counterpart the address of the intended bountyhunter
    /// @dev Lock Up crypto for the counterpart
    function fund(address counterpart) public payable {
        bountyhunter = counterpart;
        daofund = msg.sender;
    }

    /// Release Locked Up Funds
    /// @dev The deal is done, let only the payer release fund.
    function release() public payable {
        if (msg.sender==daofund){
            // Transfer all the funds to the bountyhunter
            payable(bountyhunter).transfer(address(this).balance);
        }
    }

    /// Return the locked value.
    /// @dev Anyone Should Be Able to View Locked Up Crypto Assets
    /// @return the crypto value
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}