/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: UNLICENSED
// Cryptout.io smart contract for payments
pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract CryptoutPayment {
    address public _owner;
    address public _pendingOwner;
    uint256 public _fee = 1;

    event PaymentFinished(address token, uint256 amount);
    event ClaimedTokens(address token, address owner, uint256 amount);

    modifier onlyOwner() {
        assert(msg.sender == _owner);
        _;
    }

    constructor(address owner) {
        _owner = owner;
        _pendingOwner = address(0x0);
    }

    function claimOwner(address newPendingOwner) public {
        require(msg.sender == _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = newPendingOwner;
    }

    function changeFee(uint256 newFee) public onlyOwner {
        _fee = newFee;
    }

    /**
     * @notice Cryptout.io: Pay with ETH
     * @dev Transfers given tokens to merchant address
     * @param merchantAddress Merchant address to transfer amount
     */
    function pay(
        address payable merchantAddress
    ) public payable {
        uint256 feeAmount = (msg.value * _fee) / 1000;
        uint256 transferAmount = msg.value - feeAmount;

        merchantAddress.transfer(transferAmount);
        payable(_owner).transfer(feeAmount);

        emit PaymentFinished(address(0), msg.value);
    }

    /**
     * @notice Cryptout.io: Pay with token
     * @dev Transfers given tokens to merchant address
     * @param token Token to pay with
     * @param merchantAddress Merchant address to transfer amount
     * @param amount Amount to pay
     */
    function payWithToken(
        address token,
        address merchantAddress,
        uint256 amount
    ) public {
        IERC20 erc20token = IERC20(token);
        require(amount > 0, "Amount cannot be zero");
        uint256 allowance = erc20token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token allowance failed!");

        // Calculate amounts
        uint256 feeAmount = (amount * _fee) / 1000;
        uint256 transferAmount = amount - feeAmount;

        // Transfer tokens to this contract as approved before
        erc20token.transferFrom(msg.sender, address(this), amount);

        // Send tokens to merchant, from this contract
        erc20token.transfer(merchantAddress, transferAmount);
        // Send tokens to owner, from this contract
        erc20token.transfer(_owner, feeAmount);

        emit PaymentFinished(token, amount);
    }
}