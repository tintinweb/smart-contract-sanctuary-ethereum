// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamManager is Ownable {
    struct TeamMember {
        address memberAddress;
        string memberName;
    }

    TeamMember[] public teamMembers;

    constructor() {
        teamMembers.push(TeamMember(0x3c27723b92Daf4Ef091960fc7856A2E09c5f2e9b, "mark"));
        teamMembers.push(TeamMember(0xf95893867D4E3216f9B1fDEF9fd2340bFaEB09A7, "fran"));
        teamMembers.push(TeamMember(0x1cf61eE5391CB74671d19f071cD45b1d70DeC2f5, "guy"));
        teamMembers.push(TeamMember(0x3Aa3Fd1B762CaC519D405297CE630beD30430b00, "brian"));
        teamMembers.push(TeamMember(0x5bBc546f1F38ADbf69BA4D00a7e6e1c08B9ed341, "david"));
        // test operators - eric
        teamMembers.push(TeamMember(0x9a073D235A8D2C37854Da6f6A8F075C916debe06, "testoperator1"));
        teamMembers.push(TeamMember(0x46a1ea206Ef8EC604155abA33AD3a1E3054E132F, "testoperator2"));
        teamMembers.push(TeamMember(0xE7A9DB2D1781aEC9D5De0aa17C31eFC987C14b96, "testoperator3"));
    }


    function addTeamMember(address _memberAddress, string memory _memberName) public onlyOwner {
        teamMembers.push(TeamMember(_memberAddress, _memberName));
    }

    function getAllTeamAddresses() public view returns (address[] memory) {
        address[] memory teamAddresses = new address[](teamMembers.length);

        for(uint i = 0; i < teamMembers.length; i++) {
            teamAddresses[i] = teamMembers[i].memberAddress;
        }
        return teamAddresses;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}