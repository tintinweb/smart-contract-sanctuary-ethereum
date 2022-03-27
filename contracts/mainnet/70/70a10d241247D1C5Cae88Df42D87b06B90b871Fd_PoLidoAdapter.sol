// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Helpers} from "./helpers.sol";
import "./interface.sol";
import "../lib/TokenInterface.sol";

/**
 * It helps to stake to Polido.
 */
contract PoLidoAdapter is Helpers, Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    event Deposited(address _beneficiary, uint256 _matic, uint256 _stMatic);

    uint256 public feePercentage;

    function initialize(uint256 _feePercentage) external initializer {
        feePercentage = _feePercentage;
        __Ownable_init_unchained();
    }

    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        feePercentage = _newFeePercentage;
    }

    /**
     * @notice It accepts matic token and performs staking to Polido.
     *         Received stMatic token is sent back to caller address.
     *
     * @param _amount Amount to be staked.
     */
    function deposit(uint256 _amount) external payable {
        uint256 stTokenAmount = _stake(_amount);
        TokenInterface(address(stMaticProxy)).transfer(
            msg.sender,
            stTokenAmount
        );

        emit Deposited(msg.sender, _amount, stTokenAmount);
    }

    /**
     * @notice It accepts matic token and performs staking to Polido.
     *         Received stMatic token is sent back to `_beneficiary` address.
     *
     * @param _amount Amount to be staked.
     */
    function depositFor(address _beneficiary, uint256 _amount)
        external
        payable
    {
        require(_beneficiary != address(0), "Invalid user address");
        uint256 stTokenAmount = _stake(_amount);
        TokenInterface(address(stMaticProxy)).transfer(
            _beneficiary,
            stTokenAmount
        );

        emit Deposited(_beneficiary, _amount, stTokenAmount);
    }

    /**
     * @notice It accepts any token, swaps using 1inch and performs staking
     *         to Polido. Received stMatic token is sent back to caller address.
     *
     * @param _buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAmt The amount of the token to sell.
     * @param _unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param _callData Data from 1inch API.
     */
    function swapAndStake(
        address _buyAddr,
        address _sellAddr,
        uint256 _sellAmt,
        uint256 _unitAmt,
        bytes calldata _callData
    ) external payable {
        uint256 stMaticAmount = _swapAndStake(
            _buyAddr,
            _sellAddr,
            _sellAmt,
            _unitAmt,
            _callData
        );

        TokenInterface(address(stMaticProxy)).transfer(
            msg.sender,
            stMaticAmount
        );
    }

    /**
     * @notice It performs staking to Polido and using bridge sends stMatic to
     *         Polygon network using bridge.
     *
     * @param _beneficiary Beneficiary address which will receive stMatic token.
     * @param _amount Amount to be staked.
     */
    function depositForAndBridge(address _beneficiary, uint256 _amount)
        external
        payable
        returns (uint256)
    {
        uint256 stTokenAmount = _stake(_amount);
        _bridgeToMatic(stTokenAmount, _beneficiary);

        return stTokenAmount;
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1Inch, stake and send stMatic token to matic network.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param _buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAmt The amount of the token to sell.
     * @param _unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param _callData Data from 1inch API.
     * @param _beneficiary ID stores the amount of token brought.
     */
    function swapStakeAndBridge(
        address _buyAddr, // TODO: make it constant
        address _sellAddr,
        uint256 _sellAmt,
        uint256 _unitAmt,
        bytes calldata _callData,
        address _beneficiary
    ) external payable {
        uint256 stMaticAmount = _swapAndStake(
            _buyAddr,
            _sellAddr,
            _sellAmt,
            _unitAmt,
            _callData
        );

        _bridgeToMatic(stMaticAmount, _beneficiary);
    }

    /**
     *  @notice Send stMatic tokens to _beneficiary in matic network.
     */
    function _bridgeToMatic(uint256 _stTokenAmount, address _beneficiary)
        private
    {
        TokenInterface(address(stMaticProxy)).approve(
            mintableERC20Proxy,
            _stTokenAmount
        );

        bytes memory depositData = abi.encode(_stTokenAmount);

        rootChainManagerProxy.depositFor(
            _beneficiary,
            address(stMaticProxy),
            depositData
        );
    }

    function calculateFee(uint256 _amt) public view returns (uint256) {
        return (_amt.mul(feePercentage)).div(FEE_DENOMINATOR);
    }

    /**
     * @dev 1inch API swap handler
     * @param oneInchData - contains data returned from 1inch API. Struct defined in interfaces.sol
     * @param ethAmt - Eth to swap for .value()
     */
    function oneInchSwap(OneInchData memory oneInchData, uint256 ethAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            oneInchData.sellToken
        );

        uint256 fees = calculateFee(oneInchData._sellAmt);
        uint256 finalSellAmt = oneInchData._sellAmt.sub(fees);
        uint256 _sellAmt18 = convertTo18(_sellDec, finalSellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(oneInchData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = oneInchAddr.call{value: ethAmt}(
            oneInchData.callData
        );
        if (!success) revert("1Inch-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    /**
     * @dev Gets the swapping data from 1inch's API.
     * @param oneInchData Struct with multiple swap data defined in interfaces.sol
     */
    function _sell(OneInchData memory oneInchData)
        internal
        returns (OneInchData memory)
    {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint256 ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = oneInchData._sellAmt;
        } else {
            require(
                TokenInterface(address(_sellAddr)).transferFrom(
                    msg.sender,
                    address(this),
                    oneInchData._sellAmt
                ),
                "Matic not approved"
            );
            approve(
                TokenInterface(_sellAddr),
                oneInchAddr,
                oneInchData._sellAmt
            );
        }

        oneInchData._buyAmt = oneInchSwap(oneInchData, ethAmt);

        return oneInchData;
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1Inch and stake to Polido.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     */
    function _swapAndStake(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData
    ) private returns (uint256) {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        oneInchData = _sell(oneInchData);

        maticToken.approve(address(stMaticProxy), oneInchData._buyAmt);
        uint256 stTokenAmount = stMaticProxy.submit(oneInchData._buyAmt);

        emit Deposited(msg.sender, oneInchData._buyAmt, stTokenAmount);

        return stTokenAmount;
    }

    /**
     * @notice Perform staking to polido and returns amount of stMatic tokens.
     */
    function _stake(uint256 _amount) private returns (uint256) {
        require(_amount > 0, "Invalid amount");
        require(
            maticToken.transferFrom(msg.sender, address(this), _amount),
            "Matic not approved"
        );

        maticToken.approve(address(stMaticProxy), _amount);
        uint256 stTokenAmount = stMaticProxy.submit(_amount);

        return stTokenAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DSMath} from "./math.sol";
import {Basic} from "./basic.sol";

import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    // Mainnet
    IERC20 public constant maticToken =
        IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
    StMaticProxy public constant stMaticProxy =
        StMaticProxy(0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599);

    RootchainManagerProxy public constant rootChainManagerProxy =
        RootchainManagerProxy(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);

    address public constant mintableERC20Proxy =
        address(0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf);

    /**
     * @dev 1Inch Address
     */
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;

    uint256 public constant FEE_DENOMINATOR = 10000;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "../lib/TokenInterface.sol";

interface StMaticProxy {
    function submit(uint256 _amount) external returns (uint256);

    function requestWithdraw(uint256 _amount) external;

    function claimTokens(uint256 _tokenId) external;
}

interface RootchainManagerProxy {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

interface OneInchInterace {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] calldata callAddresses,
        bytes calldata callDataConcat,
        uint256[] calldata starts,
        uint256[] calldata gasLimitsAndValues
    )
    external
    payable
    returns (uint256 returnAmount);
}

struct OneInchData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    bytes callData;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface is IERC20 {
   function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DSMath {
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(x, y);
    }

    function sub(uint256 x, uint256 y)
        internal
        pure
        virtual
        returns (uint256 z)
    {
        z = SafeMath.sub(x, y);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.mul(x, y);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.div(x, y);
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, 10**27);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DSMath} from "./math.sol";
import "../lib/TokenInterface.sol";

abstract contract Basic is DSMath {
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function convert18ToDec(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns (uint256 _amt) {
        _amt = address(token) == ethAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
        internal
        view
        returns (uint256 buyDec, uint256 sellDec)
    {
        buyDec = address(buyAddr) == ethAddr ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ? 18 : sellAddr.decimals();
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }
}