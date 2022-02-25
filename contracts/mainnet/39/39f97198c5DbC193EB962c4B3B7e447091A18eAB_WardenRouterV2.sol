/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT

// ((/*,                                                                    ,*((/,.
// &&@@&&%#/*.                                                        .*(#&&@@@@%. 
// &&@@@@@@@&%(.                                                    ,#%&@@@@@@@@%. 
// &&@@@@@@@@@&&(,                                                ,#&@@@@@@@@@@@%. 
// &&@@@@@@@@@@@&&/.                                            .(&&@@@@@@@@@@@@%. 
// %&@@@@@@@@@@@@@&(,                                          *#&@@@@@@@@@@@@@@%. 
// #&@@@@@@@@@@@@@@&#*                                       .*#@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@#.                                      ,%&@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@%(,                                    ,(&@@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@&&/                                   .(%&@@@@@@@@@@@@@@@@&#. 
// #%@@@@@@@@@@@@@@@@@@(.               ,(/,.              .#&@@@@@@@@@@@@@@@@@&#. 
// (%@@@@@@@@@@@@@@@@@@#*.            ./%&&&/.            .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#*.           *#&@@@@&%*.          .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.         ./#@@@@@@@@%(.         ./%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.        ./&@@@@@@@@@@&(*        ,/%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@%/.       ,#&@@@@@@@@@@@@&#,.      ,/%@@@@@@@@@@@@@@@@@@%(. 
// /%@@@@@@@@@@@@@@@@@@#/.      *(&@@@@@@@@@@@@@@&&*      ./%@@@@@@@@@@@@@@@@@&%(. 
// /%@@@@@@@@@@@@@@@@@@#/.     .(&@@@@@@@@@@@@@@@@@#*.    ,/%@@@@@@@@@@@@@@@@@&#/. 
// ,#@@@@@@@@@@@@@@@@@@#/.    ./%@@@@@@@@@@@@@@@@@@&#,    ,/%@@@@@@@@@@@@@@@@@&(,  
//  /%&@@@@@@@@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@&*    ,/%@@@@@@@@@@@@@@@@&%*   
//  .*#&@@@@@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/.   ,/%@@@@@@@@@@@@@@@@#*.   
//    ,(&@@@@@@@@@@@@@@#/.    /@@@@@@@@@@@@@@@@@@@@@&(,   ,/%@@@@@@@@@@@@@@%(,     
//     .*(&&@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/,   ,/%@@@@@@@@@@@&%/,       
//        ./%&@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@%*    ,/%@@@@@@@@@&%*          
//           ,/#%&&@@@@#/.     ,#&@@@@@@@@@@@@@@@@@#/.    ,/%@@@@&&%(/,            
//               ./#&@@%/.      ,/&@@@@@@@@@@@@@@%(,      ,/%@@%#*.                
//                   .,,,         ,/%&@@@@@@@@&%(*        .,,,.                    
//                                   ,/%&@@@%(*.                                   
//  .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**((/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                                                                                                                                                                                                                                                                                                            
//                                                                                             

pragma solidity ^0.8.0;

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

