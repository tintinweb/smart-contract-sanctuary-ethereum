// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: UNLISTED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CandaoPriorityPass is Ownable, Pausable {

    struct ProrityPass {
        // @dev: package price starting
        uint256 priorityPassPrice;

        // @dev: domain lenght in character count
        uint256 domainLength;

        // @dev: 
        uint256 blockNumber;

        // @dev: price transfered from user
        uint256 price;

        // @dev: only for validation
        bool valid;
    }

    struct PriorityPassPackageValue {
        // @dev: character count
        uint256 domainLength;

        // @dev: domain price based on package
        uint256 domainPrice;

        // @dev: total price that should be transfered from user
        uint256 totalPrice;

        // @dev: only for validation
        bool valid;
    }

    // @dev: USDC token address
    IERC20 public token;

    // @dev: available packages with configuration
    mapping (uint256 => PriorityPassPackageValue[]) private _packages;
    uint256[] private _availablePackages;

    mapping (uint256 => uint256) private _domainPricing;

    // @dev: wallet address that holds Candao tokens
    address private wallet;

    // @dev: mapping hosting user PP 
    mapping (address => ProrityPass) private _userInfo;

    // @dev: EVENTS
    event PriorityPassBought(address buyer, string reservationToken, uint256 packageIndex, uint256 price, uint256 domainLength);
    event DomainBought(address buyer, string[] reservationToken, uint256 price);
    event CDOBought(address buyer, uint256 amount);
    event BadgesAddressUpdated(address newAddress);
    event TokenAddressUpdated(address newAddress);

    constructor(address _token, address _wallet) {
        token = IERC20(_token);
        wallet = _wallet;
    }

    function buyPriorityPass(uint256 packagePrice, string memory domain, string memory reservationToken) external whenNotPaused {
        require(!_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy priority pass.");
        
        uint256 characterCount = bytes(domain).length;
        require(characterCount != 0, "CandaoCoordinator: Incorrect domainLength.");

        PriorityPassPackageValue[] memory pricingPackages = _packages[packagePrice];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < pricingPackages.length; i++) {
            PriorityPassPackageValue memory packageItem = pricingPackages[i];
            if (packageItem.domainLength == characterCount) {
                totalPrice = packageItem.totalPrice;
            }
        }

        require(totalPrice != 0, "CandaoCoordinator: package totalPrice not found.");

        token.transferFrom(msg.sender, wallet, totalPrice);
        _userInfo[msg.sender] = ProrityPass(packagePrice, characterCount, block.number, totalPrice, true);
        emit PriorityPassBought(msg.sender, reservationToken, packagePrice, totalPrice, characterCount);
    }

    function addPriorityPass(address _initialBuyer, address _successor) external onlyOwner {
        ProrityPass memory initialBuyerPP = _userInfo[_initialBuyer];
        _userInfo[_successor] = ProrityPass(initialBuyerPP.priorityPassPrice, initialBuyerPP.domainLength, initialBuyerPP.blockNumber, initialBuyerPP.price, true);
    }

    function buyCDO(uint256 amount) external {
        require(_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy CDO tokens.");
        token.transferFrom(msg.sender, wallet, amount);
        emit CDOBought(msg.sender, amount);
    }

    function buyAdditionalDomain(string[] memory domains, string[] memory reservationTokens) external {
        require(_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy domain.");
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < domains.length; i++) {
            uint256 characterCount = bytes(domains[i]).length;
            require(characterCount != 0, "CandaoCoordinator: Incorrect domainLength.");
            uint256 domainPrice = _domainPricing[characterCount];
            require(domainPrice != 0, "CandaoCoordinator: Domain pricing not set.");
            totalPrice += domainPrice;
        }

        token.transferFrom(msg.sender, wallet, totalPrice);
        emit DomainBought(msg.sender, reservationTokens, totalPrice);
    }

    function addDomainPrice(uint256 domainLength, uint256 price) external onlyOwner {
        _domainPricing[domainLength] = price;
    }

    function addPackageOption(uint256 packagePrice, uint256 domainLength, uint256 domainPrice, uint256 totalPrice) external onlyOwner {
        if (_packages[packagePrice].length == 0) {
            _availablePackages.push(packagePrice);
        }

        PriorityPassPackageValue[] memory pricingPackages = _packages[packagePrice];
        for (uint256 i = 0; i < pricingPackages.length; i++) {
            PriorityPassPackageValue memory packageItem = pricingPackages[i];
            if (packageItem.domainLength == domainLength) {
                revert("CandaoCoordinator: Duplicate package option.");
            }
        }

        _packages[packagePrice].push(PriorityPassPackageValue(domainLength, domainPrice, totalPrice, true));
    }

    function removePackage(uint256 packagePrice) external onlyOwner {
        require(_packages[packagePrice].length != 0, "CandaoCoordinator: Missing package");
        delete _packages[packagePrice];

        for (uint i = 0; i < _availablePackages.length; i++) {
            if (_availablePackages[i] == packagePrice) {
                delete _availablePackages[i];
            }
        }
    }

    function removePackageDomainLength(uint256 packagePrice, uint256 packageValueIndex) external onlyOwner {
        require(packagePrice != 0, "CandaoCoordinator: Package Index can't be 0.");
        require(packageValueIndex != 0, "CandaoCoordinator: Package Value Index can't be 0.");
        require(_packages[packagePrice].length != 0, "CandaoCoordinator: Missing package");
        require(_packages[packagePrice][packageValueIndex].valid, "CandaoCoordinator: Missing package value");
        delete _packages[packagePrice][packageValueIndex];
    }

    function setTokenAddress(address newAddress) external onlyOwner {
        require(address(token) != newAddress, "CandaoCoordinator: newAddress can't same as prev.");
        token = IERC20(newAddress);
        emit TokenAddressUpdated(newAddress); 
    }

    function removePriorityPass() external {
        delete _userInfo[msg.sender];
    }

    function setWalletAddress(address newAddress) external onlyOwner {
        wallet = newAddress;
    }

    function userInfo(address _wallet) public view returns (ProrityPass memory) {
        return _userInfo[_wallet];
    }

    function showPackage(uint256 selectedPackage) public view returns (PriorityPassPackageValue[] memory) {
        return _packages[selectedPackage];
    }

    function showDomainPricing(uint256 characterCount) public view returns (uint256) {
        return _domainPricing[characterCount];
    }

    function showAvailablePackages() public view returns (uint256[] memory) {
        return _availablePackages;
    }
}