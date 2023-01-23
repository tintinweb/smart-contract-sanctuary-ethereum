// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Contract: Bingo Token
 * Trade without a DEX. $BINGO maintains its own internal liquidity.
 * Socials:
 * TG: https://t.me/bingonetworkio
 * Website: https://bingonetwork.io/
 * Twitter: https://twitter.com/bingonetworkio
 */

// Provides a modifier that allows us to prevent callbacks into the contract during execution
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

// Interface to interact with Uniswap style LP
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

// Standard ERC20 interface
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

// OpenZeppelin style _msgSender() context call
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// Ownable handling
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

// Primary contract logic
contract BingoToken is IERC20, Context, Ownable, ReentrancyGuard {
    event Buy(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 ETH,
        uint256 dollarBuy
    );
    event Sell(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 ETH,
        uint256 dollarSell
    );
    event FeesMulChanged(uint256 newBuyMul, uint256 newSellMul);
    event StablePairChanged(address newStablePair, address newStableToken);
    event balanceLimitChanged(uint256 newbalanceLimit);

    // Token data
    string private constant _name = "Bingo Token";
    string private constant _symbol = "BINGO";
    uint8 private constant _decimals = 9;
    uint256 private constant _decMultiplier = 10**_decimals;

    // Total supply
    uint256 public constant _totalSupply = 10**8 * _decMultiplier;

    // Balances / Allowances
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // Fees
    mapping(address => bool) public isFeeExempt;
    uint256 public sellMul = 95; // 5% sell fee
    uint256 public buyMul = 95; // 5% buy fee
    uint256 public constant DIVISOR = 100;

    // Max balance limit
    mapping(address => bool) public isBalanceLimitExempt;
    uint256 public balanceLimit = _totalSupply / 100; // 1% max supply cap per wallet

    // Tax collection
    uint256 public taxBalance = 0; // Current total amount of taxes collected in contract

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

    // Known wallets
    address private constant DEAD = address(0xDEAD);

    // Trading parameters
    uint256 public liquidity = 20 ether;
    uint256 public liqConst = liquidity * _totalSupply;
    uint256 public constant TRADE_OPEN_TIME = 0; // ******************************** TODO: TRADE OPEN BLOCK TIMESTAMP ********************************************

    // Volume trackers
    mapping(address => uint256) public indVol;
    mapping(uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    // Candlestick data
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

    // Frontrun guard
    // Works by preventing any address from buying and selling in the same block
    mapping(address => uint256) private _lastBuyBlock;

    // ETH/USDC and USDC pair and token addresses
    address private stablePairAddress; // 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443
    address private stableAddress; // 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8

    // Initialize supply
    constructor(address _stablePairAddress, address _stableAddress) {
        stablePairAddress = _stablePairAddress;
        stableAddress = _stableAddress;

        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;

        isBalanceLimitExempt[msg.sender] = true;
        isBalanceLimitExempt[address(this)] = true;
        isBalanceLimitExempt[DEAD] = true;
        isBalanceLimitExempt[address(0)] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    // Total token supply
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    // Token balance per address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Allowance per spender for each holder
    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    // Token name
    function name() public pure returns (string memory) {
        return _name;
    }

    // Token symbol
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // Token decimals
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // Give token approval for amount to spender
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

    // Give max approval to spender
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    // Retrieve non-burned supply
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD];
    }

    // Management function to change supply per wallet cap
    // Must be at least 1%
    function changeWalletLimit_(uint256 newLimit) external onlyOwner {
        require(
            newLimit >= _totalSupply / 100,
            "New wallet limit should be at least 1% of total supply"
        );
        balanceLimit = newLimit;
        emit balanceLimitChanged(newLimit);
    }

    // Management function to set address fee exemption
    function changeIsFeeExempt_(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    // Management function to set address balance cap exemption
    function changeisBalanceLimitExempt_(address holder, bool exempt)
        external
        onlyOwner
    {
        isBalanceLimitExempt[holder] = exempt;
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
            "ZERO_ADDRESS/SELF_CONTRACT"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            isBalanceLimitExempt[recipient] ||
                _balances[recipient] + amount <= balanceLimit,
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

    // Decrease allowance by amount on all transfers
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
                // Decrease allowance
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // Token approval logic
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

    // Purchases BINGO tokens and deposit them in sender's wallet
    function buy(uint256 minTokenOut, uint256 deadline)
        public
        payable
        nonReentrant
        returns (bool)
    {
        // Deadline requirement
        require(deadline >= block.timestamp, "Deadline expired");

        // Frontrun Guard
        _lastBuyBlock[msg.sender] = block.number;

        // Ensure there is liquidity
        require(liquidity > 0, "The token has no liquidity");

        // Confirm trading is open
        require(block.timestamp >= TRADE_OPEN_TIME, "Trading is not open");

        // Deduct the buy tax
        uint256 postTaxETHAmount = isFeeExempt[msg.sender]
            ? msg.value
            : (msg.value * buyMul) / DIVISOR;

        // Calculate token purchase amount
        uint256 tokensToSend = _balances[address(this)] -
            (liqConst / (postTaxETHAmount + liquidity));

        // Ensure purchase will not make msg.sender's balance exceed max wallet limit
        require(
            _balances[msg.sender] + tokensToSend <= balanceLimit ||
                isBalanceLimitExempt[msg.sender],
            "Max wallet exceeded"
        );

        // Revert if under 1
        require(tokensToSend >= 1, "Must Buy more than 0 decimals of BINGO");

        // Revert for slippage
        require(tokensToSend >= minTokenOut, "Insufficient output amount");

        // Transfer the tokens from contract to the buyer
        _buy(msg.sender, tokensToSend);

        // Update tax and liquidity balances
        uint256 taxAmount = msg.value - postTaxETHAmount;
        taxBalance += taxAmount;
        liquidity += postTaxETHAmount;

        // Update volume data
        uint256 timestamp = block.timestamp;
        uint256 dollarBuy = msg.value * getETHPriceInUSDC();
        totalVolume += dollarBuy;
        indVol[msg.sender] += dollarBuy;
        tVol[timestamp] += dollarBuy;

        // Update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = timestamp;
        uint256 currentPrice = calculateBINGOPriceInETH() * getETHPriceInUSDC();
        candleStickData[timestamp].time = timestamp;
        if (candleStickData[timestamp].open == 0) {
            if (totalTx == 1) {
                candleStickData[timestamp].open =
                    ((liquidity - postTaxETHAmount) / (_totalSupply)) *
                    getETHPriceInUSDC();
            } else {
                candleStickData[timestamp].open = candleStickData[
                    txTimeStamp[totalTx - 1]
                ].close;
            }
        }
        candleStickData[timestamp].close = currentPrice;

        if (
            candleStickData[timestamp].high < currentPrice ||
            candleStickData[timestamp].high == 0
        ) {
            candleStickData[timestamp].high = currentPrice;
        }

        if (
            candleStickData[timestamp].low > currentPrice ||
            candleStickData[timestamp].low == 0
        ) {
            candleStickData[timestamp].low = currentPrice;
        }

        // Emit Transfer and Buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Buy(
            msg.sender,
            address(this),
            tokensToSend,
            msg.value,
            postTaxETHAmount * getETHPriceInUSDC()
        );
        return true;
    }

    /** Sends Tokens to the buyer Address */
    function _buy(address receiver, uint256 amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    /** Sells BINGO Tokens And Deposits the ETH into Seller's Address */
    function _sell(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minETHOut
    ) public nonReentrant returns (bool) {
        // Deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");

        // Frontrun guard
        // Prevents frontrunning by preventing buying and selling in the same block
        require(
            _lastBuyBlock[msg.sender] != block.number,
            "Buying and selling in the same block is not allowed!"
        );

        address seller = msg.sender;

        // Make sure seller's balance is adequate
        require(
            _balances[seller] >= tokenAmount,
            "cannot sell above token amount"
        );

        // Get how much in ETH the tokens are worth
        uint256 amountETH = liquidity -
            (liqConst / (_balances[address(this)] + tokenAmount));
        uint256 amountTax = (amountETH * (DIVISOR - sellMul)) / DIVISOR;
        uint256 ethToSend = amountETH - amountTax;

        // Slippage revert
        require(amountETH >= minETHOut, "Insufficient output amount");

        // Send ETH to Seller
        (bool successful, ) = isFeeExempt[msg.sender]
            ? payable(seller).call{value: amountETH}("")
            : payable(seller).call{value: ethToSend}("");
        require(successful, "ETH transfer failed");

        // Subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        // Add tax allowance to be withdrawn and remove from liq in the amount of ETH taken by the seller
        taxBalance = isFeeExempt[msg.sender]
            ? taxBalance
            : taxBalance + amountTax;
        liquidity = liquidity - amountETH;

        // Add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + tokenAmount;

        // Update volume
        uint256 timestamp = block.timestamp;
        uint256 dollarSell = amountETH * getETHPriceInUSDC();
        totalVolume += dollarSell;
        indVol[msg.sender] += dollarSell;
        tVol[timestamp] += dollarSell;

        // Update candleStickData
        totalTx += 1;
        txTimeStamp[totalTx] = timestamp;
        uint256 currentPrice = calculateBINGOPriceInETH() * getETHPriceInUSDC();
        candleStickData[timestamp].time = timestamp;
        if (candleStickData[timestamp].open == 0) {
            candleStickData[timestamp].open = candleStickData[
                txTimeStamp[totalTx - 1]
            ].close;
        }
        candleStickData[timestamp].close = currentPrice;

        if (
            candleStickData[timestamp].high < currentPrice ||
            candleStickData[timestamp].high == 0
        ) {
            candleStickData[timestamp].high = currentPrice;
        }

        if (
            candleStickData[timestamp].low > currentPrice ||
            candleStickData[timestamp].low == 0
        ) {
            candleStickData[timestamp].low = currentPrice;
        }

        // Emit Transfer and Sell events
        emit Transfer(seller, address(this), tokenAmount);
        if (isFeeExempt[msg.sender]) {
            emit Sell(
                address(this),
                msg.sender,
                tokenAmount,
                amountETH,
                dollarSell
            );
        } else {
            emit Sell(
                address(this),
                msg.sender,
                tokenAmount,
                ethToSend,
                ethToSend * getETHPriceInUSDC()
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
            getETHPriceInUSDC();
    }

    // Change fees to a value only between 0-5%
    function changeFees_(uint256 newBuyMul, uint256 newSellMul)
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

    // Return the amount of tokens an amount of ETH can purchase
    function getTokenAmountOut(uint256 amountETHIn)
        public
        view
        returns (uint256)
    {
        uint256 amountAfter = liqConst / (liquidity - amountETHIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    // *********************** TODO: Check if this function name correctly reflects the nature of this function *******************************
    function getPostTaxETHAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 ethPriceBefore = liqConst / _balances[address(this)];
        uint256 ethPriceAfter = liqConst / (_balances[address(this)] + amountIn);
        return ethPriceBefore - ethPriceAfter;
    }

    // Add core contract liquidity
    // Liquidity provisioning is not permissionless
    function addLiquidity_() external payable onlyOwner {
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

    // Return market cap in USDC
    function getMarketCapInUSDC() external view returns (uint256) {
        return (getCirculatingSupply() * calculateBINGOPriceInETH() * getETHPriceInUSDC());
    }

    // Management functions to change the ETH/stablecoin pair and stablecoin address values
    function changeStablePair_(address newStablePair, address newStableAddress)
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

    // Calculate ETH price in USDC by querying Uniswap ETH/USDC pool
    function getETHPriceInUSDC() public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(stablePairAddress);
        IERC20 token1 = pair.token0() == stableAddress
            ? IERC20(pair.token1())
            : IERC20(pair.token0());

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        if (pair.token0() != stableAddress) {
            (Res1, Res0, ) = pair.getReserves();
        }
        uint256 res0 = Res0 * 10**token1.decimals();
        return (res0 / Res1); // Return amount of token0 needed to buy token1
    }

    // Returns the Current Price of BINGO in ETH
    function calculateBINGOPriceInETH() public view returns (uint256) {
        require(liquidity > 0, "No Liquidity");
        return liquidity / _balances[address(this)];
    }
}