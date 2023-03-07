// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Address Book
 * @dev Implements create, retrieve, update, delete (CRUD) code using address book app.
 * REF:
 * https://bitbucket.org/rhitchens2/soliditycrud/src/master/contracts/SolidityCRUD-part2.sol
 */

contract AddressBook {
    struct Contact {
        bytes32 name;
        bytes32 email;
        uint256 age;
        uint256 birthDate;
        uint256 index;
    }

    mapping(address => Contact) private contacts;
    address[] private contactIndex;

    event Created(
        address indexed userAddress,
        uint256 index,
        bytes32 name,
        bytes32 email,
        uint256 age,
        uint256 birthDate
    );
    event Updated(
        address indexed userAddress,
        uint256 index,
        bytes32 name,
        bytes32 email,
        uint256 age,
        uint256 birthDate
    );
    event IndexUpdated(address indexed userAddress, uint256 index);
    event Deleted(address indexed userAddress, uint256 index);

    function isExists(address userAddress) public view returns (bool exists) {
        if (contactIndex.length == 0) return false;
        return (contactIndex[contacts[userAddress].index] == userAddress);
    }

    function create(
        address userAddress,
        bytes32 name,
        bytes32 email,
        uint256 age,
        uint256 birthDate
    ) public returns (uint256 index) {
        require(!isExists(userAddress), "Contact of the user exists!");
        contacts[userAddress].name = name;
        contacts[userAddress].email = email;
        contacts[userAddress].age = age;
        contacts[userAddress].birthDate = birthDate;
        contactIndex.push(userAddress);
        contacts[userAddress].index = contactIndex.length - 1;
        emit Created(
            userAddress,
            contacts[userAddress].index,
            name,
            email,
            age,
            birthDate
        );
        return contactIndex.length - 1;
    }

    function get(address userAddress)
        public
        view
        returns (
            bytes32 name,
            bytes32 email,
            uint256 age,
            uint256 birthDate,
            uint256 index
        )
    {
        require(isExists(userAddress), "Contact not found!");
        return (
            contacts[userAddress].name,
            contacts[userAddress].email,
            contacts[userAddress].age,
            contacts[userAddress].birthDate,
            contacts[userAddress].index
        );
    }

    function update(
        address userAddress,
        bytes32 name,
        bytes32 email,
        uint256 age,
        uint256 birthDate
    ) public returns (bool status) {
        require(isExists(userAddress), "Contact not found!");
        contacts[userAddress].name = name;
        contacts[userAddress].email = email;
        contacts[userAddress].age = age;
        contacts[userAddress].birthDate = birthDate;
        emit Updated(
            userAddress,
            contacts[userAddress].index,
            contacts[userAddress].name,
            contacts[userAddress].email,
            contacts[userAddress].age,
            contacts[userAddress].birthDate
        );
        return true;
    }

    function deleteRecord(address userAddress) public returns (uint256 index) {
        require(isExists(userAddress), "Contact not found!");
        uint256 rowToDelete = contacts[userAddress].index;
        if (rowToDelete < contactIndex.length - 1) {
            address keyToMove = contactIndex[contactIndex.length - 1];
            contactIndex[rowToDelete] = keyToMove;
            contacts[keyToMove].index = rowToDelete;
            emit IndexUpdated(keyToMove, rowToDelete);
        }
        delete contacts[userAddress];
        contactIndex.pop();
        emit Deleted(userAddress, rowToDelete);
        return rowToDelete;
    }

    function getCount() public view returns (uint256 count) {
        return contactIndex.length;
    }

    function getAddressByIndex(uint256 index)
        public
        view
        returns (address userAddress)
    {
        return contactIndex[index];
    }
}