/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// @@@@@@@    @@@@@@   @@@   @@@@@@    @@@@@@   @@@  @@@  
// @@@@@@@@  @@@@@@@@  @@@  @@@@@@@   @@@@@@@@  @@@@ @@@  
// @@!  @@@  @@!  @@@  @@!  [email protected]@       @@!  @@@  @@[email protected][email protected]@@  
// [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!  [email protected]!       [email protected]!  @[email protected] [email protected][email protected][email protected]!  
// @[email protected]@[email protected]!   @[email protected] [email protected]!  [email protected] [email protected]@!!    @[email protected] [email protected]!  @[email protected] [email protected]!  
// [email protected]!!!    [email protected]!  !!!  !!!   [email protected]!!!   [email protected]!  !!!  [email protected]!  !!!  
// !!:       !!:  !!!  !!:       !:!  !!:  !!!  !!:  !!!  
// :!:       :!:  !:!  :!:      !:!   :!:  !:!  :!:  !:!  
//  ::       ::::: ::   ::  :::: ::   ::::: ::   ::   ::  
//  :         : :  :   :    :: : :     : :  :   ::    :   
//                      https://Poison.Finance    

// Deposit Eth, Liquidity Generation on Uniswap, Emergency Withdraw


pragma solidity ^0.8.4;


