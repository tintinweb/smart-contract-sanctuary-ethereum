/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Trickster
/// @author https://twitter.com/mattaereal
/// @notice We might have spotted a honeypot... Anon, can you manage to obtain the real jackpot?
/// @custom:url https://www.ctfprotocol.com/tracks/eko2022/trickster
contract Jackpot {
    address private jackpotProxy;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initialize(address _jackpotProxy) public payable {
        jackpotProxy = _jackpotProxy;
    }

    modifier onlyJackpotProxy() {
        require(msg.sender == jackpotProxy);
        _;
    }

    function claimPrize(uint256 amount) external payable onlyJackpotProxy {
        payable(msg.sender).transfer(amount * 2);
    }

    fallback() external payable {}

    receive() external payable {}
}