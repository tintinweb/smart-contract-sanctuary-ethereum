/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// File: MultiTokenPurchase.sol


pragma solidity ^0.8.4;


contract MultiPaymentPurchase {

    IERC20 public _Token_Def; // PLcoin
    bool public _SM_Active;

    // IERC20 coin 
    struct TokenPayment{
        IERC20 _address;
        bool _Status_Buy;
        bool _Status_Sell;
    }

    // Default Coin
    bool public _Status_Def_Buy;
    bool public _Status_Def_Sell;

    // Min Amount to transaction he so 1
    uint public _Min_Buy_Amount;
    uint public _Min_Sell_Amount;

    address[] public address_Tokens_Array;
    mapping(uint => TokenPayment) public listTokenPayment;
    address public owner;

    constructor(address[] memory tokenAddresses, address _token_def){
        owner = msg.sender;
        _Token_Def = IERC20(_token_def);
        _SM_Active = true;

        // check input length
        require(tokenAddresses.length > 0, "");

        // default coin status 
        _Status_Def_Buy = true;
        _Status_Def_Sell = true;

        // ex: buy is 1bnb = 100 PLCoin, sell 110 coin = 1bnb.
        for(uint order=0; order<tokenAddresses.length; order++){
            address_Tokens_Array.push(tokenAddresses[order]);
            listTokenPayment[order] = TokenPayment(
                IERC20(tokenAddresses[order]), true, true
            );
        }
    }
// ==================4.5 update owner ==========================

    // check master modidifier
    modifier checkMaster(){
        require(msg.sender == owner, "Sorry, you are not allowed");
        _;
    }

    // thay đổi master của sm 
    function changeOwner(address newOwner) public checkMaster {
        owner = newOwner;
    }

    // view owner
     function getOwner() external view returns (address) {
        return owner;
    }


// ===================== BUY ===========================

    event Event_buyWith_Default_Token(uint indexed idTransaction, address sender, uint value,uint _ratio_buy);

    // 4.1.1 nhận bằng coin default BNB   _ratio_buy he so 10**18
    function buyWith_Default_Token(uint idTransaction , uint _ratio_buy) public payable{
        require(_SM_Active == true && _Status_Def_Buy == true, "000");
        require(msg.value * _ratio_buy/1000000000000000000 >= _Min_Buy_Amount*1000000000000000000, "000");
        emit Event_buyWith_Default_Token(idTransaction, msg.sender, msg.value, _ratio_buy);
    }

    //  4.1.2 nhận bằng đồng # default  1*10**18 shiba = 2*10**18 PLcoin
    function buy_by_token(uint ordering, uint amount, uint _ratio_buy) public {
        require(_SM_Active == true && listTokenPayment[ordering]._Status_Buy == true, "000");
        require(amount * _ratio_buy > _Min_Buy_Amount*1000000000000000000, "000");
        require(listTokenPayment[ordering]._address.allowance(msg.sender, address(this)) >= amount*1000000000000000000, "000");
        require(listTokenPayment[ordering]._address.balanceOf(msg.sender) >= amount*1000000000000000000, "000");
        listTokenPayment[ordering]._address.transferFrom(msg.sender, address(this), amount*1000000000000000000);
    }

    event Event_Sent_PLtoken(uint indexed idTransaction, address spender, uint amountToken);
    // 4.2. chuyển PLcoin tới user khi buy amountToken he so 10**18
    function sent_PLtoken(address[] memory spender, uint[] memory amountToken, uint[] memory idTransaction) public checkMaster{
        require(spender.length == amountToken.length, "000");
        for(uint i = 0; i< amountToken.length; i++){
            require(amountToken[i] >= _Min_Buy_Amount*1000000000000000000, "000");
        }
        for(uint j = 0; j < spender.length; j++){
            _Token_Def.transfer(spender[j], amountToken[j]);
            emit Event_Sent_PLtoken(idTransaction[j], spender[j], amountToken[j]);
        }
    }

// ===================== SELL ====================================
    // 4.3. nhận PLCoin khi user bán  sell amountToken he so 10**18
    function Sell_Token_def(uint amountToken, uint ordering) public {
        require(_SM_Active == true && listTokenPayment[ordering]._Status_Sell, "000");
        require(amountToken > _Min_Sell_Amount*1000000000000000000, "000");
        require(_Token_Def.allowance(msg.sender, address(this)) >= amountToken, "000");
        require(_Token_Def.balanceOf(msg.sender) >= amountToken, "");
        _Token_Def.transferFrom(msg.sender, address(this), amountToken);
    }

    // 4.4.1 chuyển đồng default BNB tới user  back bnb amountMoney he so 10*18
    function backToSpender(address seller, uint amountMoney) public checkMaster{
        require(address(this).balance > amountMoney , "[001]");
        payable(seller).transfer(address(this).balance);
    }

    // 4.4.2 chuyển đồng # default tới user amount he so 18 
    function backSpecifyTokenToSender(address seller, uint ordering, uint amount) public checkMaster{
        require(listTokenPayment[ordering]._address.balanceOf(address(this)) > amount);
        listTokenPayment[ordering]._address.transfer(seller, amount);
    }
// ======================= 4.8 withdraw ===============================

    // rút toàn bộ BNB
    function withdraw_money_all() public checkMaster{
        require(address(this).balance>0, "[000]");
        payable(owner).transfer(address(this).balance);
    }

    // từ 1 phần bnb 
    function withdraw_money_amount(uint amount) public checkMaster{
        require(address(this).balance>0, "[000]");
        require(address(this).balance > amount , "[001]");
        payable(owner).transfer(address(this).balance);
    }

    // rút toàn bộ các coin khác BNB và khác PLcoin
    function withdraw_by_token_alll(uint ordering) public checkMaster{
        listTokenPayment[ordering]._address.transfer(owner, listTokenPayment[ordering]._address.balanceOf(address(this)));
    }

    // rút 1 phần các coin khác BNB và khác PLcoin
    function withdraw_by_token_amount(uint ordering, uint amount)public checkMaster{
        require(listTokenPayment[ordering]._address.balanceOf(address(this)) > 0, "[019]");
        require(amount*10**18 < listTokenPayment[ordering]._address.balanceOf(address(this)), "[020]");
        listTokenPayment[ordering]._address.transfer(owner, amount*10**18);
    }

    // rút toàn bộ coin PLcoin
    function withdraw_by_PLCoin_alll(uint ordering) public checkMaster{
        _Token_Def.transfer(owner, listTokenPayment[ordering]._address.balanceOf(address(this)));
    }

    // rút 1 phần coin PLcoin
    function withdraw_by_PLcoin_amount(uint ordering, uint amount)public checkMaster{
        require(listTokenPayment[ordering]._address.balanceOf(address(this)) > 0, "[019]");
        require(amount*10**18 < listTokenPayment[ordering]._address.balanceOf(address(this)), "[020]");
        _Token_Def.transfer(owner, amount*10**18);
    }

// =========================4.7 update token  ========
    // thêm vào 1 coin mới 
    function add_new_token_for_payment(address _newTokenAddress, bool _newBuyStatus, bool _newSellStatus) public checkMaster{
        address_Tokens_Array.push(_newTokenAddress);
        listTokenPayment[address_Tokens_Array.length] = TokenPayment(
            IERC20(_newTokenAddress), _newBuyStatus, _newSellStatus
        );
    }

    // update trạng thái buy và bán của coin đó 
    function update_token_for_payment(uint ordering, bool _newBuyStatus, bool _newSellStatus) public checkMaster{
        listTokenPayment[ordering]._Status_Buy = _newBuyStatus;
        listTokenPayment[ordering]._Status_Sell = _newSellStatus;
    }

// =========================4.6 update token PLcoin========

    // update trạng thái
    function update_Token_Def_status(bool _newBuyStatus, bool _newSellStatus) public checkMaster{
        _Status_Def_Buy = _newBuyStatus;
        _Status_Def_Sell = _newSellStatus;
    }

    // update all
    function update_Token_Def(address newAddr, bool _newBuyStatus, bool _newSellStatus) public checkMaster {
        _Token_Def = IERC20(newAddr);
        _Status_Def_Buy = _newBuyStatus;
        _Status_Def_Sell = _newSellStatus;
    }

    // update min . max transaction
    function update_min_amount(uint _min_buy, uint _min_sell) public {
        _Min_Buy_Amount = _min_buy;
        _Min_Sell_Amount = _min_sell;
    }

    // update stop all transaction 
    function update_SM_active(bool active)public checkMaster{
        _SM_Active = active;
    }

 // ================ 4.9 check balance =============================
    // số dư BNB
    function balanceOfDefault() public view returns(uint){
        return address(this).balance;
    }

    // số dự các coin giao dịch
    function balanceOfOtherCoin(uint ordering) public view returns(uint){
        return listTokenPayment[ordering]._address.balanceOf(address(this));
    }

    // số dư PLcoin
    function balanceOfPLcoin() public view returns(uint){
        return _Token_Def.balanceOf(address(this));
    }
// ================= 4.10 view ====================================

    // lấy thông tin của 1 token 
    function getInformationOfToken(uint ordering) public view returns(address, bool, bool){
        return (address_Tokens_Array[ordering], listTokenPayment[ordering]._Status_Buy,
         listTokenPayment[ordering]._Status_Sell);
    }

    // address của Plcoin và trạng thái 
    function getInformationTokenDef() public view returns(address, bool, bool){
        return (address(_Token_Def), _Status_Def_Buy, _Status_Def_Sell);
    }

}