// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RightToken is ERC20, Ownable { // can stop mint

    uint256 public maxSupply;

    constructor(
    ) ERC20("Right", "Right") {
        _init();
        maxSupply = 10000000000 ether; // max 10 billion RIGHT Token
    }


    function batchMint(address[] memory accountList, uint256[] memory amountList) public virtual onlyOwner{
        uint256 amount;
        for(uint256 i = 0; i < amountList.length; i++){
            amount = amount + amountList[i];
        }
        require(totalSupply() + amount < maxSupply, "token amounts exceeds max");
        _batchMint(accountList, amountList);
    }
    
    function _batchMint(address[] memory accountList, uint256[] memory amountList) internal virtual{
        require(accountList.length == amountList.length, "mint params don't match");
        for(uint256 i = 0; i < accountList.length; i++){
            _mint(accountList[i], amountList[i]);
        }
    }
    
    function _init() internal{
        _mint(0xfE925d32edc1FAA5F0Ec93fb00a3d0f15aC747D3, 220000 ether);
        _mint(0xC581d65F4F2fdaB7e8cC331730C7d9ed6428C162, 105200 ether);
        _mint(0xD6528A689a54ABDaC4946Fa9f0D637ad18C3c312, 2000 ether);
        _mint(0x46C370b57D63a4328cC068EeB0233136A4666666, 1000 ether);
        _mint(0xea6f0eBc0358B40118Ee7D937a07e8cE9b0DAE41, 20 ether);
        _mint(0x351Db4fBa6A40e932D4f1803041EAD4Dd638BfaC, 2800 ether);
        _mint(0x6862dcAA3490493d41018eA935ae4a4cA4120862, 500 ether);
        _mint(0xBb8f12f4080816f933F0fb80E11b17DE32A3B32E, 10000 ether);
        _mint(0xCfC7bF5B9D4Aa6Ed90C219891f229e52c83070Bd, 30 ether);
        _mint(0x8bb8bCf5EE6Ff0278e4315DB409E1a8f26E51fD0, 500 ether);
        _mint(0xf819c075cd8d68E877073FFEDa6982aAc35BD726, 12000 ether);
        _mint(0x4cc40ddcB757E01A5326e07aBA4709D81B66599A, 29000 ether);
        _mint(0x07DE7F43EF5441E592F98D20ad47a33d4dA985b6, 11990 ether);
        _mint(0x7Ccbae5844eC7434dAA281e787bf1592E64D8901, 1000 ether);
        _mint(0xC567cA38efF4cef63745436f8eB07ccCF300571D, 10000 ether);
        _mint(0xb9C84645ddB24060f71963F90ec170f810E294A7, 50 ether);
        _mint(0xD004846f7676672414F50b39BcfD39c283C870Cc, 1000 ether);
        _mint(0x70fbF2f80005C7399dbAe1eC09AD25F41bc5eF1c, 300 ether);
        _mint(0x1bB77E121B1Ac9083c3C958437086D93BAB4b128, 300 ether);
        _mint(0x361A58532a16a660E6312B50E9066b6828531081, 3000 ether);
        _mint(0x7A2d3De69eDB1C584c465DB319fF597e12fE49A7, 10000 ether);
        _mint(0x3908e83DD741c35a025FAdC8bD6ec6b51fa84Da3, 2000 ether);
        _mint(0xF92f5d4Ff40277B870299A97711d054fF510BB0D, 7000 ether);
        _mint(0x452E762EC62b8F471776B7346201330F47b9d052, 20000 ether);
        _mint(0x7f71c92A1d3E885bA43af85aB0082C5244e3C364, 100000 ether);
        _mint(0xC9F77e99E83d93ed1E7E07Cb431E56F10ad1458C, 10000 ether);
        _mint(0x04A87558A4C58426Ebe2d97e32161600CCE0f9AD, 8000 ether);
        _mint(0xec4d6033f2b0296cd9A860cf2fBEF820ba64488d, 3100 ether);
        _mint(0x860268a00314c382480f1258D378589c492d9E7b, 1000 ether);
        _mint(0x1C772B9854E2C421f13f3A7e6a3D521C0510eDE0, 700350 ether);
        _mint(0xE947a586EBeFe01b9644133e89C1e38d7EeA6946, 10000 ether);
        _mint(0x01d51155Ebb3715ffD215b4Ce4B18Cf4AA8C9f76, 750000 ether);
        _mint(0xd821BF4193ba1F7044886F2b5C40e6a9597907A3, 80000 ether);
        _mint(0x1d3efff53ea9552f5C1cC046CddE5A7FE98DA7d6, 10000 ether);
        _mint(0xFa2E625542F2436E4ca64A1357aB5d440F407e0e, 200000 ether);
        _mint(0xeCe9Faaab3886115378Ce7ef362fD5417F3f74B6, 1930 ether);
        _mint(0x82aBe0456AFBD32aBf1f0c5ADd8c4199dC4a3bC3, 1000 ether);
        _mint(0x8b13205227aF504148b59fA67004b01Ec560Dc21, 2000 ether);
        _mint(0x36eF63784e89134a9b18812322139dDffEae5a24, 20000 ether);
        _mint(0xEce70e37e97931881cE50c6ce0aFd0f853702808, 55000 ether);
        _mint(0x63aB19bBaD984ee1B1866a130A4386a646537a40, 600000 ether);
        _mint(0xe18C212dc18567B887C53f89890B52CebCD8b9F3, 5000 ether);
        _mint(0x13BBC6c42cf29a9db1c043E3cC275E4d28A85F77, 130000 ether);
        _mint(0x3717Df2e0971fA64FcAA2eb78C93A033389de78A, 100 ether);
        _mint(0x7a6F44464Bf5bFBb4ce2852CC7E7B173D89c5fd5, 10000 ether);
        _mint(0x0052BBdd26c78d5046a3d5EaA47EB84dA78332a3, 15000 ether);
        _mint(0x17D7F34Bd782f9AfA72A303010BBe3dBF84B2892, 5000 ether);
        _mint(0x6033ab9fD630Cd5f77f16E2b75bC48826E052B4f, 963100 ether);
        _mint(0x8a5d335F9B2789f7db40d8f79cB59a401B268b33, 5000 ether);
        _mint(0xE985A1A1248b995266869258CD965F1dE11111EC, 5000 ether);
        _mint(0xf5648868058A62cA721e06b4177A46B9F84cc93A, 2300 ether);
        _mint(0xbB6B8AEfA6338934371Bd936B5dbaba2Da94b487, 50 ether);
        _mint(0x6693DA2C25f18a8AAc0B7F9d1CF197Ab2B29B006, 800 ether);
        _mint(0xf36E7a3fa8d4E71563253D11e1d0FBaf3ab12C57, 2000 ether);
        _mint(0x99E205965f446c1Ff578f56Cb439F5dF0D84B017, 430000 ether);
        _mint(0xBCF4FC59f7c1b50b14Bd73Ca4C1D284d1de718dE, 34000 ether);
        _mint(0x553EE04aD4b04A381d69545c84012EA2e2Df1fEE, 20000 ether);
        _mint(0x0B0975DAb21e0ADBa31C65380d5bB90dDAA7a781, 250000 ether);
        _mint(0x82148E2F318c3C607Fedbc0D2Ab470667A6a338D, 80000 ether);
        _mint(0xA2942cf26Ce71E87b74bff01aDBEDDe2EE147C59, 45000 ether);
        _mint(0x4adee4906e1011ED89A5F170DE1244f8E7007122, 500000 ether);
        _mint(0x5d2832C2AaFDB87d7F661EA707Ae1CfDbfF7269A, 74500 ether);
        _mint(0xd71bC416c9D7B2aCFceAA4038FB441839F7E2459, 130000 ether);
        _mint(0x1d82C175E43EbF0b03ea5F50F2A26A4EE6465e68, 10000 ether);
        _mint(0xf0226D8Ef8c1C0766817584e4e7F6EA6F05C279A, 96000 ether);
        _mint(0xFEB1231112D7bCd447671248f05Fb580E3836A71, 200 ether);
        _mint(0x4759C2AA030878ea0ABE3cEEBbfAe5035451139C, 1000 ether);
        _mint(0x0a4258445df9dAA2D8589E15D102d8EB9319E554, 200 ether);
        _mint(0x7268Ae58AB54955f1BD683Bf96113a0Ed33F30C9, 2000 ether);
        _mint(0x5e3D085eafEeaA3D6Dff1aB29142bAA1a640f78a, 2500000 ether);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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