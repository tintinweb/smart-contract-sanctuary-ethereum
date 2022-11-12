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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
pragma solidity ^0.8.0;

import "./utils/SafeBEP20.sol";
import "./utils/IBEP20.sol";

contract WKDCommit {
    // This contract alllows userrs to comit WKD in order to be able to participate in the WKD Launchpad
    using SafeBEP20 for IBEP20;

    IBEP20 public wkd;
    // Admin address
    address public admin;
    // Whether it is initialized
    bool public isInitialized;
    // Amount of WKD commited by users
    uint256 totalusersCommit;

    // Details of a user's commit
    mapping(address => uint256) public userCommit;
    // Custom error messages

    error NotPermitted();
    error NotInitialized();
    error InvalidAmount();

    event Commit(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Initialize(address indexed admin, address wkd);
    event removeWkdCommit(address indexed user, uint256 amount);

    constructor(address _admin) {
        admin = _admin;
    }

    function initialize(address _wkd) external {
        if (msg.sender != admin) revert NotPermitted();
        if (isInitialized) revert NotInitialized();
        wkd = IBEP20(_wkd);
        isInitialized = true;
        emit Initialize(admin, _wkd);
    }

    function commitWkd(uint256 _amount) public {
        if (!isInitialized) revert NotInitialized();
        if (_amount == 0) revert InvalidAmount();
        userCommit[msg.sender] += _amount;
        totalusersCommit += _amount;
        wkd.transferFrom(msg.sender, address(this), _amount);
        emit Commit(msg.sender, _amount);
    }

    function removeWkd(uint256 _amount) public {
        require(isInitialized, "WKDCommit: Contract not initialized");
        require(_amount > 0, "WKDCommit: Amount must be greater than 0");
        require(userCommit[msg.sender] >= _amount, "WKDCommit: Amount must be less than user's commit");
        userCommit[msg.sender] -= _amount;
        totalusersCommit -= _amount;
        wkd.safeTransfer(msg.sender, _amount);
        emit removeWkdCommit(msg.sender, _amount);
    }

    function getUserCommit(address _user) public view returns (uint256) {
        return userCommit[_user];
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoveryToken(address _tokenAddress, uint256 _tokenAmount) external {
        if (msg.sender != admin) revert NotPermitted();
        require(_tokenAddress != address(wkd), "WKDCommit: Cannot be WKD token");
        IBEP20(_tokenAddress).safeTransfer(admin, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}

pragma solidity ^0.8.0;

import "./utils/IBEP20.sol";
import "./WKDCommit.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Launchpad is Ownable {
    // // The offering token
    IBEP20 offeringToken;
    // check initialized
    bool public isInitialized;
    // The block number when the IFO starts
    uint256 public StartBlock;
    // The block number when the IFO ends
    uint256 public EndBlock;
    // pecrcentage of offering token to be distributed for tier 1
    uint256 public tier1Percentage;
    // pecrcentage of offering token to be distributed for tier 2
    uint256 public tier2Percentage;
    // admin address
    address public admin;
    uint256 public raisedAmount;
    // WKDCommit contract
    WKDCommit public wkdCommit;
    // Participants
    address[] public participants;
    // Pools details
    LaunchpadDetails public launchPadInfo;
    // launchpads share in amount raised
    uint256 public launchPercentShare;
    // Project owner's address
    address public projectOwner;

    struct LaunchpadDetails {
        // amount to be raised in BNB
        uint256 raisingAmount;
        // amount of offering token to be offered in the pool
        uint256 offeringAmount;
        // amount of WKD commit for tier2
        uint256 minimumRequirementForTier2;
        // launchpad start time
        uint256 launchpadStartTime;
        // launchpad end time
        uint256 launchpadEndTime;
        // Total amount in pool
        uint256 totalAmountInPool;
        // amount of offering token to be shared in tier1
        uint256 tier1Amount;
        // amount of offering token to be shared in tier2
        uint256 tier2Amount;
    }

    enum userTiers {
        Tier1,
        Tier2
    }

    struct userDetails {
        // amoount of BNB deposited by user
        uint256 amountDeposited;
        // user tier
        userTiers userTier;
        // if useer has claimed offering token
        bool hasClaimed;
    }

    mapping(address => userDetails) public user;

    event Deposit(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event init(
        address indexed offeringToken,
        uint256 StartBlock,
        uint256 EndBlock,
        address admin,
        address wkdCommit,
        uint256 raisingAmount,
        uint256 offeringAmount
    );
    event ProjectWithdraw(address indexed projectOwner, uint256 amount);
    event Claimed(address indexed user, uint256 offeringTokenAmount);
    event FinalWithdraw(address admin, uint256 BNBAmount, uint256 offeringTokenAmount);
    //  Custom errors

    error NotAllowed();
    error NotPermitted();
    error NotInitialized();
    error InvalidPercentage();
    error NotStarted();
    error NotEnded();
    error TargetCompleted();
    error AlreadyClaimed();
    error NotEnoughAmount();
    error NotDeposited();
    error NoWKDCommit();
    error NotEnoughOfferingToken();
    error InvalidAddress();
    error InvalidTime();

    function initialize(
        address _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress,
        address _projectOwner,
        address _wkdCommit,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _launchPercentShare,
        uint256 _tier2Percentage,
        uint256 _minimumRequirementForTier2
    ) public {
        if (msg.sender != owner()) revert NotPermitted();
        if (isInitialized) revert NotInitialized();
        if (_launchPercentShare > 100) revert InvalidPercentage();
        if (_tier2Percentage > 100) revert InvalidPercentage();
        if (_offeringToken == address(0)) revert InvalidAddress();
        if (_adminAddress == address(0)) revert InvalidAddress();
        if (_projectOwner == address(0)) revert InvalidAddress();
        if (_wkdCommit == address(0)) revert InvalidAddress();
        if (_startBlock <= block.number) revert InvalidTime();
        if (_endBlock <= _startBlock) revert InvalidTime();

        launchPadInfo.offeringAmount = _offeringAmount;
        launchPadInfo.raisingAmount = _raisingAmount;
        launchPercentShare = _launchPercentShare;
        launchPadInfo.minimumRequirementForTier2 = _minimumRequirementForTier2;
        tier2Percentage = _tier2Percentage;
        tier1Percentage = 100 - _tier2Percentage;
        launchPadInfo.tier2Amount = _offeringAmount * (_tier2Percentage) / 100;
        launchPadInfo.tier1Amount = (_offeringAmount * (100 - _tier2Percentage)) / 100;

        offeringToken = IBEP20(_offeringToken);
        isInitialized = true;
        StartBlock = _startBlock;
        EndBlock = _endBlock;
        admin = _adminAddress;
        projectOwner = _projectOwner;
        wkdCommit = WKDCommit(_wkdCommit);
        emit init(_offeringToken, _startBlock, _endBlock, _adminAddress, _wkdCommit, _raisingAmount, _offeringAmount);
    }

    function deposit() public payable {
        if (!isInitialized) revert NotInitialized();
        if (block.number < StartBlock) revert NotStarted();
        if (block.number > EndBlock) revert NotEnded();
        if (launchPadInfo.raisingAmount == raisedAmount) {
            revert TargetCompleted();
        }
        uint256 userCommit = wkdCommit.getUserCommit(msg.sender);
        if (userCommit == 0) revert NoWKDCommit();
        if (msg.value == 0) revert NotEnoughAmount();
        if (userCommit >= launchPadInfo.minimumRequirementForTier2) {
            user[msg.sender].userTier = userTiers.Tier2;
        } else {
            user[msg.sender].userTier = userTiers.Tier1;
        }
        participants.push(msg.sender);
        user[msg.sender].amountDeposited = user[msg.sender].amountDeposited + msg.value;
        raisedAmount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function claimToken() public {
        if (!isInitialized) revert NotInitialized();
        if (block.number < StartBlock) revert NotStarted();
        if (block.number < EndBlock) revert NotEnded();
        if (user[msg.sender].amountDeposited == 0) revert NotDeposited();
        if (user[msg.sender].hasClaimed) revert AlreadyClaimed();
        if (user[msg.sender].userTier == userTiers.Tier1) {
            uint256 amount =
                (launchPadInfo.tier1Amount * user[msg.sender].amountDeposited) / launchPadInfo.raisingAmount;
            offeringToken.transfer(msg.sender, amount);
            user[msg.sender].hasClaimed = true;
            emit Claimed(msg.sender, amount);
        } else if (user[msg.sender].userTier == userTiers.Tier2) {
            uint256 amount =
                (launchPadInfo.tier2Amount * user[msg.sender].amountDeposited) / launchPadInfo.raisingAmount;
            offeringToken.transfer(msg.sender, amount);
            user[msg.sender].hasClaimed = true;
            emit Claimed(msg.sender, amount);
        }
    }

    function sendOfferingToken(uint256 _offeringAmount) public {
        if (!isInitialized) revert NotInitialized();
        if (msg.sender != admin) revert NotAllowed();
        // i+f(!offeringToken.balanceOf(address(this)) < _offeringAmount) revert NotEnoughOfferingToken();
        offeringToken.transfer(msg.sender, _offeringAmount);
    }

    function finalWithdraw() public {
        if (!isInitialized) revert NotInitialized();
        if (msg.sender != admin) revert NotAllowed();
        if (block.number < EndBlock) revert NotEnded();
        uint256 offeringTokenAmount = offeringToken.balanceOf(address(this));
        uint256 launchPadShare = (raisedAmount * launchPercentShare) / 100;
        uint256 adminShare = raisedAmount - launchPadShare;
        payable(admin).transfer(adminShare);
        payable(projectOwner).transfer(launchPadShare);
        offeringToken.transfer(msg.sender, offeringTokenAmount);
        emit FinalWithdraw(admin, adminShare, offeringTokenAmount);
    }

    function getLaunchPadInfo()
        public
        view
        returns (
            uint256 _offeringAmount,
            uint256 _raisingAmount,
            uint256 _tier1Amount,
            uint256 _tier2Amount,
            uint256 _minimumRequirementForTier2,
            uint256 _tier1Percentage,
            uint256 _tier2Percentage,
            uint256 _launchPercentShare
        )
    {
        _offeringAmount = launchPadInfo.offeringAmount;
        _raisingAmount = launchPadInfo.raisingAmount;
        _tier1Amount = launchPadInfo.tier1Amount;
        _tier2Amount = launchPadInfo.tier2Amount;
        _minimumRequirementForTier2 = launchPadInfo.minimumRequirementForTier2;
        _tier1Percentage = tier1Percentage;
        _tier2Percentage = tier2Percentage;
        _launchPercentShare = launchPercentShare;
    }

    // get the amount of offering token to be distributed to user
    function getOfferingTokenAmount(address _user) public view returns (uint256) {
        getUserTier(_user);
        return (user[_user].amountDeposited * launchPadInfo.offeringAmount) / launchPadInfo.raisingAmount;
    }

    function hasClaimed(address _user) public view returns (bool) {
        return user[_user].hasClaimed;
    }

    function getParticipantsLength() public view returns (uint256) {
        return participants.length;
    }

    function getUserTier(address _user) public view returns (userTiers) {
        return user[_user].userTier;
    }

    function getTier1Amount() public view returns (uint256) {
        return launchPadInfo.tier1Amount;
    }

    function getUserDeposit() public view returns (uint256) {
        return user[msg.sender].amountDeposited;
    }

    // Calculate amount of offering token to be distributed in tier2
    function getTier2Amount() public view returns (uint256) {
        return launchPadInfo.tier2Amount;
    }

    function getUserDetails(address _user) public view returns (uint256, uint256, bool, userTiers) {
        return (
            user[_user].amountDeposited, getOfferingTokenAmount(_user), user[_user].hasClaimed, user[_user].userTier
        );
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external {
        if (msg.sender != admin) revert NotAllowed();
        require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");
        IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}