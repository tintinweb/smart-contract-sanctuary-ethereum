// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SplitSum {
    event UserProfileUpdated(address indexed userAddress, string name, string email);
    event ContactAdded(address indexed userAddress, address indexed contactAddress, string name, string email);
    event GroupCreated(
        bytes32 indexed groupId,
        address indexed ownerAddress,
        string name,
        string description,
        uint256 createdAtTimestamp
    );
    event ExpenseCreated(
        bytes32 indexed expenseId,
        bytes32 indexed groupId,
        address indexed paidByUserAddress,
        uint256 amount,
        string description,
        uint256 createdAtTimestamp,
        address[] memberAddresses
    );

    struct User {
        address userAddress;
        string name;
        string email;
    }

    struct Group {
        bytes32 groupId;
        address ownerAddress;
        string name;
        string description;
        uint256 createdAtTimestamp;
    }

    struct Membership {
        address memberAddress;
        int256 balance;
    }

    struct Expense {
        bytes32 expenseId;
        bytes32 groupId;
        address paidByUserAddress;
        uint256 amount; // 6 Decimals
        string description;
        uint256 createdAtTimestamp;
        address[] memberAddresses;
    }
    struct ExpenseMember {
        address memberAddress;
        uint256 amount; // 6 Decimals
    }

    address private _owner;

    mapping(address => User) private _userProfiles;
    mapping(address => User[]) private _userContacts;

    mapping(bytes32 => Group) private _groups;
    mapping(address => Group[]) private _ownedGroups;
    mapping(address => Group[]) private _membershipGroups;
    mapping(bytes32 => Membership[]) private _groupMemberships;

    mapping(bytes32 => Expense) private _expenses;
    mapping(bytes32 => Expense[]) private _groupExpenses;
    mapping(bytes32 => ExpenseMember[]) private _expenseMembers;

    modifier onlyGroupOwner(bytes32 groupId) {
        require(_groups[groupId].ownerAddress == msg.sender, "Not a group owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    /********************************************************************
     *   Users                                                          *
     ********************************************************************/

    function updateUserProfile(string calldata name, string calldata email) external {
        _userProfiles[msg.sender] = User({userAddress: msg.sender, name: name, email: email});

        emit UserProfileUpdated(msg.sender, name, email);
    }

    function getUserProfile() external view returns (User memory) {
        return _userProfiles[msg.sender];
    }

    function addContact(
        address contactAddress,
        string calldata name,
        string calldata email
    ) external {
        _userContacts[msg.sender].push(User({userAddress: contactAddress, name: name, email: email}));

        emit ContactAdded(msg.sender, contactAddress, name, email);
    }

    function listContacts() external view returns (User[] memory) {
        return _userContacts[msg.sender];
    }

    /********************************************************************
     *   Groups                                                         *
     ********************************************************************/

    function createGroup(
        string calldata name,
        string calldata description,
        uint256 createdAtTimestamp,
        address[] calldata memberAddresses
    ) external {
        bytes32 groupId = keccak256(abi.encodePacked(msg.sender, address(this), name));
        require(_groups[groupId].groupId == 0, "group already exists");

        _groups[groupId] = Group({
            groupId: groupId,
            ownerAddress: msg.sender,
            name: name,
            description: description,
            createdAtTimestamp: createdAtTimestamp
        });
        _ownedGroups[msg.sender].push(_groups[groupId]);

        _addGroupMembership(groupId, msg.sender);
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            _addGroupMembership(groupId, memberAddresses[i]);
        }

        emit GroupCreated(groupId, msg.sender, name, description, createdAtTimestamp);
    }

    function getGroup(bytes32 groupId) external view returns (Group memory) {
        return _groups[groupId];
    }

    function listMembershipGroups() external view returns (Group[] memory) {
        return _membershipGroups[msg.sender];
    }

    function listGroupMemberships(bytes32 groupId) external view returns (Membership[] memory) {
        return _groupMemberships[groupId];
    }

    function addGroupMembership(bytes32 groupId, address memberAddress) external onlyGroupOwner(groupId) {
        _addGroupMembership(groupId, memberAddress);
    }

    function removeGroupMembership(bytes32 groupId, address memberAddress) external onlyGroupOwner(groupId) {
        Membership[] storage groupMemberships = _groupMemberships[groupId];
        for (uint256 i = 0; i < groupMemberships.length; i++) {
            if (groupMemberships[i].memberAddress == memberAddress) {
                groupMemberships[i] = groupMemberships[groupMemberships.length - 1];
                groupMemberships.pop();
                break;
            }
        }
        delete _membershipGroups[memberAddress];
    }

    function _addGroupMembership(bytes32 groupId, address memberAddress) private {
        _membershipGroups[memberAddress].push(_groups[groupId]);
        _groupMemberships[groupId].push(Membership({memberAddress: memberAddress, balance: 0}));
    }

    /********************************************************************
     *   Expenses                                                       *
     ********************************************************************/

    function createExpense(
        bytes32 groupId,
        uint256 amount,
        string calldata description,
        uint256 createdAtTimestamp,
        address[] calldata memberAddresses
    ) external {
        Expense memory expense = _createExpense(groupId, amount, description, createdAtTimestamp, memberAddresses);
        _splitExpenseAmongMembers(expense);

        emit ExpenseCreated(
            expense.expenseId,
            groupId,
            msg.sender,
            amount,
            description,
            createdAtTimestamp,
            memberAddresses
        );
    }

    function getExpense(bytes32 expenseId) external view returns (Expense memory) {
        return _expenses[expenseId];
    }

    function listExpenseMembers(bytes32 expenseId) external view returns (ExpenseMember[] memory) {
        return _expenseMembers[expenseId];
    }

    function _createExpense(
        bytes32 groupId,
        uint256 amount,
        string calldata description,
        uint256 createdAtTimestamp,
        address[] calldata memberAddresses
    ) private returns (Expense memory) {
        require(amount > 0, "amount must be greater than zero");

        Membership[] memory memberships = _groupMemberships[groupId];
        bool foundMembership = false;
        for (uint256 i = 0; i < memberships.length; i++) {
            if (memberships[i].memberAddress == msg.sender) {
                foundMembership = true;
                break;
            }
        }
        require(foundMembership, "Not in the group members");

        bytes32 expenseId = keccak256(abi.encodePacked(msg.sender, groupId, amount, description, createdAtTimestamp));
        require(_expenses[expenseId].expenseId == 0, "expense already exists");

        _expenses[expenseId] = Expense({
            expenseId: expenseId,
            groupId: groupId,
            paidByUserAddress: msg.sender,
            amount: amount,
            description: description,
            createdAtTimestamp: createdAtTimestamp,
            memberAddresses: memberAddresses
        });
        _groupExpenses[groupId].push(_expenses[expenseId]);

        return _expenses[expenseId];
    }

    function _splitExpenseAmongMembers(Expense memory expense) private {
        uint256 expensePerMember = expense.amount / expense.memberAddresses.length;
        for (uint256 i = 0; i < expense.memberAddresses.length; i++) {
            _expenseMembers[expense.expenseId].push(
                ExpenseMember({memberAddress: expense.memberAddresses[i], amount: expensePerMember})
            );
        }
    }
}