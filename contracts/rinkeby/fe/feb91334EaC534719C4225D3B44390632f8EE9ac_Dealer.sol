/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File contracts/interfaces/IAdmins.sol

pragma solidity >=0.5.0;

interface IAdmins {
    function rootAdmin() external view returns (address);
    function isAdmin(address account) external returns (uint256);

    function changeRootAdmin(address _newRootAdmin) external;
    function addAdmin(address _newAdmin) external;
    function removeAdmin(address _admin) external;
}


// File contracts/abstracts/Admins.sol

pragma solidity 0.8.11;

contract Admins is IAdmins {

    uint256 private constant _NOT_ADMIN = 0;
    uint256 private constant _ADMIN = 1;

    address public override rootAdmin;
    mapping(address => uint256) public override isAdmin;

    event RootAdminChanged(address indexed oldRoot, address indexed newRoot);
    event AdminUpdated(address indexed account, uint256 indexed isAdmin);

    constructor(address _rootAdmin) {
        rootAdmin = _rootAdmin;
    }

    modifier onlyRootAdmin() {
        require(msg.sender == rootAdmin, "must be root admin");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == _ADMIN , "must be admin");
        _;
    }

    function changeRootAdmin(address _newRootAdmin) public onlyRootAdmin {
        address oldRoot = rootAdmin;
        rootAdmin = _newRootAdmin;
        emit RootAdminChanged(oldRoot, rootAdmin);
    }

    function addAdmin(address _admin) public onlyRootAdmin {
        isAdmin[_admin] = _ADMIN;
        emit AdminUpdated(_admin, _ADMIN);
    }

    function removeAdmin(address _admin) public onlyRootAdmin {
        isAdmin[_admin] = _NOT_ADMIN;
        emit AdminUpdated(_admin, _NOT_ADMIN);
    }
}


// File contracts/interfaces/IFeeCollector.sol

pragma solidity >=0.5.0;

interface IFeeCollector {
    function feeClaimer() external returns (address);

    function feeDecimals() external returns (uint256);

    function shifter() external returns (uint256);

    function fee() external returns (uint256);

    function tokenFeeReserves(address token) external returns (uint256);

    function collectFee(
        address token,
        uint256 amount,
        address beneficiary
    ) external;

    function setFeeClaimer(
        address newFeeClaimer
    ) external;

    function setFee(uint256 newFee) external;
}


// File contracts/abstracts/FeeCollector.sol

pragma solidity 0.8.11;


abstract contract FeeCollector is IFeeCollector {
    uint256 public constant override feeDecimals = 4;
    uint256 public constant override shifter = 10**feeDecimals;
    uint256 public override fee = 100; // 4 decimals => 0.01 * 10^4
    address public override feeClaimer;

    mapping(address => uint256) public override tokenFeeReserves;

    event FeeCollected(
        address indexed beneficiary,
        address indexed token,
        uint256 amount
    );
    event FeeClaimerChanged(
        address indexed oldFeeClaimer,
        address indexed newFeeClaimer
    );
    event FeeChanged(uint256 oldFee, uint256 newFee);

    modifier onlyFeeCalimer() {
        require(msg.sender == feeClaimer, "Only fee claimer");
        _;
    }

    constructor(address feeClaimer_) {
        feeClaimer = feeClaimer_;
    }

    function deductFee(address token, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        uint256 collectedFee = (amount * fee) / shifter;
        uint256 output = amount - collectedFee;
        tokenFeeReserves[token] += collectedFee;
        return (output, collectedFee);
    }

    function collectFee(
        address token,
        uint256 amount,
        address beneficiary
    ) external override onlyFeeCalimer {
        uint256 withdrewAmount = amount >= tokenFeeReserves[token]
            ? tokenFeeReserves[token]
            : amount;
        IERC20(token).transfer(beneficiary, withdrewAmount);
        tokenFeeReserves[token] -= withdrewAmount;
        emit FeeCollected(beneficiary, token, withdrewAmount);
    }

    function _setFeeClaimer(address newFeeClaimer) internal {
        address oldFeeCalimer = feeClaimer;
        feeClaimer = newFeeClaimer;
        emit FeeClaimerChanged(oldFeeCalimer, feeClaimer);
    }

    function _setFee(uint256 newFee) internal {
        uint256 oldFee = fee;
        fee = newFee;
        emit FeeChanged(oldFee, fee);
    }
}


