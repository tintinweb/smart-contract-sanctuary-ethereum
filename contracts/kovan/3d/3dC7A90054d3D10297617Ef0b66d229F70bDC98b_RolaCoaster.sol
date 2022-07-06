// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BlackList.sol";
import "./IRolaCoaster.sol";

contract RolaCoaster is ERC20, Ownable, Pausable, ReentrancyGuard, BlackList, IRolaCoaster{

    using Counters for Counters.Counter;

    // Index counter for the next NFT ID's
    Counters.Counter internal nextTokenIndex;

    enum PublicSaleStages {
        phase1,
        phase2,
        phase3,
        phase4,
        phase5
    }

    IERC20 public USDCContract;

    PublicSaleStages public currentStage;

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    uint16 constant HUNDRED_PERCENTAGE = 10000;

    uint8 constant DECIMALS_USDC = 6;

    uint16 public immutable PUBLIC_SALE_PERCENTAGE = 1500;
    uint16 public immutable ADVISOR_PERCENTAGE = 1000;
    uint16 public immutable TEAM_PERCENTAGE = 1200;

    uint256 public immutable ROLA_CAP;

    uint256 public treasurySupplyRola = 0;
    uint256 public publicSaleSupplyRola = 0;
    uint256 public advisorSupplyRola = 0;
    uint256 public teamSupplyRola = 0;

    uint256 public startTime;
    uint256 public rolaRatePerUSDC;

    // Address of the maintainer
    address private maintainer;

    // Address of the treasury
    address private treasury;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 rolaCap,
        uint256 rolaTokenRatePerUSDC,
        address maintainerAddress,
        address treasuryAddress,
        address usdcContractAddress
    ) ERC20(tokenName, tokenSymbol) {
        require(maintainerAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set maintainer with Zero Address.");
        require(treasuryAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set treasury with Zero Address.");
        ROLA_CAP = rolaCap * (10 ** decimals());
        rolaRatePerUSDC = rolaTokenRatePerUSDC;
        maintainer = maintainerAddress;
        treasury = treasuryAddress;
        currentStage = PublicSaleStages.phase1;
        startTime = block.timestamp;
        USDCContract = IERC20(usdcContractAddress);
    }

    /// @dev This is the onlyMaintainer modifier. It is used by the backend to call contracts functions only by the maintainer address.

    modifier onlyMaintainer() {
        require(maintainer == _msgSender(), "RolaCoaster: caller is not the maintainer address");
        _;
    }

    modifier onlyTreasury() {
        require(treasury == _msgSender(), "RolaCoaster: caller is not the treasury address");
        _;
    }

    function mintRolaToTreasury(uint256 amountRola) external override onlyTreasury whenNotPaused nonReentrant {
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        treasurySupplyRola += amountRola;
        _mint(treasury, amountRola);
        emit RolaMinted(treasury, amountRola);
    }

    function mintRolaForAdvisor(address account, uint256 amountRola) external override onlyMaintainer whenNotPaused nonReentrant whenNotBlackListedUser(account) {
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        require((ROLA_CAP * ADVISOR_PERCENTAGE)/HUNDRED_PERCENTAGE >= advisorSupplyRola + amountRola, "RolaCoaster: Advisor maximum supply reached.");
        advisorSupplyRola += amountRola;
        _mint(account, amountRola);
        emit RolaMinted(account, amountRola);
    }

    function mintRolaForTeam(address account, uint256 amountRola) external override onlyMaintainer whenNotPaused nonReentrant whenNotBlackListedUser(account) {
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        require((ROLA_CAP * TEAM_PERCENTAGE)/HUNDRED_PERCENTAGE >= teamSupplyRola + amountRola, "RolaCoaster: Team maximum supply reached.");
        teamSupplyRola += amountRola;
        _mint(account, amountRola);
        emit RolaMinted(account, amountRola);
    }

    function mintRolafromMaintainer(address account, uint256 amountRola) external override onlyMaintainer whenNotPaused nonReentrant whenNotBlackListedUser(account) {
        require(account != ZERO_ADDRESS, "RolaCoaster: Cannot mint Rola to Zero Address.");
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        _mint(account, amountRola);
        emit RolaMinted(account, amountRola);
    }

    /// @dev This is the mintRola function. It is used for minting ROLA tokens to the callers address.
    /// @dev Only the maintainer or artist can call this function
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token
    
    function mintRolaforPublicSale(uint256 amountUSDC) external override whenNotPaused nonReentrant whenNotBlackListedUser(_msgSender()) {
        require(amountUSDC > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        require(USDCContract.balanceOf(_msgSender()) > amountUSDC, "RolaCoaster: Insufficient USDC tokens.");
        uint256 amountRola = (amountUSDC * rolaRatePerUSDC * ( 10 ** decimals())) / (10 ** DECIMALS_USDC);
        USDCContract.transferFrom(_msgSender(), treasury, amountUSDC);
        publicSaleSupplyRola += amountRola;
        _mint(_msgSender(), amountRola);
        emit RolaMinted(_msgSender(), amountRola);
    }

    /// @dev This is the airdropRola function. It is used by the owner to airdrop `quantity` number of ROLA tokens to the `assigned` address respectively.
    /// @dev Only the owner can call this function
    /// @param assigned The address to be air dropped
    /// @param quantity The amount of random tokens to be air dropped respectively

    function airdropRola(address[] memory assigned, uint256[] memory quantity) external override onlyOwner whenNotPaused nonReentrant {
        require(assigned.length == quantity.length, "RolaCoaster: Incorrect parameter length");
        for (uint8 index = 0; index < assigned.length; index++) {
            if(!_isBlackListUser(assigned[index])){
                _mint(assigned[index], quantity[index]);
            }
        }
    }

    /// @dev This is the updateMaintainerAddress function. It is used by the owner to update the maintainer address in the contract.
    /// @dev Only the owner or artist can call this function
    /// @param newMaintainerAddress New maintainer address for the RolaCoaster contract 

    function updateMaintainerAddress(address newMaintainerAddress) external override onlyOwner whenNotPaused {
        require(maintainer != newMaintainerAddress,"RolaCoaster: The new maintainer address must be different from the old one");
        require(newMaintainerAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set maintainer with Zero Address.");
        maintainer = newMaintainerAddress;
        emit NewMaintainAddressSet(newMaintainerAddress);
    }

    /// @dev This is the getMaintainerAddress function. It is used to get the maintainer address in the contract.

    function getMaintainerAddress() external view override returns (address) {
        return maintainer;
    }

    /// @dev This is the updateTreasuryAddress function. It is used by the owner to update the treasury address in the contract.
    /// @dev Only the owner or artist can call this function
    /// @param newTreasuryAddress New maintainer address for the RolaCoaster contract 

    function updateTreasuryAddress(address newTreasuryAddress) external override onlyTreasury whenNotPaused {
        require(treasury != newTreasuryAddress,"RolaCoaster: The new treasury address must be different from the old one");
        require(newTreasuryAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set treasury with Zero Address.");
        treasury = newTreasuryAddress;
        emit NewTreasuryAddressSet(newTreasuryAddress);
    }

    /// @dev This is the getTreasuryAddress function. It is used to get the treasury address in the contract.

    function getTreasuryAddress() external view override returns (address) {
        return treasury;
    }

    /// @dev This function would add an address to the blacklist mapping
    /// @dev Only the owner can call this function
    /// @param user The account to be added to blacklist

    function addToBlackList(address[] memory user) external override onlyOwner whenNotPaused returns (bool) {
        for (uint256 index = 0; index < user.length; index++) {
            if( user[index] != ZERO_ADDRESS){
                _addToBlackList(user[index]);
            }
        }
        return true;
    }

    /// @dev This function would remove an address from the blacklist mapping
    /// @dev Only the owner can call this function
    /// @param user The account to be removed from blacklist

    function removeFromBlackList(address[] memory user) external override onlyOwner whenNotPaused returns (bool) {
        for (uint256 index = 0; index < user.length; index++) {
            if( user[index] != ZERO_ADDRESS){
                _removeFromBlackList(user[index]);
            }
        }
        return true;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }   

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the RolaCoaster ERC1155 token implementation.
 * @author The Systango Team
 */

interface IRolaCoaster {

    /**
     * @dev Event generated when a new Maintainer is set
     */
    event NewMaintainAddressSet(address newMaintainerAddress);

    /**
     * @dev Event generated when a new Treasury is set
     */
    event NewTreasuryAddressSet(address newTreasuryAddress);

    /**
     * @dev Event generated when ROLA tokens are minted
     */
    event RolaMinted(address account, uint256 amount);

    event PhaseChanged(uint8 newPhase);

    function mintRolaToTreasury(uint256 amountRola) external;

    function mintRolaForAdvisor(address account, uint256 amountRola) external;

    function mintRolaForTeam(address account, uint256 amountRola) external;

    function mintRolafromMaintainer(address account, uint256 amountRola) external;
    /**
     * @dev Mint the ROLA tokens to the account
     */
    function mintRolaforPublicSale(uint256 amount) external;

    /**
     * @dev Airdrop the ROLA tokens to a set of users
     */
    function airdropRola(address[] memory assigned, uint256[] memory quantity) external;

    /**
     * @dev Set the maintainer address of the contract
     */
    function updateMaintainerAddress(address newMaintainerAddress) external;

    /**
     * @dev Get the maintainer address of the contract
     */
    function getMaintainerAddress() external view returns (address);

    /**
     * @dev Set the treasury address of the contract
     */
    function updateTreasuryAddress(address newTreasuryAddress) external;

    /**
     * @dev Get the treasury address of the contract
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @dev Adds the account to blacklist
     */
    function addToBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Removes the account from blacklist
     */
    function removeFromBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Pause the contract
     */
    function pause() external;

    /**
     * @dev Unpause the contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Blacklist contract for RolaCoaster Contract
/// @author The Systango Team

contract BlackList {

    // Mapping between the address and boolean for blacklisting
    mapping (address => bool) public blackList;

    // Event to trigger the addition of address to blacklist mapping
    event AddedToBlackList(address _user);

    // Event to trigger the removal of address from blacklist mapping
    event RemovedFromBlackList(address _user);
    
    // This function would add an address to the blacklist mapping

    /// @param user The account to be added to blacklist

    function _addToBlackList(address user) internal virtual returns (bool) {
        blackList[user] = true;
        emit AddedToBlackList(user);
        return true;
    }

    // This function would remove an address from the blacklist mapping

    /// @param user The account to be removed from blacklist

    function _removeFromBlackList(address user) internal virtual returns (bool) {
        blackList[user] = false;
        // delete blackList[_user];
        emit RemovedFromBlackList(user);
        return true;
    }

    // This function would check an address from the blacklist mapping

    /// @param _user The account to be checked from blacklist mapping

    function _isBlackListUser(address _user) internal virtual returns (bool){
        return blackList[_user];
    }

    // Modifier to check address from the blacklist mapping

    /// @param _user The account to be checked from blacklist mapping

    modifier whenNotBlackListedUser(address _user) {
        require(!_isBlackListUser(_user), "RolaCoaster: This address is in blacklist");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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