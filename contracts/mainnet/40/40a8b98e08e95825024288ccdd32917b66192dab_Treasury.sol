// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * What is WGLX?
 Like WSTR, but for galaxies. And without any involvement from Tlon.
 * How do I vote a galaxy?
 Buy up enough WGLX to withdraw the top galaxy, vote it, and hold it till the
 poll expires. Then you may redeposit it and get your WGLX back.
 * How do I know the top galaxy will be allowed to vote in a poll?
 The treasury forbids depositing a galaxy which has voted on any active poll.
 * What if several people want to pool their fractions of WGLX to vote together?
 They can use a straightforward contract to do this.
 * What if there is only 1 galaxy in the treasury?
 Actually withdrawing the bottom galaxy in the stack may be impossible due to
 outstanding WGLX being lost, burned, or just incommunicado. Thus, if there is
 exactly 1 galaxy deposited and you have more than half the outstanding WGLX, you
 can vote/manage it through the contract without withdrawing it.
 * Why would anyone be the first to deposit a galaxy?
 As a motivator to get liquidity off the ground, there is a bonus for the first
 few galaxy depositors. The 1st galaxy deposited earns 1,200,000 WGLX (and costs the
 same to withdraw). The 2nd galaxy is 1,100,000 WGLX and the third is 1,050,000.
 After that, subsquent galaxies are worth 1,000,000 WGLX each.
 * How many galaxies can be deposited?
 At most 128. If a majority of galaxies were deposited, the treasury would be
 able to upgrade itself, which seems too dangerous.
 * When can the contracts self-destruct?
 Only when there are zero deposited galaxies and zero outstanding WGLX. The
 contracts were directly deployed from an external account, so there is no
 CREATE2 risk of hijacking the address with a different coin.
 * What about censures and claims?
 It is possible that the top galaxy you withdraw will have censures or claims
 attached to it. Fortunately, nobody uses these for anything and they don't matter
 at all.
 * What about spawning?
 You should only expect "bare" galaxies (which have already spawned all their
 stars) to be deposited.
*/


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "./interface/IPolls.sol";
import "./GalaxyToken.sol";

//  Treasury: Galaxy wrapper
//
//    This contract implements an extremely simple wrapper for galaxies.
//    It allows owners of Azimuth galaxy points to deposit them and mint new WGLX (wrapped galaxy) tokens,
//    and in turn to redeem WGLX tokens for Azimuth galaxies.

