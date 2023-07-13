// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/Uniswap.sol";
import "./interface/IERC20.sol";

using SafeMath for uint256;

contract Strategy is AutomationCompatibleInterface {
    address public owner;
    AggregatorV3Interface internal dataFeed;
    mapping(address => GridOrder[]) public waitingOrders;
    address[] public traders;

    // 自行部署的usdt
    address usdtTokenAddress =
        address(0x10c166afA4326682ce549fD123004749a249Ebd9);

    // 自行部署的btc
    address btcTokenAddress =
        address(0xF85EcfE2fbb730a03C1093c36b222F7Bb28dB60C);

    // address btcTokenAddress =
    //     address(0x459C848881cfD0B340435701d8d5271369d1911d);

    address btcFeedAddress =
        address(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);

    address private constant UNISWAP_V2_ROUTER =
        0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;

    constructor() {
        owner = msg.sender;
        dataFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );
    }

    struct GridOrder {
        uint orderId; // 订单的唯一标识
        uint orderAmount; // 投资额
        uint256 priceStart; // 最低价格
        uint256 priceEnd; // 最高价格
        uint gridCount; // 网格数量
        uint createTime; // 网格创建时间
        OrderInfo[] deals; // 每个价格的orderInfo
    }

    // Prepare struct to store upkeep order information
    struct UpkeepOrder {
        address trader;
        uint orderIndex;
        uint dealIndex;
        bool removeOrder;
    }

    struct OrderInfo {
        uint256 price;
        uint256 amount; //订单持有的币对数量
    }

    // 用户取消订单，返还剩余的余额
    event CancelOrder(address indexed user, uint orderId, uint256 returnAmount);

    event ReturnFunds(address user, uint orderId, uint256 returnAmount);

    // 用户下单事件
    event PlaceOrder(
        address indexed user,
        uint orderId,
        uint256 priceStart,
        uint256 priceEnd,
        uint gridCount,
        uint256 amount
    );

    // 网格成交事件
    event FillGrid(
        address indexed user,
        uint orderId,
        uint256 price,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * 授权usdt的使用额度, 该方法弃用， 需要前端主动去调用usdt合约的approve方法，不在写在我们的合约内
     * @param orderAmount 下单金额
     */
    function approveUsdtAmount(uint256 orderAmount) public {
        ERC20 usdtToken = ERC20(usdtTokenAddress);
        // Construct calldata for user's call to their token contract
        bytes memory callData = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            orderAmount
        );
        // Make the call using delegatecall
        (bool success, ) = address(usdtToken).delegatecall(callData);
        require(success, "Token approval failed");
    }

    /**
     * 查询授权的额度
     */
    function allowenceUsdtAmount() public view returns (uint256) {
        ERC20 usdtToken = ERC20(usdtTokenAddress);
        return usdtToken.allowance(msg.sender, address(this));
    }

    /**
     * 创建网格订单并返回网格交易订单id
     */
    function placeOrder(
        uint256 priceStart,
        uint256 priceEnd,
        uint256 gridCount,
        uint256 amount
    ) public returns (uint256) {
        require(
            priceStart < priceEnd,
            "priceStart should be smaller than priceEnd"
        );
        // (, int256 lastPrice, , , ) = dataFeed.latestRoundData();
        // require(priceEnd < uint256(lastPrice), "price need small currentPrice");

        ERC20 usdtToken = ERC20(usdtTokenAddress);
        uint256 ownerUsdt = usdtToken.balanceOf(msg.sender);
        require(ownerUsdt > amount, "no enough usdt");

        uint256 grid = priceEnd.sub(priceStart).div(gridCount);
        uint256 singleAmount = amount.div(gridCount.add(1));

        uint256 orderId = block.timestamp;
        GridOrder storage currentOrder = waitingOrders[msg.sender].push();
        currentOrder.createTime = block.timestamp;
        currentOrder.priceStart = priceStart;
        currentOrder.priceEnd = priceEnd;
        currentOrder.orderAmount = amount;
        currentOrder.orderId = orderId;
        currentOrder.gridCount = gridCount;

        for (uint256 i = 0; i <= gridCount; i++) {
            uint256 orderPrice = priceStart.add(i.mul(grid));
            currentOrder.deals.push(OrderInfo(orderPrice, singleAmount));
        }

        // As per the note, use non_standard_IERC20 interface for the non-standard ERC20 token USDT
        // non_standard_IERC20 usdt = non_standard_IERC20(usdtTokenAddress);
        usdtToken.transferFrom(msg.sender, address(this), amount);

        traders.push(msg.sender);

        // Emit an event
        emit PlaceOrder(
            msg.sender,
            orderId,
            priceStart,
            priceEnd,
            gridCount,
            amount
        );

        return orderId;
    }

    function cancelOrder(uint orderId) public {
        GridOrder[] storage orders = waitingOrders[msg.sender];
        uint deletedIndex = orders.length;
        for (uint orderIndex = 0; orderIndex < orders.length; orderIndex++) {
            if (orders[orderIndex].orderId == orderId) {
                deletedIndex = orderIndex;
                break;
            }
        }
        if (deletedIndex == orders.length) {
            return;
        }
        GridOrder storage order = orders[deletedIndex];
        uint returnAmount = 0;
        for (uint dealIndex = 0; dealIndex < order.deals.length; dealIndex++) {
            uint leftAmount = order.deals[dealIndex].amount;
            returnAmount += leftAmount;
        }
        if (returnAmount > 0) {
            ERC20 usdtToken = ERC20(usdtTokenAddress);
            usdtToken.transfer(msg.sender, returnAmount);
            emit ReturnFunds(msg.sender, order.orderId, returnAmount);
        }
        orders[deletedIndex] = orders[orders.length - 1];
        orders.pop();
        emit CancelOrder(msg.sender, order.orderId, returnAmount);
    }

    /// 价格范围：5000 - 6000,  网格数量10格   下单总额500USDT
    /// 当价格到5100的时候， 调用placeOrder 合约内的usdt交换为btc 交换数量为50U
    /// 通过chainlink获取价格， 检查是否满足下单条件。 如果满足下单， 调用uniswap的合约
    // 修改checkUpkeep

    //   function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (, int256 btcPrice, , , ) = dataFeed.latestRoundData();
        uint currentBtcPrice = uint256(btcPrice);

        uint256 count = 0;
        for (uint256 i = 0; i < traders.length; i++) {
            for (uint256 j = 0; j < waitingOrders[traders[i]].length; j++) {
                if (waitingOrders[traders[i]][j].deals.length > 0) {
                    for (
                        uint256 k = 0;
                        k < waitingOrders[traders[i]][j].deals.length;
                        k++
                    ) {
                        if (
                            waitingOrders[traders[i]][j].deals[k].price >
                            currentBtcPrice
                        ) {
                            count += 1;
                        }
                    }
                } else {
                    count += 1;
                }
            }
        }

        UpkeepOrder[] memory upkeepOrders = new UpkeepOrder[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < traders.length; i++) {
            for (uint256 j = 0; j < waitingOrders[traders[i]].length; j++) {
                if (waitingOrders[traders[i]][j].deals.length > 0) {
                    for (
                        uint256 k = 0;
                        k < waitingOrders[traders[i]][j].deals.length;
                        k++
                    ) {
                        if (
                            waitingOrders[traders[i]][j].deals[k].price >
                            currentBtcPrice
                        ) {
                            upkeepOrders[index] = UpkeepOrder(
                                traders[i],
                                j,
                                k,
                                false
                            );
                            index += 1;
                        }
                    }
                } else {
                    upkeepOrders[index] = UpkeepOrder(traders[i], j, 0, true);
                    index += 1;
                }
            }
        }

        performData = abi.encode(upkeepOrders);
        upkeepNeeded = upkeepOrders.length > 0;
        return (upkeepNeeded, performData);
    }

    // 删除元素时不保留默认值
    function removeOrder(address trader, uint orderIndex) private {
        require(
            waitingOrders[trader].length > orderIndex,
            "Invalid order index"
        );

        // 将要删除的元素与最后一个元素交换位置
        waitingOrders[trader][orderIndex] = waitingOrders[trader][
            waitingOrders[trader].length - 1
        ];

        // 缩小数组的大小
        waitingOrders[trader].pop();

        if (waitingOrders[trader].length == 0) {
            // 在此处处理 traders 数组的逻辑，移除相应的元素
            for (uint j = 0; j < traders.length; j++) {
                if (traders[j] == trader) {
                    traders[j] = traders[traders.length - 1];
                    traders.pop();
                    break;
                }
            }
        }
    }

    // 修改performUpkeep
    function performUpkeep(bytes calldata performData) external override {
        UpkeepOrder[] memory upkeepOrders = abi.decode(
            performData,
            (UpkeepOrder[])
        );

        for (uint i = 0; i < upkeepOrders.length; i++) {
            address trader = upkeepOrders[i].trader;
            if (upkeepOrders[i].removeOrder) {
                removeOrder(trader, upkeepOrders[i].orderIndex);
            } else {
                GridOrder storage order = waitingOrders[trader][
                    upkeepOrders[i].orderIndex
                ];
                OrderInfo storage deal = order.deals[upkeepOrders[i].dealIndex];

                swap(
                    trader,
                    order.orderId,
                    deal.price,
                    deal.amount,
                    usdtTokenAddress,
                    btcTokenAddress,
                    deal.amount,
                    trader
                );

                order.deals[upkeepOrders[i].dealIndex] = order.deals[
                    order.deals.length - 1
                ];
                order.deals.pop();
            }
        }
    }

    function lastBtcPrice() public view returns (int256) {
        (, int256 btcPrice, , , ) = dataFeed.latestRoundData();
        return btcPrice;
    }

    function userUsdtBalance() public view returns (uint256) {
        ERC20 usdtToken = ERC20(usdtTokenAddress);
        return usdtToken.balanceOf(msg.sender);
    }

    function queryUserRunningOrders() public view returns (GridOrder[] memory) {
        return waitingOrders[msg.sender];
    }

    function queryDeals(
        address trader,
        uint orderId
    ) public view returns (OrderInfo[] memory) {
        require(
            orderId < waitingOrders[trader].length,
            "orderId is out of bounds"
        );
        return waitingOrders[trader][orderId].deals;
    }

    /**
     * https://solidity-by-example.org/defi/uniswap-v2/
     * @param _tokenIn 是我们要兑换的代币的地址。
     * @param _tokenOut 是我们想从这次交易中获得的代币的地址。
     * @param _amountIn 是我们要交易的代币的数量。
     * @param _to 交易兑换出的代币发送到这个地址。
     */
    function swap(
        address trader,
        uint orderId,
        uint256 price,
        uint256 amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) public {
        // 这一步省略，因为我们的合约里 已经有用户的钱了
        // transfer the amount in tokens from msg.sender to this contract
        // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        //计算大约获得多少代币
        uint256[] memory amountsExpected = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amountsExpected[0],
            (amountsExpected[1] * 950) / 1000, // accpeting a slippage of 5%
            path,
            _to,
            block.timestamp
        );
        emit FillGrid(trader, orderId, price, amount, amountsExpected[1]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface non_standard_IERC20 {
  function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external ;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amounswapExactTokensForTokenstIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}