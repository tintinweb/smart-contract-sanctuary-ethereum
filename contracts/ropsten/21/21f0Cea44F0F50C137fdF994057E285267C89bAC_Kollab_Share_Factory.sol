/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/utils/Strings
// License: MIT
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

contract Kollab_Share_Factory {

    address payable private owner;
    uint public creationFee = 10; // thousands of an ether
    uint public withdrawlFee = 10; // thousands of an ether

    mapping(uint => Kollab_Share) private splitters;
    mapping(address => uint) private splitter_id;
    mapping(address => uint[]) public associated_splitters;
    uint idTracker = 100;

    modifier onlyOwner {
        require(msg.sender == owner, 'Access Denied.');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function createSplitter (
        string memory _name,
        string memory _desc,
        address[] memory _payees,
        uint[] memory _shares
    ) external payable {
        uint _id = idTracker + 1;
        require(!checkExists(_id), 'ID already exists.');
        require(msg.value >= creationFee / 1000, 'Please enter fee amount.');
        require(_payees.length == _shares.length, 'Ensure each address has allocated shares.');
        uint total_shares;
        for(uint i = 0; i < _shares.length; i++) { total_shares += _shares[i]; }
        require(total_shares <= 1000000000000);
        splitters[_id] = new Kollab_Share(_payees, _shares, address(this), _name, _desc, msg.sender, withdrawlFee);
        for(uint i = 0; i < _payees.length; i++) { associated_splitters[_payees[i]].push(_id); }
        splitter_id[address(splitters[_id])] = _id;
        idTracker = _id;
    }

    // Get details for a splitter
    function getSplitter (uint _id, address _account) public view returns (string[] memory) {
        Kollab_Share splitter = splitters[_id];
        string[] memory result = new string[](9);
        result[0] = Strings.toHexString(address(splitter)); // Address
        result[1] = splitter.getName(); // Name
        result[2] = splitter.getDescription(); // Description
        result[3] = Strings.toString(splitter.getPayeeShares(_account)); // Personal shares
        result[4] = Strings.toString(splitter.getTotalShares()); // Total shares
        result[5] = Strings.toString(splitter.getUserBalance(_account)); // Personal Balance
        result[6] = Strings.toString(address(splitter).balance); // Total Balance
        result[7] = Strings.toString(splitter.getLastWithdrawl(_account)); // Last withdrawl blockstamp
        result[8] = Strings.toHexString(splitter.getCreator()); // Creator or splitter
        return result;
    }

    function getSplitterIds(address _account) public view returns (uint[] memory) {
        return associated_splitters[_account];
    }

    // Checks if an ID has already been assigned to a contract
    function checkExists (uint _id) public view returns (bool) {
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

    // Update transaction fee
    function changeWithdrawlFee(uint _fee) onlyOwner public {
        require(_fee >= 0, 'Update fee cannot be less than zero.');
        for(uint i = 0; i < idTracker - 100; i++) {
            splitters[i].changeFee(_fee);
        }
        withdrawlFee = _fee;
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
    function getSplitterBalance(uint _id) public view returns (uint) {
        return address(splitters[_id]).balance;
    }

    // Retrieve address of a splitter contract using ID
    function getSplitterAddress(uint _id) public view returns (address) {
        return address(splitters[_id]);
    }

    function getSplitterId(address _address) public view returns (uint) {
        return splitter_id[_address];
    }

    // Release funds for all share holders
    function payoutAll(uint _id) external {
        splitters[_id].payoutAll(msg.sender);
    }

    // Release individual funds
    function payout(uint _id) external {
        splitters[_id].payout(msg.sender);
    }

    // Check if payee is part of a splitter contract
    function isPayee(uint _id, address _payee) public view returns (bool) {
        return splitters[_id].isPayee(_payee);
    }

    // Get balance of payee
    function getBalance(uint _id, address _payee) public view returns (uint) {
        return splitters[_id].getUserBalance(_payee);
    }

    // Get payees and shares from a splitter
    function getShareholders(uint _id) public view returns (string[] memory) {
        return splitters[_id].getShareholders();
    }
}

contract Kollab_Share {

    address creator;
    address factory;

    address[] payees;
    mapping(address => uint) shares;

    uint total_shares = 0;
    uint total_revenue = 0;
    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;

    string name;
    string description;
    uint fee;

    // Executed when a new splitter is created
    constructor(address[] memory _payees, uint[] memory _shares, address _factory, string memory _name, string memory _desc, address _creator, uint _fee) {
        payees = _payees; creator = _creator; name = _name; description = _desc; factory = _factory; fee = _fee;
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

    // Returns description of payment splitter
    function getDescription() public view returns (string memory) {
        return description;
    }

    // Returns name of payment splitter
    function getName() public view returns (string memory) {
        return name;
    }

    // Returns array of all payees
    function getPayees() public view returns (address[] memory) {
        return payees;
    }

    // Calculates balance of payee
    function getUserBalance(address _payee) public view returns (uint256) {
        return ( shares[_payee] * total_revenue ) / total_shares - total_released[_payee];
    }

    // Returns unix timestamp of last withdrawl
    function getLastWithdrawl(address _payee) public view returns (uint) {
        return last_withdrawl[_payee];
    }

    // Change withdrawl fee
    function changeFee(uint _fee) public {
        fee = _fee;
    }

    // Returns assigned shares to a payee
    function getPayeeShares(address _payee) public view returns (uint) {
        return shares[_payee];
    }

    // Get total number of shares
    function getTotalShares() public view returns (uint) {
        return total_shares;
    }

    function getShareholders() public view returns (string[] memory) {
        string[] memory shareholders = new string[](payees.length * 2);

        uint j = 0;
        for(uint i = 0; i < payees.length; i++) {
            address _payee = payees[i];
            shareholders[j] = Strings.toHexString(_payee);
            shareholders[j + 1] = Strings.toString(shares[_payee]);
            j = j + 2;
        }

        return shareholders;
    }

    // Releases funds for all shareholders
    function payoutAll(address _creator) external {
        
        require(_creator == creator, 'Only the creator of this splitter can release all funds.');
        require(address(this).balance > 0, 'Insufficient funds.');

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];

            if(shares[payee] < 0) { continue; }

            uint available_funds = this.getUserBalance(payee);
            uint transaction_fee = ( available_funds / 1000 ) * fee;
            if(available_funds > 0) {
                payable(payee).transfer(available_funds - transaction_fee);
                payable(0xF28c36CD04414b22E410ffeEf1400b4BAB4ab559).transfer(transaction_fee);
                total_released[payee] += available_funds;
                last_withdrawl[payee] = block.timestamp;
            }
        }
    }

    // Releases individual funds
    function payout(address _payee) external {

        require(this.isPayee(_payee), 'Access Denied');
        require(shares[_payee] > 0, 'Account has no shares.');
        require(address(this).balance > 0, 'Insufficient funds within contract.');
        
        uint available_funds = this.getUserBalance(_payee);
        uint transaction_fee = ( available_funds / 1000 ) * fee;

        require(available_funds > 0, 'Insufficient balance.');

        payable(_payee).transfer(available_funds - transaction_fee);
        payable(0xF28c36CD04414b22E410ffeEf1400b4BAB4ab559).transfer(transaction_fee);
        total_released[_payee] += available_funds;
        last_withdrawl[_payee] = block.timestamp;
    }
}