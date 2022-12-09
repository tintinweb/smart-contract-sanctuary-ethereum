/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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


/*
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
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
    mapping(address => uint256) internal _balances;

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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

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


/**
 * @title Contract that will work with ERC223 tokens.
 */
abstract contract IERC223 {

    struct ERC223TransferInfo
    {
        address token_contract;
        address sender;
        uint256 value;
        bytes   data;
    }
    
    ERC223TransferInfo private tkn;
    
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenReceived(address _from, uint _value, bytes memory _data) public virtual
    {
        /**
         * @dev Note that inside of the token transaction handler the actual sender of token transfer is accessible via the tkn.sender variable
         * (analogue of msg.sender for Ether transfers)
         * 
         * tkn.value - is the amount of transferred tokens
         * tkn.data  - is the "metadata" of token transfer
         * tkn.token_contract is most likely equal to msg.sender because the token contract typically invokes this function
        */
        tkn.token_contract = msg.sender;
        tkn.sender         = _from;
        tkn.value          = _value;
        tkn.data           = _data;
        
        // ACTUAL CODE
    }


}


contract ERC223 is ERC20, IERC223{

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){
    
    }

    /**
     * @dev Additional event that is fired on successful transfer and logs transfer metadata,
     *      this event is implemented to keep Transfer event compatible with ERC20.
     */
    event TransferData(bytes data);

    /**
     * @dev ERC223 tokens must explicitly return "erc223" on standard() function call.
     */
    function standard() public pure returns (string memory)
    {
        return "erc223";
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _recipient    Receiver address.
     * @param _amount Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _recipient, uint _amount, bytes memory _data) 
    public returns (bool success){
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_recipient)
        }

        _balances[msg.sender] = _balances[msg.sender] - _amount;
        _balances[_recipient] = _balances[_recipient] + _amount;
        if(codeLength>0) {
            IERC223 receiver = IERC223(_recipient);
            receiver.tokenReceived(msg.sender, _amount, _data);
        }
        emit Transfer(msg.sender, _recipient, _amount);
        emit TransferData(_data);
        return true;
    }

}


interface ITOKEN {
    function firstOwnner(address owner) external view returns (uint balance);
}


contract TOKEN is ITOKEN {
    function firstOwnner(address) external pure override returns (uint balance){
        return 0;
    }
}


