/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/KNKRAISE.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract KnkRaise is Ownable {
    uint64 public level1Size = 0;
    uint64 public level2Size = 0;
    uint64 public level3Size = 0;
    uint64 public level4Size = 0;
    mapping(address => uint256) public level1;
    mapping(address => uint256) public level2;
    mapping(address => uint256) public level3;
    mapping(address => uint256) public level4;
    bool public raiseOpen = false;

    function depositLevel1() payable public {
        require(raiseOpen == true, "Raise is not open");
        require(msg.value == 0.25 ether|| msg.value == 0.5 ether || msg.value == 0.75 ether, "you must deposit 0.25,0.5 or 0.75 ether");
        require(level1Size < 45, "this level is full");
        require(level1[msg.sender] == 0 && level2[msg.sender] == 0 && level3[msg.sender] == 0 && level4[msg.sender] == 0, "you already deposit in the raise");
        level1[msg.sender] = msg.value;
        level1Size++;
    }

    function depositLevel2() payable public {
        require(raiseOpen == true, "Raise is not open");
        require(msg.value == 1 ether|| msg.value == 1.25 ether || msg.value == 1.50 ether || msg.value == 1.75 ether, "you must deposit 1,1.25, 1.75");
        require(level1[msg.sender] == 0 && level2[msg.sender] == 0 && level3[msg.sender] == 0 && level4[msg.sender] == 0, "you already deposit in the raise");
        require(level2Size < 15, "this level is full");
        level2[msg.sender] = msg.value;
        level2Size++;
    }

    function depositLevel3() payable public {
        require(raiseOpen == true, "Raise is not open");
        require(msg.value == 2 ether|| msg.value == 2.25 ether || msg.value == 2.5 ether || msg.value == 2.75 ether|| msg.value == 3 ether, "you must deposit 2,2.25, 2.5, 2.75 or 3 ethers");
        require(level1[msg.sender] == 0 && level2[msg.sender] == 0 && level3[msg.sender] == 0 && level4[msg.sender] == 0, "you already deposit in the raise");
        require(level3Size < 7, "this level is full");
        level3[msg.sender] = msg.value;
        level3Size++;
    }

    function depositLevel4() payable public {
        require(raiseOpen == true, "Raise is not open");
        require(msg.value == 5 ether, "you must deposit 5 ethers");
        require(level1[msg.sender] == 0 && level2[msg.sender] == 0 && level3[msg.sender] == 0 && level4[msg.sender] == 0, "you already deposit in the raise");
        require(level4Size < 3, "this level is full");
        level4[msg.sender] = msg.value;
        level4Size++;
    }

    function setOpen(bool _open) public onlyOwner {
        raiseOpen = _open;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os);
    }
}