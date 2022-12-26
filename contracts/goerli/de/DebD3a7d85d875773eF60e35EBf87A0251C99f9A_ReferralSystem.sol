// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

contract ReferralSystem is Ownable {
    struct Level {
        uint256 percentage;
    }

    struct RefInfo {
        address account;
        uint256 percentage;
    }

    Level[] public levels;
    mapping(address => address) public inviter;

    event RefAction(address _from, address indexed _to, uint256 _percentage);

    modifier isValidAccountAddress(address _account) {
        require(
            _account != address(0) && _account != address(this),
            "Invalid account"
        );
        _;
    }

    function addLevel(uint256 _percentage) public onlyOwner {
        levels.push(Level(_percentage));
    }

    function editLevel(uint256 _levelIndex, uint256 _percentage)
        public
        onlyOwner
    {
        require(levels.length > _levelIndex, "Level not found");

        levels[_levelIndex].percentage = _percentage;
    }

    function removeLevel() public onlyOwner {
        require(levels.length > 0, "No levels available");

        levels.pop();
    }

    function getLevels() public view onlyOwner returns (Level[] memory) {
        return levels;
    }

    function setInvitation(address _inviter, address _invitee)
        public
        onlyOwner
        isValidAccountAddress(_inviter)
        isValidAccountAddress(_invitee)
    {
        require(
            inviter[_invitee] == address(0x0),
            "Invitee has already an inviter"
        );
        require(
            _inviter != _invitee,
            "Inviter and invitee are the same address"
        );

        inviter[_invitee] = _inviter;
    }

    function addAction(address _account)
        public
        onlyOwner
        returns (RefInfo[] memory)
    {
        require(inviter[_account] != address(0x0), "Account has not inviter");

        RefInfo[] memory refInfo = getRefInfo(_account);

        require(refInfo.length > 0, "Beh");

        for (uint256 i = 0; i < refInfo.length; i++) {
            emit RefAction(_account, refInfo[i].account, refInfo[i].percentage);
        }

        return refInfo;
    }

    function hasInviter(address _account) public view returns (bool) {
        return inviter[_account] != address(0);
    }

    function getRefInfo(address _account)
        public
        view
        returns (RefInfo[] memory)
    {
        RefInfo[] memory refInfo = new RefInfo[](levels.length);
        address currentAccount = _account;
        uint256 levelsFound = 0;

        for (levelsFound = 0; levelsFound < levels.length; levelsFound++) {
            address inviterAddr = inviter[currentAccount];

            if (inviterAddr != address(0)) {
                refInfo[levelsFound] = RefInfo(
                    inviterAddr,
                    levels[levelsFound].percentage
                );
                currentAccount = inviterAddr;
            } else {
                break;
            }
        }

        RefInfo[] memory refInfoFound = new RefInfo[](levelsFound);

        for (
            uint256 levelIndex = 0;
            levelIndex < refInfoFound.length;
            ++levelIndex
        ) {
            refInfoFound[levelIndex] = refInfo[levelIndex];
        }

        return refInfoFound;
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