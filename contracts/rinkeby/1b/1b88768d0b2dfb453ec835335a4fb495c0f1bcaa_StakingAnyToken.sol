/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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


// File contracts/StakingAnyToken/StakingAnyToken.sol

pragma solidity 0.8.9;
/**
 * @dev Staking Contract 
 *  - Stake any token and get Interest in XYZ
 *  - Number of days option for staking 
 *  - different token have different interest rate.  
 */
contract StakingAnyToken is Ownable, Pausable {

    uint32 public currentVersion;

    // minimum stake time in seconds, if the user can't be able to withdraws before this time
    uint256 public minimumStakeTime;

    // token award, AwardToken
    IERC20 public token;

    // the Stake
    struct Stake {
        // version of this stake
        uint32 version;
        // the staking token
        address token;
        // opening timestamp
        uint256 startTimestamp;
        // amount staked
        uint256 amount;
        // interest accrued, this will be available only after closing stake
        uint256 interest;
        // closing timestamp, if 0 then stake is still open
        uint256 finishedTimestamp;
        // the version on closing
        uint32 finishedVersion;
    }

    struct TokenAPY {
        // the lower bound of the token apy
        uint256 lowerBoundAmount;
        // Annual Percentage Yield. Interest(AwardToken) = stakedAmount(StakeToken) * (APY * 10^apyDecimals / stakedTime)
        uint32 apy;
    }

    struct StakeTokenInfo {
        bool hasAdded;
        bool enabled;
        // minimum amount of tokens to create a stake
        uint256 minimum;
        int8 apyDecimals;
        TokenAPY[] tokenAPYs;
    }

    // stakes that the owner have    
    mapping(address => Stake[]) public stakesOfOwner;
    
    // all accounts that have or have had stakes, this for the owner to be able to query stakes
    address[] private ownersAccounts;

    // all supported Stake Token Infos
    mapping(address => StakeTokenInfo) public supportedStakeTokenInfos;
    // all supported Stake Token addresses
    address[] public supportedStakeTokens;
    
    event ObsoleteVersion(uint32 version);
    event StakeCreated(address user, address token, uint256 amount, uint256 index);
    event Withdraw(address indexed user, uint256 index);
    event EmergencyWithdraw(address indexed user, uint256 index);
    event WithdrawObsoleteStaking(address indexed user, uint256 index);

    event StakeTokenInfoAdded(address token, uint256 minimum, int8 apyDecimals, TokenAPY[] tokenAPYs);
    event StakeTokenInfoChanged(address token, bool enable, uint256 minimum, int8 apyDecimals, TokenAPY[] tokenAPYs);

    // @param _token: the ERC20 token to be used
    // @param _minimumStakeTimeSeconds: minimum stake time in seconds
    // @param _minimum: minimum stake amount
    constructor(IERC20 _token, uint256 _minimumStakeTimeSeconds) {
        token = _token;
        minimumStakeTime = _minimumStakeTimeSeconds;
        currentVersion = 1;
    }
    
    function stakesOfOwnerLength(address _account) public view returns (uint256) {
        return stakesOfOwner[_account].length;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function modifyMinimumStakeTime(uint256 _newVal) external onlyOwner {
        minimumStakeTime = _newVal;
    }


    // give back all staking, user can withdraw all staking by calling withdrawObsoleteStake
    function obsoleteVersion() external onlyOwner {
        currentVersion += 1;
        emit ObsoleteVersion(currentVersion - 1);
    }


    // query all stake accounts holders
    function queryOwnersAccounts() external view returns (address[] memory) {
        return ownersAccounts;
    }

    // query all stake accounts holders length
    function ownersAccountsLength() external view returns (uint256) {
        return ownersAccounts.length;
    }

    // query all supported staking token length
    function supportedStakeTokensLength() public view returns (uint256) {
        return supportedStakeTokens.length;
    }

    // query supported staking token apy info length
    function stakeTokenApyLength(address _token) public view returns (uint256) {
        return supportedStakeTokenInfos[_token].tokenAPYs.length;
    }

    // query supported staking token apy info by index
    function stakeTokenAPY(address _token, uint256 _index) public view returns (TokenAPY memory) {
        require(_index < supportedStakeTokenInfos[_token].tokenAPYs.length, "Index is out of bounds");
        return supportedStakeTokenInfos[_token].tokenAPYs[_index];
    }

    // add a new stake token
    function addSupportedStakeToken(address _token, uint256 _minimum, int8 _apyDecimals, TokenAPY[] memory _tokenAPYs) external onlyOwner {
        require(!supportedStakeTokenInfos[_token].hasAdded, "Token already supported");
        supportedStakeTokens.push(_token);
        StakeTokenInfo storage info = supportedStakeTokenInfos[_token];
        info.hasAdded = true;
        info.enabled = true;
        info.minimum = _minimum;
        info.apyDecimals = _apyDecimals;

        for(uint256 i = 0; i < _tokenAPYs.length; i++) {
            supportedStakeTokenInfos[_token].tokenAPYs.push(TokenAPY(_tokenAPYs[i].lowerBoundAmount, _tokenAPYs[i].apy));
        }
        emit StakeTokenInfoAdded(_token, _minimum, _apyDecimals, _tokenAPYs);
    }

    // update the supported stake token info
    function updateSupportedStakeToken(address _token, bool _enabled, uint256 _minimum, int8 _apyDecimals, TokenAPY[] memory _tokenAPYs) external onlyOwner {
        StakeTokenInfo storage info = supportedStakeTokenInfos[_token];
        require(info.hasAdded, "Token not supported");
        info.enabled = _enabled;
        info.minimum = _minimum;
        info.apyDecimals = _apyDecimals;
        delete supportedStakeTokenInfos[_token].tokenAPYs;
        for(uint256 i = 0; i < _tokenAPYs.length; i++) {
            supportedStakeTokenInfos[_token].tokenAPYs.push(TokenAPY(_tokenAPYs[i].lowerBoundAmount, _tokenAPYs[i].apy));
        }
        emit StakeTokenInfoChanged(_token, true, _minimum, _apyDecimals, _tokenAPYs);
    }


    function isObsoleteStake(address _user, uint256 _index) public view returns (bool) {
        require(_index < stakesOfOwner[_user].length, "Index is out of bounds");
        return stakesOfOwner[_user][_index].version != currentVersion;
    }
    
    // anyone can create a stake
    function createStake(address stakeTokenAddress, uint256 amount) external whenNotPaused {
        StakeTokenInfo storage stakeTokenInfo = supportedStakeTokenInfos[stakeTokenAddress];
        require(stakeTokenInfo.enabled, "Stake token is not enabled");
        require(amount >= stakeTokenInfo.minimum, "The amount is too low");

        IERC20 stakeToken = IERC20(stakeTokenAddress);

        // store the tokens of the user in the contract
        // requires approve
        uint256 realAmount = stakeToken.balanceOf(address(this)); // we need to calculate real amount because of reflection
		stakeToken.transferFrom(msg.sender, address(this), amount);
        realAmount = stakeToken.balanceOf(address(this)) - realAmount; // realAmount is the final balance received

        // store the account of the staker in ownersAccounts if it doesnt exists
		if(stakesOfOwner[msg.sender].length == 0){
            ownersAccounts.push(msg.sender);
		}

        // create the stake
        stakesOfOwner[msg.sender].push(Stake(currentVersion, stakeTokenAddress, block.timestamp, realAmount, 0, 0, 0));
        emit StakeCreated(msg.sender, stakeTokenAddress, realAmount, stakesOfOwner[msg.sender].length - 1);
    }

    // withdraw obsoleted stakes
    // arrayIndex: is the id of the stake to be finalized
    function withdrawObsoleteStake(uint256 arrayIndex) external {

        // Stake should exists and opened
        require(arrayIndex < stakesOfOwner[msg.sender].length, "Stake does not exist");
        Stake storage stake = stakesOfOwner[msg.sender][arrayIndex];
        require(stake.finishedTimestamp == 0, "This stake is closed");
        require(stake.version != currentVersion, "This stake is not obsolete");

        IERC20 stakeToken = IERC20(stake.token);
        // transfer the amount from the contract itself
        stakeToken.transfer(msg.sender, stake.amount);
        // record the transaction
        stake.finishedTimestamp = block.timestamp;
        stake.finishedVersion = currentVersion;
        emit WithdrawObsoleteStaking(msg.sender, arrayIndex);
    }

    function calculateInterest(address _ownerAccount, uint256 inx, uint256 finishTimestamp) private view returns (uint256) {

        uint32 apy = 0;
        Stake storage stake = stakesOfOwner[_ownerAccount][inx];
        StakeTokenInfo storage stakeTokenInfo = supportedStakeTokenInfos[address(stake.token)];
        for (uint i=stakeTokenInfo.tokenAPYs.length - 1; i>=0; i--) {
            if (stake.amount >= stakeTokenInfo.tokenAPYs[i].lowerBoundAmount) {
                apy = stakeTokenInfo.tokenAPYs[i].apy;
                break;
            }
        }

        // APY per year = amount * APY * 10^apyDecimal / seconds of the year
        uint256 interestPerYear = stake.amount * apy;
        if (stakeTokenInfo.apyDecimals > 0) {
            interestPerYear = interestPerYear * 10 ** uint8(stakeTokenInfo.apyDecimals);
        } else if (stakeTokenInfo.apyDecimals < 0) {
            interestPerYear = interestPerYear / 10 ** uint8(-stakeTokenInfo.apyDecimals);
        }

        // number of seconds since opening date
        uint256 numSeconds = finishTimestamp - stake.startTimestamp;

        // calculate interest by a rule of three
        //  seconds of the year: 31536000 = 365*24*60*60
        //  interestPerYear   -   31536000
        //  interest            -   num_seconds
        //  interest = num_seconds * interestPerYear / 31536000
        return numSeconds * interestPerYear / 31536000;
    }

    // finalize the stake
    // arrayIndex: is the id of the stake to be finalized
    function withdrawStake(uint256 arrayIndex) external {
        // Stake should exists and opened
        require(arrayIndex < stakesOfOwner[msg.sender].length, "Stake does not exist");
        Stake storage stake = stakesOfOwner[msg.sender][arrayIndex];
        require(stake.finishedTimestamp == 0, "This stake is closed");
        require(stake.version == currentVersion, "This stake is obsolete");
        require(block.timestamp - stake.startTimestamp >= minimumStakeTime, "The stake is too short");
        IERC20 stakeToken = IERC20(stake.token);
        uint256 interest = calculateInterest(msg.sender, arrayIndex, block.timestamp);
        // record the transaction
        stake.finishedTimestamp = block.timestamp;
        stake.finishedVersion = currentVersion;
        stake.interest = interest;

        // transfer the interest amount from the contract owner
        stakeToken.transferFrom(owner(), msg.sender, interest);

        // transfer the amount from the contract itself
        token.transfer(msg.sender, stake.amount);
        emit Withdraw(msg.sender, arrayIndex);
    }

}