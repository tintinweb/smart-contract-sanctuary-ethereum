// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRelation.sol";

contract GuessScore is ReentrancyGuard {
    IERC20 public _usdt;
    using SafeERC20 for IERC20;

    address public owner;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    struct TeamStruct {
        mapping(address => mapping(bytes32 => uint256)) usersScore;
        mapping(address => uint256) usersAmount;
        mapping(address => uint256) usersRewarded;
        mapping(address => bool) userFirstDeposit;
        mapping(bytes32 => uint256) usersNumber;
        mapping(bytes32 => uint256) depositCount;
        mapping(bytes32 => uint256) scoreAmount;
        address[] users;
        uint256 totalAmount;
        uint256 totalReward;
        bool turnOn;
        bool stopDeposit;
        bool stopWithdrawal;
        bytes32 score;
    }

    mapping(bytes32 => TeamStruct) private teamsData;
    mapping(bytes32 => uint256[2]) private teamsScore;

    uint256 public amountMax = 1000000000;

    uint256 public amountMin = 10000000;

    uint256 public poolFee = 4;
    uint256 public relationFee = 4;

    address public feeAddr;
    address public poolAddr;

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   event
    /////////////////////////////////////////////////////////////////////////////////////////////////

    event DepositEvent(
        address userAddr,
        uint256[2] teamIds,
        uint256[2] scores,
        uint256 amount
    );
    event WithdrawalEvent(
        address userAddr,
        uint256 reward,
        uint256[2] teamIds,
        uint256[2] scores
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////



    modifier onlyOP() {
        require(
            msg.sender == operator || msg.sender == owner,
            "unauthorized"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == operator || msg.sender == owner,
            "ADMIN: unauthorized"
        );
        _;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   play
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function arryToHash(uint256[2] memory _n) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n[0], _n[1]));
    }

    function addTeamUser(address userAddr, bytes32 teamId) private {
        if (!teamUserExit(userAddr, teamsData[teamId].users))
            teamsData[teamId].users.push(userAddr);
    }

    function teamUserExit(address userAddr, address[] memory users)
        private
        pure
        returns (bool)
    {
        bool ret;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == userAddr) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    function getTeamUser(uint256[2] memory teamIds)
        public
        view
        returns (address[] memory)
    {
        return teamsData[arryToHash(teamIds)].users;
    }

    function getTeamUserDepoistAmount(uint256[2] memory teamIds, address user)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].usersAmount[user];
    }

    function getTeamUserscoreAmount(
        uint256[2] memory teamIds,
        address user,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return
            teamsData[arryToHash(teamIds)].usersScore[user][arryToHash(scores)];
    }

    function getTeamTotalAmount(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalAmount;
    }

    function getTeamTotalReward(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalReward;
    }

    function getTeamTurnOn(uint256[2] memory teamIds)
        public
        view
        returns (bool)
    {
        return teamsData[arryToHash(teamIds)].turnOn;
    }

    function getTeamScore(uint256[2] memory teamIds)
        public
        view
        returns (uint256[2] memory)
    {
        return teamsScore[arryToHash(teamIds)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   play
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function deposit(
        uint256[2] memory teamIds,
        uint256 amount,
        uint256[2] memory scores,
        address referrer
    ) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        require(!teamsData[teamId].turnOn, "deposit off");

        require(!teamsData[teamId].stopDeposit, "deposit stop");

        require(amount >= amountMin, "Amount less");

        require(
            (teamsData[teamId].usersAmount[msg.sender] + amount) <= amountMax,
            "Amount limit"
        );

        uint256 fee = getPercentage(amount, poolFee);
        uint256 reward = getPercentage(amount, relationFee);
        uint256 sa = amount - (fee + reward);

        teamsData[teamId].usersScore[msg.sender][score] += sa;

        teamsData[teamId].totalAmount += sa;

        teamsData[teamId].usersAmount[msg.sender] += amount;

        if (!teamsData[teamId].userFirstDeposit[msg.sender]) {
            teamsData[teamId].usersNumber[score]++;
        } else {
            teamsData[teamId].userFirstDeposit[msg.sender] = true;
        }
        teamsData[teamId].depositCount[score]++;
        teamsData[teamId].scoreAmount[score] += sa;

        // Share the Rewards
        IRelation _relation = IRelation(relation);
        address _superior = _relation.getUserSuperior(msg.sender);
        if (_superior == address(0)) {
            _superior = referrer;
            _relation.bind(msg.sender, referrer);
        }

        _usdt.safeTransferFrom(msg.sender, feeAddr, fee);
        _usdt.safeTransferFrom(msg.sender, _superior, reward);
        _usdt.safeTransferFrom(msg.sender, poolAddr, sa);
        //

        addTeamUser(msg.sender, teamId);

        emit DepositEvent(msg.sender, teamIds, scores, amount);
    }

    function withdrawal(uint256[2] memory teamIds) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = teamsData[teamId].score;

        require(!teamsData[teamId].stopWithdrawal, "withdrawal stop");

        require(
            teamsData[teamId].usersRewarded[msg.sender] == 0,
            "users is Rewarded"
        );

        require(teamsData[teamId].turnOn, "Rewards are not turned on");

        require(
            teamsData[teamId].totalReward < teamsData[teamId].totalAmount,
            "The reward is gone"
        );


        uint256 reward = getUserWithdrawal(msg.sender, teamId, score);

        teamsData[teamId].totalReward += reward;

        teamsData[teamId].usersRewarded[msg.sender] = reward;

        _usdt.safeTransfer(msg.sender, reward);

        emit WithdrawalEvent(
            msg.sender,
            reward,
            teamIds,
            teamsScore[teamId]
        );
    }

    function getTeamShare(
        address user,
        bytes32 teamId,
        bytes32 score
    ) public view returns (uint256) {
        if (teamId == 0) return 0;

        uint256 amount = teamsData[teamId].usersScore[user][score];

        uint256 total = teamsData[teamId].scoreAmount[score];

        return (amount / total) + 1000000;
    }

    function getPercentage(uint256 amount, uint256 parameter) public pure returns (uint256) {
        return (amount * parameter) / 100;
    }

    function getUserWithdrawal(address user, bytes32 teamId, bytes32 score) public view returns (uint256) {
        uint256 share = getTeamShare(user, teamId, score);
        uint256 reward = (teamsData[teamId].totalAmount * share) / 1000000;
        return reward;
    }

    function getScoreTeamDepostitCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].usersNumber[arryToHash(scores)];
    }

    function getScoreDepositCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].depositCount[arryToHash(scores)];
    }

    function getTeamScoreAmount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].scoreAmount[arryToHash(scores)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256[2] memory teamIds, uint256[2] memory scores)
        public
        onlyOP
        nonReentrant
    {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        teamsScore[teamId] = scores;

        teamsData[teamId].score = score;
        teamsData[teamId].turnOn = true;
    }

    function setUserAmount(uint256 _amountMax, uint256 _amountMin)
        public
        onlyOP
        nonReentrant
    {
        amountMax = _amountMax;
        amountMin = _amountMin;
    }

    function setPoolFee(uint256 _poolFee) public onlyOP nonReentrant {
        poolFee = _poolFee;
    }

    function setRelationFee(uint256 _relationFee) public onlyOP nonReentrant {
        relationFee = _relationFee;
    }

    function setStopDeposit(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopDeposit = b;
    }

    function setStopWithdrawal(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopWithdrawal = b;
    }

    function setFeeAddr(address _feeAddr) public onlyOP {
        feeAddr = _feeAddr;
    }

    function setPoolAddr(address _poolAddr) public onlyOP {
        poolAddr = _poolAddr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   manager
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function setOperators(address to) public onlyOwner {
        operator = to;
    }

    function setRelationAddr(address _relation) public onlyOwner {
        relation = _relation;
    }

    function setUsdtAddr(address _token) public onlyOwner {
        _usdt = IERC20(_token);
    }

    function emergency(address to, uint256 amount) public onlyOwner {
        _usdt.safeTransfer(to, amount);
    }

    function setOwner(address _addr) public onlyOwner {
        owner = _addr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   Program
    /////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        IERC20 _token,
        address _feeAddr,
        address _poolAddr,
        address _relation
    ) {
        owner = msg.sender;
        _usdt = _token;
        feeAddr = _feeAddr;
        poolAddr = _poolAddr;
        relation = _relation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRelation {
    function bind(address _account, address _referrer) external;

    function getUserSuperior(address account) external view returns (address);

    function getUserActive(address account) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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