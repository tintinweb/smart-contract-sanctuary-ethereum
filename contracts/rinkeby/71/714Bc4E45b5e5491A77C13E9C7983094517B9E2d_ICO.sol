//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";

enum Phase {
  SEED,
  GENERAL,
  OPEN
}

/// @notice ICO contract for SpaceCoin
/// @dev requires SpaceCoin ERC20 to mint SPC for ICO to distrbute. See SpaceCoin
contract ICO {
  event PhaseChangedToGeneral(); // SEED -> GENERAL
  event PhaseChangedToOpen(); // GENERAL -> OPEN

  event FundraisePaused(); // Contributions paused
  event FundraiseResumed(); // Contributions unpaused

  // Emitted when contribute() called successfully for amount of ether
  event ContributionMade(uint amount);
  event RedemptionMade(uint amount, address _address);

  // Owner of ICO
  address owner;
  // Address of SpaceCoin (SPC) ERC20 Contract
  SpaceCoin public spaceCoin;

  // Our total fundraising goal in ether
  uint constant icoContributionLimit = 30000 ether;
  // Our fundraising goal for SEED phase
  uint constant seedPhaseContributionLimit = 15000 ether;
  // Private Investor limit during SEED phase
  uint constant seedPhaseIndividualContributionLimit = 1500 ether;
  // Contribution limit for everyone during GENERAL phase
  uint constant generalPhaseContributionLimit = 1000 ether;

  // a mapping of private investor addresses to their boolean status
  mapping(address => bool) public seedPhaseAllowList;
  // a mapping of investor's addresses and how much they've contributed in ether
  mapping(address => uint) public contributorsToAmount;

  // The current phase the ICO is in. Starts in SEED phase
  Phase public phase = Phase.SEED;
  // isPaused limits/allows contributions of ether to ICO
  bool public isPaused = false;

  /// @notice Constructor
  /// @dev assigns msg.sender as owner
  /// @param _spaceCoin address of Spacecoin (SPC) ERC20
  constructor(address _spaceCoin) {
    owner = msg.sender;
    spaceCoin = SpaceCoin(_spaceCoin);
  }

  /// @notice Ensures that the owner of the project is making the function call
  modifier onlyOwner() {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }

  /// @notice Allows owner to toggle isPause
  /// @dev OnlyOwner modifier, emits event, external
  function togglePauseUnpause() external onlyOwner {
    isPaused = !isPaused;
    if (isPaused) emit FundraisePaused();
    else emit FundraiseResumed();
  }

  /// @notice Allows owner to move to next phase
  /// @dev OnlyOwner modifier, emits event, external
  function goToNextPhase() external onlyOwner {
    if (phase == Phase.SEED) {
      phase = Phase.GENERAL;
      emit PhaseChangedToGeneral();
    } else if (phase == Phase.GENERAL) {
      phase = Phase.OPEN;
      emit PhaseChangedToOpen();
    }
  }

  /// @notice Owner can private investors to allow list
  /// @dev onlyOwner, external
  /// @param _privateContributor address of private investor being added to allowlist
  function addToAllowList(address _privateContributor) external onlyOwner {
    if (phase != Phase.SEED) revert NotInSeedPhase();
    if (seedPhaseAllowList[_privateContributor]) revert AlreadyOnAllowList();

    seedPhaseAllowList[_privateContributor] = true;
  }

  /// @notice contribute() allows EOAs to submit their amount to fundraise
  /// @dev This function uses `phase` heavily to determine how to handle contributions
  /// @dev 30k ETH limit, requires to not be paused. emits ContributionMade event if successful
  function contribute() external payable {
    if (isPaused) revert ICOIsPaused();
    // ICO has max of 30k ETH
    if (address(this).balance > icoContributionLimit) revert ContributingBeyondMaximumAllowed();

    // Seed Phase
    if (phase == Phase.SEED) {
      // Have they been added to allow list
      if (!seedPhaseAllowList[msg.sender]) revert CannotContribute();
      // revert if the amount contributed is greater than the
      // individual limit subtracted by what they've already contributed
      //
      // e.g. contributor has already contributed 1k eth
      // and is trying to put in 600 more. (1500 limit)
      // 600 > (1500 - 1000) == true
      // 750 > (1500 - 750) == false
      if (msg.value > (seedPhaseIndividualContributionLimit - contributorsToAmount[msg.sender]))
        revert ContributingBeyondMaximumAllowed();

      // Have they contributed the max amount
      if (address(this).balance > seedPhaseContributionLimit)
        revert ContributingBeyondMaximumAllowed();

      // increase contribution tracking
      contributorsToAmount[msg.sender] += msg.value;

      emit ContributionMade(msg.value);

      // General Phase
    } else if (phase == Phase.GENERAL) {
      // similar to line 90-95 but limit is 1k eth now
      if (msg.value > (generalPhaseContributionLimit - contributorsToAmount[msg.sender]))
        revert ContributingBeyondMaximumAllowed();

      // increase contribution tracking
      contributorsToAmount[msg.sender] += msg.value;
      emit ContributionMade(msg.value);

      // Open Phase
    } else if (phase == Phase.OPEN) {
      contributorsToAmount[msg.sender] += msg.value;
      emit ContributionMade(msg.value);
    }
  }

  /// @notice Allow EOAs to transfer their alloted SPC tokens during the Open phase
  function redeem() external {
    if (phase != Phase.OPEN) revert NotInOpenPhase();
    if (contributorsToAmount[msg.sender] == 0) revert NotAContributor();

    uint contributedAmount = contributorsToAmount[msg.sender];
    uint redemptionAmount = contributedAmount * 5;

    if (spaceCoin.transfer(msg.sender, redemptionAmount)) contributorsToAmount[msg.sender] = 0;

    emit RedemptionMade(redemptionAmount, msg.sender);
  }
}