// File contracts/Dealer.sol

pragma solidity 0.8.11;



contract Dealer is Admins, FeeCollector {
    uint256 private constant _NEW = 0;
    uint256 private constant _CANCELLED = 1;
    uint256 private constant _PAID = 2;
    uint256 private constant _APPEALED = 3;
    uint256 private constant _FAILED = 4;
    uint256 private constant _COMPLETED = 5;

    uint256 public timeoutPeriod = 5 minutes;

    struct OrderSell {
        uint256 id;
        address tokenAddress;
        address seller;
        address buyer;
        uint256 amount;
        uint256 deadline;
        uint256 status;
    }

    OrderSell[] public orderSells;

    event OrderCreated(
        address indexed seller,
        address indexed buyer,
        address indexed tokenAddress,
        uint256 orderId
    );
    event OrderCancelled(
        address indexed seller,
        address indexed buyer,
        uint256 orderId
    );
    event OrderPayConfirmed(
        address indexed seller,
        address indexed buyer,
        uint256 orderId
    );
    event OrderAppealed(
        address indexed seller,
        address indexed buyer,
        uint256 orderId
    );
    event OrderAppealHandled(
        address indexed seller,
        address indexed buyer,
        uint256 orderId,
        address rightAccount,
        address indexed admin
    );
    event OrderCompleted(
        address indexed seller,
        address indexed buyer,
        uint256 orderId,
        uint256 fee
    );
    event TimeoutPeriodUpdated(
        uint256 oldDeadlineInterval,
        uint256 newTimeoutPeriod
    );

    modifier onlyOrderSeller(uint256 orderId) {
        require(
            orderSells[orderId].seller == msg.sender,
            "must be order seller"
        );
        _;
    }

    modifier onlyOrderBuyer(uint256 orderId) {
        require(orderSells[orderId].buyer == msg.sender, "must be order buyer");
        _;
    }

    modifier onlyOrderBuyerOrSeller(uint256 orderId) {
        require(
            orderSells[orderId].buyer == msg.sender ||
                orderSells[orderId].seller == msg.sender,
            "must be order buyer or seller"
        );
        _;
    }

    modifier onlyNewOrder(uint256 orderId) {
        require(orderSells[orderId].status == _NEW, "only new order");
        _;
    }

    modifier onlyPaidOrder(uint256 orderId) {
        require(orderSells[orderId].status == _PAID, "only paid order");
        _;
    }

    modifier onlyAppealedOrder(uint256 orderId) {
        require(orderSells[orderId].status == _APPEALED, "only appealed order");
        _;
    }

    modifier onlyExpired(uint256 orderId) {
        require(
            block.timestamp > orderSells[orderId].deadline,
            "only expired order"
        );
        _;
    }

    constructor(address _rootAdmin, address _feeClaimer)
        Admins(_rootAdmin)
        FeeCollector(_feeClaimer)
    {}

    function createOrderSell(
        address _tokenAddress,
        uint256 _amount,
        address _buyer
    ) external {
        require(_amount > 0, "Invalid sell amount");
        require(_buyer != address(0), "Invalid buyer");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        uint256 _orderId = orderSells.length;
        OrderSell memory createdOrder = OrderSell({
            id: _orderId,
            tokenAddress: _tokenAddress,
            seller: msg.sender,
            buyer: _buyer,
            amount: _amount,
            deadline: block.timestamp + timeoutPeriod,
            status: _NEW
        });
        orderSells.push(createdOrder);
        emit OrderCreated(msg.sender, _buyer, _tokenAddress, _orderId);
    }

    function cancelOrderSell(uint256 orderId)
        external
        onlyOrderSeller(orderId)
        onlyNewOrder(orderId)
        onlyExpired(orderId)
    {
        OrderSell storage order = orderSells[orderId];
        order.status = _CANCELLED;
        IERC20(order.tokenAddress).transfer(order.seller, order.amount);
        emit OrderCancelled(order.seller, order.buyer, orderId);
    }

    function confirmPayOrderSell(uint256 orderId)
        external
        onlyOrderBuyer(orderId)
        onlyNewOrder(orderId)
    {
        OrderSell storage order = orderSells[orderId];
        order.status = _PAID;
        emit OrderPayConfirmed(order.seller, order.buyer, orderId);
    }

    function appealOrderSell(uint256 orderId)
        external
        onlyOrderBuyerOrSeller(orderId)
        onlyPaidOrder(orderId)
    {
        OrderSell storage order = orderSells[orderId];
        order.status = _APPEALED;
        emit OrderAppealed(order.seller, order.buyer, orderId);
    }

    function handleAppealOrder(uint256 orderId, address rightAccount)
        external
        onlyAdmin
        onlyAppealedOrder(orderId)
    {
        OrderSell storage order = orderSells[orderId];
        require(
            order.seller == rightAccount || order.buyer == rightAccount,
            "Invalid right accounts"
        );

        IERC20(order.tokenAddress).transfer(rightAccount, order.amount);

        order.status = _FAILED;
        emit OrderAppealHandled(
            order.seller,
            order.buyer,
            orderId,
            rightAccount,
            msg.sender
        );
    }

    function releaseToken(uint256 orderId)
        external
        onlyOrderSeller(orderId)
        onlyPaidOrder(orderId)
    {
        OrderSell storage order = orderSells[orderId];

        (uint256 transferredAmount, uint256 collectedFee) = deductFee(
            order.tokenAddress,
            order.amount
        );

        IERC20(order.tokenAddress).transfer(order.buyer, transferredAmount);

        order.status = _COMPLETED;
        emit OrderCompleted(order.seller, order.buyer, orderId, collectedFee);
    }

    function setTimeoutPeriod(uint256 newTimeoutPeriod) external onlyRootAdmin {
        uint256 oldDeadlineInterval = timeoutPeriod;
        timeoutPeriod = newTimeoutPeriod;
        emit TimeoutPeriodUpdated(oldDeadlineInterval, newTimeoutPeriod);
    }

    function setFee(uint256 newFee) external onlyRootAdmin {
        _setFee(newFee);
    }

    function setFeeClaimer(address newFeeClaimer) external onlyRootAdmin {
        _setFeeClaimer(newFeeClaimer);
    }

    function confirmPayTrustedOrder(
        address _tokenAddress,
        address _seller,
        uint256 _amount,
        address _buyer
    ) external onlyAdmin {
        uint256 _orderId = orderSells.length;
        OrderSell memory createdOrder = OrderSell({
            id: _orderId,
            tokenAddress: _tokenAddress,
            seller: _seller,
            buyer: _buyer,
            amount: _amount,
            deadline: block.timestamp,
            status: _COMPLETED
        });
        orderSells.push(createdOrder);

        (uint256 transferredAmount, uint256 collectedFee) = deductFee(
            createdOrder.tokenAddress,
            createdOrder.amount
        );

        IERC20(_tokenAddress).transferFrom(_seller, _buyer, transferredAmount);

        emit OrderCreated(msg.sender, _buyer, _tokenAddress, _orderId);
        emit OrderCompleted(
            createdOrder.seller,
            createdOrder.buyer,
            _orderId,
            collectedFee
        );
    }
}