contract PoisonSale {
    
    using SafeERC20 for IERC20;

    Poison public PT;   
    IERC20 public poison;
    IERC20 public stableCoin;
    address payable public developer;
    address public oracle;
    
    uint public immutable multiplier;
    uint public immutable privateSaleRate;
    uint public immutable publicSaleRate;
    uint public immutable uniswapRate;
          
    uint public privateSaleSold;
    uint public publicSaleSold;
          
    uint public privateSaleCap;
    uint public publicSaleCap;
          
    uint public publicSaleOpenedAt;
    uint public publicSaleClosedAt;
    uint public liquidityGeneratedAt;
          
    bool public privateSaleClosed = false;
          
    IUniswapV2Router02 public uniswapRouter;
          
    mapping(address => bool) public whiteListed;
    mapping(address => uint256) public tokenBalances;
    mapping(address => uint256) public stableCoinContributed;
          
    event LiquidityGenerated(uint amountA, uint amountB, uint liquidity);
    event PoisonClaimed(address account, uint amount);
    event EmergencyWithdrawn(address account, uint amount);
    event EthDeposited(address account, uint tokens, int price);
    event CoinDeposited(address account, uint tokens);
    event LpRecovered(address account, uint tokens);
    
    constructor(
        uint _privateSaleRate, 
        uint _publicSaleRate, 
        uint _uniswapRate, 
        uint _privateSaleCap, 
        uint _publicSaleCap, 
        uint _multiplier,  
        IERC20 _stableCoin,
        address _poison, 
        address _oracle, 
        address _uniswapRouter
        ) {
        privateSaleRate = _privateSaleRate;
        publicSaleRate = _publicSaleRate;
        uniswapRate = _uniswapRate;
        privateSaleCap = _privateSaleCap;
        publicSaleCap = _publicSaleCap;
        multiplier = _multiplier;
        poison = IERC20(_poison);
        PT = Poison(_poison);
        stableCoin = _stableCoin;
        oracle = _oracle;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        developer = payable(msg.sender);
    }

    receive() external payable {
        depositEth();
    }

    function depositEth() public payable {
        
        uint tokens;
        
        require(msg.value > 0);
        
        (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
        
        if (privateSaleClosed == false) {

            require(whiteListed[msg.sender], "Not whitelisted");
          
            tokens = msg.value * uint(price) / privateSaleRate;
            
            require(tokenBalances[msg.sender] + tokens >= 100000000000000000000 && tokenBalances[msg.sender] + tokens <= 30000000000000000000000, "Private sale limit");
            
            require(privateSaleSold + tokens <= privateSaleCap, "Cap reached");
            privateSaleSold = privateSaleSold + tokens;
            
        } else {
       
            require(publicSaleOpenedAt !=0 && publicSaleClosedAt == 0, "Public sale closed");
            require(block.timestamp >= publicSaleOpenedAt && block.timestamp <= publicSaleOpenedAt + 21 days, "Time was reached");
            
            uint amount = msg.value * uint(price) / multiplier;
            
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = address(stableCoin);
            
            uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value:msg.value}(amount - (amount / 25), path, address(this), block.timestamp + 15 minutes);
            require(amounts[1] > 0);
            
            tokens = amounts[1] * multiplier / publicSaleRate;
            
            require(tokenBalances[msg.sender] + tokens >= 200000000000000000000 && tokenBalances[msg.sender] + tokens <= 40000000000000000000000, "Public sale limit");
            
            require(publicSaleSold + tokens <= publicSaleCap, "Cap reached");
            publicSaleSold = publicSaleSold + tokens;
            
            stableCoinContributed[msg.sender] = stableCoinContributed[msg.sender] + amounts[1];
            
        }
        
        tokenBalances[msg.sender] = tokenBalances[msg.sender] + tokens;
        emit EthDeposited(msg.sender, tokens, price);
    }
    
    function closeSeedSale() external {
    require(msg.sender == developer, "Developer only");
        
        require(privateSaleClosed == false, "Private sale closed");
        
        (bool success, ) = developer.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
    function closePrivateSale() external {
    require(msg.sender == developer, "Developer only");
        
        require(privateSaleClosed == false, "Private sale closed");
        
        privateSaleClosed = true;
        publicSaleOpenedAt = block.timestamp;
        
        (bool success, ) = developer.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function closePublicSale() external {
        
        require(publicSaleOpenedAt !=0, "Private sale open");
        require(publicSaleClosedAt == 0, "Public sale closed");
        require(block.timestamp > publicSaleOpenedAt + 21 days || (publicSaleSold >= publicSaleCap - 200000000000000000000 && publicSaleSold <= publicSaleCap), 'Too early');

        publicSaleClosedAt = block.timestamp;
    }
    
    function generateLiquidity() external {
        
        require(publicSaleClosedAt != 0, "Public sale open");
        require(liquidityGeneratedAt == 0, "Liquidity generated");
        require(block.timestamp > publicSaleClosedAt + 30 minutes, "Too early");
        
        uint stableCoinBalance = stableCoin.balanceOf(address(this));
        require(stableCoinBalance > 0, "Stablecoin balance is zero");
        stableCoin.safeApprove(address(uniswapRouter), stableCoinBalance);
        uint amountPoison = stableCoinBalance * multiplier / uniswapRate;

        uint totalPoisonMint = amountPoison + privateSaleSold + publicSaleSold;
        PT.mint(address(this), totalPoisonMint);

        poison.safeApprove(address(uniswapRouter), amountPoison);

        (uint amountA, uint amountB, uint liquidity) = uniswapRouter.addLiquidity(
            address(poison),
            address(stableCoin),
            amountPoison,
            stableCoinBalance,
            amountPoison - (amountPoison / 10),
            stableCoinBalance - (stableCoinBalance / 10),
            address(this),
            block.timestamp + 2 hours
        );
        
        liquidityGeneratedAt = block.timestamp;
        
        emit LiquidityGenerated(amountA, amountB, liquidity);
    }
    
    function claimPoison() external {
        
        require(liquidityGeneratedAt != 0, "Liquidity not generated");
        uint tokens =  tokenBalances[msg.sender];
        require(tokens > 0 , "Nothing to claim");
        
        stableCoinContributed[msg.sender] = 0;
        tokenBalances[msg.sender] = 0;
        
        poison.safeTransfer(msg.sender, tokens);
        
        emit PoisonClaimed(msg.sender, tokens);
    }
    
    function emergencyWithdrawCoins() external {
        
        require(publicSaleClosedAt != 0, "Public sale open");
        require(liquidityGeneratedAt == 0, "Liquidity generated");
        require(block.timestamp > publicSaleClosedAt + 30 minutes + 3 days, "Too early");
        
        uint contributedAmount = stableCoinContributed[msg.sender];
        require(contributedAmount > 0, "Nothing to withdraw");
        
        tokenBalances[msg.sender] = 0;      
        stableCoinContributed[msg.sender] = 0;
        
        stableCoin.safeTransfer(msg.sender, contributedAmount);
        
        emit EmergencyWithdrawn(msg.sender, contributedAmount);
    }
    
    
    function recoverLpTokens(address _lpToken) external {
    require(msg.sender == developer, "Developer only");
    
        require(liquidityGeneratedAt != 0, "Liquidity not generated");
        require(block.timestamp >= liquidityGeneratedAt + 720 days, "Too early");

        IERC20 lpToken = IERC20(_lpToken);
        uint lpBalance = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(developer, lpBalance);

        emit LpRecovered(developer, lpBalance);
    }
    
    function addPrivateInvestor(address _address, uint _tokens) external {
    require(msg.sender == developer, "Developer only");
    
        require(privateSaleClosed == false, "Private sale closed");
        
        privateSaleSold = privateSaleSold + _tokens;
        tokenBalances[_address] = tokenBalances[_address] + _tokens;
    }
    
    function setWhitelist(address[] memory addrs) external {
    require(msg.sender == developer, "Developer only");
        
        require(privateSaleClosed == false, "Private sale closed");
        
        for (uint8 i = 0; i < addrs.length; i++){
         whiteListed[addrs[i]] = true;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

interface Poison {

function mint(address _to, uint256 _amount) external;

}
// File: @openzeppelin/contracts/utils/Address.sol

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


pragma solidity >=0.8.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}