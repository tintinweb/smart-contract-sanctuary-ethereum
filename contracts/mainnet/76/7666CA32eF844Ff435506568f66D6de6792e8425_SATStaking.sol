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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

contract SATStaking is ReentrancyGuard{

    /**  Stake event logs **/
    event Stake(
        address indexed staker,
        uint sats,
        uint duration,
        uint arraySlot,
        uint activeStakes
    );

    /**  Stake Claim event logs **/
    event StakeClaim(
        address indexed initializer,
        address indexed staker,
        uint payout,
        uint daysDelayed,
        uint activeStakes
    );
    event DirectStakeClaim(
        address indexed staker,
        uint payout,
        uint activeStakes
    );

    /**  Lobby event logs **/
    event InTheLobby(
        uint entryDay,
        uint ethCheckedIn,
        address indexed lobbyMember,
        address indexed referrer
    );

    event LeftTheLobby(
        uint entryDay,
        uint exitDay,
        uint ethCheckedOut, 
        uint totalRewards,
        address indexed lobbyMember,
        uint ethLeftInLobby
    );

    /** Satoshis Vision token interface and Safety Wrapper **/
    using SafeERC20 for IERC20;
    IERC20 public SatoshisVision = IERC20(0x6C22910c6F75F828B305e57c6a54855D8adeAbf8);

    uint public immutable LaunchTime; //Launch time contract
    uint public TotalShares; //Total share of users
    uint public MaxStakeDuration = 5479; //Maximum stake time in days
    uint public EndOfLobby = 365; //Final day of an active lobby in days
    uint private MinUnstakePenalty = 182; //The minimum number days to be used when calulating penalty for an early unstake
    
    uint private OriginScale = 10; //Origin scale: represents 10% of penalty / payout sent to the origin address
    uint private FlushScale = 1000; //Flush scale: represents 0.1% sent to flush address 
    uint private PenaltyScale = 4; //Penalty scale: represents 25% of penalties to leave in the lobby
    uint private DurationScale = 700; //Duration scale: represents 0.14% of penalties deducted from payout after a late unstake

    address private Reserve = 0xD14e0D9DB23A7925c6C19C28D9A616d873357CBD;

    address public OriginAddr = 0xaDEF1dd539a70D59477f9CF18354F9c264fFf40f;
    address payable public FlushAddr = payable(0xaDEF1dd539a70D59477f9CF18354F9c264fFf40f);

    struct StakeCollection {
        uint sats;
        uint share;
        uint startday;
        uint payday;
        uint duration;
    }

    struct StakeHistory {
        uint sats;
        uint share;
        int yield;
        uint startday;
        uint payday;
        uint duration;
        uint closed;
    }

    struct LobbyEntries {
        uint ethCheckIn;
        address referralAddress;
    }

    /** Stakers mapping **/
    mapping(address => StakeCollection[]) public stakersArray;
    mapping(address => StakeHistory[]) public stakersHistory;

    /** Lobby mappings**/
    mapping(uint => mapping(address => LobbyEntries[])) public lobby;
    mapping(address => uint[]) public lobbyMapping; //Used by frontend to view a lobby member's day of entry. Does not affect flow of contract
    mapping(uint => uint) public lobbyTotalEth;
    mapping(uint => uint) public lobbyCut;

    constructor() {
        LaunchTime = block.timestamp;
    }

    function currentDay() public view returns (uint){
        return (block.timestamp - LaunchTime) / 1 days;
    }

    function timeStamp() external view returns (uint){
        return block.timestamp;
    }

    function contractBalance() 
        public 
        view 
        returns (uint)
    {
        return SatoshisVision.balanceOf(address(this));
    }

    function deleteFromMapping(address _recipient, uint _arraySlot) 
        private 
    {
        if (_arraySlot != stakersArray[_recipient].length - 1) {
            stakersArray[_recipient][_arraySlot] = stakersArray[_recipient][stakersArray[_recipient].length - 1];
        }
        stakersArray[_recipient].pop();
    }

    function stakeSatoshisVision(uint256 _satoshiAmount, uint256 _duration)
        external
        nonReentrant
    {
        require(_satoshiAmount > 10000, "Stake amount too low");
        require(_duration >= 7 && _duration <= MaxStakeDuration, "INVALID STAKE TIME");

        SatoshisVision.safeTransferFrom(msg.sender, address(this), _satoshiAmount);// CHANGE ADDRESS ON MAINNET
        
        if (TotalShares == 0 ){
            stakersArray[msg.sender].push(StakeCollection(_satoshiAmount, _satoshiAmount, block.timestamp, block.timestamp + (_duration * 1 days), _duration));
            stakersHistory[msg.sender].push(StakeHistory(_satoshiAmount, _satoshiAmount, 0, block.timestamp, block.timestamp + (_duration * 1 days), _duration, 0));
            TotalShares += _satoshiAmount;
        }
        else{
            uint TotalSATS = contractBalance();
            uint SATShare = _satoshiAmount * TotalShares / TotalSATS;
            stakersArray[msg.sender].push(StakeCollection(_satoshiAmount, SATShare, block.timestamp, block.timestamp + (_duration * 1 days), _duration));
            stakersHistory[msg.sender].push(StakeHistory(_satoshiAmount, SATShare, 0, block.timestamp, block.timestamp + (_duration * 1 days), _duration, 0));
            TotalShares += SATShare;
        }
        emit Stake(msg.sender, _satoshiAmount, _duration, stakersArray[msg.sender].length - 1, stakersArray[msg.sender].length);
    }

    function matureUnstake(address _recipient, uint _arraySlot) 
        external 
        nonReentrant
    {
        require(_recipient != address(0), "Address zero not allowed");
        require(_recipient != address(this), "Contract address not allowed");
        require(stakersArray[_recipient].length != 0, "Recipient has no Stakes");
        require(_arraySlot < stakersArray[_recipient].length, "Invalid slot");

        StakeCollection memory sc = stakersArray[_recipient][_arraySlot];
        require(block.timestamp >= sc.payday, "Immature Unstake");
        
        uint TotalSATS = contractBalance();
        uint SATS = sc.share * TotalSATS / TotalShares;
        uint payout = _calculatePayout(SATS, sc.duration * 1 days);
        uint totalPayout = SATS + payout;
        uint delay = block.timestamp - sc.payday;
        if (delay > 14 days){
            totalPayout = _calculateLatePayout(totalPayout, delay - 14 days);
        }

        TotalShares -= sc.share;
        stakersHistory[_recipient][_arraySlot] = StakeHistory(sc.sats, sc.share, int(totalPayout) - int(sc.sats), sc.startday, sc.payday, sc.duration, block.timestamp);  
        deleteFromMapping(_recipient, _arraySlot);

        if (totalPayout > 0){
            if (totalPayout > SATS && totalPayout - SATS > OriginScale){
                uint OriginAccounting = (totalPayout - SATS) / OriginScale;
                SatoshisVision.safeTransferFrom(Reserve, address(this), totalPayout - SATS);
                SatoshisVision.safeTransfer(OriginAddr, OriginAccounting);
                SatoshisVision.safeTransfer(_recipient, totalPayout - OriginAccounting);
            }
            else{
                SatoshisVision.safeTransfer(_recipient, totalPayout);
            } 
        }
        emit StakeClaim(msg.sender, _recipient, totalPayout, delay > 1 days ? delay / 1 days : 0, stakersArray[_recipient].length);
    }

    function unstake(uint _arraySlot) 
        external 
        nonReentrant
    {
        require(msg.sender != address(0), "Address zero not allowed");
        require(msg.sender != address(this), "Contract address not allowed");
        require(stakersArray[msg.sender].length != 0, "You have no Stakes");
        require(_arraySlot < stakersArray[msg.sender].length, "Invalid slot");

        StakeCollection memory sc = stakersArray[msg.sender][_arraySlot];
        uint TotalSATS = contractBalance();
        uint SATS = sc.share * TotalSATS / TotalShares;
        uint totalPayout;

        if (sc.payday > block.timestamp){
            uint actualStakeTime = block.timestamp - sc.startday;
            require(actualStakeTime > 0);
            totalPayout = _calculateEarlyPayout(SATS, actualStakeTime);
        }

        else{
            uint payout = _calculatePayout(SATS, sc.duration * 1 days);
            totalPayout = SATS + payout;
            
            uint delay = block.timestamp - sc.payday;
            if (delay > 14 days){
                totalPayout = _calculateLatePayout(totalPayout, delay - 14 days);
            }
        }

        TotalShares -= sc.share;
        stakersHistory[msg.sender][_arraySlot] = StakeHistory(sc.sats, sc.share, int(totalPayout) - int(sc.sats), sc.startday, sc.payday, sc.duration, block.timestamp);  
        deleteFromMapping(msg.sender, _arraySlot);

        if (totalPayout > 0){
            if (totalPayout > SATS && totalPayout - SATS > OriginScale){
                uint OriginAccounting = (totalPayout - SATS) / OriginScale;
                SatoshisVision.safeTransferFrom(Reserve, address(this), totalPayout - SATS);
                SatoshisVision.safeTransfer(OriginAddr, OriginAccounting);
                SatoshisVision.safeTransfer(msg.sender, totalPayout - OriginAccounting);
            }
            else{
                SatoshisVision.safeTransfer(msg.sender, totalPayout);
            }
        }
        emit DirectStakeClaim(msg.sender, totalPayout, stakersArray[msg.sender].length);
    }

    function _calculatePayout(uint _sats, uint _seconds)
        internal 
        pure
        returns (uint payout)
    {
        uint longerPaysBetter = (_sats * (_seconds / 1 days)) / 1820;
        uint biggerPaysBetter = _sats < 1e15 ? (_sats ** 2) / 21e15 : 4e13;
        payout = longerPaysBetter + biggerPaysBetter;
    }

    function _calculateEarlyPayout(uint _sats, uint _seconds)
        internal 
        returns (uint)
    {
        if (_seconds < 1 days) _seconds = 1 days;
        uint payout = _calculatePayout(_sats, _seconds);
        uint penalty = (payout * MinUnstakePenalty) / (_seconds / 1 days);
        uint totalPayout = _sats + payout > penalty ? (_sats + payout) - penalty : 0;
        
        if (penalty <= _sats) {
            if(currentDay() < EndOfLobby){
                SatoshisVision.safeTransfer(OriginAddr, penalty / OriginScale);
                lobbyCut[currentDay()] += penalty / PenaltyScale;
            }
            else{
                SatoshisVision.safeTransfer(OriginAddr, penalty / OriginScale);
                SatoshisVision.safeTransfer(Reserve, penalty / PenaltyScale);
            }
        }
        return totalPayout;
    }

     function _calculateLatePayout(uint _totalPayout, uint _seconds) 
        internal 
        view
        returns (uint actualPayout)
    {
        uint penalty = _calculateLatePenalty(_totalPayout, _seconds);
        actualPayout = penalty < _totalPayout ? _totalPayout - penalty : 0;

    }

    function _calculateLatePenalty(uint _rawPayout, uint _seconds) 
        internal 
        view 
        returns (uint penalty)
    {
        uint secondsToDays = _seconds / 1 days;
        penalty = _rawPayout * secondsToDays / DurationScale;
    }

    /** @notice 
        Helper for frontend to receive user's stake length
    */

    function individualStakesLength(address _recipient) 
        external 
        view 
        returns (uint, uint)
    {
        return (stakersArray[_recipient].length, stakersHistory[_recipient].length);
    }

    /** @notice 
        Enter lobby with Eth to receive a percentage of penalties from early unstakers
    */

    function enterLobby(address _referralAddress) 
        external 
        payable
    {
        require(msg.value != 0, "Value cannot be zero");
        require(currentDay() < EndOfLobby, "Lobbies have ended");

        if (lobby[currentDay()][msg.sender].length == 0){
            lobbyMapping[msg.sender].push(currentDay());
        }
        
        uint lobbyFee = msg.value / FlushScale;
        lobby[currentDay()][msg.sender].push(LobbyEntries(msg.value - lobbyFee, _referralAddress));
        lobbyTotalEth[currentDay()] += msg.value - lobbyFee;
        FlushAddr.transfer(lobbyFee);
        emit InTheLobby(currentDay(), msg.value - lobbyFee, msg.sender, _referralAddress);
    }

    /** @notice 
        Exit lobby with Eth and any penalty rewards
    */

    function exitLobby(uint _entryDay) 
        external 
        nonReentrant
    {
        require(currentDay() >= _entryDay++, "This lobby will be open after 24 hours");
        require(lobby[_entryDay][msg.sender].length != 0, "You're not in this lobby");
        uint ethCheckout;
        uint totalRewards;

        while(lobby[_entryDay][msg.sender].length > 0){
            uint ethCheckedIn = lobby[_entryDay][msg.sender][lobby[_entryDay][msg.sender].length - 1].ethCheckIn;
            address referrer = lobby[_entryDay][msg.sender][lobby[_entryDay][msg.sender].length - 1].referralAddress;

            uint rewards = lobbyCut[_entryDay] * ethCheckedIn / lobbyTotalEth[_entryDay];
            
            if (referrer != address(0) && rewards > 5 && SatoshisVision.balanceOf(address(this)) > rewards) {
                SatoshisVision.safeTransfer(referrer, rewards / 5);
                totalRewards += rewards - (rewards / 5);
            }else{
                totalRewards += rewards;
            }

            ethCheckout += ethCheckedIn;
            lobbyCut[_entryDay] -= rewards;
            lobbyTotalEth[_entryDay] -= ethCheckedIn;
            lobby[_entryDay][msg.sender].pop();
        }

        if (totalRewards > 0 && SatoshisVision.balanceOf(address(this)) > totalRewards){
            SatoshisVision.safeTransfer(msg.sender, totalRewards);
        }
        lobbyDelete(msg.sender, _entryDay);
        payable(msg.sender).transfer(ethCheckout);
        emit LeftTheLobby(_entryDay, (block.timestamp - _entryDay) / 1 days, ethCheckout, totalRewards, msg.sender, lobbyTotalEth[_entryDay]);
    }

    /** @notice 
        Delete from lobbyMapping which is used by frontend. Does not affect contract flow 
    */
    function lobbyDelete(address _member, uint _entryDaySlot) 
        private 
    {
        if (_entryDaySlot != lobbyMapping[_member].length - 1) {
            lobbyMapping[_member][_entryDaySlot] = lobbyMapping[_member][lobbyMapping[_member].length - 1];
        }
        lobbyMapping[_member].pop();
    }

    /** @notice 
        Helper for frontend to receive days length of single lobby member 
    */
    function lobbyMemberDaysLength(address _member) 
        external 
        view 
        returns (uint)
    {
        return lobbyMapping[_member].length;
    }

    /** @notice 
        Remove foreign tokens from the smart contract
    */

    function sweep(
        IERC20 token
    ) external {
        require(token != SatoshisVision, "Cannot be SATS");
        token.safeTransfer(OriginAddr, token.balanceOf(address(this)));
    }
}