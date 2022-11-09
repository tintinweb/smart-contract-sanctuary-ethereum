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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

library SharedStructs {
    struct SenatorData {
        string state;
        string senatorFullname;
    }

    struct GovernorData {
        string state;
        string fullname;
    }
}

contract Nov2022Elections is Ownable {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    event SetWinnerSenator(string state, string fullname);
    event SetWinnerGovernor(string state, string fullname);

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------
    mapping(string => string[]) public winnerSenators;
    mapping(string => string[]) public winnerGovernors;

    /// -----------------------------------------------------------------------
    /// internal functions
    /// -----------------------------------------------------------------------

    function compareTwoStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function getWinnerSenatorsByState(string calldata state)
        external
        view
        returns (string memory, string[] memory senators)
    {
        return (state, winnerSenators[state]);
    }

    function getWinnerSenator(string calldata state, string calldata fullname)
        external
        view
        returns (bool winner)
    {
        for (uint256 i = 0; i < winnerSenators[state].length; ) {
            string memory currentSenator = winnerSenators[state][i];

            if (compareTwoStrings(currentSenator, fullname) == true)
                return true;

            unchecked {
                i++;
            }
        }
    }

    function getWinnerGovernors(string calldata state)
        external
        view
        returns (string[] memory)
    {
        return winnerGovernors[state];
    }

    function getWinnerGovernor(string calldata state, string calldata _fullname)
        external
        view
        returns (bool winner)
    {
        for (uint256 i = 0; i < winnerGovernors[state].length; ) {
            string memory governor = winnerGovernors[state][i];

            if (compareTwoStrings(governor, _fullname) == true) return true;

            unchecked {
                i++;
            }
        }
    }

    function setWinnerSenator(string calldata fullname, string calldata state)
        external
        onlyOwner
    {
        winnerSenators[state].push(fullname);
        emit SetWinnerSenator(state, fullname);
    }

    function setWinnerSenators(SharedStructs.SenatorData[] memory senators)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < senators.length; ) {
            SharedStructs.SenatorData memory senator = senators[i];
            winnerSenators[senator.state].push(senator.senatorFullname);
            emit SetWinnerSenator(senator.state, senator.senatorFullname);

            unchecked {
                i++;
            }
        }
    }

    function setWinnerGovernors(SharedStructs.GovernorData[] calldata governors)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < governors.length; ) {
            SharedStructs.GovernorData memory governor = governors[i];
            winnerGovernors[governor.state].push(governor.fullname);

            emit SetWinnerGovernor(governor.state, governor.fullname);

            unchecked {
                i++;
            }
        }
    }

    function setWinnerGovernor(string calldata fullname, string calldata state)
        external
        onlyOwner
    {
        winnerGovernors[state].push(fullname);
        emit SetWinnerGovernor(state, fullname);
    }

    function deleteSenator(string calldata state, string calldata fullname)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < winnerSenators[state].length; ) {
            string memory senator = winnerSenators[state][i];
            if (compareTwoStrings(senator, fullname) == true)
                delete winnerSenators[state][i];

            unchecked {
                i++;
            }
        }
    }

    function deleteGovernor(string calldata state, string calldata _governor)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < winnerGovernors[state].length; ) {
            string memory governor = winnerGovernors[state][i];
            if (compareTwoStrings(governor, _governor) == true)
                delete winnerGovernors[state][i];

            unchecked {
                i++;
            }
        }
    }
}