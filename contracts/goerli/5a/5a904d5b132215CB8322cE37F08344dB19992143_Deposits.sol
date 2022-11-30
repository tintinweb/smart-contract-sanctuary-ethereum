/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/// @title A Banking application that tracks balances
/// @author Redacted
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
contract Deposits {
    address payable public owner;
    uint private minDeposit;
    uint private fees = 10;
    // mapping(address => uint) private balances;
    mapping(address => bool) private escrow_managers;

    constructor(uint _minDeposit) {
        minDeposit = _minDeposit;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyEscrow() {
        require(escrow_managers[msg.sender], "Only escrow members have access");
        _;
    }
    
    /// @notice Add an address to the list of authorised escrow managers
    /// @dev Only the owner can add a new address as an escrow
    /// @param _escrowManager the address of the entity authorized as an escrow manager
    function addEscrowManager(address _escrowManager) public onlyOwner {
        if (!escrow_managers[_escrowManager]) escrow_managers[_escrowManager] = true;
    }

    /// @notice Remove an address from the list of authorised escrow managers if it exists
    /// @dev Only the owner can remove an address as an escrow
    /// @param _escrowManager the address of the entity removed as an escrow manager
    function removeEscrowManager(address _escrowManager) public onlyOwner {
        if (escrow_managers[_escrowManager]) escrow_managers[_escrowManager] = false;
    }

    /// @notice Modify the percentage of fees reserved in the smart contract
    /// @dev Only the owner can modify the fees percentage
    /// @param _newFeesPercentage the new value of fees supposed to be charged for all bets
    function modifyFees(uint _newFeesPercentage) public onlyOwner {
        require(_newFeesPercentage < 100 && _newFeesPercentage > 0, "Fees should be between 0 and 100");

        fees = _newFeesPercentage;
    }

    /// @notice Transfer ownership to a new owner
    /// @dev Only the owner can call this function
    /// @param _newOwner the new owner that is supposed to be the owner of the contract
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // /// @notice Check balance amount deposited by a wallet
    // /// @dev Anyone can call this function
    // /// @param _address the address whose balance needs to be checked
    // function checkBalance(address _address) public view returns(uint) {
    //     return balances[_address];
    // }

    /// @notice Change the minimum deposit amount
    /// @dev Only the owner can change the minimum bet amount
    /// @param _newMinDeposit the new minimum bet amount supposed to be set in minBetAmt
    function changeMinDeposit(uint _newMinDeposit) public onlyOwner {
        minDeposit = _newMinDeposit;
    }

    /// @notice Refunds the bet amount to all members that paid for a particular bet
    /// @dev this can only be triggered by the escrow manager
    /// @param _members addresses of all participants that paid for the bet
    /// @param _amount total amount of bet money to be refunded
    /// @return true when the participants have been refunded
    function refund(address payable[] memory _members, uint _amount) public onlyEscrow returns (bool) {
        uint _amountPerPerson = _amount / _members.length;
        // for(uint i = 0;i<=_members.length;++i) {
        //     require(balances[_members[i-1]] > _amountPerPerson, "Some members have insufficient balance");
        // }
        pay(_members, _amountPerPerson);
        return true;
    }

    /// @notice Pays the winners the bet amount
    /// @dev this can only be triggered by the escrow manager
    /// @param _members addresses of all winning team participants
    /// @param _winningAmount total amount of bet money to be paid out
    /// @return true when the winners have been paid
    function payWinners(address payable[] memory _members, uint _winningAmount) public onlyEscrow returns (bool) {
        _winningAmount = _winningAmount * (100 - fees) / 100;
        uint _winningAmountPerPerson = _winningAmount / _members.length;
        // for(uint i = 0;i<=_members.length;++i) {
        //     require(balances[_members[i-1]] > _winningAmountPerPerson, "Some members have insufficient balance");
        // }
        pay(_members, _winningAmountPerPerson);
        return true;
    }

    /// @notice pay the bet amount (used in refund and payWinners)
    /// @dev this can only be triggered by the escrow manager
    /// @param _members addresses of all winning team participants
    /// @param amount amount in wei sent to each member address
    function pay(address payable[] memory _members, uint amount) private onlyEscrow {
        require(address(this).balance > _members.length * amount, "Not enough balance");

        for(uint i=0;i<=_members.length;++i) {
            _members[++i].transfer(amount);
        }
    }

    /// @notice allows the owner of the contract to withdraw from the smart contract address
    /// @dev this can only be triggered by the owner
    /// @param _withdrawAmount the amount in wei that the owner intends to withdraw
    function withdraw(uint _withdrawAmount) public payable onlyOwner {
        require(_withdrawAmount < address(this).balance, "Withdraw overflow");

        owner.transfer(_withdrawAmount);
    }

    receive() external payable {
        require(msg.value >= minDeposit, "Min. Eth amount not sent");
        // balances[msg.sender] = balances[msg.sender] + msg.value;
    }

    /// @notice allows the owner to look at the balance of the contract
    /// @dev this can only be triggered by the owner
    /// @return balance the amount of wei stored in the smart contract
    function getContractBal() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    /// @notice allows anyone to check what the minimum deposit amount is
    /// @dev anyone can call this function
    /// @return minDepositAmount the minimum amount of wei that the smart contract accepts
    function getMinDepositAmount() public view onlyOwner returns(uint) {
        return minDeposit;
    }
}