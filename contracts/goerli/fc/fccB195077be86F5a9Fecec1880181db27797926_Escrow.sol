/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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


contract Escrow is ReentrancyGuard {
    address public escAcc;
    address public treasury;
    address public arbitrater;
    uint256 public escFee;
    uint256 public constant MaxEscFee = 1000;
    uint256 public totalItems = 0;
    // 1 min
    uint256 private min = 60;
    uint256 public ETHByUSDT = 1500;

    IERC20 public SET;
    IERC20 public USDT;

    mapping(uint256 => ItemStruct) private items;
    mapping(address => uint256[]) private itemsOf;
    mapping(address => uint256[]) private participateOf;
    mapping(uint256 => address) public ownerOf;

    enum Status {
        OPEN,
        CONFIRMING,
        CANCELING,
        CONFIRMED,
        CANCELLED,
        EXPIRED
    }

    struct ItemStruct {
        uint256 itemId;
        uint256 uid;
        bool isNativeToken;
        bool isSetForFee;
        uint256 amount;
        uint256 expired;
        address sender;
        address receiver;
        Status status;
        Status senderStatus;
        Status receiverStatus;
        uint256 fee;
    }

    event Action(
        uint256 itemId,
        uint256 uid,
        string actionType,
        address indexed executor
    );

    event Opened(uint256 itemId, uint256 uid, uint256 fee, uint256 expired);

    constructor(
        address _treasury,
        address _arbitrater,
        address _usdt,
        address _set,
        uint256 _escFee
    ) {
        escAcc = msg.sender;
        treasury = _treasury;
        arbitrater = _arbitrater;
        escFee = _escFee;
        SET = IERC20(_set);
        USDT = IERC20(_usdt);
    }

    function createItem(
        address receiver,
        uint256 amount,
        bool isNativeToken,
        bool isSetForFee,
        uint256 uid,
        uint256 expired
    ) external payable returns (bool) {
        require(uid > 0, "Escrow: uid cannot be empty");
        require(expired > 0, "Escrow: expired days cannot be empty");
        uint256 fee = 0;
        if (isNativeToken) {
            require(msg.value >= amount, "Escrow: eth insufficient for pay");
            fee = (amount * ETHByUSDT * escFee) / MaxEscFee;
        } else {
            fee = (amount * escFee) / MaxEscFee;
        }
        uint256 itemId = totalItems++;
        ItemStruct storage item = items[itemId];

        item.itemId = itemId;
        item.uid = uid;
        item.amount = amount;
        item.expired = block.timestamp + min * expired;
        item.sender = msg.sender;
        item.receiver = receiver;
        item.isNativeToken = isNativeToken;
        item.fee = fee;
        item.status = Status.OPEN;
        item.senderStatus = Status.OPEN;
        item.receiverStatus = Status.OPEN;
        item.isSetForFee = isSetForFee;

        itemsOf[msg.sender].push(itemId);
        participateOf[receiver].push(itemId);
        ownerOf[itemId] = msg.sender;

        if (!isNativeToken) {
            USDT.transferFrom(msg.sender, address(this), amount);
        }
        if (isSetForFee) {
            SET.transferFrom(msg.sender, address(this), fee);
        } else {
            USDT.transferFrom(msg.sender, address(this), fee);
        }

        emit Action(itemId, uid, "CREATED", msg.sender);
        emit Opened(itemId, uid, item.fee, item.expired);
        return true;
    }

    function confirm(uint256 itemId) external returns (bool) {
        ItemStruct storage item = items[itemId];
        address executor = msg.sender;
        require(
            item.sender == executor || item.receiver == executor,
            "No operation permission"
        );
        require(item.expired > block.timestamp, "Escrow: item expired");
        require(item.status < Status.CONFIRMED, "Escrow: forbbiden");

        if (item.sender == executor) {
            item.senderStatus = Status.CONFIRMED;
        } else {
            item.receiverStatus = Status.CONFIRMED;
        }
        if (
            item.senderStatus == Status.CONFIRMED &&
            item.receiverStatus == Status.CONFIRMED
        ) {
            item.status = Status.CONFIRMED;
            payItem(itemId);
        } else {
            item.status = Status.CONFIRMING;
        }
        emit Action(itemId, item.uid, "CONFIRMED", msg.sender);
        return true;
    }

    function cancel(uint256 itemId) external returns (bool) {
        ItemStruct storage item = items[itemId];
        address executor = msg.sender;
        require(
            item.sender == executor || item.receiver == executor,
            "No operation permission"
        );
        require(item.expired > block.timestamp, "Escrow: item expired");
        require(item.status < Status.CONFIRMED, "Escrow: forbbiden");

        if (item.sender == executor) {
            item.senderStatus = Status.CANCELLED;
        } else {
            item.receiverStatus = Status.CANCELLED;
        }
        if (
            item.senderStatus == Status.CANCELLED &&
            item.receiverStatus == Status.CANCELLED
        ) {
            item.status = Status.CANCELLED;
            refundItem(itemId);
        } else {
            item.status = Status.CANCELING;
        }
        emit Action(itemId, item.uid, "CANCELLED", msg.sender);
        return true;
    }

    function payItem(uint256 itemId) internal {
        ItemStruct storage item = items[itemId];
        require(item.status == Status.CONFIRMED);
        if (item.isNativeToken) {
            payTo(item.receiver, item.amount);
        } else {
            USDT.transfer(item.receiver, item.amount);
        }
        if (item.isSetForFee) {
            SET.transfer(treasury, item.fee);
        } else {
            USDT.transfer(treasury, item.fee);
        }
    }

    function refundItem(uint256 itemId) internal {
        ItemStruct storage item = items[itemId];
        require(item.status == Status.CANCELLED);
        if (item.isNativeToken) {
            payTo(item.sender, item.amount);
        } else {
            USDT.transfer(item.sender, item.amount);
        }
        uint256 half = item.fee / 2;
        if (item.isSetForFee) {
            SET.transfer(treasury, half);
            SET.transfer(item.sender, half);
        } else {
            USDT.transfer(treasury, half);
            USDT.transfer(item.sender, half);
        }
    }

    function checkExpired() external returns (bool) {
        require(msg.sender == escAcc, "Escrow: Only Escrow allowed");

        for (uint256 i = 0; i < totalItems; i++) {
            ItemStruct storage item = items[i];
            if (
                item.status != Status.EXPIRED && item.expired < block.timestamp
            ) {
                item.status = Status.EXPIRED;
                if (item.isSetForFee) {
                    SET.transfer(treasury, item.fee);
                } else {
                    USDT.transfer(treasury, item.fee);
                }

                if (item.isNativeToken) {
                    payTo(arbitrater, item.amount);
                } else {
                    USDT.transfer(arbitrater, item.amount);
                }
                emit Action(item.itemId, item.uid, "EXPIRED", msg.sender);
            }
        }
        return true;
    }

    function payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }

    function getItems() external view returns (ItemStruct[] memory props) {
        props = new ItemStruct[](totalItems);

        for (uint256 i = 0; i < totalItems; i++) {
            props[i] = items[i];
        }
    }

    function getItem(uint256 itemId) external view returns (ItemStruct memory) {
        return items[itemId];
    }

    function myItems() external view returns (ItemStruct[] memory) {
        uint256[] memory ids = itemsOf[msg.sender];
        ItemStruct[] memory arr = new ItemStruct[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            arr[i] = items[i];
        }
        return arr;
    }

    function participateItems() external view returns (ItemStruct[] memory) {
        uint256[] memory ids = participateOf[msg.sender];
        ItemStruct[] memory arr = new ItemStruct[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            arr[i] = items[i];
        }
        return arr;
    }
}