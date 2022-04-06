/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.0;

// ██████╗░██╗████████╗░█████╗░██╗░░██╗░█████╗░░█████╗░██╗███╗░░██╗
// ██╔══██╗██║╚══██╔══╝██╔══██╗██║░░██║██╔══██╗██╔══██╗██║████╗░██║
// ██████╦╝██║░░░██║░░░██║░░╚═╝███████║██║░░╚═╝██║░░██║██║██╔██╗██║
// ██╔══██╗██║░░░██║░░░██║░░██╗██╔══██║██║░░██╗██║░░██║██║██║╚████║
// ██████╦╝██║░░░██║░░░╚█████╔╝██║░░██║╚█████╔╝╚█████╔╝██║██║░╚███║
// ╚═════╝░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░╚════╝░░╚════╝░╚═╝╚═╝░░╚══╝
// 
// ███████╗██╗░░██╗░█████╗░██╗░░██╗░█████╗░███╗░░██╗░██████╗░███████╗
// ██╔════╝╚██╗██╔╝██╔══██╗██║░░██║██╔══██╗████╗░██║██╔════╝░██╔════╝
// █████╗░░░╚███╔╝░██║░░╚═╝███████║███████║██╔██╗██║██║░░██╗░█████╗░░
// ██╔══╝░░░██╔██╗░██║░░██╗██╔══██║██╔══██║██║╚████║██║░░╚██╗██╔══╝░░
// ███████╗██╔╝╚██╗╚█████╔╝██║░░██║██║░░██║██║░╚███║╚██████╔╝███████╗
// ╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚══════╝
// 
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

interface IBitchcoin {

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function isApprovedForAll(address account, address operator) external view returns (bool);

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface IWrappedBitcoin {

  function allowance(address _owner, address _spender) external returns (uint256);

  function balanceOf(address _who) external returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value) external;
}

contract BitchcoinExchange is Ownable {

    IBitchcoin bitchcoin;
    IWrappedBitcoin wrappedBitcoin;

    uint256 public price;

    constructor(address btch, address wbtc, uint256 _price) {
        bitchcoin = IBitchcoin(btch);
        wrappedBitcoin = IWrappedBitcoin(wbtc);

        price = _price;
    }

    function balance(uint256 tokenId) public view returns(uint256) {
        if (!bitchcoin.isApprovedForAll(owner(), address(this)))
            return 0;
        return bitchcoin.balanceOf(owner(), tokenId);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function buy(uint256 tokenId) public {
        require(wrappedBitcoin.balanceOf(msg.sender) >= price, "You must have enough Wrapped Bitcoins");
        require(wrappedBitcoin.allowance(msg.sender, address(this)) >= price, "I must be allowed to spend your Wrapped Bitcoins");
        require(bitchcoin.balanceOf(owner(), tokenId) > 0, "I'm out of stock");
        wrappedBitcoin.transferFrom(msg.sender, owner(), price);
        bitchcoin.safeTransferFrom(owner(), msg.sender, tokenId, 1, "");
    }
}