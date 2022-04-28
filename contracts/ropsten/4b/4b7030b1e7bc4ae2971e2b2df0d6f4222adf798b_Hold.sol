// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bank.sol";
import "./IERC20.sol";

contract Hold {
    mapping(address => address) bank;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getBank(address _addr) public view returns (address) {
        return bank[_addr];
    }

    function createBank(uint256 _unlockDate)
        public
        payable
        returns (address wallet)
    {
        address myBank = bank[msg.sender];

        if (myBank != address(0)) {
            return myBank;
        }

        Bank newBank = new Bank(msg.sender, _unlockDate);

        bank[msg.sender] = address(newBank);

        // Send ether from this transaction to the created contract.
        payable(address(newBank)).transfer(msg.value);

        // Emit event.
        emit CreateBank(
            wallet,
            msg.sender,
            block.timestamp,
            _unlockDate,
            msg.value
        );

        return address(newBank);
    }

    function deposit() public payable {
        require(bank[msg.sender] != address(0));

        payable(bank[msg.sender]).transfer(msg.value);

        emit Received(msg.sender, msg.value);
    }

    function withdraw() public returns (uint256) {
        require(bank[msg.sender] != address(0));

        Bank myBank = Bank(payable(bank[msg.sender]));

        uint256 tokenBalance = myBank.withdraw();

        emit Withdrew(msg.sender, tokenBalance);

        return tokenBalance;
    }

    function depositTokens(address _tokenContract, uint256 amount) public {
        require(bank[msg.sender] != address(0));

        Bank myBank = Bank(payable(bank[msg.sender]));

        myBank.depositTokens(_tokenContract, amount);

        emit DepositTokens(_tokenContract, msg.sender, amount);
    }

    function withdrawTokens(address _tokenContract) public returns (uint256) {
        require(bank[msg.sender] != address(0));

        Bank myBank = Bank(payable(bank[msg.sender]));

        uint256 tokenBalance = myBank.withdrawTokens(_tokenContract);

        emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);

        return tokenBalance;
    }

    function setUnlockDate(uint256 _unlockDate) public {
        require(bank[msg.sender] != address(0));
        Bank myBank = Bank(payable(bank[msg.sender]));

        myBank.setUnlockDate(_unlockDate);

        emit SetUnlockDate(msg.sender, _unlockDate);
    }

    function getUnlockDate() public view returns (uint256) {
        require(bank[msg.sender] != address(0));
        Bank myBank = Bank(payable(bank[msg.sender]));

        return myBank.getUnlockDate();
    }

    // Prevents accidental sending of ether to the factory
    fallback() external {
        revert();
    }

    // keep all the ether sent to this address
    receive() external payable {
        require(bank[msg.sender] != address(0));

        payable(bank[msg.sender]).transfer(msg.value);

        emit Received(msg.sender, msg.value);
    }

    event CreateBank(
        address wallet,
        address from,
        uint256 createdAt,
        uint256 unlockDate,
        uint256 amount
    );

    event Received(address from, uint256 amount);
    event DepositTokens(address tokenContract, address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
    event SetUnlockDate(address from, uint256 unlockDate);
}