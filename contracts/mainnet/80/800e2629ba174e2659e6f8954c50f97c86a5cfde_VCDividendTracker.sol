/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

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
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant MAGNITUDE = 2**128;
    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        distributeDividends();
    }

    /**
     * @dev function requires sending ethereum
     * @dev Magnified divident per share will be 0 on the time of deployement
     */

    function distributeDividends() public payable override {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(MAGNITUDE) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    function withdrawDividend() external virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            emit DividendWithdrawn(user, _withdrawableDividend);
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
            } else {
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / MAGNITUDE;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract VCDividendTracker is Context, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping(address => bool) isDividendHolder;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    mapping(address => bool) private isOwner;

    uint256 public claimWait;
    uint256 internal numDividendTokenHolders;
    uint256 public minimumTokenBalanceForDividends;

    modifier onlyOwners() {
        require(isOwner[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event minimumTokenBalanceUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    event OwnershipSet(address indexed account, bool indexed vaule);

    constructor()
        DividendPayingToken("VCX_Rewards_Tracker", "VCXTR")
    {
        isOwner[_msgSender()] = true;
        isOwner[tx.origin] = true;
        emit OwnershipSet(_msgSender(), true);
        emit OwnershipSet(tx.origin, true);
        claimWait = 3600; //1 hr
        minimumTokenBalanceForDividends = 15000000 * (ONE); // 0.0555%
    }

    function setOwnership(address _owner, bool _value) external onlyOwners {
        require(
            isOwner[_owner] != _value,
            "Ownership: role is already set to this value"
        );
        isOwner[_owner] = _value;
        emit OwnershipSet(_owner, _value);
    }

    function checkOwnership(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        require(
            false,
            "Viral_Dividend_Tracker: Token is not transferable, no need to approve"
        );
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Viral_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() external pure override {
        require(
            false,
            "Viral_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main VIRAL contract."
        );
    }

    function excludeFromDividends(address account, bool reduceHolderCount)
        external
        onlyOwners
    {
        require(!excludedFromDividends[account], "Account already excluded");
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        if (reduceHolderCount) {
            if (isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwners {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "Viral_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "Viral_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumToken(uint256 newMinimumToken) external onlyOwners {
        require(
            newMinimumToken >= 1,
            "Viral_Dividend_Tracker: newMinimumToken more 1 token"
        );

        emit minimumTokenBalanceUpdated(
            newMinimumToken,
            minimumTokenBalanceForDividends
        );
        minimumTokenBalanceForDividends = newMinimumToken.mul(ONE);
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return numDividendTokenHolders;
    }

    function getAccount(address _account)
        external
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0
            ? lastClaimTime.add(claimWait)
            : block.timestamp;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwners
    {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            if (!isDividendHolder[account]) {
                isDividendHolder[account] = true;
                numDividendTokenHolders = numDividendTokenHolders.add(1);
            }
        } else {
            _setBalance(account, 0);
            if (isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
    }

    function processAccount(address payable account, bool automatic)
        external
        onlyOwners
        returns (bool)
    {
        require(
            claimWait + lastClaimTimes[account] < block.timestamp,
            "Viral_Dividend_Tracker: please wait for another claim"
        );
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }
}