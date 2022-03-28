/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

/**
 * Chimp Authority Contract
 */
contract Authority {
    /* ========== EVENTS ========== */
    event OwnerPushed(address indexed from, address indexed to);
    event OwnerPulled(address indexed from, address indexed to);
    event AddManager(address[] addrs);
    event DeleteManager(address[] addrs);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    address public owner;
    address[] public managers;
    address public newOwner;

    constructor() {
        owner = msg.sender;
        managers.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, UNAUTHORIZED);
        _;
    }

    function pushOwner(address _newOwner, bool _effectiveImmediately)
        external
        onlyOwner
    {
        address oldOwner = owner;
        if (_effectiveImmediately) {
            owner = _newOwner;
        }
        newOwner = _newOwner;
        emit OwnerPushed(oldOwner, newOwner);
    }

    function pullOwner() external {
        require(msg.sender == newOwner, "Authority: not newOwner");
        emit OwnerPulled(owner, newOwner);
        owner = newOwner;
    }

    function addManager(address[] memory addrs) public virtual onlyOwner {
        require(addrs.length > 0, "Authority: addrs can't be null");
        for (uint256 i = 0; i < addrs.length; i++) {
            bool isManager;
            uint256 idx;
            (isManager, idx) = checkIsManager(addrs[i]);
            if (isManager) {
                continue;
            }
            managers.push(addrs[i]);
        }
    }

    function deleteManager(address[] memory addrs) public virtual onlyOwner {
        require(addrs.length > 0, "Authority: addrs can't be null");
        for (uint256 i = 0; i < addrs.length; i++) {
            bool isManager;
            uint256 idx;
            (isManager, idx) = checkIsManager(addrs[i]);
            if (!isManager) {
                continue;
            }
            delete managers[idx];
        }
    }

    function checkIsManager(address addr) public view returns (bool, uint256) {
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}