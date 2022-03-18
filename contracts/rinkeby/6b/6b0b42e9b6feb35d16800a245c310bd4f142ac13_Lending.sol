/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

pragma solidity 0.8.1;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
contract myToken is ERC20 {
    constructor() ERC20("Token","Token") {
        _mint(msg.sender, 100000000000000000000);
    }
}
contract floatingPointNumber{

    uint constant floatScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant one = floatScale;
    uint constant onePercent = 1e16;
}
contract Lending is floatingPointNumber{
    using SafeMath for uint;
    using SafeMath for uint;
                            ///***数据***///
    //test
    address public account1 = 0xDC629d964E3D13553112Ef9053B08C4051DcF057;
    address public account2 = 0xD4e8F5e913816FCAE2c762E4C0a7e5990ad03bec;
    address public testToken1;
    address public testKtoken1 = 0x2DB0262c69324f393737b74F2f8a71D6Fda74097;
    address public testToken2;
    address public testKtoken2 = 0xe559c0f503b6de531Af733b8833749ccfAff5BE7;

    //默认为1e18的精度
    struct tokenInfo{
        uint cash;
        uint borrow;
        uint reserve;
    }
    struct ktokenInfo{
        uint totalsupply;
        uint collateralrate;
        uint blockNumber;
        uint index;
    }
    struct debt{
        uint base;
        uint index;
    }
    struct rateModel{
        uint k;
        uint b;
    }

    //合约拥有者地址
    address public  owner;
    //用户所有Ktoken地址
    address [] public allKtoken;
    //eth地址
    address public  eth;
    //weth地址
    address public  weth;
    //初始兑换率
    uint public constant INITAL_EXCHANGERATE = 1;
    //清算率 50% 
    uint public constant LIQUIDITY_RATE = 5000;
    //清算奖励 110%
    uint public constant LIQUIDITY_REWARD = 11000;
    //利息中给reserver的比例 20%
    uint public constant RESERVER_RATE = 2000;
    //根据token地址得到token的cash、borrow
    mapping (address =>tokenInfo) public infoOfToken;
    //根据Ktoken地址得到Ktoken的储备情况
    mapping (address => ktokenInfo) public infoOfKtoken;
    //由token地址得到Ktoken地址
    mapping (address => address) public tokenToktoken;
    //由Ktoken地址得到token地址
    mapping (address => address) public ktokenTotoken;
    //得到用户未质押的Ktoken
    mapping (address => mapping(address => uint)) public ktokenUnlock;
    //得到用户质押的Ktoken
    mapping (address => mapping(address => uint)) public ktokenlock;
    //得到用户的Ktoken债务 ktoken => user => Debt
    mapping (address => mapping(address => debt)) public userDebt;
    //得到Ktoken的利息指数
    mapping (address => uint) public ktokenIndex;
    //得到用户所有token的地址
    mapping (address => address[]) public userKtoken;
    //标的资产的价格，模拟预言机的作用
    mapping (address => uint) public price;
    //得到Ktoken对应的利率模型
    mapping (address => rateModel) public ktokenModel;
    //检查是否 user=>ktoken
    mapping (address => bool) public ktokenExsis;

    event point1(bool _right);
    event point2(bool _right);
    event point3(uint _amount);
    event point4(uint _amount);
    event point5(debt _debt);
                            ///***Owner函数***///
    constructor() {
        owner = msg.sender;
        testInitial();
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner");
        _;
    }
    function testInitial() private{
        myToken erc1 = new myToken();
        myToken erc2 = new myToken();
        testToken1 = address(erc1);
        testToken2 = address(erc2);

        ERC20(erc1).transfer(account1,100000000000000000000);
        ERC20(erc2).transfer(account2,100000000000000000000);
        establishMapping(testToken1,testKtoken1);
        establishMapping(testToken2,testKtoken2);
        Initial(testToken1,100);
        Initial(testToken2,200);

    }
    //设置利率模型初始参数
    function Initial(address _token,uint _amount)public onlyOwner{
        address _ktoken = tokenToktoken[_token];
        //初始K值 = 0.01
        ktokenModel[_ktoken].k = onePercent;
        ktokenModel[_ktoken].b = 0;
        // 初始index =1
        infoOfKtoken[_ktoken].index = one;
        infoOfKtoken[_ktoken].blockNumber = block.number;
        //0.5
        infoOfKtoken[_ktoken].collateralrate = 5000;
        price[_token] = _amount;
    }
    function setParameter(address _token,uint _amount,uint _k,uint _b, uint _index,uint _collateralrate)public onlyOwner{
        address _ktoken = tokenToktoken[_token];

        ktokenModel[_ktoken].k = _k;
        ktokenModel[_ktoken].b = _b;

        infoOfKtoken[_ktoken].index = _index;
        infoOfKtoken[_ktoken].collateralrate = _collateralrate;
        price[_token] = _amount;
    }
    //建立token和ktoken的映射
    function establishMapping(address _token,address _ktoken) public onlyOwner{
        tokenToktoken[_token] = _ktoken;
        ktokenTotoken[_ktoken] = _token;
    }
    function setWethAddress(address _weth) public onlyOwner{
        weth = _weth;
    }


                            ///***主函数***///
    // 充值ERC20
    function externalTransferfrom(address token,uint _amount) public{
        IERC20(token).transferFrom(msg.sender,address(this),_amount);      
    }
    function deposit(address _token,uint _amount) public{
        //计息
        accurateInterest(_token);
        // 根据充值token数量，通过计算兑换率，获取应该返回用户的 K token的数量
        (address _kToken,uint _KTokenAmount) = getKTokenAmount(_token,_amount);
        // 转入用户的token
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        // 增加协议的Token的cash数量
        addCash(_token,_amount);
        // 给用户转入 K token 以及更新 Ktoken的总供应
        addKtoken(_kToken,msg.sender,_KTokenAmount);
    }
    // 充值ETH
    function depositETH() public payable{
        //计息
        accurateInterest(weth);
        //向WETH合约中存入用户发送的ETH
        IWETH(weth).deposit{value: msg.value}();
        address _kweth = tokenToktoken[weth];
        //增加WETH的cash数量
        addCash(weth,msg.value);
        // 根据充值token数量，通过计算兑换率，获取应该返回用户的 K token的数量
        (,uint _kwethAmount) = getKTokenAmount(weth,msg.value);
        // 给用户转入 K token
        addKtoken(_kweth,msg.sender,_kwethAmount);
    }
    // 取回
    function withdraw(address _ktoken,uint _amount) public{
        address _token = ktokenTotoken[_ktoken];
        //计息
        accurateInterest(_token);
        //验证用户是否有足够Ktoken
        require(ktokenUnlock[_ktoken][msg.sender]>=_amount,"user amount insuficient");
        //根据取出Ktoken的数量和兑换率得到标的资产数量
        uint _tokenAmount = _amount * getExchangeRate(_ktoken);
        //减少记录的cash值
        reduceCash(_token,_tokenAmount);
        //给用户转入标的资产
        IERC20(_token).transfer(msg.sender,_tokenAmount);
        //转出用户的Ktoken
        reduceKtoken(_ktoken,msg.sender,_amount);
    }
    // 取回WETH
    function withdrawETH(uint _amount)public {
        //计息
        accurateInterest(weth);
        address _kweth = tokenToktoken[weth];
        //验证用户是否有足够Kweth
        require(ktokenUnlock[_kweth][msg.sender]>_amount,"user amount insuficient");
        //weth数量 = Keth数量 * 兑换率
        uint _wethAmount = _amount * getExchangeRate(_kweth);
        //用WETH提取ETH
        IWETH(weth).withdraw(_wethAmount);
        //减少记录的cash值
        reduceCash(weth,_wethAmount);
        //向用户发送ETH
        eth.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _wethAmount));
        //转出用户的Kweth
        reduceKtoken(_kweth,msg.sender,_amount);
    }
    // 借款
    function borrow(address _token,uint _amount) public{
        //计息
        accurateInterest(_token);
        //验证用户的借款能力
        require(verifyBorrowCapacity(msg.sender,_token,_amount)>=0,"insufficient borrow capacity");
        //如果cash过小，则无法通过reduceCash中的require
        reduceCash(_token,_amount);
        addBorrow(_token,_amount);
        //增加用户债务
        addDebt(_token,msg.sender,_amount);
        //给用户转入标的资产
        IERC20(_token).transfer(msg.sender,_amount);
    
    }
    // 借ETH
    function borrowETH(uint _amount) public{
        //计息
        accurateInterest(weth);
        address _kweth = tokenToktoken[weth];
        //验证用户的借款能力
        require(verifyBorrowCapacity(msg.sender,weth,_amount)>=0,"insufficient borrow capacity");
        //提取ETH
        IWETH(weth).withdraw(_amount);
        //如果cash过小，则无法通过reduceCash中的require
        reduceCash(weth,_amount);
        addBorrow(weth,_amount);
        //增加用户债务
        addDebt(weth,msg.sender,_amount);
        //向用户发送ETH
        eth.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount));
    }
    // 还款
    function repay(address _token,uint _amount,address _borrower) public{
        //计息
        accurateInterest(_token);
        emit point1(true);
        //得到Ktoken地址
        address Ktoken = tokenToktoken[_token];
        //用户向合约转入标的资产
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        //
        reduceBorrow(_token,_amount);
        addCash(_token,_amount);
        emit point2(true);
        //减轻用户债务
        reduceDebt(_token,_borrower,_amount);
    }
    // 还ETH
    function repayETH(address _user)public payable{
        //计息
        accurateInterest(weth);
        //将用户发送的ETH存入WETH合约中
        IWETH(weth).deposit{value: msg.value}();
        //
        reduceBorrow(weth,msg.value);
        addCash(weth,msg.value);
        //减轻用户债务
        reduceDebt(weth,_user,msg.value);
    }
    // 清算
    function liquity(address _liquityAddress,address _borrower,address _token,uint _amount) public{
        //计息
        accurateInterest(_token);
        //验证borrower的净资产是否小于负债
        uint _value = verifyBorrowCapacity(msg.sender,_token,0);
        require(_value < 0 ,"enough collateral");
        //计算可以清算的标的资产数量
        (uint _tokenAmount,uint _ktokenAmount,address _ktoken) = accountLiquity(_borrower,_token);
        //为borrower偿还债务
        repay(_token,_ktokenAmount,_borrower);
        //结算清算者得到Ktoken的数量
        liquityReward(_liquityAddress,_borrower,_ktoken,_ktokenAmount);
    }
    //质押ktoken
    function lock(address _token,uint _amount)public{
        address _ktoken = tokenToktoken[_token];
        //计息
        accurateInterest(_token);
        //如果资产Ktoken不在allassert中，则添加进去
        if(ktokenExsis[_ktoken] == false){
            ktokenExsis[_ktoken] = true;
            allKtoken.push(_ktoken);
        }
        require(ktokenUnlock[_ktoken][msg.sender] >= _amount,"unlock amount insuffcient");
        addCollateral(_ktoken,msg.sender,_amount);
    }
    //解除质押ktoken
    function unlock(address _token,uint _amount)public{
        address _ktoken = tokenToktoken[_token];
        //计息
        accurateInterest(_token);

        require(ktokenlock[_ktoken][msg.sender]>=_amount,"lock amount insuffcient");
        reduceCollateral(_ktoken,msg.sender,_amount);
    }


                            ///***更新***///
    /*用户存取时更新用户未质押Ktoken的值和Ktoken的总供应量
    function renewKtoken(address _ktoken,address _user,int _amount) private{
        ktokenUnlock[_ktoken][_user] += _amount;
        infoOfKtoken[_ktoken].totalsupply += _amount;
    }*/
    //转入/转出 Ktoken
    function addKtoken(address _ktoken,address _user,uint _amount) private{
        ktokenUnlock[_ktoken][_user] += _amount;
        infoOfKtoken[_ktoken].totalsupply += _amount;
    }
    function reduceKtoken(address _ktoken,address _user,uint _amount) private{
        ktokenUnlock[_ktoken][_user] -= _amount;
        infoOfKtoken[_ktoken].totalsupply -= _amount;
    }
    /*根据标的资产地址和数量，更新用户债务的base和index
    function renewDebt(address _token,address _user,uint _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint _ktokenamount = _amount / getExchangeRate(_ktoken);
        uint _oldDebt = getOneDebtVaule()
        //debt memory new_debt;
        //更新用户债务
        debt memory old_debt = getNowDebtAmount(_user,_ktoken);
        debt memory new_debt;
        new_debt.base = old_debt.base + _ktokenamount;
        new_debt.index = ktokenIndex[_ktoken];
        userDebt[_ktoken][_user] = new_debt;
    }*/
    function addDebt(address _token,address _user,uint _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint _ktokenAmount = _amount / getExchangeRate(_ktoken);
        //增加用户Ktoken债务：新债务 = 老债务本息合 + 借走的Ktoken数量
        uint _oldDebtAmount = getOneDebtAmount(_user,_token);
        debt memory _newDebt;
        _newDebt.base = _oldDebtAmount + _ktokenAmount;
        _newDebt.index = infoOfKtoken[_ktoken].index;
        userDebt[_ktoken][_user] = _newDebt;
    }
    function reduceDebt(address _token,address _user,uint _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint _ktokenAmount = _amount / getExchangeRate(_ktoken);
        emit point3(_ktokenAmount);
        //减少用户Ktoken债务：新债务 = 老债务本息合 - 偿还的的Ktoken数量
        uint _oldDebtAmount = getOneDebtAmount(_user,_token);
        emit point4(_oldDebtAmount);
        debt memory _newDebt;
        _newDebt.base = _oldDebtAmount - _ktokenAmount;
        _newDebt.index = infoOfKtoken[_ktoken].index;
        emit point5(_newDebt);
        userDebt[_ktoken][_user] = _newDebt;
    }


                            ///***辅助计算函数***///
    //token和Ktoken的兑换率= (borrow+cash-reserve)/totalsupply
    function getExchangeRate(address _ktoken) public view returns(uint _exchangerate){
        address _token = ktokenTotoken[_ktoken];
        ktokenInfo memory ktokeninfo=infoOfKtoken[_ktoken];
        tokenInfo memory tokeninfo = infoOfToken[_token];
        if(ktokeninfo.totalsupply == 0){
            _exchangerate = INITAL_EXCHANGERATE;
        }
        else{
            _exchangerate =(tokeninfo.borrow + tokeninfo.cash-tokeninfo.reserve)/ktokeninfo.totalsupply;
        }
        return _exchangerate;
    }
    //得到用户当欠的Ktoken数量
    function getOneDebtAmount(address _user,address _ktoken) public view returns (uint _nowamount){
        debt memory debt = userDebt[_ktoken][_user];
        if(debt.index == 0){
            _nowamount = 0;
        }
        else{
            _nowamount = debt.base * infoOfKtoken[_ktoken].index / debt.index; 
        }
        return _nowamount;
    }
    //得到用户欠的某一ktoken价值
    function getOneDebtVaule(address _user,address _ktoken)  public view returns(uint _nowDebt){
        //得到token地址
        address _token = ktokenTotoken[_ktoken];    
        //计算此时所欠的Ktoken数量
        uint _amount = getOneDebtAmount(_user,_ktoken);
        //债务 = ktoken数量 * 兑换率 * token价格
        _nowDebt = _amount * getExchangeRate(_ktoken) * price[_token];
        return _nowDebt;
    }
    //得到用户所欠的所有ktoken价值
    function getAllDebtVaule(address _user)  public view returns(uint _alldebt){
        //得到所有Ktoken
        address[] memory _allKtoken = allKtoken;
        //循环执行getOneDebtVaule函数，得到总债务
        for(uint i =0;i < _allKtoken.length;i++){
            debt memory debt = userDebt[_allKtoken[i]][_user];
            if(debt.base == 0) break;
            _alldebt+=getOneDebtVaule(_user,_allKtoken[i]);
        }
        return _alldebt;
    }
    // 根据转入的token数量，计算返回的kToken数量
    function getKTokenAmount(address _token,uint _amount) public view returns(address,uint){
        address _ktoken = tokenToktoken[_token];
        uint _ktokenAmount = _amount / getExchangeRate(_ktoken);
        return(_ktoken,_ktokenAmount);
    }
    //得到用户的总质押物价值
    function getUserCollateralValue(address _user)public view returns(uint _sumvalue){
        //得到用户所有Ktoken地址
        address[] memory _allKtoken = allKtoken;
        //求质押的总价值
        for(uint i = 0;i<_allKtoken.length;i++){
            //由ktoken地址得到token地址
            address _token = ktokenTotoken[_allKtoken[i]];
            //得到质押的Ktoken数量
            uint _amount = ktokenlock[_allKtoken[i]][_user];
            //总价格 = sum{Ktoken数量 * 兑换率 * token价格 * 质押率}
            _sumvalue += _amount * getExchangeRate(_allKtoken[i]) * price[_token] * infoOfKtoken[_allKtoken[i]].collateralrate /10000;
        }
        return _sumvalue;
    }
    //计算可清算最大标的资产数量
    function accountLiquity(address _borrowAddress, address _token)public view returns(uint _amount,uint _ktokenAmount,address _ktoken){
        _ktoken = tokenToktoken[_token];
        //得到Ktoken债务
        _ktokenAmount = getOneDebtAmount(_borrowAddress,_ktoken) * LIQUIDITY_RATE / 1000;
        //得到token债务
        _amount = _ktokenAmount * getExchangeRate(_ktoken);
        return(_amount,_ktokenAmount,_ktoken);
    }
    //得到token的当前借贷利率
    function getBorrowRate(address _token)public view returns(uint _borrowRate){
        address _ktoken = tokenToktoken[_token];
        uint _borrow = infoOfToken[_token].borrow;
        uint _cash = infoOfToken[_token].cash;
        uint interResult;

        // y = kx + b, x为资金利用率
            //k为18位精度  0.01 . UseRate也是18位 borrrowrate
        interResult = ktokenModel[_ktoken].k * getUseRate(_borrow,_cash);
        _borrowRate = ktokenModel[_ktoken].k * getUseRate(_borrow,_cash)  + ktokenModel[_ktoken].b;
        return _borrowRate;
    }
    //得到当前资金利用率 cash不可能是负数，所以分母不可能为0，div不作错误判断
    //为了保留输出的精度*18e
    function getUseRate(uint _borrow,uint _cash)public view returns(uint){
        if (_borrow == 0) {
            return 0;
        }
        return _borrow.mul(1e18).div(_borrow.add(_cash));
    }
    //根据区块变化和先前的利息指数得到新的利息指数
    function getNowIndex(uint _oldIndex,uint _deltaTime,address _ktoken) public view returns(uint _newIndex){
        uint _borrowRate = getBorrowRate(_ktoken);
        uint inter = _deltaTime * _borrowRate ;
        if(inter != 0){
            _newIndex = _oldIndex * inter / 1e36;
        }
        else{
            _newIndex = _oldIndex;
        }
        return _newIndex;
    }


                            ///***改变状态变量的函数***///
    //根据liquidity偿还的ktoken数量，从借款者向清算者转移ktoken
    function liquityReward(address _liquidity,address _borrower,address _ktoken,uint _amount) private {
        uint _actualamount = _amount * LIQUIDITY_REWARD /1000;
        ktokenUnlock[_ktoken][_borrower]-=_actualamount;
        ktokenUnlock[_ktoken][_liquidity]+=_actualamount;
    }
    //
    function addCollateral(address _ktoken,address _user,uint _amount) private {
        ktokenlock[_ktoken][_user]+=_amount;
        ktokenUnlock[_ktoken][_user]-=_amount;
    }
    function reduceCollateral(address _ktoken,address _user,uint _amount) private {
        ktokenlock[_ktoken][_user] -= _amount;
        ktokenUnlock[_ktoken][_user] += _amount;
    }

    function addCash(address _token,uint _amount)private{
        uint _cashNow = infoOfToken[_token].cash;
        require((_cashNow + _amount) >=_amount && (_cashNow +_amount) >=_amount,"amount too big");
        infoOfToken[_token].cash += _amount;
    }
    function reduceCash(address _token,uint _amount)private{
        uint _cashNow = infoOfToken[_token].cash;
        require(_cashNow > _amount,"cash insufficient");
        infoOfToken[_token].cash -= _amount;
    }
    function addBorrow(address _token,uint _amount) private{
        uint _borrowNow = infoOfToken[_token].borrow;
        infoOfToken[_token].borrow = _borrowNow + _amount;
    }
    function reduceBorrow(address _token,uint _amount) private{
        uint _borrowNow = infoOfToken[_token].borrow;
        require(_borrowNow >= _amount,"too much");
        infoOfToken[_token].borrow -= _amount;
    }


                            ///***验证函数***///
    //验证用户的（总质押物价值-总债务）>=所借金额
    function verifyBorrowCapacity(address _user,address _token,uint _amount) public view returns(uint){
        //要借的价值
        uint _borrowValue = _amount * price[_token];
        //总质押物价值
        uint _collateralValue = getUserCollateralValue(_user);
        //总债务价值
        address _ktoken = tokenToktoken[_token];
        uint _allDebt = getAllDebtVaule(_user);
        //返回净值
        return(_collateralValue - _allDebt - _borrowValue);
    }
                            ///***计息***///
    function accurateInterest(address _token)public {

        //节省gas
        address _ktoken = tokenToktoken[_token];
        ktokenInfo memory _ktokenInfo = infoOfKtoken[_ktoken];
        tokenInfo memory _tokenInfo = infoOfToken[_token];

        uint _borrow = _tokenInfo.borrow;
        uint _reserve = _tokenInfo.reserve;
        uint _oldIndex =_ktokenInfo.index;

        //得到变化的区块数量
        uint _blockNumberNow = block.number;
        (bool returnMessage,uint _deltaBlock) = _blockNumberNow.trySub(_ktokenInfo.blockNumber);
        require(returnMessage == true,"deltaBlock error!");

        if(_deltaBlock != 0){
            //更新blockNumber和index
            infoOfKtoken[_ktoken].blockNumber = _blockNumberNow;
            infoOfKtoken[_ktoken].index = getNowIndex(_ktokenInfo.index,_deltaBlock,_ktoken);
            //利息 = borrow * （_newindex/_oldIndex）
            if(_borrow != 0){
                renewTokenInfo(_token,_borrow,_reserve,_ktokenInfo.index,_oldIndex);
            }

        }
    }
    function renewTokenInfo(address _token,uint _borrow,uint _reserve,uint _index,uint _oldIndex) internal{
        uint _interest = _borrow * _index / _oldIndex;
        _reserve += _interest * RESERVER_RATE / 10000;
        _borrow += _interest * (10000 - RESERVER_RATE) / 10000;
        infoOfToken[_token].reserve = _reserve;
        infoOfToken[_token].borrow  = _borrow;
    }

}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
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
    function mul(uint a, uint b) internal pure returns (uint) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}