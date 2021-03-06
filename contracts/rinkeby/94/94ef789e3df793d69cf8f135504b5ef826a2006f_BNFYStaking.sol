/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-10
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.10;


contract Ownable is Context {

    address payable public owner;

    event TransferredOwnership(address _previous, address _next, uint256 _time);
    event AddedPlatformAddress(address _platformAddress, uint256 _time);
    event RemovedPlatformAddress(address _platformAddress, uint256 _time);

    modifier onlyOwner() {
        require(_msgSender() == owner, "Owner only");
        _;
    }

    modifier onlyPlatform() {
        require(platformAddress[_msgSender()] == true, "Only Platform");
        _;
    }

    mapping(address => bool) platformAddress;

    constructor() public {
        owner = _msgSender();
    }

    // Function to transfer ownership
    function transferOwnership(address payable _owner) public onlyOwner() {
        address previousOwner = owner;
        owner = _owner;
        emit TransferredOwnership(previousOwner, owner, now);
    }

    // Function to add platform address
    function addPlatformAddress(address _platformAddress) public onlyOwner() {
        require(platformAddress[_platformAddress] == false, "already platform address");
        platformAddress[_platformAddress] = true;

        emit AddedPlatformAddress(_platformAddress, now);
    }

    // Function to remove platform address
    function removePlatformAddress(address _platformAddress) public onlyOwner() {
        require(platformAddress[_platformAddress] == true, "not platform address");
        platformAddress[_platformAddress] = false;

        emit RemovedPlatformAddress(_platformAddress, now);
    }
}

// File: contracts/BNFYStaking.sol



pragma solidity ^0.6.10;





interface IBNFYStakingNFT {
    function nftTokenId(address _stakeholder) external view returns(uint id);
    function revertNftTokenId(address _stakeholder, uint _tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract BNFYStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public safeguard;
    struct NFT {
        address _addressOfMinter;
        uint _BNFYDeposited;
        bool _inCirculation;
        uint _rewardDebt;
    }

    event StakeCompleted(address _staker, uint _amount, uint _tokenId, uint _totalStaked, uint _time);
    event WithdrawCompleted(address _staker, uint _amount, uint _tokenId, uint _time);
    event PoolUpdated(uint _blocksRewarded, uint _amountRewarded, uint _time);
    event RewardsClaimed(address _staker, uint _rewardsClaimed, uint _tokenId, uint _time);
    event RewardsCompounded(address _staker, uint _rewardsCompounded, uint _tokenId, uint _totalStaked, uint _time);
    event MintedToken(address _staker, uint256 _tokenId, uint256 _time);

    event TotalUnstaked(uint _total);

    IERC20 public BNFYToken;
    IBNFYStakingNFT public StakingNFT;
    address public rewardPool;
    address public staking;
    uint public dailyReward;
    uint public accBNfyPerShare;
    uint public lastRewardBlock;
    uint public totalStaked;

    mapping(uint => NFT) public NFTDetails;

    // Constructor will set the address of BNFY token and address of BNFY staking NFT
    constructor(address _BNFYToken, address _StakingNFT, address _staking, address _rewardPool, uint _dailyReward) Ownable() public {
        BNFYToken = IERC20(_BNFYToken);
        StakingNFT = IBNFYStakingNFT(_StakingNFT);
        staking = _staking;
        rewardPool = _rewardPool;

        // Apr-05-2021 06:00:00 PM +UTC
        lastRewardBlock = 6308868;

        setDailyReward(_dailyReward);
        accBNfyPerShare;
    }

    // 28800 blocks in average day --- decimals * BNFY balance of rewardPool / blocks / 10000 * dailyReward (in hundredths of %) = rewardPerBlock
    function getRewardPerBlock() public view returns(uint) {
        return BNFYToken.balanceOf(rewardPool).mul(dailyReward).div(28800).div(10000);
    }

    // % of reward pool to be distributed each day --- in hundredths of % 30 == 0.3%
    function setDailyReward(uint _dailyReward) public onlyOwner {
        dailyReward = _dailyReward;
    }

    // Function that will get balance of a BNFY balance of a certain stake
    function getNFTBalance(uint _tokenId) public view returns(uint _amountStaked) {
        return NFTDetails[_tokenId]._BNFYDeposited;
    }

    // Function that will check if a BNFY stake NFT is in circulation
    function checkIfNFTInCirculation(uint _tokenId) public view returns(bool _inCirculation) {
        return NFTDetails[_tokenId]._inCirculation;
    }

    // Function that returns NFT's pending rewards
    function pendingRewards(uint _NFT) public view returns(uint) {
        NFT storage nft = NFTDetails[_NFT];

        uint256 _accBNfyPerShare = accBNfyPerShare;

        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 blocksToReward = block.number.sub(lastRewardBlock);
            uint256 bnfyReward = blocksToReward.mul(getRewardPerBlock());
            _accBNfyPerShare = _accBNfyPerShare.add(bnfyReward.mul(1e18).div(totalStaked));
        }

        return nft._BNFYDeposited.mul(_accBNfyPerShare).div(1e18).sub(nft._rewardDebt);
    }

