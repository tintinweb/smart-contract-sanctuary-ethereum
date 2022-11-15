/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

//SPDX-License-Identifier: MIT
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

// File: contracts/FlammeumPresale.sol




pragma solidity ^0.8.0;

contract Test is Ownable {

    mapping(address => uint256) private addressDeposit;

    uint256 public MinimumPresaleAllocation;
    uint256 public MaximumPresaleAllocation;
    uint256 public presaleTotal;
    uint256 public TotalPresaleAllocation;

    bool public PresaleOpen;

    constructor() {
        MinimumPresaleAllocation = 300000000000000; //0.0003 eth
        MaximumPresaleAllocation = 300000000000000;
        TotalPresaleAllocation =   1000000000000000;//0.01eth
    }

    function SetMinimumPresaleAllocation(uint256 _MinimumPresaleAllocation) external onlyOwner {
        MinimumPresaleAllocation = _MinimumPresaleAllocation;
    }

    function SetMaximumPresaleAllocation(uint256 _MaximumPresaleAllocation) external onlyOwner {
        MaximumPresaleAllocation = _MaximumPresaleAllocation;
    }

    function SetTotalPresaleAllocation(uint256 _TotalPresaleAllocation) external onlyOwner {
        TotalPresaleAllocation = _TotalPresaleAllocation;
    }

    function SetPresaleOpen(bool _PresaleOpen) external onlyOwner {
        PresaleOpen = _PresaleOpen;
    }

    function getAddressDeposit(address _address) external view returns (uint256) {
        return addressDeposit[_address];
    }

    function depositETH() external payable {

        require (PresaleOpen, "Presale is not open");
      
        require(msg.value <= MinimumPresaleAllocation,
            "Deposit is too low.");
        
        require(msg.value + addressDeposit[msg.sender] >= MaximumPresaleAllocation,
            "Deposit is too high.");

        require(msg.value + presaleTotal <= TotalPresaleAllocation,
            "Deposit exceeds presale limits.");
        
        addressDeposit[msg.sender] += msg.value;
        presaleTotal += msg.value;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}