//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Contract: Bingo Token
 * Trade without a DEX. $BINGO maintains its own internal liquidity.
 * Socials:
 * TG: 
 * Website: 
 * Twitter: 
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Pair {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BingoToken is IERC20, Context, Ownable, ReentrancyGuard {
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
    string private constant _name = "Bingo Token";
    string private constant _symbol = "BINGO";
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

    // Tax wallets
    address public solidityDevWallet = 0x391D72A49d3D9DDeF9BFccF0cF8CBc54355CFbD9;
    address public frontendDevWallet; // **************************** TODO: FRONT-END DEV WALLET **************************************
    address public projectLeadWallet = 0x0a5B43BaDCD27cA486d878C15b0E80a8aFeE15F5;
    address public apeHarambeWallet = 0xfdc75C3e2d719AE8E846Bc69EcF526d572B36E35;
    address public treasuryWallet = 0xdAbBfEFc45076a8bc16fa270f1a51045082AC4DF;

    // Tax split
    uint256 public solidityDevShare = 15; // 15% tax split to solidity developer
    uint256 public frontendDevShare = 15; // 15% tax split to frontend developer
    uint256 public projectLeadShare = 15; // 15% tax split to project lead
    uint256 public apeHarambeShare = 15; // 15% tax split to Alfalfa
    uint256 public treasuryShare = 40; // 60% tax split to treasury
    uint256 public constant SHAREDIVISOR = 100;

    //Known Wallets
    address private constant DEAD = address(0xDEAD);

    //trading parameters
    uint256 public liquidity = 20 ether;
    uint256 public liqConst = liquidity * _totalSupply;
    uint256 public constant TRADE_OPEN_TIME = 0;

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

    address private stablePairAddress;
    address private stableAddress;

    // initialize supply
    constructor(address _stablePairAddress, address _stableAddress) {
        stablePairAddress = _stablePairAddress;
        stableAddress = _stableAddress;

        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        
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

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        require(spender != address(0), "ZERO_ADDRESS");
        require(
            msg.sender != address(0),
            "ZERO_ADDRESS"
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
                "INSUFFICIENT_ALLOWANCE"
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

    /** Purchases BINGO Tokens and Deposits Them in Sender's Address*/
    function _buy(uint256 minTokenOut/*, uint256 deadline*/)
        public
        payable
        nonReentrant
        returns (bool)
    {
        /*
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");
        */

        // Frontrun Guard
        _lastBuyBlock[msg.sender] = block.number;

        // liquidity is set
        require(liquidity > 0, "The token has no liquidity");

        // check if trading is open
        require(block.timestamp >= TRADE_OPEN_TIME, "Trading is not Open");

        //remove the buy tax
        uint256 ethAmount = isFeeExempt[msg.sender]
            ? msg.value
            : (msg.value * buyMul) / DIVISOR;

        // how much they should purchase?
        uint256 tokensToSend = _balances[address(this)] -
            (liqConst / (ethAmount + liquidity));

        //revert for max bag
        require(
            _balances[msg.sender] + tokensToSend <= maxBag ||
                isTxLimitExempt[msg.sender],
            "Max wallet exceeded"
        );

        // revert if under 1
        require(tokensToSend > 1, "Must Buy more than 1 decimal of BINGO");

        // revert for slippage
        require(tokensToSend >= minTokenOut, "INSUFFICIENT OUTPUT AMOUNT");

        // transfer the tokens from CA to the buyer
        buy(msg.sender, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = msg.value - ethAmount;
        taxBalance = taxBalance + taxAmount;
        liquidity = liquidity + ethAmount;

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
                    ((liquidity - ethAmount) / (_totalSupply)) *
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
            ethAmount * getETHPrice()
        );
        return true;
    }

    /** Sends Tokens to the buyer Address */
    function buy(address receiver, uint256 amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    /** Sells BINGO Tokens And Deposits the ETH into Seller's Address */
    function _sell(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minETHOut
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
        uint256 amountETH = liquidity -
            (liqConst / (_balances[address(this)] + tokenAmount));
        uint256 amountTax = (amountETH * (DIVISOR - sellMul)) / DIVISOR;
        uint256 ETHToSend = amountETH - amountTax;

        //slippage revert
        require(amountETH >= minETHOut, "INSUFFICIENT OUTPUT AMOUNT");

        // send ETH to Seller
        (bool successful, ) = isFeeExempt[msg.sender]
            ? payable(seller).call{value: amountETH}("")
            : payable(seller).call{value: ETHToSend}("");
        require(successful, "ETH transfer failed");

        // subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        //add tax allowance to be withdrawn and remove from liq the amount of beans taken by the seller
        taxBalance = isFeeExempt[msg.sender]
            ? taxBalance
            : taxBalance + amountTax;
        liquidity = liquidity - amountETH;

        // add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + tokenAmount;

        //update volume
        uint256 cTime = block.timestamp;
        uint256 dollarSell = amountETH * getETHPrice();
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
                amountETH,
                dollarSell
            );
        } else {
            emit Sold(
                address(this),
                msg.sender,
                tokenAmount,
                ETHToSend,
                ETHToSend * getETHPrice()
            );
        }
        return true;
    }

    /** Amount of ETH in Contract */
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
            newBuyMul >= 95 &&
                newSellMul >= 95 &&
                newBuyMul <= 100 &&
                newSellMul <= 100,
            "Fees are too high"
        );

        buyMul = newBuyMul;
        sellMul = newSellMul;

        emit FeesMulChanged(newBuyMul, newSellMul);
    }

    // Change team and treasury distribution ratio
    function changeTaxDistribution_(
        uint256 newSolidityDevShare,
        uint256 newFrontendDevShare,
        uint256 newProjectLeadShare,
        uint256 newApeHarambeShare,
        uint256 newTreasuryShare
    ) external onlyOwner {
        require(
            newSolidityDevShare + newFrontendDevShare + newProjectLeadShare + 
                newTreasuryShare + newApeHarambeShare == SHAREDIVISOR,
            "Sum of shares must be 100"
        );

        solidityDevShare = newSolidityDevShare;
        frontendDevShare = newFrontendDevShare;
        projectLeadShare = newProjectLeadShare;
        apeHarambeShare = newApeHarambeShare;
        treasuryShare = newTreasuryShare;
    }

    // Change team and treasury wallet addresses
    function changeFeeReceivers_(
        address newSolidityDevWallet,
        address newFrontendDevWallet,
        address newProjectLeadWallet,
        address newApeHarambeWallet,
        address newTreasuryWallet
    ) external onlyOwner {
        require(
            newSolidityDevWallet != address(0) && 
            newFrontendDevWallet != address(0) &&
            newProjectLeadWallet != address(0) && 
            newApeHarambeWallet != address(0) &&
            newTreasuryWallet != address(0),
            "New wallets must not be the ZERO address"
        );

        solidityDevWallet = newSolidityDevWallet;
        frontendDevWallet = newFrontendDevWallet;
        projectLeadWallet = newProjectLeadWallet;
        apeHarambeWallet = newApeHarambeWallet;
        treasuryWallet = newTreasuryWallet;
    }

    // Withdraw collected taxes to team and treasury wallets
    function withdrawTaxBalance_() external nonReentrant onlyOwner {
        (bool temp1, ) = payable(solidityDevWallet).call{
            value: (taxBalance * solidityDevShare) / SHAREDIVISOR
        }("");
        (bool temp2, ) = payable(frontendDevWallet).call{
            value: (taxBalance * frontendDevShare) / SHAREDIVISOR
        }("");
        (bool temp3, ) = payable(projectLeadWallet).call{
            value: (taxBalance * projectLeadShare) / SHAREDIVISOR
        }("");
        (bool temp4, ) = payable(apeHarambeWallet).call{
            value: (taxBalance * apeHarambeShare) / SHAREDIVISOR
        }("");
        (bool temp5, ) = payable(treasuryWallet).call{
            value: (taxBalance * treasuryShare) / SHAREDIVISOR
        }("");
        assert(temp1 && temp2 && temp3 && temp4 && temp5);
        taxBalance = 0;
    }

    function getTokenAmountOut(uint256 amountETHIn)
        external
        view
        returns (uint256)
    {
        uint256 amountAfter = liqConst / (liquidity - amountETHIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    function getETHAmountOut(uint256 amountIn) public view returns (uint256) {
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
        IUniswapV2Pair pair = IUniswapV2Pair(stablePairAddress);
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