// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./libs/ERC20.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";

contract TESTYEN is ERC20 {
    event Share(address indexed person, uint256 amount);
    event Get(address indexed person, uint256 amount);
    event Mint(address indexed person, uint256 index);
    event Claim(address indexed person, uint256 amount);
    event Stake(address indexed person, uint256 amount);
    event WithdrawStake(address indexed person, uint256 amount);
    event WithdrawReward(address indexed person, uint256 amount);

    struct Block {
        uint128 personAmount;
        uint128 mintAmount;
    }

    struct Person {
        uint32[] blockList;
        uint128 blockIndex;
        uint128 stakeAmount;
        uint128 rewardAmount;
        uint128 lastPerStakeRewardAmount;
    }

    struct Sharer {
        uint128 shareAmount;
        uint128 getAmount;
    }

    uint256 public constant halvingBlockAmount = ((60 * 60 * 24) / 12) * 1;
    uint256 public lastBlock;
    uint256 public halvingBlock;
    uint256 public blockMintAmount = 100 * 10**18;
    uint256 public mintStartBlock;

    uint256 public stakeAmount = 1;
    uint256 public perStakeRewardAmount;

    uint256 public constant shareBlockAmount = ((60 * 60 * 24) / 12) * 1;
    uint256 public constant shareTokenAmount = 6800000 * 10**18;
    uint256 public constant getBlockAmount = ((60 * 60 * 24) / 12) * 5;
    uint256 public immutable shareEndBlock = block.number + shareBlockAmount;
    uint256 public shareEthAmount;
    uint256 public sharePairAmount;

    uint256 public constant fee = 1;

    IWETH public constant weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    IERC20 public immutable token = IERC20(address(this));
    IUniswapV2Pair public immutable pair =
        IUniswapV2Pair(
            IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(address(weth), address(this))
        );

    mapping(uint256 => Block) public blockMap;
    mapping(address => Person) public personMap;
    mapping(address => Sharer) public sharerMap;

    constructor() ERC20("YEN", "YEN") {}

    /* ================ UTIL FUNCTIONS ================ */

    modifier _checkHalving() {
        unchecked {
            if (block.number >= halvingBlock) {
                blockMintAmount /= 2;
                halvingBlock += halvingBlockAmount;
            }
        }
        _;
    }

    modifier _checkReward() {
        if (personMap[msg.sender].lastPerStakeRewardAmount != perStakeRewardAmount) {
            personMap[msg.sender].rewardAmount = uint128(getRewardAmount(msg.sender));
            personMap[msg.sender].lastPerStakeRewardAmount = uint128(perStakeRewardAmount);
        }
        _;
    }

    modifier _checkMintStart() {
        require(mintStartBlock != 0, "mint must start!");
        _;
    }

    function _addPerStakeRewardAmount(uint256 addAmount) internal {
        perStakeRewardAmount += addAmount / stakeAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 feeAmount;
        if (sender != address(this)) {
            feeAmount = (amount * fee) / 1000;
        }
        if (feeAmount != 0) {
            _balances[address(this)] += feeAmount;
            _addPerStakeRewardAmount(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        uint256 getAmount = amount - feeAmount;
        _balances[recipient] += getAmount;
        emit Transfer(sender, recipient, getAmount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /* ================ VIEW FUNCTIONS ================ */

    function maxGetAmount(address sharer) public view returns (uint256) {
        unchecked {
            uint256 percent = ((block.number - mintStartBlock) * 100) / getBlockAmount;
            if (percent > 100) {
                percent = 100;
            }
            return
                (((sharePairAmount * sharerMap[sharer].shareAmount) / shareEthAmount) * percent) /
                100 -
                sharerMap[sharer].getAmount;
        }
    }

    function getMintAmount() public view returns (uint256) {
        unchecked {
            return (block.number - lastBlock) * blockMintAmount;
        }
    }

    function getRewardAmount(address person) public view returns (uint256) {
        unchecked {
            return
                personMap[person].stakeAmount *
                (perStakeRewardAmount - personMap[person].lastPerStakeRewardAmount) +
                personMap[person].rewardAmount;
        }
    }

    function getPersonBlockList(address person) external view returns (uint32[] memory) {
        uint32[] memory blockList = new uint32[](personMap[person].blockIndex);
        for (uint256 i = 0; i < personMap[person].blockIndex; i++) {
            blockList[i] = personMap[person].blockList[i];
        }
        return blockList;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function share() external payable {
        require(block.number < shareEndBlock, "block cannot over shareEndBlock!");
        sharerMap[msg.sender].shareAmount += uint128(msg.value);
        shareEthAmount += msg.value;
        emit Share(msg.sender, msg.value);
    }

    function start() external {
        require(block.number >= shareEndBlock, "block must over shareEndBlock!");
        require(mintStartBlock == 0, "mint cannot start!");
        weth.deposit{value: shareEthAmount}();
        weth.transfer(address(pair), shareEthAmount);
        _mint(address(pair), shareTokenAmount);
        sharePairAmount = pair.mint(address(this));
        mintStartBlock = block.number;
        halvingBlock = block.number + halvingBlockAmount;
        lastBlock = block.number;
    }

    function get(uint256 amount) external _checkMintStart {
        uint256 maxAmount = maxGetAmount(msg.sender);
        require(amount <= maxAmount, "cannot over maxAmount!");
        sharerMap[msg.sender].getAmount += uint128(amount);
        pair.transfer(msg.sender, amount);
        emit Get(msg.sender, amount);
    }

    function mint() external _checkMintStart _checkHalving {
        if (block.number != lastBlock) {
            uint256 mintAmount = getMintAmount();
            _mint(address(this), mintAmount);
            blockMap[block.number].mintAmount = uint128(mintAmount / 2);
            lastBlock = block.number;
            _addPerStakeRewardAmount(blockMap[block.number].mintAmount);
        }
        Person storage person = personMap[msg.sender];
        if (person.blockList.length == person.blockIndex) {
            person.blockList.push(uint32(block.number));
        } else {
            person.blockList[person.blockIndex] = uint32(block.number);
        }
        emit Mint(msg.sender, blockMap[block.number].personAmount);
        unchecked {
            blockMap[block.number].personAmount++;
            person.blockIndex++;
        }
    }

    function claim() external _checkMintStart {
        Person memory person = personMap[msg.sender];
        require(person.blockList[person.blockIndex - 1] != block.number, "mint claim cannot in sample block!");
        uint256 claimAmount;
        unchecked {
            for (uint256 i = 0; i < person.blockIndex; i++) {
                Block memory _block = blockMap[person.blockList[i]];
                claimAmount += _block.mintAmount / _block.personAmount;
            }
        }
        personMap[msg.sender].blockIndex = 0;
        token.transfer(msg.sender, claimAmount);
        emit Claim(msg.sender, claimAmount);
    }

    function stake(uint256 amount) external _checkMintStart _checkReward {
        pair.transferFrom(msg.sender, address(this), amount);
        personMap[msg.sender].stakeAmount += uint128(amount);
        stakeAmount += amount;
        emit Stake(msg.sender, amount);
    }

    function withdrawStake(uint256 amount) public _checkMintStart _checkReward {
        require(amount <= personMap[msg.sender].stakeAmount, "amount cannot over stakeAmount!");
        personMap[msg.sender].stakeAmount -= uint128(amount);
        stakeAmount -= amount;
        pair.transfer(msg.sender, amount);
        emit WithdrawStake(msg.sender, amount);
    }

    function withdrawReward() public _checkMintStart _checkReward {
        uint256 rewardAmount = personMap[msg.sender].rewardAmount;
        personMap[msg.sender].rewardAmount = 0;
        token.transfer(msg.sender, rewardAmount);
        emit WithdrawReward(msg.sender, rewardAmount);
    }

    function exit() external {
        withdrawStake(personMap[msg.sender].stakeAmount);
        withdrawReward();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping(address => uint256) _balances;

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
        //     require(sender != address(0), "ERC20: transfer from the zero address");
        //     require(recipient != address(0), "ERC20: transfer to the zero address");
        //     _beforeTokenTransfer(sender, recipient, amount);
        //     uint256 senderBalance = _balances[sender];
        //     require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        //     unchecked {
        //         _balances[sender] = senderBalance - amount;
        //     }
        //     _balances[recipient] += amount;
        //     emit Transfer(sender, recipient, amount);
        //     _afterTokenTransfer(sender, recipient, amount);
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
    // function _burn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _beforeTokenTransfer(account, address(0), amount);

    //     uint256 accountBalance = _balances[account];
    //     require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    //     unchecked {
    //         _balances[account] = accountBalance - amount;
    //     }
    //     _totalSupply -= amount;

    //     emit Transfer(account, address(0), amount);

    //     _afterTokenTransfer(account, address(0), amount);
    // }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address to) external returns (uint256 liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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