// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../Dugo.sol";

contract DugoTestWrapper is Dugo {
    constructor(
        IAswang aswang,
        address team
    )
        Dugo(aswang, team)
    {}

    function mint(uint256 amount) public {
        _mint(_msgSender(), amount);
    }

    function _rate(uint256 baseRate, uint256 epoch) public pure returns (uint256) {
        return rate(baseRate, epoch);
    }

    function setStartedAt(uint256 startedAt) public {
        STARTED_AT = startedAt;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IDugo.sol";

error Dugo_ClaimDisabled();
error Dugo_FunctionLocked();
error Dugo_InvalidMaxSupply();
error Dugo_NotAswangContract();
error Dugo_NotTokenOwner();
error Dugo_TokenIdOutOfRange();

interface IAswang is IERC721 {
    function prayingStartedAt(uint256 tokenId) external view returns (uint256);
}

/**                                                      .,,,,.
                                                        ,l;..,l;.
                                                      .co,    ,ol.
                                                     ;do'.'::'..ox;.
                                                   .cxl..:xOOk:..cxc.
                                                  .dk:. ;xxc:dk;  ;xd,
                                                 ,xx;  'xk;. 'xx,  'dx;
                                                ;xd,  .dOxc;,;oOx.  .okc.
                                              .cko.  .oOo'.   .c0o.  .lkl.
                                             .okc.  .:kx,      .dkc.   ;xd,
                                            ;xd,     ..          ..     'okc.
                                          .lOo.                          .lko.
                                         .oOl.                             :Od'
                                        .dOc.                               ;kx'
                                       ,xk;         ...'',,,,,,''...         ,xk;
                                     .:xx'   ..';:coodddddddddoddoollc:;'.    .okl.
                                    .okl.   ..''.....               ....''..    :kk,
                                  .:O0c            ..,:loxkkxxkkdl:,..           'xOc.
                                 .o0k;        .,:oxkkkkxoooooodxkO00Okxoc,..      .o0x.
                                ,k0o.     .;ldxdoc;'....',,;;;;,....,:lxOOOko:,.    :0O;
                              .cOO:.   .:odo:'.     'cdoc:,,,;:lloc'    .':oxOOxc,.  ,kKl.
                             .dX0;  .:ooc'.       'lxd;.         'lko'      .'cxOOxc' .xXk'
                            ;OKd'.'oxl'          ;dxc.    .''.     ,xk:        .'cxOkl'.lK0:
                          .oK0:.'okl.           ,xk:.   .ldlldc.    'xk;          .,okxc';OXd.
                         'kXx'.cxl.            .oOd.   .ck:  ,xl.   .lOd.            ,oxl''xXO,
                        ;0Kl..cl'              .dOo.   .oO:  ,kx.    cOx,             .'cc..lKK:
                      .cKKo;cdo.               .l0x'    .ol;,lx:.   .d0d'               .cdc':0Xo.
                     .dX0c.oKXO:.               'x0l.     .....    .lOOc.               .xK0o.'xXx.
                    ;OXk;  .:k0Oo;.              ;OKd'            'd00o.              .:xxl;'  .lKO:
                  .oKKo.     .;okOko;.            'oOOd:'......,cx0KOl.            .;oxo;.       'xKo.
                 'xXO:        ..'cxO0Odc,.          .,:lddxxkxkkkdc,.          .'cxxd:...         .c0k'
                ;0Xx'      .;c;.  .':ok00Odl;'.           ......          ..;ldkxo;.  .lko,         ,O0;
              .cKXd.     .:dl'        .';ldk00Oxoc;,...            ..,;coxkkxl;..      .;xko,        'kKl.
             .oKKl.     ,oo,      .:;      .';lxkO00Okkxdoc:;:clodxOOOkoc;..   ,;.       .;dxc.       .dKx.
            ,kKO:.     .;'       'oo.           ..',::codkkxxkxdlc:,...        ;xx;         '::.       .lKO;
          .c0Xk,                'ol.      'l,                        .:c.       'oko.                    ;OKl.
         .oKKo. ..             .:;.      'dc.     .;;       .;,       ;xl.       .;xd,                ..  'xXd.
        .xX0c. .dk:            ..       .:c.      ;xc      .,dk.       cOl.        .,:.              :Ok,  .oKk'
       'kXO:  :Okc;.                    .'.      .ld'       .l0:       .cx:                          ;cdkc.  cKO;
      ;0XO; .dXx.                                .;;         'ko.        ,:.                           .xKx'  ;0Kc.
     cKXx'.;O0dl'    .                                        ;;                                  ..   :dldkc. 'kKo.
   .oXXd..oKO:.cd:,;cdl.                                                                        .lko;;oOo''oOd' .dKd.
  .dX0l. :OOdoloxdlc;,:'                                                                        .:;,:ldxolllxOl. .lKx.
 'xXO:.  ........                                                                                        ......   .c0k'
'OWNOoccccccccccc:c::::::;;;;,,,;;;,,,,,,,,;,,,,,,,;;,,,'''''''',,,,;;;;,,,,,;;,;;;;;;;;;;;:::::;::cccccccllccllllodONO'
:XWWWNXK00OO00000000000000OOOOOOO00OOOOO00000000000000KXXXXXXXXXKK00000000OO0O000OOOOOOOOOOOO000OOOO000OOOOOOOO00KXNNWNd

 * @title Aswang Tribe $DUGO token
 * @author Augminted Labs, LLC
 */
contract Dugo is IDugo, ERC20, Ownable, ReentrancyGuard {
    IAswang public immutable ASWANG;
    uint256 public STARTED_AT;
    uint256 public constant GENESIS_SUPPLY = 3333;
    uint256 public constant TOTAL_SUPPLY = 6666;
    uint256 public constant GENESIS_BASE_RATE = 5 ether;
    uint256 public constant MANANANGGAL_BASE_RATE = 2 ether;
    uint256 public constant EPOCH_DURATION = 180 days;

    uint256 public maxSupply = 10_000_000 ether;
    uint256 public totalClaimed = 2_000_000 ether;
    mapping(bytes4 => bool) public functionLocked;
    mapping(uint256 => uint256) internal _lastClaimedAt;

    constructor(
        IAswang aswang,
        address team
    )
        ERC20("Dugo", "DUGO")
    {
        ASWANG = aswang;
        STARTED_AT = block.timestamp;
        _mint(team, totalClaimed);
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Dugo_FunctionLocked();
        _;
    }

    /**
     * @notice Current !praying epoch
     */
    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - STARTED_AT) / EPOCH_DURATION;
    }

    /**
     * @notice Base rate of specified token
     * @param tokenId Token to return base rate for
     */
    function baseRate(uint256 tokenId) public pure returns (uint256) {
        if (tokenId >= TOTAL_SUPPLY) revert Dugo_TokenIdOutOfRange();

        return tokenId < GENESIS_SUPPLY ? GENESIS_BASE_RATE : MANANANGGAL_BASE_RATE;
    }

    /**
     * @notice Calculate the $DUGO generation rate at a specified epoch
     * @param _baseRate Base rate for a particular token
     * @param epoch Epoch to calculate rate for
     */
    function rate(uint256 _baseRate, uint256 epoch) internal pure returns (uint256) {
        return epoch == 0 ? _baseRate : _baseRate / (2 ** epoch);
    }

    /**
     * @notice Last time $DUGO was claimed for a specified token
     * @param tokenId Token to return the last claim time for
     */
    function lastClaimedAt(uint256 tokenId) public view returns (uint256) {
        uint256 prayingStartedAt = ASWANG.prayingStartedAt(tokenId);

        if (prayingStartedAt == 0) return 0;

        return prayingStartedAt > _lastClaimedAt[tokenId] ? prayingStartedAt : _lastClaimedAt[tokenId];
    }

    /**
     * @notice The amount of currently claimable $DUGO for a specified token
     * @param tokenId Token to return the amount of claimable $DUGO for
     */
    function claimable(uint256 tokenId) public view returns (uint256) {
        uint256 claimFrom = lastClaimedAt(tokenId);

        if (claimFrom == 0) return 0;

        uint256 totalClaimable;
        uint256 _currentEpoch = currentEpoch();
        uint256 _baseRate = baseRate(tokenId);
        uint256 epochEndsAt = STARTED_AT + EPOCH_DURATION;

        for (uint256 i; i <= _currentEpoch;) {
            unchecked {
                if (epochEndsAt > claimFrom) {
                    totalClaimable += ((i == _currentEpoch ? block.timestamp : epochEndsAt) - claimFrom)
                        * rate(_baseRate, i)
                        / 1 days;

                    claimFrom = epochEndsAt;
                }

                epochEndsAt += EPOCH_DURATION;
                ++i;
            }
        }

        return totalClaimable;
    }

    /**
     * @notice Lower the maximum token supply
     * @param newMaxSupply New max supply
     */
    function lowerMaxSupply(uint256 newMaxSupply) external lockable onlyOwner  {
        if (newMaxSupply > maxSupply || newMaxSupply < totalClaimed) revert Dugo_InvalidMaxSupply();

        maxSupply = newMaxSupply;
    }

    /**
     * @notice ASWANG contract only function to burn a specified amount of $DUGO
     * @param account Account to burn $DUGO from
     * @param amount Amount of $DUGO to burn
     */
    function burn(address account, uint256 amount) public override {
        if (_msgSender() != address(ASWANG)) revert Dugo_NotAswangContract();

        _burn(account, amount);
    }

    /**
     * @notice ASWANG contract only function to claim $DUGO for a specified token
     * @param account Account that owns the token
     * @param tokenId Token to claim $DUGO for
     */
    function claim(address account, uint256 tokenId) public override {
        if (_msgSender() != address(ASWANG)) revert Dugo_NotAswangContract();

        _claim(account, tokenId);
    }

    /**
     * @notice Claim $DUGO for specified tokens
     * @param tokenIds Tokens to claim $DUGO for
     */
    function claim(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length;) {
            _claim(_msgSender(), tokenIds[i]);
            _lastClaimedAt[tokenIds[i]] = block.timestamp;
            unchecked { ++i; }
        }
    }

    /**
     * @notice Internal function to claim $DUGO for specified account and token
     * @param account Account that owns the token
     * @param tokenId Token to claim $DUGO for
     */
    function _claim(address account, uint256 tokenId) internal nonReentrant {
        if (ASWANG.ownerOf(tokenId) != account) revert Dugo_NotTokenOwner();

        if (totalClaimed < maxSupply) {
            uint256 _claimable = claimable(tokenId);

            _mint(
                account,
                totalClaimed + _claimable < maxSupply ? _claimable : maxSupply - totalClaimed
            );

            totalClaimed += _claimable;
        }
    }

    /**
     * @notice Recover ASWANG tokens accidentally transferred directly to the contract
     * @param to Account to send the ASWANG to
     * @param tokenId ASWANG to recover
     */
    function recoveryTransfer(address to, uint256 tokenId) external lockable onlyOwner {
        ASWANG.transferFrom(address(this), to, tokenId);
    }

    /**
     * @notice Lock individual functions that are no longer needed. WARNING: THIS CANNOT BE UNDONE
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        functionLocked[id] = true;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDugo is IERC20 {
    function burn(address, uint256) external;
    function claim(address, uint256) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}