// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWETH.sol";

// Warning: TEST-ONLY CONTRACT!!! UNSAFE, DO NOT USE.

contract CreatorFeesReceiver is Ownable {

    struct CreatorFees{
        uint256 accrued;
        uint256 timestamp;
    }

    // WETH contract
    IWETH private constant _weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    CreatorFees public creatorFees;
    address public creatorAddress;

    constructor(){
        creatorAddress = msg.sender;
    }

    event Received(address indexed account, uint256 indexed amount);
    event Payout(address indexed account, uint256 indexed amount);

    function setCreatorAddress(address newAddress) external onlyOwner{
        require(newAddress!=address(0));
        creatorAddress=newAddress;
    }

    // New test with additional stuff
    receive() external payable{
        creatorFees.accrued+=msg.value;
        creatorFees.timestamp=block.timestamp;
        emit Received(tx.origin, msg.value);
        _forwardToCreator(address(this).balance);
        _unwrapWethIfAny();
    }

    function _forwardToCreator(uint256 amount) private{
        emit Payout(creatorAddress, amount);
        payable(creatorAddress).transfer(amount);
    }

    function _unwrapWethIfAny() public{
        uint256 bal = _weth.balanceOf(address(this));
        if(bal>0) _weth.withdraw(bal);
    }

    function _wethBalance() view public returns(uint256){
        return _weth.balanceOf(address(this));
    }

    function _wethUnwrap(uint256 amount) public{
        _weth.withdraw(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface to wrap/unwrap ETH.
 */
interface IWETH {

    /**
     * @dev Wrap (ETH -> WETH)
     */
    function deposit() external payable;

    /**
     * @dev Unwrap (WETH -> ETH)
     */
    function withdraw(uint256) external;

        /**
     * @dev WETH balance
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

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