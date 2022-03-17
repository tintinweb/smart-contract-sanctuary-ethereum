/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.4.24;

contract MyContract {
        string value;

function get() public view returns(string) {
                return value;
        }

function set(string _value) public {
        value = _value;
        }
}