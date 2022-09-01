/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract PoolMatrixGame {

    address public owner;
    uint256 balance;
    address referrer;

    event ContractCreated(string msg, address indexed owner);
    event TestEvent(string msg);
    event TestEvent2(string msg, uint value);
    event PaymentReceived(string msg, address indexed owner, address indexed sender, uint value);

    constructor() {
        owner = msg.sender;
        emit ContractCreated("Contract has been created", owner);
    }

    receive() payable external {
        emit PaymentReceived("Payment received!", msg.sender, msg.sender, msg.value);
        balance += msg.value;
    }

    fallback() external payable {
        bytes memory data = msg.data;
        address ref;

        assembly {
            ref := mload(data)
        }

        emit PaymentReceived("Fallback function executed", ref, msg.sender, msg.data.length);
        //balance = abi.decode(msg.data, (uint));
        //referrer = abi.decode(msg.data, (address));
    }

    function bytesToAddress(bytes memory _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }

    function getRefAddr() internal pure returns(address parsedReferrer) {
        bytes memory data = msg.data;
        assembly {
            parsedReferrer := mload(data)
            //parsedReferrer := mload(add(data,0x14))
        }
        return parsedReferrer;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function getReferrer() public view returns(address) {
        return referrer;
    }
}