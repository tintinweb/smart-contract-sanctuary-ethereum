// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// @Author: Alireza Haghshenas github: alireza1691


interface IMain {


// event Deposit(address indexed from, uint256 indexed amount, address indexed tokenAddress);
// event Whithdraw(address indexed to, uint256 indexed amount, address indexed tokenAddress);

function updateUserBalances (uint256 amount, address userAddress, address tokenAddress, bool isSum) external;
function getUserBalances (address userAddress, address tokenAddress) external returns(uint256);
// function depositToken (uint256 amount, address tokenContractAddress) external;
// function withdrawToken (uint256 amount, address tokenContractAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// @Author: Alireza Haghshenas github: alireza1691

import "./IERC20.sol";
// import "./Main.sol";
import "./IMain.sol";



error Pair__Insufficient_Balance();
error Pair__IndexNotFound();
error Pair__OrderNotAvailable();
error Pair__LengthsNotEqual();

contract Pair {
    event NewOrder(
        uint256 amount,
        uint256 price,
        address orderOwner,
        bool isBuy
    );
    event RemoveOrderByOwner(
        uint256 amount,
        uint256 price,
        address orderOwner,
        bool isBuy
    );
    event OrderSucceed(
        address indexed firstTokenOwner,
        uint256 firstTokenAmount,
        address indexed secondTokenOwner,
        uint256 secondTokenAmount
    );

    // IMain Main_Interface = IMain(token2Address);
    IMain Main_Interface;
    // Main main;
    address token1Address;
    address token2Address;
    string private name;

    constructor(
        string memory pairName,
        address firstTokenAdress,
        address secondTokenAddress,
        address mainContractAddress
    ) {
        token1Address = firstTokenAdress;
        token2Address = secondTokenAddress;
        Main_Interface = IMain(mainContractAddress);
        name = pairName;
    }

    struct order {
        uint256 orderAmount;
        uint256 price;
        address userAddress;
    }
    
    // This mapping stores orders (price of order => order is buy or sell => array of orders)
    mapping(uint256 => mapping(bool => order[])) public ordersInThisPrice;


    // Get name of the contract that shows this contracts belongs to which pair
    function getName() external view returns(string memory) {
        return name;
    }

    // External verion of new order function which calls by user and puts new order
    // There is another _newOrder function but that one is internal
    function newOrder(uint256 price, uint256 amount, bool isBuy) external {

        //Check if user has enough balance to enter this order
        if (amount > Main_Interface.getUserBalances(msg.sender,(isBuy ? token1Address : token2Address))) {
            revert Pair__Insufficient_Balance();
        }
        // Decrease balance of user in main contract as much as order amount
        Main_Interface.updateUserBalances(
            amount,
            msg.sender,
            isBuy ? token1Address : token2Address,
            false
        );
        // Push order in mapping
        ordersInThisPrice[price][isBuy].push(
            order(amount, price, msg.sender)
        );
        // Emit the event
        emit NewOrder(amount, price, msg.sender, isBuy);
    }

    // Cancel order if still not purchased
    function cancelOrder(bool isBuy, uint256 index, uint256 price) external {
        address userAddress = ordersInThisPrice[price][true][index].userAddress;
        uint256 orderAmount = ordersInThisPrice[price][true][index].orderAmount;
        // We will make sure order belongs to msg.sender and also value of order is bigger than zero
        if (msg.sender == userAddress && orderAmount > 0) {
            delete (ordersInThisPrice[price][true][index]);
            // After delete order increase balance of user as much as amount of order
            Main_Interface.updateUserBalances(
                orderAmount,
                userAddress,
                token1Address,
                true
            );
        emit RemoveOrderByOwner(orderAmount, price, userAddress, isBuy);
        } else {
            revert Pair__OrderNotAvailable();
        }
        
    }

    // This order will purchase equivalent of entered amount 
    // 'indexes' & 'prices' parameters are not entered directly by user, user just calls BeforePurchaseAmountNow then depends on existed orders(we will using events to get available orders) and entered other inputs automatically
    function purchaseThisAmountNow(
        uint256 amount,
        uint256[] memory indexes,
        uint256[] memory prices,
        bool isBuy
    ) external {
        if (
            amount >
            Main_Interface.getUserBalances(
                msg.sender,
                (isBuy? token1Address : token2Address)
            )
        ) {
            revert Pair__Insufficient_Balance();
        }
        uint256 spendedAmounts;
        uint256 sumPurchasedAmounts;
        for (uint i = 0; i < indexes.length - 1; i++) {
            if (ordersInThisPrice[prices[i]][isBuy][indexes[i]].orderAmount > 0) {
                (uint256 purchasedAmount, uint256 spendedAmount) = _purchaseThisOrder(
                prices[i],
                indexes[i],
                isBuy,
                msg.sender
            );
            spendedAmounts += spendedAmount;
            sumPurchasedAmounts += purchasedAmount;   
            } 
        }
        uint256 amountOut = _purchaseSomeAmountOfOrder(
            indexes[indexes.length - 1],
            prices[prices.length - 1],
            amount - spendedAmounts,
            isBuy,
            msg.sender
        );
        sumPurchasedAmounts += amountOut;
        Main_Interface.updateUserBalances(
            sumPurchasedAmounts,
            msg.sender,
            token2Address,
            true
        );
    }

    function beforePurchase () internal {
        
    }
    // Purchase if all of enterd amount is exist in entered price
    function purchaseAllAmountInEnteredPrice(
        uint256 amountIn,
        uint256 price,
        bool isBuy
    ) external returns (uint256) {
        Main_Interface.updateUserBalances(amountIn, msg.sender, (isBuy ? token1Address : token2Address), false);
        uint256 sumAmounts;
        uint256 spendedAmounts;
        (uint256 indexFrom/*, bool isExist*/) = _findFirstIndexAboveZero(
            price,
            isBuy
        );
        for (
            uint i = indexFrom;
            i < ordersInThisPrice[price][!isBuy].length;
            i++
        ) {
            if (
                ordersInThisPrice[price][!isBuy][i].orderAmount + sumAmounts <=
                amountIn / price
            ) {
                (uint256 purchasedAmount ,uint256 spendedAmount) = _purchaseThisOrder(
                    price,
                    i,
                    isBuy,
                    msg.sender
                );
                sumAmounts += purchasedAmount;
                spendedAmounts +=spendedAmount;
            } else {
                uint256 amountOut = _purchaseSomeAmountOfOrder(
                    i,
                    price,
                    amountIn - spendedAmounts,
                    isBuy,
                    msg.sender
                );
                sumAmounts += amountOut;
                break;
            }
        }
        // address tokenAddress = isBuy ? token2Address : token1Address;
        Main_Interface.updateUserBalances(
            sumAmounts,
            msg.sender,
            (isBuy ? token2Address : token1Address),
            // tokenAddress,
            true
        );
        return sumAmounts;
    }

    // Purchase exist amount in entered price, then put order for the rest of amount
    function purchaseInEnterdAmountThenPutNewOrder(
        uint256 amountIn,
        uint256 price,
        bool isBuy
    ) external {
        Main_Interface.updateUserBalances(amountIn, msg.sender, isBuy ? token1Address : token2Address, false);
        uint256 sumAmounts;
        uint256 spendedAmounts;
        uint index = _findFirstIndexAboveZero(price, isBuy);
        for (uint i = index; i < ordersInThisPrice[price][!isBuy].length; i++) {
            if (
                sumAmounts + ordersInThisPrice[price][!isBuy][i].orderAmount <=
                (isBuy ? (amountIn / price) : ( amountIn *price))
            ) {
                (uint256 purchasedAmount, uint256 spendedAmount) = _purchaseThisOrder(
                    price,
                    i,
                    isBuy,
                    msg.sender
                );
                sumAmounts += purchasedAmount;
                spendedAmounts += spendedAmount;
            }
        }
        Main_Interface.updateUserBalances(
            sumAmounts,
            msg.sender,
            isBuy ? token2Address : token1Address,
            true
        );
        _newOrder(
            price,
            (amountIn - spendedAmounts),
            msg.sender,
            isBuy
        );
    }

    // ***** Private functions which calls only in the external functions

    // This function purchase an entered amount from the order
    // Note that entered amount is the amount which we want tp purchase from the order, when we want to update user balance,we must consider price
    // For example if order is sell order calls by someone who want to buy tokens, buyer for purchase X amount of token 2, must spend X*price, So when we purchase some amount of sell order, balance of sell orders owner must increased amount of order * price and conversely.
    function _purchaseSomeAmountOfOrder(
        uint256 index,
        uint256 price,
        uint256 amountIn,
        bool isBuy,
        address orderSender
    ) private returns(uint256 amountOut){
            amountOut = (isBuy ? amountIn/price : amountIn * price);
            ordersInThisPrice[price][!isBuy][index].orderAmount -= amountOut;
            Main_Interface.updateUserBalances(
                amountIn,
                ordersInThisPrice[price][!isBuy][index].userAddress,
                (isBuy ? token1Address : token2Address),
                true
            );
        emit OrderSucceed(
            orderSender,
            amountIn,
            ordersInThisPrice[price][!isBuy][index].userAddress,
            amountOut
        );
    }

    // This function buys a whole amount of one order, update balance of the user who owned this order, then delete order an retern value to update balance of user who purchased this order
    function _purchaseThisOrder(
        uint256 price,
        uint256 index,
        bool isBuy,
        address orderSender
    ) private returns (uint256 purchasedAmount, uint256 spendedAmount) {
            purchasedAmount = ordersInThisPrice[price][!isBuy][index].orderAmount;
            spendedAmount = (isBuy ? purchasedAmount * price : purchasedAmount / price);
            Main_Interface.updateUserBalances(
                spendedAmount,
                ordersInThisPrice[price][!isBuy][index].userAddress,
                (isBuy ? token1Address : token2Address),
                true
            );
            
            delete ordersInThisPrice[price][!isBuy][index];
            emit OrderSucceed(
                orderSender,
                spendedAmount,
                ordersInThisPrice[price][!isBuy][index].userAddress,
                purchasedAmount
            );
    
    }

    // Put new order private this function will use when all amount of order is not availabe and we calling this function to put new order for remained amount
    function _newOrder(
        uint256 price,
        uint256 amount,
        address orderBelongTo,
        bool isBuy
    ) private {
            ordersInThisPrice[price][isBuy].push(order(amount, price, msg.sender));
        
        emit NewOrder(amount, price, orderBelongTo, isBuy);
    }

    // Since when all amount of an order purchased, the order is removed, then the first elements of array in mapping may have been used before and return zero value, So this function return the first element which is not used before ,and can keep going with the rest of orders.
    function _findFirstIndexAboveZero(
        uint256 price,
        bool isBuy
    ) internal view returns (uint256 index) {
        index = 0;
        for (uint i = 0; i < ordersInThisPrice[price][!isBuy].length; i++) {
            if (ordersInThisPrice[price][!isBuy][i].orderAmount > 0) { 
                return index;
            }
        }

 
    }

    // ***** Getter functions:
    function getOrders(
        uint256 price,
        bool isBuy
    ) external view returns (order[] memory) {
        if (isBuy) {
            return ordersInThisPrice[price][true];
        } else {
            return ordersInThisPrice[price][false];
        }
    }


}