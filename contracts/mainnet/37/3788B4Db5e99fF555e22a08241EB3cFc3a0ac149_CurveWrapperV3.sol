/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





interface IExchangeV3 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) external returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory _additionalData) external returns (uint);
}




interface ISwaps {

    ///@notice Perform an exchange using the pool that offers the best rate
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Does NOT check rates in factory-deployed pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);


    ///@notice Perform an exchange using a specific pool
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Works for both regular and factory-deployed pools
    ///@param _pool Address of the pool to use for the swap
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);



    ///@notice Find the pool offering the best rate for a given swap.
    ///@dev Checks rates for regular and factory pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _exclude_pools A list of up to 8 addresses which shouldn't be returned
    ///@return Pool address, amount received
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        address[8] memory _exclude_pools
    ) external view returns (address, uint256);


    ///@notice Get the current number of coins received in an exchange
    ///@dev Works for both regular and factory-deployed pools
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_from` to be sent
    ///@return Quantity of `_to` to be received
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_input_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amounts Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_exchange_amounts(
        address _pool,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);


    ///@notice Set calculator contract
    ///@dev Used to calculate `get_dy` for a pool
    ///@param _pool Pool address
    ///@return `CurveCalc` address
    function get_calculator(address _pool) external view returns (address);


    /// @notice Perform up to four swaps in a single transaction
    /// @dev Routing and swap params must be determined off-chain. This
    ///     functionality is designed for gas efficiency over ease-of-use.
    /// @param _route Array of [initial token, pool, token, pool, token, ...]
    ///     The array is iterated until a pool address of 0x00, then the last
    ///     given token is transferred to `_receiver`
    /// @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
    ///     values for the n'th pool in `_route`. The swap type should be 1 for
    ///     a stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3
    ///     for a cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying`,
    ///     5 for Polygon factory metapools `exchange_underlying`, 6-8 for
    ///     underlying coin -> LP token "exchange" (actually `add_liquidity`), 9 and 10
    ///     for LP token -> underlying coin "exchange" (actually `remove_liquidity_one_coin`)
    /// @param _amount The amount of `_route[0]` token being sent.
    /// @param _expected The minimum amount received after the final swap.
    /// @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for
    ///     Polygon meta-factories underlying swaps.
    /// @param _receiver Address to transfer the final output token to.
    /// @return Received amount of the final output token
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external payable returns (uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount
    ) external view returns (uint256);
}




interface IAddressProvider {
    function admin() external view returns (address);
    function get_registry() external view returns (address);
    function get_address(uint256 _id) external view returns (address);
}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}





abstract contract IDFSRegistry {
 
    function getAddr(bytes4 _id) public view virtual returns (address);

    function addNewContract(
        bytes32 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public virtual;

    function startContractChange(bytes32 _id, address _newContractAddr) public virtual;

    function approveContractChange(bytes32 _id) public virtual;

    function cancelContractChange(bytes32 _id) public virtual;

    function changeWaitPeriod(bytes32 _id, uint256 _newWaitPeriod) public virtual;
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;
    address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
    address internal constant ADMIN_ADDR = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9; // USED IN ADMIN VAULT CONSTRUCTOR
}





contract AuthHelper is MainnetAuthAddresses {
}





contract AdminVault is AuthHelper {
    address public owner;
    address public admin;

    error SenderNotAdmin();

    constructor() {
        owner = msg.sender;
        admin = ADMIN_ADDR;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        admin = _admin;
    }

}








contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender){
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender){
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}





contract MainnetWrapperAddresses {

    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant KYBER_INTERFACE = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
    address payable internal constant WALLET_ID = payable(0x322d58b9E75a6918f7e7849AEe0fF09369977e08);
    address internal constant UNI_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant UNI_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant UNI_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address internal constant CURVE_ADDRESS_PROVIDER = 0x0000000022D53366457F9d5E68Ec105046FC4383;
}





contract WrapperHelper is MainnetWrapperAddresses {
}











contract CurveWrapperV3 is DSMath, IExchangeV3, AdminAuth, WrapperHelper {
    using SafeERC20 for IERC20;

    IAddressProvider addressProvider = IAddressProvider(CURVE_ADDRESS_PROVIDER);

    /// @notice Sells _srcAmount of tokens on Curve
    /// @param _srcAddr From token
    /// @param _srcAmount From amount
    /// @param _additionalData Route and swap params
    /// @return uint256 amount of tokens received from selling
    function sell(address _srcAddr, address, uint256 _srcAmount, bytes calldata _additionalData) external override returns (uint) {    
        ISwaps exchangeContract = ISwaps(
                addressProvider.get_address(2)
        );
        IERC20(_srcAddr).safeApprove(address(exchangeContract), _srcAmount);

        (
            address[9] memory _route, uint256[3][4] memory _swap_params
        ) = abi.decode(_additionalData, (address[9], uint256[3][4]));

        address[4] memory pools;
        uint256 amountOut = exchangeContract.exchange_multiple(
            _route,
            _swap_params,
            _srcAmount,
            1,   // _expected
            pools,
            msg.sender
        );

        return amountOut;
    }

    /// @dev deprecated function
    function buy(address, address, uint, bytes calldata) external override returns(uint) {
        return 0;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAmount From amount
    /// @param _additionalData Route and swap params
    /// @return uint256 Rate (price)
    function getSellRate(address, address, uint256 _srcAmount, bytes memory _additionalData) public override returns (uint) {
        ISwaps exchangeContract = ISwaps(
                addressProvider.get_address(2)
        );
        (
            address[9] memory _route, uint256[3][4] memory _swap_params
        ) = abi.decode(_additionalData, (address[9], uint256[3][4]));

        uint256 amountOut = exchangeContract.get_exchange_multiple_amount(
            _route,
            _swap_params,
            _srcAmount
        );
        return wdiv(amountOut, _srcAmount);
    }

    /// @dev deprecated function
    function getBuyRate(address, address, uint, bytes memory) public override returns (uint) {
        return 0;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}