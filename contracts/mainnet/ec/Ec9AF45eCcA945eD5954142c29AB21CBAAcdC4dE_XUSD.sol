//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
    XSurge Interface
 */
interface IXSurge is IERC20 {
    function exchange(address tokenIn, address tokenOut, uint256 amountTokenIn, address destination) external;
    function burn(uint256 amount) external;
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256);
    function mintWithBacking(address backingToken, uint256 numTokens, address recipient) external returns (uint256);
    function requestPromiseTokens(address stable, uint256 amount) external returns (uint256);
    function sell(uint256 tokenAmount) external returns (address, uint256);
    function calculatePrice() external view returns (uint256);
    function getValueOfHoldings(address holder) external view returns(uint256);
    function isUnderlyingAsset(address token) external view returns (bool);
    function getUnderlyingAssets() external view returns(address[] memory);
    function requestFlashLoan(address stable, address stableToRepay, uint256 amount) external returns (bool);
    function resourceCollector() external view returns (address);
}

interface ITokenFetcher {
    function ethToStable(address stable, uint256 minOut) external payable;
    function chooseStable() external view returns (address);
}

interface IPromiseUSD {
    function mint(uint256 amount) external;
    function setApprovedContract(address Contract, bool _isApproved) external;
}

interface ILoanProvider {
    function fulfillFlashLoanRequest() external returns (bool);
}

/**
 * Contract: xUSD V2
 * Developed By: DeFi Mark
 *
 * XUSD Is A Token With A Built In Exchange, Loan Provider, and Internal Market Maker
 * Send ETH or Stake Stablecoins in To Mint xUSD Tokens
 * Sell XUSD tokens to redeem the underlying stablecoins
 * Every Transaction Raises The Value Of XUSD In Stable Coins
 * Price is calculated as a ratio between Total Supply and stable coin quantity in Contract
 * No Contract Interaction Can Lower The Value Of XUSD In Stables, It Is Only Allowed To Rise
 *
 * For More Information:
 * Visit xsurge.net
 */
