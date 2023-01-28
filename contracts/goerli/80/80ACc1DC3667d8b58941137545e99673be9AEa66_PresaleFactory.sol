/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

interface IERC20 {
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

struct LaunchPad {
    address tokenAddress;
    uint256 startTime;
    uint256 endTime;
    uint256 hardcap;
    uint256 softcap;
    uint256 totalTokenForSale;
    uint256 tokenPerEth;
    uint256 minBuy;
    uint256 maxBuy;
    bool isFairLaunch;
    bool isRefund;
    string uri;
    string tokenUri;
}

// Template used to initialize state variables
contract Presale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public PLATFORM_FEE = 2; //2%
    uint256 public TOTAL_PERCENTAGE = 100; //100%

    uint256 totalSoldToken = 0;
    uint256 totalEthRaised = 0;
    bool finalizedSale;

    address public owner;
    address public deployer;
    address public tokenAddress;
    uint256 startTime;
    uint256 endTime;
    uint256 hardcap;
    uint256 softcap;
    uint256 totalTokenForSale;
    uint256 tokenPerEth;
    uint256 minBuy;
    uint256 maxBuy;
    bool isFairLaunch;
    bool isRefund;
    string uri;
    string tokenUri;

    struct UserInfo {
        uint256 realEthAmount;
        uint256 buyAmount;
        bool isBuy;
    }

    address[] public users;
    mapping(address => UserInfo) public userInfos;

    event Received(address, uint256);
    event BuyToken(
        address indexed user,
        uint256 ethAmount,
        uint256 boughtTokenAmount
    );

    constructor(
        address _owner,
        LaunchPad memory _launchPad
    ) {
        owner = _owner;
        deployer = msg.sender;
        tokenAddress = _launchPad.tokenAddress;
        startTime = _launchPad.startTime;
        endTime = _launchPad.endTime;
        hardcap = _launchPad.hardcap;
        softcap = _launchPad.softcap;
        totalTokenForSale = _launchPad.totalTokenForSale;
        tokenPerEth = _launchPad.tokenPerEth;
        minBuy = _launchPad.minBuy;
        maxBuy = _launchPad.maxBuy;
        isFairLaunch = _launchPad.isFairLaunch;
        isRefund = _launchPad.isRefund;
        uri = _launchPad.uri;
        tokenUri = _launchPad.tokenUri;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getPresaleAddress() external view returns (address) {
        return address(this);
    }

    function buyToken() external payable {
        require(
            startTime < block.timestamp,
            "Sale:: Presale is not started yet"
        );
        require(endTime > block.timestamp, "Sale:: Presale is ended");
        require(!finalizedSale, "Sale:: Presale is finalized");
        require(msg.value >= minBuy, "Sale:: Invalid buy amount");
        UserInfo memory userInfo = userInfos[msg.sender];
        require(userInfo.buyAmount <= maxBuy, "Sale:: Max bought tokens");
        if (!userInfo.isBuy) {
            userInfo.isBuy = true;
            users.push(msg.sender);
        }
        uint256 tokenDecimals = IERC20(tokenAddress).decimals();
        uint256 amountBuy = msg
            .value
            .mul(tokenPerEth)
            .mul(10**tokenDecimals)
            .div(10**18);
        uint256 devFee = msg.value.mul(PLATFORM_FEE).div(TOTAL_PERCENTAGE);
        payable(deployer).transfer(devFee);
        userInfo.realEthAmount = msg.value - devFee;
        IERC20(tokenAddress).safeTransfer(msg.sender, amountBuy);
        totalSoldToken += amountBuy;
        totalEthRaised += msg.value;

        emit BuyToken(msg.sender, msg.value, amountBuy);
    }

    function withdraw(uint256 _ethAmount) external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        require(
            _ethAmount <= address(this).balance,
            "Sale:: Invaid withdrawn amount"
        );
        payable(msg.sender).transfer(_ethAmount);
    }

    function claimRemainingToken() external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        require(endTime >= block.timestamp, "Sale:: Can claim after end");

        if (isRefund) {
            IERC20(tokenAddress).safeTransfer(
                msg.sender,
                totalTokenForSale.sub(totalSoldToken)
            );
        } else {
            IERC20(tokenAddress).safeTransfer(
                address(0),
                totalTokenForSale.sub(totalSoldToken)
            );
        }
    }

    function finalSale() external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        require(totalEthRaised >= softcap, "Sale:: Not reached to softcap");
        require(
            totalEthRaised >= hardcap || endTime >= block.timestamp,
            "Sale:: Not reached to hardcap on duration"
        );
        finalizedSale = true;
    }

    function cancelSale() external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        require(
            totalEthRaised <= softcap && endTime >= block.timestamp,
            "Sale:: Not reached to softcap"
        );
        for (uint256 k = 0; k < users.length; k++) {
            address user = users[k];
            UserInfo memory userInfo = userInfos[user];
            payable(user).transfer(userInfo.realEthAmount);
        }
    }

    function getUsers() external view returns (uint256) {
        return users.length;
    }

    function transferOwner(address _newOwner) external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        require(_newOwner != address(0), "Sale:: Invalid new owner");
        owner = _newOwner;
    }

    function recoverERC20(
        address _token,
        uint256 _amount,
        address _wallet
    ) external {
        require(msg.sender == owner, "Sale:: Invalid owner");
        IERC20(_token).safeTransfer(_wallet, _amount);
    }
}

contract PresaleFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // instantiate Presale contract
    Presale presale;

    //keep track of created Presale addresses in array
    Presale[] public list_of_presales;

    uint256 public TOKEN_FEE = 3; //3%
    uint256 public TOTAL_PERCENTAGE = 100; //100%
    address public devAddress;
    event Received(address, uint256);

    constructor(address _devAddress) {
        require(_devAddress != address(0), "Pad:: Invalid dev addresss");
        devAddress = _devAddress;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // function arguments are passed to the constructor of the new created contract
    function createPad(LaunchPad memory _launchData) external {
        address tempTokenAddress = _launchData.tokenAddress;
        uint256 tempTotalTokenForSale = _launchData.totalTokenForSale;
        require(tempTokenAddress != address(0), "Pad:: Token address is zero");
        require(_launchData.startTime >= block.timestamp, "Pad:: Invalid start time");
        require(_launchData.startTime <= _launchData.endTime, "Pad:: Invalid end time");
        require(_launchData.tokenPerEth > 0, "Pad::Invalid token per eth");
        require(tempTotalTokenForSale > 0, "Pad:: Invalid total token for sale");

        IERC20(tempTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tempTotalTokenForSale
        );

        uint256 tokenFee = tempTotalTokenForSale.mul(TOKEN_FEE).div(
            TOTAL_PERCENTAGE
        );
        uint256 tempTotal = tempTotalTokenForSale.sub(tokenFee);
        IERC20(tempTokenAddress).safeTransfer(devAddress, tokenFee);

        presale = new Presale(
            msg.sender,
            _launchData
        );

        list_of_presales.push(presale);

        IERC20(tempTokenAddress).safeTransfer(address(presale), tempTotal);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "Pad:: Invalid dev addresss");
        devAddress = _devAddress;
    }

    function recoverERC20(
        address _token,
        uint256 _amount,
        address _wallet
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_wallet, _amount);
    }

    function recoverEth() external onlyOwner {
        uint256 balance = address(this).balance;
        address payable sender = payable(msg.sender);
        sender.transfer(balance);
    }
}