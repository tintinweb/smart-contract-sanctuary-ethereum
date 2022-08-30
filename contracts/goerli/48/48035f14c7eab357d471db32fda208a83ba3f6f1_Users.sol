// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Users/IUsers.sol";

contract Users is IUsers {
    event CheckUserExist(address indexed userAccount, uint8 indexed userRole);

    Owner public owner;
    address[] private usersAccounts;
    uint256 private usersIndex;
    bool public contractState;
    mapping(address => User) private addressToUser;

    constructor(string memory ownerName) {
        contractState = true;
        owner = Owner(msg.sender, ownerName);
    }

    function addUser(address _userAddress, Roles.Role _userRole)
        public
        onlyAdmin
        activeContract
    {
        if (addressToUser[_userAddress].userRole != Roles.Role.None) {
            revert UserAlreadyExists(_userAddress);
        }
        if (_userRole == Roles.Role.None) {
            revert NotAcceptedRole(_userRole);
        }
        usersIndex++;
        User memory user = User(usersIndex, block.timestamp, _userRole);
        usersAccounts.push(_userAddress);
        addressToUser[_userAddress] = user;
    }

    function deleteUser(address _userAddress) public onlyAdmin activeContract {
        if (addressToUser[_userAddress].userRole == Roles.Role.None) {
            revert UserNotExist(_userAddress);
        }
        delete usersAccounts[addressToUser[_userAddress]._id - 1];
        usersAccounts[addressToUser[_userAddress]._id - 1] = usersAccounts[
            usersAccounts.length - 1
        ];
        usersAccounts.pop();
        delete addressToUser[_userAddress];
    }

    function checkUser() public activeContract {
        if (addressToUser[msg.sender].userRole == Roles.Role.None) {
            revert UserNotExist(msg.sender);
        }
        emit CheckUserExist(
            msg.sender,
            uint8(addressToUser[msg.sender].userRole)
        );
    }

    function getUser(address _userAccount)
        public
        view
        activeContract
        returns (User memory)
    {
        return addressToUser[_userAccount];
    }

    function getUsersCount() public view returns (uint256) {
        return usersAccounts.length;
    }

    function getAllUsers() public view returns (address[] memory) {
        return usersAccounts;
    }

    function changeState(bool _contractState) public onlyOwner {
        contractState = _contractState;
    }

    modifier activeContract() {
        if (!contractState) {
            revert NotActiveContract();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner.ownerAccount) {
            revert NotContractOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (
            msg.sender != owner.ownerAccount &&
            (addressToUser[msg.sender].userAddDate == 0 ||
                addressToUser[msg.sender].userRole != Roles.Role.Admin)
        ) {
            revert NotAdminAccount(msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Roles.sol";

error NotAcceptedRole(Roles.Role userRole);
error UserAlreadyExists(address userAccount);
error UserNotExist(address userAccount);
error NotAdminAccount(address userAccount);
error NotActiveContract();
error NotContractOwner();

interface IUsers {
    struct User {
        uint256 _id;
        uint256 userAddDate;
        Roles.Role userRole;
    }

    struct Owner {
        address ownerAccount;
        string ownerName;
    }

    function addUser(address, Roles.Role) external;

    function deleteUser(address) external;

    function checkUser() external;

    function getUser(address) external view returns (User memory);

    function getUsersCount() external view returns (uint256);

    function getAllUsers() external view returns (address[] memory);

    function changeState(bool) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Roles {
    enum Role {
        None,
        Admin,
        Teacher,
        Tutor,
        Student
    }
}