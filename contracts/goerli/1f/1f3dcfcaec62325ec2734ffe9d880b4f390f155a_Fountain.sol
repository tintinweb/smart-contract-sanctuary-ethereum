/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'no whitelist');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
        return success;
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     */
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is IERC20, Whitelist {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    event Mint(address indexed to, uint256 amount);

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }



    function _mint(address _to, uint256 _amount)  onlyWhitelisted internal {
        require(_to != address(0));
        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IToken {
    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

interface HexToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Fountain is ERC20 {

    string public constant name = "EARTH LP-V0";
    string public constant symbol = "LP-V0";
    uint8 public constant decimals = 18;
    HexToken private hexToken = HexToken(0x263cc10F71BEDBC9eEAde45a53bd34835AaCC19a);
    address private _reservoir;
    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    // Variables
    IToken internal token; // address of the BEP20 token traded on this contract
    uint256 public totalTxs;

    uint256 internal lastBalance_;
    uint256 internal trackingInterval_ = 1 minutes;
    uint256 public providers;

    mapping (address => bool) internal _providers;
    mapping (address => uint256) internal _txs;

    bool public isPaused = true;

    // Events
    event onTokenPurchase(address indexed buyer, uint256 indexed bnb_amount, uint256 indexed token_amount);
    event onBnbPurchase(address indexed buyer, uint256 indexed token_amount, uint256 indexed bnb_amount);
    event onAddLiquidity(address indexed provider, uint256 indexed bnb_amount, uint256 indexed token_amount);
    event onRemoveLiquidity(address indexed provider, uint256 indexed bnb_amount, uint256 indexed token_amount);
    event onLiquidity(address indexed provider, uint256 indexed amount);
    event onContractBalance(uint256 balance);
    event onPrice(uint256 price);
    event onSummary(uint256 liquidity, uint256 price);


    /***********************************|
    |            Constructor            |
    |__________________________________*/
    constructor (address token_addr) Ownable() public {
        token = IToken(token_addr);
        lastBalance_= now;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }


    /***********************************|
    |        Exchange Functions         |
    |__________________________________*/


    /**
     * @notice 
     */
    receive() external payable {

    }

    /**
      * @dev Pricing function for converting between BNB && Tokens.
      * @param input_amount Amount of BNB or Tokens being sold.
      * @param input_reserve Amount of BNB or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of BNB or Tokens (output type) in exchange reserves.
      * @return Amount of BNB or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
        uint256 input_amount_with_fee = input_amount.mul(990);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator / denominator;
    }

    /**
      * @dev Pricing function for converting between BNB && Tokens.
      * @param output_amount Amount of BNB or Tokens being bought.
      * @param input_reserve Amount of BNB or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of BNB or Tokens (output type) in exchange reserves.
      * @return Amount of BNB or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 numerator = input_reserve.mul(output_amount).mul(1000);
        uint256 denominator = (output_reserve.sub(output_amount)).mul(990);
        return (numerator / denominator).add(1);
    }

    function bnbToTokenInput(uint256 bnb_sold, uint256 min_tokens, address buyer, address recipient) private returns (uint256) {
        require(bnb_sold > 0 && min_tokens > 0, "sold and min 0");

        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getInputPrice(bnb_sold, (hexToken.balanceOf(address(this))*1e10).sub(bnb_sold), token_reserve);

        require(tokens_bought >= min_tokens, "tokens_bought >= min_tokens");
        require(hexToken.transferFrom(msg.sender, address(this), bnb_sold/1e10));
        require(token.transfer(recipient, tokens_bought), "transfer err");

        emit onTokenPurchase(buyer, bnb_sold, tokens_bought);
        emit onContractBalance(bnbBalance());

        trackGlobalStats();

        return tokens_bought;
    }

    /**
     * @notice Convert BNB to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function bnbToTokenSwapInput(uint256 hexAmount, uint256 min_tokens) public isNotPaused returns (uint256) {
        return bnbToTokenInput(hexAmount, min_tokens,msg.sender, msg.sender);
    }

    function bnbToTokenOutput(uint256 tokens_bought, uint256 max_bnb, address buyer, address recipient) private returns (uint256) {
        require(tokens_bought > 0 && max_bnb > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 bnb_sold = getOutputPrice(tokens_bought, (hexToken.balanceOf(address(this))*1e10).sub(max_bnb), token_reserve);
        // Throws if bnb_sold > max_bnb
        uint256 bnb_refund = max_bnb.sub(bnb_sold);
        if (bnb_refund > 0) {
            payable(buyer).transfer(bnb_refund);
        }
        require(hexToken.transferFrom(msg.sender, address(this), max_bnb/1e10));
        require(token.transfer(recipient, tokens_bought));
        emit onTokenPurchase(buyer, bnb_sold, tokens_bought);
        trackGlobalStats();
        return bnb_sold;
    }

    /**
     * @notice Convert BNB to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of BNB sold.
     */
    function bnbToTokenSwapOutput(uint256 hexAmount, uint256 tokens_bought) public payable isNotPaused returns (uint256) {
        return bnbToTokenOutput(tokens_bought, hexAmount, msg.sender, msg.sender);
    }

    function tokenToBnbInput(uint256 tokens_sold, uint256 min_bnb, address buyer, address recipient) private returns (uint256) {
        require(tokens_sold > 0 && min_bnb > 0);
        uint256 token_reserve = token.balanceOf(address(this));

        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);

        uint256 bnb_bought = getInputPrice(realized_sold, token_reserve, hexToken.balanceOf(address(this))*1e10);
        require(bnb_bought >= min_bnb);
        hexToken.transfer(recipient, bnb_bought/1e10);
        require(token.transferFrom(buyer, address(this), tokens_sold));
        emit onBnbPurchase(buyer, tokens_sold, bnb_bought);
        trackGlobalStats();
        return bnb_bought;
    }

    /**
     * @notice Convert Tokens to BNB.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_bnb Minimum BNB purchased.
     * @return Amount of BNB bought.
     */
    function tokenToBnbSwapInput(uint256 tokens_sold, uint256 min_bnb) public isNotPaused returns (uint256) {
        return tokenToBnbInput(tokens_sold, min_bnb, msg.sender, msg.sender);
    }

    function tokenToBnbOutput(uint256 bnb_bought, uint256 max_tokens, address buyer, address recipient) private returns (uint256) {
        require(bnb_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_sold = getOutputPrice(bnb_bought, token_reserve, hexToken.balanceOf(address(this))*1e10);

        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);
        tokens_sold += taxAmount;

        // tokens sold is always > 0
        require(max_tokens >= tokens_sold, 'max tokens exceeded');
        hexToken.transfer(recipient, bnb_bought/1e10);
        require(token.transferFrom(buyer, address(this), tokens_sold));
        emit onBnbPurchase(buyer, tokens_sold, bnb_bought);
        trackGlobalStats();

        return tokens_sold;
    }

    /**
     * @notice Convert Tokens to BNB.
     * @dev User specifies maximum input && exact output.
     * @param bnb_bought Amount of BNB purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToBnbSwapOutput(uint256 bnb_bought, uint256 max_tokens) public isNotPaused returns (uint256) {
        return tokenToBnbOutput(bnb_bought, max_tokens, msg.sender, msg.sender);
    }

    function trackGlobalStats() private {

        uint256 price = getBnbToTokenOutputPrice(1e18);
        uint256 balance = bnbBalance();

        if (now.safeSub(lastBalance_) > trackingInterval_) {

            emit onSummary(balance * 2, price);
            lastBalance_ = now;
        }

        emit onContractBalance(balance);
        emit onPrice(price);

        totalTxs += 1;
        _txs[msg.sender] += 1;
    }


    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for BNB to Token trades with an exact input.
     * @param bnb_sold Amount of BNB sold.
     * @return Amount of Tokens that can be bought with input BNB.
     */
    function getBnbToTokenInputPrice(uint256 bnb_sold) public view returns (uint256) {
        require(bnb_sold > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        return getInputPrice(bnb_sold, hexToken.balanceOf(address(this))*1e10, token_reserve);
    }

    /**
     * @notice Public price function for BNB to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of BNB needed to buy output Tokens.
     */
    function getBnbToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
        require(tokens_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 bnb_sold = getOutputPrice(tokens_bought, hexToken.balanceOf(address(this))*1e10, token_reserve);
        return bnb_sold;
    }

    /**
     * @notice Public price function for Token to BNB trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of BNB that can be bought with input Tokens.
     */
    function getTokenToBnbInputPrice(uint256 tokens_sold) public view returns (uint256) {
        require(tokens_sold > 0, "token sold < 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 bnb_bought = getInputPrice(tokens_sold, token_reserve, hexToken.balanceOf(address(this))*1e10);
        return bnb_bought;
    }

    /**
     * @notice Public price function for Token to BNB trades with an exact output.
     * @param bnb_bought Amount of output BNB.
     * @return Amount of Tokens needed to buy output BNB.
     */
    function getTokenToBnbOutputPrice(uint256 bnb_bought) public view returns (uint256) {
        require(bnb_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        return getOutputPrice(bnb_bought, token_reserve, hexToken.balanceOf(address(this))*1e10);
    }

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address) {
        return address(token);
    }

    function bnbBalance() public view returns (uint256) {
        return hexToken.balanceOf(address(this))*1e10;
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getBnbToLiquidityInputPrice(uint256 bnb_sold) public view returns (uint256){
        require(bnb_sold > 0);
        uint256 token_amount = 0;
        uint256 total_liquidity = totalSupply();
        uint256 bnb_reserve = hexToken.balanceOf(address(this))*1e10;
        uint256 token_reserve = token.balanceOf(address(this));
        token_amount = (bnb_sold.mul(token_reserve) / bnb_reserve).add(1);
        uint256 liquidity_minted = bnb_sold.mul(total_liquidity) / bnb_reserve;

        return liquidity_minted;
    }

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256){
        uint256 total_liquidity = totalSupply();
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 bnb_amount = amount.mul(hexToken.balanceOf(address(this))*1e10) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        return (bnb_amount, token_amount);
    }

    function setReservoir(address reservoir) public onlyOwner returns (address) {
        _reservoir = reservoir;
        return reservoir;
    }

    function txs(address owner) public view returns (uint256) {
        return _txs[owner];
    }

    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit BNB && Tokens (token) at current ratio to mint SWAP tokens.
     * @dev min_liquidity does nothing when total SWAP supply is 0.
     * @param min_liquidity Minimum number of DROPS sender will mint if total DROP supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total DROP supply is 0.
     * @return The amount of SWAP minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 amountt, uint256 max_tokens) isNotPaused public returns (uint256) {
        require(max_tokens > 0 && amountt > 0, 'Swap#addLiquidity: INVALID_ARGUMENT');
        require(hexToken.transferFrom(msg.sender, address(this), amountt/1e10));
        uint256 total_liquidity = totalSupply();

        uint256 token_amount = 0;

        if (_providers[msg.sender] == false){
            _providers[msg.sender] = true;
            providers += 1;
        }

        if (total_liquidity > 0) {
            require(min_liquidity > 0);
            uint256 bnb_reserve = (hexToken.balanceOf(address(this))*1e10).sub(amountt);
            uint256 token_reserve = token.balanceOf(address(this));
            token_amount = (amountt.mul(token_reserve) / bnb_reserve).add(1);
            uint256 liquidity_minted = amountt.mul(total_liquidity) / bnb_reserve;

            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity);
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            _totalSupply = total_liquidity.add(liquidity_minted);
            require(token.transferFrom(msg.sender, address(this), token_amount));

            emit onAddLiquidity(msg.sender, amountt, token_amount);
            emit onLiquidity(msg.sender, balanceOf(msg.sender));
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;

        } else {
            require(amountt >= 1e8, "INVALID_VALUE");
            token_amount = max_tokens;
            uint256 initial_liquidity = hexToken.balanceOf(address(this))*1e10;
            _totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;
            require(token.transferFrom(msg.sender, address(this), token_amount));

            emit onAddLiquidity(msg.sender, amountt, token_amount);
            emit onLiquidity(msg.sender, balanceOf(msg.sender));
            emit Transfer(address(0), msg.sender, initial_liquidity);
            return initial_liquidity;
        }
    }


    /**
     * @dev Burn SWAP tokens to withdraw BNB && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_bnb Minimum BNB withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of BNB && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_bnb, uint256 min_tokens) onlyWhitelisted public returns (uint256, uint256) {
        require(amount > 0 && min_bnb > 0 && min_tokens > 0);
        uint256 total_liquidity = totalSupply();
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 bnb_amount = amount.mul(hexToken.balanceOf(address(this))*1e10) / total_liquidity;

        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(bnb_amount >= min_bnb && token_amount >= min_tokens);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = total_liquidity.sub(amount);
        require(hexToken.transfer(msg.sender, bnb_amount/1e10));
        require(token.transfer(msg.sender, token_amount));
        emit onRemoveLiquidity(msg.sender, bnb_amount, token_amount);
        emit onLiquidity(msg.sender, balanceOf(msg.sender));
        emit Transfer(msg.sender, address(0), amount);
        return (bnb_amount, token_amount);
    }
}