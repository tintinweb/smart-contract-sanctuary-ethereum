// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {BytesLib} from "./bytes.sol";
import "./ERC20.sol";

contract FToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        address minter
    ) ERC20(name, symbol) {
        // send all supply to minter
        _mint(minter, cap);
    }
}

contract FTokenFactory {
    using BytesLib for bytes;

    struct Token {
        string name;
        string symbol;
        uint256 cap;
        uint128 trace;
        address minter;
    }

    address public owner;
    address public receiver;
    mapping(address => Token) tokens;

    constructor(address _owner, address _receiver) {
        owner = _owner;
        receiver = _receiver;
    }

    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "Only owner can transfer ownership");
        owner = _owner;
    }

    function setReceiverAddress(address _receiver) public {
        require(msg.sender == owner, "Only owner can update receiver address");
        receiver = _receiver;
    }

    function readToken(address _address) public view returns (Token memory) {
        return tokens[_address];
    }

    function createContract(
        string memory name,
        string memory symbol,
        uint256 cap,
        uint128 trace
    ) public {
        require(msg.sender == owner, "Only owner can create contracts");

        uint256 balance = cap * 10**18;
        FToken ftoken = new FToken(name, symbol, balance, address(this));
        ftoken.transfer(receiver, balance);

        Token memory token = Token({
            name: name,
            symbol: symbol,
            cap: cap,
            trace: trace,
            minter: receiver
        });
        tokens[address(ftoken)] = token;
    }

    function createContractRaw(bytes memory raw) public {
        require(msg.sender == owner, "Only owner can create contracts");

        uint256 offset;
        uint8 size;
        string memory name;
        string memory symbol;
        uint256 cap;
        uint128 trace;

        while (offset < raw.length) {
            size = raw.toUint8(offset);
            offset = offset + 1;
            require(
                size > 0 && offset + size <= raw.length,
                "invalid data: name size"
            );
            name = string(raw.slice(offset, size));
            offset = offset + size;

            size = raw.toUint8(offset);
            offset = offset + 1;
            require(
                size > 0 && offset + size <= raw.length,
                "invalid data: symbol size"
            );
            symbol = string(raw.slice(offset, size));
            offset = offset + size;

            require(offset + 8 <= raw.length, "invalid data: cap size");
            cap = raw.toUint64(offset);
            require(cap > 0, "invalid cap size");
            offset = offset + 8;

            size = raw.toUint8(offset);
            offset = offset + 1;
            require(
                size == 16 && offset + size <= raw.length,
                "invalid data: trace size"
            );
            trace = raw.toUint128(offset);
            offset = offset + size;

            createContract(name, symbol, cap, trace);
        }
    }
}