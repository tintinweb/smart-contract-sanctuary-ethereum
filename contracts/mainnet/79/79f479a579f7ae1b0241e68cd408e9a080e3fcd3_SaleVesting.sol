/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: No

pragma solidity = 0.8.17;

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//--- Initialize ---//
contract Initializable {
  bool private initialized;
  bool private initializing;
  modifier initializer() {
    require(initializing || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


library SafeERC20 {
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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



contract SaleVesting is Context, Ownable, Initializable {

    using SafeERC20 for IERC20;

    // map address to uint256
    mapping (address => uint256) private _purchasedSEEDSALETokens;
    mapping (address => uint256) private _purchasedPrivateSaleTokens;
    mapping (address => uint256) private _purchasedPrivateSale2Tokens;
    mapping (address => uint256) private _purchasedPreSaleTokens;

    // mapping pending rewards
    mapping (address => uint256) private _pendingSeedSaleTokens;
    mapping (address => uint256) private _pendingPrivateSaleTokens;
    mapping (address => uint256) private _pendingPrivateSale2Tokens;
    mapping (address => uint256) private _pendingPresaleTokens;

    // mapping claim amount of tokens at TGE events.
    mapping (address => uint256) private _claimedTGE1Tokens;
    mapping (address => uint256) private _claimedTGE2Tokens;
    mapping (address => uint256) private _claimedTGE3Tokens;
    mapping (address => uint256) private _claimedTGE4Tokens;

    // mapping purchased tokens in terms of USDT (Stablecoin)
    mapping (address => uint256) private _purchasedS1;
    mapping (address => uint256) private _purchasedS2;
    mapping (address => uint256) private _purchasedS3;
    mapping (address => uint256) private _purchasedS4;

    // other mapping
    mapping (address => uint256) private _totalTokenPurchased;
    mapping (address => uint256) private _tokensRemainToClaim;
    mapping (address => uint256) private _purchasedAmount;
    mapping (address => uint256) private _personalRelease;
    mapping (address => uint256) private _lastClaim;
    mapping (address => uint256) private _claimed;

    // map address to bool
    mapping (address => bool) private _isWhitelisted;
     mapping (address => bool) private _didLastClaim;
    mapping (address => bool) private _didClaim;
    mapping (IERC20 => bool) private _tokenWhitelisted;
    mapping (IERC20 => bool) private tokenWithDecimals;
    mapping (IERC20 => uint256) private howManyDecimalsMissing;

    // map address to string
    mapping (address => string) private _whereDidHeBuy;

    /* EVENTS */ 

    event _contribute(uint256 amount);
    event _claim(uint256 amount, uint256 when);



    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // ERC20 
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // ERC20
    IERC20 BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53); // ERC20
    IERC20 BEC;


    bool private _isLive;
    uint256 private _actualSale = 0;
    bool private _initialized;
    bool private notContract = false;

    uint256 private TGE;
    uint256 private biWeekly = 500; // 1209600

    // total amount contributed in different sales.
    uint256 private _contributedsale1;
    uint256 private _contributedsale2;
    uint256 private _contributedsale3;
    uint256 private _contributedsale4;


    bool private _forcedRate = false;
    bool private _lastBuys = false;
    uint256 private _forcedRateuint = 0;
    uint256 private MIN = 1 * 10**18; // 50
    uint256 private MAX = 100_000 * 10**18;
    address private liquidity = address(this); // 0x86720518b3714aC7267983Ca3D392c6db7AA5C1F
    


    // hardcap for each sale in (USD)
    uint256 private HardCapSale1 = 939_130;
    uint256 private HardCapSale2 = 1_739_130;
    uint256 private HardCapSale3 = 2_173_913;
    uint256 private HardCapSale4 = 5_147_826;


    constructor() {
        _tokenWhitelisted[USDT] = true;
        _tokenWhitelisted[USDC] = true;
        _tokenWhitelisted[BUSD] = true;
        tokenWithDecimals[USDT] = true;
        tokenWithDecimals[USDC] = true;
        howManyDecimalsMissing[USDT] = 12;
        howManyDecimalsMissing[USDC] = 12;

    }

    function initalizeContract(address newToken) external onlyOwner {
        require(!notContract,"Already initialized");
        BEC = IERC20(newToken);
        notContract = true;
    }

    function checkRate() internal view returns(uint256) {

        uint256 _rate;

        if(checkSale() == 1) { _rate = 47_916_666_706_600_000_000; }
        if(checkSale() == 2) { _rate = 43_124_999_994_600_000_000; }
        if(checkSale() == 3) { _rate = 34_500_000_055_200_000_000; }
        if(checkSale() == 4) { _rate = 29_138_513_496_300_000_000; } 
        if(_forcedRate) {_rate = _forcedRateuint;}

        return _rate;
        
    }

    function viewRate() external view returns(uint256) {
        return checkRate() / 10**15;
    }

    function setForcedRate(bool use, uint256 rate) external onlyOwner {
        _forcedRateuint = rate;
        _forcedRate = use;
    }

    function initialize(bool isTGENow, uint256 _TGE) external onlyOwner initializer {
        if(isTGENow) {  TGE = block.timestamp; } else {TGE = _TGE;}
        _initialized = true;
    }

    function setIsLive() external onlyOwner {
        _isLive = true;
    }

    function changeMinAndMaxContribute(uint256 _min, uint256 _max) external onlyOwner {
        MIN = _min * 10**18;
        MAX = _max * 10**18;
    }

    function changeLiquidityAddress(address newLiquidity) external onlyOwner {
        liquidity = newLiquidity;
    }

    function minAndMaxContribute(address holder, uint256 amount) internal {
    if(checkSale() == 1) {
        require(_purchasedS1[holder] + amount <= MAX,"Amount exceed max contribution");
        require(amount >= MIN || _lastBuys,"Amount does not meet min contribution criteria"); }

    if(checkSale() == 2) {
        require(_purchasedS2[holder] + amount <= MAX,"Amount exceed max contribution");
        require(amount >= MIN || _lastBuys,"Amount does not meet min contribution criteria"); }

    if(checkSale() == 3) {
        require(_purchasedS3[holder] + amount <= MAX,"Amount exceed max contribution");
        require(amount >= MIN || _lastBuys,"Amount does not meet min contribution criteria"); }

    if(checkSale() == 4) {
        require(_purchasedS4[holder] + amount <= MAX,"Amount exceed max contribution");
        require(amount >= MIN || _lastBuys,"Amount does not meet min contribution criteria"); }
        addContribute(amount);
    }

    function checkHardCap(uint256 amount) internal {
        if(checkSale() == 1) {_contributedsale1 = _contributedsale1 + amount; require(_contributedsale1 <= HardCapSale1 * 10**18,"Hard cap reached");}
        if(checkSale() == 2) {_contributedsale2 = _contributedsale2 + amount; require(_contributedsale2 <= HardCapSale2 * 10**18,"Hard cap reached");}
        if(checkSale() == 3) {_contributedsale3 = _contributedsale3 + amount; require(_contributedsale3 <= HardCapSale3 * 10**18,"Hard cap reached");}
        if(checkSale() == 4) {_contributedsale4 = _contributedsale4 + amount; require(_contributedsale4 <= HardCapSale4 * 10**18,"Hard cap reached");}
    }

    function setLastBuy(bool yesno) external onlyOwner {
        _lastBuys = yesno;
    }

    function addContribute(uint256 amount) internal {
        if(checkSale() == 1) _purchasedS1[msg.sender] += amount;
        if(checkSale() == 2) _purchasedS2[msg.sender] += amount;
        if(checkSale() == 3) _purchasedS3[msg.sender] += amount;
        if(checkSale() == 4) _purchasedS4[msg.sender] += amount;
    }

    function setTokenDecimals(address token, uint256 __decimals) external onlyOwner {
        IERC20 Token = IERC20(token);
        howManyDecimalsMissing[Token] = __decimals;
    }

    function setTokenBoolDecimals(address token, bool yesno) external onlyOwner {
        IERC20 Token = IERC20(token);
        tokenWithDecimals[Token] = yesno;
    }


    function contribute(address token, uint256 amount) external {
        IERC20 Token = IERC20(token);
        require(_tokenWhitelisted[Token],"Token not whitelisted");
        require(_isLive,"Sale is not live");
        require(amount > 0 ,"Amount should be greater than 0");

        Token.safeTransferFrom(msg.sender, address(this), amount); // transfer amount to smart contract. 

        automaticTransfer(token, amount);

        if(tokenWithDecimals[Token]) { amount = amount * 10**howManyDecimalsMissing[Token];}

        checkHardCap(amount);
        minAndMaxContribute(msg.sender, amount);

        if(checkSale() > 0 && checkSale() <= 4) {  writeTokens(msg.sender, amount);  } else { revert("Sale ID not valid"); }

        
        _whereDidHeBuy[msg.sender] = "User purchased token from the official smart contract.";
        _purchasedAmount[msg.sender] += amount;
        _isWhitelisted[msg.sender] = true;


        emit _contribute(amount);
    }

    function automaticTransfer(address token, uint256 amount) internal {
        IERC20 Token = IERC20(token);
        
        if(amount > 0) { Token.safeTransfer(owner(), amount / 100 * 60);
        if(liquidity != address(this)) {Token.safeTransfer(liquidity, amount / 100 * 40);} }

    }

    function writeTokens(address holder, uint256 amount) internal {
        uint256 temp1; uint256 temp2; uint256 temp3; uint256 temp4;
        if(checkSale() == 1) { _purchasedSEEDSALETokens[holder] += checkRate() * amount / 10**18; temp1 = checkRate() * amount / 10**18; }
        if(checkSale() == 2) { _purchasedPrivateSaleTokens[holder] += checkRate() * amount / 10**18 ; temp2 = checkRate() * amount / 10**18; }
        if(checkSale() == 3) { _purchasedPrivateSale2Tokens[holder] += checkRate() * amount / 10**18; temp3 = checkRate() * amount / 10**18;}
        if(checkSale() == 4) { _purchasedPreSaleTokens[holder] += checkRate() * amount / 10**18; temp4 = checkRate() * amount / 10**18;}

        _totalTokenPurchased[holder] += temp1 + temp2 + temp3 + temp4;
        _tokensRemainToClaim[holder] = _totalTokenPurchased[holder];
    }

    function checkReleaseAll() internal view returns (bool){
        return !notClaimed() && block.timestamp >= TGE + 18 * biWeekly;
    }

    function releaseAll(bool one, bool second, bool third, bool fourth) internal {
        if(one) {_pendingPresaleTokens[msg.sender] = _purchasedPreSaleTokens[msg.sender];}
        if(second) {_pendingPrivateSale2Tokens[msg.sender] = _purchasedPrivateSale2Tokens[msg.sender];}
        if(third) {_pendingPrivateSaleTokens[msg.sender] = _purchasedPrivateSaleTokens[msg.sender];}
        if(fourth) {_pendingSeedSaleTokens[msg.sender] = _purchasedSEEDSALETokens[msg.sender];}
    }


    function notClaimed() internal view returns (bool) {
        return _didClaim[msg.sender];
    }

    function whatUnlockPhaseWeAre() public view returns (uint256) {
        uint256 _phase;
        if(block.timestamp < TGE) {  _phase = 0; }
        if(block.timestamp >= TGE + 1 * biWeekly) { _phase = 1; }
        if(block.timestamp >= TGE + 2 * biWeekly) { _phase = 2; }
        if(block.timestamp >= TGE + 3 * biWeekly) { _phase = 3; }
        if(block.timestamp >= TGE + 4 * biWeekly) { _phase = 4; }
        if(block.timestamp >= TGE + 5 * biWeekly) { _phase = 5; }
        if(block.timestamp >= TGE + 6 * biWeekly) { _phase = 6; }
        if(block.timestamp >= TGE + 7 * biWeekly) { _phase = 7; }
        if(block.timestamp >= TGE + 8 * biWeekly) { _phase = 8; }
        if(block.timestamp >= TGE + 9 * biWeekly) { _phase = 9; }
        if(block.timestamp >= TGE + 10 * biWeekly) { _phase = 10; }
        if(block.timestamp >= TGE + 11 * biWeekly) { _phase = 11; }
        if(block.timestamp >= TGE + 12 * biWeekly) { _phase = 12; }
        if(block.timestamp >= TGE + 13 * biWeekly) { _phase = 13; }
        if(block.timestamp >= TGE + 14 * biWeekly) { _phase = 14; }
        if(block.timestamp >= TGE + 15 * biWeekly) { _phase = 15; }
        if(block.timestamp >= TGE + 16 * biWeekly) { _phase = 16; }
        if(block.timestamp >= TGE + 17 * biWeekly) { _phase = 17; }
        if(block.timestamp >= TGE + 18 * biWeekly) { _phase = 18; }
        if(TGE == 0) { _phase = 0; }
        return _phase;
    }

    function checkHowManyTokensAreLocked(bool lastclaim, uint256 id, address holder) external view returns(uint256){
        uint256 tokensLocked;
        if(id == 4) { if(lastclaim) {tokensLocked = _purchasedPreSaleTokens[holder] / 100 * 15;} else { tokensLocked = _purchasedPreSaleTokens[holder] / 100 * 20; } }
        if(id == 3) { if(lastclaim) {tokensLocked = _purchasedPrivateSale2Tokens[holder] / 100 * 20;} else { tokensLocked = _purchasedPrivateSale2Tokens[holder] / 100 * 15; } }
        if(id == 2) { if(lastclaim) {tokensLocked = _purchasedPrivateSaleTokens[holder] / 100 * 15;} else { tokensLocked = _purchasedPrivateSaleTokens[holder] / 100 * 10; } }
        if(id == 1) {  tokensLocked = _purchasedSEEDSALETokens[holder] / 100 * 5;  }
        return tokensLocked;
    }

    function standardUnlock() internal {
        if(whatUnlockPhaseWeAre() > 3) { releaseAll(true,false,false,false); } else {_pendingPresaleTokens[msg.sender] = (_purchasedPreSaleTokens[msg.sender] / 100 * ((20) * whatUnlockPhaseWeAre()) + _claimedTGE4Tokens[msg.sender]);}
        if(whatUnlockPhaseWeAre() >= 5) { releaseAll(true,true,false,false); } else {_pendingPrivateSale2Tokens[msg.sender] = (_purchasedPrivateSale2Tokens[msg.sender] / 100 * ((15) * whatUnlockPhaseWeAre()) + _claimedTGE3Tokens[msg.sender]);}
        if(whatUnlockPhaseWeAre() >= 8) { releaseAll(true,true,true,false); } else {_pendingPrivateSaleTokens[msg.sender] = (_purchasedPrivateSaleTokens[msg.sender] / 100 * ((10) * whatUnlockPhaseWeAre()) + _claimedTGE2Tokens[msg.sender]);}
        if(whatUnlockPhaseWeAre() >= 18) { releaseAll(true,true,true,true); _didLastClaim[msg.sender] = true; } else {_pendingSeedSaleTokens[msg.sender] = (_purchasedSEEDSALETokens[msg.sender] / 100 * ((5) * whatUnlockPhaseWeAre()) + _claimedTGE1Tokens[msg.sender]);}
    }

    function checkVesting() internal {
        if(checkReleaseAll()) { releaseAll(true,true,true,true); _didLastClaim[msg.sender] = true; } else {

        standardUnlock();

        if(!notClaimed() && block.timestamp >= TGE) {
            claimTGE();
        }
    }
    }

    function claimTGE() internal {
        _pendingSeedSaleTokens[msg.sender] = _purchasedSEEDSALETokens[msg.sender] / 100 * 10;
        _pendingPrivateSaleTokens[msg.sender] = _purchasedPrivateSaleTokens[msg.sender] / 100 * 15;
        _pendingPrivateSale2Tokens[msg.sender] = _purchasedPrivateSale2Tokens[msg.sender] / 100 * 20;
        _pendingPresaleTokens[msg.sender] = _purchasedPreSaleTokens[msg.sender] / 100 * 25;
        _claimedTGE1Tokens[msg.sender] = _pendingSeedSaleTokens[msg.sender];
        _claimedTGE2Tokens[msg.sender] = _pendingPrivateSaleTokens[msg.sender];
        _claimedTGE3Tokens[msg.sender] = _pendingPrivateSale2Tokens[msg.sender];
        _claimedTGE4Tokens[msg.sender] = _pendingPresaleTokens[msg.sender];
    }

    function claimedRewards(address account, uint256 ID) external view returns (uint256) {
        uint256 _claimedd;
        if (ID == 1) { _claimedd = _pendingSeedSaleTokens[account];}
        if (ID == 2) { _claimedd = _pendingPrivateSaleTokens[account];}
        if (ID == 3) { _claimedd = _pendingPrivateSale2Tokens[account];}
        if (ID == 4) { _claimedd = _pendingPresaleTokens[account];}

        return _claimedd;
    }

    function claim() external {
        require(!_didLastClaim[msg.sender],"No more to claim");
        require(_isLive,"Sale is not live");
        require(_isWhitelisted[msg.sender],"Did not contribute");
        require(_initialized,"Not initalized");
        checkVesting();

        _personalRelease[msg.sender] = _pendingPresaleTokens[msg.sender] + _pendingPrivateSale2Tokens[msg.sender] + _pendingPrivateSaleTokens[msg.sender] + _pendingSeedSaleTokens[msg.sender];
        _personalRelease[msg.sender] -= _claimed[msg.sender];


        uint256 tokens = _personalRelease[msg.sender];
        require( _tokensRemainToClaim[msg.sender] >= tokens,"Cannot claim more");
        _tokensRemainToClaim[msg.sender] -= tokens;


        require(tokens > 0,"Amount pending should be greater than 0"); 


        BEC.transfer(msg.sender, tokens);

        
        _claimed[msg.sender] += tokens;
        _lastClaim[msg.sender] = block.timestamp; 
        _didClaim[msg.sender] = true;

        emit _claim(tokens, _lastClaim[msg.sender]);
    }

    function whenYouDidYourLastClaim(address account) external view returns(uint256) {
        return _lastClaim[account];
    }

    function checkSale() internal view returns(uint256) {
        require(_isLive,"Sale is not live");
        return _actualSale;
    }

    function whitelistToken(address token, bool yesno) external onlyOwner {
        IERC20 Token = IERC20(token);
        _tokenWhitelisted[Token] = yesno; 
    }

    function saleOngoing() external view returns(uint256) {
        return checkSale();
    }

    function setActualSale(uint256 id) external onlyOwner {
        require(id <= 4);
        _actualSale = id;
    }

    function removeTokens(address token, uint256 amount) external onlyOwner {
        IERC20 Token = IERC20(token);
        Token.safeTransfer(msg.sender, amount);
    }

    function tokensPurchased(uint256 ID, address account) external view returns(uint256) {
        uint256 tokens;
        if (ID == 1) { tokens = _purchasedSEEDSALETokens[account];}
        if (ID == 2) { tokens = _purchasedPrivateSaleTokens[account];}
        if (ID == 3) { tokens = _purchasedPrivateSale2Tokens[account];}
        if (ID == 4) { tokens = _purchasedPreSaleTokens[account];}
        return tokens;
    }

    function manualBuy(bool auto18zeros, string memory whereDidHeBuy, address holder, uint256 amount) external onlyOwner { // For purchases FIAT
        require(_isLive,"Sale is not live");
        require(amount > 0 ,"Amount should be greater than 0");


        if(auto18zeros) {amount = amount * 10**18;} else {  amount = amount;  }

        
        writeTokens(holder, amount); _whereDidHeBuy[holder] = whereDidHeBuy; checkHardCap(amount); minAndMaxContribute(holder, amount);


        _isWhitelisted[holder] = true;
        _purchasedAmount[holder] += amount;

    }

    function paymentMethod(address holder) external view returns(string memory) {
        return _whereDidHeBuy[holder];
    }

    function showPurchasedAmount(address holder) external view returns (uint256) {
        return _purchasedAmount[holder] / 10**18;
    }

    function showClaimedAmount(address holder) external view returns (uint256) {
        return _claimed[holder];
    }

    function showUnreleasedTotalAmount(address holder) external view returns (uint256) {
        return _tokensRemainToClaim[holder];
    }

    function canClaimNow() external view returns(bool) {
        return block.timestamp >= TGE && TGE > 2;
    }

    function whenIsTheTge() external view returns(uint256) {
        return TGE;
    }

    function hardcapCheck() external view returns(uint256) {
        uint256 _return; 
        if(checkSale() == 1) { _return = HardCapSale1 * 10**18 - _contributedsale1;}
        if(checkSale() == 2) { _return = HardCapSale2 * 10**18 - _contributedsale2;}
        if(checkSale() == 3) { _return = HardCapSale3 * 10**18 - _contributedsale3;}
        if(checkSale() == 4) { _return = HardCapSale4 * 10**18 - _contributedsale4;}
        _return = _return / 10**18;
        return _return;
    }

    function isThisTokenWhitelisted(address token) external view returns(bool) {
        IERC20 Token = IERC20(token);
        return _tokenWhitelisted[Token];
    }

}