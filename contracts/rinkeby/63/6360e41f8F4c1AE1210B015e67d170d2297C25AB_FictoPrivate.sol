// SPDX-License-Identifier: MIT

// ___________._______________________________    ____________________._______   _______________________________
// \_   _____/|   \_   ___ \__    ___/\_____  \   \______   \______   \   \   \ /   /  _  \__    ___/\_   _____/
//  |    __)  |   /    \  \/ |    |    /   |   \   |     ___/|       _/   |\   Y   /  /_\  \|    |    |    __)_
//  |     \   |   \     \____|    |   /    |    \  |    |    |    |   \   | \     /    |    \    |    |        \
//  \___  /   |___|\______  /|____|   \_______  /  |____|    |____|_  /___|  \___/\____|__  /____|   /_______  /
//      \/                \/                  \/                    \/                    \/                 \/

///////
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegated is Ownable {
    mapping(address => bool) internal _delegates;

    constructor() {
        _delegates[owner()] = true;
    }

    modifier onlyDelegates() {
        require(_delegates[msg.sender], "Invalid delegate");
        _;
    }

    //onlyOwner
    function isDelegate(address addr) external view onlyOwner returns (bool) {
        return _delegates[addr];
    }

    function setDelegate(address addr, bool isDelegate_) external onlyOwner {
        _delegates[addr] = isDelegate_;
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        _delegates[newOwner] = true;
        super.transferOwnership(newOwner);
    }
}

contract FictoPrivate is Delegated {
    constructor() {}

    event PaymentReleased(address, uint256);
    address anonx = 0xeB2B7dbf1D37B1495f855aCb2d251Fa68e1202ce;

    function setAnonx(address addr) public onlyDelegates {
        anonx = addr;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawSome(uint256 _amount, address _to) public onlyDelegates {
        uint256 bank = address(this).balance;
        require(_amount < bank, "too much!");

        (bool wa, ) = payable(_to).call{value: _amount}("");
        require(wa);

        emit PaymentReleased(anonx, _amount);
    }

    function withdrawAll() public onlyDelegates {
        uint256 bank = address(this).balance;

        (bool wa, ) = payable(anonx).call{value: bank}("");
        require(wa);

        emit PaymentReleased(anonx, bank);
    }

    event GotIt(address, uint256);

    receive() external payable {
        // React to receiving ether
    }

    function buyFicto() external payable {
        emit GotIt(msg.sender, msg.value);
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