contract Treasury is Context, Ownable {
    // MODEL

    //  assets: galaxies currently held in this pool
    //  note: galaxies are 8 bit numbers and we always handle them as uint8.
    //  some azimuth and ecliptic calls (below) expect uint32 points. in these cases, solidity upcasts the uint8 to
    //  uint32, which is a safe operation.
    //
    uint8[] public assets;

    //  azimuth: points state data store
    //
    IAzimuth public immutable azimuth;

    // deploy a new token contract with no balance
    GalaxyToken public immutable galaxytoken;

    // bonuses for the first few depositors
    uint256 constant public FIRST_GALAXY = 1.2e24;
    uint256 constant public SECOND_GALAXY = 1.1e24;
    uint256 constant public THIRD_GALAXY = 1.05e24;
    uint256 constant public SUBSEQUENT_GALAXY = 1e24;
    uint256 constant public VOTE_FIRST_GALAXY = FIRST_GALAXY/ 2 + 1;

    // EVENTS

    event Deposit(
        uint8 indexed galaxy,
        address sender
    );

    event Redeem(
        uint8 indexed galaxy,
        address sender
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store and token contract
    // address
    constructor(IAzimuth _azimuth, GalaxyToken _galaxytoken) Ownable()
    {
        azimuth = _azimuth;
        galaxytoken = _galaxytoken;
    }

    //  getAllAssets(): return array of assets held by this contract
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getAllAssets()
        view
        external
        returns (uint8[] memory allAssets)
    {
        return assets;
    }

    //  getAssetCount(): returns the number of assets held by this contract
    //
    function getAssetCount()
        view
        external
        returns (uint256 count)
    {
        return assets.length;
    }

    function getTopGalaxyValue()
        view
        internal
        returns (uint256 value)
    {
        if (assets.length == 1) {
            return FIRST_GALAXY;
        } else if (assets.length == 2) {
            return SECOND_GALAXY;
        } else if (assets.length == 3) {
            return THIRD_GALAXY;
        } else {
            return SUBSEQUENT_GALAXY;
        }
    }

    function requireHasNotVotedOnAnyActivePoll(
        uint8 _galaxy, IPolls polls)
        view
        internal
    {
        uint256 i = polls.getDocumentProposalCount();
        while(i > 0) {
            i--;
            bytes32 proposal = polls.documentProposals(i);
            (uint256 start,
             uint16 yesVotes,
             uint16 noVotes,
             uint256 duration,
             uint256 cooldown) = polls.documentPolls(proposal);
            if (block.timestamp < start + duration) {
                require(!polls.hasVotedOnDocumentPoll(_galaxy, proposal),
                        "Treasury: Galaxy has voted on active document");
            }
        }
        i = polls.getUpgradeProposalCount();
        while(i > 0) {
            i--;
            address proposal = polls.upgradeProposals(i);
            (uint256 start,
             uint16 yesVotes,
             uint16 noVotes,
             uint256 duration,
             uint256 cooldown) = polls.upgradePolls(proposal);
            if (block.timestamp < start + duration) {
                require(!polls.hasVotedOnUpgradePoll(_galaxy, proposal),
                        "Treasury: Galaxy has voted on active upgrade");
            }
        }
    }

    //  deposit(galaxy): deposit a galaxy you own, receive a newly-minted wrapped galaxy token in exchange
    //
    function deposit(uint8 _galaxy) external
    {
        require(assets.length < 128, "Treasury: full");
        require(azimuth.getPointSize(_galaxy) == IAzimuth.Size.Galaxy, "Treasury: must be a galaxy");
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        requireHasNotVotedOnAnyActivePoll(_galaxy, ecliptic.polls());

        require(azimuth.getSpawnProxy(_galaxy) != 0x1111111111111111111111111111111111111111,
                "Treasury: No L2");
        require(azimuth.canTransfer(_galaxy, _msgSender()),
                "Treasury: can't transfer"); 
        // transfer ownership of the _galaxy to :this contract
        // note: _galaxy is uint8, ecliptic expects a uint32 point
        ecliptic.transferPoint(_galaxy, address(this), true);

        //  update state to include the deposited galaxy
        //
        assets.push(_galaxy);

        //  mint a galaxy token and grant it to the :msg.sender
        galaxytoken.mint(_msgSender(), getTopGalaxyValue());
        emit Deposit(_galaxy, _msgSender());
    }

    //  redeem(): burn one galaxy token, receive ownership of the most recently deposited galaxy in exchange
    //
    function redeem() external returns (uint8) {
        // there must be at least one galaxy in the asset list
        require(assets.length > 0, "Treasury: no galaxy available to redeem");

        // must have sufficient balance
        uint256 _topGalaxyValue = getTopGalaxyValue();
        require(galaxytoken.balanceOf(_msgSender()) >= _topGalaxyValue, "Treasury: Not enough balance");

        // remove the galaxy to be redeemed
        uint8 _galaxy = assets[assets.length-1];

        assets.pop();

        // burn the tokens
        galaxytoken.ownerBurn(_msgSender(), _topGalaxyValue);

        // transfer ownership
        // note: Treasury should be the owner of the point and able to transfer it. this check happens inside
        // transferPoint().

        // note: _galaxy is uint8, ecliptic expects a uint32 point
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        ecliptic.transferPoint(_galaxy, _msgSender(), true);

        emit Redeem(_galaxy, _msgSender());
        return _galaxy;
    }

    // When the treasury contains exactly 1 galaxy, anyone with more than half
    // its cost can vote/manage it.
    function setProxy(address _addr) external {
        require(assets.length == 1, "Treasury: needs 1 galaxy");
        require(galaxytoken.balanceOf(_msgSender()) >= VOTE_FIRST_GALAXY,
                "Treasury: Not enough balance");
        galaxytoken.ownerBurn(_msgSender(), VOTE_FIRST_GALAXY);
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        ecliptic.setVotingProxy(assets[0], _addr);
        ecliptic.setManagementProxy(assets[0], _addr);
    }

    function unsetProxy() external {
        require(assets.length >= 1, "Treasury: needs a galaxy");
        uint8 _gal = assets[0];
        require(azimuth.canVoteAs(_gal, _msgSender()),
                "Treasury: not voter");
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        requireHasNotVotedOnAnyActivePoll(_gal, ecliptic.polls());
        ecliptic.setVotingProxy(_gal, address(0));
        ecliptic.setManagementProxy(_gal, address(0));
        galaxytoken.mint(_msgSender(), VOTE_FIRST_GALAXY);
    }
    function destroyAndSend(address payable _recipient) external onlyOwner {
        require(galaxytoken.totalSupply()==0, "Treasury: not empty");
        selfdestruct(_recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

//  GalaxyToken: ERC20-compatible fungible wrapped galaxy token
//
//    This contract implements a simple ERC20-compatible fungible token. It's deployed
//    and owned by the Treasury. The Treasury mints and burns these tokens when it
//    processes deposits and withdrawals.

contract GalaxyToken is Context, Ownable, ERC20 {
    constructor() Ownable() ERC20("WrappedGalaxy", "WGLX") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function ownerBurn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function destroyAndSend(address payable _recipient) public onlyOwner {
        require(totalSupply() == 0, "GalaxyToken: not empty");
        selfdestruct(_recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPolls {
  function getDocumentProposalCount()
    external
    view
      returns (uint256 count);
  function hasVotedOnDocumentPoll(uint8 _galaxy, bytes32 _proposal)
    external
    view
      returns (bool result);

    function getUpgradeProposalCount()
    external
    view
      returns (uint256 count);
  function hasVotedOnUpgradePoll(uint8 _galaxy, address _proposal)
    external
    view
      returns (bool result);

  // getters autogenerated by Solidity 0.4.24

  function documentProposals(uint)
        external
        view
        returns (bytes32 proposal);
  function documentPolls(bytes32 proposal) view external returns
      (uint256 start,
       // bool[256] voted -- omitted by solidity
       uint16 yesVotes,
       uint16 noVotes,
       uint256 duration,
       uint256 cooldown);
  function upgradeProposals(uint)
        external
        view
        returns (address proposal);
  function upgradePolls(address proposal) view external returns
      (uint256 start,
       // bool[256] voted -- omitted by solidity
       uint16 yesVotes,
       uint16 noVotes,
       uint256 duration,
       uint256 cooldown);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPolls.sol";

interface IEcliptic {
    function polls() external returns (IPolls);
    function transferPoint(uint32, address, bool) external;
    function setVotingProxy(uint8, address) external;
    function setManagementProxy(uint32, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAzimuth {
    function canVoteAs(uint32, address) view external returns (bool);
    function canTransfer(uint32, address) view external returns (bool);
    function getPointSize(uint32) external pure returns (Size);
    function owner() external returns (address);
    function getSpawnProxy(uint32) view external returns (address);
    enum Size
    {
        Galaxy, // = 0
        Star,   // = 1
        Planet  // = 2
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