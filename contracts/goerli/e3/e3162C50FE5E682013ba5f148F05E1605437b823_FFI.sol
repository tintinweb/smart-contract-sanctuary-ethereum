/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

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

contract FFI is ERC20 {

    
    struct User {
        address parent;
        uint time;
        uint64 faucetNum;
        bool isUsed ;
    }
    struct FaucetParam  {
        uint64 faucetTotalNum;
        uint64 faucetNum;
        uint64 faucetMaxNum;
        bool faucetStatus;
    }
    struct Relation {
        mapping(address => User) users;
        address[] userAddress;
        uint256 minRelationAmount;
        address queryAddress;
    }
    
    address internal owner;                                //合约创建者
    address internal approveAddress;                       //授权地址
    FaucetParam param;
    Relation relation;

    
    constructor() ERC20("FFI", "FFI") {
        owner = msg.sender;
        param = FaucetParam({
            faucetTotalNum: 10000000,
            faucetNum : 100,
            faucetMaxNum : 1000,
            faucetStatus : true
        });
        relation.minRelationAmount = tokenNum(1) / 10;
        relation.queryAddress = 0x1c35BAcFc4d7570200c551C14768bD182150FB23;

        // 测试        
        test();
    }

    function test() private {
        newUser(0xE4509B94ea0400A8A54947b70222cB21f1e103FC,0x18e9bAb51FD57E6c0D5Fc84B6a42B46133425A29);
        newUser(0x676CF79b2080c241fA3199181D096C5b596D8f37,0xE4509B94ea0400A8A54947b70222cB21f1e103FC);
        newUser(0x676CF79b2080c241fA3199181D096C5b596D8f37,0xD2c3A30bd7f21E57B7F18Ba02b427f6Ac8653dDb);
        newUser(0xF6A1425A32F9da08B530a3638F21EB6007b13479,0x676CF79b2080c241fA3199181D096C5b596D8f37);
        newUser(0xf5A123C5d331aEecC20Bf78a8b2F7015a5d9E7d1,0xF6A1425A32F9da08B530a3638F21EB6007b13479);
        newUser(0x37ec7D20B90fB97011B773bA9aEf4D8A20E94201,0xf5A123C5d331aEecC20Bf78a8b2F7015a5d9E7d1);
        newUser(0x89e58F87dC7463dd74d590A261BB5C00600e74F0,0x37ec7D20B90fB97011B773bA9aEf4D8A20E94201);
        newUser(0x201184Fa51D44283a035303468aD93D83e2d273f,0x89e58F87dC7463dd74d590A261BB5C00600e74F0);
        newUser(0xd8d810499d13A073E5182C481a8e41c69aa8F429,0x201184Fa51D44283a035303468aD93D83e2d273f);
        newUser(0xBfA0C27ccCA82CBc013C693cEdF7b2fCc15694e2,0xd8d810499d13A073E5182C481a8e41c69aa8F429);
        newUser(0xcCc321E7B1Cc80e51B8023dA5E610562c39c6d32,0xBfA0C27ccCA82CBc013C693cEdF7b2fCc15694e2);
        newUser(0xd6A5D29Ddf9cFf1E9b822e4aC4cd8A942450300D,0xcCc321E7B1Cc80e51B8023dA5E610562c39c6d32);
        newUser(0x47F3a4273BC7BFDE021D816a63B2ECFaC52e0487,0xd6A5D29Ddf9cFf1E9b822e4aC4cd8A942450300D);
        newUser(0x7163472e096fF27008743CD0C12a11FB30Abc176,0x47F3a4273BC7BFDE021D816a63B2ECFaC52e0487);
        newUser(0x96bCc332F3443C667E79cE1d3107Cdb6efF9B8A5,0x7163472e096fF27008743CD0C12a11FB30Abc176);
        newUser(0xD0f1F67217f98b99317C14E0e0E38fDaaA7E491b,0x96bCc332F3443C667E79cE1d3107Cdb6efF9B8A5);
        newUser(0xFD17D3D30fe80f11e7c0059241DB90EC47a51335,0xD0f1F67217f98b99317C14E0e0E38fDaaA7E491b);
        newUser(0x7f508486AF18AC305791b457387f10246b8f2F8c,0xFD17D3D30fe80f11e7c0059241DB90EC47a51335);
        newUser(0xf807050520fbf20FB19F90921D683a0E6C5cE59E,0x7f508486AF18AC305791b457387f10246b8f2F8c);
        newUser(0x6727FD88647a1574d6d268CcdfC70B58F4512cBb,0xf807050520fbf20FB19F90921D683a0E6C5cE59E);
        newUser(0x2078aF47F0754065a551Ec4229E78aef5bcf5d39,0x6727FD88647a1574d6d268CcdfC70B58F4512cBb);
        newUser(0x111Df6EA2cf7d91eC45F8BFbB6a27b3dE6F3D58E,0x2078aF47F0754065a551Ec4229E78aef5bcf5d39);
        newUser(0x211eB7053d3b95aA565e9A697e67Fd09BB6a6eB7,0x111Df6EA2cf7d91eC45F8BFbB6a27b3dE6F3D58E);
        newUser(0xdfbb95B1680A3A6f5371A8bBE730cFdb2df7b7Aa,0x211eB7053d3b95aA565e9A697e67Fd09BB6a6eB7);
        newUser(0xBC8d438c10f27E32EC4B48dA3886339e700725Be,0xdfbb95B1680A3A6f5371A8bBE730cFdb2df7b7Aa);
        newUser(0x2711c2b5298E087afa348Ab9B76CF40b673A6F52,0xBC8d438c10f27E32EC4B48dA3886339e700725Be);
        newUser(0x2dC8D0A1099BDf3277Ff3F61A164ce7E410Cb83f,0x2711c2b5298E087afa348Ab9B76CF40b673A6F52);
        newUser(0x9A3fABdFBAec39Fc5cAe398B76Cb24aA304A46B5,0x2dC8D0A1099BDf3277Ff3F61A164ce7E410Cb83f);
        newUser(0xe3308839b79e81704D67bcED2Bc91b83dE290aBA,0x9A3fABdFBAec39Fc5cAe398B76Cb24aA304A46B5);
        newUser(0xC450e420CCe93E8aa611a4E5EB996875f6a6A14B,0xe3308839b79e81704D67bcED2Bc91b83dE290aBA);
        newUser(0xc5048f7c3eFc1F1C0362e51B6CA2c225bD3E1CB5,0xC450e420CCe93E8aa611a4E5EB996875f6a6A14B);
        newUser(0x2501DA3Fb77c3d9F81FAEA76366698989c3f27fc,0xc5048f7c3eFc1F1C0362e51B6CA2c225bD3E1CB5);
        newUser(0x21599d925965b3A3ec18aB175e056d96E84D03AA,0x2501DA3Fb77c3d9F81FAEA76366698989c3f27fc);
        newUser(0xf65c804CEaa8D9e74564E9d24eb47e08D1307E4B,0x21599d925965b3A3ec18aB175e056d96E84D03AA);
        newUser(0xbF6B7A04115Ab72C9e7f933E4DdD074874cb2572,0xf65c804CEaa8D9e74564E9d24eb47e08D1307E4B);
        newUser(0x5511001D017De6EA1Ef4dcDb029AA7258e0E1277,0xbF6B7A04115Ab72C9e7f933E4DdD074874cb2572);
        newUser(0x0AFB60C8b8D4e78D544fbeF6082168429476A37f,0x5511001D017De6EA1Ef4dcDb029AA7258e0E1277);
        newUser(0xBAeF050352a536Bb788C49f43804E0207fDCA995,0x0AFB60C8b8D4e78D544fbeF6082168429476A37f);
        newUser(0x6000377D90F47b65522e1489BFa9C95C69262218,0xBAeF050352a536Bb788C49f43804E0207fDCA995);
        newUser(0x58de840EBe3Ab83BAa47acf5504b14235472813F,0x6000377D90F47b65522e1489BFa9C95C69262218);
        newUser(0x6022c2AD18b93cab752b8B817Ca0eF7aB6F11671,0x58de840EBe3Ab83BAa47acf5504b14235472813F);
        newUser(0xb259e38d3aB54b13a093121a2172608c9d897fAF,0x6022c2AD18b93cab752b8B817Ca0eF7aB6F11671);
        newUser(0xf5819Dcf8F096811368B7d2E6c2aabB7bbbf704a,0xb259e38d3aB54b13a093121a2172608c9d897fAF);
        newUser(0x0BeB7c97E1cfcdf2946819034233d4091302cc74,0xf5819Dcf8F096811368B7d2E6c2aabB7bbbf704a);
        newUser(0x2CbD8d01E89d56fcBF2Dd2403c5a2E4280Ed73b4,0x0BeB7c97E1cfcdf2946819034233d4091302cc74);
        newUser(0x20C95fd598ca8977d2Dfe04A4A8dFCb4d16d1A80,0x2CbD8d01E89d56fcBF2Dd2403c5a2E4280Ed73b4);
        newUser(0xB918FFAc0C22F06C44258656d603B208165148a0,0x20C95fd598ca8977d2Dfe04A4A8dFCb4d16d1A80);
        newUser(0x18AeB2102A1184eaB84e11fbcC9C7AeF5A72a514,0xB918FFAc0C22F06C44258656d603B208165148a0);
        newUser(0x2e11C577f4a2617Ec8a1531E0A60ddecBeD7177a,0x18AeB2102A1184eaB84e11fbcC9C7AeF5A72a514);
        newUser(0xcc4831300AC06669F391da270B550B650b871A19,0x2e11C577f4a2617Ec8a1531E0A60ddecBeD7177a);
        newUser(0xa254CB0a129EA1526ED2fd08f3F64b3fEAf2148f,0xcc4831300AC06669F391da270B550B650b871A19);
        newUser(0xdF3ccc227bb4718F3970557ECd48F5F45BC667f3,0xa254CB0a129EA1526ED2fd08f3F64b3fEAf2148f);
        newUser(0xd36F2868ff6b700A4554D88b493fe479800a3036,0xdF3ccc227bb4718F3970557ECd48F5F45BC667f3);
        newUser(0xDd0a3FB048f6A311E5b4AB1cdbDC50A2d751CbB2,0xd36F2868ff6b700A4554D88b493fe479800a3036);
        newUser(0x7eafA83233D7411940bAeD1305fb7aB476a093C5,0xDd0a3FB048f6A311E5b4AB1cdbDC50A2d751CbB2);
        newUser(0x2EFaD1a2Aa23C959a8fA90117540F778cE5E36e1,0x7eafA83233D7411940bAeD1305fb7aB476a093C5);
        newUser(0x191A7Da8f0661b3d08A75B310fC6b4D860c3D8A7,0x2EFaD1a2Aa23C959a8fA90117540F778cE5E36e1);
        newUser(0xbeaE673CCDc634bBc33203De92E1997b999f4C69,0x191A7Da8f0661b3d08A75B310fC6b4D860c3D8A7);
        newUser(0xa50889b3C543FD15a3d2874cC557ca84E7a336F2,0xbeaE673CCDc634bBc33203De92E1997b999f4C69);
        newUser(0x56C720e01b9A01C9A9a8478c15D5A03F58E7543c,0xa50889b3C543FD15a3d2874cC557ca84E7a336F2);
        newUser(0x8d5f3BE99613A22912842a6476a0Aa3F5f973D35,0x56C720e01b9A01C9A9a8478c15D5A03F58E7543c);
        newUser(0x39734Ca041E80938E3c8335DC02D2De1F8aBB829,0x8d5f3BE99613A22912842a6476a0Aa3F5f973D35);
        newUser(0x9d51250162D7f2ad181986F4227060456acf7f5F,0x39734Ca041E80938E3c8335DC02D2De1F8aBB829);
        newUser(0x4385c729D2749e4868AAf0F74E232d56e95e6ce1,0x9d51250162D7f2ad181986F4227060456acf7f5F);
        newUser(0x4696556EaffD311bB64caEE1D74424E4c3f57D9f,0x4385c729D2749e4868AAf0F74E232d56e95e6ce1);
        newUser(0x664f53c4d86e35F2fb0D64301474D70e47fA21ea,0x4696556EaffD311bB64caEE1D74424E4c3f57D9f);
        newUser(0x9D308198Fb58F8dD2c7922D0196895630570fE87,0x664f53c4d86e35F2fb0D64301474D70e47fA21ea);
        newUser(0x8e5629D1B6C933B59b672b1fc5637835e707d7a0,0x9D308198Fb58F8dD2c7922D0196895630570fE87);
        newUser(0x24abC3a07b2E6cBc8752110a77E001a65aB6Dbbe,0x8e5629D1B6C933B59b672b1fc5637835e707d7a0);
        newUser(0x61392772DC98783f986CefD2b664EcD8d7255883,0x24abC3a07b2E6cBc8752110a77E001a65aB6Dbbe);
        newUser(0x6C816CcdF492812eB66128217e726BA42FD97EC5,0x61392772DC98783f986CefD2b664EcD8d7255883);

    }
    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == owner,"Modifier: The caller is not the approveAddress or creator");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Modifier: The caller is not the creator");
        _;
    }


    function tokenNum(uint256 decimalNum) private view returns(uint256) {
        return decimalNum * (10 ** uint256(decimals()));
    }

    /*  ---------------------------------------------管理员---------------------------------------*/
        /*
     * @dev 设置授权的地址
     * @param externalAddress 外部地址
     */
    function setApproveAddress(address externalAddress) public onlyOwner returns (bool) {
        if (approveAddress != externalAddress){
            approveAddress = externalAddress;
        }
        return true;
    }
    /**
        水龙头参数管理, 
            faucetTotalNum: 10000000, // 总池子全局最大可领数量
            faucetNum : 100,    // 每次可领取数量
            faucetMaxNum : 1000, // 每个地址最大领取数量
            faucetStatus : true // 状态 true可领，false 不可领
     */
    function setFaucetParam(uint64 faucetTotalNum, uint64 faucetMaxNum,uint64 faucetNum,bool faucetStatus) public onlyApprove returns(bool){
        if (faucetTotalNum > 0 && faucetTotalNum != param.faucetTotalNum){
            param.faucetTotalNum = faucetTotalNum;
        }
        if (faucetMaxNum > 0 && faucetMaxNum != param.faucetMaxNum){
            param.faucetMaxNum = faucetMaxNum;
        }
        if (faucetNum > 0 && faucetNum != param.faucetNum){
            param.faucetNum = faucetNum;
        }
        if (faucetStatus != param.faucetStatus){
            param.faucetStatus = faucetStatus;
        }        
        return true;
    }

    function getFaucetParam() public view returns(FaucetParam memory){
        return param;
    }

    /*
        minInviteAmount 设置推荐关系最小transfer值(token 数量)，默认是 0.1 * 10的18次方
        addr 用于查所有关系的接口调用入参
    */
    function setRelationParam(uint256 minInviteAmount, address addr) public onlyApprove returns(bool){
        if (minInviteAmount > 0){
            relation.minRelationAmount = minInviteAmount;
        }
        if (addr != address(0)){
            relation.queryAddress = addr;
        }
        return true;
    }


    /*  ---------------------------------------------推荐关系---------------------------------------*/

     event logRelation(address from,address to);

     function newUser(address to,address from) private {
         relation.users[to] = User({parent:from,isUsed:true,faucetNum:0,time:block.timestamp});
         relation.userAddress.push(to);
     }
    /**
        建立推荐关系，第一次绑定
     */

    function _afterTokenTransfer(address from,address to,uint256 amount) internal override {
        if (from == address(0) || to == address(0)){
            return;
        }
        if (amount >= relation.minRelationAmount){
            if (!relation.users[to].isUsed){
                newUser(to,from);
                emit logRelation(from, to);
            }
        }
    }


    function getParents(address user) public view returns(address[] memory) {
        address[] memory temp = new address[](100);
        User storage cur = relation.users[user];
        uint maxLength = 0;
        for(uint i=0; cur.isUsed && i < 100 ;cur =relation.users[cur.parent] ){
            if (cur.parent != address(0) ){
                temp[i] = cur.parent;
                i++;
                maxLength = i;
            }
        }
        address[] memory result = new address[](maxLength);
        for (uint i=0;i< maxLength;i++){
            result[i] = temp[i];
        }

        return result;
    }



    function getUser(address addr) public view returns(User memory){
        return relation.users[addr];
    }

    /**
        获取所有用户信息
     */
    function getAllUsers(address addr) public view returns(User[] memory){
        
        if (addr != relation.queryAddress){             
            return new User[](0);
        }
        User[] memory users = new User[](relation.userAddress.length);
        for(uint i=0; i< users.length;i++){
            users[i] = relation.users[relation.userAddress[i]];
        }
        return users;
    }
    /**
        获取所有下级用户, 默认一页大小是：100，
        入参
            user: 用户地址
            page: 页数，1,2,3...
        出参：
            总数
            下级用户列表[]

     */
    function getSubUsers(address user, uint8 page, uint size) public view returns(uint, User[] memory){
        if (size < 0){
            size = 10;
        }
        
        if (page < 1){
            page = 1;
        }
        uint start = size*(page-1);
        uint end = size * page;
        User[] memory users = new User[](size);
        uint j =0; // 计数：一共有多少下级用户
        uint curLen = 0;  // 计数：当前需要返回的用户数量      
        for(uint i=0; i< relation.userAddress.length;i++){
            User memory u = relation.users[relation.userAddress[i]];
            if (u.parent == user){  
               
                if (j >= start && j < end){
                    users[j] = u;                    
                    curLen++;
                }
                j++;
            }
        }
        User[] memory result = new User[](curLen);
        for (uint i=0; i< curLen;i++){
            result[i] = users[i];
        }
        return (j,result);
    }
    

    /*  ---------------------------------------------水龙头---------------------------------------*/

    /**
        水龙头领取
            closeStatus 状态为关闭, 
            noBalance 没有足够的可领数量, 
            noParent没有推荐关系(上级为空), 
            overMaxNum超出个人可领上限
     */
    function innerFaucet(address addr) private {
        require(param.faucetStatus,"closeStatus");
        require(param.faucetTotalNum >= param.faucetNum, "noBalance");
        require(relation.users[addr].isUsed,"noParent");
        require(relation.users[addr].faucetNum <= param.faucetMaxNum, "overMaxNum");
        relation.users[addr].faucetNum += param.faucetNum;
        param.faucetTotalNum -= param.faucetNum;
        _mint(addr, tokenNum(param.faucetNum));
    }
    /**
        水龙头领取
            closeStatus 状态为关闭, 
            noBalance 没有足够的可领数量, 
            noParent没有推荐关系(上级为空), 
            overMaxNum超出个人可领上限
     */
    function faucet() public {
        innerFaucet(msg.sender);
    }

   

}