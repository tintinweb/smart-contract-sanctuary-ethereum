/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**

>>> UPDATES

>>> 18 DEC 2022:
        - Add Custom Errors;
        - paySubscription function returns a boolean value so devs can perform actions
          after a user successfully paid the subscription;

 */


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

abstract contract Subscription is Ownable {
    uint256 public ethFee;
    mapping (address => EthPayment ) public userPaymentEth;
    address public feeCollector;

    struct EthPayment {
        uint256 paymentMoment; 
        uint256 paymentExpire; 
    }

    /// @dev Array of Eth payments
    EthPayment[] public ethPayments;

    /// @dev Events
    event UserPaidEth(address indexed who, uint256 indexed fee, uint256 indexed period);

    /// @dev Errors
    error FailedEthTransfer();

    /// @dev We transfer the ownership to a given owner
    constructor() {
        _transferOwnership(_msgSender());
        feeCollector = _msgSender();
    }

 
    function paySubscription(uint256 _period) external payable virtual returns(bool) { 

        if(msg.value != ethFee * _period) revert FailedEthTransfer();
        
        EthPayment memory newPayment = EthPayment(block.timestamp, block.timestamp + (_period * (30 days)));
        ethPayments.push(newPayment); // Push the payment in the payments array
        userPaymentEth[msg.sender] = newPayment; // User's last payment

        emit UserPaidEth(msg.sender, ethFee * _period, _period);

        return true;
    }

    function setEthFee(uint256 _newEthFee) external virtual onlyOwner {
        ethFee = _newEthFee;
    }

    function setNewPaymentCollector(address _feeCollector) external virtual onlyOwner {
        feeCollector = _feeCollector;
    }

    function withdrawEth() external virtual onlyOwner {
        uint256 _amount = address(this).balance;

        (bool sent, ) = feeCollector.call{value: _amount}("");
        if(sent == false) revert FailedEthTransfer();
    }

}


contract TwitTools is Subscription {
    constructor() {
    // We set the fee to 1 Ether (1 * 10 * 18)
        //setEthFee(1000000000000000000);
    }
}