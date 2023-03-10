/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
        uint activeStakesLeft
    );
    event DirectStakeClaim(
        address indexed staker,
        uint payout,
        uint activeStakesLeft
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

    uint public immutable LaunchTime;
    uint public TotalShares; 
    uint public MaxStakeDuration = 5479;
    uint public EndOfLobby = 365;
    uint private MinUnstakePenalty = 182;
    
    uint private OriginScale = 10;
    uint private FlushScale = 1000;
    uint private LobbyScale = 4;
    uint private DurationScale = 700;

    address private Reserve = 0xD14e0D9DB23A7925c6C19C28D9A616d873357CBD;

    address public OriginAddr = 0xaDEF1dd539a70D59477f9CF18354F9c264fFf40f;
    address payable public FlushAddr = payable(0xaDEF1dd539a70D59477f9CF18354F9c264fFf40f);

    struct StakeCollection {
        uint share;
        uint startday;
        uint payday;
        uint duration;
    }

    struct LobbyEntries {
        uint ethCheckIn;
        address referralAddress;
    }

    /** Stakers mapping **/
    mapping(address => StakeCollection[]) public stakersArray;

    /** Lobby mappings**/
    mapping(uint => mapping(address => LobbyEntries[])) public lobby;
    mapping(uint => uint) public lobbyTotalEth;
    mapping(uint => uint) public lobbyCut;

    constructor() {
        LaunchTime = block.timestamp;
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
        require(_duration >= 7 && _duration <= MaxStakeDuration, "INVALID STAKE TIME");

        SatoshisVision.safeTransferFrom(msg.sender, address(this), _satoshiAmount);// CHANGE ADDRESS ON MAINNET
        
        if (TotalShares == 0 ){
            stakersArray[msg.sender].push(StakeCollection(_satoshiAmount, block.timestamp, block.timestamp + (_duration * 1 days), _duration));
            TotalShares += _satoshiAmount;
        }
        else{
            uint TotalSATS = contractBalance();
            uint SATShare = _satoshiAmount * TotalShares / TotalSATS;
            stakersArray[msg.sender].push(StakeCollection(SATShare, block.timestamp, block.timestamp + (_duration * 1 days), _duration));
            TotalShares += SATShare;
        }
        emit Stake(msg.sender, _satoshiAmount, _duration, stakersArray[msg.sender].length - 1, stakersArray[msg.sender].length);
    }

    function matureUnstake(address _recipient, uint _arraySlot) 
        external 
        nonReentrant
    {
        require(_recipient != address(0));
        require(_recipient != address(this));
        require(stakersArray[_recipient].length != 0, "Recipient has no Stakes");
        require(_arraySlot < stakersArray[_recipient].length, "Invalid slot");

        StakeCollection memory sc = stakersArray[_recipient][_arraySlot];
        assert(sc.share != 0);
        require(block.timestamp >= sc.payday, "Immature Unstake");
        
        uint TotalSATS = contractBalance();
        uint SATS = sc.share * TotalSATS / TotalShares;
        uint payout = _calculatePayout(SATS, sc.duration * 1 days);
        uint totalPayout = SATS + payout;
        uint delay = block.timestamp - sc.payday;
        if (delay > 14 days){
            totalPayout = _calculateLatePayout(totalPayout, delay - 14 days);
        }
        if (totalPayout > SATS){
            SatoshisVision.safeTransferFrom(Reserve, address(this), totalPayout - SATS);
        }
        if (totalPayout > 0){
            SatoshisVision.safeTransfer(_recipient, totalPayout);
        }

        TotalShares -= sc.share;  
        deleteFromMapping(_recipient, _arraySlot);
        emit StakeClaim(msg.sender, _recipient, totalPayout, delay > 1 days ? delay / 1 days : 0, stakersArray[_recipient].length);
    }

    function Unstake(uint _arraySlot) 
        external 
        nonReentrant
    {
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        require(stakersArray[msg.sender].length != 0, "You have no Stakes");
        require(_arraySlot < stakersArray[msg.sender].length, "Invalid slot");

        StakeCollection memory sc = stakersArray[msg.sender][_arraySlot];
        assert(sc.share != 0);
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

        if (totalPayout > SATS){
            SatoshisVision.safeTransferFrom(Reserve, address(this), totalPayout - SATS);
        }

        if (totalPayout > 0){
            SatoshisVision.safeTransfer(msg.sender, totalPayout);
        }

        TotalShares -= sc.share;  
        deleteFromMapping(msg.sender, _arraySlot);
        emit DirectStakeClaim(msg.sender, totalPayout, stakersArray[msg.sender].length);
    }

    function _calculatePayout(uint _sats, uint _seconds)
        internal 
        returns (uint)
    {
        uint longerPaysBetter = (_sats * (_seconds / 1 days)) / 1820;
        uint biggerPaysBetter = _sats < 1e15 ? (_sats ** 2) / 21e15 : 4e13;
        uint payout = longerPaysBetter + biggerPaysBetter;
        if (payout > 0 ){
            SatoshisVision.safeTransfer(OriginAddr, payout / OriginScale);
            payout -= payout / OriginScale;
        }
        return payout;
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
            SatoshisVision.safeTransfer(OriginAddr, penalty / OriginScale);
            lobbyCut[(block.timestamp - LaunchTime) / 1 days] += penalty / LobbyScale;
        }
        return totalPayout;
    }

     function _calculateLatePayout(uint _totalPayout, uint _seconds) 
        internal 
        returns (uint actualPayout)
    {
        uint penalty = _calculateLatePenalty(_totalPayout, _seconds);
        actualPayout = penalty < _totalPayout ? _totalPayout - penalty : 0;
        if (actualPayout != 0) {
            lobbyCut[(block.timestamp - LaunchTime) / 1 days] += penalty / LobbyScale;
        }
    }

    function _calculateLatePenalty(uint _rawPayout, uint _seconds) 
        internal 
        view 
        returns (uint penalty)
    {
        uint secondsToDays = _seconds / 1 days;
        penalty = _rawPayout * secondsToDays / DurationScale;
    }

    function individualStakes(address _recipient) 
        external 
        view 
        returns (uint)
    {
        return stakersArray[_recipient].length;
    }

    function EnterLobby(address _referralAddress) 
        external 
        payable
    {
        require(msg.value != 0);
        uint currentDay = (block.timestamp - LaunchTime) / 1 days;
        require(currentDay < EndOfLobby, "There are no open lobbies");
        uint lobbyFee = msg.value / FlushScale;
        lobby[currentDay][msg.sender].push(LobbyEntries(msg.value - lobbyFee, _referralAddress));
        lobbyTotalEth[currentDay] += msg.value - lobbyFee;
        FlushAddr.transfer(lobbyFee);
        emit InTheLobby(currentDay, msg.value- lobbyFee, msg.sender, _referralAddress);
    }

    function ExitLobby(uint _entryDay) 
        external 
    {
        require(block.timestamp - LaunchTime > 1 days && (block.timestamp - LaunchTime) / 1 days >= _entryDay++, "This lobby will be open after 24 hours");
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

        payable(msg.sender).transfer(ethCheckout);
        if (totalRewards > 0 && SatoshisVision.balanceOf(address(this)) > totalRewards){
            SatoshisVision.safeTransfer(msg.sender, totalRewards);
        }
        emit LeftTheLobby(_entryDay, (block.timestamp - _entryDay) / 1 days, ethCheckout, totalRewards, msg.sender, lobbyTotalEth[_entryDay]);
    }

}