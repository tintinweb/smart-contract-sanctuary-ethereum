// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Decentralized Application Project
// Team: To The Moon
// Members:
// 1. 2210731503004 นายภัทรศักดิ์ ผอบแก้ว
// 2. 2210731503005 นายจารุภูมิ ชาลีสมบัติ
// 3. 2130731303011 นายรัชชานนท์ นิศกุลรัตน์ 
// Detail: Lucky Draw

import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyDraw is Ownable {
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(uint256 => mapping(address => string)) public mappingAcctName;
    mapping(uint256 => address[]) public accounts;
    uint256 public currentRound = 0;

    event RegisterEvent(uint256 _round ,address indexed _from, uint256 _value);
    event TransferRewardEvent(uint256 _round ,address indexed _from, address indexed _to, uint256 _value);
    event TransferFeeEvent(uint256 _round ,address indexed _from, address indexed _to, uint256 _value);
    event ResetEvent(uint256 _round ,address indexed _from, address indexed _to, uint256 _value);

    function register(string memory accountName) public payable {
        require(bytes(accountName).length > 0, "Register name can't empty");
        require(msg.value == 0.05 ether, "Register sizes are restricted to 0.05 ether");
        require(balances[currentRound][msg.sender] == 0, "An address cannot register twice");
        accounts[currentRound].push(msg.sender);
        require(accounts[currentRound].length <= 6, "Can't register more than 6 account");
        balances[currentRound][msg.sender] = msg.value;
        mappingAcctName[currentRound][msg.sender] = accountName;
        emit RegisterEvent(currentRound, msg.sender, msg.value);
    }

    function accountCount() public view returns (uint256) {
        return accounts[currentRound].length;
    }

    function allAccount() public view returns (address[] memory) {
        return accounts[currentRound];
    }

    function adminTransfer(uint256 acctIndex) 
        public
        onlyOwner 
    {
        address toAccount = accounts[currentRound][acctIndex];
        uint256 fee = address(this).balance * 30 / 100;
        uint256 reward = address(this).balance - fee;
        payable(toAccount).transfer(reward);
        emit TransferRewardEvent(currentRound, address(this), toAccount, reward);
        payable(owner()).transfer(fee);
        emit TransferFeeEvent(currentRound, address(this), owner(), fee);
        adminReset();
    }

    function adminReset() 
        public 
        onlyOwner
    {   
        if(address(this).balance > 0) {
            for (uint256 i = 0; i < accounts[currentRound].length; i++) {
                address toAccount = accounts[currentRound][i];
                uint256 balance = balances[currentRound][toAccount];
                payable(toAccount).transfer(balance);
                emit ResetEvent(currentRound, address(this), toAccount, balance);
            }
        }
        currentRound += 1;
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