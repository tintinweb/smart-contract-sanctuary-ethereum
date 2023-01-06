/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: exxbet.sol


pragma solidity ^0.8.0;



contract ExxbetRewards is Initializable{


    address public admin;
    IERC20Upgradeable tokenA;

      function initalize() external initializer{
        admin = payable(msg.sender);
        // token = IERC20Upgradeable(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
        tokenA = IERC20Upgradeable(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
        // tokenB = 0xb5708e2F641738312D51f824A46992Ae6c89D9f5;
        

    }
    

    mapping(address => bool) public canRefer;   
    mapping(address => uint) public referralCount;
    mapping(address => mapping(uint => address)) public addresstoReferrals;
    mapping(address => uint) public totalAmountSpent;
    

    mapping(address => address) public referredBy;


    uint referralBonusCap;
    uint referralBonusMinimumSpend;

    function staked(address staker) external{
        canRefer[staker] =  true;
    }

    function refer(address referred) external{
        require(canRefer[msg.sender], "You are not qualified to refer");

        referralCount[msg.sender] ++;

        addresstoReferrals[msg.sender][referralCount[msg.sender]] = referred;

        referredBy[referred] = msg.sender;

    }

    function setAmountSpent(address user, uint amount) external {
        totalAmountSpent[user] += amount;
    }

    function claimReferralBonus(address user, uint amount) external{
        require(canRefer[user], "Not eligible to refer");
        require(referralCount[user] > 0, "No referrals");
        
        if(amount > referralBonusCap){
            amount = referralBonusCap;
        }

        tokenA.transfer(user,amount);

    }

    function getBonus(address user) internal view returns(uint){
        uint amount = 500 * totalAmountSpent[user]/10000;

     

        return amount;
    }

    


    function setBonusCap(uint cap) external{
        require(msg.sender == admin, "Not Admin");

        referralBonusCap = cap;
    }

    function setMinimumSpend(uint _minim) external{
        require(msg.sender == admin, "Not Admin");

        referralBonusMinimumSpend = _minim;  
    
    }


}
// File: Pool.sol


pragma solidity ^0.8.0;




contract PoolBetDT is Initializable{

    address public admin;
    // IERC20 public immutable token;
    ExxbetRewards public exxbet;
    address public tokenA;
    address public tokenB;
    
    // mapping(address => mapping(string => uint)) public betidToStake;
    mapping(address => mapping(string => mapping(uint => uint))) public betidToStake;
    mapping(address => mapping(string => mapping(uint => address))) public tokenToStake;
    mapping(string => uint) public betIdtoTotal;
    mapping(string => uint) public betCount;
    mapping(address => mapping(string => mapping(uint => bool))) public betidToClaimed;
    mapping(address => mapping(string => mapping(uint => bool))) public staked;
    mapping(string => bool) public fullyClaimed;
    mapping(string => string) public Game;
    mapping(string => address) public firstAddress;

    mapping (address => uint) public adminTotaFee;
    mapping (address => uint) public totalResiduals;

    bool public bonus;
    uint public bonusPercent;
    uint public maxBonusAmount;
    address public bonusAddress;

    event GameName(string gamename);
    

    function initialize() external initializer{
        admin = payable(msg.sender);
        // token = IERC20(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
        tokenA = 0xe10DCe92fB554E057619142AbFBB41688A7e8D07;
        tokenB = 0xb5708e2F641738312D51f824A46992Ae6c89D9f5;
        exxbet = ExxbetRewards(0xdA664Ce0eb058e8fF1d23af52826620957aB5Fe1);

    }
    


    receive() external payable{}
    

    function _stake(address _token, string calldata  betid, uint transactionID, uint stakeAmount, address staker) internal returns(bool success){
            require(msg.sender == staker, "Staker");

            IERC20Upgradeable token = IERC20Upgradeable(_token);

            token.transferFrom(staker, address(this), stakeAmount);
            staked[staker][betid][transactionID] = true;
            return true;
        
    }

    function Stake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
        // require(!fullyClaimed[betid], "Bet Id is currently in use");
        if (_token == tokenA || _token == tokenB){
            
            if(betCount[betid] == 0){

                firstAddress[betid] =_token;

            }else{
                
                require(_token == firstAddress[betid], "Token not used in bet");

            }

            bool success =  _stake(_token, betid, transactionID, stakeAmount, msg.sender);

            require(success, "transfer Failed");

            betCount[betid] ++;
            betidToStake[msg.sender][betid][transactionID] += stakeAmount;
            betIdtoTotal[betid] += stakeAmount;
            tokenToStake[msg.sender][betid][transactionID] = _token;

            exxbet.staked(msg.sender);
            exxbet.setAmountSpent(msg.sender, stakeAmount);

            Game[betid] = game;

            emit GameName(game);
        }else{
            revert("Unknown Token");
        }

     

    }

    function creditsStake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
         if (_token == tokenA || _token == tokenB){
            
            if(betCount[betid] == 0){

                firstAddress[betid] =_token;

            }else{
                
                require(_token == firstAddress[betid], "Token not used in bet");

            }

            // bool success =  _stake(_token, betid, transactionID, stakeAmount, msg.sender);

            // require(success, "transfer Failed");

            betCount[betid] ++;
            betidToStake[msg.sender][betid][transactionID] += stakeAmount;
            betIdtoTotal[betid] += stakeAmount;
            tokenToStake[msg.sender][betid][transactionID] = _token;

            staked[msg.sender][betid][transactionID] = true;

            Game[betid] = game;

            emit GameName(game);
        }else{
            revert("Unknown Token");
        }

    }

    function getStaked(string calldata  betid, uint transactionID, address staker) external view returns(bool){
        return staked[staker][betid][transactionID];
    }

    function getFinalised(string calldata  betid, uint transactionID, address reciever) external view returns(bool){
        return betidToClaimed[reciever][betid][transactionID];
    }




    function end(string calldata  betid, uint transactionID, uint amount, uint fee, bool last) external{
        
        require(!betidToClaimed[msg.sender][betid][transactionID], "Address already claimed");
        
        uint stake = betidToStake[msg.sender][betid][transactionID];
        uint totalStake = betIdtoTotal[betid];

        require(amount <= totalStake, "Insufficient Amount in balance");
        require(stake > 0, "Did Not Stake");
         
        uint newamount = amount;
        

        bool success = _transfer(firstAddress[betid], msg.sender, amount);
        require(success, "Transfer Not successful");

        
        betidToClaimed[msg.sender][betid][transactionID] = true;        
        delete betidToStake[msg.sender][betid][transactionID];
        delete tokenToStake[msg.sender][betid][transactionID];

        amount+= fee;

        betIdtoTotal[betid] -= amount;

        adminTotaFee[firstAddress[betid]] += fee;

        lastClaim(firstAddress[betid], betid, last, betIdtoTotal[betid]);

        
        if (bonus == true && firstAddress[betid] == bonusAddress){
          Bonus(newamount, betid);
        }

        
        emit GameName(Game[betid]);

    }

    function Bonus(uint amount, string calldata betid) internal{
        require(bonus, "Bonus not set");

         amount = amount * bonusPercent/ 10000;
         if(amount > maxBonusAmount){

             amount = maxBonusAmount;
         }

        _transfer(firstAddress[betid], msg.sender, amount);

    }


    function _transfer(address _token, address reciever, uint amount) internal returns(bool){
        require(msg.sender == reciever, "Not Reciever");
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        
        token.transfer(reciever, amount);

        return true;

    }

    function lastClaim(address _token, string calldata betid, bool last, uint residual) internal{
        fullyClaimed[betid] = last;

        if(fullyClaimed[betid]){
            totalResiduals[_token] += residual;
        }
    }

    function getTotalResidue(address _token) external view returns(uint){
          require(msg.sender == admin, "Not Admin");
        return totalResiduals[_token];
    }
            
     function withdrawFees(address _token, uint amount) external{
        require(msg.sender == admin, "Not Admin");
        require(amount <= adminTotaFee[_token], "Insufficient Amount in Balance");
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        
        adminTotaFee[_token] -= amount;

        token.transfer(admin, amount);

        
    }
    
    function adminResidualWithdraw(address _token) external{
          require(msg.sender == admin, "Not Admin");
          require(totalResiduals[_token] > 0, "No Residuals Available");

        IERC20Upgradeable token = IERC20Upgradeable(_token);
        
          uint residual = totalResiduals[_token];

          delete totalResiduals[_token];

          token.transfer(admin, residual);
    }

    
    function setBonus(bool _bonus) external{
        require(msg.sender == admin, "Not Admin");
        
        bonus = _bonus;
    }

    function bonusDetails(address _bonusAddress, uint _max, uint percent) external{
        require(msg.sender == admin, "Not Admin");
        require(bonus, "Bonus not set");

        maxBonusAmount = _max;
        bonusPercent = percent;
        bonusAddress = _bonusAddress;

    }
}