    // Get total rewards for all of user's BNFY nfts
    function getTotalRewards(address _address) public view returns(uint) {
        uint totalRewards;

        for(uint i = 0; i < StakingNFT.balanceOf(_address); i++) {
            uint _rewardPerNFT = pendingRewards(StakingNFT.tokenOfOwnerByIndex(_address, i));
            totalRewards = totalRewards.add(_rewardPerNFT);
        }

        return totalRewards;
    }

    // Get total stake for all user's BNFY nfts
    function getTotalBalance(address _address) public view returns(uint) {
        uint totalBalance;

        for(uint i = 0; i < StakingNFT.balanceOf(_address); i++) {
            uint _balancePerNFT = getNFTBalance(StakingNFT.tokenOfOwnerByIndex(_address, i));
            totalBalance = totalBalance.add(_balancePerNFT);
        }

        return totalBalance;
    }

    // Function that updates BNFY pool
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 blocksToReward = block.number.sub(lastRewardBlock);

        uint256 bnfyReward = blocksToReward.mul(getRewardPerBlock());

        //Approve bnfyReward here
        BNFYToken.transferFrom(rewardPool, address(this), bnfyReward);

        accBNfyPerShare = accBNfyPerShare.add(bnfyReward.mul(1e18).div(totalStaked));
        lastRewardBlock = block.number;

