/*
🇧​​​​​ 🇮​​​​​ 🇱​​​​​ 🇪​​​​​ 🇹​​​​​ 🇸​​​​​

🇨​​​​​ 🇱​​​​​ 🇺​​​​​ 🇧​​​​​

████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
█████████████''.....................................''█████████████
█████████████''...........██████████████............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██████████████............''█████████████
█████████████''..............█████████..............''█████████████
█████████████''............█████████████............''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''.....................................''█████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BiletsClubCharStatus Contract
 */

contract BiletsClubCharStatus is Ownable, ReentrancyGuard {
    string public name = "Bilets Club Char Status";
    string public symbol = "BLT-CharStatus";
    bool public pause = false;
    struct NFTSstatus {
        uint256 balancesExp;
        uint256 health;
        uint256 mana;
    }
    mapping(uint256 => NFTSstatus) public NFTstatus;
    mapping(address => bool) public admins;

    modifier onlyAdmins() {
        require(admins[msg.sender] == true, "Caller is not a admin.");
        _;
    }
    modifier isPaused() {
        require(pause == false, "The contract is paused.");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    /******************** PUBLIC ********************/
    function getTokenEXP(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].balancesExp;
    }

    function getTokenHealth(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].health;
    }

    function getTokenMana(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].mana;
    }

    /******************** ADMINS ********************/
    function changeStatus(
        bool earn,
        uint256 tokenID,
        uint256 amountExp,
        uint256 amountHp,
        uint256 amountMana
    ) external payable onlyAdmins nonReentrant isPaused {
        if (earn)
            NFTstatus[tokenID] = NFTSstatus(
                getTokenEXP(tokenID) + amountExp,
                getTokenHealth(tokenID) + amountHp,
                getTokenMana(tokenID) + amountMana
            );
        else {
            NFTstatus[tokenID] = NFTSstatus(
                getTokenEXP(tokenID) - amountExp,
                getTokenHealth(tokenID) - amountHp,
                getTokenMana(tokenID) - amountMana
            );
        }
    }

    /******************** OWNER ********************/
    function setAdmin(address _admin, bool _key) public onlyOwner {
        admins[_admin] = _key;
    }

    function flipPause() public onlyOwner {
        pause = !pause;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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