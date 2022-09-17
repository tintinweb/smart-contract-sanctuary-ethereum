/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/utils/Strings
// License: MIT
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

contract Kollab_Splitter_Factory {

    address payable private owner;
    uint public creationFee;

    mapping(uint => Kollab_Splitter) private splitters;
    mapping(address => uint) private splitter_id;
    mapping(address => uint[]) public associated_splitters;
    uint idTracker;

    // Modifier contract to only allow contract deployer access
    modifier onlyOwner {
        require(msg.sender == owner, 'Access Denied.');
        _;
    }

    // Executed when deployed to block chain
    constructor() {
        owner = payable(msg.sender);
        creationFee = 1; // Percent of ether
        idTracker = 100;
    }

    // Create a splitter contract
    function createSplitter (
        string memory _name,
        string memory _desc,
        address[] memory _payees,
        uint[] memory _shares
    ) external payable {
        uint _id = idTracker + 1;
        require(!checkExists(_id), 'ID already exists.');
        require(msg.value >= creationFee / 100, 'Please enter fee amount.');
        require(_payees.length == _shares.length, 'Ensure each address has allocated shares.');
        uint total_shares;
        for(uint i = 0; i < _shares.length; i++) { total_shares += _shares[i]; }
        require(total_shares < 1000000000000000);

        splitters[_id] = new Kollab_Splitter(_payees, _shares, address(this), _name, _desc, payable(msg.sender));
        for(uint i = 0; i < _payees.length; i++) { associated_splitters[_payees[i]].push(_id); }
        splitter_id[address(splitters[_id])] = _id;
        idTracker = _id;
    }

    // Get all splitter info for id
    function getAccountSplitters (address _sender) public view returns (string[] memory) {
        uint[] memory asoc = associated_splitters[_sender];
        
        address _address;
        string[] memory result = new string[](asoc.length * 8);

        uint i = 0;
        for(uint j = 0; j < asoc.length; j++) {
            _address = this.getSplitterAddress(asoc[j]);
            result[i] = Strings.toHexString(_address);
            result[i + 1] = Strings.toString(splitter_id[_address]);
            result[i + 2] = this.getName(asoc[j]);
            result[i + 3] = this.getDescription(asoc[j]);
            result[i + 4] = Strings.toString(this.getLastWithdrawl(asoc[j], msg.sender));
            result[i + 5] = Strings.toString(this.getTotalShares(asoc[j]));
            result[i + 6] = Strings.toString(this.getShares(asoc[j], msg.sender));
            result[i + 7] = Strings.toHexString(this.getCreator(asoc[j]));
            i+=8;
        }

        return result;
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

    // Get name of splitter
    function getName(uint _id) public view returns (string memory) {
        return splitters[_id].getName();
    }

    // Get description of splitter
    function getDescription(uint _id) public view returns (string memory) {
        return splitters[_id].getDescription();
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

contract Kollab_Splitter {

    address payable creator;
    address factory;

    address[] payees;
    mapping(address => uint) shares;

    uint total_shares = 0;
    uint total_revenue = 0;
    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;

    string name;
    string description;

    // Executed when a new splitter is created
    constructor(address[] memory _payees, uint[] memory _shares, address _factory, string memory _name, string memory _desc, address payable _creator) {
        payees = _payees; creator = _creator; name = _name; description = _desc; factory = _factory;
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

    // Returns assigned shares to a payee
    function getPayeeShares(address _payee) public view returns (uint) {
        return shares[_payee];
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

    // Get total number of shares
    function getTotalShares() public view returns (uint) {
        return total_shares;
    }

    // Calculates balance of payee
    function getUserBalance(address _payee) public view returns (uint256) {
        return ( shares[_payee] * total_revenue ) / total_shares - total_released[_payee];
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

            if(shares[payee] < 0) { continue; }

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
        require(shares[_payee] > 0, 'Account has no shares.');
        require(address(this).balance > 0, 'Insufficient funds within contract.');
        
        uint available_funds = this.getUserBalance(_payee);

        require(available_funds > 0, 'Insufficient balance.');

        payable(_payee).transfer(available_funds);
        total_released[_payee] += available_funds;
        last_withdrawl[_payee] = block.timestamp;
    }
}