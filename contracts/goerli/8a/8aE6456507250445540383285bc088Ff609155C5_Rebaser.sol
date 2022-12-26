// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

interface IBEP20 {
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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./RebaseToken.sol";

interface IUniswapV2Pair {
    function skim(address to) external;

    function sync() external;
}

contract Rebaser is RebaseToken {
    using SafeMath for uint256;

    //config
    uint256 public constant BIG_INT = ~uint128(0);
    uint256 public constant MAX_SUPPLY = BIG_INT * 10 ** 18;
    uint256 public constant PRE_SUPPLY = 21000000 ether;
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    //rebases
    uint256 public rewardYield = 10; //<-------------------- 1 percent
    uint256 public rewardYieldDenominator = 1000;
    uint256 public rebaseFrequency = 1 days; //<---------------- rebase will be due every 1 days
    uint256 public nextRebase;

    //state
    bool public autosync;
    bool public autocomp;
    bool public locked;

    //addresses
    address public admin;
    address public pairAddress;

    //rebase gaurd
    mapping(address => bool) private authAddresses;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not authorized.");
        _;
    }

    modifier onlyAuth() {
        require(isAuth(msg.sender), "Not authorized, only auth");
        _;
    }

    constructor() {
        admin = msg.sender; //<---------------------------------- set admin
        authAddresses[admin] = true; //<---------------------------------------- add admin auth
        autosync = true; //<---------------------------------------- will autosync pool (do not disable)
        autocomp = true; //<---------------------------------------- will autocompound rewards
        nextRebase = block.timestamp + rebaseFrequency; //<----------- set first rebase

        _setIndexSupply(1 ether); //<--------------------------------- initialize index supply
        _setIndexSupplyCheckpoint(1 ether); //<----------------------- initialize index supply checkpoint
        _setDivisor(BIG_INT); //<------------------------------------- initialize divisor
        _mint(msg.sender, PRE_SUPPLY.mul(divisor())); //<------------- mint initial supply
    }

    function rebase() private {
        //stop reentry
        locked = true;

        //calc supply delta
        uint256 supply;
        if (autocomp) {
            supply = indexSupply();
        } else {
            supply = indexSupplyCheckpoint();
        }
        uint256 supplyDelta = supply.mul(rewardYield).div(
            rewardYieldDenominator
        );

        //exec rebase
        coreRebase(supplyDelta);

        //unlock
        locked = false;
    }

    function coreRebase(uint256 supplyDelta) private {
        uint256 old_supply = indexSupply();
        uint256 new_supply;

        if (old_supply < MAX_SUPPLY) {
            new_supply = old_supply.add(supplyDelta);
        } else {
            new_supply = MAX_SUPPLY;
        }

        _setIndexSupply(new_supply);
        _setDivisor(MAX_SUPPLY.div(new_supply));

        nextRebase = block.timestamp + rebaseFrequency;
        _setCurrentEpoch();
    }

    function sync() private {
        IUniswapV2Pair(pairAddress).skim(burnAddress);
        IUniswapV2Pair(pairAddress).sync();
    }

    function rebaseDue() public view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function isLocked() public view returns (bool) {
        return locked;
    }

    function isAdmin(address atAddress) private view returns (bool) {
        return atAddress == admin;
    }

    function isAuth(address atAddress) public view returns (bool) {
        return authAddresses[atAddress];
    }

    function setPairAddress(address toAddress) external onlyAdmin {
        pairAddress = toAddress;
    }

    function setAutosync(bool toState) external onlyAdmin {
        autosync = toState;
    }

    function setAutocomp(bool toState) external onlyAdmin {
        autocomp = toState;

        if (toState == false) {
            _setIndexSupplyCheckpoint(indexSupply());
        }
    }

    function setRewardYield(uint256 toAmount) external onlyAdmin {
        rewardYield = toAmount;
    }

    function adminRebase() external onlyAdmin {
        rebase();
    }

    function adminRebaseTimes(uint256 howmany) external onlyAdmin {
        for (uint256 i = 0; i < howmany; i++) {
            rebase();
        }
    }

    function setAuth(address atAddress, bool toValue) external onlyAdmin {
        authAddresses[atAddress] = toValue;
    }

