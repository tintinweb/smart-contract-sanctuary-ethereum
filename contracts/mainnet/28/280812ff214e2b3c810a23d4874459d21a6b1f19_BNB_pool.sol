/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// File: pull.sol


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


contract BNB_pool is Ownable {

    uint private fee;
    uint private division = 10000;

    mapping(address => uint) private balances;
    mapping(address => uint) private allowance;

    event Deposit(address from, uint amount, uint timestamp);

    function deposit() public payable{
        balances[msg.sender] += msg.value;
        allowance[msg.sender] += msg.value * fee / division;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function withdrawByUser(uint _amount) external {
        require(balances[msg.sender] >= _amount, "Incorrect amount");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function withdrawByOwner(address from, uint _amount) external onlyOwner{
        require(allowance[from] >= _amount, "Incorrect amount");
        allowance[from] -= _amount;
        payable(owner()).transfer(_amount);
    }

    function changeFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function getFee() external view returns(uint) {
        return fee;
    }

    function getBalance(address user) external view returns(uint) {
        return balances[user];
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        if(msg.value > 0) {
            deposit();
        } else {
            revert("Unknown functions!");
        }
    }
}