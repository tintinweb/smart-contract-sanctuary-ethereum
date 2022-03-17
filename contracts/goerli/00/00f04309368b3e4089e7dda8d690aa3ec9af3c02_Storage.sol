/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address[] public oracle;

    function set(address[] memory addr) public {
        oracle = addr;
    }
}


// Basketcoin Governance Platform
// We needs a governance platform where users can vote with the help of Basketcoin native
// tokens (BSKT)( staked tokens + tokens in wallet) and NFTs collection.
// Requirements
// Ref: https://vote.makerdao.com/
// According to the reference given we needs 2 kinds of voting (executive and polling).
// Voting with BasketCoin:
// 1 coin = 1 voting power
// Staked coin (https://bscscan.com/address/0xe0c255a5d89b6d9fedb5c4e43c11341a072e3bcc#code)
// +
// Coins in wallet (Coin address: https://bscscan.com/token/
// 0x4dd1984a706e1c2c227bea67ad2f92dbde30afce )
// Added voting power with NFTs
// There will be 54 NFT cards minted with Basketcoin (Not to be done by us)
// For NFT voting power & multiplier refer the pdf shared before.
// Points to keep in mind:
// • There will be no delegation of voting powers.
// • Anyone who have 5k+ (can be variable & changeable) voting power can create proposal.
// • Executive proposals can only be created by admins.
// • NFTs voting power and multiplier are not hardcoded. They should be changeable.
// • Include test cases (truffle will be preferred).
// References
// https://vote.makerdao.com/ (Polling & Executive feature)