// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IStorage {

    function store(uint256 num) external;
}

contract RefStorage {

    // uint256 public number;
    event ABC(bool index, bytes val);

    uint256 public number;
    address public sender;
    address public origin;

    // event AAA(address sender, uint256 val);

    function val_change() public {
        number = 456;
    }

    function delegatecall(address addr, uint256 num) public payable {
        // s_val.store(num);

        bytes memory v = abi.encodeWithSignature("store(uint256)", num);
        (bool success, bytes memory data) = addr.delegatecall(v);
        emit ABC(success, data);
    }

    function call(address addr, uint256 num) public payable {
        // s_val.store(num);

        bytes memory v = abi.encodeWithSignature("store(uint256)", num);
        (bool success, bytes memory data) = addr.call(v);
        emit ABC(success, data);
    }

    function staticcall(address addr, uint256 num) public payable {
        // s_val.store(num);

        bytes memory v = abi.encodeWithSignature("store(uint256)", num);
        (bool success, bytes memory data) = addr.call(v);
        emit ABC(success, data);
    }
}