/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
  
    function allowance(address owner, address spender) external view returns (uint256);
  
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EtomicSwap {
    enum PaymentState {
        Uninitialized,
        PaymentSent,
        ReceivedSpent,
        SenderRefunded
    }

    enum SecretHashAlgo {
        Ripe160Sha256,
        Sha256,
        Keccak256
    }

    struct Payment {
        bytes20 paymentHash;
        uint64 lockTime;
        PaymentState state;
        SecretHashAlgo secret_hash_algo;
    }

    mapping (bytes32 => Payment) public payments;

    uint256 public version = 2;

    event PaymentSent(bytes32 id);
    event ReceiverSpent(bytes32 id, bytes32 secret);
    event SenderRefunded(bytes32 id);

    constructor() public { }

    function ethPayment(
        bytes32 _id,
        address _receiver,
        uint64 _lockTime,
        SecretHashAlgo _algo,
        bytes calldata _secretHash
    ) external payable {
        require(_receiver != address(0) && msg.value > 0 && payments[_id].state == PaymentState.Uninitialized);
        require(_algo == SecretHashAlgo.Ripe160Sha256 || _algo == SecretHashAlgo.Sha256 || _algo == SecretHashAlgo.Keccak256);

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
            PaymentState.PaymentSent,
            _algo
        );

        emit PaymentSent(_id);
    }

    function erc20Payment(
        bytes32 _id,
        uint256 _amount,
        address _tokenAddress,
        address _receiver,
        uint64 _lockTime,
        SecretHashAlgo _algo,
        bytes calldata _secretHash
    ) external payable {
        require(_receiver != address(0) && _amount > 0 && payments[_id].state == PaymentState.Uninitialized);
        require(_algo == SecretHashAlgo.Ripe160Sha256 || _algo == SecretHashAlgo.Sha256 || _algo == SecretHashAlgo.Keccak256);

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
            PaymentState.PaymentSent,
            _algo
        );

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
        bytes memory expected_hash;
        if (payments[_id].secret_hash_algo == SecretHashAlgo.Ripe160Sha256) {
            expected_hash = abi.encodePacked(ripemd160(abi.encodePacked(sha256(abi.encodePacked(_secret)))));
        } else if (payments[_id].secret_hash_algo == SecretHashAlgo.Sha256) {
            expected_hash = abi.encodePacked(sha256(abi.encodePacked(_secret)));
        } else if (payments[_id].secret_hash_algo == SecretHashAlgo.Keccak256) {
            expected_hash = abi.encodePacked(keccak256(abi.encodePacked(_secret)));
        } else {
            revert("Unknown secret hash algo");
        }

        bytes20 paymentHash = ripemd160(abi.encodePacked(
                msg.sender,
                _sender,
                expected_hash,
                _tokenAddress,
                _amount
            ));

        require(paymentHash == payments[_id].paymentHash);
        payments[_id].state = PaymentState.ReceivedSpent;
        if (_tokenAddress == address(0)) {
            msg.sender.transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount));
        }

        emit ReceiverSpent(_id, _secret);
    }

    function senderRefund(
        bytes32 _id,
        uint256 _amount,
        bytes calldata _secretHash,
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

        require(paymentHash == payments[_id].paymentHash && now >= payments[_id].lockTime);

        payments[_id].state = PaymentState.SenderRefunded;

        if (_tokenAddress == address(0)) {
            msg.sender.transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount));
        }

        emit SenderRefunded(_id);
    }
}