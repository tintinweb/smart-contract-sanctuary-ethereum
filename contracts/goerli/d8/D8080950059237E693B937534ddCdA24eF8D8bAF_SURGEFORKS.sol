//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IPancakePair.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISRG.sol";
import "./DividendDistributor.sol";

contract SURGEFORKS is IERC20, Context, Ownable, ReentrancyGuard {
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
    string private _name = "SurgeForks";
    string private _symbol = "SRGF";
    uint8 private constant _decimals = 9;
    uint256 private constant _DECMULTIPLIER = 10**_decimals;

    //SRG pair data
    address private constant SRG = 0xF5d7636974ff35dA8d22Ab83CDd8B64476bEbAB9; //change this according to chain
    ISRG private constant SRGI = ISRG(SRG); //interface to interact with SRG
    IERC20 private constant SRGIE = IERC20(SRG); //interace to interact with SRG

    uint256 private _srgDecimals = SRGIE.decimals();

    // Total Supply
    uint256 public constant _totalSupply = 77*10**6 * _DECMULTIPLIER;

    // balances
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    //Fees
    mapping(address => bool) public isFeeExempt;
    uint256 public sellMul = 91;
    uint256 public buyMul = 91;
    uint256 public constant DIVISOR = 100;

    //Max bag requirements and max TX
    mapping(address => bool) public isTxLimitExempt;
    uint256 public maxBag = (_totalSupply * 2) / 100;
    uint256 public maxTX = _totalSupply / 200;

    //Tax collection
    uint256 public taxBalance = 0;

    //Tax wallets
    address public teamWallet = 0x9E5FE3A8cB5FDCf88A5Ccd92FB2A76f8c8c14322;
    address public treasuryWallet = 0x3eb625c01aE9288F8a255ffd1D7C52f964d8D6CE;
    // Tax Split
    uint256 public teamShare = 0;
    uint256 public treasuryShare = 300;
    uint256 public rewardsShare = 600;
    uint256 public constant SHAREDIVISOR = 900;
    //Known Wallets
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    //trading parameters
    uint256 public liquidity = 77 * 10**13;
    uint256 public liqConst = liquidity * _totalSupply;
    bool public tradeOpen = false;

    //volume trackers
    mapping(address => uint256) public indVol;
    mapping(uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    //candlestick data
    uint256 public constant PADDING = 10**18;
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

    //Dividend distributor
    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 500000;
    mapping(address => bool) public isDividendExempt;

    // initialize supply
    constructor() {
        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(0)] = true;

        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        dividendDistributor = new DividendDistributor();
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

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
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
    function _buy(
        uint256 buyAmount,
        uint256 minTokenOut,
        uint256 deadline
    ) public nonReentrant returns (bool) {
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");

        address buyer = msg.sender;
        // Frontrun Guard
        _lastBuyBlock[buyer] = block.number;

        // liquidity is set
        require(liquidity > 0, "The token has no liquidity");

        // check if trading is open
        require(tradeOpen, "Trading is not Open");

        //remove the buy tax
        uint256 srgAmount = isFeeExempt[buyer]
            ? buyAmount
            : (buyAmount * buyMul) / DIVISOR;

        // how much they should purchase?
        uint256 tokensToSend = _balances[address(this)] -
            (liqConst / (srgAmount + liquidity));

        //revert for max bag
        require(
            (_balances[buyer] + tokensToSend <= maxBag &&
                tokensToSend <= maxTX) || isTxLimitExempt[buyer],
            "Max wallet exceeded"
        );

        // revert if under 1
        require(tokensToSend > 1, "SRG20: Must Buy more than 1 decimal");

        // revert for slippage
        require(tokensToSend >= minTokenOut, "INSUFFICIENT OUTPUT AMOUNT");

        // transfer the SRG from the msg.sender to the CA
        bool s = SRGIE.transferFrom(buyer, address(this), buyAmount);

        require(s, "transfer of SRG failed!");

        // transfer the tokens from CA to the buyer
        buy(buyer, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = buyAmount - srgAmount;
        taxBalance = taxBalance + taxAmount;
        liquidity = liquidity + srgAmount;

        //update volume
        uint256 cTime = block.timestamp;
        uint256 dollarBuy = buyAmount * getSRGPrice();
        totalVolume += dollarBuy;
        indVol[buyer] += dollarBuy;
        tVol[cTime] += dollarBuy;

        //update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = cTime;
        uint256 cPrice = calculatePrice() * getSRGPrice();
        candleStickData[cTime].time = cTime;
        if (candleStickData[cTime].open == 0) {
            if (totalTx == 1) {
                candleStickData[cTime].open =
                    ((liquidity - srgAmount) / (_totalSupply)) *
                    getSRGPrice();
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

        if (
            !isDividendExempt[buyer] && !isFeeExempt[buyer] && rewardsShare > 0
        ) {
            try
                dividendDistributor.deposit(
                    (taxAmount * rewardsShare) / SHAREDIVISOR
                )
            {} catch {}

            try
                dividendDistributor.setShare(buyer, _balances[buyer])
            {} catch {}

            bool temp2 = SRGIE.transfer(
                dividendDistributor.getAddress(),
                (taxAmount * rewardsShare) / SHAREDIVISOR
            );

            require(temp2, "Failed to send SRG rewards");

            taxBalance -= (taxAmount * rewardsShare) / SHAREDIVISOR;

            try dividendDistributor.process(distributorGas) {} catch {}
        }

        //emit transfer and buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Bought(
            msg.sender,
            address(this),
            tokensToSend,
            buyAmount,
            srgAmount * getSRGPrice()
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

        //max TX requirement
        require(tokenAmount <= maxTX, "Max Tx exceeded!");

        address seller = msg.sender;

        // make sure seller has this balance
        require(
            _balances[seller] >= tokenAmount,
            "cannot sell above token amount"
        );

        // get how much beans are the tokens worth
        uint256 amountSRG = liquidity -
            (liqConst / (_balances[address(this)] + tokenAmount));
        uint256 amountTax = (amountSRG * (DIVISOR - sellMul)) / DIVISOR;
        uint256 SRGtoSend = amountSRG - amountTax;

        //slippage revert
        require(amountSRG >= minBNBOut, "INSUFFICIENT OUTPUT AMOUNT");

        // send SRG to Seller

        bool successful = isFeeExempt[msg.sender]
            ? SRGIE.transfer(msg.sender, amountSRG)
            : SRGIE.transfer(msg.sender, SRGtoSend);
        require(successful, "SRG transfer failed");

        // subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        //add tax allowance to be withdrawn and remove from liq the amount of beans taken by the seller
        taxBalance = isFeeExempt[msg.sender]
            ? taxBalance
            : taxBalance + amountTax;
        liquidity = liquidity - amountSRG;

        // add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + tokenAmount;

        //update volume
        uint256 cTime = block.timestamp;
        uint256 dollarSell = amountSRG * getSRGPrice();
        totalVolume += dollarSell;
        indVol[msg.sender] += dollarSell;
        tVol[cTime] += dollarSell;

        //update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = cTime;
        uint256 cPrice = calculatePrice() * getSRGPrice();
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
                amountSRG,
                dollarSell
            );
        } else {
            emit Sold(
                address(this),
                msg.sender,
                tokenAmount,
                SRGtoSend,
                SRGtoSend * getSRGPrice()
            );

            // Dividends

            if (
                !isDividendExempt[seller] &&
                !isFeeExempt[seller] &&
                rewardsShare > 0
            ) {
                try
                    dividendDistributor.deposit(
                        (amountTax * rewardsShare) / SHAREDIVISOR
                    )
                {} catch {}
                try
                    dividendDistributor.setShare(seller, _balances[seller])
                {} catch {}

                bool temp2 = SRGIE.transfer(
                    dividendDistributor.getAddress(),
                    (amountTax * rewardsShare) / SHAREDIVISOR
                );
                require(temp2, "Failed to send SRG rewards");

                taxBalance -= (amountTax * rewardsShare) / SHAREDIVISOR;
                try dividendDistributor.process(distributorGas) {} catch {}
            }
        }
        return true;
    }

    /** Amount of liquidity in Contract */
    function getLiquidity() public view returns (uint256) {
        return liquidity;
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns (uint256) {
        return
            ((_balances[holder] * liquidity) / _balances[address(this)]) *
            getSRGPrice();
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
        uint256 newtreasuryShare,
        uint256 newBurnShare,
        uint256 newrewardsShare
    ) external onlyOwner {
        require(
            newteamShare + newtreasuryShare + newBurnShare + newrewardsShare ==
                SHAREDIVISOR,
            "Sum of shares must be SHAREDIVISOR"
        );
        teamShare = newteamShare;
        treasuryShare = newtreasuryShare;
        rewardsShare = newrewardsShare;
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
        if (teamShare > 0) {
            bool temp1 = SRGIE.transfer(
                teamWallet,
                (taxBalance * teamShare) / (teamShare + treasuryShare)
            );
            require(temp1, "failed to send funds");
        }

        if (treasuryShare > 0) {
            bool temp2 = SRGIE.transfer(
                treasuryWallet,
                (taxBalance * treasuryShare) / (teamShare + treasuryShare)
            );
            require(temp2, "failed to send funds");
        }
        taxBalance = 0;
    }

    function getTokenAmountOut(uint256 amountSRGIn)
        external
        view
        returns (uint256)
    {
        uint256 amountAfter = liqConst / (liquidity - amountSRGIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    function getsrgAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 srgBefore = liqConst / _balances[address(this)];
        uint256 srgAfter = liqConst / (_balances[address(this)] + amountIn);
        return srgBefore - srgAfter;
    }

    function addLiquidity(uint256 amountSRGLiq) external onlyOwner {
        uint256 tokensToAdd = (_balances[address(this)] * amountSRGLiq) /
            liquidity;
        require(_balances[msg.sender] >= tokensToAdd, "Not enough tokens!");

        bool sLiq = SRGIE.transfer(address(this), amountSRGLiq);
        require(sLiq, "SRG transfer was unsuccesful!");

        uint256 oldLiq = liquidity;
        liquidity = liquidity + amountSRGLiq;
        _balances[address(this)] += tokensToAdd;
        _balances[msg.sender] -= tokensToAdd;
        liqConst = (liqConst * liquidity) / oldLiq;

        emit Transfer(msg.sender, address(this), tokensToAdd);
    }

    function getMarketCap() external view returns (uint256) {
        return (getCirculatingSupply() * calculatePrice() * getSRGPrice());
    }

    // calculate price based on pair SRG price
    function getSRGPrice() public view returns (uint256) {
        return (SRGI.calculatePrice() * SRGI.getETHPrice()); // return amount of token0 needed to buy token1
    }

    // Returns the Current Price of the Token in SRG
    function calculatePrice() public view returns (uint256) {
        require(liquidity > 0, "No Liquidity");
        return (liquidity * PADDING) / _balances[address(this)];
    }

    function changeIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this));
        isDividendExempt[holder] = exempt;

        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        dividendDistributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution
        );
    }

    function changeDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    // HELL YA WE CAN BE BITCOIN
    function changeTokenName(string memory newName, string memory newSymbol)
        external
        onlyOwner
    {
        _name = newName;
        _symbol = newSymbol;
    }

    function openTrading() external nonReentrant onlyOwner {
        require(!tradeOpen, "You cannot disable trading after enabling!");
        tradeOpen = true;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISRG {
    function calculatePrice() external view returns (uint256);

    function getETHPrice() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IDividendDistributor.sol";
import "./interfaces/IERC20.sol";

contract DividendDistributor is IDividendDistributor {
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    /// Modify the SURGE Address here
    IERC20 SURGE = IERC20(0x3816B271c3D89726e80f4c79EE303639d05999D0);

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10**18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
    }

    function getAddress() external view override returns (address) {
        return address(this);
    }

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amount) external override onlyToken {
        totalDividends = totalDividends + amount;
        dividendsPerShare =
            dividendsPerShare +
            ((dividendsPerShareAccuracyFactor * amount) / totalShares);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            SURGE.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised =
                shares[shareholder].totalRealised +
                amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function claimDividend(address holder) external override {
        distributeDividend(holder);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit(uint256 amount) external;

    function process(uint256 gas) external;

    function claimDividend(address holder) external;

    function getAddress() external view returns (address);
}