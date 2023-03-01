/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// Root file: contracts/CashRushPool.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract CashRushPool {
    uint256 public constant DELAY = 5 days;
    uint256 public constant SHARES = 50;
    uint256 public lastDeposit = 0;
    uint256 public nextId = 0;
    mapping(uint256 => address) public accounts;
    mapping(address => bool) public depositors;

    event Received(address indexed account, uint256 value);
    event Deposited(address indexed account, uint256 id, uint256 value);
    event Distributed(address indexed account, uint256 id, uint256 value);

    constructor(address[] memory _depositors) public {
        for (uint256 i = 0; i < _depositors.length; i++) {
            depositors[_depositors[i]] = true;
        }
    }

    modifier onlyDepositors() {
        require(depositors[msg.sender], "Not allowed");
        _;
    }

    function distribute() external {
        require(block.timestamp >= (lastDeposit + DELAY), "Too early");
        uint256 shares = _min(SHARES, nextId);
        uint256 value = address(this).balance / shares;
        for (uint256 i = 1; i <= shares; i++) {
            uint256 id = nextId - i;
            address payable recipient = payable(accounts[id]);
            recipient.transfer(value);
            emit Distributed(recipient, id, value);
        }
    }

    function deposit(address account)
        external
        payable
        onlyDepositors
        returns (bool)
    {
        lastDeposit = block.timestamp;
        uint256 id = nextId++;
        accounts[id] = account;
        emit Deposited(account, id, msg.value);
        return true;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return a;
        else return b;
    }
}