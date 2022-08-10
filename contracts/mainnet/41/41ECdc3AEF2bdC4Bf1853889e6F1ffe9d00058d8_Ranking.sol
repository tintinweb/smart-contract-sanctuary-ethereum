//SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title The rank contract allows you to assign a rank to users.
/// @author Nethny
/// @notice Allows you to assign different parameters to users
/// @dev By default, the first created rank is used for users.
/// This rank can be changed using various parameter change functions.
/// Ranks are 2 arrays (name array, value array), they are extensible
/// and provide flexibility to the rank system.
/// (Don't forget about memory allocation and overuse)
///
/// EXAMPLE ==================
/// "First", ["1 param", "2 param", "3 param", "4 param"],  [1,2,3,4], True
/// "Second", ["A", "B", "C", "D"],  [4,3,2,1], True
/// EXAMPLE ==================
contract Ranking is Ownable {
    struct Rank {
        string Name;
        string[] pNames;
        uint256[] pValues;
        bool isChangeable;
    }

    //List of ranks
    Rank[] public _ranks;
    mapping(string => uint256) public _rankSequence;
    uint256 _ranksHead;

    //Table of ranks assigned to users
    mapping(address => uint256) public _rankTable;

    /// @notice Give a users the rank
    /// @dev To make it easier to change the ranks of a large number of users
    /// For the admin only
    /// @param users - an array of users to assign a rank to, rank - the name of the title to be awarded
    /// @return bool (On successful execution returns true)
    function giveRanks(address[] memory users, string memory rank)
        public
        onlyOwner
        returns (bool)
    {
        uint256 index = searchRank(rank);

        for (uint256 i = 0; i < users.length; i++) {
            _rankTable[users[i]] = index;
        }

        return true;
    }

    /// @notice Give a user the rank
    /// @dev For the admin only
    /// @param user - the address of the user to whom you want to assign a rank, rank - the name of the title to be awarded
    /// @return bool (On successful execution returns true)
    function giveRank(address user, string memory rank)
        public
        onlyOwner
        returns (bool)
    {
        uint256 index = searchRank(rank);

        _rankTable[user] = index;

        return true;
    }

    /// @notice Сreate the rank
    /// @dev For the admin only
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @param pValues[] - An array of parameter values
    /// @param isChangeable - Flag of rank variability
    /// @return bool (On successful execution returns true)
    function createRank(
        string memory Name,
        string[] memory pNames,
        uint256[] memory pValues,
        bool isChangeable
    ) public onlyOwner returns (bool) {
        require(
            pNames.length == pValues.length,
            "RANK: Each parameter must have a value!"
        );

        Rank memory rank = Rank(Name, pNames, pValues, isChangeable);

        _rankSequence[Name] = _ranksHead;

        _ranks.push(rank);
        _ranksHead++;
        return true;
    }

    /// @notice Сhange the rank
    /// @dev For the admin only
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @param pValues[] - An array of parameter values
    /// @param isChangeable - Flag of rank variability
    /// @return bool (On successful execution returns true)
    function changeRank(
        string memory Name,
        string[] memory pNames,
        uint256[] memory pValues,
        bool isChangeable
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");
        require(
            pNames.length == pValues.length,
            "RANK: Each parameter must have a value!"
        );

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index] = Rank(Name, pNames, pValues, isChangeable);

        return true;
    }

    /// @notice Сhange only the names of the rank parameters
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @return bool (On successful execution returns true)
    function changeRankParNames(string memory Name, string[] memory pNames)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            pNames.length == _ranks[index].pNames.length,
            "RANK: Each parameter must have a value!"
        );

        _ranks[index].pNames = pNames;
        return true;
    }

    /// @notice Сhange only the values of the rank parameters
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param pValues[] - An array of parameter values
    /// @return bool (On successful execution returns true)
    function changeRankParValues(string memory Name, uint256[] memory pValues)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            pValues.length == _ranks[index].pValues.length,
            "RANK: Each parameter must have a value!"
        );

        _ranks[index].pValues = pValues;
        return true;
    }

    /// @notice Blocks rank variability
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @return bool (On successful execution returns true)
    function lockRank(string memory Name) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index].isChangeable = false;
        return true;
    }

    /// @notice Renames the rank parameter
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewParName - New parameter name
    /// @param NumberPar - The number of the parameter you want to change
    /// @return bool (On successful execution returns true)
    function renameRankParam(
        string memory Name,
        string memory NewParName,
        uint256 NumberPar
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            _ranks[index].pNames.length > NumberPar,
            "RANK: There is no such parameter!"
        );

        _ranks[index].pNames[NumberPar] = NewParName;
        return true;
    }

    /// @notice Change the rank parameter
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewValue - New parameter value
    /// @param NumberPar - The number of the parameter you want to change
    /// @return bool (On successful execution returns true)
    function changeRankParam(
        string memory Name,
        uint32 NewValue,
        uint256 NumberPar
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            _ranks[index].pNames.length > NumberPar,
            "RANK: There is no such parameter!"
        );

        _ranks[index].pValues[NumberPar] = NewValue;
        return true;
    }

    /// @notice Renames the rank
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewName - New rank name
    /// @return bool (On successful execution returns true)
    function renameRank(string memory Name, string memory NewName)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index].Name = NewName;

        _rankSequence[Name] = 0;
        _rankSequence[NewName] = index;

        return true;
    }

    /// @notice Searches for a rank by its name
    /// @dev For internal calls only
    /// @param Name - Unique rank identifier
    /// @return uint256 (Returns the number of the title you are looking for, or discards Rank not found)
    function searchRank(string memory Name) internal view returns (uint256) {
        uint256 temp = _rankSequence[Name];
        if (temp < _ranksHead) {
            return temp;
        }

        revert("RANK: There is no such rank!");
    }

    //View Functions

    /// @notice Shows the ranks
    /// @dev Read-only calls
    /// @return Rank[]
    function showRanks() public view returns (Rank[] memory) {
        require(_ranks.length > 0, "RANK: There are no ranks.");
        return _ranks;
    }

    /// @notice Shows the ranks parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function showRank(string memory Name)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        return (
            _ranks[searchRank(Name)].Name,
            _ranks[searchRank(Name)].pNames,
            _ranks[searchRank(Name)].pValues,
            _ranks[searchRank(Name)].isChangeable
        );
    }

    /// @notice Shows the ranks parameters
    /// @dev Read-only calls
    /// Saves gas by not using rank names
    /// @param Number - Rank number in the ranks array
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function showRankOfNumber(uint256 Number)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        require(_ranks.length > Number, "RANK: There are no ranks.");
        return (
            _ranks[Number].Name,
            _ranks[Number].pNames,
            _ranks[Number].pValues,
            _ranks[Number].isChangeable
        );
    }

    /// @notice Returns the user's rank
    /// @dev Read-only calls
    /// @param user - User address
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function getRank(address user)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        return (
            _ranks[_rankTable[user]].Name,
            _ranks[_rankTable[user]].pNames,
            _ranks[_rankTable[user]].pValues,
            _ranks[_rankTable[user]].isChangeable
        );
    }

    /// @notice Returns the names of the rank parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// string[] Parameters names
    function getNameParRank(string memory Name)
        public
        view
        returns (string[] memory)
    {
        return _ranks[searchRank(Name)].pNames;
    }

    /// @notice Returns the values of the rank parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// uint23[] Parameters values
    function getParRank(string memory Name)
        public
        view
        returns (uint256[] memory)
    {
        return _ranks[searchRank(Name)].pValues;
    }

    /// @notice Returns the current user parameters
    /// @dev Read-only calls
    /// @param user - User address
    /// @return uint32[] Parameters values
    function getParRankOfUser(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _ranks[_rankTable[user]].pValues;
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