// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "IXToken.sol";
import "IDebtToken.sol";
import "PriceOracle.sol";
import "PoolConfiguration.sol";
import "math.sol";

/**
 * @author  . MEBARKIA Abdenour
 * @title   . PoolLogic
 * @dev     . validate some end-user functions in the Pool contract
 */

contract PoolLogic is DSMath {
    uint256 public constant maxAmountRate = 7500; //in basis points
    PoolConfiguration public poolConfiguration;

    constructor(address _poolConfigurationAddress) {
        poolConfiguration = PoolConfiguration(_poolConfigurationAddress);
    }

    /**
     * @dev     . get the user xToken balance in USD
     * @param   _account  . the user's address
     * @param   _underlyingAsset  . the asset underlying asset's xToken
     * @return  uint256  . returns user xToken balance in USD
     */
    function getUserBalanceInUSD(address _account, address _underlyingAsset)
        internal
        view
        returns (uint256)
    {
        address xToken = poolConfiguration.underlyingAssetToXtoken(
            _underlyingAsset
        );
        uint256 userBalance = IXToken(xToken).balanceOf(_account);

        address priceOracleAddress = poolConfiguration
            .underlyingAssetToPriceOracle(_underlyingAsset);
        PriceOracle priceOracle = PriceOracle(priceOracleAddress);

        uint256 assetPrice = priceOracle.getLatestPrice();

        uint256 userBalanceInUSD = userBalance * assetPrice;
        return userBalanceInUSD;
    }

    /**
     * @dev     . get the user debtToken balance in USD
     * @param   _account  . the user's address
     * @param   _underlyingAsset  . the asset underlying asset's xToken
     * @return  uint256  . returns user debtToken balance in USD
     */
    function getUserDebtInUSD(address _account, address _underlyingAsset)
        internal
        view
        returns (uint256)
    {
        address debtToken = poolConfiguration.underlyingAssetToDebtToken(
            _underlyingAsset
        );
        uint256 userDebt = IDebtToken(debtToken).balanceOf(_account);

        address priceOracleAddress = poolConfiguration
            .underlyingAssetToPriceOracle(_underlyingAsset);
        PriceOracle priceOracle = PriceOracle(priceOracleAddress);

        uint256 assetPrice = priceOracle.getLatestPrice();

        uint256 userDebtInUSD = userDebt * assetPrice;
        return userDebtInUSD;
    }

    /**
     * @dev     . get an amount of an underlying asset price in USD
     * @param   _amount  . the amount to get its price
     * @param   _underlyingAsset  . the underlying asset address
     * @return  uint256  . price in USD
     */
    function getAmountInUSD(uint256 _amount, address _underlyingAsset)
        internal
        view
        returns (uint256)
    {
        address priceOracleAddress = poolConfiguration
            .underlyingAssetToPriceOracle(_underlyingAsset);
        PriceOracle priceOracle = PriceOracle(priceOracleAddress);

        uint256 assetPrice = priceOracle.getLatestPrice();

        uint256 amountInUSD = _amount * assetPrice;

        return amountInUSD;
    }

    /**
     * @dev     . tells if user is legitimate to borrow
     * @param   _account  . the address of the user who wants to borrow
     * @param   _asset  . The address of the underlying asset to borrow
     * @param   _amount  . The amount to be borrowed
     * @param   _collateral  . he address of the underlying asset to set as collateral
     * @return  bool  . success boolian
     * @return  uint256  . the amount borrowed if the user is legitimate to borrow otherwise it returns 0
     */
    function validateBorrow(
        address _account,
        address _asset,
        uint256 _amount,
        address _collateral
    ) public view returns (bool, uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            poolConfiguration.isAvailable(_collateral),
            "token not available"
        );
        address priceOracleAddress = poolConfiguration
            .underlyingAssetToPriceOracle(_collateral);
        PriceOracle priceOracle = PriceOracle(priceOracleAddress);

        uint256 collateralPrice = priceOracle.getLatestPrice();

        uint256 userBalanceInUSD = getUserBalanceInUSD(_account, _collateral);

        uint256 amountInUSD = getAmountInUSD(_amount, _asset);

        uint256 amountOfCollateral = amountInUSD / collateralPrice;

        uint256 maxAmountInUSD = (userBalanceInUSD / 10000) * maxAmountRate;

        if (amountInUSD <= maxAmountInUSD) {
            return (true, amountOfCollateral);
        } else {
            return (false, 0);
        }
    }

    /**
     * @dev     . tells if user is legitimate to withdraw
     * @param   _account  . the address of the user who wants to withdraw
     * @param   _underlyingAsset  . The address of the underlying asset to withdraw
     * @param   _amount  . The amount to be withdrawn
     * @return  bool  . legitimacy boolian
     */
    function validateWithdraw(
        address _account,
        address _underlyingAsset,
        uint256 _amount
    ) public view returns (bool) {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            poolConfiguration.isAvailable(_underlyingAsset),
            "token not available"
        );

        address xtoken = poolConfiguration.underlyingAssetToXtoken(
            _underlyingAsset
        );
        uint256 userBalance = IXToken(xtoken).balanceOf(_account);

        if (_amount > userBalance) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @dev     . get the collateral amount to mint depending on an amount of asset
     * @param   _asset  . address of the asset
     * @param   _amount  . the amount of the asset
     * @param   _collateral  . the address of the collateral to mint
     * @return  uint256  . collateral amount
     */
    function getCollateralAmountToMint(
        address _asset,
        uint256 _amount,
        address _collateral
    ) public view returns (uint256) {
        address priceOracleAddress = poolConfiguration
            .underlyingAssetToPriceOracle(_collateral);
        PriceOracle priceOracle = PriceOracle(priceOracleAddress);

        uint256 collateralPrice = priceOracle.getLatestPrice();
        uint256 amountOfAssetInUSD = getAmountInUSD(_amount, _asset);

        return amountOfAssetInUSD / collateralPrice;
    }

    /**
     * @dev     . tells if user is legitimate to liquidate a non-healthy position collateral-wise
     * @param   _user  . The address of the borrower getting liquidated
     * @param   _asset  . The address of the underlying borrowed asset to be repaid with the liquidation
     * @param   _collateral  . The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param   _collateralAmount  . the amount of collateral borrower hass
     * @return  bool  . legitimacy boolian
     * @return  uint256  . the amount undercollateralized
     */
    function validateLiquidation(
        address _user,
        address _asset,
        address _collateral,
        uint256 _collateralAmount
    ) public view returns (bool, uint256) {
        uint256 collateralInUSD = getAmountInUSD(
            _collateralAmount,
            _collateral
        );
        uint256 debtInUSD = getUserDebtInUSD(_user, _asset);

        if (collateralInUSD >= debtInUSD) {
            return (false, 0);
        } else {
            uint256 undercollateralizedAmountInUSD = debtInUSD -
                collateralInUSD;

            address priceOracleAddress = poolConfiguration
                .underlyingAssetToPriceOracle(_collateral);
            PriceOracle priceOracle = PriceOracle(priceOracleAddress);

            uint256 assetPrice = priceOracle.getLatestPrice();

            return (true, undercollateralizedAmountInUSD / assetPrice);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "IERC20.sol";

interface IXToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function transferUnderlyingAssetTo(address _account, uint256 _amount)
        external;

    function getTotalDeposited() external view returns (uint256);

    function setTotalDeposited(uint256 _totalDeposited) external;
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
pragma solidity ^0.8.12;
import "IERC20.sol";

interface IDebtToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function getTotalBorrowed() external view returns (uint256);

    function setTotalBorrowed(uint256 _totalBorrowed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "AggregatorV3Interface.sol";

/**
 * @author  . Mebarkia Abdenour
 * @title   . PriceOracle
 * @dev     . get a price of specified pair - e.g (dai / usd )
 */

contract PriceOracle {
    AggregatorV3Interface public priceFeed;
    uint256 public decimals;

    constructor(address _priceFeedAddress, uint256 _decimals) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        decimals = _decimals;
    }

    /**
     * @dev     .  get the latest price of an asset
     * @return  uint256  . the latest price of an asset
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (decimals == 8) {
            uint256 latestPrice = uint256(price / 1e8);
            return latestPrice;
        }
        if (decimals == 18) {
            uint256 latestPrice = uint256(price / 1e18);
            return latestPrice;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "XToken.sol";
import "DebtToken.sol";
import "Ownable.sol";
import "PriceOracle.sol";

import "ReservesManager.sol";

import {DataTypes} from "DataTypes.sol";

/**
 * @author  . MEBARKIA Abdenour
 * @title   . PoolConfiguration
 * @dev     . To add new token and all the related configuration
 */

contract PoolConfiguration is Ownable {
    address public poolAddress;
    ReservesManager public reservesManager;
    XToken internal xtoken;
    DebtToken internal debtToken;
    PriceOracle internal priceOracle;

    mapping(address => address) public underlyingAssetToXtoken;
    mapping(address => address) public underlyingAssetToDebtToken;
    mapping(address => bool) public isAvailable;
    mapping(address => address) public underlyingAssetToPriceOracle;
    mapping(address => DataTypes.Reserve) public underlyingAssetToReserve;

    address[] public tokens;

    constructor(address _poolAddress) {
        poolAddress = _poolAddress;
    }

    function setReserveManagerContract(address _reserveManagerAddress)
        external
        onlyOwner
    {
        reservesManager = ReservesManager(_reserveManagerAddress);
    }

    /**
     * @dev     . Add new token to the protocol utilisation panel
     * @param   _name  . the name of the underlying asset to be added
     * @param   _symbol  .  the symbol of the underlying asset to be added
     * @param   _underlyingAsset  .  the address of the underlying asset to be added
     * @param   _priceFeedAddress  . the address of the underlying asset's price feed contract
     * @param   _decimals  .  the name of the underlying asset to be added
     * @param   _baseVariableBorrowRate  . base variable borrow rate to calculate the interests/debts
     * @param   _interestRateSlope  . interest rate slope to calculate the interests/debts
     * @return  address  . the xToken address of the underlying asset
     * @return  address  . the dentToken address of the underlying asset
     * @return  address  . the priceOracle address
     */
    function addToken(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _priceFeedAddress,
        uint256 _decimals,
        uint256 _baseVariableBorrowRate,
        uint256 _interestRateSlope
    )
        external
        onlyOwner
        returns (
            address,
            address,
            address
        )
    {
        xtoken = new XToken(
            string.concat("x", _name),
            string.concat("x", _symbol),
            _underlyingAsset,
            poolAddress,
            address(reservesManager)
        );

        debtToken = new DebtToken(
            string.concat("debt", _name),
            string.concat("debt", _symbol),
            _underlyingAsset,
            poolAddress,
            address(reservesManager)
        );

        reservesManager.initReserve(
            _underlyingAsset,
            _baseVariableBorrowRate,
            _interestRateSlope,
            address(xtoken),
            address(debtToken)
        );

        underlyingAssetToXtoken[_underlyingAsset] = address(xtoken);
        underlyingAssetToDebtToken[_underlyingAsset] = address(debtToken);
        isAvailable[_underlyingAsset] = true;

        priceOracle = new PriceOracle(_priceFeedAddress, _decimals);

        underlyingAssetToPriceOracle[_underlyingAsset] = address(priceOracle);
        tokens.push(_underlyingAsset);

        return (address(xtoken), address(debtToken), address(priceOracle));
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "ERC20.sol";
import "IERC20.sol";

import "ReservesManager.sol";

import "math.sol";

/**
 * @author  . MEBARKIA Abdenour
 * @title   . XToken
 * @dev     . Implements a x token to track the supplying positions of users
 */

contract XToken is ERC20, DSMath {
    address public poolAddress;
    address public underlyingAsset;

    ReservesManager public reservesManager;

    modifier onlyPool() {
        require(_msgSender() == poolAddress, "caller must be pool");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _poolAddress,
        address _reservesManagerAddress
    ) ERC20(_name, _symbol) {
        poolAddress = _poolAddress;
        underlyingAsset = _underlyingAsset;
        reservesManager = ReservesManager(_reservesManagerAddress);
    }

    /**
     * @dev     . Mints `amount` xTokens to `user`
     * - Only callable by the Pool
     * @param   _account  . The address receiving the minted tokens
     * @param   _amount  . The amount of tokens getting minted
     */
    function mint(address _account, uint256 _amount) external onlyPool {
        super._mint(_account, _amount);
    }

    /**
     * @dev     . Burns xTokens from `user`
     * -  Only callable by the Pool
     * @param   _account  . The owner of the xTokens, getting them burned
     * @param   _amount  . The amount being burned
     */
    function burn(address _account, uint256 _amount) external onlyPool {
        super._burn(_account, _amount);
    }

    function transferUnderlyingAssetTo(address _account, uint256 _amount)
        external
        onlyPool
    {
        IERC20(underlyingAsset).transfer(_account, _amount);
    }

    /**
     * @dev     . Calculates the balance of the user: principal balance + interest generated by the principal
     * @param   user  . The user whose balance is calculated
     * @return  uint256  . The balance of the user
     */
    function balanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 scaledBalance = super.balanceOf(user);

        if (scaledBalance == 0) {
            return 0;
        }

        return
            wmul(
                scaledBalance,
                reservesManager.getSupplyIndexSinceLastUpdate(underlyingAsset)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "IERC20.sol";
import "IXToken.sol";
import "IDebtToken.sol";
import "PoolConfiguration.sol";
import "math.sol";

import {DataTypes} from "DataTypes.sol";

/**
 * @author  . MEBARKIA Abdenour
 * @title   . ReservesManager
 * @dev     . Manage reserves and calculates debt & interests indexes
 */

contract ReservesManager is DSMath {
    address public poolConfigurationAddress;
    address public poolAddress;

    uint256 public constant SECONDS_PER_YEAR = 365 days;

    mapping(address => DataTypes.Reserve) public underlyingAssetToReserve;

    modifier onlyPool() {
        require(msg.sender == poolAddress, "caller must be pool");
        _;
    }

    modifier onlyPoolConfiguration() {
        require(
            msg.sender == poolConfigurationAddress,
            "caller must be pool configuration"
        );
        _;
    }

    constructor(address _poolConfigurationAddress, address _poolAddress) {
        poolConfigurationAddress = _poolConfigurationAddress;
        poolAddress = _poolAddress;
    }

    function getReserve(address _underlyingAsset)
        public
        view
        returns (DataTypes.Reserve memory)
    {
        return underlyingAssetToReserve[_underlyingAsset];
    }

    /**
     * @dev     . calculates the utilization rate of a reserve based on the total deposited / borrowed on the reserve
     * @param   _totalDeposited  . total amount deposited in a reserve
     * @param   _totalBorrowed  . total amount borrowed in a reserve
     * @return  uint256  . the utilization rate value
     */
    function updateUtilizationRate(
        uint256 _totalDeposited,
        uint256 _totalBorrowed
    ) internal pure returns (uint256) {
        uint256 utilizationRate;

        if (_totalDeposited == 0) {
            utilizationRate = 0;
        } else {
            utilizationRate = wdiv(_totalBorrowed, _totalDeposited);
        }

        return utilizationRate;
    }

    /**
     * @dev     . calculates the variable borrow rate of a reserve based on utilization rate, base variable borrow rate
     * & intereste rate slope of a reserve
     * @param   _utilizationRate  .  utilization rate of a reserve
     * @param   _baseVariableBorrowRate  . base variable borrow rate of a reserve
     * @param   _interestRateSlope  . intereste rate slope of a reserve
     * @return  uint256  . the variable borrow value
     */
    function updateVariableBorrowRate(
        uint256 _utilizationRate,
        uint256 _baseVariableBorrowRate,
        uint256 _interestRateSlope
    ) internal pure returns (uint256) {
        uint256 variableBorrowRate = add(
            _baseVariableBorrowRate,
            (wmul(_utilizationRate, _interestRateSlope))
        );

        return variableBorrowRate;
    }

    /**
     * @dev     . calculates the index of debt or interest of all users
     * @param   _latestIndex  . latest index
     * @param   _rate  . variable borrow rate / liquidity rate , dependes of the index we want to calculate
     * @param   _secondsSinceLastupdate  . number of seconds since latest update of a reserve
     * @return  uint256  . the index value
     */
    function updateIndex(
        uint256 _latestIndex,
        uint256 _rate,
        uint256 _secondsSinceLastupdate
    ) internal pure returns (uint256) {
        uint256 ratePerSecond = _rate / SECONDS_PER_YEAR;

        uint256 index = wmul(
            _latestIndex,
            add(1000000000000000000, ratePerSecond * _secondsSinceLastupdate)
        );

        return index;
    }

    /**
     * @dev     . update all the variable properties of a reserve, this function is called
     * whenever a user call this functions : supply, borrow, withdraw, repay
     * @param   _underlyingAsset  . The address of the underlying asset of the reserve
     * @param   _amount  . the amount user passed on one of the function quoted above
     * @param   _operation  . an integer that represents which function the user called
     *                           operation : value
     *                           supply : 0
     *                           borrow : 1
     *                           withdraw : 2
     *                           repay : 3
     */
    function updateState(
        address _underlyingAsset,
        uint256 _amount,
        uint256 _operation
    ) public onlyPool {
        DataTypes.Reserve memory reserve;
        reserve = underlyingAssetToReserve[_underlyingAsset];

        uint256 secondsSinceLastupdate = block.timestamp -
            reserve.lastUpdateTime;

        if (_operation == 0) {
            reserve.totalDeposited = reserve.totalDeposited + _amount;
        }
        if (_operation == 1) {
            reserve.totalBorrowed = reserve.totalBorrowed + _amount;
        }
        if (_operation == 2) {
            reserve.totalDeposited = reserve.totalDeposited - _amount;
        }
        if (_operation == 3) {
            reserve.totalBorrowed = reserve.totalBorrowed - _amount;
        }

        uint256 utilizationRate = updateUtilizationRate(
            reserve.totalDeposited,
            reserve.totalBorrowed
        );
        uint256 variableBorrowRate = updateVariableBorrowRate(
            utilizationRate,
            reserve.baseVariableBorrowRate,
            reserve.interestRateSlope
        );

        uint256 liquidityRate = wmul(variableBorrowRate, utilizationRate);

        uint256 variableBorrowIndex = updateIndex(
            reserve.variableBorrowIndex,
            variableBorrowRate,
            secondsSinceLastupdate
        );

        uint256 supplyIndex = updateIndex(
            reserve.supplyIndex,
            liquidityRate,
            secondsSinceLastupdate
        );

        reserve.utilizationRate = utilizationRate;
        reserve.variableBorrowRate = variableBorrowRate;
        reserve.variableBorrowIndex = variableBorrowIndex;
        reserve.liquidityRate = liquidityRate;
        reserve.supplyIndex = supplyIndex;
        reserve.lastUpdateTime = block.timestamp;

        underlyingAssetToReserve[_underlyingAsset] = reserve;
    }

    /**
     * @dev     . returns the variable borrow index needed to calculate the balance of user debtToken
     * @param   _underlyingAsset  . the adress of the underlying asset of the debtToken
     * @return  uint256  . variable borrow index
     */
    function getVariableBorrowIndexSinceLastUpdate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        DataTypes.Reserve memory reserve;
        reserve = underlyingAssetToReserve[_underlyingAsset];

        uint256 secondsSinceLastupdate = block.timestamp -
            reserve.lastUpdateTime;

        uint256 variableBorrowIndex = updateIndex(
            reserve.variableBorrowIndex,
            reserve.variableBorrowRate,
            secondsSinceLastupdate
        );

        return variableBorrowIndex;
    }

    /**
     * @dev     . returns the supply index needed to calculate the balance of user xToken
     * @param   _underlyingAsset  . the adress of the underlying asset of the xToken
     * @return  uint256  . supply index
     */
    function getSupplyIndexSinceLastUpdate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        DataTypes.Reserve memory reserve;
        reserve = underlyingAssetToReserve[_underlyingAsset];

        uint256 secondsSinceLastupdate = block.timestamp -
            reserve.lastUpdateTime;

        uint256 supplyIndex = updateIndex(
            reserve.supplyIndex,
            reserve.liquidityRate,
            secondsSinceLastupdate
        );

        return supplyIndex;
    }

    /**
     * @dev     . init a new reserve when adding new available token, this can only be called by PoolConfiguration
     * @param   _underlyingAsset  . the address of the underlying asset of the new reserve
     * @param   _baseVariableBorrowRate  . base variable borrow rate of the new reserve
     * @param   _interestRateSlope  . interest rate slope of the new reserve
     * @param   _xToken  . address of xToken of the new reserve
     * @param   _debtToken  . address of debtToken of the new reserve
     */
    function initReserve(
        address _underlyingAsset,
        uint256 _baseVariableBorrowRate,
        uint256 _interestRateSlope,
        address _xToken,
        address _debtToken
    ) public onlyPoolConfiguration {
        DataTypes.Reserve memory reserve;

        reserve = DataTypes.Reserve(
            0,
            0,
            0,
            0,
            _baseVariableBorrowRate,
            _interestRateSlope,
            1000000000000000000,
            0,
            1000000000000000000,
            block.timestamp,
            _xToken,
            _debtToken
        );
        underlyingAssetToReserve[_underlyingAsset] = reserve;
    }

    // Reseve getters

    function getTotalDeposited(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].totalDeposited;
    }

    function getTotalBorrowed(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].totalBorrowed;
    }

    function getUtilizationRate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].utilizationRate;
    }

    function getVariableBorrowRate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].variableBorrowRate;
    }

    function getBaseVariableBorrowRate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return
            underlyingAssetToReserve[_underlyingAsset].baseVariableBorrowRate;
    }

    function getInterestRateSlope(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].interestRateSlope;
    }

    function getVariableBorrowIndex(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].variableBorrowIndex;
    }

    function getLiquidityRate(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].liquidityRate;
    }

    function getSupplyIndex(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].supplyIndex;
    }

    function getLastUpdateTime(address _underlyingAsset)
        public
        view
        returns (uint256)
    {
        return underlyingAssetToReserve[_underlyingAsset].lastUpdateTime;
    }

    function getXToken(address _underlyingAsset) public view returns (address) {
        return underlyingAssetToReserve[_underlyingAsset].xToken;
    }

    function getDebtToken(address _underlyingAsset)
        public
        view
        returns (address)
    {
        return underlyingAssetToReserve[_underlyingAsset].debtToken;
    }
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @author  . MEBARKIA Abdenour
 * @title   . DataTypes
 * @dev     . Library containing a Reserve struct wich defines reserve properties .
 */

