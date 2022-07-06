// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./LongShortToken.sol";
import "./PrePOMarket.sol";
import "./interfaces/ILongShortToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IPrePOMarketFactory.sol";

contract PrePOMarketFactory is IPrePOMarketFactory, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  mapping(address => bool) private _validCollateral;
  mapping(bytes32 => address) private _deployedMarkets;

  function initialize() public initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  function isCollateralValid(address _collateral) external view override returns (bool) {
    return _validCollateral[_collateral];
  }

  function getMarket(bytes32 _longShortHash) external view override returns (IPrePOMarket) {
    return IPrePOMarket(_deployedMarkets[_longShortHash]);
  }

  function createMarket(
    string memory _tokenNameSuffix,
    string memory _tokenSymbolSuffix,
    address _governance,
    address _collateral,
    uint256 _floorLongPrice,
    uint256 _ceilingLongPrice,
    uint256 _floorValuation,
    uint256 _ceilingValuation,
    uint256 _mintingFee,
    uint256 _redemptionFee,
    uint256 _expiryTime
  ) external override onlyOwner nonReentrant {
    require(_validCollateral[_collateral], "Invalid collateral");

    (LongShortToken _longToken, LongShortToken _shortToken) = _createPairTokens(
      _tokenNameSuffix,
      _tokenSymbolSuffix
    );
    bytes32 _salt = keccak256(abi.encodePacked(_longToken, _shortToken));

    PrePOMarket _newMarket = new PrePOMarket{salt: _salt}(
      _governance,
      _collateral,
      ILongShortToken(address(_longToken)),
      ILongShortToken(address(_shortToken)),
      _floorLongPrice,
      _ceilingLongPrice,
      _floorValuation,
      _ceilingValuation,
      _mintingFee,
      _redemptionFee,
      _expiryTime,
      false
    );
    _deployedMarkets[_salt] = address(_newMarket);

    _longToken.transferOwnership(address(_newMarket));
    _shortToken.transferOwnership(address(_newMarket));
    emit MarketAdded(address(_newMarket), _salt);
  }

  function setCollateralValidity(address _collateral, bool _validity) external override onlyOwner {
    _validCollateral[_collateral] = _validity;
    emit CollateralValidityChanged(_collateral, _validity);
  }

  function _createPairTokens(string memory _tokenNameSuffix, string memory _tokenSymbolSuffix)
    internal
    returns (LongShortToken _newLongToken, LongShortToken _newShortToken)
  {
    string memory _longTokenName = string(abi.encodePacked("LONG", " ", _tokenNameSuffix));
    string memory _shortTokenName = string(abi.encodePacked("SHORT", " ", _tokenNameSuffix));
    string memory _longTokenSymbol = string(abi.encodePacked("L", "_", _tokenSymbolSuffix));
    string memory _shortTokenSymbol = string(abi.encodePacked("S", "_", _tokenSymbolSuffix));
    _newLongToken = new LongShortToken(_longTokenName, _longTokenSymbol);
    _newShortToken = new LongShortToken(_shortTokenName, _shortTokenSymbol);
    return (_newLongToken, _newShortToken);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LongShortToken is ERC20Burnable, Ownable {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

  function mint(address _recipient, uint256 _amount) external onlyOwner {
    _mint(_recipient, _amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./interfaces/ILongShortToken.sol";
import "./interfaces/IPrePOMarket.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PrePOMarket is IPrePOMarket, Ownable, ReentrancyGuard {
  address private _treasury;

  IERC20 private immutable _collateral;
  ILongShortToken private immutable _longToken;
  ILongShortToken private immutable _shortToken;

  uint256 private immutable _floorLongPrice;
  uint256 private immutable _ceilingLongPrice;
  uint256 private _finalLongPrice;

  uint256 private immutable _floorValuation;
  uint256 private immutable _ceilingValuation;

  uint256 private _mintingFee;
  uint256 private _redemptionFee;

  uint256 private immutable _expiryTime;

  bool private _publicMinting;

  uint256 private constant MAX_PRICE = 1e18;
  uint256 private constant FEE_DENOMINATOR = 1000000;
  uint256 private constant FEE_LIMIT = 50000;

  /**
   * Assumes `_newCollateral`, `_newLongToken`, and `_newShortToken` are
   * valid, since they will be handled by the PrePOMarketFactory. The
   * treasury is initialized to governance due to stack limitations.
   *
   * Assumes that ownership of `_longToken` and `_shortToken` has been
   * transferred to this contract via `createMarket()` in
   * `PrePOMarketFactory.sol`.
   */
  constructor(
    address _governance,
    address _newCollateral,
    ILongShortToken _newLongToken,
    ILongShortToken _newShortToken,
    uint256 _newFloorLongPrice,
    uint256 _newCeilingLongPrice,
    uint256 _newFloorValuation,
    uint256 _newCeilingValuation,
    uint256 _newMintingFee,
    uint256 _newRedemptionFee,
    uint256 _newExpiryTime,
    bool _allowed
  ) {
    require(_newCeilingLongPrice > _newFloorLongPrice, "Ceiling must exceed floor");
    require(_newExpiryTime > block.timestamp, "Invalid expiry");
    require(_newMintingFee <= FEE_LIMIT, "Exceeds fee limit");
    require(_newRedemptionFee <= FEE_LIMIT, "Exceeds fee limit");
    require(_newCeilingLongPrice <= MAX_PRICE, "Ceiling cannot exceed 1");

    transferOwnership(_governance);
    _treasury = _governance;

    _collateral = IERC20(_newCollateral);
    _longToken = _newLongToken;
    _shortToken = _newShortToken;

    _floorLongPrice = _newFloorLongPrice;
    _ceilingLongPrice = _newCeilingLongPrice;
    _finalLongPrice = MAX_PRICE + 1;

    _floorValuation = _newFloorValuation;
    _ceilingValuation = _newCeilingValuation;

    _mintingFee = _newMintingFee;
    _redemptionFee = _newRedemptionFee;

    _expiryTime = _newExpiryTime;

    _publicMinting = _allowed;

    emit MarketCreated(
      address(_newLongToken),
      address(_newShortToken),
      _newFloorLongPrice,
      _newCeilingLongPrice,
      _newFloorValuation,
      _newCeilingValuation,
      _newMintingFee,
      _newRedemptionFee,
      _newExpiryTime
    );
  }

  function mintLongShortTokens(uint256 _amount) external override nonReentrant returns (uint256) {
    if (msg.sender != owner()) {
      require(_publicMinting, "Public minting disabled");
    }
    require(_finalLongPrice > MAX_PRICE, "Market ended");
    require(_collateral.balanceOf(msg.sender) >= _amount, "Insufficient collateral");
    /**
     * Add 1 to avoid rounding to zero, only process if user is minting
     * an amount large enough to pay a fee
     */
    uint256 _fee = (_amount * _mintingFee) / FEE_DENOMINATOR + 1;
    require(_amount > _fee, "Minting amount too small");
    _collateral.transferFrom(msg.sender, _treasury, _fee);
    unchecked {
      _amount -= _fee;
    }
    _collateral.transferFrom(msg.sender, address(this), _amount);
    _longToken.mint(msg.sender, _amount);
    _shortToken.mint(msg.sender, _amount);
    emit Mint(msg.sender, _amount);
    return _amount;
  }

  function redeem(uint256 _longAmount, uint256 _shortAmount) external override nonReentrant {
    require(_longToken.balanceOf(msg.sender) >= _longAmount, "Insufficient long tokens");
    require(_shortToken.balanceOf(msg.sender) >= _shortAmount, "Insufficient short tokens");

    uint256 _collateralOwed;
    if (_finalLongPrice <= MAX_PRICE) {
      uint256 _shortPrice = MAX_PRICE - _finalLongPrice;
      _collateralOwed = (_finalLongPrice * _longAmount + _shortPrice * _shortAmount) / MAX_PRICE;
    } else {
      require(_longAmount == _shortAmount, "Long and Short must be equal");
      _collateralOwed = _longAmount;
    }

    _longToken.burnFrom(msg.sender, _longAmount);
    _shortToken.burnFrom(msg.sender, _shortAmount);
    /**
     * Add 1 to avoid rounding to zero, only process if user is redeeming
     * an amount large enough to pay a fee
     */
    uint256 _fee = (_collateralOwed * _redemptionFee) / FEE_DENOMINATOR + 1;
    require(_collateralOwed > _fee, "Redemption amount too small");
    _collateral.transfer(_treasury, _fee);
    unchecked {
      _collateralOwed -= _fee;
    }
    _collateral.transfer(msg.sender, _collateralOwed);

    emit Redemption(msg.sender, _collateralOwed);
  }

  function setTreasury(address _newTreasury) external override onlyOwner {
    _treasury = _newTreasury;
    emit TreasuryChanged(_newTreasury);
  }

  function setFinalLongPrice(uint256 _newFinalLongPrice) external override onlyOwner {
    require(_newFinalLongPrice >= _floorLongPrice, "Price cannot be below floor");
    require(_newFinalLongPrice <= _ceilingLongPrice, "Price cannot exceed ceiling");
    _finalLongPrice = _newFinalLongPrice;
    emit FinalLongPriceSet(_newFinalLongPrice);
  }

  function setMintingFee(uint256 _newMintingFee) external override onlyOwner {
    require(_newMintingFee <= FEE_LIMIT, "Exceeds fee limit");
    _mintingFee = _newMintingFee;
    emit MintingFeeChanged(_newMintingFee);
  }

  function setRedemptionFee(uint256 _newRedemptionFee) external override onlyOwner {
    require(_newRedemptionFee <= FEE_LIMIT, "Exceeds fee limit");
    _redemptionFee = _newRedemptionFee;
    emit RedemptionFeeChanged(_newRedemptionFee);
  }

  function setPublicMinting(bool _allowed) external override onlyOwner {
    _publicMinting = _allowed;
    emit PublicMintingChanged(_allowed);
  }

  function getTreasury() external view override returns (address) {
    return _treasury;
  }

  function getCollateral() external view override returns (IERC20) {
    return _collateral;
  }

  function getLongToken() external view override returns (ILongShortToken) {
    return _longToken;
  }

  function getShortToken() external view override returns (ILongShortToken) {
    return _shortToken;
  }

  function getFloorLongPrice() external view override returns (uint256) {
    return _floorLongPrice;
  }

  function getCeilingLongPrice() external view override returns (uint256) {
    return _ceilingLongPrice;
  }

  function getFinalLongPrice() external view override returns (uint256) {
    return _finalLongPrice;
  }

  function getFloorValuation() external view override returns (uint256) {
    return _floorValuation;
  }

  function getCeilingValuation() external view override returns (uint256) {
    return _ceilingValuation;
  }

  function getMintingFee() external view override returns (uint256) {
    return _mintingFee;
  }

  function getRedemptionFee() external view override returns (uint256) {
    return _redemptionFee;
  }

  function getExpiryTime() external view override returns (uint256) {
    return _expiryTime;
  }

  function isPublicMintingAllowed() external view override returns (bool) {
    return _publicMinting;
  }

  function getMaxPrice() external pure override returns (uint256) {
    return MAX_PRICE;
  }

  function getFeeDenominator() external pure override returns (uint256) {
    return FEE_DENOMINATOR;
  }

  function getFeeLimit() external pure override returns (uint256) {
    return FEE_LIMIT;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice LongShortToken contract representing PrePOMarket positions.
 *
 * The token can represent either a Long or Short position for the
 * PrePOMarket it belongs to.
 */
interface ILongShortToken is IERC20 {
  /**
   * @dev Inherited from OpenZeppelin Ownable.
   * @return Address of the current owner
   */
  function owner() external returns (address);

  /**
   * @notice Mints `amount` tokens to `recipient`. Allows PrePOMarket to mint
   * positions for users.
   * @dev Only callable by `owner()` (should be PrePOMarket).
   * @param recipient Address of the recipient
   * @param amount Amount of tokens to mint
   */
  function mint(address recipient, uint256 amount) external;

  /**
   * @notice Destroys `amount` tokens from `account`, deducting from the
   * caller's allowance.
   * @dev Inherited from OpenZeppelin ERC20Burnable.
   * @param account Address of the account to destroy tokens from
   * @param amount Amount of tokens to destroy
   */
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IPrePOMarket.sol";

/**
 * @notice Deploys a PrePOMarket and two LongShortToken contracts to serve as
 * the token pair.
 */
interface IPrePOMarketFactory {
  /// @dev Emitted via `setCollateralValidity()`.
  /// @param collateral the collateral changed
  /// @param allowed whether the collateral is valid
  event CollateralValidityChanged(address collateral, bool allowed);

  /// @dev Emitted via `createMarket()`.
  /// @param market The market created
  /// @param longShortHash The market unique id
  event MarketAdded(address market, bytes32 longShortHash);

  /**
   * @notice Deploys a PrePOMarket with the given parameters and two
   * LongShortToken contracts to serve as the token pair.
   * @dev Parameters are all passed along to their respective arguments
   * in the PrePOMarket constructor.
   *
   * Token names are generated from `tokenNameSuffix` as the name
   * suffix and `tokenSymbolSuffix` as the symbol suffix.
   *
   * "LONG "/"SHORT " are appended to respective names, "L_"/"S_" are
   * appended to respective symbols.
   *
   * e.g. preSTRIPE 100-200 30-September 2021 =>
   * LONG preSTRIPE 100-200 30-September-2021.
   *
   * e.g. preSTRIPE_100-200_30SEP21 => L_preSTRIPE_100-200_30SEP21.
   * @param tokenNameSuffix The name suffix for the token pair
   * @param tokenSymbolSuffix The symbol suffix for the token pair
   * @param collateral The address of the collateral token
   * @param governance The address of the governance contract
   * @param floorLongPrice The floor price for the Long token
   * @param ceilingLongPrice The ceiling price for the Long token
   * @param floorValuation The floor valuation for the Market
   * @param ceilingValuation The ceiling valuation for the Market
   * @param mintingFee The minting fee for Long/Short tokens
   * @param redemptionFee The redemption fee for Long/Short tokens
   * @param expiryTime The expiry time for the Market
   */
  function createMarket(
    string memory tokenNameSuffix,
    string memory tokenSymbolSuffix,
    address collateral,
    address governance,
    uint256 floorLongPrice,
    uint256 ceilingLongPrice,
    uint256 floorValuation,
    uint256 ceilingValuation,
    uint256 mintingFee,
    uint256 redemptionFee,
    uint256 expiryTime
  ) external;

  /**
   * @notice Sets whether a collateral contract is valid for assignment to
   * new PrePOMarkets.
   * @param collateral The address of the collateral contract
   * @param validity Whether the collateral contract should be valid
   */
  function setCollateralValidity(address collateral, bool validity) external;

  /**
   * @notice Returns whether collateral contract is valid for assignment to
   * new PrePOMarkets.
   * @param collateral The address of the collateral contract
   * @return Whether the collateral contract is valid
   */
  function isCollateralValid(address collateral) external view returns (bool);

  /**
   * @dev `longShortHash` is a keccak256 hash of the long token address and
   * short token address of the PrePOMarket.
   * @param longShortHash PrePOMarket unique identifier
   * @return PrePOMarket address corresponding to the market id
   */
  function getMarket(bytes32 longShortHash) external view returns (IPrePOMarket);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

import "./ILongShortToken.sol";
import "./IStrategyController.sol";

/**
 * @notice Users can mint/redeem long/short positions on a specific asset in
 * exchange for Collateral tokens.
 * @dev Position settlement prices are bound by a floor and ceiling set
 * during market initialization.
 *
 * The value of a Long and Short token should always equal 1 Collateral.
 */
interface IPrePOMarket {
  /// @dev Emitted via `constructor()`
  /// @param longToken Market Long token address
  /// @param shortToken Market Short token address
  /// @param shortToken Market Short token address
  /// @param floorLongPrice Long token price floor
  /// @param ceilingLongPrice Long token price ceiling
  /// @param floorValuation Market valuation floor
  /// @param ceilingValuation Market valuation ceiling
  /// @param mintingFee Market minting fee
  /// @param redemptionFee Market redemption fee
  /// @param expiryTime Market expiry time
  event MarketCreated(
    address longToken,
    address shortToken,
    uint256 floorLongPrice,
    uint256 ceilingLongPrice,
    uint256 floorValuation,
    uint256 ceilingValuation,
    uint256 mintingFee,
    uint256 redemptionFee,
    uint256 expiryTime
  );

  /// @dev Emitted via `mintLongShortTokens()`.
  /// @param minter The address of the minter
  /// @param amount The amount of Long/Short tokens minted
  event Mint(address indexed minter, uint256 amount);

  /// @dev Emitted via `redeem()`.
  /// @param redeemer The address of the redeemer
  /// @param amount The amount of Long/Short tokens redeemed
  event Redemption(address indexed redeemer, uint256 amount);

  /// @dev Emitted via `setTreasury()`.
  /// @param treasury The new treasury address
  event TreasuryChanged(address treasury);

  /// @dev Emitted via `setFinalLongPrice()`.
  /// @param price The final Long price
  event FinalLongPriceSet(uint256 price);

  /// @dev Emitted via `setMintingFee()`.
  /// @param fee The new minting fee
  event MintingFeeChanged(uint256 fee);

  /// @dev Emitted via `setRedemptionFee()`.
  /// @param fee The new redemption fee
  event RedemptionFeeChanged(uint256 fee);

  /// @dev Emitted via `setPublicMinting()`.
  /// @param allowed The new public minting status
  event PublicMintingChanged(bool allowed);

  /**
   * @notice Mints Long and Short tokens in exchange for `amount`
   * Collateral.
   * @dev Minting is not allowed after the market has ended.
   *
   * `owner()` may mint tokens before PublicMinting is enabled to
   * bootstrap a market with an initial supply.
   * @param amount Amount of Collateral to deposit
   * @return Long/Short tokens minted
   */
  function mintLongShortTokens(uint256 amount) external returns (uint256);

  /**
   * @notice Redeem `longAmount` Long and `shortAmount` Short tokens for
   * Collateral.
   * @dev Before the market ends, redemptions can only be done with equal
   * parts N Long/Short tokens for N Collateral.
   *
   * After the market has ended, users can redeem any amount of
   * Long/Short tokens for Collateral.
   * @param longAmount Amount of Long tokens to redeem
   * @param shortAmount Amount of Short tokens to redeem
   */
  function redeem(uint256 longAmount, uint256 shortAmount) external;

  /**
   * @notice Sets the treasury address minting/redemption fees are sent to.
   * @dev Only callable by `owner()`.
   * @param newTreasury New treasury address
   */
  function setTreasury(address newTreasury) external;

  /**
   * @notice Sets the price a Long token can be redeemed for after the
   * market has ended (in wei units of Collateral).
   * @dev The contract initializes this to > MAX_PRICE and knows the market
   * has ended when it is set to <= MAX_PRICE.
   *
   * Only callable by `owner()`.
   * @param newFinalLongPrice Price to set Long token redemptions
   */
  function setFinalLongPrice(uint256 newFinalLongPrice) external;

  /**
   * @notice Sets the fee for minting Long/Short tokens, must be a 4
   * decimal place percentage value e.g. 4.9999% = 49999.
   * @dev Only callable by `owner()`.
   * @param newMintingFee New minting fee
   */
  function setMintingFee(uint256 newMintingFee) external;

  /**
   * @notice Sets the fee for redeeming Long/Short tokens, must be a 4
   * decimal place percentage value e.g. 4.9999% = 49999.
   * @dev Only callable by `owner()`.
   * @param newRedemptionFee New redemption fee
   */
  function setRedemptionFee(uint256 newRedemptionFee) external;

  /**
   * @notice Sets whether or not everyone is allowed to mint Long/Short
   * tokens.
   * @dev Only callable by `owner()`.
   * @param allowed Whether or not to allow everyone to mint Long/Short
   */
  function setPublicMinting(bool allowed) external;

  /// @return Treasury address where minting/redemption fees are sent
  function getTreasury() external view returns (address);

  /// @return Collateral token used to fund Long/Short positions
  function getCollateral() external view returns (IERC20);

  /**
   * @dev The PrePOMarket is the owner of this token contract.
   * @return Long token for this market
   */
  function getLongToken() external view returns (ILongShortToken);

  /**
   * @dev The PrePOMarket is the owner of this token contract.
   * @return Short token for this market
   */
  function getShortToken() external view returns (ILongShortToken);

  /**
   * @notice Returns the lower bound of what a Long token can be priced at
   * (in wei units of Collateral).
   * @dev Must be less than ceilingLongPrice and MAX_PRICE.
   * @return Minimum Long token price
   */
  function getFloorLongPrice() external view returns (uint256);

  /**
   * @notice Returns the upper bound of what a Long token can be priced at
   * (in wei units of Collateral).
   * @dev Must be less than MAX_PRICE.
   * @return Maximum Long token price
   */
  function getCeilingLongPrice() external view returns (uint256);

  /**
   * @notice Returns the price a Long token can be redeemed for after the
   * market has ended (in wei units of Collateral).
   * @dev The contract initializes this to > MAX_PRICE and knows the market
   * has ended when it is set to <= MAX_PRICE.
   * @return Final Long token price
   */
  function getFinalLongPrice() external view returns (uint256);

  /**
   * @notice Returns valuation of a market when the price of a Long
   * token is at the floor.
   * @return Market valuation floor
   */
  function getFloorValuation() external view returns (uint256);

  /**
   * @notice Returns valuation of a market when the price of a Long
   * token is at the ceiling.
   * @return Market valuation ceiling
   */
  function getCeilingValuation() external view returns (uint256);

  /**
   * @notice Returns the fee for minting Long/Short tokens as a 4 decimal
   * place percentage value e.g. 4.9999% = 49999.
   * @return Minting fee
   */
  function getMintingFee() external view returns (uint256);

  /**
   * @notice Returns the fee for redeeming Long/Short tokens as a 4 decimal
   * place percentage value e.g. 4.9999% = 49999.
   * @return Redemption fee
   */
  function getRedemptionFee() external view returns (uint256);

  /**
   * @notice Returns the timestamp of when the market will expire.
   * @return Market expiry timestamp
   */
  function getExpiryTime() external view returns (uint256);

  /**
   * @notice Returns whether Long/Short token minting is open to everyone.
   * @dev If true, anyone can mint Long/Short tokens, if false, only
   * `owner()` may mint.
   * @return Whether or not public minting is allowed
   */
  function isPublicMintingAllowed() external view returns (bool);

  /**
   * @notice Long prices cannot exceed this value, equivalent to 1 ether
   * unit of Collateral.
   * @return Max Long token price
   */
  function getMaxPrice() external pure returns (uint256);

  /**
   * @notice Returns the denominator for calculating fees from 4 decimal
   * place percentage values e.g. 4.9999% = 49999.
   * @return Denominator for calculating fees
   */
  function getFeeDenominator() external pure returns (uint256);

  /**
   * @notice Fee limit of 5% represented as 4 decimal place percentage
   * value e.g. 4.9999% = 49999.
   * @return Fee limit
   */
  function getFeeLimit() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Strategy Controller acts as an intermediary between the Strategy
 * and the PrePO Collateral contract.
 *
 * The Collateral contract should never interact with the Strategy directly
 * and only perform operations via the Strategy Controller.
 */
interface IStrategyController {
  /// @dev Emitted via `setVault()`.
  /// @param vault The new vault address
  event VaultChanged(address vault);

  /// @dev Emitted via `migrate()`.
  /// @param oldStrategy The old strategy address
  /// @param newStrategy The new strategy address
  /// @param amount The amount migrated
  event StrategyMigrated(address oldStrategy, address newStrategy, uint256 amount);

  /**
   * @notice Deposits the specified amount of Base Token into the Strategy.
   * @dev Only the vault (Collateral contract) may call this function.
   *
   * Assumes approval to transfer amount from the Collateral contract
   * has been given.
   * @param amount Amount of Base Token to deposit
   */
  function deposit(uint256 amount) external;

  /**
   * @notice Withdraws the requested amount of Base Token from the Strategy
   * to the recipient.
   * @dev Only the vault (Collateral contract) may call this function.
   *
   * This withdrawal is optimistic, returned amount might be less than
   * the amount specified.
   * @param amount Amount of Base Token to withdraw
   * @param recipient Address to receive the Base Token
   */
  function withdraw(address recipient, uint256 amount) external;

  /**
   * @notice Migrates funds from currently configured Strategy to a new
   * Strategy and replaces it.
   * @dev If a Strategy is not already set, it sets the Controller's
   * Strategy to the new value with no funds being exchanged.
   *
   * Gives infinite Base Token approval to the new strategy and sets it
   * to zero for the old one.
   *
   * Only callable by `owner()`.
   * @param newStrategy Address of the new Strategy
   */
  function migrate(IStrategy newStrategy) external;

  /**
   * @notice Sets the vault that is allowed to deposit/withdraw through this
   * StrategyController.
   * @dev Only callable by `owner()`.
   * @param newVault Address of the new vault
   */
  function setVault(address newVault) external;

  /**
   * @notice Returns the Base Token balance of this contract and the
   * `totalValue()` returned by the Strategy.
   * @return The total value of assets within the strategy
   */
  function totalValue() external view returns (uint256);

  /**
   * @notice Returns the vault that is allowed to deposit/withdraw through
   * this Strategy Controller.
   * @return The vault address
   */
  function getVault() external view returns (address);

  /**
   * @notice Returns the ERC20 asset that this Strategy Controller supports
   * handling funds with.
   * @return The Base Token address
   */
  function getBaseToken() external view returns (IERC20);

  /**
   * @return The Strategy that this Strategy Controller manages
   */
  function getStrategy() external view returns (IStrategy);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

import "./IStrategyController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Strategy that deploys Base Token to earn yield denominated in Base
 * Token.
 * @dev `owner()` can call emergency functions and setters, only controller
 * can call deposit/withdraw.
 */
interface IStrategy {
  /**
   * @notice Deposits `amount` Base Token into the strategy.
   * @dev Assumes the StrategyController has given infinite spend approval
   * to the strategy.
   * @param amount Amount of Base Token to deposit
   */
  function deposit(uint256 amount) external;

  /**
   * @notice Withdraws `amount` Base Token from the strategy to `recipient`.
   * @dev This withdrawal is optimistic, returned amount might be less than
   * the amount specified.
   * @param recipient Address to receive the Base Token
   * @param amount Amount of Base Token to withdraw
   */
  function withdraw(address recipient, uint256 amount) external;

  /**
   * @notice Returns the Base Token balance of this contract and
   * the estimated value of deployed assets.
   * @return Total value of assets within the strategy
   */
  function totalValue() external view returns (uint256);

  /**
   * @notice Returns the Strategy Controller that intermediates interactions
   * between a vault and this strategy.
   * @dev Functions with the `onlyController` modifier can only be called by
   * this Strategy Controller.
   * @return The Strategy Controller address
   */
  function getController() external view returns (IStrategyController);

  /**
   * @notice The ERC20 asset that this strategy utilizes to earn yield and
   * return profits with.
   * @return The Base Token address
   */
  function getBaseToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}