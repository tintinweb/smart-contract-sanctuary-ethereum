/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// Proxy mint for InPeak allowing to claim NFTs for users having pledged so far.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity)
        external
        payable;
}

contract InPeakProxyMint is Ownable {
    IERC721Pledge public inPeakContract;
    uint256 public price = 0.08 ether;
    uint256 public fee = 250;
    mapping(address => bool) public allowed;
    mapping(address => bool) public claimed;

    constructor(IERC721Pledge inPeakContract_) {
        inPeakContract = inPeakContract_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint() external payable callerIsUser {
        require(allowed[msg.sender] && !claimed[msg.sender], "You are not allowed to mint or have already minted");
        require(msg.value == price, "Wrong amount");
        claimed[msg.sender] = true;

        uint256 pmRevenue = (price * fee) / 10000;
        inPeakContract.pledgeMint{ value: price - pmRevenue }(msg.sender, 1);
    }

    function mintFor(address recipient) external payable onlyOwner {
        inPeakContract.pledgeMint(recipient, 1);
    }

    function setInPeakContract(IERC721Pledge inPeakContract_) external onlyOwner {
        inPeakContract = inPeakContract_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
    }

    function allowAddresses(address[] calldata allowlist_)
        external
        onlyOwner
    {
        for (uint256 i; i < allowlist_.length; ) {
            allowed[allowlist_[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    function setAllowed(address wallet, bool isAllowed) 
        external
        onlyOwner
    {
        allowed[wallet] = isAllowed;
    }

    function setClaimed(address wallet, bool isClaimed) 
        external
        onlyOwner
    {
        claimed[wallet] = isClaimed;
    }

    // in case some funds end up stuck in the contract
    function withdrawBalance() 
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}