library DataTypes {
    struct Reserve {
        uint256 totalDeposited;
        uint256 totalBorrowed;
        uint256 utilizationRate;
        uint256 variableBorrowRate;
        uint256 baseVariableBorrowRate;
        uint256 interestRateSlope;
        uint256 variableBorrowIndex;
        uint256 liquidityRate;
        uint256 supplyIndex;
        uint256 lastUpdateTime;
        address xToken;
        address debtToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "ERC20.sol";
import "IERC20.sol";

import "ReservesManager.sol";

import "math.sol";

/**
 * @author  . MEBARKIA Abdenour
 * @title   . DebtToken
 * @dev     . Implements a debt token to track the borrowing positions of users
 */

contract DebtToken is ERC20, DSMath {
    address public poolAddress;
    address public underlyingAsset;

    ReservesManager public reservesManager;

    modifier onlyPool() {
        require(_msgSender() == poolAddress, "caller must be pool");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _poolAddress,
        address _reservesManagerAddress
    ) ERC20(_name, _symbol) {
        poolAddress = _poolAddress;
        underlyingAsset = _underlyingAsset;
        reservesManager = ReservesManager(_reservesManagerAddress);
    }

    /**
     * @dev     . Mints debt token to the borrower address
     * -  Only callable by the Pool
     * @param   _account  . borrower address
     * @param   _amount  . amount to mint
     */
    function mint(address _account, uint256 _amount) external onlyPool {
        super._mint(_account, _amount);
    }

    /**
     * @dev     . Burns user variable debt
     * - Only callable by the Pool
     * @param   _account  . The user whose debt is getting burned
     * @param   _amount  . The amount getting burned
     */
    function burn(address _account, uint256 _amount) external onlyPool {
        super._burn(_account, _amount);
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     */

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        recipient;
        amount;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        owner;
        spender;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        amount;
        revert("APPROVAL_NOT_SUPPORTED");
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender;
        recipient;
        amount;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        addedValue;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        subtractedValue;
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    /**
     * @dev     . Calculates the debt balance of the user
     * @return  uint256  . The debt balance of the user
     */
    function balanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 scaledBalance = super.balanceOf(user);

        if (scaledBalance == 0) {
            return 0;
        }

        return
            wmul(
                scaledBalance,
                reservesManager.getVariableBorrowIndexSinceLastUpdate(
                    underlyingAsset
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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