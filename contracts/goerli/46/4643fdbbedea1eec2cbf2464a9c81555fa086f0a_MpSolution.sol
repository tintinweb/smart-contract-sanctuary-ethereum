/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract MpSolution {
    address payable public immutable owner;
    address public challenge;

    constructor(address _challenge) {
        owner = payable(msg.sender);
        challenge = _challenge;
    }

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function attack() public onlyOwner {
        (bool success,) = challenge.call(abi.encodeWithSignature("exploit_me(address)", owner));
        assert(success);
    }

    function changeChallenge(address _newChallenge) public onlyOwner {
        assert(_newChallenge != address(0));
        challenge = _newChallenge;
    }

    fallback() external payable {
        assert (msg.sender == challenge);
        (bool success,) = challenge.call(abi.encodeWithSignature("lock_me()"));
        assert(success);
    }

    function destroy() external onlyOwner {
        selfdestruct(owner);
    }

}