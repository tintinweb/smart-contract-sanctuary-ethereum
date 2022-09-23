/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
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
interface IInsuranceDao {
    function insure(uint256 amount, string memory symbol, address lpAddress) external returns (uint256);
    function active() external ;
    function isMember(address lp) external view returns (bool);
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}



contract DaoclubV2 is ReentrancyGuard, IERC20 {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    //rinkinby
    // address public constant USDT = 	0xB61d1dB83E6478e3daDf22caEb79D1ceC613ab0e;
    // address public constant USDC = 	0x0C41477f886F910d285f6d0893780f4D92A8cEE1;
    // address public constant WETH = 	0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant WBTC = 	0x577D296678535e4903D59A4C929B718e1D575e0A;

    //main
    address public constant USDT = 	0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 	0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC = 	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* erc20 param */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /*遍历成员*/
    mapping(address => bool) private _inserted;
    address[] public _members;
    /* erc20 param */
    mapping(address => bool) private _buyed;

    bool private _initialized = false;
    address public _owner;
    string public _targetSymbol;
    uint256 public _totalFund;
    uint256 public _actualFund;
    uint256 public _miniOffering;
    IERC20 public _targetToken;
    address public _summonerAddress;
    uint256 public _collectionDeadline;
    uint256 public _managementDuration;
    uint8 public _expectedRevenue;
    IInsuranceDao public _insuranceDao;


    /***********
    EVENT
    ***********/
    event BuyToken(address indexed buyer, uint256 amount);
    event FundraisingCompleted(address daoAddress, uint256 collectionDeadline);
    event LpRedemption(address indexed lpAddress, uint256 daoAmount, uint256 insrueAmount, uint256 time);
    event GpGoReturn(address daoAddress, uint256 returnAmount);


    modifier possibleToByToken {
        require(daoStatus() == 0, "Daoclub Can not buy: status error");
        require(block.timestamp < _collectionDeadline, "Daoclub Can not buy: Time has expired");
        require(getBalance() <= _totalFund, "Daoclub Can not buy: enough to raise");
        require(!_insuranceDao.isMember(msg.sender), "Daoclub Can not buy: insurance member");
        _;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    receive() external payable {
    }

    fallback() external payable {
    }

    function setCollectionDeadline(uint256 timestamp) public {
        _collectionDeadline = timestamp;
    } 
    
    function init(
        address owner,
        string memory tokenSymbol,
        string memory targetSymbol,
        uint256 totalFund,
        uint256 miniOffering,
        uint8 expectedRevenue,
        uint256 collectionDeadline,
        uint256 managementDuration,
        address summonerAddress
    ) external {
        require(_initialized == false, "Daoclub: cannot be initialized repeatedly ");
        _initialized = true;
        _owner = owner;
        _totalFund = totalFund;
        _miniOffering = miniOffering;
        _name = tokenSymbol;
        _symbol = tokenSymbol;
        _targetSymbol = targetSymbol;
        if (compareStr(targetSymbol, "USDT")) {
            _targetToken = IERC20(USDT); 
        } else if(compareStr(targetSymbol, "USDC")) {
            _targetToken = IERC20(USDC);  
        } else { 
            _targetToken = IERC20(WETH);  
        }
        
        
        
        _collectionDeadline = collectionDeadline;
        _managementDuration = managementDuration;
        _summonerAddress = summonerAddress;
        _expectedRevenue = expectedRevenue;

    }

    function daoStatus() public view returns(uint8 daoStatus_) {
        if(block.timestamp < _collectionDeadline) {
            daoStatus_ = 0;
        } else if(block.timestamp >= _collectionDeadline && block.timestamp < _collectionDeadline + (_managementDuration.mul(86400))) {
            daoStatus_ = 1;
        } else {
            daoStatus_ = 2;
        }
    }

    function getBalance() public view returns (uint256) {
        if(isETH()) {
            return address(this).balance;
        }else {
            return _targetToken.balanceOf(address(this));
        }
    }

    function countToken(uint256 amount) public view returns (uint256) {
        return amount.add(amount.mul(_expectedRevenue).mul(_managementDuration).div(36500));
    } 

    function isETH() internal view returns(bool) {
        return compareStr(_targetSymbol, "ETH");
    }



    function addInsure(address insureDaoAddress, uint256 coverageAmount, uint premium) public {
        require(address(_insuranceDao) == address(0), "Daoclub: Cannot reset insuredao");
        _insuranceDao = IInsuranceDao(payable(insureDaoAddress));
        _mint(insureDaoAddress, coverageAmount.mul(premium).mul(_managementDuration).div(36500));
    }

    function withdraw(uint256 amount) onlyOwner external {
        require(daoStatus() == 1, "Daoclub: Can only be withdrawn after the fundraising is completed");
        require(amount <= getBalance(), "Daoclub: The withdrawal amount cannot be greater than the dao balance");
        fundraisingCompleted();
        _insuranceDao.active();
        if(isETH()) {
            payable(_summonerAddress).transfer(amount);
        }else {
            _targetToken.safeTransfer(_summonerAddress, amount);
        }
    }



    function buyTokenByETH() possibleToByToken external payable {
        require(isETH(), "Daoclub: target token is not ETH");
        require(msg.value >= _miniOffering, "Daoclub: miniOffering are not met");
        buyToken(msg.value);
    }


    function buyTokenByUSDTorUSDC(uint256 amount) possibleToByToken external {
        require(!isETH(), "Daoclub: target token is ETH");
        require(getBalance() + amount <= _totalFund, "Can not buy: enough to raise");
        require(amount >= _miniOffering, "Daoclub: miniOffering are not met");
        _targetToken.safeTransferFrom(msg.sender, address(this), amount);
        buyToken(amount);
    }

    function buyToken(uint256 amount) internal {
        _actualFund += amount;
        _mint(msg.sender, countToken(amount));
        emit BuyToken(msg.sender, amount);
        fundraisingCompleted();
        _buyed[msg.sender] = true;
    }

    //募集结束
    function fundraisingCompleted() public {
        if(_actualFund == _totalFund || _totalFund.sub(_actualFund) < _miniOffering) {
            _collectionDeadline = block.timestamp;
            emit FundraisingCompleted(address(this), _collectionDeadline);
        }
    }

    //LP赎回
    function lpRedemption() public returns(uint256 ){
        require(_buyed[msg.sender], "not buy");
        require(balanceOf(msg.sender) > 0, "not buy");
        require(daoStatus() == 2, "status error");
        uint256 insureAmount;
        uint256 daoAmount;
        if(getBalance() < balanceOf(msg.sender)) {
            daoAmount = getBalance();
            insureAmount = balanceOf(msg.sender).sub(getBalance());
            approve(address(_insuranceDao), insureAmount);
            insureAmount = _insuranceDao.insure(insureAmount, _targetSymbol, msg.sender);
            if(allowance(msg.sender, address(_insuranceDao)) > 0) {
                approve(address(_insuranceDao), 0);
            }
            //保险分配
        }else {
            daoAmount = balanceOf(msg.sender);
            insureAmount = 0;
        }
        pay(msg.sender, daoAmount, insureAmount);
        emit LpRedemption(msg.sender, daoAmount, insureAmount, block.timestamp);
        return daoAmount.add(insureAmount);
    }

    function pay(address lp, uint256 daoAmount, uint256 insureAmount) private {
        if(isETH()) {
            payable(lp).transfer(daoAmount.add(insureAmount));
        }else {
            _targetToken.safeTransfer(lp, daoAmount.add(insureAmount));
        }
        _burn(lp, daoAmount);
    }

    function gpLiquidate() public {
        uint256 total = _totalSupply;
        uint256 balance = getBalance();
        uint256 gpGoReturnAmount = 0;
        for(uint i = 0; i < _members.length; i++ ) {
            if(_balances[_members[i]] > 0 && _members[i] != address(_insuranceDao)) {    
                uint256 distributeAmount_;
                if(balance < total) {
                    distributeAmount_ = balance.mul(_balances[_members[i]]).div(total);
                }else {
                    distributeAmount_ = _balances[_members[i]];
                }
                pay(_members[i], distributeAmount_, 0);
                emit LpRedemption(_members[i], distributeAmount_, 0, block.timestamp);
                if(_insuranceDao.isMember(_members[i])) {
                    gpGoReturnAmount = gpGoReturnAmount.add(distributeAmount_);
                }
            }
        }   
        emit GpGoReturn(address(this), gpGoReturnAmount);     
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
        if(to == address(0)) {
            _burn(owner, amount);    
        } else {
            _transfer(owner, to, amount);
        }
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
        //require(daoStatus() == 0 || daoStatus() == 1, "The current DAO state cannot be traded");

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

    function _burn(address account, uint256 amount) internal   virtual {
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
    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str));
    }
    function _checkOwner() internal view virtual {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    /* util function */


}