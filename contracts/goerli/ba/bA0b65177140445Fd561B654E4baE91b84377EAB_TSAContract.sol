/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract TSAContract {
    address private _owner;
    uint256 private _count;

    mapping(bytes32 => uint256) private _stamps;

    constructor() {
        _owner = msg.sender;
        _count = 0;
    }

    function Count() public view returns (uint256) {
        return _count;
    }

    function StampID(bytes32 hash) public view returns (uint256) {
        return _stamps[hash];
    }

    function StampHash(bytes32 hash) public onlyOwner {
        uint256 id = NextID();
        _stamps[hash] = id;
    }

    function HashStamped(bytes32 hash) public view returns (bool) {
        return _stamps[hash] == 0;
    }

    function NextID() private returns (uint256) {
        _count++;
        return _count;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "No permission");
        _;
    }
   
}