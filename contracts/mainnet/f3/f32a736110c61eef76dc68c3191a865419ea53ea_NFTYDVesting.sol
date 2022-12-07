/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: NFTYDVesting.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;





contract NFTYDVesting is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _grantIds;
    uint256 private constant GENESIS_TIMESTAMP = 1654041600; // June 1, 2022 00:00:00 UTC (arbitrary date/time for timestamp validatio
    address private treasuryAddress; // Treasury address for vesting
    IERC20 public tokenContract; //NFTYD token contract

    struct VestingGrant {
        uint256 grantId; //Unique GrantID for every issued grant
        bool isGranted; // Flag to indicate grant was issued
        address issuer; // Account that issued grant
        address beneficiary; // Beneficiary of grant
        uint256 grantDreams; // Number of dreams granted
        uint256 startTimestamp; // Start date/time of vesting
        uint256 cliffTimestamp; // Cliff date/time for vesting
        uint256 endTimestamp; // End date/time of vesting
        bool isRevocable; // Whether issuer can revoke and reclaim dreams
        bool isLockedGrant; // True for timelock and False for regular grants
        uint256 releasedDreams; // Number of dreams already released
    }

    mapping(address => uint256[]) public AccountGrants; // GrantIDs associated with the address
    mapping(uint256 => VestingGrant) public VestingGrants; // Grant ID to grant mapping
    mapping(address => bool) public authorizedAddresses; // Token grants subject to vesting

    /* Vesting Events */
    event Grant(
        // Fired when an account grants tokens to another account on a vesting schedule
        address indexed owner,
        address indexed beneficiary,
        uint256 value
    );

    event Timelock(
        // Fired when an account grants tokens to another account on a timelock schedule
        address indexed owner,
        address indexed beneficiary,
        uint256 value
    );

    event Revoke(
        // Fired when an account revokes previously granted unvested tokens to another account
        address indexed owner,
        address indexed beneficiary,
        uint256 value
    );

    /**
     * @dev Constructor
     *
     * @param  _tokenContract Address of the NFTYD token contract
     */
    constructor(address payable _tokenContract, address payable _treasury) {
        treasuryAddress = _treasury;
        tokenContract = IERC20(_tokenContract);
        authorizedAddresses[msg.sender] = true;
    }

    /**
     * @dev Authorizes a smart contract to call this contract
     *
     * @param account Address of the calling smart contract
     */
    function setAuthorizeAddress(address account)
        external
        whenNotPaused
        onlyOwner
    {
        require(account != address(0), "Account must be a valid address");
        authorizedAddresses[account] = true;
    }

    /**
     * @dev Deauthorizes a previously authorized smart contract from calling this contract
     *
     * @param account Address of the calling smart contract
     */
    function deauthorizeAddress(address account)
        external
        whenNotPaused
        onlyOwner
    {
        require(account != address(0), "Account must be a valid address");
        authorizedAddresses[account] = false;
    }

    function setTreasuryAddress(address _treasury) public {
        require(authorizedAddresses[msg.sender], "Sender not authorized.");
        treasuryAddress = _treasury;
    }

    function setTokenContract(address _tokenAddress) public {
        require(authorizedAddresses[msg.sender], "Sender not authorized.");
        tokenContract = IERC20(_tokenAddress);
    }

    function grantBulk(
        address[] calldata beneficiary,
        uint256[] calldata dreams,
        uint256[] calldata startTimestamp,
        uint256[] calldata cliffSeconds,
        uint256[] calldata vestingSeconds,
        bool[] calldata revocable
    ) public whenNotPaused {
        require(authorizedAddresses[msg.sender], "Sender not authorized");
        for (uint256 i = 0; i < beneficiary.length; i++) {
            grant(
                beneficiary[i],
                dreams[i],
                startTimestamp[i],
                cliffSeconds[i],
                vestingSeconds[i],
                revocable[i]
            );
        }
    }

    function timelockBulk(
        address[] calldata beneficiary,
        uint256[] calldata dreams,
        uint256[] calldata startTimestamp,
        uint256[] calldata cliffSeconds,
        bool[] calldata revocable
    ) public whenNotPaused {
        require(authorizedAddresses[msg.sender], "Sender not authorized");
        for (uint256 i = 0; i < beneficiary.length; i++) {
            timelock(
                beneficiary[i],
                dreams[i],
                startTimestamp[i],
                cliffSeconds[i],
                revocable[i]
            );
        }
    }

    /**
     * @dev Grants a beneficiary dreams using a vesting schedule
     *
     * @param beneficiary The account to whom dreams are being granted
     * @param dreams dreams that are granted but not vested
     * @param startTimestamp Date/time when vesting begins
     * @param cliffSeconds Date/time prior to which tokens vest but cannot be released
     * @param vestingSeconds Vesting duration (also known as vesting term)
     * @param revocable Indicates whether the granting account is allowed to revoke the grant
     */

    function grant(
        address beneficiary,
        uint256 dreams,
        uint256 startTimestamp,
        uint256 cliffSeconds,
        uint256 vestingSeconds,
        bool revocable
    ) public whenNotPaused {
        require(authorizedAddresses[msg.sender], "Sender not authorized");
        require(beneficiary != address(0), "Account must be a valid address");
        uint256 dreamsAmount = dreams * 1e18;
        require(
            (dreamsAmount > 0 &&
                dreamsAmount <= tokenContract.balanceOf(treasuryAddress)),
            "Tokens must be greater than zero"
        ); // Dreams must be greater than zero and treasury has enough dreams
        require(startTimestamp >= GENESIS_TIMESTAMP, "Invalid startTimestamp"); // Just a way to prevent really old dates
        require(vestingSeconds > 0, "Duration must be greater than zero");
        require(cliffSeconds >= 0, "Cliff must be greater than zero");
        require(
            cliffSeconds < vestingSeconds,
            "Cliff must be lesser than vestingSeconds"
        );

        _grantIds.increment();
        AccountGrants[beneficiary].push(_grantIds.current());

        createGrant(
            _grantIds.current(),
            beneficiary,
            dreamsAmount,
            startTimestamp,
            cliffSeconds,
            vestingSeconds,
            revocable,
            false // Vesting grant is always false
        );

        tokenContract.transferFrom(
            treasuryAddress,
            address(this),
            dreamsAmount
        );

        emit Grant(msg.sender, beneficiary, dreamsAmount); // Fire event
    }

    function timelock(
        address beneficiary,
        uint256 dreams,
        uint256 startTimestamp,
        uint256 cliffSeconds,
        bool revocable
    ) public whenNotPaused {
        require(authorizedAddresses[msg.sender], "Sender not authorized");
        require(beneficiary != address(0), "Account must be a valid address");
        uint256 dreamsAmount = dreams * 1e18;
        require(
            (dreamsAmount > 0 &&
                dreamsAmount <= tokenContract.balanceOf(treasuryAddress)),
            "Tokens must be greater than zero"
        ); // Dreams must be greater than zero and treasury has enough dreams
        require(startTimestamp >= GENESIS_TIMESTAMP, "Invalid startTimestamp"); // Just a way to prevent really old dates
        require(cliffSeconds >= 0, "Cliff must be greater than zero");

        _grantIds.increment();
        AccountGrants[beneficiary].push(_grantIds.current());

        createGrant(
            _grantIds.current(),
            beneficiary,
            dreamsAmount,
            startTimestamp,
            cliffSeconds,
            0, // Timelock grant has no Vesting Seconds
            revocable,
            true // Timelock grant is always true
        );

        tokenContract.transferFrom(
            treasuryAddress,
            address(this),
            dreamsAmount
        );

        emit Timelock(msg.sender, beneficiary, dreamsAmount); // Fire event
    }

    function createGrant(
        uint256 grantId,
        address beneficiary,
        uint256 dreams,
        uint256 startTimestamp,
        uint256 cliffSeconds,
        uint256 vestingSeconds,
        bool revocable,
        bool isLockedGrant
    ) internal {
        VestingGrant storage newGrant = VestingGrants[grantId];
        newGrant.grantId = grantId;
        newGrant.isGranted = true;
        newGrant.issuer = msg.sender;
        newGrant.beneficiary = beneficiary;
        newGrant.grantDreams = dreams;
        newGrant.startTimestamp = startTimestamp;
        newGrant.cliffTimestamp = startTimestamp + cliffSeconds;
        newGrant.endTimestamp = startTimestamp + cliffSeconds + vestingSeconds;
        newGrant.isRevocable = revocable;
        newGrant.isLockedGrant = isLockedGrant;
        newGrant.releasedDreams = 0;
    }

    /**
     * @dev Gets total grant balance for caller
     *
     */
    function getTotalGrantedDreamsOf(address account)
        external
        view
        returns (uint256 dreams)
    {
        uint256[] memory userGrantsIds = AccountGrants[account];
        for (uint256 i = 0; i < userGrantsIds.length; i++) {
            uint256 id = userGrantsIds[i];
            if (VestingGrants[id].isGranted) {
                dreams += VestingGrants[id].grantDreams;
            }
        }
    }

    /**
     * @dev Gets tokens claimed by the caller
     *
     */
    function getClaimedDreamsOf(address account)
        external
        view
        returns (uint256 dreams)
    {
        uint256[] memory userGrantsIds = AccountGrants[account];
        for (uint256 i = 0; i < userGrantsIds.length; i++) {
            uint256 id = userGrantsIds[i];
            dreams += VestingGrants[id].releasedDreams;
        }
    }

    /**
     * @dev Gets token balance currently under vesting/locked for caller
     *
     */
    function getLockedDreamsOf(address account)
        external
        view
        returns (uint256)
    {
        return (getCurrentGrantBalanceOf(account) -
            getUnclaimedDreams(account));
    }

    /**
     * @dev Gets current grant balance for an account (locked + unclaimed)
     *
     * The return value subtracts dreams that have previously
     * been released.
     *
     * @param account Account whose grant balance is returned
     *
     */
    function getCurrentGrantBalanceOf(address account)
        public
        view
        returns (uint256 grantBalance)
    {
        require(account != address(0), "Account must be a valid address");
        require(AccountGrants[account].length > 0, "Account must be granted");
        uint256[] memory userGrantsIds = AccountGrants[account];
        for (uint256 i = 0; i < userGrantsIds.length; i++) {
            uint256 id = userGrantsIds[i];
            if (VestingGrants[id].isGranted) {
                grantBalance += (VestingGrants[id].grantDreams -
                    (VestingGrants[id].releasedDreams));
            }
        }
    }

    function getAccountGrantsIds(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return AccountGrants[_account];
    }

    /**
     * @dev Gets tokens available to claim for caller
     *
     */
    function getUnclaimedDreams(address account)
        public
        view
        returns (uint256 dreams)
    {
        uint256[] memory userGrantsIds = AccountGrants[account];
        for (uint256 i = 0; i < userGrantsIds.length; i++) {
            uint256 id = userGrantsIds[i];
            if (VestingGrants[id].isGranted) {
                dreams += getReleasableDreamsForGrant(id);
            }
        }
    }

    /**
     * @dev Returns releasableDreams of an account
     *
     * @param id  Account whose releasable dreams will be calculated
     */

    function getReleasableDreamsForGrant(uint256 id)
        internal
        view
        returns (uint256 releasableDreams)
    {
        VestingGrant memory userGrant = VestingGrants[id];
        if (userGrant.cliffTimestamp > block.timestamp) {
            releasableDreams = 0;
        } else if (block.timestamp >= userGrant.endTimestamp) {
            releasableDreams =
                userGrant.grantDreams -
                (userGrant.releasedDreams);
        } else {
            // Calculate vesting rate per second
            uint256 duration = (userGrant.endTimestamp -
                (userGrant.cliffTimestamp));

            // Calculate how many dreams can be released
            uint256 secondsPassed = (block.timestamp -
                userGrant.cliffTimestamp);

            uint256 vestedDreams = ((userGrant.grantDreams * secondsPassed) /
                duration);
            releasableDreams = vestedDreams - (userGrant.releasedDreams);
        }
    }

    /**
     * @dev Releases dreams that have been vested for caller
     *
     */
    function release() external {
        releaseFor(msg.sender);
    }

    /**
     * @dev Releases dreams that have been vested for an account (Claim)
     *
     * @param account Account whose dreams will be released
     *
     */
    function releaseFor(address account) public {
        require(account != address(0), "Account must be a valid address");
        require(AccountGrants[account].length > 0, "Account must be granted");
        uint256[] memory userGrantsIds = AccountGrants[account];
        uint256 releasableDreams = 0;
        for (uint256 i = 0; i < userGrantsIds.length; i++) {
            uint256 id = userGrantsIds[i];
            if (VestingGrants[id].isGranted) {
                uint256 releasableDreamsForGrant = getReleasableDreamsForGrant(
                    id
                );

                if (releasableDreamsForGrant > 0) {
                    // Update the released dreams counter
                    VestingGrants[id].releasedDreams =
                        VestingGrants[id].releasedDreams +
                        (releasableDreamsForGrant);
                    releasableDreams += releasableDreamsForGrant;
                }
            }
        }
        if (releasableDreams > 0) {
            tokenContract.transfer(account, releasableDreams);
        }
    }

    /**
     * @dev Revokes previously issued vesting grant
     *
     * For a grant to be revoked, it must be revocable.
     * In addition, only the unreleased tokens can be revoked.
     *
     * @param grantId Account for which a prior grant will be revoked
     */
    function revoke(uint256 grantId) public whenNotPaused {
        require(VestingGrants[grantId].isGranted, "Tokens must be granted");
        require(VestingGrants[grantId].isRevocable, "Tokens must be revocable");
        require(authorizedAddresses[msg.sender], "Not an authorized address"); // Only the original issuer can revoke a grant

        // Set the isGranted flag to false to prevent any further
        // actions on this grant from ever occurring
        VestingGrants[grantId].isGranted = false;

        // Get the remaining balance of the grant
        uint256 balanceDreams = VestingGrants[grantId].grantDreams -
            (VestingGrants[grantId].releasedDreams);

        // If there is any balance left, return it to the issuer
        if (balanceDreams > 0) {
            tokenContract.transfer(treasuryAddress, balanceDreams);
        }

        emit Revoke(
            VestingGrants[grantId].issuer,
            VestingGrants[grantId].beneficiary,
            balanceDreams
        );
    }

    function recoverETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(IERC20 erc20Contract) external onlyOwner {
        erc20Contract.transfer(
            msg.sender,
            erc20Contract.balanceOf(address(this))
        );
    }
}