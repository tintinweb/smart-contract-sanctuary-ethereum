/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT
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


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SignerRole
 * @dev A signer role contract.
 */
abstract contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () {
        _addSigner(_msgSender());
    }

    /**
     * @dev Makes function callable only if sender is a signer.
     */
    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    /**
     * @dev Checks if the address is a signer.
     */
    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    /**
     * @dev Makes the address a signer. Only other signers can add new signers.
     */
    function addSigner(address account) public virtual onlySigner {
        _addSigner(account);
    }

    /**
     * @dev Removes the address from signers. Signer can be renounced only by himself.
     */
    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

abstract contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "[Pauser Role]: only for pauser");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
abstract contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title AdminRole
 * @dev An operator role contract.
 */
abstract contract AdminRole is Context {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () {

    }

    /**
     * @dev Makes function callable only if sender is an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    /**
     * @dev Checks if the address is an admin.
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

/**
 * @title TokenProviderRole
 * @dev An operator role contract.
 */
abstract contract TokenProviderRole is Context {
    using Roles for Roles.Role;

    event TokenProviderAdded(address indexed account);
    event TokenProviderRemoved(address indexed account);

    Roles.Role private _providers;

    constructor () {

    }

    /**
     * @dev Makes function callable only if sender is an token provider.
     */
    modifier onlyTokenProvider() {
        require(isTokenProvider(_msgSender()), "TokenProviderRole: caller does not have the Token Provider role");
        _;
    }

    /**
     * @dev Checks if the address is an token provider.
     */
    function isTokenProvider(address account) public view returns (bool) {
        return _providers.has(account);
    }

    function _addTokenProvider(address account) internal {
        _providers.add(account);
        emit TokenProviderAdded(account);
    }

    function _removeTokenProvider(address account) internal {
        _providers.remove(account);
        emit TokenProviderRemoved(account);
    }
}

contract Exchanger is Ownable {
    address public vestingProxy;
    address public beneficiary;

    uint ratePur = 0.016 * 1e18;
    uint rateHwx = 1e18;

    uint public minimalBuyingLimit = 50000e18;

    address[] purchasedTokens;
    mapping (address => bool) isPurchased;

    constructor (address[] memory _purchasedTokens, address _vestingProxy, address _beneficiary) {
        require(_vestingProxy != address(0), "zero vesting Proxy token address");
        require(_beneficiary != address(0), "zero beneficiary address");
        for (uint i = 0 ; i < _purchasedTokens.length; i++) {
            require(_purchasedTokens[i] != address(0), "zero purchased token address");
            addPurchasedToken(_purchasedTokens[i]);
        }
        vestingProxy = _vestingProxy;
        beneficiary = _beneficiary;
    }

    function buy(address _token, uint amount) public {
        require(isPurchased[_token], "(buy) the token is not purchased");
        require(amount > 0, "(buy) zero amount");
        (uint purAmount, uint hwxAmount) = prices(amount);
        require(purAmount >= minimalBuyingLimit, "(buy) less than minimal buying limit");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= purAmount, "(buy) not approved token amount");
        require(hwxAmount > 0, "(buy) zero contribution");

        IERC20(_token).transferFrom(msg.sender, beneficiary, purAmount);
        IERC20(vestingProxy).transfer(msg.sender, hwxAmount);
    }

    function prices(uint hwxAmount) public view returns(uint _purchasedToken, uint _hwxAmount) {
        _purchasedToken = hwxAmount * ratePur/rateHwx;
        _hwxAmount = _purchasedToken * rateHwx/ratePur;
    }

    function updateRate(uint _ratePur, uint _rateHwx) public onlyOwner {
        ratePur = _ratePur;
        rateHwx = _rateHwx;
    }

    function updateProxy(address proxy) public onlyOwner {
        require(proxy != address(0), "zero address of the token");
        vestingProxy = proxy;
    }
    
    function updateBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function getRateFromUSDT(uint usdtAmount) public view returns(uint) {
        uint _hwxAmount = usdtAmount * rateHwx/ratePur;
        return _hwxAmount;
    }

    function getPurchasedTokens() public view returns(address[] memory) {
        return purchasedTokens;
    }

    function withdrawHWX(address token, uint amount) public onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "insufficient balance");
        IERC20(token).transfer(msg.sender, amount);
    }

    function updateMinimalBuyingLimit(uint newLimit) public onlyOwner {
        minimalBuyingLimit = newLimit;
    }

    function addPurchasedToken(address _token) public onlyOwner {
        require(!isPurchased[_token], "(addPurchasedToken) the already purchased token");
        purchasedTokens.push(_token);
        isPurchased[_token] = true;
    }

    function removePurchasedToken(address _token) public onlyOwner {
        require(isPurchased[_token], "(addPurchasedToken) the not purchased token");
        deleteAddressFromArray(purchasedTokens, _token);
        isPurchased[_token] = false;
    }

    function deleteAddressFromArray(address[] storage _array, address _address) private {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                address temp = _array[_array.length-1];
                _array[_array.length-1] = _address;
                _array[i] = temp;
            }
        }

        _array.pop();
    }
}