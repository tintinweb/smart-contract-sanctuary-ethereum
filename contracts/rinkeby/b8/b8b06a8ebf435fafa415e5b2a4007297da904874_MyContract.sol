/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract MyContract {
        string value;
        constructor() public {
                value = "myValue";
        }

function get() public view returns(string) {
                return value;
        }

function set(string _value) public {
        value = _value;
        }
}