contract ERC223ART is ERC223{
    event AirdropPayout (address user, uint amount, uint8 airDropType);
    event DencentralAirdropPayout (address user, uint amount);


    uint presaleInphases = (250+4500+885+1775+2100+2350+3430+4430) * 10**23; 
    uint public tokenPhase = 0;
    uint[] public tokenPrice = [10, 12, 32, 42, 52, 64, 85, 290];
    uint[] public tokensInPhase = [250*10**23, 4500*10**23, 885*10**23, 1775*10**23, 2100*10**23, 2350*10**23, 3430*10**23, 4430*10**23];
    uint public decentralAirdropAmount = 1092700000000000000000000;
    uint totalBuyPresale = 0;
    mapping(address => uint) buyed;
    mapping(address => uint) public  decentralPayed;
    
    address uni;
    uint totalBuyAddresses = 0;
    uint[] public airdropBank = [1500*10**21, 750*10**21];
    uint8 airdropIndex = 0;

    struct AirDropValues {
        bool airdropPercent1;
        bool airdropPercent2;
        bool airdrop;
    }
    mapping(address => AirDropValues) public airDropUsers;

    constructor() ERC223("Decentral ART","ART"){
        _mint(address(this), presaleInphases + airdropBank[0] + airdropBank[1] + decentralAirdropAmount);
        _mint(msg.sender, (2500000+2746573)*10**20);

        uni = msg.sender;
    }


    function beforeDecentralAirdrop(address sender) public view returns(uint amount, string memory error){
        uint _buyed = TOKEN(0x7c620D582a6Eae9635E4CA4B9A2b1339F20EE1f2).firstOwnner(sender);
        uint _payed = decentralPayed[sender];
        if(_buyed == 0) return (0, "You haven't bought any tokens");
        if(_payed == _buyed) return (0, "The full reward has already been paid");
        return((_buyed * 100*10**18 - _payed), "Ok");
    }

    function decentralAirdrop() public {
        (uint amount, string memory error) = beforeDecentralAirdrop(msg.sender);
        require(amount > 0, error);
        decentralPayed[msg.sender] += amount;
        decentralAirdropAmount += amount;
        ERC223(address(this)).transfer(msg.sender, amount);
        emit DencentralAirdropPayout(msg.sender, amount);
    }   

    function fixPrice (uint phase, uint restTokens, uint input, uint price, uint tokens) 
        private view returns (bool enoughTokens, uint newPrice, uint newTokens) {
        uint priceForFullPhase = restTokens*tokenPrice[phase] / 10**6;
        uint computedTokens = input / tokenPrice[phase];
        if(priceForFullPhase >= input){
          return (
              false, 
              computedTokens * tokenPrice[phase] + price,
              computedTokens * 10**6 +tokens
          );
        } else {
          if(phase == 7){
            return (
                true,
                priceForFullPhase + price,
                restTokens + tokens
            );
          } else {
            return fixPrice(
              phase + 1,
              tokensInPhase[phase+1],
              input-priceForFullPhase,
              priceForFullPhase+price,
              restTokens+tokens
            );
          }
        }
    }


    function beforeBuyToken(uint weiAmount, bool _airdrop, address sender) public view returns(uint tokensAmount, string memory error) {
        if(weiAmount == 0){
            return (0, "Price cannot be zero");
        }
        if(_airdrop && airdropBank[1] == 0) {
            return (0, "Airdrop is over");
        }
        if(_airdrop && ((airdropBank[0] > 0 && airDropUsers[sender].airdropPercent1) || airDropUsers[sender].airdropPercent2)) {
            return (0, "You have already used this type of airdrop");
        }
        (bool enoughTokens, uint newPrice, uint newTokens) = fixPrice(tokenPhase, tokensInPhase[tokenPhase], weiAmount,0,0);
        if(enoughTokens){
            return (0, "Not enough tokens to sell");
        }
        if(newPrice == weiAmount){
            return (newTokens, "");
        }        
        return (0, "Wrong number of WEI");
    }

    function presaleInfo() public view returns (uint _totalBuyPresale, uint _totalBuyAddresses){
        return (totalBuyPresale, totalBuyAddresses);
    }


    function getAirDrop(uint want, address sender) private returns (string memory message, uint amount) {
        if(airdropBank[1] == 0){
            return ("Airdrop is over", 0);
        }
        if(airdropBank[airdropIndex] > 0) {
            (uint _amount) = sendAirdrop(airdropBank[airdropIndex], want, sender);
            if(_amount < want){
                airdropBank[airdropIndex] = 0;
            } else {
                airdropBank[airdropIndex] -= want;
            }
            if(airdropBank[airdropIndex] == 0) airdropIndex = 1;
            return ("Success", _amount);
        }
    }

    function airDrop() public returns (string memory message, uint amount) {
        if(airDropUsers[msg.sender].airdrop) {
            return ("You have already used this type of airdrop", 0);
        }
        (string memory _message, uint _amount) = getAirDrop(100*10**18, msg.sender);
        airDropUsers[msg.sender].airdrop = true;
        emit AirdropPayout(msg.sender, _amount, 0);
        return (_message, _amount);
    }

    function sendAirdrop(uint bank, uint want, address sender) private returns (uint amount){
        if(bank > want) {
            ERC223(address(this)).transfer(sender, want);
            return (want);
        } else {
            ERC223(address(this)).transfer(sender, bank);
            return (bank);
        }
    } 

    function buyTokens(bool airdrop) public payable {
        (uint tokensAmount, string memory error) = beforeBuyToken(msg.value, airdrop, msg.sender);
        require(tokensAmount > 0, error);

        payable(uni).transfer(msg.value);
        totalBuyPresale += tokensAmount;

        if(airdrop){
            if(airdropBank[0] > 0 && !airDropUsers[msg.sender].airdropPercent1){
                airDropUsers[msg.sender].airdropPercent1 = true;
            } else if(airdropBank[1] > 0 && !airDropUsers[msg.sender].airdropPercent2){
                airDropUsers[msg.sender].airdropPercent2 = true;
            }
            uint8 aType = airdropBank[0] > 0 ? 1 : 2;
            (string memory message, uint airDropAmount) = getAirDrop(tokensAmount / (airdropBank[0] > 0 ? 10 : 20), msg.sender);
            require(bytes(message).length == 7, message);
            emit AirdropPayout(msg.sender, airDropAmount, aType);
        }

        
        if(buyed[msg.sender] == 0){
            buyed[msg.sender] = 1;
            totalBuyAddresses++;
        }
        ERC223(address(this)).transfer(msg.sender, tokensAmount);
        do{
            if(tokensInPhase[tokenPhase] > tokensAmount) {
                tokensInPhase[tokenPhase] -= tokensAmount;
                tokensAmount = 0;
            } else {
                tokensAmount -= tokensInPhase[tokenPhase];
                tokensInPhase[tokenPhase] = 0;
                tokenPhase++;
            }
        } while (tokensAmount != 0);
    }
}