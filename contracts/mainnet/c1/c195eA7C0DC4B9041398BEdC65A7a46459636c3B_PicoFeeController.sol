// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAggregationRouterV4.sol";
import "./interfaces/IUniswapV3PoolImmutables.sol";

/**
 * @notice Contract perform swap of tokens using 1inch and also deduct Fee Percentage as described
 * by the owner. 1inch uses mulitple protocols or exchanges to get the swap at best price.
 * @dev Contract uses 1inch Aggregation Router for token swap depends on route data and exchange, contract
 * also have feature to set fees percent and also collect Eth and token Fees for Owner.
 * Refer for AggegationRouter:https://bscscan.com/address/0x1111111254fb6c44bAC0beD2854e76F90643097d#code
 * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/AggregationRouterV4
 * Contract uses Ownable, ReentrancyGuard and Pausable library for for Owner Rights and Security Concerns.
 */
contract PicoFeeController is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _WETH_WRAP_MASK = 1 << 254;

    IERC20 private constant _ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    address public aggregationRouter;

    uint16 public constant denominator = 10000;

    uint16 public feesPercentage;

    event FeesCollected(
        address indexed accountAddress,
        IERC20 fromTokenAddress,
        IERC20 toTokenAddress,
        uint256 swapAmount,
        uint256 feeAmount
    );

    /**
     * @dev constructor initalizes the aggregation router and percentage(in basis points).
     * Eg- For 1.24% fees percentage basis points is 124.
     * AggregationRouterV4 address is deployed at - 0x1111111254fb6c44bAC0beD2854e76F90643097d
     * Refer: https://bscscan.com/address/0x1111111254fb6c44bAC0beD2854e76F90643097d#code
     */
    constructor(address _aggregationRouter, uint16 _percentage) {
        require(
            _aggregationRouter != address(0),
            "Enter a valid aggregation Router Address"
        );
        aggregationRouter = _aggregationRouter;
        feesPercentage = _percentage;
    }

    receive() external payable {}

    /**
     * @dev Function to set Fee Percentage(only in basis points). For eg- For 1.24%, parameter will
     * take 124 as number for fee Percent. Only the owner of contract can set fee Percentage
     * @param _newPercentage New fees Percent(in basis points) that owner can set.
     */

    function setFeePercentage(uint16 _newPercentage) external onlyOwner {
        feesPercentage = _newPercentage;
    }

    /**
     * @dev Function to change Aggregation Router Address. Currently, Aggregation
     * Router Version 4 is deployed by 1inch, but if aggregation router version
     * is updated in future by 1inch, the function can update the aggregation router
     * address
     * @param _aggregationRouter New aggregation router address that owner can set.
     */

    function updateAggregationRouter(address _aggregationRouter)
        external
        onlyOwner
    {
        require(
            _aggregationRouter != address(0),
            "Enter a valid aggregation Router Address"
        );
        aggregationRouter = _aggregationRouter;
    }

    /**
     * @dev Function to collect token fees stored in contract's address for all tokens.
     * Tokens are transferd to owner's account address. Only be called by the owner of the contract.
     * @param _tokenAddress Token Address owner want to collect.
     */
    function collectTokensFee(address[] calldata _tokenAddress)
        external
        onlyOwner
    {
        require(_tokenAddress.length < 30, "limit exceeded");
        uint256 balance;
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            balance = IERC20(_tokenAddress[i]).balanceOf(address(this));
            IERC20(_tokenAddress[i]).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * @dev Function to collect Eth fees stored in contract's address. Can only be called by the
     * owner of the contract
     */
    function collectEthfee() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed");
    }

    /**
     *@notice used to pause smart contract's swap functions
     *@dev only owner can call the pause function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     *@notice used to unpause smart contract's swap functions
     *@dev only owner can call the unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Calls if route of swap involves all protocol Exchanges (except uniswap,
     * uniswapV3 and clipperswap) for tokens swap using 1inch.
     * @dev Encoded data gets decoded for Excutor or caller, swap description and route data.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/AggregationRouterV4 for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token in contract's address
     *  before swap by calling _intialProcessing function,
     * checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router swap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to swap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information, caller
     * address, swap route and other Swap Description parameters.
     */

    function swap(bytes calldata data)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (
            IAggregationExecutor executor,
            IAggregationRouterV4.SwapDescription memory desc,
            bytes memory _data
        ) = abi.decode(
                data[4:],
                (
                    IAggregationExecutor,
                    IAggregationRouterV4.SwapDescription,
                    bytes
                )
            );
        require(desc.minReturnAmount > 0, "Minimum return should not be zero");
        require(
            desc.dstReceiver == address(this),
            "another reciever not supported"
        );
        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            desc.srcToken,
            desc.dstToken,
            desc.amount
        );
        if (_isETH(desc.srcToken)) {
            IAggregationRouterV4(aggregationRouter).swap{value: desc.amount}(
                executor,
                desc,
                _data
            );
        } else {
            IAggregationRouterV4(aggregationRouter).swap(executor, desc, _data);
        }

        _finalProcessing(
            desc.dstToken,
            isEthDst,
            balanceBefore,
            desc.minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves Uniswap Exchange for tokens swap using 1inch.
     * @dev Encoded data gets decoded for amount, minReturnAmount, pools and source token.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapRouter for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token in contract's address
     *  before swap by calling _intialProcessing function,
     * checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router unoswap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to unoswap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information related to token amount, caller
     * address, swap route and other Swap Description parameters.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     */

    function uniswapSwap(bytes calldata data, address dstToken)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (
            IERC20 srcToken,
            uint256 amount,
            uint256 minReturnAmount,
            bytes32[] memory pools
        ) = abi.decode(data[4:], (IERC20, uint256, uint256, bytes32[]));
        require(minReturnAmount > 0, "Minimum return should not be zero");
        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            IERC20(dstToken),
            amount
        );

        if (_isETH(srcToken)) {
            IAggregationRouterV4(aggregationRouter).unoswap{value: amount}(
                IERC20(srcToken),
                amount,
                minReturnAmount,
                pools
            );
        } else {
            IAggregationRouterV4(aggregationRouter).unoswap(
                IERC20(srcToken),
                amount,
                minReturnAmount,
                pools
            );
        }

        _finalProcessing(
            IERC20(dstToken),
            isEthDst,
            balanceBefore,
            minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves UniswapV3 Exchange for tokens swap using 1inch.
     * @dev Encoded data gets decode for amount, minReturnAmount and pools.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapV3Router for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token before swap by calling
     *  _intialProcessing, checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router uniswapV3swap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to uniswapV3 swap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information related to token amount, caller
     * address, swap route and other Swap Description parameters.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     */

    function uniswapV3Swap(bytes calldata data, address dstToken)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 minReturnAmount, uint256[] memory pools) = abi
            .decode(data[4:], (uint256, uint256, uint256[]));
        require(minReturnAmount > 0, "Minimum return should not be zero");
        IERC20 srcToken;
        bool wrapWeth = pools[0] & _WETH_WRAP_MASK > 0;
        if (wrapWeth) {
            srcToken = _ETH_ADDRESS;
        } else {
            bool zeroForOne = pools[0] & _ONE_FOR_ZERO_MASK == 0;
            address tokenPool = address(uint160(pools[0]));
            if (zeroForOne) {
                srcToken = IERC20(IUniswapV3PoolImmutables(tokenPool).token0());
            } else {
                srcToken = IERC20(IUniswapV3PoolImmutables(tokenPool).token1());
            }
        }

        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            IERC20(dstToken),
            amount
        );
        if (_isETH(IERC20(srcToken))) {
            IAggregationRouterV4(aggregationRouter).uniswapV3Swap{
                value: amount
            }(amount, minReturnAmount, pools);
        } else {
            IAggregationRouterV4(aggregationRouter).uniswapV3Swap(
                amount,
                minReturnAmount,
                pools
            );
        }

        _finalProcessing(
            IERC20(dstToken),
            isEthDst,
            balanceBefore,
            minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves Clipper Exchange for tokens swap using 1inch.
     * @dev Function fetches Balance of source token & destination token before swap by calling
     *  _intialProcessing, checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router clipperswap function with token amount for swap. And then
     * calls _finalProcessing function to transfer token amount after swap.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/ClipperRouter for more
     * information related to clipperswap function on Aggregation Router.
     * @param srcToken Source Token Address as IERC20 type. Source Token is token which user want to swap.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     * @param amount Token Amount
     * @param minReturn Minimum Return Amount
     */

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable nonReentrant whenNotPaused {
        require(minReturn > 0, "Minimum return should not be zero");

        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            dstToken,
            amount
        );

        if (_isETH(srcToken)) {
            IAggregationRouterV4(aggregationRouter).clipperSwap{value: amount}(
                srcToken,
                dstToken,
                amount,
                minReturn
            );
        } else {
            IAggregationRouterV4(aggregationRouter).clipperSwap(
                srcToken,
                dstToken,
                amount,
                minReturn
            );
        }

        _finalProcessing(dstToken, isEthDst, balanceBefore, minReturn);
    }

    /**
     * @dev Function stores balance of eth or token from contract's address before swap and calls for
     * _processTransferandApproval function with amount & source token address.
     * @param _srcToken Source Token Address as IERC20 type. Source Token is token which user want to swap.
     * @param _dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     * @param _amount Token Amount
     * @return _balanceBefore Returns amount of eth or Token in contract's address before swap.
     * @return _isEthDst Returns bool as 'true' if eth is Destination Address else 'false' for other
     * token address
     */

    function _initialProcessing(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _amount
    ) internal returns (uint256 _balanceBefore, bool _isEthDst) {
        uint256 actualAmount = _calculateAmountWithFees(_amount);

        if (_isETH(_srcToken)) {
            _balanceBefore = _fetchTokenBalance(address(_dstToken));
            require(msg.value == actualAmount, "less input tokens");
        } else {
            _isEthDst = _isETH(_dstToken);
            if (_isEthDst) {
                _balanceBefore = _fetchETHBalance();
            } else {
                _balanceBefore = _fetchTokenBalance(address(_dstToken));
            }
            _processTransferAndApproval(
                address(_srcToken),
                actualAmount,
                _amount
            );
        }
        emit FeesCollected(
            msg.sender,
            _srcToken,
            _dstToken,
            _amount,
            (actualAmount - _amount)
        );
    }

    /**
     * @dev Function stores balance after swap based on Eth is Destination Address or not. Checks
     * condition for slippage and transfer Eth or Token back to 'caller'
     * @param _dstToken Destination Token Address as IERC20 type.
     * @param _isEthDst 'bool' input as 'true' if Destination Address is eth Address else 'false'
     * @param _balanceBefore Actual token Balance before swap
     * @param _minReturn Minimum Return Amount
     */

    function _finalProcessing(
        IERC20 _dstToken,
        bool _isEthDst,
        uint256 _balanceBefore,
        uint256 _minReturn
    ) internal {
        uint256 _balanceAfter;
        if (_isEthDst) {
            _balanceAfter = _fetchETHBalance();
        } else {
            _balanceAfter = _fetchTokenBalance(address(_dstToken));
        }

        require(
            (_balanceAfter - _balanceBefore) >= _minReturn,
            "slippage too high"
        );

        if (_isEthDst) {
            payable(msg.sender).transfer(_balanceAfter - _balanceBefore);
        } else {
            _dstToken.safeTransfer(
                msg.sender,
                (_balanceAfter - _balanceBefore)
            );
        }
    }

    /**
     * @dev Function transfers the token amount from 'caller' to contract's address.
     * Approves for Aggregation Router of 1inch with 'zero' amount as to change the approve amount
     * you first have to reduce the addresses` allowance to zero by calling `approve(_spender, 0)`
     *  if it is not already 0 to mitigate the race condition described here:
     *  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Approves for Aggregation Router of 1inch with amount to swap.
     * @param _token Token Address
     * @param _actualAmount Entire Token Amount
     * @param _amount Swap Amount
     */

    function _processTransferAndApproval(
        address _token,
        uint256 _actualAmount,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _actualAmount
        );
        IERC20(_token).safeApprove(aggregationRouter, 0);
        IERC20(_token).safeApprove(aggregationRouter, _amount);
    }

    /**
     * @dev Function calculates the Amount with Fees included. Calculates using denominator value declared
     * as constant which is '10000' and feesPercentage which is initalized by the Owner(in basis points).
     * Eg- Suppose if amount is '1000' and feePercentage is 2% (200 basis points) then function will
     * calculate as (1000 * 10000) / (10000 - 200) which will be (approx) 1020.
     * @param  _amount Token Amount
     * @return Returns Amount with Fees included.
     */

    function _calculateAmountWithFees(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return (_amount * denominator) / (denominator - feesPercentage);
    }

    /**
     * @dev Function to fetch Token balance from the contract's address.
     * @param _token Address
     * @return Return token amount balance in the contract's address.
     */

    function _fetchTokenBalance(address _token)
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Function to fetch ether balance from the contract's address.
     * @return Return number of Ether amount stored in the contract's address.
     */

    function _fetchETHBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Function with input parameter as ERC20 token returns 'bool' as 'true' if token address is
     * is zero address or default eth address  else returns 'false' for any other address.
     * @param _token Token Address as IERC20 type.
     * @return Returns 'bool' as 'true' for eth address and zero address else returns 'false'
     */

    function _isETH(IERC20 _token) internal pure returns (bool) {
        return (_token == _ZERO_ADDRESS || _token == _ETH_ADDRESS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IAggregationExecutor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAggregationRouterV4 {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /**
     * @dev Function for swap tokens
     * @param caller Executor or caller address
     * @param desc Swap description
     * @param data swap route data
     * @return returnAmount Amount of destination token after swap
     * @return gasLeft Amount of gasLeft
     *
     */

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 gasLeft);

    /**
     * @dev Function is called when uniswap exchange for token swap
     * @param srcToken source token
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
     * @return returnAmount Amount of tokens after swap
     */

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);

    /**
     * @dev Function is called when uniswapV3 exchange for token swap
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
     * @return returnAmount Amount of tokens after swap
     */

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    /**
     * @dev Function is called when clipper exchange for token swap
     * @param srcToken Source token
     * @param dstToken Destination token
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @return returnAmount Amount of tokens after swap
     */

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAggregationExecutor {
    /**
     * @notice Make calls on `msgSender` with specified data
     * @param msgSender Address of 'caller'
     * @param data Encoded Bytes data specified with call
     */

    function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
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