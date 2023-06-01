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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/ISchwapMarket.sol";
import "./interfaces/MatchingEvents.sol";
import "./SimpleMarket.sol";
import "./libraries/SchwapLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/PriceOracleLike.sol";

contract SchwapMarket is ISchwapMarket, MatchingEvents, SimpleMarket {
    uint epochStart = 1685980800;

    uint[289] private epochs = [
        0,
        25000, 25000, 25000, 25000,
        18750, 18750, 18750, 18750,
        18750, 18750, 18750, 18750,
        18750, 18750, 18750, 18750,
        18750, 18750, 18750, 18750,
        18750, 18750, 18750, 18750,
        18750, 18750, 18750, 18750,
        12500, 12500, 12500, 12500,
        12500, 12500, 12500, 12500,
        12500, 12500, 12500, 12500,
        12500, 12500, 12500, 12500,
        12500, 12500, 12500, 12500,
        12500, 12500, 12500, 12500,
        8750, 8750, 8750, 8750,
        8750, 8750, 8750, 8750,
        8750, 8750, 8750, 8750,
        8750, 8750, 8750, 8750,
        8750, 8750, 8750, 8750,
        8750, 8750, 8750, 8750,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        7500, 7500, 7500, 7500,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        5000, 5000, 5000, 5000,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        4375, 4375, 4375, 4375,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        3750, 3750, 3750, 3750,
        2500, 2500, 2500, 2500,
        2500, 2500, 2500, 2500,
        2500, 2500, 2500, 2500,
        2500, 2500, 2500, 2500
    ];

    struct sortInfo {
        uint next;  //points to id of next higher offer
        uint prev;  //points to id of previous lower offer
        uint delb;  //the blocknumber where this entry was marked for delete
    }
    mapping(uint => sortInfo) public _rank;                     //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint)) public _best;  //id of the highest offer for a token pair
    mapping(address => mapping(address => uint)) public _span;  //number of offers stored for token pair in sorted orderbook
    mapping(address => uint) public _dust;                      //minimum sell amount for a token to avoid dust offers
    mapping(uint => uint) public _near;         //next unsorted offer id
    uint _head;                                 //first unsorted offer id

    // dust management
    address public dustToken;
    uint256 public dustLimit;
    address public priceOracle;

    //mapping(address => mapping(address => address)) public _pair;
    mapping(address => mapping(uint => uint)) public _pairVolume;
    mapping(address => mapping(address => mapping(uint => uint))) public _userVolume;

    constructor(address _dustToken, uint _dustLimit, address _priceOracle, address _vesch) {
        dustToken = _dustToken;
        dustLimit = _dustLimit;
        priceOracle = _priceOracle;
        vesch = IveSCH(_vesch);

        _setMinSell(IERC20(dustToken), dustLimit);
    }

    // If owner, can cancel an offer
    // If dust, anyone can cancel an offer
    modifier can_cancel(uint id) override {
        require(isActive(id), "Offer was deleted or taken, or never existed.");

        require(
            msg.sender == getOwner(id) || offers[id].pay_amt < _dust[address(offers[id].pay_gem)],
            "Offer can not be cancelled because user is not owner nor a dust one."
        );
        _;
    }

    function getCurrentEpoch()
        public
        view
        returns (uint)
    {
        if (block.timestamp >= epochStart) {
            return ((block.timestamp - epochStart) / 604800) + 1;
        } else {
            return 0;
        }
    }

    function getEmissionsCurrent()
        public
        view
        returns (uint)
    {
        uint _epoch = getCurrentEpoch();
        if (_epoch < 289) {
            return epochs[_epoch] * (10 ** 17);
        } else {
            return 0;
        }
    }

    function getEmissions(
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        if (_epoch < 289) {
            return epochs[_epoch] * (10 ** 17);
        } else {
            return 0;
        }
    }

    function getPairVolume(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _pairVolume[_pair][_epoch];
    }

    function getUserVolume(
        address _pair,
        address _user,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _userVolume[_pair][_user][_epoch];
    }

    // ---- Public entrypoints ---- //

    function make(
        IERC20    pay_gem,
        IERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        override
        returns (bytes32)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    function take(bytes32 id, uint128 maxTakeAmount) public override {
        require(buy(uint256(id), maxTakeAmount));
    }

    function kill(bytes32 id) public override {
        require(cancel(uint256(id)));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    //
    //     * creates new offer without putting it in
    //       the sorted list.
    //     * available to authorized contracts only!
    //     * keepers should call insert(id,pos)
    //       to put offer in the sorted list.
    //
    function offer(
        uint pay_amt,    //maker (ask) sell how much
        IERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //taker (ask) buy how much
        IERC20 buy_gem    //taker (ask) buy which token
    )
        public
        override
        returns (uint)
    {
        require(!locked, "Reentrancy attempt");
        return _offeru(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint pay_amt,    //maker (ask) sell how much
        IERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //maker (ask) buy how much
        IERC20 buy_gem,   //maker (ask) buy which token
        uint pos         //position to insert offer, 0 should be used if unknown
    )
        public
        can_offer
        returns (uint)
    {
        return offer(pay_amt, pay_gem, buy_amt, buy_gem, pos, true);
    }

    function offer(
        uint pay_amt,    //maker (ask) sell how much
        IERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //maker (ask) buy how much
        IERC20 buy_gem,   //maker (ask) buy which token
        uint pos,        //position to insert offer, 0 should be used if unknown
        bool rounding    //match "close enough" orders?
    )
        public
        can_offer
        returns (uint)
    {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt);

        return _matcho(pay_amt, pay_gem, buy_amt, buy_gem, pos, rounding);
    }

    //Transfers funds from caller to offer maker, and from market to caller.
    function buy(uint id, uint amount)
        public
        can_buy(id)
        override
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        return _buys(id, amount);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        override
        returns (bool success)
    {
        require(!locked, "Reentrancy attempt");
        if (isOfferSorted(id)) {
            require(_unsort(id));
        } else {
            require(_hide(id));
        }
        return super.cancel(id);    //delete the offer.
    }

    //insert offer into the sorted list
    //keepers need to use this function
    function insert(
        uint id,   //maker (ask) id
        uint pos   //position to insert into
    )
        public
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        require(!isOfferSorted(id));    //make sure offers[id] is not yet sorted
        require(isActive(id));          //make sure offers[id] is active

        _hide(id);                      //remove offer from unsorted offers list
        _sort(id, pos);                 //put offer into the sorted offers list
        emit LogInsert(msg.sender, id);
        return true;
    }

    //deletes _rank [id]
    //  Function should be called by keepers.
    function del_rank(uint id)
        public
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        require(!isActive(id) && _rank[id].delb != 0 && _rank[id].delb < block.number - 10);
        delete _rank[id];
        emit LogDelete(msg.sender, id);
        return true;
    }

    //set the minimum sell amount for a token. Uses Uniswap as a price oracle.
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        IERC20 pay_gem     //token to assign minimum sell amount to
    )
        public
    {
        require(msg.sender == tx.origin, "No indirect calls please");
        require(address(pay_gem) != dustToken, "Can't set dust for the dustToken");
        
        uint256 dust = PriceOracleLike(priceOracle).getPriceFor(dustToken, address(pay_gem), dustLimit);

        _setMinSell(pay_gem, dust);
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        IERC20 pay_gem      //token for which minimum sell amount is queried
    )
        public
        view
        returns (uint)
    {
        return _dust[address(pay_gem)];
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(IERC20 sell_gem, IERC20 buy_gem) public view returns(uint) {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint id) public view returns(uint) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint id) public view returns(uint) {

        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(IERC20 sell_gem, IERC20 buy_gem) public view returns(uint) {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() public view returns(uint) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint id) public view returns(uint) {
        return _near[id];
    }

    function isOfferSorted(uint id) public view returns(bool) {
        return _rank[id].next != 0
               || _rank[id].prev != 0
               || _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] == id;
    }

    function sellAllAmount(IERC20 pay_gem, uint pay_amt, IERC20 buy_gem, uint min_fill_amount)
        public
        returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (pay_amt > 0) {                           //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0);                      //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (pay_amt * 1 ether < wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {                       //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt);          //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt);            //Decrease amount to sell
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else { // if lower
                uint256 baux = rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9;
                fill_amt = add(fill_amt, baux);         //Add amount bought to acumulator
                take(bytes32(offerId), uint128(baux));  //We take the portion of the offer that we need
                pay_amt = 0;                            //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount);
    }

    function buyAllAmount(IERC20 buy_gem, uint buy_amt, IERC20 pay_gem, uint max_fill_amount)
        public
        returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (buy_amt > 0) {                           //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0);

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (buy_amt * 1 ether < wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {                       //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt);          //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt);            //Decrease amount to buy
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else {                                                        //if lower
                fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add amount sold to acumulator
                take(bytes32(offerId), uint128(buy_amt));                   //We take the portion of the offer that we need
                buy_amt = 0;                                                //All amount is bought
            }
        }
        require(fill_amt <= max_fill_amount);
    }

    function getBuyAmount(IERC20 buy_gem, IERC20 pay_gem, uint pay_amt) public view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt);  //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt);    //Decrease amount to pay
            if (pay_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0);                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9); //Add proportional amount of last offer to buy accumulator
    }

    function getPayAmount(IERC20 pay_gem, IERC20 buy_gem, uint buy_amt) public view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt);  //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt);    //Decrease amount to buy
            if (buy_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0);                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _setMinSell(
        IERC20 pay_gem,     //token to assign minimum sell amount to
        uint256 dust
    )
        internal
    {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
    }

    function _buys(uint id, uint amount)
        internal
        returns (bool)
    {
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            }else{
                _hide(id);
            }
        }
        require(super.buy(id, amount));
        // If offer has become dust during buy, we cancel it
        if (isActive(id) && offers[id].pay_amt < _dust[address(offers[id].pay_gem)]) {
            cancel(id);
        }
        address _pair = SchwapLibrary.getPair(address(offers[id].pay_gem), address(offers[id].buy_gem));
        uint _epoch = getCurrentEpoch();
        uint _volume = mul(amount, (mul(amount, offers[id].buy_amt) / offers[id].pay_amt));
        _pairVolume[_pair][_epoch] += _volume;
        _userVolume[_pair][msg.sender][_epoch] += _volume;
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint id)
        internal
        view
        returns (uint)
    {
        require( id > 0 );

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint top = _best[pay_gem][buy_gem];
        uint old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint id, uint pos)
        internal
        view
        returns (uint)
    {
        require(id > 0);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);

        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if(_isPricedLtOrEq(id, pos)) {
                uint old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

            // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint low,   //lower priced offer's id
        uint high   //higher priced offer's id
    )
        internal
        view
        returns (bool)
    {
        return mul(offers[low].buy_amt, offers[high].pay_amt)
          >= mul(offers[high].buy_amt, offers[low].pay_amt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint t_pay_amt,    //taker sell how much
        IERC20 t_pay_gem,   //taker sell which token
        uint t_buy_amt,    //taker buy how much
        IERC20 t_buy_gem,   //taker buy which token
        uint pos,          //position id
        bool rounding      //match "close enough" orders?
    )
        internal
        returns (uint id)
    {
        uint best_maker_id;    //highest maker id
        uint t_buy_amt_old;    //taker buy how much saved
        uint m_buy_amt;        //maker offer wants to buy this much token
        uint m_pay_amt;        //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (mul(m_buy_amt, t_buy_amt) > mul(t_pay_amt, m_pay_amt) +
                (rounding ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt : 0))
            {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (t_buy_amt > 0 && t_pay_amt > 0 && t_pay_amt >= _dust[address(t_pay_gem)]) {
            //new offer should be created
            id = super.offer(t_pay_amt, t_pay_gem, t_buy_amt, t_buy_gem);
            //insert offer into the sorted list
            _sort(id, pos);
        }
    }

    // Make a new offer without putting it in the sorted list.
    // Takes funds from the caller into market escrow.
    // ****Available to authorized contracts only!**********
    // Keepers should call insert(id,pos) to put offer in the sorted list.
    function _offeru(
        uint pay_amt,      //maker (ask) sell how much
        IERC20 pay_gem,     //maker (ask) sell which token
        uint buy_amt,      //maker (ask) buy how much
        IERC20 buy_gem      //maker (ask) buy which token
    )
        internal
        returns (uint id)
    {
        require(_dust[address(pay_gem)] <= pay_amt);
        id = super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
        _near[id] = _head;
        _head = id;
        emit LogUnsortedOffer(id);
    }

    //put offer into the sorted list
    function _sort(
        uint id,    //maker (ask) id
        uint pos    //position to insert into
    )
        internal
    {
        require(isActive(id));

        IERC20 buy_gem = offers[id].buy_gem;
        IERC20 pay_gem = offers[id].pay_gem;
        uint prev_id;                                      //maker (ask) id

        pos = pos == 0 || offers[pos].pay_gem != pay_gem || offers[pos].buy_gem != buy_gem || !isOfferSorted(pos)
        ?
            _find(id)
        :
            _findpos(id, pos);

        if (pos != 0) {                                    //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {                                           //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {                               //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint id    //id of maker (ask) offer to remove from sorted list
    )
        internal
        returns (bool)
    {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(_rank[id].delb == 0 &&                    //assert id is in the sorted list
                 isOfferSorted(id));

        if (id != _best[pay_gem][buy_gem]) {              // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {                                          //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {                        //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number;                    //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint id     //id of maker offer to remove from unsorted list
    )
        internal
        returns (bool)
    {
        uint uid = _head;               //id of an offer in unsorted offers list
        uint pre = uid;                 //id of previous offer in unsorted offers list

        require(!isOfferSorted(id));    //make sure offer id is not in sorted offers list

        if (_head == id) {              //check if offer is first offer in unsorted offers list
            _head = _near[id];          //set head to new first unsorted offer
            _near[id] = 0;              //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {  //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {                //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id];         //set previous unsorted offer to point to offer after offer id
        _near[id] = 0;                  //delete order from unsorted order list
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/EventfulMarket.sol";
import "./libraries/DSMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Custom.sol";
import "@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IveSCH.sol";

contract SimpleMarket is EventfulMarket, DSMath {

    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public treasury = 0x496CA1523D6Afb85c9368e8F1146404fB14932Fa;

    IveSCH public vesch;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        IERC20    pay_gem;
        uint     buy_amt;
        IERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }

    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) virtual {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) public view returns (uint, IERC20, uint, IERC20) {
      OfferInfo memory _offer = offers[id];
      return (_offer.pay_amt, _offer.pay_gem,
              _offer.buy_amt, _offer.buy_gem);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
        public
        can_buy(uint256(id_))
    {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            keccak256(abi.encodePacked(offers[id].pay_gem, offers[id].buy_gem)),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buy(uint id, uint quantity)
        public
        can_buy(id)
        synchronized
        virtual
        returns (bool)
    {
        OfferInfo memory _offer = offers[id];
        uint spend = mul(quantity, _offer.buy_amt) / _offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

        // For backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > _offer.pay_amt || spend > _offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(_offer.pay_amt, quantity);
        offers[id].buy_amt = sub(_offer.buy_amt, spend);
        uint fee = spend * 10 / 10000;
        safeTransferFrom(_offer.buy_gem, msg.sender, _offer.owner, spend - fee);
        if (fee > 0) {
            safeTransferFrom(_offer.buy_gem, msg.sender, address(this), fee);
        }
        safeTransfer(_offer.pay_gem, msg.sender, quantity);
        address __offer_buy_gem = address(_offer.buy_gem);
        if (__offer_buy_gem == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) { // WETH
            IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(fee);
            vesch.depositFees{value: fee * 5000 / 10000}(fee * 5000 / 10000, 4);
            vesch.depositFees{value: fee * 3500 / 10000}(fee * 3500 / 10000, 3);
            vesch.depositFees{value: fee * 1000 / 10000}(fee * 1000 / 10000, 2);
            vesch.depositFees{value: fee * 500 / 10000}(fee * 500 / 10000, 1);
        } else if (
            __offer_buy_gem == 0xdAC17F958D2ee523a2206206994597C13D831ec7 || // USDT
            __offer_buy_gem == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 || // USDC
            __offer_buy_gem == 0x6B175474E89094C44Da98b954EedeAC495271d0F || // DAI
            __offer_buy_gem == 0x4Fabb145d64652a948d72533023f6E7A623C7C53    // BUSD
        ) {
            address[] memory path = new address[](2);
            path[0] = __offer_buy_gem;
            path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            IERC20Custom(__offer_buy_gem).approve(address(router), type(uint).max);
            uint256 snapshot = address(this).balance;
            try router.swapExactTokensForETHSupportingFeeOnTransferTokens(fee, 0, path, address(this), block.timestamp + 600) {
                uint256 yield = address(this).balance - snapshot;
                if (yield > 0) {
                    vesch.depositFees{value: yield * 5000 / 10000}(yield * 5000 / 10000, 4);
                    vesch.depositFees{value: yield * 3500 / 10000}(yield * 3500 / 10000, 3);
                    vesch.depositFees{value: yield * 1000 / 10000}(yield * 1000 / 10000, 2);
                    vesch.depositFees{value: yield * 500 / 10000}(yield * 500 / 10000, 1);
                }
            } catch {
                safeTransfer(_offer.buy_gem, treasury, fee);
            }
        } else {
            safeTransfer(_offer.buy_gem, treasury, fee);
        }

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(block.timestamp)
        );
        emit LogTrade(quantity, address(_offer.pay_gem), spend, address(_offer.buy_gem));

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        synchronized
        virtual
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory _offer = offers[id];
        delete offers[id];

        safeTransfer(_offer.pay_gem, _offer.owner, _offer.pay_amt);

        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(_offer.pay_amt),
            uint128(_offer.buy_amt),
            uint64(block.timestamp)
        );

        success = true;
    }

    function kill(bytes32 id)
        public
        virtual
    {
        require(cancel(uint256(id)));
    }

    function make(
        IERC20    pay_gem,
        IERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        virtual
        returns (bytes32 id)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(uint pay_amt, IERC20 pay_gem, uint buy_amt, IERC20 buy_gem)
        public
        can_offer
        synchronized
        virtual
        returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != IERC20(address(0)));
        require(buy_amt > 0);
        require(buy_gem != IERC20(address(0)));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        safeTransferFrom(pay_gem, msg.sender, address(this), pay_amt);

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(block.timestamp)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount)
        public
        virtual
    {
        require(buy(uint256(id), maxTakeAmount));
    }

    function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        require(size > 0, "Not a contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Token call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EventfulMarket {
    event LogItemUpdate(uint id);
    event LogTrade(uint pay_amt, address indexed pay_gem,
                   uint buy_amt, address indexed buy_gem);

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogBump(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Custom {
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
    function transfer(address to, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface ISchwapMarket {
    function getCurrentEpoch() external view returns (uint);
    function getEmissions(uint _epoch) external view returns (uint);
    function getPairVolume(address _pair, uint _epoch) external view returns (uint);
    function getUserVolume(address _pair, address _user, uint _epoch) external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IveSCH {
    function depositFees(uint256 _amount, uint256 _period) external payable;
    function getVotingPower(address _voter) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

contract MatchingEvents {
    event LogMinSell(address pay_gem, uint min_amount);
    event LogUnsortedOffer(uint id);
    event LogSortedOffer(uint id);
    event LogInsert(address keeper, uint id);
    event LogDelete(address keeper, uint id);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface PriceOracleLike {
  function getPriceFor(address, address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

library SchwapLibrary {
    function getPair(
        address tokenA,
        address tokenB
    )
        public
        pure
        returns (address)
    {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == token1 || token0 == address(0)) {
            return address(0);
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(token0, token1)))));
    }
}