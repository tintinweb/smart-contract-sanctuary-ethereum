/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

contract Kollab_Splitter_Factory {

    address payable private owner;
    uint public creationFee;

    // Store each splitter contract and an assigned ID
    mapping(uint => Kollab_Splitter) private splitters;
    
    // Map a unique phrase to each id
    mapping(string => uint) private unique_phrases;
    string[] private phrases;

    // Modifier contract to only allow contract deployer access
    modifier onlyOwner {
        require(msg.sender == owner, 'Access Denied.');
        _;
    }

    // Executed when deployed to block chain
    constructor() {
        owner = payable(msg.sender);
        creationFee = 1; // Percent of ether
    }

    // Checks if an ID has already been assigned to a contract
    function checkExists(uint _id) public view returns (bool) {
        if(address(splitters[_id]) != address(0)) {
            return true;
        }
        return false;
    }

    // Update creation fee
    function changeCreationFee(uint _fee) onlyOwner public {
        require(_fee >= 0, 'Creation fee cannot be less than zero.');
        creationFee = _fee;
    }

    // Allows transfer of contract owner
    function changeOwner(address payable _newOwner) onlyOwner public {
        owner = _newOwner;
    }

    // Release accumulated fees to factory owner address
    function ownerPayout(uint _amount) onlyOwner public {
        owner.transfer(_amount);
    }

    // Returns value of splitter contract
    function getContractValue(uint _id) public view returns (uint) {
        return address(splitters[_id]).balance;
    }

    // Retrieve address of a splitter contract using ID
    function getSplitterAddress(uint _id) public view returns (address) {
        return address(splitters[_id]);
    }

    // Release funds for all share holders
    function payoutAll(uint _id) external {
        splitters[_id].payoutAll(msg.sender);
    }

    // Release individual funds
    function payout(uint _id) external {
        splitters[_id].payout(msg.sender);
    }

    // Get timestamp of last withdrawl
    function getLastWithdrawl(uint _id, address _payee) public view returns (uint) {
        return splitters[_id].getLastWithdrawl(_payee);
    }

    // Get contract creator
    function getCreator(uint _id) public view returns (address) {
        return splitters[_id].getCreator();
    }

    // Get array of payees within splitter contract
    function getPayees(uint _id) public view returns (address[] memory) {
        return splitters[_id].getPayees();
    }

    // Check if payee is part of a splitter contract
    function isPayee(uint _id, address _payee) public view returns (bool) {
        return splitters[_id].isPayee(_payee);
    }

    // Get shares allocated to individual payees
    function getShares(uint _id, address _payee) public view returns (uint) {
        return splitters[_id].getPayeeShares(_payee);
    }

    // Get total number of shares within splitter contract
    function getTotalShares(uint _id) public view returns (uint) {
        return splitters[_id].getTotalShares();
    }

    // Create a splitter contract
    function createSplitter(
        uint _id,
        address[] memory _payees,
        uint[] memory _shares
    ) external payable {
        require(!checkExists(_id), 'ID already exists.');
        require(msg.value >= creationFee / 100, 'Please enter fee amount.');
        require(_payees.length == _shares.length, 'Ensure each address has allocated shares.');

        splitters[_id] = new Kollab_Splitter(_payees, _shares, address(this), payable(msg.sender));
    }

}

contract Kollab_Splitter {

    address payable creator;
    address factory;

    address[] payees;
    mapping(address => uint) shares;

    uint total_shares = 0;
    uint256 total_revenue = 0;
    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;

    // Executed when a new splitter is created
    constructor(address[] memory _payees, uint[] memory _shares, address _factory, address payable _creator) {
        payees = _payees; creator = _creator; factory = _factory;
        for(uint i = 0; i < _payees.length; i++) {
            shares[_payees[i]] = _shares[i];
            total_shares += _shares[i];
        }
    }

    modifier onlyFactory {
        require(msg.sender == factory, 'Only the factory contract has access to this functionality.');
        _;
    }
    
    // Deposit funds
    receive() external payable {
        require(msg.value > 0, 'Enter valid amount.');
        total_revenue = total_revenue + msg.value;
    }

    // Check if payee is within a contract
    function isPayee(address _payee) public view returns (bool) {
        for(uint i = 0; i < payees.length; i++) {
            if(_payee == payees[i]) { return true; }
        }
        return false;
    }

    // Returns address of splitter creator
    function getCreator() public view returns (address) {
        return creator;
    }

    // Returns array of all payees
    function getPayees() public view returns (address[] memory) {
        return payees;
    }

    function getPayee(uint _id) public view returns (address) {
        return payees[_id];
    }

    // Returns assigned shares to a payee
    function getPayeeShares(address _payee) public view returns (uint) {
        return shares[_payee];
    }

    // Get total number of shares
    function getTotalShares() public view returns (uint) {
        return total_shares;
    }

    // Calculates balance of payee
    function getUserBalance(address _payee) public view returns (uint) {
        return ((shares[_payee] - total_shares) * total_revenue) - total_released[_payee];
    }

    // Returns unix timestamp of last withdrawl
    function getLastWithdrawl(address _payee) public view returns (uint) {
        return last_withdrawl[_payee];
    }

    // Releases funds for all shareholders
    function payoutAll(address _creator) external {
        
        require(_creator == creator, 'Only the creator of this splitter can release all funds.');
        require(address(this).balance > 0, 'Insufficient funds.');

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];
            uint available_funds = this.getUserBalance(payee);
            
            if(available_funds > 0) {
                payable(payee).transfer(available_funds);
                total_released[payee] += available_funds;
                last_withdrawl[payee] = block.timestamp;
            }

        }
    }

    // Releases individual funds
    function payout(address _payee) external {

        require(this.isPayee(_payee), 'Access Denied');
        require(address(this).balance > 0, 'Insufficient funds within contract.');
        
        uint available_funds = this.getUserBalance(_payee);

        require(available_funds > 0, 'Insufficient balance.');

        payable(_payee).transfer(available_funds);
        total_released[_payee] += available_funds;
        last_withdrawl[_payee] = block.timestamp;
    }
}