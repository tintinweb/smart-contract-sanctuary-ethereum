/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract EtomicSwap {
    enum PaymentState {
        Uninitialized,
        PaymentSent,
        ReceivedSpent,
        SenderRefunded
    }

    enum SecretHashAlgo {
        Dhash160,
        Sha256
    }

    struct Payment {
        bytes20 paymentHash;
        uint64 lockTime;
        PaymentState state;
    }

    mapping (bytes32 => Payment) public payments;
    mapping (bytes32 => SecretHashAlgo) public secret_hash_algos;

    event PaymentSent(bytes32 id);
    event ReceiverSpent(bytes32 id, bytes32 secret);
    event SenderRefunded(bytes32 id);

    constructor() { }

    function ethPayment(
        bytes32 _id,
        address _receiver,
        bytes20 _secretHash,
        uint64 _lockTime
    ) external payable {
        require(_receiver != address(0) && msg.value > 0 && payments[_id].state == PaymentState.Uninitialized);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                address(0),
                msg.value
            ));

        payments[_id] = Payment(
            paymentHash,
            _lockTime,
            PaymentState.PaymentSent
        );

        secret_hash_algos[_id] = SecretHashAlgo.Dhash160;
        emit PaymentSent(_id);
    }

    function ethPaymentSha256(
        bytes32 _id,
        address _receiver,
        bytes32 _secretHash,
        uint64 _lockTime
    ) external payable {
        require(_receiver != address(0) && msg.value > 0 && payments[_id].state == PaymentState.Uninitialized);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                address(0),
                msg.value
            ));

        payments[_id] = Payment(
            paymentHash,
            _lockTime,
            PaymentState.PaymentSent
        );

        secret_hash_algos[_id] = SecretHashAlgo.Sha256;
        emit PaymentSent(_id);
    }

    function erc20Payment(
        bytes32 _id,
        uint256 _amount,
        address _tokenAddress,
        address _receiver,
        bytes20 _secretHash,
        uint64 _lockTime
    ) external payable {
        require(_receiver != address(0) && _amount > 0 && payments[_id].state == PaymentState.Uninitialized);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                _tokenAddress,
                _amount
            ));

        payments[_id] = Payment(
            paymentHash,
            _lockTime,
            PaymentState.PaymentSent
        );

        secret_hash_algos[_id] = SecretHashAlgo.Dhash160;

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount));
        emit PaymentSent(_id);
    }

    function erc20PaymentSha256(
        bytes32 _id,
        uint256 _amount,
        address _tokenAddress,
        address _receiver,
        bytes32 _secretHash,
        uint64 _lockTime
    ) external payable {
        require(_receiver != address(0) && _amount > 0 && payments[_id].state == PaymentState.Uninitialized);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                _tokenAddress,
                _amount
            ));

        payments[_id] = Payment(
            paymentHash,
            _lockTime,
            PaymentState.PaymentSent
        );
        secret_hash_algos[_id] = SecretHashAlgo.Sha256;
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount));
        emit PaymentSent(_id);
    }

    function receiverSpend(
        bytes32 _id,
        uint256 _amount,
        bytes32 _secret,
        address _tokenAddress,
        address _sender
    ) external {
        require(payments[_id].state == PaymentState.PaymentSent);

        bytes20 paymentHash;

        if (secret_hash_algos[_id] == SecretHashAlgo.Dhash160) {
            paymentHash = ripemd160(abi.encodePacked(
                msg.sender,
                _sender,
                ripemd160(abi.encodePacked(sha256(abi.encodePacked(_secret)))),
                _tokenAddress,
                _amount
            ));
        } else if (secret_hash_algos[_id] == SecretHashAlgo.Sha256) {
            paymentHash = ripemd160(abi.encodePacked(
                msg.sender,
                _sender,
                sha256(abi.encodePacked(_secret)),
                _tokenAddress,
                _amount
            ));
        } else {
            revert("Unexpected secret_hash_algo");
        }

        require(paymentHash == payments[_id].paymentHash);
        payments[_id].state = PaymentState.ReceivedSpent;
        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount));
        }

        emit ReceiverSpent(_id, _secret);
    }

    function senderRefund(
        bytes32 _id,
        uint256 _amount,
        bytes20 _secretHash,
        address _tokenAddress,
        address _receiver
    ) external {
        require(payments[_id].state == PaymentState.PaymentSent);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                _tokenAddress,
                _amount
            ));

        require(paymentHash == payments[_id].paymentHash && block.timestamp >= payments[_id].lockTime);

        payments[_id].state = PaymentState.SenderRefunded;

        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount));
        }

        emit SenderRefunded(_id);
    }

    function senderRefundSha256(
        bytes32 _id,
        uint256 _amount,
        bytes32 _secretHash,
        address _tokenAddress,
        address _receiver
    ) external {
        require(payments[_id].state == PaymentState.PaymentSent);

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                _receiver,
                msg.sender,
                _secretHash,
                _tokenAddress,
                _amount
            ));

        require(paymentHash == payments[_id].paymentHash && block.timestamp >= payments[_id].lockTime);

        payments[_id].state = PaymentState.SenderRefunded;

        if (_tokenAddress == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount));
        }

        emit SenderRefunded(_id);
    }
}