/*
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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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


// File contracts/libraries/TransferHelper.sol

pragma solidity ^0.8.0;

interface IERC20NoReturn {
    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// helper methods for interacting with ERC20 tokens that do not consistently return boolean
library TransferHelper {
    function safeTransfer(IERC20 token, address to, uint value) internal {
        try IERC20NoReturn(address(token)).transfer(to, value) {

        } catch Error(string memory reason) {
            // catch failing revert() and require()
            revert(reason);
        } catch  {
            revert("TransferHelper: transfer failed");
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        try IERC20NoReturn(address(token)).transferFrom(from, to, value) {

        } catch Error(string memory reason) {
            // catch failing revert() and require()
            revert(reason);
        } catch {
            revert("TransferHelper: transferFrom failed");
        }
    }
}


// File contracts/interface/IWETH.sol


pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/interface/IWardenPreTrade2.sol

pragma solidity ^0.8.0;

interface IWardenPreTrade2 {
    function preTradeAndFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        address     _trader,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        external
        returns (
            uint256[] memory _fees,
            address[] memory _collectors
        );
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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


// File contracts/interface/IWardenSwap2.sol

pragma solidity ^0.8.0;

interface IWardenSwap2 {
    function trade(
        bytes calldata  _data,
        IERC20      _src,
        uint256     _srcAmount,
        uint256     _originalSrcAmount,
        IERC20      _dest,
        address     _receiver,
        address     _trader,
        uint256     _partnerId,
        uint256     _metaData
    )
        external;
    
    function tradeSplit(
        bytes calldata  _data,
        uint256[] calldata _volumes,
        IERC20      _src,
        uint256     _totalSrcAmount,
        uint256     _originalSrcAmount,
        IERC20      _dest,
        address     _receiver,
        address     _trader,
        uint256     _partnerId,
        uint256     _metaData
    )
        external;
}


// File contracts/swap/WardenRouterV2.sol

pragma solidity ^0.8.0;





contract WardenRouterV2 is Ownable {
    using TransferHelper for IERC20;
    
    IWardenPreTrade2 public preTrade;

    IWETH public immutable weth;
    IERC20 private constant ETHER_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    event UpdatedWardenPreTrade(
        IWardenPreTrade2 indexed preTrade
    );

    /**
    * @dev When fee is collected by WardenSwap for a trade, this event will be emitted
    * @param token Collected token
    * @param wallet Collector address
    * @param amount Amount of fee collected
    */
    event ProtocolFee(
        IERC20  indexed   token,
        address indexed   wallet,
        uint256           amount
    );

    /**
    * @dev When fee is collected by WardenSwap's partners for a trade, this event will be emitted
    * @param partnerId Partner ID
    * @param token Collected token
    * @param wallet Collector address
    * @param amount Amount of fee collected
    */
    event PartnerFee(
        uint256 indexed   partnerId,
        IERC20  indexed   token,
        address indexed   wallet,
        uint256           amount
    );

    /**
    * @dev When the new trade occurs (and success), this event will be emitted.
    * @param srcAsset Source token
    * @param srcAmount Amount of source token
    * @param destAsset Destination token
    * @param destAmount Amount of destination token
    * @param trader User address
    */
    event Trade(
        address indexed srcAsset,
        uint256         srcAmount,
        address indexed destAsset,
        uint256         destAmount,
        address indexed trader,
        address         receiver,
        bool            hasSplitted
    );

    constructor(
        IWardenPreTrade2 _preTrade,
        IWETH _weth
    ) {
        preTrade = _preTrade;
        weth = _weth;
        
        emit UpdatedWardenPreTrade(_preTrade);
    }

    function updateWardenPreTrade(
        IWardenPreTrade2 _preTrade
    )
        external
        onlyOwner
    {
        preTrade = _preTrade;
        emit UpdatedWardenPreTrade(_preTrade);
    }

    /**
    * @dev Performs a trade with single volume
    * @param _swap Warden Swap contract
    * @param _data Warden Swap payload
    * @param _deposits Source token receiver
    * @param _src Source token
    * @param _srcAmount Amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount Minimum of destination token amount
    * @param _receiver Destination token receiver
    * @param _partnerId Partner id for fee sharing / Referral
    * @param _metaData Reserved for upcoming features
    * @return _destAmount Amount of actual destination tokens
    */
    function swap(
        IWardenSwap2    _swap,
        bytes calldata  _data,
        address     _deposits,
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        // Collect fee
        uint256 newSrcAmount = _preTradeAndCollectFee(
            _src,
            _dest,
            _srcAmount,
            msg.sender,
            _receiver,
            _partnerId,
            _metaData
        );

        // Wrap ETH
        if (ETHER_ERC20 == _src) {
            require(msg.value == _srcAmount, "WardenRouter::swap: Ether source amount mismatched");
            weth.deposit{value: newSrcAmount}();
            
            // Transfer user tokens to target
            IERC20(address(weth)).safeTransfer(_deposits, newSrcAmount);
        } else {
            // Transfer user tokens to target
            _src.safeTransferFrom(msg.sender, _deposits, newSrcAmount);
        }

        bytes memory payload = abi.encodeWithSelector(IWardenSwap2.trade.selector,
            _data,
            _src,
            newSrcAmount,
            _srcAmount,
            _dest,
            _receiver,
            msg.sender,
            _partnerId,
            _metaData
        );

        _destAmount = _internalSwap(
            _swap,
            payload,
            _dest,
            _minDestAmount,
            _receiver
        );
        emit Trade(address(_src), _srcAmount, address(_dest), _destAmount, msg.sender, _receiver, false);
    }

    /**
    * @dev Performs a trade by splitting volumes
    * @param _swap Warden Swap contract
    * @param _data Warden Swap payload
    * @param _deposits Source token receivers
    * @param _volumes Volume percentages
    * @param _src Source token
    * @param _totalSrcAmount Amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount Minimum of destination token amount
    * @param _receiver Destination token receiver
    * @param _partnerId Partner id for fee sharing / Referral
    * @param _metaData Reserved for upcoming features
    * @return _destAmount Amount of actual destination tokens
    */
    function swapSplit(
        IWardenSwap2    _swap,
        bytes calldata  _data,
        address[] memory _deposits,
        uint256[] memory _volumes,
        IERC20      _src,
        uint256     _totalSrcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        // Collect fee
        uint256 newTotalSrcAmount = _preTradeAndCollectFee(
            _src,
            _dest,
            _totalSrcAmount,
            msg.sender,
            _receiver,
            _partnerId,
            _metaData
        );

        // Wrap ETH
        if (ETHER_ERC20 == _src) {
            require(msg.value == _totalSrcAmount, "WardenRouter::swapSplit: Ether source amount mismatched");
            weth.deposit{value: newTotalSrcAmount}();
        }

        // Transfer user tokens to targets
        _depositVolumes(
            newTotalSrcAmount,
            _deposits,
            _volumes,
            _src
        );
        

        bytes memory payload = abi.encodeWithSelector(IWardenSwap2.tradeSplit.selector,
            _data,
            _volumes,
            _src,
            newTotalSrcAmount,
            _totalSrcAmount,
            _dest,
            _receiver,
            msg.sender,
            _partnerId,
            _metaData
        );

        _destAmount = _internalSwap(
            _swap,
            payload,
            _dest,
            _minDestAmount,
            _receiver
        );
        emit Trade(address(_src), _totalSrcAmount, address(_dest), _destAmount, msg.sender, _receiver, true);
    }

    function _depositVolumes(
        uint256 newTotalSrcAmount,
        address[] memory _deposits,
        uint256[] memory _volumes,
        IERC20           _src
    )
        private
    {
        {
            uint256 amountRemain = newTotalSrcAmount;
            for (uint i = 0; i < _deposits.length; i++) {
                uint256 amountForThisRound;
                if (i == _deposits.length - 1) {
                    amountForThisRound = amountRemain;
                } else {
                    amountForThisRound = newTotalSrcAmount * _volumes[i] / 100;
                    amountRemain = amountRemain - amountForThisRound;
                }
            
                if (ETHER_ERC20 == _src) {
                    IERC20(address(weth)).safeTransfer(_deposits[i], amountForThisRound);
                } else {
                    _src.safeTransferFrom(msg.sender, _deposits[i], amountForThisRound);
                }
            }
        }
    }

    function _internalSwap(
        IWardenSwap2 _swap,
        bytes memory _payload,
        IERC20       _dest,
        uint256      _minDestAmount,
        address      _receiver
    )
        private
        returns (uint256 _destAmount)
    {
        // Record dest asset for later consistency check.
        uint256 destAmountBefore = ETHER_ERC20 == _dest ? _receiver.balance : _dest.balanceOf(_receiver);

        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(_swap).call(_payload);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
        }

        _destAmount = ETHER_ERC20 == _dest ? _receiver.balance - destAmountBefore : _dest.balanceOf(_receiver) - destAmountBefore;

        // Throw exception if destination amount doesn't meet user requirement.
        require(_destAmount >= _minDestAmount, "WardenRouter::_internalSwap: destination amount is too low.");
    }

    function _preTradeAndCollectFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        address     _trader,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        private
        returns (uint256 _newSrcAmount)
    {
        // Collect fee
        (uint256[] memory fees, address[] memory feeWallets) = preTrade.preTradeAndFee(
            _src,
            _dest,
            _srcAmount,
            _trader,
            _receiver,
            _partnerId,
            _metaData
        );
        _newSrcAmount = _srcAmount;
        if (fees.length > 0) {
            if (fees[0] > 0) {
                _collectFee(
                    _trader,
                    _src,
                    fees[0],
                    feeWallets[0]
                );
                _newSrcAmount -= fees[0];
            }
            if (fees.length == 2 && fees[1] > 0) {
                _partnerFee(
                    _trader,
                    _partnerId, // partner id
                    _src,
                    fees[1],
                    feeWallets[1]
                );
                _newSrcAmount -= fees[1];
            }
        }
    }
    
    function _collectFee(
        address _trader,
        IERC20  _token,
        uint256 _fee,
        address _feeWallet
    )
        private
    {
        if (ETHER_ERC20 == _token) {
            (bool success, ) = payable(_feeWallet).call{value: _fee}(""); // Send ether to fee collector
            require(success, "WardenRouter::_collectFee: Transfer fee of ether failed.");
        } else {
            _token.safeTransferFrom(_trader, _feeWallet, _fee); // Send token to fee collector
        }
        emit ProtocolFee(_token, _feeWallet, _fee);
    }

    function _partnerFee(
        address _trader,
        uint256 _partnerId,
        IERC20  _token,
        uint256 _fee,
        address _feeWallet
    )
        private
    {
        if (ETHER_ERC20 == _token) {
            (bool success, ) = payable(_feeWallet).call{value: _fee}(""); // Send back ether to partner
            require(success, "WardenRouter::_partnerFee: Transfer fee of ether failed.");
        } else {
            _token.safeTransferFrom(_trader, _feeWallet, _fee);
        }
        emit PartnerFee(_partnerId, _token, _feeWallet, _fee);
    }

    /**
    * @dev Performs a trade ETH -> WETH
    * @param _receiver Receiver address
    * @return _destAmount Amount of actual destination tokens
    */
    function tradeEthToWeth(
        address     _receiver
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        weth.deposit{value: msg.value}();
        IERC20(address(weth)).safeTransfer(_receiver, msg.value);
        _destAmount = msg.value;
        emit Trade(address(ETHER_ERC20), msg.value, address(weth), _destAmount, msg.sender, _receiver, false);
    }
    
    /**
    * @dev Performs a trade WETH -> ETH
    * @param _srcAmount Amount of source tokens
    * @param _receiver Receiver address
    * @return _destAmount Amount of actual destination tokens
    */
    function tradeWethToEth(
        uint256     _srcAmount,
        address     _receiver
    )
        external
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        IERC20(address(weth)).safeTransferFrom(msg.sender, address(this), _srcAmount);
        weth.withdraw(_srcAmount);
        (bool success, ) = _receiver.call{value: _srcAmount}(""); // Send back ether to receiver
        require(success, "WardenRouter::tradeWethToEth: Transfer ether back to receiver failed.");
        _destAmount = _srcAmount;
        emit Trade(address(weth), _srcAmount, address(ETHER_ERC20), _destAmount, msg.sender, _receiver, false);
    }

    // Receive ETH in case of trade WETH -> ETH
    receive() external payable {
        require(msg.sender == address(weth), "WardenRouter: Receive Ether only from WETH");
    }

    // In case of an expected and unexpected event that has some token amounts remain in this contract, owner can call to collect them.
    function collectRemainingToken(
        IERC20  _token,
        uint256 _amount
    )
      external
      onlyOwner
    {
        _token.safeTransfer(msg.sender, _amount);
    }

    // In case of an expected and unexpected event that has some ether amounts remain in this contract, owner can call to collect them.
    function collectRemainingEther(
        uint256 _amount
    )
      external
      onlyOwner
    {
        (bool success, ) = msg.sender.call{value: _amount}(""); // Send back ether to sender
        require(success, "WardenRouter::collectRemainingEther: Transfer ether back to caller failed.");
    }
}