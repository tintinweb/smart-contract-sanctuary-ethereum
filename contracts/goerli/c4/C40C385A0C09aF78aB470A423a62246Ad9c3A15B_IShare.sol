// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

error NotOwner();
error NotSigned();
error NotRequestedYet();
error NotValidInput();
error SamePerson();
error AlreadySigned();
error AlreadyRequested();
error NotVerifier();

contract IShare {
    using Counters for Counters.Counter;
    Counters.Counter public _userID;

    struct UserCredentials {
        uint256 userNo;
        address userId;
        string userName;
        string userLocation;
        uint256 userAge;
        bool userSigned;
        bool isseuerSigned;
        address issuerId;
        uint256 issueDate;
    }

    mapping(uint256 => UserCredentials) public s_Users;
    mapping(address => UserCredentials) public s_allUsers;
    mapping(address => bool) public s_permittedVerfier;

    event RequestSent();
    event CredentialsIssued();
    event CredentialsAcepted();
    event GiveConcent();
    event ConcentRevoked();

    function requestCredentials(
        string memory _name,
        string memory _location,
        uint256 _age
    ) external {
        if (s_allUsers[msg.sender].userId == msg.sender) {
            revert AlreadyRequested();
        }
        if (_age <= 0) {
            revert NotValidInput();
        }
        _userID.increment();
        uint256 currentId = _userID.current();
        s_allUsers[msg.sender] = UserCredentials(
            currentId,
            msg.sender,
            _name,
            _location,
            _age,
            false,
            false,
            address(0),
            block.timestamp
        );
        s_Users[currentId] = UserCredentials(
            currentId,
            msg.sender,
            _name,
            _location,
            _age,
            false,
            false,
            address(0),
            block.timestamp
        );
        emit RequestSent();
    }

    function issueCredentials(address userId, uint256 userNo) external {
        if (s_allUsers[userId].userAge <= 0) {
            revert NotRequestedYet();
        }
        if (s_allUsers[userId].userId == msg.sender) {
            revert SamePerson();
        }
        if (s_allUsers[userId].isseuerSigned == true) {
            revert AlreadySigned();
        }
        s_allUsers[userId].issuerId = msg.sender;
        s_allUsers[userId].isseuerSigned = true;
        s_Users[userNo].issuerId = msg.sender;
        s_Users[userNo].isseuerSigned = true;
        emit CredentialsIssued();
    }

    function acceptCredentials(address userId, uint256 userNo) external {
        if (s_allUsers[userId].userAge <= 0) {
            revert NotRequestedYet();
        }
        if (s_allUsers[userId].userId != msg.sender) {
            revert NotOwner();
        }
        if (s_allUsers[userId].isseuerSigned == false) {
            revert NotSigned();
        }
        s_allUsers[userId].userSigned = true;
        s_allUsers[userId].issueDate = block.timestamp;
        s_Users[userNo].userSigned = true;
        s_Users[userNo].issueDate = block.timestamp;
        emit CredentialsAcepted();
    }

    function giveConcent(address userId, address recipientId) external {
        if (s_allUsers[userId].userId != msg.sender) {
            revert NotOwner();
        }
        if (s_allUsers[userId].isseuerSigned == false) {
            revert NotSigned();
        }

        s_permittedVerfier[recipientId] = true;
        emit GiveConcent();
    }

    function revokeConcent(address userId, address recipientId) external {
        if (s_allUsers[userId].userId != msg.sender) {
            revert NotOwner();
        }
        if (s_allUsers[userId].isseuerSigned == false) {
            revert NotSigned();
        }
        s_permittedVerfier[recipientId] = false;
        emit ConcentRevoked();
    }

    function checkConcent(
        address userId,
        address recipientId
    ) public view returns (bool) {
        if (s_allUsers[userId].userId != msg.sender) {
            revert NotOwner();
        }
        if (s_allUsers[userId].isseuerSigned == false) {
            revert NotSigned();
        }
        if (s_permittedVerfier[recipientId] == true) {
            return true;
        }
        return false;
    }

    function verifyUser(
        address userId,
        address recipientId
    ) public view returns (bool) {
        if (recipientId != msg.sender) {
            revert NotVerifier();
        }
        if (s_allUsers[userId].isseuerSigned == false) {
            revert NotSigned();
        }

        if (s_permittedVerfier[recipientId] == true) {
            return true;
        }
        return false;
    }
}