// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "../Interfaces/IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

pragma solidity >= 0.8.0;

import "./ERC/ERC20.sol";
import "./Interfaces/IERC20.sol";

// Contract expects external injection of underlying tokens in order to maintain the generation of interest for infinite deposits at a 5% APY
// Fake Euler Token
contract FDToken is ERC20 {

    uint256 immutable public underlyingDecimals;

    address immutable public underlyingAsset;

    uint256 public debtAllowance = 100000000000000000000;

    uint256 public lastTraded;

    // @param u underlying asset
    // @param n name
    // @param s symbol
    // @comment always 18 decimals
    constructor (address u, string memory n, string memory s) ERC20(n, s, 18) {
        underlyingDecimals = IERC20(u).decimals();
        underlyingAsset = u;
    }

    function totalSupplyExact() external view returns (uint){
        return (_totalSupply * 10e9);
    }

    function balanceOfExact(address user) external view returns (uint){
        return (_balanceOf[user] * 10e9);
    }

    // Borrows by minting dTokens and receiving underlying
    // @param subAccountId unused euler param
    // @param amount an amount of underlying tokens
    function borrow(uint subAccountId, uint amount) external {
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        lastTraded = block.timestamp;
    }

    // "Repays" debt by sending underlying and burning dTokens
    // @param subAccountId unused euler param
    // @param amount an amount of underlying tokens
    function repay(uint subAccountId, uint amount) external {
        IERC20(underlyingAsset).transfer(msg.sender, amount);
        _burn(msg.sender, amount);
        lastTraded = block.timestamp;
    }

    function flashLoan(uint amount, bytes calldata data) external {
        uint256 initialBalance = IERC20(underlyingAsset).balanceOf(address(this));
        IERC20(underlyingAsset).transfer(msg.sender, amount);
        (bool success, bytes memory result) = address(this).delegatecall(
                data
            );

        if (!success) revert();
        require(IERC20(underlyingAsset).balanceOf(address(this)) >= initialBalance);
    }
    
    function approveDebt(uint subAccountId, address spender, uint amount) external returns (bool){
        return(true);
    }

    // A simple method to top off the contract with underlying tokens given there is no actual interest accrual mechanism
    function refill(uint256 amount) external {
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
    }

    function changeDebtAllowance(uint256 newAllowance) external {
        debtAllowance = newAllowance;
    }
}

pragma solidity >=0.8.0;

import './Interfaces/IERC20.sol';
import './FEToken.sol';
import './FDToken.sol';

// Contract expects external injection of underlying tokens in order to maintain the generation of interest for infinite deposits at a 5% APY
// Fake Euler Token
contract FEMarket {
    mapping(address => int96) public InterestRates;

    uint32 public reserveFee;

    uint256 public rateModel;

    address public chainlinkAggregator;

    struct market {
        address EToken;
        address DToken;
    }

    mapping(address => address) ETokenstoDTokens;

    mapping(address => market) Markets;

    mapping(address => uint256) RateModels;

    address[] public entered;

    constructor(
        uint32 _reserveFee,
        uint256 _rateModel,
        address _chainlinkAggregator,
        address[] memory _entered
    ) {
        reserveFee = _reserveFee;
        rateModel = _rateModel;
        chainlinkAggregator = _chainlinkAggregator;
        entered = _entered;
    }

    function interestRateModel(address underlying)
        external
        view
        returns (uint256)
    {
        return (RateModels[underlying]);
    }

    /// returns FD token
    function activateMarket(address underlying, int96 _interestRate)
        external
        returns (address)
    {
        FEToken _FEToken = new FEToken(
            underlying,
            string.concat('FE', IERC20(underlying).name()),
            string.concat('FE', IERC20(underlying).symbol())
        );
        FDToken _FDToken = new FDToken(
            underlying,
            string.concat('FD', IERC20(underlying).name()),
            string.concat('FD', IERC20(underlying).symbol())
        );
        Markets[underlying] = market(address(_FEToken), address(_FDToken));
        ETokenstoDTokens[address(_FEToken)] = address(_FDToken);
        InterestRates[underlying] = _interestRate;

        return address(_FDToken);
    }

    function underlyingToEToken(address underlying)
        external
        view
        returns (address)
    {
        return (Markets[underlying].EToken);
    }

    function underlyingToDToken(address underlying)
        external
        view
        returns (address)
    {
        return (Markets[underlying].DToken);
    }

    function eTokenToUnderlying(address eToken)
        external
        view
        returns (address underlying)
    {
        return (FEToken(eToken).underlyingAsset());
    }

    function dTokenToUnderlying(address dToken)
        external
        view
        returns (address underlying)
    {
        return (FDToken(dToken).underlyingAsset());
    }

    function eTokenToDToken(address eToken)
        external
        view
        returns (address dTokenAddr)
    {
        return (ETokenstoDTokens[eToken]);
    }

    function interestRate(address underlying) external view returns (int96) {
        return (InterestRates[underlying]);
    }

    /// consumes underlying
    function getPricingConfig(address)
        external
        view
        returns (
            uint16 pricingType,
            uint32 pricingParameters,
            address pricingForwarded
        )
    {
        pricingType = uint16(1);
        pricingParameters = 0;
        pricingForwarded = address(0);
    }

    /// consumes underlying
    function getChainlinkPriceFeedConfig(address)
        external
        view
        returns (address _chainlinkAggregator)
    {
        return (chainlinkAggregator);
    }

    /// consumes account
    function getEnteredMarkets(address)
        external
        view
        returns (address[] memory)
    {
        return (entered);
    }

    function enterMarket(uint256 subAccountId, address newMarket) external {}

    function exitMarket(uint256 subAccountId, address oldMarket) external {}

    function setInterestRate(address underlying, int96 _interestRate) external {
        InterestRates[underlying] = _interestRate;
    }

    function setRateModel(address underlying, uint256 _rateModel) external {
        RateModels[underlying] = _rateModel;
    }
}

