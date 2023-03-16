//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/pools/common/RealWorldAssetReceipt.sol";

/// @title Stablz Cannavest - Real world asset pool
contract StablzCannavestPool is RealWorldAssetReceipt, Ownable {

    using SafeERC20 for IERC20;

    address public rwaHandler;
    // @dev this is used to allow for decimals in the currentRewardValue as well as to convert USDT amount to 18 decimals
    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;
    uint private constant LOCK_UP_PERIOD = 365 days;
    uint private constant ONE_USDT = 10 ** 6;
    uint private constant MAX_AMOUNT = 5_000_000 * ONE_USDT;
    uint public startedAt;
    bool public isDepositingEnabled;
    uint public finalAmount;
    uint public finalSupply;
    uint public currentRewardFactor;
    uint public allTimeRewards;
    uint public allTimeRewardsClaimed;
    uint public allTimeCirculatingSupplyAtDistribution;

    struct Reward {
        uint factor;
        uint held;
    }

    mapping(address => Reward) private _rewards;

    event Started();
    event Ended(uint finalAmount, uint finalSupply);
    event RealWorldAssetHandlerUpdated(address rwaHandler);
    event DepositingEnabled();
    event DepositingDisabled();
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint expected, uint actual);
    event Claimed(address indexed user, uint rewards);
    event Distributed(uint rewards, uint circulatingSupply);

    modifier onlyRWAHandler() {
        require(_msgSender() == rwaHandler, "StablzCannavestPool: Only the real world asset handler can call this function");
        _;
    }

    /// @param _rwaHandler Real world asset handler
    constructor(address _rwaHandler) RealWorldAssetReceipt("STABLZ-CANNAVEST", "CANNAVEST") {
        require(_rwaHandler != address(0), "StablzCannavestPool: _rwaHandler cannot be the zero address");
        rwaHandler = _rwaHandler;
    }

    /// @notice Start the pool
    function start() external onlyOwner {
        require(startedAt == 0, "StablzCannavestPool: Already started");
        startedAt = block.timestamp;
        isDepositingEnabled = true;
        emit Started();
    }

    /// @notice End the pool (after the lock up period)
    /// @param _amount Principal amount
    function end(uint _amount) external onlyOwner {
        require(block.timestamp > getEndDate(), "StablzCannavestPool: You cannot end before the end date");
        require(!hasEnded(), "StablzCannavestPool: Already ended");
        require(0 < _amount && _amount <= totalSupply(), "StablzCannavestPool: _amount must be greater than zero and less than or equal to the total staked");
        isDepositingEnabled = false;
        finalAmount = _amount;
        /// @dev totalSupply is user balances + OTC
        finalSupply = totalSupply();
        usdt.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Ended(finalAmount, finalSupply);
    }

    /// @notice Update the real world asset handler address
    /// @param _rwaHandler Real world asset handler
    function updateRealWorldAssetHandler(address _rwaHandler) external onlyOwner {
        require(_rwaHandler != address(0), "StablzCannavestPool: _rwaHandler cannot be the zero address");
        rwaHandler = _rwaHandler;
        emit RealWorldAssetHandlerUpdated(_rwaHandler);
    }

    /// @notice Enable depositing
    function enableDepositing() external onlyOwner {
        require(startedAt > 0, "StablzCannavestPool: Pool not started yet");
        require(_isPoolActive(), "StablzCannavestPool: Pool has already stopped");
        require(!isDepositingEnabled, "StablzCannavestPool: Depositing is already enabled");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    /// @notice Disable depositing
    function disableDepositing() external onlyOwner {
        require(isDepositingEnabled, "StablzCannavestPool: Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    /// @notice Deposit USDT and receive STABLZ-CANNAVEST
    /// @param _amount USDT to deposit
    function deposit(uint _amount) external nonReentrant {
        require(_isPoolActive(), "StablzCannavestPool: Depositing is not allowed because the pool has ended");
        require(isDepositingEnabled, "StablzCannavestPool: Depositing is not allowed at this time");
        require(ONE_USDT <= _amount, "StablzCannavestPool: _amount must be greater than or equal to 1 USDT");
        require(_amount <= usdt.balanceOf(_msgSender()), "StablzCannavestPool: Insufficient USDT balance");
        require(_amount <= usdt.allowance(_msgSender(), address(this)), "StablzCannavestPool: Insufficient USDT allowance");
        require(totalSupply() + _amount <= MAX_AMOUNT, "StablzCannavestPool: Max amount reached");
        _mint(_msgSender(), _amount);
        usdt.safeTransferFrom(_msgSender(), rwaHandler, _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /// @notice Withdraw USDT after lockup and give back STABLZ-CANNAVEST
    function withdraw() external nonReentrant {
        require(hasEnded(), "StablzCannavestPool: You can only withdraw once the pool has ended");
        uint balance = balanceOf(_msgSender());
        uint otc = _getUserAmountListed(_msgSender());
        require(0 < balance + otc, "StablzCannavestPool: Receipt balance must be greater than zero");
        uint amount = _calculateFinalAmount(_msgSender());
        if (0 < balance) {
            _burn(_msgSender(), balance);
        }
        if (0 < otc) {
            _clearUserAmountListed(_msgSender());
            _burn(address(this), otc);
        }
        usdt.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), balance, amount);
    }

    /// @notice Claim USDT rewards
    function claimRewards() external nonReentrant {
        _mergeRewards(_msgSender());
        uint held = _getHeldRewards(_msgSender());
        require(0 < held, "StablzCannavestPool: No rewards available to claim");
        _rewards[_msgSender()].held = 0;
        allTimeRewardsClaimed += held;
        usdt.safeTransfer(_msgSender(), held);
        emit Claimed(_msgSender(), held);
    }

    /// @notice Distribute USDT to receipt token holders (RWA handler only)
    /// @param _amount Amount of USDT to distribute
    function distribute(uint _amount) external onlyRWAHandler {
        /// @dev checks !hasEnded() and not block.timestamp <= getEndDate() in case the final distribution occurs slightly after 1 year
        require(!hasEnded(), "StablzCannavestPool: Distributions are disabled because the pool has ended");
        uint circulatingSupply = _getCirculatingSupply();
        require(ONE_USDT <= circulatingSupply, "StablzCannavestPool: Total staked must be greater than 1 receipt token");
        require(ONE_USDT <= _amount, "StablzCannavestPool: _amount must be greater than or equal to 1 USDT");
        require(_amount <= usdt.balanceOf(rwaHandler), "StablzCannavestPool: Insufficient balance");
        require(_amount <= usdt.allowance(rwaHandler, address(this)), "StablzCannavestPool: Insufficient allowance");
        allTimeCirculatingSupplyAtDistribution += circulatingSupply;
        allTimeRewards += _amount;
        currentRewardFactor += REWARD_FACTOR_ACCURACY * _amount / circulatingSupply;
        usdt.safeTransferFrom(rwaHandler, address(this), _amount);
        emit Distributed(_amount, circulatingSupply);
    }

    /// @notice Get the end date
    /// @return uint End date
    function getEndDate() public view returns (uint) {
        require(startedAt > 0, "StablzCannavestPool: Pool has not started yet");
        return startedAt + LOCK_UP_PERIOD;
    }

    /// @notice Get the current rewards for a user
    /// @param _user User address
    /// @return uint Current rewards for _user
    function getReward(address _user) external view returns (uint) {
        require(_user != address(0), "StablzCannavestPool: _user cannot equal the zero address");
        return _getHeldRewards(_user) + _getCalculatedRewards(_user);
    }

    /// @notice Calculate the final amount to withdraw
    /// @param _user User address
    /// @return uint Final amount to withdraw for _user
    function calculateFinalAmount(address _user) external view returns (uint) {
        require(hasEnded(), "StablzCannavestPool: The pool has not ended yet");
        require(_user != address(0), "StablzCannavestPool: _user cannot equal the zero address");
        return _calculateFinalAmount(_user);
    }

    /// @notice Has the pool ended
    /// @return bool true - ended, false - not ended
    function hasEnded() public view returns (bool) {
        return finalAmount > 0;
    }

    /// @inheritdoc ERC20
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint _amount
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        require(0 < _amount, "StablzCannavestPool: _amount must be greater than zero");
        require(
            /// @dev mint
            _from == address(0) ||
            /// @dev delist or purchase
            _from == address(this) ||
            /// @dev burn
            _to == address(0) ||
            /// @dev list
            (_to == address(this) && _inbound),
            "StablzCannavestPool: Receipt token is only transferrable via OTC, depositing, and withdrawing"
        );
        if (_from != address(0) && _from != address(this)) {
            _mergeRewards(_from);
        }
        if (_to != address(0) && _to != address(this)) {
            _mergeRewards(_to);
        }
    }

    /// @param _user User address
    /// @return uint Final amount to withdraw for _user
    function _calculateFinalAmount(address _user) private view returns (uint) {
        return finalAmount * _getTotalBalance(_user) / finalSupply;
    }

    /// @param _user User address
    /// @return uint Balance of _user + OTC amount listed by _user
    function _getTotalBalance(address _user) private view returns (uint) {
        return balanceOf(_user) + _getUserAmountListed(_user);
    }

    /// @dev get the total amount staked (not including otc listings)
    /// @return uint Circulating supply
    function _getCirculatingSupply() private view returns (uint) {
        return totalSupply() - totalAmountListed;
    }

    /// @dev Merge calculated rewards with held rewards
    /// @param _user User address
    function _mergeRewards(address _user) private {
        /// @dev move calculated rewards into held rewards
        _holdCalculatedRewards(_user);
        /// @dev clear calculated rewards
        _rewards[_user].factor = currentRewardFactor;
    }

    /// @dev Convert calculated rewards into held rewards
    /// @dev Used when the user carries out an action that would cause their calculated rewards to change
    function _holdCalculatedRewards(address _user) private {
        uint calculatedReward = _getCalculatedRewards(_user);
        if (calculatedReward > 0) {
            _rewards[_user].held += calculatedReward;
        }
    }

    /// @param _user User address
    /// @return uint Held rewards
    function _getHeldRewards(address _user) private view returns (uint) {
        return _rewards[_user].held;
    }

    /// @param _user User address
    /// @return uint Calculated rewards
    function _getCalculatedRewards(address _user) private view returns (uint) {
        uint balance = balanceOf(_user);
        return balance * (currentRewardFactor - _rewards[_user].factor) / REWARD_FACTOR_ACCURACY;
    }

    /// @return bool true - active, false - not active
    function _isPoolActive() internal view override returns (bool) {
        /// @dev checks !hasEnded() too because block.timestamp can vary
        return block.timestamp <= getEndDate() && !hasEnded();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Real world asset receipt token
abstract contract RealWorldAssetReceipt is ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    IERC20 public immutable receipt;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint public totalAmountListed;
    uint public totalListings;
    uint public totalDelisted;
    bool internal _inbound;

    struct User {
        uint amountListed;
        uint[] listingIds;
        uint[] purchasedIds;
    }

    struct Listing {
        uint listingId;
        address seller;
        address buyer;
        uint listedAt;
        uint purchasedAt;
        uint delistedAt;
        uint amount;
        uint cost;
    }

    mapping(address => User) public _users;
    mapping(uint => Listing) public _listings;

    event Listed(address indexed seller, uint indexed listingId, uint amount, uint cost);
    event Delisted(address indexed seller, uint indexed listingId);
    event PriceChanged(uint indexed oldListingId, uint indexed newListingId, uint newCost);
    event Purchased(address indexed buyer, uint indexed listingId);

    /// @param _listingId Listing ID
    modifier onlyActiveListing(uint _listingId) {
        require(_listingId < totalListings, "RealWorldAssetReceipt: Listing does not exist");
        require(_listings[_listingId].purchasedAt == 0, "RealWorldAssetReceipt: Listing has already been purchased");
        require(_listings[_listingId].delistedAt == 0, "RealWorldAssetReceipt: Listing has already been delisted");
        _;
    }

    modifier onlyActivePool() {
        require(_isPoolActive(), "RealWorldAssetReceipt: OTC has closed");
        _;
    }

    /// @param _name Receipt token name
    /// @param _symbol Receipt token symbol
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        usdt = IERC20(USDT);
        receipt = IERC20(address(this));
    }

    /// @inheritdoc ERC20
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice List a RWA receipt tokens
    /// @param _amount Amount of RWA receipt tokens to list
    /// @param _cost Cost of _amount in USDT
    function list(uint _amount, uint _cost) external nonReentrant onlyActivePool {
        require(_amount <= balanceOf(_msgSender()), "RealWorldAssetReceipt: Insufficient balance");
        require(_amount <= allowance(_msgSender(), address(this)), "RealWorldAssetReceipt: Insufficient allowance");
        uint listingId = _list(_amount, _cost);
        totalAmountListed += _amount;
        _inbound = true;
        receipt.safeTransferFrom(_msgSender(), address(this), _amount);
        _inbound = false;
        emit Listed(_msgSender(), listingId, _amount, _cost);
    }

    /// @notice Delist your listing. If the pool has ended you don't need to delist because the pool with automatically handle it for you
    /// @param _listingId Listing ID
    function delist(uint _listingId) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        uint amount = _delist(_listingId);
        totalAmountListed -= amount;
        receipt.safeTransfer(_msgSender(), amount);
        emit Delisted(_msgSender(), _listingId);
    }

    /// @notice Change price of a listing (delists then relists)
    /// @param _listingId Listing ID
    /// @param _newCost New cost of the listing in USDT
    function changePrice(uint _listingId, uint _newCost) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        require(0 < _newCost, "RealWorldAssetReceipt: _cost must be greater than 0");
        /// @dev Delists then relists otherwise when purchasing a user could be frontrun if they approved max
        uint amount = _delist(_listingId);
        uint newListingId = _list(amount, _newCost);
        emit PriceChanged(_listingId, newListingId, _newCost);
    }

    /// @notice Purchase a listing
    /// @param _listingId Listing ID
    function purchase(uint _listingId) external nonReentrant onlyActiveListing(_listingId) onlyActivePool {
        Listing storage listing = _listings[_listingId];
        require(listing.seller != _msgSender(), "RealWorldAssetReceipt: You cannot purchase your own listing");
        require(listing.cost <= usdt.balanceOf(_msgSender()), "RealWorldAssetReceipt: Insufficient USDT balance");
        require(listing.cost <= usdt.allowance(_msgSender(), address(this)), "RealWorldAssetReceipt: Insufficient USDT allowance");
        listing.purchasedAt = block.timestamp;
        listing.buyer = _msgSender();
        _users[_msgSender()].purchasedIds.push(_listingId);
        _users[listing.seller].amountListed -= listing.amount;
        totalAmountListed -= listing.amount;
        usdt.safeTransferFrom(_msgSender(), listing.seller, listing.cost);
        receipt.safeTransfer(_msgSender(), listing.amount);
        emit Purchased(_msgSender(), _listingId);
    }

    /// @notice Get the amount listed by a user
    /// @param _user User address
    /// @return Amount listed by _user
    function getUserAmountListed(address _user) external view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _getUserAmountListed(_user);
    }

    /// @notice Get the total number of listings by a user
    /// @param _user User address
    /// @return Total listings by _user
    function getUserTotalListings(address _user) public view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _users[_user].listingIds.length;
    }

    /// @notice Get the total purchases by a user
    /// @param _user User address
    /// @return Total purchases by _user
    function getUserTotalPurchases(address _user) public view returns (uint) {
        require(_user != address(0), "RealWorldAssetReceipt: _user cannot equal the zero address");
        return _users[_user].purchasedIds.length;
    }

    /// @notice Get listings
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getListings(uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        _validateIndexes(_startIndex, _endIndex, totalListings);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[index];
            listIndex++;
        }
        return listings;
    }

    /// @notice Get user listings
    /// @param _user User address
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getUserListings(address _user, uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        uint total = getUserTotalListings(_user);
        _validateIndexes(_startIndex, _endIndex, total);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[_users[_user].listingIds[index]];
            listIndex++;
        }
        return listings;
    }

    /// @notice Get user purchases
    /// @param _user User address
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return listings Listings
    function getUserPurchases(address _user, uint _startIndex, uint _endIndex) external view returns (Listing[] memory listings) {
        uint total = getUserTotalPurchases(_user);
        _validateIndexes(_startIndex, _endIndex, total);
        listings = new Listing[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint index = _startIndex; index <= _endIndex; index++) {
            listings[listIndex] = _listings[_users[_user].purchasedIds[index]];
            listIndex++;
        }
        return listings;
    }

    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @param _total Total
    function _validateIndexes(uint _startIndex, uint _endIndex, uint _total) private pure {
        require(_startIndex <= _endIndex, "RealWorldAssetReceipt: Start index must be less than or equal to end index");
        require(_startIndex < _total, "RealWorldAssetReceipt: Invalid start index");
        require(_endIndex < _total, "RealWorldAssetReceipt: Invalid end index");
    }

    /// @param _user User address
    /// @return uint Amount listed by _user
    function _getUserAmountListed(address _user) internal view returns (uint) {
        return _users[_user].amountListed;
    }

    /// @dev Used when withdrawing
    /// @param _user User address
    function _clearUserAmountListed(address _user) internal {
        _users[_user].amountListed = 0;
    }

    /// @return bool Is pool active
    function _isPoolActive() internal view virtual returns (bool);

    /// @param _amount Amount of RWA receipt tokens to list
    /// @param _cost Cost of _amount in USDT
    /// @return uint Listing ID
    function _list(uint _amount, uint _cost) private returns (uint) {
        require(0 < _amount, "RealWorldAssetReceipt: _amount must be greater than 0");
        require(0 < _cost, "RealWorldAssetReceipt: _cost must be greater than 0");
        User storage user = _users[_msgSender()];
        uint listingId = totalListings;
        _listings[listingId] = Listing(listingId, _msgSender(), address(0), block.timestamp, 0, 0, _amount, _cost);
        user.amountListed += _amount;
        user.listingIds.push(listingId);
        totalListings++;
        return listingId;
    }

    /// @param _listingId Listing ID
    /// @return uint Amount of RWA receipt tokens associated with _listingId
    function _delist(uint _listingId) private returns (uint) {
        Listing storage listing = _listings[_listingId];
        require(listing.seller == _msgSender(), "RealWorldAssetReceipt: Only the seller can delist their listing");
        listing.delistedAt = block.timestamp;
        User storage user = _users[_msgSender()];
        user.amountListed -= listing.amount;
        totalDelisted++;
        return listing.amount;
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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