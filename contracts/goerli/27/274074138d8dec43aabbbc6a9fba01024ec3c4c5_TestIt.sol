/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


contract TestIt is IERC20, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    // token data
    string private constant _name = "TestIt";
    string private constant _symbol = "TestIt";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10**18;
    
    IERC20 public immutable underlying;

    uint256 private _totalSupply;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // address -> Fee Exemption
    mapping ( address => bool ) public isTransferFeeExempt;
    
    // Custom Fees for contracts/users
    struct CustomFee {
        uint256 sellFee;
        uint256 mintFee;
    }

    mapping(address => CustomFee) public customFee;

    // presale allocation
    struct Presale {
        address user;
        uint256 allocation;
    }

    mapping(address => Presale) public presale;

    // Token Activation
    bool public tokenActivated;

    // presale
    bool public presaleOpen;

    // Fees
    uint256 public mintFee        = 100_000;            // 0% presale mintfee
    uint256 public sellFee        = 96_000;            // 4% redeem fee 
    uint256 public transferFee    = 100_000;            // 0% transfer fee
    uint256 private constant feeDenominator = 10**5;   //100,000

    // Fee Receiver Fees
    address public feeReceiver;
    uint256 public feeReceiverPercentage; // percentage of 100,000

    address public zapper;

    constructor(address underlying_, address feeReceiver_) {
        require(
            underlying_ != address(0),
            'Zero Address'
        );

        // initialize underlying asset
        underlying = IERC20(underlying_);

        // Fee Exempt Router And Creator For Initial Distribution
        isTransferFeeExempt[msg.sender] = true;

        // initialize fee receiver
        feeReceiver = feeReceiver_;
        feeReceiverPercentage = feeDenominator / 4; // 25% of fee is taken for receivers

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
    function transfer(address recipient, uint256 amount) external override nonReentrant returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override nonReentrant returns (bool) {
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
        // amount to give recipient
        uint256 tAmount = (isTransferFeeExempt[sender] || isTransferFeeExempt[recipient]) ? amount : amount.mul(transferFee).div(feeDenominator);
        // tax taken from transfer
        uint256 tax = amount.sub(tAmount);

        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");     //100

        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);                //90

        // burn the tax
        if (tax > 0) {
            // Take Fee
            _takeFee(tax);
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
        Mint testTokens With The Native Token
        This will purchase BUSD with BNB received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `minOut` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted testTokens
        @param minOut minimum amount out from BNB -> BUSD - prevents front run attacks
        @return received number of testtokens received
     */
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256) {   
        _checkGarbageCollector(address(this));
        return _mintWithNative(recipient, minOut);
    }


    /** 
        Mint testTokens For `recipient` By Depositing BUSD Into The Contract
            Requirements:
                Approval from the BUSD prior to purchase
        
        @param numTokens number of BUSD tokens to mint testwith
        @param recipient Account to receive minted testtokens
        @return tokensMinted number of testtokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        return _mintWithBacking(numTokens, recipient);
    }

    /** 
        Burns Sender's testTokens and redeems their value in BUSD
        @param tokenAmount Number of testTokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's testTokens and redeems their value in BUSD for `recipient`
        @param tokenAmount Number of testTokens To Redeem, Must be greater than 0
        @param recipient Recipient Of BUSD transfer, Must not be address(0)
    */
    function sell(uint256 tokenAmount, address recipient) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, recipient);
    }
    
    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of testTokens To Burn
    */
    function burn(uint256 amount) external nonReentrant {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, 'Zero Holdings');
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // take fee
        _takeFee(amount);
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }
    
    /** Purchases testToken and Deposits Them in Recipient's Address */
    function _mintWithNative(address recipient, uint256 minOut) internal nonReentrant returns (uint256) {        
        require(msg.value > 0, 'Zero Value');
        require(recipient != address(0), 'Zero Address');
        require(
            tokenActivated || msg.sender == this.getOwner() || presaleOpen,
            'Token Not Activated'
        );
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // amount of underlying
        uint256 amountUnderlying = underlyingBalance();   //amount of BUSD in this contract.
        
        // swap BNB for stable
        uint256 received = _getUnderlying(minOut);    //how much BUSD we just swapped into

        // mint to recipient
        return _mintTo(recipient, received, amountUnderlying, oldPrice);
    }
    
    /** Stake Tokens and Deposits testin Sender's Address, Must Have Prior Approval For BUSD */
    function _mintWithBacking(uint256 amount, address recipient) internal returns (uint256) {
        require(
            tokenActivated || msg.sender == this.getOwner() || presaleOpen,
            'Token Not Activated'
        );

        // users token balance
        uint256 userTokenBalance = underlying.balanceOf(msg.sender);    //how much BUSD the user owns
        // ensure user has enough to send
        require(userTokenBalance > 0 && amount <= userTokenBalance, 'Insufficient Balance');   //first condition redundant

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // amount of underlying
        uint256 amountUnderlying = underlyingBalance();

        // transfer in token
        uint256 received = _transferIn(amount);

        // Handle Minting
        return _mintTo(recipient, received, amountUnderlying, oldPrice);
    }
    
    /** Burns testTokens And Deposits BUSD Tokens into Recipients's Address */
    function _sell(address seller, uint256 tokenAmount, address recipient) internal returns (uint256) {
        require(tokenAmount > 0 && _balances[seller] >= tokenAmount);
        require(seller != address(0) && recipient != address(0));
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        uint256 curFee = customFee[seller].sellFee > 0 ? 
                customFee[seller].sellFee : sellFee;

        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isTransferFeeExempt[seller] ? 
            tokenAmount.sub(100, 'Minimum Exemption') :
            tokenAmount.mul(curFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);

        // Take Fee
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokenAmount.sub(tokensToSwap);
            _takeFee(fee);
        }

        // burn from sender + supply 
        _burn(seller, tokenAmount);

        // send Tokens to Seller
        require(
            underlying.transfer(recipient, amountUnderlyingAsset), 
            'Underlying Transfer Failure'
        );

        // require price rises
        _requirePriceRises(oldPrice);

        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);

        // return token redeemed and amount underlying
        return amountUnderlyingAsset;
    }

    /** Handles Minting Logic To Create New test*/
    function _mintTo(address recipient, uint256 received, uint256 totalBacking, uint256 oldPrice) private returns(uint256) {
        
        // find the number of tokens we should mint to keep testwith the current price
        uint256 tokensToMintNoTax = _totalSupply == 0 ?
            received : 
            _totalSupply.mul(received).div(totalBacking);

        uint256 curFee = customFee[msg.sender].mintFee > 0 ?      //100,000
                customFee[msg.sender].mintFee : mintFee;
        
        // apply fee to minted tokens to inflate price relative to total supply
        uint256 tokensToMint = isTransferFeeExempt[msg.sender] ? 
                tokensToMintNoTax.sub(100, 'Minimum Exemption') :
                tokensToMintNoTax.mul(curFee).div(feeDenominator);
        require(tokensToMint > 0, 'Zero Amount');

        if(presaleOpen){
            require(presale[msg.sender].user == msg.sender, 'Not Whitelisted');
            require(tokensToMint <= presale[msg.sender].allocation, 'Not enough allocation');
            presale[msg.sender].allocation -= tokensToMint;
        }
        
        // mint to Buyer
        _mint(recipient, tokensToMint);

        // apply fee to tax taken
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokensToMintNoTax.sub(tokensToMint);
            _takeFee(fee);
        }

        // require price rises
        _requirePriceRises(oldPrice);

        // differentiate purchase
        emit Minted(recipient, tokensToMint);
        return tokensToMint;
    }

    /** Takes Fee */
    function _takeFee(uint mFee) internal {
        uint256 feeToTake = ( mFee * feeReceiverPercentage ) / feeDenominator;     //2.5  (upon deployment)
        if (feeToTake > 0 && feeReceiver != address(0)) {
            _mint(feeReceiver, feeToTake);
        }
    }

    /** Swaps to underlying, must get minOut underlying to be successful */
    function _getUnderlying(uint256 minOut) internal returns (uint256) {

        // previous amount of Tokens before we received any
        uint256 balBefore = underlyingBalance();

        // swap BNB For stable of choice
        (bool s,) = payable(zapper).call{value: address(this).balance}("");    //how is this a swap? is the zapper a contract with custom receive()
        require(s, 'Failure On Zapper Transfer');

        // amount after swap
        uint256 balAfter = underlyingBalance();
        require(
            balAfter > balBefore,
            'Zero Received'
        );
        require(
            balAfter >= ( balBefore + minOut ),
            'Insufficient Out'
        );
        return balAfter - balBefore;
    }

    /** Requires The Price Of testTo Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, 'Price Cannot Fall');
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(uint256 desiredAmount) internal returns (uint256) {
        uint256 balBefore = underlyingBalance();
        require(
            underlying.transferFrom(msg.sender, address(this), desiredAmount),
            'Failure Transfer From'
        );
        uint256 balAfter = underlyingBalance();
        require(
            balAfter > balBefore,
            'Zero Received'
        );
        return balAfter - balBefore;
    }
    
    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) private {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }

        function AAmint(uint amount) public {
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), msg.sender, amount);
    }
    
    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) private {
        _balances[account] = _balances[account].sub(amount, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(amount, 'Negative Supply');
        emit Transfer(account, address(0), amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function _checkGarbageCollector(address burnLocation) public {
        uint256 bal = _balances[burnLocation];   //testtoken balance of the contract 
        if (bal > 10**3) {       //if there is more than 1,000 tokens in the contract?. No decimal check, so 1 token is actually enough? Seems that's what they want
            // Track Change In Price
            // take fee
            // burn amount
            _burn(burnLocation, bal);


        }
    }
    
    function underlyingBalance() public view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /** Price Of testin BUSD With 18 Points Of Precision */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }
    
    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        return _totalSupply == 0 ? 10**18 : (underlyingBalance().mul(precision)).div(_totalSupply);
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of UP
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return amountOut(_balances[holder]);
    }

    /** Activates/Pauses Token */
    function activateToken(bool _flag) external onlyOwner {
        tokenActivated = _flag;
        emit TokenActivated(block.number);
    }

    function presaleToggle(bool _flag) external onlyOwner {
        presaleOpen = _flag;
        emit presaleStatus(presaleOpen);
    }
    
    function setFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), 'Zero Address');
        feeReceiver = newReceiver;
        emit SetFeeReceiver(newReceiver);
    }

    function setFeeReceiverPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= ( 9 * feeDenominator / 10), 'Invalid Percentage');
        feeReceiverPercentage = newPercentage;
        emit SetFeeReceiverPercentage(newPercentage);
    }

    function setZapper(address newZapper) external onlyOwner {
        require(newZapper != address(0), 'Zero Address');
        zapper = newZapper;
        emit SetZapper(newZapper);
    }

    /** Withdraws Tokens Incorrectly Sent To test*/
    function withdrawNonStableToken(IERC20 token) external onlyOwner {
        require(address(token) != address(underlying), 'Cannot Withdraw Underlying Asset');
        require(address(token) != address(0), 'Zero Address');
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setCustomFee(address[] memory _id, CustomFee[] memory _item) external onlyOwner {
        for (uint256 i = 0; i < _id.length; i++) {
            customFee[_id[i]].sellFee = _item[i].sellFee;
            customFee[_id[i]].mintFee = _item[i].mintFee;
        }
    }

    function setPresale(address[] memory _id, Presale[] memory _item) external onlyOwner {
        for (uint256 i = 0; i < _id.length; i++) {
            presale[_id[i]].user = _item[i].user;
            presale[_id[i]].allocation = _item[i].allocation;
        }
    }

    /** 
        Sells Tokens On Tax Free On Behalf Of Other User Tax Free
        Prevents Locked or Inaccessible funds from appreciating indefinitely
     */
    function sellDownExternalAccount(address account) external nonReentrant onlyOwner {
        require(account != address(0), 'Zero Address');
        require(_balances[account] > 0, 'Zero Amount');

        // exempt account from fees and sell them down
        isTransferFeeExempt[account] = true;
        _sell(
            account,
            _balances[account], 
            account
        );
        isTransferFeeExempt[account] = false;

        // emit sell down event
        emit SellDownAccount(account);
    }

    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 10% ) 
    */
    function setFees(uint256 _mintFee, uint256 _transferFee, uint256 _sellFee) external onlyOwner {
        require(_mintFee >= 90000);       // capped at 10% fee
        require(_transferFee >= 90000);   // capped at 10% fee
        require(_sellFee >= 90000);       // capped at 10% fee
        
        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        emit SetFees(_mintFee, _transferFee, _sellFee);
    }
    
    /** Excludes Contract From Transfer Fees */
    function setTransferFeeExempt(address Contract, bool transferFeeExempt) external onlyOwner {
        require(Contract != address(0), 'Zero Address');
        isTransferFeeExempt[Contract] = transferFeeExempt;
        emit SetPermissions(Contract, transferFeeExempt);
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        _checkGarbageCollector(address(this));
        _mintWithNative(msg.sender, 0);
    }
    
    
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event TokenActivated(uint blockNo);
    event presaleStatus(bool flag);
    event Burn(address from, uint256 amountTokensErased);
    event GarbageCollected(uint256 amountTokensErased);
    event Redeemed(address seller, uint256 amountMDB, uint256 amountBUSD);
    event Minted(address recipient, uint256 numTokens);
    event SetPermissions(address Contract, bool feeExempt);
    event SetFees(uint mintFee, uint transferFee, uint sellFee);
    event SetFeeReceiver(address newReceiver);
    event SetFeeReceiverPercentage(uint256 newPercentage);
    event SetZapper(address newZapper);
    event SellDownAccount(address account);
}