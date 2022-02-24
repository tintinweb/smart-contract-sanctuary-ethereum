/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/SwapStaking.sol


pragma solidity ^0.8.0;


contract ConvertAndStakingContract is Ownable{
    uint256 public fees;
    address public addressReceiveTokenSwap;
    mapping(address => mapping(address => uint256)) public listOfTokenConvertRatio;
    mapping(address => address) public listOfBankAccount;
    mapping(address => mapping(address => bool)) public listOfPauseTokens;



    /*PARAMS STAKING*/
    string public name = "Convert and Staking";
    uint256 profileId;
    uint256 packageId;
    uint256 public totalStaking;
    uint256 public totalClaimedStaking;
    uint256 public totalProfit;
    uint256 public totalClaimedProfit;

    struct Package {
        uint256 totalPercentProfit; // 5 = 5%
        uint256 vestingTime; // 1 = 1 month
        bool isActive; 
    }

    struct UserInfo {
        uint256 id;
        address user;
        uint256 amount; // How many tokens the user has provided.
        uint256 profitClaimed; // default false
        uint256 stakeClaimed; // default false
        uint256 vestingStart;
        uint256 vestingEnd;
        uint256 totalProfit;
        uint256 packageId;
        bool refunded;
        address stakeToken;
    }

    mapping(address => uint) public totalProfile;

    mapping(uint256 => uint256[]) public lockups;
    
    UserInfo[] public userInfo;

    address[] public stakers;
    mapping(uint => Package ) public packages;

    event Deposit(address by, uint256 amount);
    event ClaimProfit(address by, uint256 amount);
    event ClaimStaking(address by, uint256 amount);

    /*STAKING*/


    constructor(uint256 _fees, address _addressReceiveTokenSwap) {
        fees = _fees;
        addressReceiveTokenSwap = _addressReceiveTokenSwap;

        packages[1] = Package(6, 1, true);
        lockups[1] =  [5, 10, 15, 25, 35, 45, 60, 80, 100];

        packages[2] = Package(24, 2, true);
        lockups[2] =  [5, 10, 25, 40, 65, 100];

        packages[3] = Package(60, 3, true);
        lockups[3] =  [100];

        packageId = 4;
    }

    function setRates(address[] memory token0, address[] memory token1,uint256[] memory rates) public onlyOwner {
        require(token0.length == token1.length && token0.length == rates.length, "data does not match each other length");
        for(uint i = 0; i < rates.length; i++){
            listOfTokenConvertRatio[token0[i]][token1[i]] = rates[i];
        }
    }

    function setTokenBankAccounts(address[] memory tokens, address[] memory bankAddresses) public onlyOwner {
        require(tokens.length == bankAddresses.length, "data does not match each other length");
        for(uint i = 0; i < bankAddresses.length; i++){
            listOfBankAccount[tokens[i]] = bankAddresses[i];
        }
    }

    function setPauseTokens(address[] memory token0, address[] memory token1) public onlyOwner {
        require(token0.length == token1.length, "data does not match each other length");
        for(uint i = 0; i < token0.length; i++){
            listOfPauseTokens[token0[i]][token1[i]] = true;
        }
    }

    function cancelPauseTokens(address[] memory token0, address[] memory token1) public onlyOwner {
        require(token0.length == token1.length, "data does not match each other length");
        for(uint i = 0; i < token0.length; i++){
            listOfPauseTokens[token0[i]][token1[i]] = false;
        }
    }

    function setRate(address token0, address token1,uint256 rate) public onlyOwner {
        listOfTokenConvertRatio[token0][token1] = rate;
    }

    function setAddressReceiveTokenSwap(address receiveAddress) public onlyOwner {
        addressReceiveTokenSwap = receiveAddress;
    }

    function setTokenBankAccount(address token, address bankAddress) public onlyOwner {
        listOfBankAccount[token] = bankAddress;
    }

    function setPauseToken(address token0, address token1) public onlyOwner{
        listOfPauseTokens[token0][token1] = true;
    }

    function cancelPauseToken(address token0, address token1) public onlyOwner{
        listOfPauseTokens[token0][token1] = false;
    }

    function setFees(uint256 _Fees) public onlyOwner {
        fees = _Fees;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function swapToken0ToToken1(address token0, address token1, uint256 amountToken0, uint256 _packageId) public returns (uint256) {
        require(!listOfPauseTokens[token0][token1], "tokens is not enable to swap");
        require(listOfTokenConvertRatio[token0][token1] > 0,"rate of convert is not set yet");
        require(listOfBankAccount[token1] != address(0),"token bank is not set yet");
        require(amountToken0 > 0, "amountToken0 must be greater then zero");
        require(
            IERC20(token0).balanceOf(msg.sender) >= amountToken0,
            "sender doesn't have enough Tokens"
        );
        uint256 exchangeA = uint256(mul(amountToken0, listOfTokenConvertRatio[token0][token1]));
        uint256 exchangeAmount = exchangeA;
        if(fees > 0){
            exchangeAmount = exchangeAmount -
                uint256((mul(exchangeA, fees)) / 100);

            require(
                exchangeAmount > 0,
                "exchange Amount must be greater then zero"
            );
        }

        require(
            IERC20(token1).balanceOf(listOfBankAccount[token1]) > exchangeAmount,
            "currently the exchange doesnt have enough Token1, please retry later :=("
        );

        IERC20(token0).transferFrom(address(msg.sender), addressReceiveTokenSwap, amountToken0);
        IERC20(token1).transferFrom(listOfBankAccount[token1], address(this), exchangeAmount/1000);

        stake(exchangeAmount/1000, _packageId, token1);
        return exchangeAmount;
    }

    /*STAKING FUNCTION*/
    
    function stake(uint _amount, uint256 _packageId, address _stakeToken) public payable {
        // Validate amount
        require(_amount > 0, "Amount cannot be 0");
        require(packages[_packageId].totalPercentProfit > 0, "Invalid package id");
        require(packages[_packageId].isActive == true, "This package is not available");

        uint256 profit = _amount * packages[_packageId].totalPercentProfit / 100;

        UserInfo memory profile;
        profile.id = profileId;
        profile.packageId = _packageId;
        profile.user = msg.sender;
        profile.amount = _amount;
        profile.profitClaimed = 0;
        profile.stakeClaimed = 0;
        profile.vestingStart = block.timestamp;
        profile.vestingEnd = block.timestamp + packages[_packageId].vestingTime * 10 minutes;
        profile.refunded = false;
        profile.totalProfit = profit;
        profile.stakeToken = _stakeToken;
        userInfo.push(profile);

        // Update profile id
        profileId++;

        // Update total staking
        totalStaking += _amount;

        // Update total profit
        totalProfit += profit;

        emit Deposit(msg.sender, _amount);
    }

    // Add status package
    function addPackage(uint256 _totalPercentProfit, uint256 _vestingTime, uint256[] memory _lockups ) public onlyOwner {
        require(_totalPercentProfit > 0, "Profit can not be 0");
        require(_vestingTime > 0, "Vesting time can not be 0");
        packages[packageId] = Package(_totalPercentProfit, _vestingTime, true);
        lockups[packageId] = _lockups;
        packageId++;
    }

     // Update status package
    function setPackage(uint256 _packageId, bool _isActive) public onlyOwner {
        require(packages[_packageId].totalPercentProfit > 0, "Invalid package id");
        packages[_packageId].isActive = _isActive;
    }

    function getStakers() public view returns(address[] memory) {
        return stakers;
    }

    function getLockups(uint256 _packageId) public view returns(uint256[] memory) {
        return lockups[_packageId];
    }

    function getProfilesByAddress(address user) public view returns(UserInfo[] memory) {
        uint256 total = 0;
        for(uint i = 0; i < userInfo.length; i++){
            if (userInfo[i].user == user) {
               total++;
            }
        }

        require(total > 0, "Invalid profile address");

        UserInfo[] memory profiles = new UserInfo[](total);
        uint256 j;

        for(uint i = 0; i < userInfo.length; i++){
            if (userInfo[i].user == user) {
                profiles[j] = userInfo[i];  // step 3 - fill the array
                j++;
            }
        }

        return profiles;
    }

    function getProfilesLength() public view returns(uint256) {
        return userInfo.length;
    }

    function getCurrentProfit(uint256 _profileId) public view returns(uint256) {
        require(userInfo[_profileId].packageId != 0, 'Invalid profile');

        UserInfo memory info = userInfo[_profileId];

        if ( block.timestamp > info.vestingEnd) {
            return info.totalProfit;
        }

        uint256 profit = (( block.timestamp - info.vestingStart) * info.totalProfit) / (info.vestingEnd - info.vestingStart);
        return profit;
    }

    function claimProfit(uint256 _profileId) public {
        require(userInfo[_profileId].user == msg.sender, 'You are not onwer');
        UserInfo storage info = userInfo[_profileId];

        uint256 profit = getCurrentProfit(_profileId);
        uint256 remainProfit = profit - info.profitClaimed;

        require(remainProfit > 0, "No profit");
        IERC20(info.stakeToken).transfer(msg.sender, remainProfit);
        info.profitClaimed += remainProfit;

        // Update total profit claimed
        totalClaimedProfit += profit;

        emit ClaimProfit(msg.sender, remainProfit);
    }

    function getCurrentStakeUnlock(uint256 _profileId) public view returns(uint256) {
        require(userInfo[_profileId].packageId != 0, 'Invalid profile');

        UserInfo memory info = userInfo[_profileId];

        uint256[] memory pkgLockups = getLockups(info.packageId);

        if (block.timestamp < info.vestingEnd) {
            return 0;
        }

        // Not lockup, can withdraw 100% after vesting time
        if (pkgLockups.length == 1 && pkgLockups[0] == 100) {
            return info.amount;
        }

        uint256 length = pkgLockups.length;
        for(uint i = length - 1; i >= 0; i--){
            uint256 limitWithdrawTime = info.vestingEnd + (i + 1) * 10 minutes;
            if (block.timestamp > limitWithdrawTime) {
               return pkgLockups[i] * info.amount / 100;
            }
        }

        return 0;
    }

    function claimStaking(uint256 _profileId) public {
        require(userInfo[_profileId].user == msg.sender, 'You are not onwer');
        require(userInfo[_profileId].vestingEnd < block.timestamp, 'Can not claim before vesting end');

        UserInfo storage info = userInfo[_profileId];
        uint256 amountUnlock = getCurrentStakeUnlock(_profileId);

        uint256 remainAmount = amountUnlock - info.stakeClaimed;

        require(remainAmount > 0, "No staking");
        
        IERC20(info.stakeToken).transfer(msg.sender, remainAmount);

        info.stakeClaimed += remainAmount;

        // Update total staking
        totalClaimedStaking += remainAmount;

        emit ClaimStaking(msg.sender, remainAmount);
    }


}