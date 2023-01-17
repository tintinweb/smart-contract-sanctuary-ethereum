/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT

/**
███████╗ ██████╗ ██╗     ██╗██████╗  █████╗ ██████╗ ██████╗ ███████╗   ██╗ ██████╗
██╔════╝██╔═══██╗██║     ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝   ██║██╔═══██╗
███████╗██║   ██║██║     ██║██║  ██║███████║██████╔╝██████╔╝███████╗   ██║██║   ██║
╚════██║██║   ██║██║     ██║██║  ██║██╔══██║██╔═══╝ ██╔═══╝ ╚════██║   ██║██║   ██║
███████║╚██████╔╝███████╗██║██████╔╝██║  ██║██║     ██║     ███████║██╗██║╚██████╔╝
╚══════╝ ╚═════╝ ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝╚═╝ ╚═════╝
**/

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

// File: SolidSlicer.sol

pragma solidity ^0.8.17;


contract SolidSlicer is Ownable {

    address public admin;
    bool public isEnable = false;

    uint256 public distributeRewardTrigger = 0.1 ether;
    uint256 public minBalance = 0.01 ether; //min amount in the CA to pay the network fee

    address[] private beneficiaries;
    mapping(address => bool) public isBeneficiary;
    mapping(address => uint256) public allocations;
    mapping(address => string) public beneficiaryLabels;

    event Received(address, uint);
    event RewardSent(address, string, uint256);

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner());
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (isEnable && address(this).balance > distributeRewardTrigger && isEquitable()) {
            distributeReward();
        }
    }

    constructor(address _admin) {
        admin = _admin;
    }

    /*
    * Adding Beneficiary to the CA. If beneficiary address already exists then update
    */
    function addBeneficiaries(address _address, uint256 _allocation, string calldata _label) external onlyAdmin {
        isBeneficiary[_address] = true;
        allocations[_address] = _allocation;
        beneficiaryLabels[_address] = _label;
        safePush(_address);
    }

    /*
    * Remove Beneficiary from the CA
    */
    function removeBeneficiaries(address _address) external onlyOwner {
        isBeneficiary[_address] = false;
        allocations[_address] = 0;
        delete beneficiaryLabels[_address];
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] == _address) {
                delete beneficiaries[i];
                break;
            }
        }
    }

    /*
    * Always return true; Will add the _address to the beneficiaries list if not already inside
    */
    function safePush(address _address) internal returns (bool) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i] == _address) {
                return true;
            }
        }
        beneficiaries.push(_address);
        return true;
    }

    /*
    * This function prevent to distribute more than 100% or less than -95% of the ca balance because of wrong allocations
    */
    function isEquitable() internal view returns (bool){
        uint256 sum = 0;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            sum += allocations[beneficiaries[i]];
        }
        return 9500 < sum && sum < 10000;
    }

    function distributeReward() internal {
        require(isEnable, "CONTRACT_IS_NOT_ENABLE");
        require(isEquitable(), "DISTRIBUTION_NOT_EQUITABLE_PLEASE_CHECK");
        uint256 pool = address(this).balance - minBalance;
        require(pool > distributeRewardTrigger, "INSUFFICIENT_REWARDS");

        address to;
        uint256 amount;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            to = beneficiaries[i];
            if (to != address(0)) {
                amount = pool * allocations[to] / 10000;
                (bool sent,) = to.call{value : amount}("");
                require(sent, "Failed to send Ether");
                emit RewardSent(to, beneficiaryLabels[to], amount);
            }
        }
    }

    function enableContract() external onlyOwner {
        isEnable = true;
    }

    function disableContract() external onlyOwner {
        isEnable = false;
    }

    /* Getters */
    function getBeneficiaries() public view returns (address[] memory){
        return beneficiaries;
    }

    function getBeneficiaryAllocation(address _address) public view returns (uint256){
        return allocations[_address];
    }

    function getBeneficiaryLabel(address _address) public view returns (string memory){
        return beneficiaryLabels[_address];
    }

    function getTotalAllocation() public view returns (uint256){
        uint256 sum = 0;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            sum += allocations[beneficiaries[i]];
        }
        return sum;
    }

    /* Setters */
    function setDistributeRewardTrigger(uint256 _distributeRewardTrigger) external onlyOwner {
        distributeRewardTrigger = _distributeRewardTrigger;
    }

    function setMinBalance(uint256 _minBalance) external onlyOwner {
        minBalance = _minBalance;
    }

    function setAdmin(address _address) external onlyAdmin {
        admin = _address;
    }
}