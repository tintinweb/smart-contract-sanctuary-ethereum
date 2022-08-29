/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IAnyswapRouter.sol



pragma solidity 0.8.0;

interface IAnyswapRouter {
  function anySwapOutNative(address token, address to, uint toChainID) external payable;
}
// File: contracts/interfaces/IBridgeFee.sol



pragma solidity 0.8.0;

interface IBridgeFee {
    struct Fee {
        uint256 value;
        uint256 precisions;
    }

    event BridgeDone(
        address indexed sender,
        address indexed dcrmAddress,
        address indexed tokenAddress,
        uint256 amount,
        uint256 feeAmount
    );

    function configure(
        address _oracleAddress,
        address _feeAddress,
        Fee calldata _fee
    ) external;
}

// File: contracts/interfaces/IBridgeFeeOracle.sol



pragma solidity 0.8.0;

interface IBridgeFeeOracle {
    event OracleCallerUpdated(address indexed oracleCaller);
    event TokenBridgeAmountUpdate(address indexed tokenAddress);
    event TokenBridgeAmountUpdated(address indexed tokenAddress);

    function getBridgeAmount(address tokenAddress)
        external
        view
        returns (uint256, uint256);
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/access/Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/BridgeFee.sol



pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;






/// @title Bridge Fee
/// @notice This contract is the middleware of MadWallet fee system and the AnySwap bridge contract
contract BridgeFee is Ownable, IBridgeFee {
    /// @notice the default fee percentage of bridging tokens
    Fee public defaultFee;

    address internal oracleAddress;

    /// @notice stores the address that will receive the fee
    address public feeAddress;

    /// @notice stores the fee per token
    mapping(address => Fee) public tokenFee;

    /// @notice A function to set the primary contract state variables
    /// @param _oracleAddress BridgeFeeOracle address
    /// @param _feeAddress the value for feeAddress
    /// @param _defaultFee the value for defaultFee
    function configure(
        address _oracleAddress,
        address _feeAddress,
        Fee calldata _defaultFee
    ) external override onlyOwner {
        require(_oracleAddress != address(0), "invalid oracle address");
        require(_feeAddress != address(0), "invalid fee address");

        defaultFee = _defaultFee;
        oracleAddress = _oracleAddress;
        feeAddress = _feeAddress;
    }

    /// @notice A function to set the fee value for a token
    /// @param tokenAddress the token address
    /// @param fee the struct value of the token fee
    function setTokenFee(address tokenAddress, Fee calldata fee) external onlyOwner {
        tokenFee[tokenAddress] = fee;
    }

    /// @notice A function to set the defaultFee
    /// @param fee the struct value of the default fee
    function setDefaultFee(Fee calldata fee) external onlyOwner {
        defaultFee = fee;
    }

    /// @notice A function to transfer ERC20 tokens to AnySwap Bridge
    /// @param tokenAddress the token address to be bridged
    /// @param amount token amount to be bridged
    /// @param dcrmAddress AnySwap Bridge Address
    function transfer(
        address tokenAddress,
        uint256 amount,
        address dcrmAddress
    ) external {
        require(dcrmAddress != address(0), "invalid dcrm address");
        require(amount > 0, "invalid amount");

        IERC20 token = IERC20(tokenAddress);

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(
            amount,
            tokenAddress
        );
        require(token.transferFrom(_msgSender(), dcrmAddress, bridgeAmount), "bridge failed");
        require(token.transferFrom(_msgSender(), feeAddress, feeAmount), "fee transfer failed");
        emit BridgeDone(_msgSender(), dcrmAddress, tokenAddress, bridgeAmount, feeAmount);
    }

    /// @notice A function to transfer native coin to AnySwap Bridge
    function transfer(address routerAddress, address anyToken, address dcrmAddress, uint256 toChainID) external payable {
        require(routerAddress != address(0), "invalid router address");
        require(msg.value > 0, "invalid amount");

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(
            msg.value,
            address(0)
        );

        IAnyswapRouter(routerAddress).anySwapOutNative{value: bridgeAmount}(anyToken, dcrmAddress, toChainID);

        (bool feeAmountSent, ) = payable(feeAddress).call{value: feeAmount}("");
        require(feeAmountSent, "fee transfer failed");

        emit BridgeDone(_msgSender(), routerAddress, address(0), bridgeAmount, feeAmount);
    }

    /// @param _totalAmount the amount has been transferred to this contract
    /// @param tokenAddress the address of the token
    function getFeeAmounts(
        uint256 _totalAmount,
        address tokenAddress
    ) internal view returns (uint256, uint256) {
        Fee memory fee = tokenFee[tokenAddress];

        if (fee.value == 0) {
            fee = defaultFee;
        }
        uint256 feeAmount = _totalAmount * fee.value / 100 / 10 ** fee.precisions;
        uint256 bridgeAmount = _totalAmount - feeAmount;    

        (uint256 min, uint256 max) = IBridgeFeeOracle(oracleAddress)
            .getBridgeAmount(tokenAddress);

        require(min > 0 && max >= min, "unavailable");
        require(min <= bridgeAmount && max >= bridgeAmount, "limit");

        return (feeAmount, bridgeAmount);
    }
}