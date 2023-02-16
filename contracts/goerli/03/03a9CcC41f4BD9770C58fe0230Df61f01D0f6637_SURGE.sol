//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IPancakePair.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SURGE is IERC20, Context, Ownable, ReentrancyGuard {
    event Bought(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 beans,
        uint256 dollarBuy
    );
    event Sold(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 beans,
        uint256 dollarSell
    );
    event FeesMulChanged(uint256 newBuyMul, uint256 newSellMul);
    event StablePairChanged(address newStablePair, address newStableToken);
    event MaxBagChanged(uint256 newMaxBag);

    // token data
    string private constant _name = "SURGE";
    string private constant _symbol = "SRG";
    uint8 private constant _decimals = 9;
    uint256 private constant _decMultiplier = 10**_decimals;

    // Total Supply
    uint256 public constant _totalSupply = 10**8 * _decMultiplier;

    // balances
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    //Fees
    mapping(address => bool) public isFeeExempt;
    uint256 public sellMul = 95;
    uint256 public buyMul = 95;
    uint256 public constant DIVISOR = 100;

    //Max bag requirements
    mapping(address => bool) public isTxLimitExempt;
    uint256 public maxBag = _totalSupply / 100;

    //Tax collection
    uint256 public taxBalance = 0;

    //Tax wallets
    address public teamWallet = 0x4867542d8366E845D4ddECb608Fb0b939aA9DF56;
    address public treasuryWallet = 0x4867542d8366E845D4ddECb608Fb0b939aA9DF56;

    // Tax Split
    uint256 public teamShare = 40;
    uint256 public treasuryShare = 60;
    uint256 public constant SHAREDIVISOR = 100;

    //Known Wallets
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    //trading parameters
    uint256 public liquidity = 20 ether;
    uint256 public liqConst = liquidity * _totalSupply;
    uint256 public constant TRADE_OPEN_TIME = 1673542800;

    //volume trackers
    mapping(address => uint256) public indVol;
    mapping(uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    //candlestick data
    uint256 public totalTx;
    mapping(uint256 => uint256) public txTimeStamp;

    struct candleStick {
        uint256 time;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }

    mapping(uint256 => candleStick) public candleStickData;

    //Frontrun Guard
    mapping(address => uint256) private _lastBuyBlock;

    //Migration Wallet
    address public constant MIGRATION_WALLET =
        0x897826Aa5cb352216E14AfAeAA75d434d27aF573;
    
    //Stable address 
    // Mainnet
    // address private stablePairAddress =
    //     0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
    // address private stableAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // Testnet
    address private stablePairAddress =
        0xe979387E6dAD7D4a92F9aC88e42C6e6461DB8b64;
    address private stableAddress = 0x00B64e468d2C705A0907F58505536a6C8c49Ab26;

    // initialize supply
    constructor() {
        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[MIGRATION_WALLET] = true;

        isTxLimitExempt[MIGRATION_WALLET] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(0)] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        require(spender != address(0), "SRG20: approve to the zero address");
        require(
            msg.sender != address(0),
            "SRG20: approve from the zero address"
        );

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD];
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(
            newLimit >= _totalSupply / 100,
            "New wallet limit should be at least 1% of total supply"
        );
        maxBag = newLimit;
        emit MaxBagChanged(newLimit);
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** TransferFrom Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        address spender = msg.sender;
        //check allowance requirement
        _spendAllowance(sender, spender, amount);
        return _transferFrom(sender, recipient, amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        // make standard checks
        require(
            recipient != address(0) && recipient != address(this),
            "transfer to the zero address or CA"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            isTxLimitExempt[recipient] ||
                _balances[recipient] + amount <= maxBag,
            "Max wallet exceeded!"
        );

        // subtract from sender
        _balances[sender] = _balances[sender] - amount;

        // give amount to receiver
        _balances[recipient] = _balances[recipient] + amount;

        // Transfer Event
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "SRG20: insufficient allowance"
            );

            unchecked {
                // decrease allowance
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

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

    /** Purchases SURGE Tokens and Deposits Them in Sender's Address*/
    function _buy(uint256 minTokenOut, uint256 deadline)
        public
        payable
        nonReentrant
        returns (bool)
    {
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");

        // Frontrun Guard
        _lastBuyBlock[msg.sender] = block.number;

        // liquidity is set
        require(liquidity > 0, "The token has no liquidity");

        // check if trading is open or whether the buying wallet is the migration one
        require(
            block.timestamp >= TRADE_OPEN_TIME ||
                msg.sender == MIGRATION_WALLET,
            "Trading is not Open"
        );

        //remove the buy tax
        uint256 bnbAmount = isFeeExempt[msg.sender]
            ? msg.value
            : (msg.value * buyMul) / DIVISOR;

        // how much they should purchase?
        uint256 tokensToSend = _balances[address(this)] -
            (liqConst / (bnbAmount + liquidity));

        //revert for max bag
        require(
            _balances[msg.sender] + tokensToSend <= maxBag ||
                isTxLimitExempt[msg.sender],
            "Max wallet exceeded"
        );

        // revert if under 1
        require(tokensToSend > 1, "Must Buy more than 1 decimal of Surge");

        // revert for slippage
        require(tokensToSend >= minTokenOut, "INSUFFICIENT OUTPUT AMOUNT");

        // transfer the tokens from CA to the buyer
        buy(msg.sender, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = msg.value - bnbAmount;
        taxBalance = taxBalance + taxAmount;
        liquidity = liquidity + bnbAmount;

        //update volume
        uint256 cTime = block.timestamp;
        uint256 dollarBuy = msg.value * getETHPrice();
        totalVolume += dollarBuy;
        indVol[msg.sender] += dollarBuy;
        tVol[cTime] += dollarBuy;

        //update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = cTime;
        uint256 cPrice = calculatePrice() * getETHPrice();
        candleStickData[cTime].time = cTime;
        if (candleStickData[cTime].open == 0) {
            if (totalTx == 1) {
                candleStickData[cTime].open =
                    ((liquidity - bnbAmount) / (_totalSupply)) *
                    getETHPrice();
            } else {
                candleStickData[cTime].open = candleStickData[
                    txTimeStamp[totalTx - 1]
                ].close;
            }
        }
        candleStickData[cTime].close = cPrice;

        if (
            candleStickData[cTime].high < cPrice ||
            candleStickData[cTime].high == 0
        ) {
            candleStickData[cTime].high = cPrice;
        }

        if (
            candleStickData[cTime].low > cPrice ||
            candleStickData[cTime].low == 0
        ) {
            candleStickData[cTime].low = cPrice;
        }

        //emit transfer and buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Bought(
            msg.sender,
            address(this),
            tokensToSend,
            msg.value,
            bnbAmount * getETHPrice()
        );
        return true;
    }

    /** Sends Tokens to the buyer Address */
    function buy(address receiver, uint256 amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    /** Sells SURGE Tokens And Deposits the BNB into Seller's Address */
    function _sell(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minBNBOut
    ) public nonReentrant returns (bool) {
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");

        //Frontrun Guard
        require(
            _lastBuyBlock[msg.sender] != block.number,
            "Buying and selling in the same block is not allowed!"
        );

        address seller = msg.sender;

        // make sure seller has this balance
        require(
            _balances[seller] >= tokenAmount,
            "cannot sell above token amount"
        );

        // get how much beans are the tokens worth
        uint256 amountBNB = liquidity -
            (liqConst / (_balances[address(this)] + tokenAmount));
        uint256 amountTax = (amountBNB * (DIVISOR - sellMul)) / DIVISOR;
        uint256 BNBToSend = amountBNB - amountTax;

        //slippage revert
        require(amountBNB >= minBNBOut, "INSUFFICIENT OUTPUT AMOUNT");

        // send BNB to Seller
        (bool successful, ) = isFeeExempt[msg.sender]
            ? payable(seller).call{value: amountBNB}("")
            : payable(seller).call{value: BNBToSend}("");
        require(successful, "BNB/ETH transfer failed");

        // subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        //add tax allowance to be withdrawn and remove from liq the amount of beans taken by the seller
        taxBalance = isFeeExempt[msg.sender]
            ? taxBalance
            : taxBalance + amountTax;
        liquidity = liquidity - amountBNB;

        // add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + tokenAmount;

        //update volume
        uint256 cTime = block.timestamp;
        uint256 dollarSell = amountBNB * getETHPrice();
        totalVolume += dollarSell;
        indVol[msg.sender] += dollarSell;
        tVol[cTime] += dollarSell;

        //update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = cTime;
        uint256 cPrice = calculatePrice() * getETHPrice();
        candleStickData[cTime].time = cTime;
        if (candleStickData[cTime].open == 0) {
            candleStickData[cTime].open = candleStickData[
                txTimeStamp[totalTx - 1]
            ].close;
        }
        candleStickData[cTime].close = cPrice;

        if (
            candleStickData[cTime].high < cPrice ||
            candleStickData[cTime].high == 0
        ) {
            candleStickData[cTime].high = cPrice;
        }

        if (
            candleStickData[cTime].low > cPrice ||
            candleStickData[cTime].low == 0
        ) {
            candleStickData[cTime].low = cPrice;
        }

        // emit transfer and sell events
        emit Transfer(seller, address(this), tokenAmount);
        if (isFeeExempt[msg.sender]) {
            emit Sold(
                address(this),
                msg.sender,
                tokenAmount,
                amountBNB,
                dollarSell
            );
        } else {
            emit Sold(
                address(this),
                msg.sender,
                tokenAmount,
                BNBToSend,
                BNBToSend * getETHPrice()
            );
        }
        return true;
    }

    /** Amount of BNB in Contract */
    function getLiquidity() public view returns (uint256) {
        return liquidity;
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns (uint256) {
        return
            ((_balances[holder] * liquidity) / _balances[address(this)]) *
            getETHPrice();
    }

    function changeFees(uint256 newBuyMul, uint256 newSellMul)
        external
        onlyOwner
    {
        require(
            newBuyMul >= 90 &&
                newSellMul >= 90 &&
                newBuyMul <= 100 &&
                newSellMul <= 100,
            "Fees are too high"
        );

        buyMul = newBuyMul;
        sellMul = newSellMul;

        emit FeesMulChanged(newBuyMul, newSellMul);
    }

    function changeTaxDistribution(
        uint256 newteamShare,
        uint256 newtreasuryShare
    ) external onlyOwner {
        require(
            newteamShare + newtreasuryShare == SHAREDIVISOR,
            "Sum of shares must be 100"
        );

        teamShare = newteamShare;
        treasuryShare = newtreasuryShare;
    }

    function changeFeeReceivers(
        address newTeamWallet,
        address newTreasuryWallet
    ) external onlyOwner {
        require(
            newTeamWallet != address(0) && newTreasuryWallet != address(0),
            "New wallets must not be the ZERO address"
        );

        teamWallet = newTeamWallet;
        treasuryWallet = newTreasuryWallet;
    }

    function withdrawTaxBalance() external nonReentrant onlyOwner {
        (bool temp1, ) = payable(teamWallet).call{
            value: (taxBalance * teamShare) / SHAREDIVISOR
        }("");
        (bool temp2, ) = payable(treasuryWallet).call{
            value: (taxBalance * treasuryShare) / SHAREDIVISOR
        }("");
        assert(temp1 && temp2);
        taxBalance = 0;
    }

    function getTokenAmountOut(uint256 amountBNBIn)
        external
        view
        returns (uint256)
    {
        uint256 amountAfter = liqConst / (liquidity - amountBNBIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    function getBNBAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 beansBefore = liqConst / _balances[address(this)];
        uint256 beansAfter = liqConst / (_balances[address(this)] + amountIn);
        return beansBefore - beansAfter;
    }

    function addLiquidity() external payable onlyOwner {
        uint256 tokensToAdd = (_balances[address(this)] * msg.value) /
            liquidity;
        require(_balances[msg.sender] >= tokensToAdd, "Not enough tokens!");

        uint256 oldLiq = liquidity;
        liquidity = liquidity + msg.value;
        _balances[address(this)] += tokensToAdd;
        _balances[msg.sender] -= tokensToAdd;
        liqConst = (liqConst * liquidity) / oldLiq;

        emit Transfer(msg.sender, address(this), tokensToAdd);
    }

    function getMarketCap() external view returns (uint256) {
        return (getCirculatingSupply() * calculatePrice() * getETHPrice());
    }

    function changeStablePair(address newStablePair, address newStableAddress)
        external
        onlyOwner
    {
        require(
            newStablePair != address(0) && newStableAddress != address(0),
            "New addresses must not be the ZERO address"
        );

        stablePairAddress = newStablePair;
        stableAddress = newStableAddress;
        emit StablePairChanged(newStablePair, newStableAddress);
    }

    // calculate price based on pair reserves
    function getETHPrice() public view returns (uint256) {
        IPancakePair pair = IPancakePair(stablePairAddress);
        IERC20 token1 = pair.token0() == stableAddress
            ? IERC20(pair.token1())
            : IERC20(pair.token0());

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        if (pair.token0() != stableAddress) {
            (Res1, Res0, ) = pair.getReserves();
        }
        uint256 res0 = Res0 * 10**token1.decimals();
        return (res0 / Res1); // return amount of token0 needed to buy token1
    }

    // Returns the Current Price of the Token in beans
    function calculatePrice() public view returns (uint256) {
        require(liquidity > 0, "No Liquidity");
        return liquidity / _balances[address(this)];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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