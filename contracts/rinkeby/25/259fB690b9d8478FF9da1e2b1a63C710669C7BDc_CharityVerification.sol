// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title   Charity Verification
 * @author  sicktastic.eth
 * @notice  Verifying should be only allowed to Kind Blocks DAO wallet
 */
contract CharityVerification is Ownable {

    /// @dev We use charityId and charitySafe as an external Id
    /// @param charityName Name of the charity
    /// @param charityId EIN for USA, this can be different for all countries
    /// @param charitySafe Charity Gnosis safe address
    /// @param verifiedTimeStamp UNIX timestamp when Kind Blocks verified the charity
    struct Charity {
        string charityName;
        string charityId;
        address charitySafe;
        uint verifiedTimeStamp;
    }

    /// @dev Gnosis wallet address is mapped to Charity Struct
    mapping(address => Charity) charities;

    /// @dev This is used to prevent duplicate safe addresses
    mapping(address => bool) verifiedSafes;

    /// @dev This is used to prevent duplicate charity Ids
    mapping(string => bool) verifiedCharities;

    /// @dev Keeping track of all the Gnosis safe addresses and charity Ids
    address[] safeAddresses;
    string[] charityIds;

    /// @dev This function should be only called by the owner Gnosis safe
    function verifyCharity(
        string calldata _charityName,
        string  calldata _charityId,
        address _charitySafe,
        uint  _verifiedTimeStamp
    ) public onlyOwner {
        /// @notice Make sure there are no duplication, since these are recorded on chain
        require(!verifiedSafes[_charitySafe], "This safe is already verified.");
        require(!verifiedCharities[_charityId], "This charity is already verified.");

        Charity memory c = Charity({
            charityName: _charityName,
            charityId: _charityId,
            charitySafe: _charitySafe,
            verifiedTimeStamp: _verifiedTimeStamp
        });

        charities[_charitySafe] = c;

        /// @dev Mapping the address with boolean value to evaluate duplication
        verifiedSafes[_charitySafe] = true;
        verifiedCharities[_charityId] = true;

        /// @dev Array of Gnosis safe wallet addresses 
        safeAddresses.push(_charitySafe);

        /// @dev Array of charity identification numbers
        charityIds.push(_charityId);
    }

    /// @dev Return charity info of given Gnosis safe address
    function getCharity(address _safeAddress) view public returns (Charity memory) {
        return charities[_safeAddress];
    }

    /// @dev Return all the safe addresses
    function getCharitySafeAddresses() view public returns (address[] memory) {
        return safeAddresses;
    }

    /// @dev Return total count of Gnosis safes
    function countSafes() view public returns (uint) {
        return safeAddresses.length;
    }

    /// @dev Return total count of Charity Ids
    function countCharities() view public returns (uint) {
        return charityIds.length;
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