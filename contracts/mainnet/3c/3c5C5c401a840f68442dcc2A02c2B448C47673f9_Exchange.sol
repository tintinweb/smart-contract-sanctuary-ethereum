//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Token.sol";

error Exchange__InsufficientValue();
error Exchange__InsufficientBalance();
error Exchange__InsufficientDeposit();
error Exchange__OrderNotFound();
error Exchange__OrderWasFilled();
error Exchange__OrderWasCancelled();
error Exchange__NotOwner();

contract Exchange {
    struct Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    uint256 public orderCount;
    address public feeAccount;
    uint256 public feePercent;
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    event Deposit(address token, address user, uint256 amount, uint256 balance);

    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event OrderMade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event OrderCancelled(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address creator,
        uint256 timestamp
    );

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    function fundExchange(address _token, uint256 _amount) public {
        Token(_token).transferFrom(msg.sender, address(this), _amount);
        tokens[_token][address(this)] += _amount;
    }

    function buyToken(address _token, uint256 _amount) public payable {
        if (msg.value < _amount) {
            revert Exchange__InsufficientValue();
        }
        Token(_token).transfer(msg.sender, _amount);
        tokens[_token][address(this)] -= _amount;
    }

    function sellToken(address _token, uint256 _amount) public payable {
        if (address(this).balance < _amount) {
            revert Exchange__InsufficientBalance();
        }
        Token(_token).transferFrom(msg.sender, address(this), _amount);
        tokens[_token][address(this)] += _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
    }

    function depositToken(address _token, uint256 _amount) public {
        Token(_token).transferFrom(msg.sender, address(this), _amount);
        tokens[_token][msg.sender] += _amount;
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        Token(_token).transfer(msg.sender, _amount);
        tokens[_token][msg.sender] -= _amount;
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function makeOrder(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) public {
        if (tokens[_tokenGive][msg.sender] < _amountGive) {
            revert Exchange__InsufficientDeposit();
        }
        orderCount++;
        orders[orderCount] = Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
        emit OrderMade(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _id) public {
        Order memory order = orders[_id];
        if (order.id != _id) {
            revert Exchange__OrderNotFound();
        }
        if (order.user != msg.sender) {
            revert Exchange__NotOwner();
        }
        orderCancelled[_id] = true;
        emit OrderCancelled(
            order.id,
            order.user,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            block.timestamp
        );
    }

    function fillOrder(uint256 _id) public {
        Order memory order = orders[_id];
        if (order.id != _id) {
            revert Exchange__OrderNotFound();
        }
        if (orderCancelled[_id]) {
            revert Exchange__OrderWasCancelled();
        }
        if (orderFilled[_id]) {
            revert Exchange__OrderWasFilled();
        }
        _trade(
            order.id,
            order.user,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive
        );
        orderFilled[_id] = true;
    }

    function _trade(
        uint256 _id,
        address _user,
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) internal {
        uint256 feeAmount = (_amountGet * feePercent) / 100;
        tokens[_tokenGet][msg.sender] -= (_amountGet + feeAmount);
        tokens[_tokenGet][_user] += _amountGet;
        tokens[_tokenGet][feeAccount] += feeAmount;

        tokens[_tokenGive][msg.sender] += _amountGive;
        tokens[_tokenGive][_user] -= _amountGive;

        emit Trade(
            _id,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            _user,
            block.timestamp
        );
    }
}