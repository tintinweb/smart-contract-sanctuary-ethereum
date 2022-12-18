// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from "./utils/Ownable.sol";

contract Arblet is Ownable {
    bool public borrowLocked;
    uint256 public fee = 3 * 10 ** 15; // 3000000000000000 = 0.3%
    uint256 public protocolFee = 1 * 10 ** 15; // 1000000000000000 = 0.1%
    uint256 public shareSupply;
    address public protocol;

    mapping(address => uint256) public providerShares;
    mapping(address => uint256) public borrowerDebt;

    modifier borrowLock() {
        require(!borrowLocked, "Functions locked during a loan");
        _;
    }

    event LiquidityAdded(address indexed provider, uint256 ethAdded, uint256 sharesMinted);

    event LiquidityRemoved(address indexed provider, uint256 ethRemoved, uint256 sharesBurned);

    event LoanCompleted(address indexed borrower, uint256 debtRepayed);

    event LoanRepayed(address indexed borrower, address indexed payee, uint256 debtRepayed);

    receive() external payable {}

    // Auto repay debt from msg.sender
    fallback() external payable {
        // Shortcut for raw calls to repay debt
        //repayDebt(msg.sender);
    }

    function provideLiquidity() external payable borrowLock {
        require(msg.value > 1 wei, "Non-dust value required");
        uint256 sharesMinted = msg.value;
        providerShares[msg.sender] = providerShares[msg.sender] + sharesMinted;
        shareSupply = shareSupply + sharesMinted;

        emit LiquidityAdded(msg.sender, msg.value, sharesMinted);
    }

    function withdrawLiquidity(uint256 shareAmount) external borrowLock {
        require(shareAmount > 0, "non-zero value required");
        require(shareAmount <= providerShares[msg.sender], "insufficient user balance");
        require(shareAmount <= shareSupply, "insufficient global supply");

        uint256 sharePer = (address(this).balance * 10 ** 18 / shareSupply);
        uint256 shareValue = (sharePer * (shareAmount)) / 10 ** 18;

        providerShares[msg.sender] = providerShares[msg.sender] - shareAmount;
        shareSupply = shareSupply - shareAmount;

        (bool sent,) = msg.sender.call{value: shareValue}("");
        require(sent, "Failed to send Ether");

        emit LiquidityRemoved(msg.sender, shareValue, shareAmount);
    }

    //issue a new loan
    function borrow(uint256 ethAmount) external borrowLock {
        require(ethAmount >= 1 wei, "non-dust value required");
        require(ethAmount <= address(this).balance, "insufficient global liquidity");
        require(borrowerDebt[msg.sender] == 0, "active loan in progress");

        uint256 initialLiquidity = address(this).balance;
        uint256 interest = calculateInterest(ethAmount);
        uint256 protocolInterest = calculateProtocolInterest(ethAmount);
        uint256 outstandingDebt = ethAmount + interest;

        borrowLocked = true;
        borrowerDebt[msg.sender] = outstandingDebt;

        (bool result0,) = msg.sender.call{gas: (gasleft() - 10000), value: ethAmount}("");
        require(result0, "the call must return true");

        require(address(this).balance >= (initialLiquidity + interest), "funds must be returned plus interest");
        require(borrowerDebt[msg.sender] == 0, "borrower debt must be repaid in full");

        (bool result1,) = protocol.call{gas: (gasleft() - 10000), value: protocolInterest}("");
        require(result1, "the call must return true");

        borrowLocked = false;

        emit LoanCompleted(msg.sender, outstandingDebt);
    }

    function repayDebt(address borrower) public payable {
        require(borrowLocked == true, "can only repay active loans");
        require(borrowerDebt[borrower] != 0, "must repay outstanding debt");
        require(msg.value == borrowerDebt[borrower], "debt must be repaid in full");

        uint256 outstandingDebt = borrowerDebt[borrower];
        borrowerDebt[borrower] = 0;

        emit LoanRepayed(borrower, msg.sender, outstandingDebt);
    }

    function setProtocol(address protocol_) public onlyOwner borrowLock {
        protocol = protocol_;
    }

    function setFee(uint256 protocolFee_, uint256 providerFee_) public onlyOwner borrowLock {
        protocolFee = protocolFee_;
        fee = protocolFee_ + providerFee_;
    }
    /**
     * VIEW FUNCTIONS
     */

    // 1000000000000000000 = 100
    //
    // 10000000000000000 = 1
    //
    // 1000000000000000 = 0.1
    function liquidityAsPercentage(uint256 addedLiquidity) public view returns (uint256 liquidityPercentage) {
        if (address(this).balance <= 0) {
            liquidityPercentage = 10 ** 18;
        } else {
            uint256 liquidity = addedLiquidity + address(this).balance;
            liquidityPercentage = (addedLiquidity * 10 ** 18 / liquidity);
        }
    }

    function shareValue_(uint256 shareProportion) public view returns (uint256 value) {
        uint256 interestValue = address(this).balance - shareSupply;
        value = (interestValue * 10 ** 18) / shareProportion;
    }

    function calculateInterest(uint256 loanAmount) public view returns (uint256 interest) {
        interest = (loanAmount * fee) / 10 ** 18;
    }

    function calculateProtocolInterest(uint256 loanAmount) public view returns (uint256 protocolInterest) {
        protocolInterest = (loanAmount * protocolFee) / 10 ** 18;
    }

    function currentLiquidity() external view returns (uint256 avialableLiquidity) {
        avialableLiquidity = address(this).balance;
    }

    function getShares(address provider) public view returns (uint256) {
        return (providerShares[provider]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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