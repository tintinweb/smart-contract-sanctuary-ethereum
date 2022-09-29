// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

error Bank__InsufficientFunds();

error Bank__NotOwner();

/**
 * @author Jesus Badillo
 * @dev A smart contract to keep track of the transactions within a smart contract(i.e a peer to peer bank)
 */
contract Bank {
    address private immutable i_bankOwner;
    string private s_bankName;
    mapping(address => uint256) private s_customerBalance;

    modifier onlyOwner() {
        if (msg.sender != i_bankOwner) {
            revert Bank__NotOwner();
        }
        _;
    }

    constructor() {
        i_bankOwner = msg.sender;
    }

    function depositMoney() public payable {
        if (msg.value == 0) {
            revert Bank__InsufficientFunds();
        }

        s_customerBalance[msg.sender] += msg.value;
    }

    function setBankName(string memory _bankName) external {
        if (msg.sender != i_bankOwner) {
            revert Bank__NotOwner();
        }
        s_bankName = _bankName;
    }

    function withdrawMoney(address payable _to, uint256 _total) public {
        if (s_customerBalance[msg.sender] < _total) {
            revert Bank__InsufficientFunds();
        }

        s_customerBalance[msg.sender] -= _total;
        _to.transfer(_total);
    }

    function getCustomerBalance() external view returns (uint256) {
        return s_customerBalance[msg.sender];
    }

    function getBankOwner() public view onlyOwner returns (address) {
        return i_bankOwner;
    }

    function getBankBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getBankName() public view returns (string memory) {
        return s_bankName;
    }
}