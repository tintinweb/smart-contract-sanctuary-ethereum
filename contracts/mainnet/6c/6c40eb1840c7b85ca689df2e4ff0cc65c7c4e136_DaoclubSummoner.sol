/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.7;

//import "hardhat/console.sol";



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
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

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



contract ReentrancyGuard {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

contract Daoclub is ReentrancyGuard, IERC20 {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    

   // ISwapRouter public swapRouter;

    
    /* erc20 param */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    /* erc20 param */

    /*遍历成员*/
    mapping(address => bool) private _inserted;
    address[] public _members;

    //todo 如何获取合约的所有代币
    //address[] public _tokenContracts;

    /* daoclub param */
    address private _owner;
    address private _summonerAddress;
    bool private _initialized;
    uint256 public _initTimestamp;
    uint8 public _daoStatus; //0: Fundraising,1: Fundraising completed operation,2: Liquidation in progress,3: Liquidation completed
    
    mapping(address => uint8) public _voteResult; //（0未投票 1yes 2no）
    uint256 public _yesShares;
    uint256 public _noShares;
    
    
    uint256 public _totalFund;
    uint256 public _actualFund;
    uint256 public _miniOffering;
    uint256 public _amountOfGrandTotalLiquidation;
    uint8 private _managementFee;
    uint8 private _profitDistribution;
    uint256 public _periodTimestamp;
    uint256 private _duration;
    string public _targetSymbol;  //ETH/USDT/USDC
    IERC20 public _targetToken;
    //IWETH9 private _targetWeth;
    uint256 public _receivableManagementFee;
    bool public _receivedManagementFee;
    /* daoclub param */

    struct InitUint8 {
        uint8  managementFee;
        uint8  profitDistribution;
        uint8  daoType;
    }



    /*v1.1*/
    uint8 public _daoType;  //0: active--close, 1:active--open
    uint256 public _exchangeRate; //  totalSupply/actaulFund
    mapping(address => uint256) public _aveCost;

    struct Subscription {
        address _member;
        uint256 _buyAmount; 
        uint256 _buyMaxNetValue; 
    }

    struct Redemption {
        address _member;
        uint256 _sellShares; 
        uint256 _sellMinNetValue; 
    }

    mapping(uint256 => Subscription) public _subscriptionMap;
    mapping(uint256 => Redemption) public _redemptionMap;
    uint256 public _lockAmount;
    /*v1.1*/


    /***********
    EVENT
    ***********/
    event BuyToken(address indexed buyer, uint256 amount);
    event FundraisingCompleted();
    event SubmitProposal(address indexed daoAddress, address indexed Submitter);
    event SubmitVote(address indexed daoAddress, address indexed voter, uint8 vote, uint256 shares);
    event ProposalSucceeded(address indexed daoAddress, address voter);
    event ProposalFailed(address indexed daoAddress, address voter);
    event LiquidationCompleted(address indexed daoAddress, address memberAddress, uint256 amount, uint256 totalAmount);

    //v1.1
    event SubscriptionSubmit();
    event SubscriptionApprove(uint256 sid, uint256 shares);
    event RedemptionSubmit(uint256 sid, uint256 aveCost);
    event RedemptionApprove(uint256 sid, uint256 payAmount, uint256 aveCost);


    /********
    MODIFIERS
    ********/
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyMember {
        require(_balances[msg.sender] > 0, "Daoclub ::onlyMember - not a member");
        _;
    }

    modifier onlyGpAndLp {
        require(_balances[msg.sender] > 0 || _owner == msg.sender, "Daoclub :: onlyGpAndLp");
        _;
    }

    modifier possibleToByToken {
        require(daoStatus() == 0, "Daoclub Can not buy: status error");
        require(block.timestamp < _periodTimestamp, "Daoclub Can not buy: Time has expired");
        require(getBalance() <= _totalFund, "Daoclub Can not buy: enough to raise");
        _;
    }

    receive() external payable {
    }


    fallback() external payable {
    }

    function daoStatus() public view returns(uint8 daoStatus_) {
        if(_daoStatus == 0 && block.timestamp > _periodTimestamp) {
            daoStatus_ = 1;
        }else {
            daoStatus_ = _daoStatus;
        }
    }

    /**测试完了记得删除**/
    // function resetInitTimeStamp(uint256 initTimestamp) external {
    //     _initTimestamp = initTimestamp;
    // }


    function init(
        address summoner,
        string memory tokenSymbol,
        uint256 totalSupply_,
        uint256 totalFund,
        uint256 miniOffering,
        InitUint8 memory initUint8,
        uint256  periodTimestamp,
        uint256  duration,
        address summonerAddress,
        string memory targetSymbol
    ) external {
        require(_initialized == false, "Daoclub: cannot be initialized repeatedly ");
        _initialized = true;
        _owner = summoner;
        _daoStatus = 0;
        _name = tokenSymbol;
        _symbol = tokenSymbol;
        _miniOffering = miniOffering;
        _managementFee = initUint8.managementFee;
        _profitDistribution = initUint8.profitDistribution;
        _daoType = initUint8.daoType;
        _totalFund = totalFund;
        //铸币
        _mint(address(this), totalSupply_);
        _targetSymbol = targetSymbol;
        if (compareStr(targetSymbol, "USDT")) {
            _targetToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); //USDT主网合约地址0xdAC17F958D2ee523a2206206994597C13D831ec7 测试地址0xB61d1dB83E6478e3daDf22caEb79D1ceC613ab0e
        } else if(compareStr(targetSymbol, "USDC")) {
            _targetToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);  //USDC主网合约地址0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        } else {
            //_targetToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  //WETH合约地址 rinnkby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
            //_targetWeth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);   //WETH合约地址 rinnkby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
        }
        _periodTimestamp = periodTimestamp;
        _duration = duration;
        _summonerAddress = summonerAddress;
        _initTimestamp = block.timestamp;
        //明确exchangeRate
        _exchangeRate = _totalSupply.div(_totalFund);
        //swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); //SwapRouter合约地址
    }
    


    function withdraw(uint256 amount) onlyOwner external {
        require(daoStatus() == 1, "Daoclub: Can only be withdrawn after the fundraising is completed");
        require(amount <= getBalance(), "Daoclub: The withdrawal amount cannot be greater than the dao balance");
        //burn 
        fundraisingCompleted();

        if(isETH()) {
            payable(_summonerAddress).transfer(amount);
        }else {
            _targetToken.safeTransfer(_summonerAddress, amount);
        }
    }



    function buyTokenByETH() possibleToByToken external payable {
        require(isETH(), "Daoclub: target token is not ETH");
        require(address(this).balance <= _totalFund, "Can not buy: enough to raise");
        require(daoStatus() == 0, "Daoclub: status can not buy");
        require(msg.value >= _miniOffering, "Daoclub: miniOffering are not met");
        _actualFund += msg.value;
        //send token
        _transfer(address(this), msg.sender, _totalSupply.mul(msg.value).div(_totalFund));

        emit BuyToken(msg.sender, msg.value);
        
        _aveCost[_msgSender()] = 10000;
        fundraisingCompleted();
    }


    function buyTokenByUSDTorUSDC(uint256 amount) possibleToByToken external {
        require(!isETH(), "Daoclub: target token is ETH");
        require(_targetToken.balanceOf(address(this)) + amount <= _totalFund, "Can not buy: enough to raise");
        require(daoStatus() == 0, "Daoclub: status can not buy");
        require(amount >= _miniOffering, "Daoclub: miniOffering are not met");
        
        
        
        
        
        //_targetToken.transferFrom(msg.sender, address(this), amount); 
        _targetToken.safeTransferFrom(msg.sender, address(this), amount);
        
        _actualFund += amount;
        
        //send token
        _transfer(address(this), msg.sender, _totalSupply.mul(amount).div(_totalFund));
        

        emit BuyToken(msg.sender, amount);
        _aveCost[_msgSender()] = 10000;
        fundraisingCompleted();
    }

    //募集结束
    function fundraisingCompleted() onlyGpAndLp public {
        if(block.timestamp > _periodTimestamp || _actualFund == _totalFund || _totalFund.sub(_actualFund) < _miniOffering) {
            _daoStatus = 1;
            //销毁剩余代币
            if(balanceOf(address(this)) > 0) {
                _burn(address(this), balanceOf(address(this)));
            }
            emit FundraisingCompleted();
        }
    }



    //发起提案
    function submitProposal() onlyGpAndLp external {
        fundraisingCompleted();
        require(daoStatus() == 1, " Proposal not allowed in current status ");
        _daoStatus = 2;
        _yesShares = 0;
        _noShares = 0;
        for(uint i = 0; i < _members.length; i++ ) {
            _voteResult[_members[i]] = 0;
        }
        emit SubmitProposal(address(this), msg.sender);
    }


    //提交投票
    function submitVote(uint8 vote) onlyMember external {
        require(daoStatus()== 2, "no Proposal");
        //判断是否投过票
        if(_voteResult[msg.sender] == 0) {
            //没投过
            _voteResult[msg.sender] = vote;
            if(vote == 1) {
                _voteYes();
            }else {
                _voteNo();
            }    
        }else {
            require(_voteResult[msg.sender] != vote, "Can't vote again");
            if(_voteResult[msg.sender] == 1) {
                _yesShares -= _balances[msg.sender];
                _voteNo();
            }else {
                _noShares -= _balances[msg.sender];
                _voteYes();
            }
        }
        
        emit SubmitVote(address(this), msg.sender, vote, _balances[msg.sender].mul(100).div(_totalSupply));

    }

    function _voteYes() internal { 
        _yesShares += _balances[msg.sender];
        if(_yesShares >= _totalSupply.mul(7).div(10)) {
            //投票成功 ， 触发清算， xx时间之后 自动清算 但是我不能在这sleep啊
            //状态变更 投票通过
            _daoStatus = 3;
            //计算应收管理费
            //首先计算管理天数
            uint256 managementDays_ = block.timestamp.sub(_initTimestamp).div(24 * 3600);
            if(managementDays_ > _duration) {
                managementDays_ = _duration;
            }
            _receivableManagementFee = _actualFund.mul(_managementFee).div(36500).mul(managementDays_);
            _receivedManagementFee = false;
            

            emit ProposalSucceeded(address(this), msg.sender);
        }
    }

    function _voteNo() internal {
        _noShares += _balances[msg.sender];
        if(_noShares >= _totalSupply.mul(3).div(10)) {
            //本次提案失败，DAO状态回退
            _daoStatus = 1;
            emit ProposalFailed(address(this), msg.sender);
        }
    }

    


    function isETH() internal view returns(bool) {
        return compareStr(_targetSymbol, "ETH");
    }


    // function sellToken() internal returns (uint256 amountOut){
    //     //合约中的币 怎么获取 如果能获取
    //     //遍历目标币合约
    //     for(uint8 i = 0; i< _tokenContracts.length; i++) {
    //         //通过UNISWAP卖出币收回targetSymbol;
    //         // 将资产授权给 swapRouter
    //         TransferHelper.safeApprove(_tokenContracts[i], address(swapRouter), IERC20(_tokenContracts[i]).balanceOf(address(this)));
    //         // amountOutMinimum 在生产环境下应该使用 oracle 或者其他数据来源获取其值
    //         ISwapRouter.ExactInputSingleParams memory params =
    //             ISwapRouter.ExactInputSingleParams({
    //                 tokenIn: _tokenContracts[i],
    //                 tokenOut: address(_targetToken),
    //                 fee: 3000,
    //                 recipient: address(this),
    //                 deadline: block.timestamp,
    //                 amountIn: IERC20(_tokenContracts[i]).balanceOf(address(this)),
    //                 amountOutMinimum: 0,
    //                 sqrtPriceLimitX96: 0
    //             });

    //         amountOut = swapRouter.exactInputSingle(params);

    //     }
    //     if(isETH()) {
    //         //把weth拆封变成eth
    //         _targetWeth.withdraw(_targetToken.balanceOf(address(this)));
    //     }
        

    // }

    
    //清算
    function liquidate() onlyGpAndLp external {
        require(daoStatus() == 3, "Daoclub: yes shares less than 70%");
        //获取结算资金
        uint256 amountOfThisLiquidation_ = getBalance();
        if(!_receivedManagementFee) {    
            require(amountOfThisLiquidation_ > _receivableManagementFee, "Daoclub: Insufficient amount");
            if(isETH()) {
                payable(_summonerAddress).transfer(_receivableManagementFee);
            }else {
                _targetToken.safeTransfer( _summonerAddress, _receivableManagementFee);
            }
            _receivedManagementFee = true;
            amountOfThisLiquidation_ = amountOfThisLiquidation_.sub(_receivableManagementFee);

        }

        //先来一波卖币逻辑
        //sellToken();

        
        uint256 gpProfit_ = 0;
        if((amountOfThisLiquidation_ + _amountOfGrandTotalLiquidation) > _actualFund) {
            //分利润
            uint256 profit_;
            if(_amountOfGrandTotalLiquidation < _actualFund) {
                profit_ = amountOfThisLiquidation_ + _amountOfGrandTotalLiquidation - _actualFund;
            }else {
                profit_ = amountOfThisLiquidation_;
            }
            //先分gp
            gpProfit_ = profit_.mul(_profitDistribution).div(100);
            if(isETH()) {
                payable(_summonerAddress).transfer(gpProfit_);
            }else {
                _targetToken.safeTransfer( _summonerAddress, gpProfit_);
            }
            amountOfThisLiquidation_ -= gpProfit_;
            //emit LiquidationCompleted(address(this), _owner, gpProfit_, _fundShare());
        }
        for(uint i = 0; i < _members.length; i++ ) {
            if(_balances[_members[i]] > 0) {
                uint256 distributeProfit_ = amountOfThisLiquidation_.mul(_balances[_members[i]]).div(_totalSupply);
                if(isETH()) {
                    payable(_members[i]).transfer(distributeProfit_);
                }else {
                    _targetToken.safeTransfer(_members[i], distributeProfit_);
                }
                emit LiquidationCompleted(address(this), _members[i], distributeProfit_, _fundShare(_members[i]));
            }
        }
        _amountOfGrandTotalLiquidation = _amountOfGrandTotalLiquidation + amountOfThisLiquidation_ + gpProfit_;
        

        
    }



    function getBalance() public view returns (uint256) {
        if(isETH()) {
            return address(this).balance.sub(_lockAmount);
        }else {
            return _targetToken.balanceOf(address(this)).sub(_lockAmount);
        }
    }


    //v1.1
    //申购通过eth
    function subscriptionSubmitByEth(uint256 sid, uint256 maxNetValue) external payable {
        require(_daoType == 1, "Daoclub: type error");
        require(isETH(), "Daoclub: target token is not ETH");
        Subscription storage subscription = _subscriptionMap[sid];
        require(subscription._member == address(0), "Daoclub: error sid");
        subscription._buyAmount = msg.value;
        subscription._buyMaxNetValue = maxNetValue;
        subscription._member = _msgSender();
        _lockAmount += msg.value;
    }

    //申购通过usd
    function subscriptionSubmitByUSD(uint256 sid, uint256 buyAmount, uint256 maxNetValue) external {
        require(_daoType == 1, "Daoclub: type error");
        require(!isETH(), "Daoclub: target token is ETH");
        Subscription storage subscription = _subscriptionMap[sid];
        subscription._buyAmount = buyAmount;
        subscription._buyMaxNetValue = maxNetValue;
        subscription._member = _msgSender();
        _lockAmount += buyAmount;
        _targetToken.safeTransferFrom(msg.sender, address(this), buyAmount);
    }

    //取消申购
    function subscriptionCancel(uint256 sid) external {
        require(_daoType == 1, "Daoclub: type error");
        Subscription storage subscription = _subscriptionMap[sid];
        require(_msgSender() == subscription._member, "Daoclub: not allow" );
        
        //退款
        if(isETH()) {
            payable(subscription._member).transfer(subscription._buyAmount);
        }else {
            _targetToken.safeTransfer(subscription._member, subscription._buyAmount);
        }
        _lockAmount = _lockAmount.sub(subscription._buyAmount);
        subscription._buyAmount = 0;
        subscription._buyMaxNetValue = 0;
        
        
    }

    //申购批准
    function subscriptionApprove(uint256[] memory sid, uint256[] memory confirmNetValue) onlyOwner external {
        for(uint i = 0; i < sid.length; i++ ) {
            subscriptionApproveOne(sid[i], confirmNetValue[i]);
        }
    }


    function subscriptionApproveOne(uint256 sid, uint256 confirmNetValue) onlyOwner internal {
        require(_daoType == 1, "Daoclub: type error");
        Subscription storage subscription = _subscriptionMap[sid];
        require(confirmNetValue <= subscription._buyMaxNetValue, "Daoclub: confirm NetValue to high");
        _lockAmount = _lockAmount.sub(subscription._buyAmount);
        //计算份额
        uint256 shares = subscription._buyAmount.div(confirmNetValue.div(10000)).mul(_exchangeRate);
        _mint(subscription._member, shares);
        //重新计算平均成本

        _aveCost[subscription._member] = (_aveCost[subscription._member].mul(_balances[subscription._member] - shares) + confirmNetValue.mul(shares)).div(_balances[subscription._member]);
        emit SubscriptionApprove(sid, shares);

    }


    //赎回申请
    function redemptionSubmit(uint256 sid, uint256 sellShares, uint256 sellMinNetValue) onlyMember external {
        require(_daoType == 1, "Daoclub: type error");
        Redemption storage redemption = _redemptionMap[sid];
        require(redemption._member == address(0), "Daoclub: error sid");
        require(sellShares <= _balances[_msgSender()], "Daoclub: sold too much");
        redemption._member = _msgSender();
        redemption._sellShares = sellShares;
        redemption._sellMinNetValue = sellMinNetValue;
        emit RedemptionSubmit(sid, _aveCost[_msgSender()]);
    }

    //赎回取消
    // function redemptionCancel(uint256 sid) onlyMember external {
    //     require(_daoType == 1, "Daoclub: type error");
    //     Redemption storage redemption = _redemptionMap[_msgSender()];
    //     require(redemption._sellShares >= cancelShares, "Daoclub: cancel too much");
    //     redemption._sellShares -= cancelShares;
    // }


    function redemptionApprove(uint256[] memory sid, uint256[] memory confirmNetValue) onlyOwner external {
        for(uint i = 0; i < sid.length; i++ ) {
            redemptionApproveOne(sid[i], confirmNetValue[i]);
        }
    }

    //赎回批准
    function redemptionApproveOne(uint256 sid, uint256 confirmNetValue) onlyOwner internal {
        require(_daoType == 1, "Daoclub: type error");
        Redemption storage redemption = _redemptionMap[sid];
        require(_balances[redemption._member] >= redemption._sellShares, "Daoclub: Not enough shares to redeem");
        require(confirmNetValue >= redemption._sellMinNetValue, "Daoclub: confirm NetValue to low");
        //计算支付金额 (扣除利润分成)
        uint256 payAmount = redemption._sellShares.div(_exchangeRate).mul(confirmNetValue.div(10000));
        if(_aveCost[redemption._member] < confirmNetValue) {
            //利润分成
            //uint256 distributeProfit = payAmount.mul(confirmNetValue.sub(_aveCost[redemption._member]).div(10000)).mul(_profitDistribution).div(100)
            payAmount = payAmount.sub(payAmount.mul(confirmNetValue.sub(_aveCost[redemption._member])).div(confirmNetValue).mul(_profitDistribution).div(100));
        }
        


        require(getBalance()>=payAmount, "Daoclub: DAO does not have enough funds");
        if(isETH()) {
            payable(redemption._member).transfer(payAmount);
        }else {
            _targetToken.safeTransfer( redemption._member, payAmount);
        }
        _burn(redemption._member, redemption._sellShares);

        emit RedemptionApprove(sid, payAmount, _aveCost[redemption._member]);
    }



    
    /* erc20 function */
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual  returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(daoStatus() == 0 || daoStatus() == 1, "The current DAO state cannot be traded");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        if(!_inserted[to]) {
            _inserted[to] = true;
            _members.push(to);
        }
            
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        if(!_inserted[account]) {
            _inserted[account] = true;
            _members.push(account);
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /* erc20 function */



    /* util function */

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str));
    }

    function _checkOwner() internal view virtual {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }

    function _fundShare(address member) internal view returns (uint256) {
        return _actualFund.mul(_balances[member]).div(_totalSupply);
    }

    

    /* util function */
}


