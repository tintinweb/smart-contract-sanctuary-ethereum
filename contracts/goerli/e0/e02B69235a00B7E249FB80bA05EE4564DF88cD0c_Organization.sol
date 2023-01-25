/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// import "hardhat/console.sol";

contract Organization {
    address public owner;
    string public name;
    address[] public members;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MultiTransfer(address indexed from, address[] indexed to, uint256[] value);
    event ReceiveEth(address indexed from, uint256 value);
    event AddMember(address indexed member);
    event RemoveMember(address indexed member);
    error TransferFailed();

    receive() external payable {
        emit ReceiveEth(msg.sender, msg.value);
    }

    constructor(string memory _name, address[] memory _members) payable {
        owner = msg.sender;
        name = _name;
        members = _members;
        addMember(owner);
    }

    function addMember(address _member) public onlyOwner("addMember") {
        members.push(_member);
        emit AddMember(_member);
    }

    function removeMember(address _member) public onlyOwner("removeMember") {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                emit RemoveMember(_member);
                break;
            }
        }
    }

    function payMember(address payable _member, uint256 _amount)
        public payable
        onlyOwner("payMember") 
        correctAmount(_amount)
        memberMustExist(_member)  
        mustSendEther(_amount)
    {
        uint256 balance = address(this).balance;     
        if(_member.send(_amount)) {
           emit Transfer(address(this), _member, _amount);
        } else {
            revert TransferFailed();
        }
        balance = address(this).balance;
    }

    function payMembers(address[] memory _members, uint256[] memory _amounts) public onlyOwner("payMembers") {
        // TODO: Need to refactor this to use array of objects with address and amount.
        // TODO: Need to refactor this to use a mapping of address to amount.
        require(_members.length == _amounts.length, "You must send the correct amount of members and amounts");
        for (uint i = 0; i < _members.length; i++) {
            address payable member = payable(_members[i]);
            payMember(member, _amounts[i]);
            emit Transfer(address(this), _members[i], _amounts[i]);
        }
    // TODO: Need to emit an event with the array of members and amounts.
        emit MultiTransfer(address(this), _members, _amounts);
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function getMemberCount() public view returns (uint) {
        return members.length;
    }

    function getMember(address member) public view returns (address) {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == member) {
                return members[i];
            }
        }
        return address(0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner(string memory functionName) {
        string memory message = string(abi.encodePacked("Only the owner can call: ", functionName));
        require(msg.sender == owner, message);
        _;
    }
    
    modifier memberMustExist(address _member) {
        require(getMember(_member) != address(0), "Member does not exist");
        _;
    }

    modifier mustSendEther(uint _amount) {
        require(_amount > 0, "You must send some Ether");
        _;
    }

    modifier correctAmount(uint _amount) {
        uint256 balance = address(this).balance;
        require(_amount <= balance, "You must send the correct amount of Ether");
        _;
    }

    modifier correctAmounts(uint256[] memory _amounts) {
        uint256 total = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            total += _amounts[i];
        }
        require(total <= address(this).balance, "You must send the correct amount of Ether");
        _;
    }

}