        emit PoolUpdated(blocksToReward, bnfyReward, now);
    }

    // Function that lets user stake BNFY
    function stakeBNFY(uint _amount) public {
        require(!safeguard);
        require(_amount > 0, "Can not stake 0 BNFY");
        require(BNFYToken.balanceOf(_msgSender()) >= _amount, "Do not have enough BNFY to stake");

        updatePool();

        if(StakingNFT.nftTokenId(_msgSender()) == 0){
             addStakeholder(_msgSender());
        }

        NFT storage nft = NFTDetails[StakingNFT.nftTokenId(_msgSender())];

        if(nft._BNFYDeposited > 0) {
            uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);

            if(_pendingRewards > 0) {
                BNFYToken.transfer(_msgSender(), _pendingRewards);
                emit RewardsClaimed(_msgSender(), _pendingRewards, StakingNFT.nftTokenId(_msgSender()), now);
            }
        }

        BNFYToken.transferFrom(_msgSender(), address(this), _amount);
        nft._BNFYDeposited = nft._BNFYDeposited.add(_amount);
        totalStaked = totalStaked.add(_amount);

        nft._rewardDebt = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18);

        emit StakeCompleted(_msgSender(), _amount, StakingNFT.nftTokenId(_msgSender()), nft._BNFYDeposited, now);

    }

    function addStakeholder(address _stakeholder) private {
        require(!safeguard);
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("mint(address)", _stakeholder));
        require(success == true, "Mint call failed");
        NFTDetails[StakingNFT.nftTokenId(_msgSender())]._addressOfMinter = _stakeholder;
        NFTDetails[StakingNFT.nftTokenId(_msgSender())]._inCirculation = true;
    }

    function addStakeholderExternal(address _stakeholder) external onlyPlatform() {
        require(!safeguard);
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("mint(address)", _stakeholder));
        require(success == true, "Mint call failed");
        NFTDetails[StakingNFT.nftTokenId(_stakeholder)]._addressOfMinter = _stakeholder;
        NFTDetails[StakingNFT.nftTokenId(_stakeholder)]._inCirculation = true;
    }

    // Function that will allow user to claim rewards
    function claimRewards(uint _tokenId) public {
        require(!safeguard);
        require(StakingNFT.ownerOf(_tokenId) == _msgSender(), "User is not owner of token");
        require(NFTDetails[_tokenId]._inCirculation == true, "Stake has already been withdrawn");

        updatePool();

        NFT storage nft = NFTDetails[_tokenId];

        uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);
        require(_pendingRewards > 0, "No rewards to claim!");

        BNFYToken.transfer(_msgSender(), _pendingRewards);

        nft._rewardDebt = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18);

        emit RewardsClaimed(_msgSender(), _pendingRewards, _tokenId, now);
    }

    // Function that will add BNFY rewards to BNFY staking NFT
    function compoundRewards(uint _tokenId) public {
        require(!safeguard);
        require(StakingNFT.ownerOf(_tokenId) == _msgSender(), "User is not owner of token");
        require(NFTDetails[_tokenId]._inCirculation == true, "Stake has already been withdrawn");

        updatePool();

        NFT storage nft = NFTDetails[_tokenId];

        uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);
        require(_pendingRewards > 0, "No rewards to compound!");

        nft._BNFYDeposited = nft._BNFYDeposited.add(_pendingRewards);
        totalStaked = totalStaked.add(_pendingRewards);

        nft._rewardDebt = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18);

        emit RewardsCompounded(_msgSender(), _pendingRewards, _tokenId, nft._BNFYDeposited, now);
    }

    // Function that lets user claim all rewards from all their nfts
    function claimAllRewards() public {
        require(!safeguard);
        require(StakingNFT.balanceOf(_msgSender()) > 0, "User has no stake");
        for(uint i = 0; i < StakingNFT.balanceOf(_msgSender()); i++) {
            uint _currentNFT = StakingNFT.tokenOfOwnerByIndex(_msgSender(), i);
            claimRewards(_currentNFT);
        }
    }

    // Function that lets user compound all rewards from all their nfts
    function compoundAllRewards() public {
        require(!safeguard);
        require(StakingNFT.balanceOf(_msgSender()) > 0, "User has no stake");
        for(uint i = 0; i < StakingNFT.balanceOf(_msgSender()); i++) {
            uint _currentNFT = StakingNFT.tokenOfOwnerByIndex(_msgSender(), i);
            compoundRewards(_currentNFT);
        }
    }

    // Function that lets user unstake BNFY in system. 5% fee that gets redistributed back to reward pool
    function unstakeBNFY(uint _tokenId) public {
        require(!safeguard);
        // Require that user is owner of token id
        require(StakingNFT.ownerOf(_tokenId) == _msgSender(), "User is not owner of token");
        require(NFTDetails[_tokenId]._inCirculation == true, "Stake has already been withdrawn");

        updatePool();

        NFT storage nft = NFTDetails[_tokenId];

        uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);

        uint amountStaked = getNFTBalance(_tokenId);
        uint stakeAfterFees = amountStaked.div(100).mul(95);
        uint userReceives = amountStaked.div(100).mul(95).add(_pendingRewards);

        uint fee = amountStaked.div(100).mul(5);

        uint beingWithdrawn = nft._BNFYDeposited;
        nft._BNFYDeposited = 0;
        nft._inCirculation = false;
        totalStaked = totalStaked.sub(beingWithdrawn);
        StakingNFT.revertNftTokenId(_msgSender(), _tokenId);

        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("burn(uint256)", _tokenId));
        require(success == true, "mint call failed");

        BNFYToken.transfer(_msgSender(), userReceives);
        BNFYToken.transfer(rewardPool, fee);

        emit WithdrawCompleted(_msgSender(), stakeAfterFees, _tokenId, now);
        emit RewardsClaimed(_msgSender(), _pendingRewards, _tokenId, now);
    }

    // Function that will unstake every user's BNFY stake NFT for user
    function unstakeAll() public {
        require(!safeguard);
        require(StakingNFT.balanceOf(_msgSender()) > 0, "User has no stake");

        while(StakingNFT.balanceOf(_msgSender()) > 0) {
            uint _currentNFT = StakingNFT.tokenOfOwnerByIndex(_msgSender(), 0);
            unstakeBNFY(_currentNFT);
        }

    }

    // Will increment value of staking NFT when trade occurs
    function incrementNFTValue (uint _tokenId, uint _amount) external onlyPlatform() {
        require(!safeguard);
        require(checkIfNFTInCirculation(_tokenId) == true, "Token not in circulation");
        updatePool();

        NFT storage nft = NFTDetails[_tokenId];

        if(nft._BNFYDeposited > 0) {
            uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);

            if(_pendingRewards > 0) {
                BNFYToken.transfer(StakingNFT.ownerOf(_tokenId), _pendingRewards);
                emit RewardsClaimed(StakingNFT.ownerOf(_tokenId), _pendingRewards, _tokenId, now);
            }
        }

        NFTDetails[_tokenId]._BNFYDeposited =  NFTDetails[_tokenId]._BNFYDeposited.add(_amount);

        nft._rewardDebt = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18);
    }

    // Will decrement value of staking NFT when trade occurs
    function decrementNFTValue (uint _tokenId, uint _amount) external onlyPlatform() {
        require(!safeguard);
        require(checkIfNFTInCirculation(_tokenId) == true, "Token not in circulation");
        require(getNFTBalance(_tokenId) >= _amount, "Not enough stake in NFT");

        updatePool();

        NFT storage nft = NFTDetails[_tokenId];

        if(nft._BNFYDeposited > 0) {
            uint _pendingRewards = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18).sub(nft._rewardDebt);

            if(_pendingRewards > 0) {
                BNFYToken.transfer(StakingNFT.ownerOf(_tokenId), _pendingRewards);
                emit RewardsClaimed(StakingNFT.ownerOf(_tokenId), _pendingRewards, _tokenId, now);
            }
        }

        NFTDetails[_tokenId]._BNFYDeposited =  NFTDetails[_tokenId]._BNFYDeposited.sub(_amount);

        nft._rewardDebt = nft._BNFYDeposited.mul(accBNfyPerShare).div(1e18);
    }
    
     function changeSafeguardStatus() onlyPlatform() public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }

}