error OnlyOwner();

error NotInSeedPhase();
error NotInOpenPhase();

error AlreadyOnAllowList();

error ICOIsPaused();
error CannotContribute();
error ContributingBeyondMaximumAllowed();
error NotAContributor();

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ICO.sol";

error OwnerOnly();
error ICOStarted();

/// @notice SpaceCoin (SPC) ERC20 Implementation
/// @dev initial distribution of ERC20s determined by ICO contract
contract SpaceCoin is ERC20 {
  // Address of Owner of SpaceCoin
  address creator;
  // Address of SpaceCoin's Treasury. Taxes are deposited here
  address public treasury;
  // Address of ICO
  address ico;
  // Is the ERC20 taking a tax of 2% during every transaction
  bool public isTaxing = false;
  // Precision factor for determining tax
  uint constant PRECISION = 10**3;
  // A mapping of addresses and their unpaid taxes (uint)
  mapping(address => uint) public unpaidPreciseTax;

  mapping(address => uint) public nonces;

  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  // Event toggled when taxing is turned on
  event TaxToggled(bool isTaxing);

  /// @notice Constructor
  /// @param _owner Owner of SpaceCoin
  /// @param _treasury Treasury of SpaceCoin
  constructor(address _owner, address _treasury) ERC20("SpaceCoin", "SPC") {
    creator = _owner;
    treasury = _treasury;
    _mint(_treasury, 350000 * (10**decimals()));
  }

  ////////////////
  // External

  /// @notice Allocates 150000 SPC to ICO to distribute
  /// @dev If total supply is more than initial mint of 350k,
  /// this cannot be called again
  function setIco(address _ico) external {
    if (creator != msg.sender) revert OwnerOnly();
    if (balanceOf(_ico) > 0 || totalSupply() > (350000 * (10**decimals()))) revert ICOStarted();
    ico = _ico;

    uint amount = 150000 * (10**decimals());
    _mint(_ico, amount);
  }

  /// @notice Allows creator to toggle taxing
  function toggleTax() external {
    if (creator != msg.sender) revert OwnerOnly();
    isTaxing = !isTaxing;
    emit TaxToggled(isTaxing);
  }

  ////////////////
  // Overrides

  /// @notice an override of ERC20 implementation that adds tax
  function transfer(address to, uint256 amount) public override returns (bool) {
    address _owner = _msgSender();
    // transfers from ICO shouldn't be taxed
    if (isTaxing && _owner != ico) {
      uint tax = calculateTax(amount, _owner);
      _transfer(_owner, to, amount - tax);
      _transfer(_owner, treasury, tax);
    } else {
      _transfer(_owner, to, amount);
    }

    return true;
  }

  /// @notice an override of ERC20 implementation that adds tax
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    address spender = _msgSender();

    _spendAllowance(from, spender, amount);

    if (isTaxing) {
      uint tax = calculateTax(amount, from);
      _transfer(from, to, amount - tax);
      _transfer(from, treasury, tax);
    } else {
      _transfer(from, to, amount);
    }
    return true;
  }

  error PermitDeadlinePassed(address owner, address spender, uint value, uint deadline);
  error IncorrectSignatory(
    address signatory,
    address owner,
    address spender,
    uint value,
    uint deadline
  );

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    if (block.timestamp >= deadline) revert PermitDeadlinePassed(owner, spender, value, deadline);
    uint chainid = block.chainid;

    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), chainid, address(this))
    );
    bytes32 permitHash = keccak256(
      abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
    );
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, permitHash));
    address signatory = ecrecover(digest, v, r, s);

    if (signatory == address(0) || signatory != owner)
      revert IncorrectSignatory(signatory, owner, spender, value, deadline);

    _approve(owner, spender, value);
  }

  //////////////////////////////
  // Private

  /// @notice Stores untaxed amount that is lost due to rounding
  /// to be included in further transactions
  function calculateTax(uint taxableAmount, address from) public returns (uint tax) {
    uint taxAmount = (taxableAmount / 100) * 2; // 2%

    uint preciseFee = ((taxableAmount * PRECISION) / 100) * 2; // 2%

    unpaidPreciseTax[from] += preciseFee % PRECISION;

    if (unpaidPreciseTax[from] >= PRECISION) {
      unpaidPreciseTax[from] -= PRECISION;
      taxAmount += 2; // 2%
    }
    return taxAmount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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