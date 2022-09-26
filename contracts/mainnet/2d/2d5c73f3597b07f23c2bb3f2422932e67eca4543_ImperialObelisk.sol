/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

/*

Telegram: https://t.me/imperialobelisk
Website:  https://imperialobelisk.net/
Medium:   https://imperialobelisk.medium.com/


*/

// SPDX-License-Identifier: MIT

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: contracts\@openzeppelin\contracts\utils\Context.sol



pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\@openzeppelin\contracts\token\ERC20\ERC20.sol



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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




pragma solidity ^0.8.0;


contract ImperialObelisk is ERC20 {
      
    constructor() ERC20("Imperial Obelisk", "IMP") {
        
        uint256 totalSupply = 1 * 10**12 * 10**decimals();        
        uint256 sum = 0;
        uint256 factor = 1000000;
        
        //Version 1 Airdrops
        
        uint16[85] memory amounts = [45075, 3388, 2934, 326, 1, 859, 1308, 617, 143, 146, 9242, 23151, 9470, 3332, 7915, 2588, 2989, 3686, 6710, 9808, 3604, 2677, 509, 656, 29964,
        2713, 801, 537, 523, 22, 1021, 931, 4408, 8385, 41563, 5215, 16549, 2283, 7864, 89, 1511, 3582, 48, 174, 87, 101, 223, 84, 339, 55, 3594, 55, 121, 233, 93, 2374, 4356, 155,
        337, 115, 11250, 1554, 1134, 574, 1092, 769, 14987, 982, 169, 29, 187, 153, 31, 17, 701, 917, 525, 6700, 5948, 31456, 10784, 28988, 33449, 30368, 38364];

        address[85] memory hodlers = [0xe7524Dd1f3f0cF2E48CEb901F0DA3bFcCfdF41fe,0xEa51D3fD4b4F0CaF0147d4928370e6278476c994,0x523C80ae16D90a67262805Ed41264eafB0f59e94,
        0xA59cDD29E22F799e65d841E87cBA049c7e125325,0xe7524Dd1f3f0cF2E48CEb901F0DA3bFcCfdF41fe,0xD600e4a1F8c45766d61239C72a94B65b5a05230E,0x054E8c447e3c7f1B73644693002445a0F30Aa64b,
        0x914070Ac0B9B4c305638154c6305257204D5a639,0x2B16452b6F7a7b71450edc9c3D8f2cb9a91F19fe,0xffE78e26Ef60320a9F8Dfc969f8E7E7054C17423,0x96F906DcE93c05CF555ED227EdEDD7E5151fA66C,
        0x303e17b365ef353f0E3DFc6DD8cEff071f455107,0xE972852bd1E33a526545c7d96Dd317b8EE50cC69,0x152072Bf08F2F37eC5327E26E8d6051152b63af2,0xef2611C32Fd1c222Ce706Caae79eEbF32feb8a8E,
        0x152072Bf08F2F37eC5327E26E8d6051152b63af2,0x31805b4f79f328293DF79b9dC672543b56a51E70,0x86fEd3844156c2f36e990a00b2836Fa85A5FbD92,0xa6cB0C78d5a311517295Fd62F037050DF1059C93,
        0x687CC40DbFb918eF5EbeB370a05e8049E726d7c6,0xE3bB441Eb62C6Fce98a319Dd18b43dcCD9B34E77,0xD31F19930e6907777536b3a258dAa8298668F3A2,0xFbf90C74bbb218304374C259cD8a2f0dccbbB4cc,
        0x9995779237D1e1bb072ae88b83a80e409DbEbB75,0x265c78295464246c2b94d417eAbA0acdDD059670,0x0dFD4E5431a3B1753489feC5430B1cab0aC4633F,0xd1Cddd12dDeB82837f965953cDF53A289Aa7AD17,
        0x4E964eB134cB28c4DAFB689DD2973192a0b2986f,0x65fDe4B43CDd2FFeEBe8c73676D6F62a25dcFE3e,0xB515Ac8e3E5CE77c0f77e5F023E5D4e696FD284B,0x37C680b193635473A4F1BbE913688837019c1583,
        0x05C56eEd53Dec05555582e50354cDf8e731aF778,0x503e7cBC2058932fC0A77cFE6445f117760dF904,0xa6F14C23cf42C1556156c0Ec20702f567F910335,0xBaAAb5dae967780e36F057B036D82568Be140a53,
        0x034f41AEd7ed6f4EAe2De4a4d37dD3Ae5fc310F1,0xB1f1FFf3757953D8410e1719d0a03a616Cf4de17,0xB041230054ab0D8516decc79203Fe02D416D8c9E,0x5e12c06802147b8Ded5a27ceb7352b47710eeB30,
        0xeE5f0C1A97618fFB44403dD56F03d3Ac37Cf1a85,0x5940Bf44241854E1574A9D900F0AC46105a46916,0xd6f1dbBE11a4CbaAb5e7a9b4fD3b353F89AD713A,0x55F7ac89EAD7aAFeCee341Ca041228930A7bf8c5,
        0xF90B65094CccEBab59bD6F53e4793719b7BaD965,0x5c8A8C349711485d93565AC2A32fad08a16D7e9E,0x2FeC703CaF64E6320dDf3199a6a2198F2C1BA0Bc,0x355766d2B1D63c55448A03285324CD882f39d54b,
        0x156fb1a790cDab269b13d633Bb32689D7E7FB629,0x157Bde9ad8Fe3c74496B421DA637729BCa52B4aE,0xE14D6f28B2E8fca7e1AD675D1103E1A040b4675D,0xfB5C3Ca624D950a6E54f12d1FD01C27d02d00aa5,
        0x9Ebdaa39D6751Ebc62d43e1F0a43508F0fE9B231,0xF0c32D084babb52b2d6c0471c1174b03B6E989Af,0x7461513A6F392361788B28f8C94f902aF0353589,0x11b76618f41415B6313e3848d0638963Cc7308B7,
        0x17B466eA4EdDa17c70a98080DBe38C2af5e0A8a0,0x967D61D29F01EC152eFD62A9fE67cB28FBfB7eEC,0x4B744061755848E88abe1E89bdbFC0cCa1a9bf67,0x8D97788452d55B600A31ae321Dbe7372c8427348,
        0x8d4862b7f73A34aB3Adfcab2b6d5563fA2Df12d4,0xC14C43fB61794E803916E3C66fc963F77d7aC095,0xC0b63F27D3af2553fe737E12d78ed90286E9f2f4,0xD5EC7eA5a498a837a613C9e24da8486689957560,
        0x6F2f2ae687283aE342E41f799335A09269e030bd,0xdC798f72f05894A49d3164d17ded11205164e696,0x7aC19eA6d047c2FBb75e1761ED9b16E74d69F4A5,0x3566994A0C98aEe4fA430C1d85a0bF76aB091371,
        0x96cB6Ec258eD505F4f9D6d0CdAD327972c05a93f,0xcF5f95FFA5F6099343a961B76aaabeE1976a7c53,0x5647502d8a6a6bF37633070E6669Bd7dD2c2049B,0xF6aefA6b1A9850D6Dd7E28a7cc52dfB7f1b8B7d6,
        0x69Ef86AD72417B8585D348E01EfB617E777Ed1dB,0x0AbE9Ef3f669d0FDb644638E27F3d84b97d7E54B,0x34c0C7BCC62a58547989a7beefFD59ce5bCA3939,0xe608f3fB9c6fcA4d8Af8e4a6e76d7863222c5305,
        0x0Cf28aAe2687cF2E23fF2690dD8A1cA89AB67C99,0x719023B09DdD440155b9938B2EBD4DCd58349346,0xD27350cAD2f3e5a502DE1ebD8993331FFACEC816,0xE3E5A703EB49F02E2Da5C041a5B71C89930d3E92,
        0x371400eD9a7E8497DAFd3802806eBf2734161Bc9,0xAAc9DE065798C03358402B503aCb3975716aDd42,0x24D6cbDb0a9987468f7130295A28E367Efa39348,0x2B16452b6F7a7b71450edc9c3D8f2cb9a91F19fe,
        0x054E8c447e3c7f1B73644693002445a0F30Aa64b,0x5E00692612cFB0b3CdC0Bc2ab41Bd05f384Cd037];
        
        for(uint256 i = 0;i < hodlers.length;i++){
            _mint(hodlers[i],(totalSupply * amounts[i] / factor));
            sum += amounts[i];
        }
        
        //Remaining to deployer
        uint256 remaining = factor - sum;
        
        _mint(msg.sender,totalSupply * remaining / factor);
    }


    function multitransfer(address[] memory hodler,uint256[] memory amount) external{

        for(uint256 i = 0;i < hodler.length;i++){
            transfer(hodler[i],amount[i]);
        }

    }

}