/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory { // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract DaoclubSummoner is CloneFactory { 
    
    address public _template;
    address _owner;
    Daoclub private _daoclub; // daoclub contract
    address[] public _summonedDaoclub;
    uint public _daoIdx = 0;
    
    constructor(address template) {
        _template = payable(template);
        _owner = msg.sender;
    }
    
    event SummonComplete(address indexed daoclub, address summoner);
    


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function resetTemplate(address template) onlyOwner external {
        _template = payable(template);
    }
    
     
    function summonDaoclub(
        uint8 daoType,
        string memory tokenSymbol,
        uint256 totalSupply,
        uint256 totalFund,
        uint256 miniOffering,
        uint8  managementFee,
        uint8  profitDistribution,
        uint256  periodTimestamp,
        uint256  duration,
        address summonerAddress,    
        string memory targetSymbol
        
    ) public returns (address) {
        Daoclub.InitUint8 memory initUint8 = Daoclub.InitUint8(managementFee, profitDistribution, daoType);
        _daoclub = Daoclub(payable(createClone(_template)));
        _daoclub.init(
            msg.sender,
            tokenSymbol,
            totalSupply,
            totalFund,
            miniOffering,
            initUint8,
            periodTimestamp,
            duration,
            summonerAddress,
            targetSymbol
        );
        _summonedDaoclub.push(address(_daoclub));
        _daoIdx ++;
       
        emit SummonComplete(address(_daoclub), msg.sender);
        return address(_daoclub);
    }
    
}