    function setLimiter(bool toValue) external onlyAdmin {
        useLimiter = toValue;
    }

    function setLimit(uint256 toAmount) external onlyAdmin {
        limit = toAmount;
    }

    function setLength(uint256 toSeconds) external onlyAdmin {
        toLength = toSeconds;
    }

    function setWhitelisted(address atAddress, bool toValue) external onlyAuth {
        whitelisted[atAddress] = toValue;
    }

    function manualRebase() external onlyAuth {
        if (rebaseDue() && !isLocked()) {
            rebase();
        }

        if (autosync) {
            sync();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//imports

import "./Context.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

abstract contract RebaseToken is Context, IBEP20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _indexSupply;
    uint256 private _indexSupplyCheckpoint;
    uint256 private _divisor;
    uint256 private _currentEpoch;

    string private constant _name = "Optimus V3";
    string private constant _symbol = "OPT3";

    mapping(address => uint256) public count;
    mapping(address => uint256) public countingStarted;
    mapping(address => uint256) public cooldownEnd;
    mapping(address => bool) public whitelisted;
    uint256 internal limit;
    uint256 internal toLength;
    bool internal useLimiter;

    constructor() {
        useLimiter = true;
        limit = 5;
        toLength = 5 days;
    }

    modifier limiter(address atAddress) {
        require(!inCooldown(atAddress), "Try again later");
        _;
    }

    function iterate(address atAddress) private {
        if (count[atAddress] == 0) {
            countingStarted[atAddress] = currentEpoch();
        } else if (currentEpoch() > countingStarted[atAddress]) {
            count[atAddress] = 0;
            countingStarted[atAddress] = currentEpoch();
        }

        count[atAddress]++;

        if (count[atAddress] >= limit) {
            setCooldown(atAddress, toLength);
            count[atAddress] = 0;
        }
    }

    function setCooldown(address atAddress, uint256 length) private {
        cooldownEnd[atAddress] = block.timestamp.add(length);
    }

    function inCooldown(address atAddress) public view returns (bool) {
        return block.timestamp < cooldownEnd[atAddress];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.div(divisor());
    }

    function indexSupply() public view returns (uint256) {
        return _indexSupply;
    }

    function indexSupplyCheckpoint() public view returns (uint256) {
        return _indexSupplyCheckpoint;
    }

    function divisor() public view returns (uint256) {
        return _divisor;
    }

    function currentEpoch() public view returns (uint256) {
        return _currentEpoch;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account].div(divisor());
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender].div(divisor());
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount.mul(divisor()));
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount.mul(divisor()));
        _transfer(from, to, amount.mul(divisor()));
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount.mul(divisor()));
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(
            owner,
            spender,
            allowance(owner, spender).mul(divisor()) + addedValue.mul(divisor())
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender); //no conversion required
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(
                owner,
                spender,
                currentAllowance.mul(divisor()) - subtractedValue.mul(divisor())
            );
        }

        return true;
    }

    function _setIndexSupply(uint256 toSupply) internal virtual {
        _indexSupply = toSupply;
    }

    function _setIndexSupplyCheckpoint(uint toSupply) internal virtual {
        _indexSupplyCheckpoint = toSupply;
    }

    function _setDivisor(uint256 toDivisor) internal virtual {
        _divisor = toDivisor;
    }

    function _setCurrentEpoch() internal virtual {
        _currentEpoch++;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual limiter(tx.origin) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount.div(divisor()));

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        //implement cooldown //////////////////////////
        address sender = tx.origin;

        if (useLimiter) {
            if (!whitelisted[sender]) {
                iterate(sender);
            }
        }
        ///////////////////////////////////////////////

        emit Transfer(from, to, amount.div(divisor()));

        _afterTokenTransfer(from, to, amount.div(divisor()));
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount.div(divisor()));

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount.div(divisor()));

        _afterTokenTransfer(address(0), account, amount.div(divisor()));
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount.div(divisor()));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount.div(divisor()));

        _afterTokenTransfer(account, address(0), amount.div(divisor()));
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount.div(divisor()));
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender).mul(divisor());
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount); // no conversion required
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}