contract XUSD is IXSurge, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    // token data
    string private constant _name = "XUSD";
    string private constant _symbol = "XUSD";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10**18;
    
    // 1 initial supply
    uint256 private _totalSupply = 10**18; 
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Fees
    uint256 public mintFee        = 99250;            // 0.75% mint fee
    uint256 public sellFee        = 99750;            // 0.25% redeem fee 
    uint256 public transferFee    = 99750;            // 0.25% transfer fee
    uint256 public constant feeDenominator = 10**5;
    
    // Underlying Asset
    struct StableAsset {
        bool isApproved;
        bool mintDisabled;
        uint8 index;
    }
    address[] public stables;
    mapping ( address => StableAsset ) public stableAssets;
    
    // address -> Fee Exemption
    mapping ( address => bool ) public isTransferFeeExempt;

    // Immutable Contracts
    // Lending Token
    address public immutable PROMISE_USD;
    // Token Proposal Contract
    address public immutable TokenProposalContract;

    // Swappable Contracts
    // xSwap Router
    address public xSwapRouter;
    // fee collection
    address private _resourceCollector;
    // Flash Loan Provider
    address public flashLoanProvider;
    // Token Fetcher
    ITokenFetcher public TokenFetcher;
    
    // Percentage of taxation to go toward utilities
    uint256 public resourceAllocationPercentage;

    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrancy Guard call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier notEntered() {
        require(_status != _ENTERED, "Reentrant call");
        _;
    }

    // initialize some stuff
    constructor (
        address PromiseUSD,
        address NewTokenProposal
    ) {
        require(
            PromiseUSD != address(0) &&
            NewTokenProposal != address(0)
        );

        // Set Fields
        PROMISE_USD = PromiseUSD;
        TokenProposalContract = NewTokenProposal;

        // set reentrancy
        _status = _NOT_ENTERED;

        // resource collector
        resourceAllocationPercentage = 50;

        // Add BUSD
        address BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
        stables.push(BUSD);
        stableAssets[BUSD].isApproved = true;
        stableAssets[BUSD].index = 0;

        // Add USDC
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        stables.push(USDC);
        stableAssets[USDC].isApproved = true;
        stableAssets[USDC].index = 1;
        
        // fee exempt PCS Router + Promisary Contract
        isTransferFeeExempt[0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45] = true;
        isTransferFeeExempt[PromiseUSD]                                 = true;
        isTransferFeeExempt[_resourceCollector]                         = true;

        // allocate initial 1 token
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return _totalSupply; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }
    
    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            require(_status != _ENTERED, "Reentrant call");
            _sell(msg.sender, expectedTokenToReceive(amount), amount, recipient);
            return true;
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero");
        require(amount > 0, "Transfer Amt Zero");
        // track price change
        uint256 oldPrice = _calculatePrice();
        // fee exempt
        bool isExempt = isTransferFeeExempt[sender] || isTransferFeeExempt[recipient];
        // amount to give recipient
        uint256 tAmount = isExempt ? amount : amount.mul(transferFee).div(feeDenominator);
        // tax taken from transfer
        uint256 tax = amount.sub(tAmount);
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // allocate tax if applicable
        if (shouldAllocateResources(isExempt, sender, recipient)) {
            _allocateResources(tax);
        }

        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);

        // burn the tax
        if (tax > 0) {
            _totalSupply = _totalSupply.sub(tax);
            emit Transfer(sender, address(0), tax);
        }
        
        // require price rises
        _requirePriceRises(oldPrice);
        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    /**
        Mint XUSD Tokens With The Native Token ETH
        This will choose the optimal stable token to purchase via PancakeSwap
        It will then mint tokens to `recipient` based on the value received from Pancakeswap
        `minOut` should be set to avoid the PCS Transaction from being front runned

        @param recipient Account to receive minted XUSD Tokens
        @param minOut minimum amount out from ETH -> StableCoin - prevents front run attacks
        @return received number of XUSD tokens received
     */
    function mintWithNative(address recipient, uint256 minOut) external override payable returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithNative(recipient, minOut);
    }
    
    /** 
        Mint XUSD Tokens By Depositing Approved Stable Coins Into The Contract
        Requires Approval from the backingToken prior to purchase
        
        @param backingToken Approved Stable To Mint XUSD With, Must have mintDisabled set to false
        @param numTokens number of `backingToken` tokens to mint XUSD with
        @return tokensMinted number of XUSD tokens minted
    */
    function mintWithBacking(address backingToken, uint256 numTokens) external nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithBacking(backingToken, numTokens, msg.sender);
    }

    /** 
        Mint XUSD Tokens For `recipient` By Depositing `backingToken` Into The Contract
            Requirements:
                `backingToken` must be an approved XUSD stable coin
                Approval from the `backingToken` prior to purchase
        
        @param backingToken Approved Stable To Mint XUSD With, Must have mintDisabled set to false
        @param numTokens number of `backingToken` tokens to mint XUSD with
        @param recipient Account to receive minted XUSD tokens
        @return tokensMinted number of XUSD tokens minted
    */
    function mintWithBacking(address backingToken, uint256 numTokens, address recipient) external override nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithBacking(backingToken, numTokens, recipient);
    }

    /** 
        Burns Sender's XUSD Tokens and redeems their value in the optimal Approved XUSD Stable Token
        @param tokenAmount Number of XUSD Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external override notEntered returns (address, uint256) {
        address tokenToSend = expectedTokenToReceive(tokenAmount);
        return _sell(msg.sender, tokenToSend, tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's XUSD Tokens and redeems their value in `desiredToken`
        @param desiredToken Token to receive from XUSD, Must be an Approved XUSD Stable
        @param tokenAmount Number of XUSD Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount, address desiredToken) external notEntered returns (address, uint256) {
        return _sell(msg.sender, desiredToken, tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's XUSD Tokens and redeems their value in `desiredToken` for `recipient`
        @param desiredToken Token to receive from XUSD, Must be an Approved XUSD Stable
        @param tokenAmount Number of XUSD Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of `desiredToken` transfer, Must not be address(0)
    */
    function sell(uint256 tokenAmount, address desiredToken, address recipient) external notEntered returns (address, uint256) {
        return _sell(msg.sender, desiredToken, tokenAmount, recipient);
    }

    /**
        Exchanges TokenIn For TokenOut 1:1 So Long As:
            - TokenIn  is an approved XUSD stable and not address(0) or tokenOut
            - TokenOut is an approved XUSD stable and not address(0) or tokenIn
            - TokenIn and TokenOut have the same decimal count
        
        The xSwap Router is the only contract with permission to this function
        It is up to the xSwap Router to charge a fee for this service that will
        benefit XUSD in some capacity, either through donation or to the Treasury

        @param tokenIn - Token To Give XUSD in exchange for TokenOut
        @param tokenOut - Token To receive from swap
        @param tokenInAmount - Amount of `tokenIn` to exchange for tokenOut
        @param recipient - Recipient of `tokenOut` tokens
     */
    function exchange(address tokenIn, address tokenOut, uint256 tokenInAmount, address recipient) external override nonReentrant {
        require(
            tokenIn != address(0) && 
            tokenOut != address(0) && 
            recipient != address(0) &&
            tokenIn != tokenOut &&
            tokenInAmount > 0,
            'Invalid Params'
        );
        require(
            !stableAssets[tokenIn].mintDisabled,
            'TokenIn Disabled'
        );
        require(
            stableAssets[tokenIn].isApproved &&
            stableAssets[tokenOut].isApproved,
            'Not Approved'
        );
        require(
            IERC20(tokenIn).decimals() == IERC20(tokenOut).decimals(),
            'Decimal Mismatch'
        );
        require(
            msg.sender == xSwapRouter,
            'Only Router'
        );
        _swapStables(tokenIn, tokenOut, tokenInAmount, recipient);
    }
    
    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of XUSD Tokens To Burn
    */
    function burn(uint256 amount) external override notEntered {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, 'Zero Holdings');
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }

    /**
        Triggerable Only By PromisaryToken Contract
        Temporarily Sells XUSD Tax Free and holds XUSD in escrow
        Until Stable Amount Is Returned
        It is up to implementing contracts to ensure XUSD profits from this trade off

        @param stable Stable Token To Be Sent To PROMISE_USD
        @param amount number of XUSD tokens to redeem
        @return amountDelivered number of `stable` tokens returned to PROMISE_USD
     */
    function requestPromiseTokens(address stable, uint256 amount) external override nonReentrant returns (uint256) {
        require(msg.sender == PROMISE_USD, 'Only Promise');
        require(stableAssets[stable].isApproved, 'Non Approved Stable');

        // log old price
        uint256 oldPrice = _calculatePrice();

        // value in underlying
        uint256 amountUnderlyingToDeliver = amountOut(amount);
        require(
            amountUnderlyingToDeliver > 0 &&
            amountUnderlyingToDeliver <= IERC20(stable).balanceOf(address(this)),
            'Invalid Amount'
        );

        // send Tokens to Seller
        bool successful = IERC20(stable).transfer(PROMISE_USD, amountUnderlyingToDeliver);
        require(successful, 'Transfer Failure');

        // Trigger Ghost Token Creation
        IPromiseUSD(PROMISE_USD).mint(amountUnderlyingToDeliver);

        // require price rises
        _requirePriceRises(oldPrice);

        // emit ghost event
        emit PromiseTokens(amount, amountUnderlyingToDeliver);

        // return amount that was sent
        return amountUnderlyingToDeliver;
    }

    /**
        Allows User To Borrow Stables From XUSD For One Transaction
        If The Stables Are Not Returned By The End Of The Transaction, everything is reverted
        It is up to the implementing flashLoanProvider contract to handle the charging of fees if applicable

        @param stable Stable Token To Request Loan
        @param stableToRepay Stable Token To Fulfil Loan
        @param amount amount of stable tokens to transfer
        @return success whether transaction succeeded or not
     */
    function requestFlashLoan(address stable, address stableToRepay, uint256 amount) external override nonReentrant returns (bool) {
        require(
            msg.sender == flashLoanProvider,
            'Only Flash Loan Provider'
        );
        require(
            stableAssets[stable].isApproved,
            'Not Approved'
        );
        require(
            stableAssets[stableToRepay].isApproved &&
            !stableAssets[stableToRepay].mintDisabled,
            'Repayment Stable Not Approved'
        );
        require(
            amount <= IERC20(stable).balanceOf(address(this)),
            "Insufficient Balance"
        );

        // stable swap liquidity balance before loan
        uint256 oldLiquidity = liquidityInStableCoinSwap();

        // price before loan
        uint256 oldPrice = _calculatePrice();

        // backing before loan
        uint256 oldBacking = calculateBacking();

        // transfer amount to sender
        IERC20(stable).transfer(flashLoanProvider, amount);

        // trigger functionality on external contract
        require(
            ILoanProvider(flashLoanProvider).fulfillFlashLoanRequest(),
            'Fulfilment Request Failed'
        );
        
        // track pricing value changes
        uint256 newLiquidity = liquidityInStableCoinSwap();

        // require more stable has been acquired
        require(
            newLiquidity >= oldLiquidity &&
            calculateBacking() >= oldBacking, 
            "Flash loan not paid back"
        );

        // require price rises
        _requirePriceRises(oldPrice);

        // track event
        emit FlashLoaned(stable, stableToRepay, amount, newLiquidity - oldLiquidity + amount);
        return true;
    }



    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    /** Purchases xUSD Token and Deposits Them in Recipient's Address */
    function _mintWithNative(address recipient, uint256 minOut) internal nonReentrant returns (uint256) {        
        require(msg.value > 0, 'Zero Value');
        require(recipient != address(0));
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // previous backing
        uint256 previousBacking = calculateBacking();
        
        // swap ETH for stable
        uint256 received = _swapForStable(minOut);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? calculateBacking() : previousBacking;

        // mint to recipient
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Stake Tokens and Deposits xUSD in Sender's Address, Must Have Prior Approval */
    function _mintWithBacking(address token, uint256 numTokens, address recipient) internal returns (uint256) {
        // require staking token is approved
        require(stableAssets[token].isApproved && token != address(0), 'Token Not Approved');
        // users token balance
        uint256 userTokenBalance = IERC20(token).balanceOf(msg.sender);
        // ensure user has enough to send
        require(userTokenBalance > 0 && numTokens <= userTokenBalance, 'Insufficient Balance');
        // require token is approved for minting
        require(!stableAssets[token].mintDisabled, 'Mint Is Disabled With This Token');

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // previous backing
        uint256 previousBacking = calculateBacking();

        // transfer in token
        uint256 received = _transferIn(token, numTokens);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? received : previousBacking;

        // Handle Minting
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Sells xUSD Tokens And Deposits Underlying Asset Tokens into Recipients's Address */
    function _sell(address seller, address desiredToken, uint256 tokenAmount, address recipient) internal nonReentrant returns (address, uint256) {
        require(tokenAmount > 0 && _balances[seller] >= tokenAmount);
        require(seller != address(0) && recipient != address(0));
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isTransferFeeExempt[seller] ? 
            tokenAmount.sub(10, 'Minimum Exemption') :
            tokenAmount.mul(sellFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);
        require(_validToSend(desiredToken, amountUnderlyingAsset), 'Invalid Token');

        // burn from sender + supply 
        _burn(seller, tokenAmount);
        
        // allocate resources
        if (shouldAllocateResources(isTransferFeeExempt[seller], seller, recipient)) {
            _allocateResources(tokenAmount.sub(tokensToSwap));
        }

        // send Tokens to Seller
        bool successful = IERC20(desiredToken).transfer(recipient, amountUnderlyingAsset);

        // ensure Tokens were delivered
        require(successful, 'Transfer Failure');

        // require price rises
        _requirePriceRises(oldPrice);
        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);
        // return token redeemed and amount underlying
        return (desiredToken, amountUnderlyingAsset);
    }

    /** Handles Minting Logic To Create New Surge Tokens*/
    function _mintTo(address recipient, uint256 received, uint256 totalBacking, uint256 oldPrice) private returns(uint256) {
        
        // find the number of tokens we should mint to keep up with the current price
        uint256 calculatedSupply = _totalSupply == 0 ? 10**18 : _totalSupply;
        uint256 tokensToMintNoTax = calculatedSupply.mul(received).div(totalBacking);
        
        // apply fee to minted tokens to inflate price relative to total supply
        uint256 tokensToMint = isTransferFeeExempt[msg.sender] ? 
                tokensToMintNoTax.sub(10, 'Minimum Exemption') :
                tokensToMintNoTax.mul(mintFee).div(feeDenominator);
        require(tokensToMint > 0, 'Zero Amount');
        
        // allocate resources if fee exempt
        if (shouldAllocateResources(isTransferFeeExempt[msg.sender], msg.sender, recipient)) {
            _allocateResources(tokensToMintNoTax.sub(tokensToMint));
        }
        
        // mint to Buyer
        _mint(recipient, tokensToMint);
        // require price rises
        _requirePriceRises(oldPrice);
        // differentiate purchase
        emit Minted(recipient, tokensToMint);
        return tokensToMint;
    }

    /** Swaps `amount` ETH for `stable` utilizing the token fetcher contract */
    function _swapForStable(uint256 minOut) internal returns (uint256) {

        // stable to swap for
        address stable = TokenFetcher.chooseStable();
        require(stableAssets[stable].isApproved && !stableAssets[stable].mintDisabled);

        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = IERC20(stable).balanceOf(address(this));

        // swap ETH For stable of choice
        TokenFetcher.ethToStable{value: address(this).balance}(stable, minOut);

        // amount after swap
        uint256 currentTokenAmount = IERC20(stable).balanceOf(address(this));
        require(currentTokenAmount > prevTokenAmount);
        return currentTokenAmount - prevTokenAmount;
    }

    /** Accepts `tokenIn` and sends `tokenOut` to recipient. This is a 1:1 swap */
    function _swapStables(address tokenIn, address tokenOut, uint256 tokenInAmount, address recipient) internal {

        // track previous price
        uint256 oldPrice = _calculatePrice();

        // transfer in tokens
        uint256 received = _transferIn(tokenIn, tokenInAmount);

        // check send amount validity
        require(
            received <= tokenInAmount && received > 0,
            'SC'
        );
        require(
            IERC20(tokenOut).balanceOf(address(this)) >= received,
            'Insufficient Balance'
        );

        // send amount to sender
        bool s = IERC20(tokenOut).transfer(recipient, received);
        require(s, 'Transfer Fail');

        // require price rises
        _requirePriceRises(oldPrice);

        // track event
        emit ExchangeStables(tokenIn, tokenOut, tokenInAmount, received, recipient);
    }

    /** Requires The Price Of XUSD To Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, 'Price Cannot Fall');
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(address token, uint256 desiredAmount) internal returns (uint256) {
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(msg.sender, address(this), desiredAmount);
        uint256 received = IERC20(token).balanceOf(address(this)) - balBefore;
        require(s && received > 0 && received <= desiredAmount);
        return received;
    }
    
    /** Mints a percentage of `tax` to the resource collector */
    function _allocateResources(uint256 tax) private {
        uint256 allocation = tax.mul(resourceAllocationPercentage).div(100);
        if (allocation > 0) {
            _mint(_resourceCollector, allocation);
        }
    }
    
    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) private {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) private {
        _balances[account] = _balances[account].sub(amount, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(amount, 'Negative Supply');
        emit Transfer(account, address(0), amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function _checkGarbageCollector(address burnLocation) internal {
        uint256 bal = _balances[burnLocation];
        if (bal > 0) {
            // Track Change In Price
            uint256 oldPrice = _calculatePrice();
            // burn amount
            _burn(burnLocation, bal);
            // Emit Collection
            emit GarbageCollected(bal);
            // Emit Price Difference
            emit PriceChange(oldPrice, _calculatePrice(), _totalSupply);
        }
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    

    /** Price Of XUSD in BUSD With 18 Points Of Precision */
    function calculatePrice() external view override returns (uint256) {
        return _calculatePrice();
    }
    
    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        uint256 totalShares = _totalSupply == 0 ? 1 : _totalSupply;
        uint256 backingValue = calculateBacking();
        return (backingValue.mul(precision)).div(totalShares);
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of XUSD
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view override returns(uint256) {
        return amountOut(_balances[holder]);
    }

    /** Returns true if `token` is an XUSD Approved Stable Coin, false otherwise */
    function isUnderlyingAsset(address token) external view override returns (bool) {
        return stableAssets[token].isApproved;
    }

    /** Returns The Address of the Underlying Asset */
    function getUnderlyingAssets() external override view returns(address[] memory) {
        return stables;
    }

    /** Calculates The Sum Of Assets Backing XUSD's Valuation */
    function calculateBacking() public view returns (uint256) {
        uint total = liquidityInStableCoinSwap();
        return total + IERC20(PROMISE_USD).totalSupply();
    }

    /** Calculates Sum Of Assets Backing XUSD's Valuation EXLCUDING Promisary Tokens */
    function liquidityInStableCoinSwap() public view returns (uint256 total) {
        for (uint i = 0; i < stables.length; i++) {
            total += IERC20(stables[i]).balanceOf(address(this));
        }
    }

    /** expected token to receive when tokens are sold */
    function expectedTokenToReceive(uint256 amount) public view returns (address) {
        uint MAX = 0;
        address tokenToReceive;
        uint bal;
        for (uint i = 0; i < stables.length; i++) {
            bal = IERC20(stables[i]).balanceOf(address(this));
            if (bal > MAX) {
                tokenToReceive = stables[i];
                MAX = bal;
            }
        }
        return _validToSend(tokenToReceive, amountOut(amount)) ? tokenToReceive : address(0);
    }

    function resourceCollector() external view override returns (address) {
        return _resourceCollector;
    }

    /** Whether or not XUSD Should Allocate Resources To The Resource Collector */
    function shouldAllocateResources(bool feeExempt, address caller, address recipient) internal view returns (bool) {
        return 
            !feeExempt
            && caller != _resourceCollector
            && recipient != _resourceCollector
            && resourceAllocationPercentage > 0;
    }
    
    /** Whether or not a stable token is valid to send to a user when selling the token */
    function _validToSend(address stable, uint256 amount) internal view returns (bool) {
        return 
            stable != address(0) && 
            stableAssets[stable].isApproved && 
            amount > 0 &&
            IERC20(stable).balanceOf(address(this)) >= amount;
    }
    
    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////

    /** Updates The Address Of The Flashloan Provider */
    function upgradeFlashLoanProvider(address flashLoanProvider_) external onlyOwner {
        require(flashLoanProvider_ != address(0));
        flashLoanProvider = flashLoanProvider_;
        emit SetFlashLoanProvider(flashLoanProvider_);
    }

    /** Updates The Address Of The Token Fetcher, in case of PCS Migration */
    function upgradeTokenFetcher(ITokenFetcher tokenFetcher) external onlyOwner {
        require(address(tokenFetcher) != address(0));
        TokenFetcher = tokenFetcher;
        emit SetTokenFetcher(address(tokenFetcher));
    }

    /** Updates The Address Of The xSwap Router */
    function upgradeXSwapRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0));
        xSwapRouter = _newRouter;
        emit SetXSwapRouter(_newRouter);
    }

    /** Updates The Address Of The Resource Collector */
    function upgradeResourceCollector(address newCollector, uint256 _allocationPercentage) external onlyOwner {
        require(newCollector != address(0));
        require(_allocationPercentage <= 90);
        if (!isTransferFeeExempt[newCollector]) {
            isTransferFeeExempt[newCollector] = true;
        }
        _resourceCollector = newCollector;
        resourceAllocationPercentage = _allocationPercentage;
        emit SetResourceCollector(newCollector, _allocationPercentage);
    }

    /** Disables The Stable Token To Be Used To Mint XUSD, Cannot Disable Immutable Tokens */
    function disableMintForStable(address stable, bool isDisabled) external onlyOwner {
        require(stable != address(0));
        require(stableAssets[stable].isApproved);
        stableAssets[stable].mintDisabled = isDisabled;
    }

    /** 
        Adds And Approves A Stable Coin For XUSD
        Must be called From TokenProposalContract which puts
        precautions and wait times in place for security and transparency
     */
    function addStable(address newStable) external {
        require(msg.sender == TokenProposalContract);
        require(!stableAssets[newStable].isApproved);
        require(newStable != address(0));
        require(IERC20(newStable).decimals() == 18);

        stableAssets[newStable].isApproved = true;
        stableAssets[newStable].index = uint8(stables.length);
        stables.push(newStable);
    }

    /** 
        Removes A Stable Coin From The List Of Approved Stables
        ALL Value Of The Removed Token MUST Be Replaced By The Caller
        Within The Same Transaction. This Function is here to prevent risks from
        a compromised stable coin.
    */
    function removeStable(address stable, address stableToSwapWith) external nonReentrant onlyOwner {
        require(stableAssets[stable].isApproved);
        require(stableAssets[stableToSwapWith].isApproved);
        require(stableToSwapWith != stable, 'Matching Swap');
        require(stableToSwapWith != PROMISE_USD && stable != PROMISE_USD, 'Promise');

        // price before Tx
        uint256 oldPrice = _calculatePrice();

        // last element's index set to removed element's index
        stableAssets[
            stables[stables.length - 1]
        ].index = stableAssets[stable].index;

        // replace removed element with last element
        stables[
            stableAssets[stable].index
        ] = stables[stables.length - 1];

        // remove last element of array
        stables.pop();
        delete stableAssets[stable];
        
        // transfer in approved stable
        uint256 bal = IERC20(stable).balanceOf(address(this));
        uint256 received = _transferIn(stableToSwapWith, bal);
        
        // transfer out removed stable
        require(
            IERC20(stable).transfer(msg.sender, received),
            'Failure Transfer Out'
        );

        // require no change to price
        _requirePriceRises(oldPrice);
    }

    /** Withdraws Tokens Incorrectly Sent To XUSD */
    function withdrawNonStableToken(address token) external onlyOwner {
        require(!stableAssets[token].isApproved);
        require(token != address(0) && token != PROMISE_USD);
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /** 
        Situation Where Tokens Are Un-Recoverable
            Example Situations: 
                Lost Wallet Keys
                Broken Contract Without Withdraw Fuctionality
                Exchange Hot Wallet Without XUSD Support
        Will Redeem Stables Tax Free On Behalf of Wallet
        Will Prevent Incorrectly 'Burnt' or Locked Up Tokens From Continuously Appreciating
     */
    function redeemForLostAccount(address account, uint256 amount) external onlyOwner {
        require(account != address(0));
        require(account != PROMISE_USD);
        require(_balances[account] > 0 && _balances[account] >= amount);

        // make tax exempt
        isTransferFeeExempt[account] = true;
        // sell tokens tax free on behalf of frozen wallet
        _sell(
            account, 
            expectedTokenToReceive(amount),
            amount == 0 ? _balances[account] : amount, 
            account
        );
        // remove tax exemption
        isTransferFeeExempt[account] = false;
    }

    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 2% ) 
    */
    function setFees(uint256 _mintFee, uint256 _transferFee, uint256 _sellFee) external onlyOwner {
        require(_mintFee >= 98000);      // capped at 2% fee
        require(_transferFee >= 98000);  // capped at 2% fee
        require(_sellFee >= 98000);      // capped at 2% fee
        
        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        emit SetFees(_mintFee, _transferFee, _sellFee);
    }
    
    /** Excludes Contract From Transfer Fees */
    function setPermissions(address Contract, bool transferFeeExempt) external onlyOwner {
        require(Contract != address(0) && Contract != PROMISE_USD);
        isTransferFeeExempt[Contract] = transferFeeExempt;
        emit SetPermissions(Contract, transferFeeExempt);
    }

    /** Allows an external contract to interact with Promise USD */
    function setApprovedPromiseUSDContract(address Contract, bool isApprovedForPromiseUSD) external onlyOwner {
        require(Contract != address(0));
        IPromiseUSD(PROMISE_USD).setApprovedContract(Contract, isApprovedForPromiseUSD);
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        _mintWithNative(msg.sender, 0);
        _checkGarbageCollector(address(this));
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    // Data Tracking
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event TokenActivated(uint blockNo);

    // Balance Tracking
    event Burn(address from, uint256 amountTokensErased);
    event GarbageCollected(uint256 amountTokensErased);
    event Redeemed(address seller, uint256 amountxUSD, uint256 assetsRedeemed);
    event Minted(address recipient, uint256 numTokens);

    // Upgradable Contract Tracking
    event SetFlashLoanProvider(address newFlashProvider);
    event SetTokenFetcher(address newTokenFetcher);
    event SetXSwapRouter(address newRouter);
    event SetResourceCollector(address newCollector, uint256 allocation);

    // Utility Event Notifiers
    event PromiseTokens(uint256 tokensLocked, uint256 assetsGhosted);
    event FlashLoaned(address token, address repaymentToken, uint256 amountLent, uint256 amountReceived);
    event ExchangeStables(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, address recipient);

    // Governance Tracking
    event TransferOwnership(address newOwner);
    event SetPermissions(address Contract, bool feeExempt);
    event SetFees(uint mintFee, uint transferFee, uint sellFee);
}