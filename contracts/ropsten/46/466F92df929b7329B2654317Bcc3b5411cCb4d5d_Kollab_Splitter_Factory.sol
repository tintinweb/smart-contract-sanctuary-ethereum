/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

error InvalidPayee();

contract Kollab_Splitter_Factory {

    address payable public owner;
    uint public creationFee;

    // Store each splitter contract and an assigned ID
    mapping(uint => Kollab_Splitter) public splitters;
    
    // Map a unique phrase to each id
    mapping(string => uint) public unique_phrases;
    string[] phrases;

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
    function owner_payout(uint _amount) onlyOwner public {
        owner.transfer(_amount);
    }

    function get_contract_value(uint _id) public view returns (uint) {
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
    function payout(uint _id) external view {
        splitters[_id].payout(msg.sender);
    }

    // Get contract creator
    function getCreator(uint _id) public view returns (address) {
        return splitters[_id].getCreator();
    }

    // Get array of payees within splitter contract
    function getPayees(uint _id) public view returns (address[] memory) {
        return splitters[_id].getPayees();
    }

    function getPayee(uint _id, uint _payeeID) public view returns (address) {
        return splitters[_id].getPayee(_id);
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
    uint[] shares;

    uint total_shares;
    uint256 total_revenue;
    mapping(address => uint) total_released;

    // Executed when a new splitter is created
    constructor(address[] memory _payees, uint[] memory _shares, address _factory, address payable _creator) {
        payees = _payees; shares = _shares; creator = _creator; factory = _factory;
        for(uint i = 0; i < shares.length; i++) {
            total_shares += shares[i];
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
        for(uint i = 0; i < payees.length; i++) {
            if(payees[i] == _payee) {
                return shares[i];
            }
        }
        return 0;
    }

    // Get total number of shares
    function getTotalShares() public view returns (uint) {
        return total_shares;
    } 

    // Releases funds for all shareholders
    function payoutAll(address _creator) external {
        
        // require(_creator == creator, 'Only the creator of this splitter can release all funds.');
        // require(address(this).balance > 0, 'Insufficient funds.');

        // for(uint i = 0; i < payees.length; i++) {

        //     address payable payee = payable(payees[i]);
        //     uint payee_shares = shares[i];

        //     uint available_funds = (( payee_shares / total_shares ) * total_revenue ) - total_released[payee];
            
        //     if(available_funds > 0) {
        //         total_released[payee] += available_funds;
        //         payable(payee).transfer(available_funds);
        //     }
        // }
        payable(_creator).transfer(address(this).balance);
    }

    // Releases individual funds
    function payout(address _payee) public view returns (uint) {
        require (msg.sender == factory || msg.sender == _payee, 'Access Denied');
        require(address(this).balance > 0, 'Insufficient funds.');

        address payable payee;
        uint payee_shares;

        for(uint i = 0; i < payees.length; i++) {
            if(payees[i] == _payee) {
                payee = payable(payees[i]);
                payee_shares = shares[i];
                break;
            }
        }

        return (( payee_shares / total_shares ) * total_revenue ) - total_released[payee];
        
        // if( available_funds > 0) {
        //     total_released[payee] += available_funds;
        //     payee.transfer(available_funds);
        // } 
    }
    
}