pragma solidity >= 0.8.0;

import "./ERC/ERC20.sol";
import "./Interfaces/IERC20.sol";

// Contract expects external injection of underlying tokens in order to maintain the generation of interest for infinite deposits at a 5% APY
// Fake Euler Token
contract FEToken is ERC20 {

    uint256 immutable public underlyingDecimals;

    address immutable public underlyingAsset;

    uint256 public exchangeRate = 1000000000000000000;

    uint256 public rateDenominator = 20; // Equivalent of 5% APY

    uint256 public lastTraded;

    // @param u underlying asset
    // @param n name
    // @param s symbol
    // @comment always 18 decimals
    constructor (address u, string memory n, string memory s) ERC20(n, s, 18) {
        underlyingDecimals = IERC20(u).decimals();
        underlyingAsset = u;
    }

    // Total supply of the underlying asset
    function totalSupplyUnderlying() external view returns (uint) {
        return IERC20(underlyingAsset).totalSupply();
    }

    // Converts balanceOf an accounts shares into underlying
    function balanceOfUnderlying(address account) external view returns (uint) {
        return convertBalanceToUnderlying(_balanceOf[account]);
    }

    // Converts an amount of underlying assets to eToken shares
    // Does not mutate state
    // @param _assets the amount of underlying assets
    function convertUnderlyingToBalance(uint256 _assets)
        public
        view
        returns (uint256 shares) {
            uint256 diff = block.timestamp - lastTraded;
            if (diff != 0) {
                uint256 tempExchangeRate = exchangeRate + (exchangeRate * diff/(31536000 * rateDenominator));
                return (_assets / ((tempExchangeRate / (1*10^(18 + underlyingDecimals - decimals)))));
            }
            else {
                return (_assets / ((exchangeRate / (1*10^(18 + underlyingDecimals - decimals)))));
            }
        }

    // Converts an amount of eToken shares to underlying assets
    // Does not mutate state
    // @param _shares the amount of eToken shares
    function convertBalanceToUnderlying(uint256 _shares)
        public
        view
        returns (uint256 assets) {
            uint256 diff = block.timestamp - lastTraded;
            if (diff != 0 ) {
                uint256 tempExchangeRate = exchangeRate + (exchangeRate * diff/(31536000 * rateDenominator));
                return (_shares * ((tempExchangeRate / (1*10^(18 + underlyingDecimals - decimals)))));
            }
            else {
                return (_shares * ((exchangeRate / (1*10^(18 + underlyingDecimals - decimals)))));
            } 
    }

    // Mutates state and accrues interest
    function touch() public {
        uint256 diff = block.timestamp - lastTraded;
        exchangeRate = exchangeRate + (exchangeRate * diff/(31536000 * rateDenominator));
    }

    // Deposits an amount of underlying tokens, minting eTokens
    // @param subAccountId unused euler param
    // @param amount an amount of underlying tokens
    function deposit(uint subAccountId, uint amount) external {
        touch();
        uint256 shares = convertUnderlyingToBalance(amount);
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
        lastTraded = block.timestamp;
    }

    // Withdraws an amount of underlying, burning eTokens
    // @param subAccountId unused euler param
    // @param amount an amount of underlying tokens
    function withdraw(uint subAccountId, uint amount) external {
        touch();
        uint256 shares = convertUnderlyingToBalance(amount);
        IERC20(underlyingAsset).transfer(msg.sender, amount);
        _burn(msg.sender, shares);
        lastTraded = block.timestamp;
    }

    // Mints an amount of eToken shares, depositing underlying tokens
    // @param subAccountId unused euler param
    // @param amount an amount of eToken shares
    function mint(uint subAccountId, uint amount) external {
        touch();
        uint256 assets = convertBalanceToUnderlying(amount);
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), assets);
        _mint(msg.sender, amount);
        lastTraded = block.timestamp;
    }

    // Burns an amount of eToken shares, withdrawing underlying tokens
    // @param subAccountId unused euler param
    // @param amount an amount of eToken shares
    function burn(uint subAccountId, uint amount) external {
        touch();
        uint256 assets = convertBalanceToUnderlying(amount);
        IERC20(underlyingAsset).transfer(msg.sender, assets);
        _burn(msg.sender, amount);    
        lastTraded = block.timestamp;   
    }

    // Random Euler method that transfers max amount of tokens
    // @param from the person having tokens removed
    // @param to the person receiving tokens
    function transferFromMax(address from, address to) external returns (bool) {
        if (_allowance[from][to] >= _balanceOf[from]) {
            _burn(from, _balanceOf[from]);
            _mint(to, _balanceOf[from]);
            return true;
        }
        else {
            return false;
        }
    }

    // A simple method to top off the contract with underlying tokens given there is no actual interest accrual mechanism
    function refill(uint256 amount) external {
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
    }

    function changeRate(uint256 newRateDenominator) external {
        rateDenominator = newRateDenominator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the number of decimals the token uses
     */
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the oFYTokenional metadata functions from the ERC20 standard.
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