// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "../ERC20/ERC20TradableVotes.sol";

contract ERC20TradableVotesMintable is ERC20TradableVotes {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 price_,
        uint8 capitalShareRate_
    )
        ERC20TradableVotes(name_, symbol_, decimals_, price_, capitalShareRate_)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function mint(address account, uint256 amount) public {
        require(account != address(0), "mint to zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "./ERC20Tradable.sol";
import "../interfaces/IVotes.sol";

/**
 * @title ERC20TradableVotes
 * @notice ERC20Tradable contract that allows to vote for token price.
 * @author Ilya Kubariev <[email protected]>
 */
contract ERC20TradableVotes is IVotes, ERC20Tradable {
    uint8 internal immutable _capitalShareRate;

    uint64 internal _duration;
    uint64 internal _votingStartedTime;
    uint256 internal _suggestedPrice;
    uint256 internal _acceptPower;
    uint256 internal _rejectPower;
    uint256 internal _votingNumber;
    mapping(uint256 => mapping(address => bool)) internal _votes;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 price_,
        uint8 capitalShareRate_
    ) ERC20Tradable(name_, symbol_, decimals_, price_) {
        _capitalShareRate = capitalShareRate_;
    }

    /**
     * @inheritdoc IVotes
     */
    function price()
        public
        view
        override(IVotes, ERC20Tradable)
        returns (uint256)
    {
        return _price * divider;
    }

    /**
     * @inheritdoc IVotes
     */
    function suggestedPrice() public view returns (uint256) {
        return _suggestedPrice * divider;
    }

    /**
     * @inheritdoc IVotes
     */
    function capitalShareRate() public view returns (uint8) {
        return _capitalShareRate;
    }

    /**
     * @inheritdoc IVotes
     */
    function acceptPower() public view returns (uint256) {
        return _acceptPower;
    }

    /**
     * @inheritdoc IVotes
     */
    function rejectPower() public view returns (uint256) {
        return _rejectPower;
    }

    /**
     * @inheritdoc IVotes
     */
    function votingStartedTime() public view returns (uint64) {
        return _votingStartedTime;
    }

    /**
     * @inheritdoc IVotes
     */
    function votingDuration() public view returns (uint64) {
        return _duration;
    }

    /**
     * @inheritdoc IVotes
     */
    function lastVotingNumber() public view returns (uint256) {
        return _votingNumber;
    }

    /**
     * @inheritdoc IVotes
     */
    function isWhale(address whale) public view returns (bool) {
        return balanceOf(whale) >= _totalSupply / (100 / _capitalShareRate);
    }

    /**
     * @inheritdoc IVotes
     */
    function startVoting(uint256 suggestedPrice_, uint64 duration)
        external
        onlyWhale(msg.sender)
        returns (bool)
    {
        require(
            _votingStartedTime == 0 && _duration == 0,
            "voting has already started"
        );
        require(suggestedPrice_ > 0, "suggestedPrice must be positive");
        require(duration > 0, "duration must be positive");

        (_suggestedPrice, _duration, _votingStartedTime) = (
            suggestedPrice_,
            duration,
            _time()
        );
        _votingNumber++;

        emit VotingStart(msg.sender, suggestedPrice_, duration, _votingNumber);
        return true;
    }

    /**
     * @inheritdoc IVotes
     */
    function vote(bool decision) external onlyWhale(msg.sender) returns (bool) {
        uint64 time = _time();
        require(
            _votingStartedTime > 0 && _duration > 0,
            "voting has not been started"
        );
        require(time <= _votingStartedTime + _duration, "voting ended");
        address sender = msg.sender;
        require(!_votes[_votingNumber][sender], "already voted");

        uint256 power = balanceOf(sender);

        if (decision) {
            _acceptPower += power;
        } else {
            _rejectPower += power;
        }

        _votes[_votingNumber][sender] = true;

        emit Vote(sender, decision, power);
        return true;
    }

    /**
     * @inheritdoc IVotes
     */
    function endVoting() external returns (bool) {
        uint64 time = _time();
        require(
            _votingStartedTime > 0 && _duration > 0,
            "voting has not been started"
        );
        require(time > _votingStartedTime + _duration, "voting is in progress");

        emit VotingEnd(
            msg.sender,
            _price,
            _suggestedPrice,
            _acceptPower,
            _rejectPower
        );

        if (_acceptPower > _rejectPower) {
            _price = _suggestedPrice;
        }

        delete _suggestedPrice;
        delete _duration;
        delete _votingStartedTime;
        delete _acceptPower;
        delete _rejectPower;

        return true;
    }

    /**
     * @dev one place to get time of block.
     * @return current timestamp of block.
     */
    function _time() internal view returns (uint64) {
        // solhint-disable-next-line not-rely-on-time
        return uint64(block.timestamp);
    }

    /**
     * @notice allows to call function only for `whale`
     * @param whale - address to check
     */
    modifier onlyWhale(address whale) {
        require(isWhale(whale), "not a whale");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "../interfaces/ITradable.sol";

/**
 * @title ERC20Tradable
 * @notice ERC20 contract that allows to trade tokens.
 * @author Ilya Kubariev <[email protected]uck.io>
 */
contract ERC20Tradable is ITradable, ERC20 {
    /**
     * @return divider - returns divider for price.
     */
    uint256 public immutable divider;

    uint256 internal _token0;
    uint256 internal _token1;
    uint256 internal _price;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 price_
    ) ERC20(name_, symbol_, decimals_) {
        divider = 10**decimals_;
        _price = price_;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @inheritdoc ITradable
     */
    function price() public view virtual returns (uint256) {
        return _price * divider;
    }

    /**
     * @inheritdoc ITradable
     */
    function liquidity()
        public
        view
        returns (uint256 amount, uint256 tokenAmount)
    {
        (amount, tokenAmount) = (_token0, _token1);
    }

    /**
     * @inheritdoc ITradable
     */
    function addLiquidity(uint256 tokenAmount) external payable returns (bool) {
        uint256 amount = msg.value;
        require(amount > 0, "amount must be positive");
        require(tokenAmount > 0, "tokenAmount must be positive");

        _changeLiquidity(amount, tokenAmount, _add, _add);

        transferFrom(msg.sender, address(this), tokenAmount);

        return true;
    }

    /**
     * @inheritdoc ITradable
     */
    function buy() external payable returns (bool) {
        uint256 amount = msg.value;
        require(amount > 0, "amount must be positive");
        uint256 tokenAmount = amount / (price() / divider);
        require(tokenAmount > 0, "tokenAmount must be positive");
        require(
            int256(_token1) - int256(tokenAmount) > 0,
            "not enough liquidity"
        );

        _changeLiquidity(amount, tokenAmount, _add, _sub);

        address sender = msg.sender;
        _transfer(address(this), sender, tokenAmount);

        emit Buy(sender, tokenAmount, amount);

        return true;
    }

    /**
     * @inheritdoc ITradable
     */
    function sell(uint256 tokenAmount) external returns (bool) {
        require(tokenAmount > 0, "tokenAmount must be positive");
        uint256 amount = (tokenAmount * price()) / divider;
        require(amount > 0, "amount must be positive");
        require(int256(_token0) - int256(amount) > 0, "not enough liquidity");

        _changeLiquidity(amount, tokenAmount, _sub, _add);

        address sender = msg.sender;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = sender.call{value: amount}("");
        require(success, "transfer failed");

        transferFrom(sender, address(this), tokenAmount);

        emit Sell(sender, amount, tokenAmount);

        return true;
    }

    /**
     * @inheritdoc ITradable
     */
    function release(address recipient) external returns (bool) {
        require(recipient != address(0), "recipient is zero address");
        address addr = address(this);
        uint256 freeAmount = addr.balance - _token0;
        uint256 freeTokenAmount = balanceOf(addr) - _token1;
        require(freeAmount > 0 || freeTokenAmount > 0, "nothing to transfer");

        if (freeTokenAmount > 0) {
            _transfer(addr, recipient, freeTokenAmount);
        }

        if (freeAmount > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = recipient.call{value: freeAmount}("");
            require(success, "transfer failed");
        }

        return true;
    }

    /**
     * @dev internal func to change liquidity in different ways.
     * @param amount - ether amount to change in liquidity.
     * @param tokenAmount - token amount to change in liquidity.
     * @param op0 - function to apply to ether liquidity.
     * @param op1 - function to apply to token liquidity.
     */
    function _changeLiquidity(
        uint256 amount,
        uint256 tokenAmount,
        function(uint256, uint256) pure returns (uint256) op0,
        function(uint256, uint256) pure returns (uint256) op1
    ) internal {
        _token0 = op0(_token0, amount);
        _token1 = op1(_token1, tokenAmount);

        emit LiquidityChanged(msg.sender, _token1, _token0);
    }

    function _add(uint256 first, uint256 second)
        private
        pure
        returns (uint256)
    {
        return first + second;
    }

    function _sub(uint256 first, uint256 second)
        private
        pure
        returns (uint256)
    {
        return first - second;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

/**
 * @title IVotes
 * @notice interface for Votes tokens.
 * @author Ilya Kubariev <[email protected]>
 */
interface IVotes {
    /**
     * @notice emits whenever {startVoting} called.
     * @param account - initiator of {startVoting}.
     * @param suggestedPrice - price that was suggested.
     * @param duration - duration of started voting in seconds.
     * @param votingNumber - number of started voting.
     */
    event VotingStart(
        address indexed account,
        uint256 suggestedPrice,
        uint64 duration,
        uint256 votingNumber
    );

    /**
     * @notice emits whenever {vote} called.
     * @param account - initiator of {vote}.
     * @param decision - accept or reject.
     * @param power - power of `account` vote.
     */
    event Vote(address indexed account, bool decision, uint256 power);

    /**
     * @notice emits whenever {endVoting} called.
     * @param account - initiator of {endVoting}.
     * @param previousPrice - price that was before voting.
     * @param price - new price.
     * @param acceptPower - power for accepting voting.
     * @param declinePower - power for rejecting voting.
     */
    event VotingEnd(
        address indexed account,
        uint256 previousPrice,
        uint256 price,
        uint256 acceptPower,
        uint256 declinePower
    );

    /**
     * @return currect price of token.
     */
    function price() external view returns (uint256);

    /**
     * @return currect suggested price of token (zero if no voting in progress).
     */
    function suggestedPrice() external view returns (uint256);

    /**
     * @return capital share rate that is needed to participate in voting.
     */
    function capitalShareRate() external view returns (uint8);

    /**
     * @return accept power for current voting (zero if no voting in progress).
     */
    function acceptPower() external view returns (uint256);

    /**
     * @return reject power for current voting (zero if no voting in progress).
     */
    function rejectPower() external view returns (uint256);

    /**
     * @return time when current voting started (zero if no voting in progress).
     */
    function votingStartedTime() external view returns (uint64);

    /**
     * @return duration of current voting (zero if no voting in progress).
     */
    function votingDuration() external view returns (uint64);

    /**
     * @return number of last voting started.
     */
    function lastVotingNumber() external view returns (uint256);

    /**
     * @param whale - address to check
     * @return true if `whale` is whale, false if not.
     */
    function isWhale(address whale) external view returns (bool);

    /**
     * @param suggestedPrice - price to vote.
     * @param duration - duration of new vote.
     * @return true if succeeded.
     */
    function startVoting(uint256 suggestedPrice, uint64 duration)
        external
        returns (bool);

    /**
     * @param decision - accept or reject current voting.
     * @return true if succeeded.
     */
    function vote(bool decision) external returns (bool);

    /**
     * @notice end current voting.
     * @return true if succeeded.
     */
    function endVoting() external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title ERC20
 * @notice Default ERC20 implementation.
 * @author Ilya Kubariev <[email protected]>
 */
contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        (_name, _symbol, _decimals) = (name_, symbol_, decimals_);
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(from, to);
        require(currentAllowance >= amount, "transfer exceeds allowance");

        _approve(from, to, currentAllowance - amount);
        _transfer(from, to, amount);

        return true;
    }

    /**
     * @dev internal function to change allowances.
     * @param owner - change allowance for this address.
     * @param spender - address of spender of funds.
     * @param amount - token amount to allow to transfer.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "owner is zero address");
        require(spender != address(0), "spender is zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @dev internal function to change balances.
     * @param from - reduce from this address.
     * @param to - add to this address.
     * @param amount - token amount to change.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer to zero address");
        uint256 balanceFrom = _balances[from];
        require(balanceFrom >= amount, "transfer amount exceeds balance");

        _balances[from] = balanceFrom - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

/**
 * @title ITradable
 * @notice interface for Tradable tokens.
 * @author Ilya Kubariev <[email protected]>
 */
interface ITradable {
    /**
     * @notice emits whenever {buy} called.
     * @param account - initiator of {buy} tokens.
     * @param tokenAmount - token amount that account received.
     * @param amount - ether amount that account spent.
     */
    event Buy(address indexed account, uint256 tokenAmount, uint256 amount);

    /**
     * @notice emits whenever {sell} called.
     * @param account - initiator of {sell} tokens.
     * @param amount - ether amount that account received.
     * @param tokenAmount - token amount that account sold.
     */
    event Sell(address indexed account, uint256 amount, uint256 tokenAmount);

    /**
     * @notice emits whenever {addLiquidity}, {buy} or {sell} called.
     * @param account - initiator of {addLiquidity}, {buy} or {sell} tokens.
     * @param amount - ether amount of new liquidity.
     * @param tokenAmount - token amount of new liquidity.
     */
    event LiquidityChanged(
        address indexed account,
        uint256 tokenAmount,
        uint256 amount
    );

    /**
     * @return currect price of token.
     */
    function price() external view returns (uint256);

    /**
     * @return amount - ether amount of liquidity.
     * @return tokenAmount - token amount of liquidity.
     */
    function liquidity()
        external
        view
        returns (uint256 amount, uint256 tokenAmount);

    /**
     * @notice add ether and token liquidity.
     * @dev to ether liquidity will be added `msg.value`.
     * @param tokenAmount - token amount to add to liquidity.
     * @return true if succeeded.
     */
    function addLiquidity(uint256 tokenAmount) external payable returns (bool);

    /**
     * @notice buy token with ether at {price}.
     * @dev to ether liquidity will be added `msg.value`.
     * @return true if succeeded.
     */
    function buy() external payable returns (bool);

    /**
     * @notice sell token to ether at {price}.
     * @dev to token liquidity will be added `tokenAmount`.
     * @param tokenAmount - sell this amount of tokens.
     * @return true if succeeded.
     */
    function sell(uint256 tokenAmount) external returns (bool);

    /**
     * @notice send surplus of tokens and eth.
     * @param recipient - surplus destination address.
     * @return true if succeeded.
     */
    function release(address recipient) external returns (bool);
}

// SPDX-License-Identifier: MIT
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