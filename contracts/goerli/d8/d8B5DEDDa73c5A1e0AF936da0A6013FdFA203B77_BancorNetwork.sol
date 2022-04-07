// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IBancorNetwork.sol";
import "./IConversionPathFinder.sol";
import "./converter/interfaces/IConverter.sol";
import "./converter/interfaces/IConverterAnchor.sol";
import "./utility/ContractRegistryClient.sol";
import "./utility/TokenHolder.sol";

import "./token/interfaces/IDSToken.sol";
import "./token/SafeERC20Ex.sol";
import "./token/ReserveToken.sol";

import "./bancorx/interfaces/IBancorX.sol";

// interface of older converters for backward compatibility
interface ILegacyConverter {
    function change(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        uint256 minReturn
    ) external returns (uint256);
}

/**
 * @dev This contract is the main entry point for Bancor token conversions.
 * It also allows for the conversion of any token in the Bancor Network to any other token in a single
 * transaction by providing a conversion path.
 *
 * A note on Conversion Path: Conversion path is a data structure that is used when converting a token
 * to another token in the Bancor Network, when the conversion cannot necessarily be done by a single
 * converter and might require multiple 'hops'.
 * The path defines which converters should be used and what kind of conversion should be done in each step.
 *
 * The path format doesn't include complex structure; instead, it is represented by a single array
 * in which each 'hop' is represented by a 2-tuple - converter anchor & target token.
 * In addition, the first element is always the source token.
 * The converter anchor is only used as a pointer to a converter (since converter addresses are more
 * likely to change as opposed to anchor addresses).
 *
 * Format:
 * [source token, converter anchor, target token, converter anchor, target token...]
 */
contract BancorNetwork is IBancorNetwork, TokenHolder, ContractRegistryClient, ReentrancyGuard {
    using SafeMath for uint256;
    using ReserveToken for IReserveToken;
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    struct ConversionStep {
        IConverter converter;
        IConverterAnchor anchor;
        IReserveToken sourceToken;
        IReserveToken targetToken;
        address payable beneficiary;
        bool isV28OrHigherConverter;
    }

    /**
     * @dev triggered when a conversion between two tokens occurs
     */
    event Conversion(
        IConverterAnchor indexed anchor,
        IReserveToken indexed sourceToken,
        IReserveToken indexed targetToken,
        uint256 sourceAmount,
        uint256 targetAmount,
        address trader
    );

    /**
     * @dev initializes a new BancorNetwork instance
     */
    constructor(IContractRegistry registry) public ContractRegistryClient(registry) {}

    /**
     * @dev returns the conversion path between two tokens in the network
     *
     * note that this method is quite expensive in terms of gas and should generally be called off-chain
     */
    function conversionPath(IReserveToken sourceToken, IReserveToken targetToken)
        public
        view
        returns (address[] memory)
    {
        IConversionPathFinder pathFinder = IConversionPathFinder(_addressOf(CONVERSION_PATH_FINDER));
        return pathFinder.findPath(sourceToken, targetToken);
    }

    /**
     * @dev returns the expected target amount of converting a given amount on a given path
     *
     * note that there is no support for circular paths
     */
    function rateByPath(address[] memory path, uint256 sourceAmount) public view override returns (uint256) {
        // verify that the number of elements is larger than 2 and odd
        require(path.length > 2 && path.length % 2 == 1, "ERR_INVALID_PATH");

        uint256 amount = sourceAmount;

        // iterate over the conversion path
        for (uint256 i = 2; i < path.length; i += 2) {
            IReserveToken sourceToken = IReserveToken(path[i - 2]);
            address anchor = path[i - 1];
            IReserveToken targetToken = IReserveToken(path[i]);
            IConverter converter = IConverter(payable(IConverterAnchor(anchor).owner()));
            (amount, ) = _getReturn(converter, sourceToken, targetToken, amount);
        }

        return amount;
    }

    /**
     * @dev converts the token to any other token in the bancor network by following a predefined conversion path and
     * transfers the result tokens to a target account
     *
     * note that the network should already have been given allowance of the source token (if not ETH)
     */
    function convertByPath2(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary
    ) public payable nonReentrant greaterThanZero(minReturn) returns (uint256) {
        // verify that the path contains at least a single 'hop' and that the number of elements is odd
        require(path.length > 2 && path.length % 2 == 1, "ERR_INVALID_PATH");

        // validate msg.value and prepare the source token for the conversion
        _handleSourceToken(IReserveToken(path[0]), IConverterAnchor(path[1]), sourceAmount);

        // check if beneficiary is set
        if (beneficiary == address(0)) {
            beneficiary = msg.sender;
        }

        // convert and get the resulting amount
        ConversionStep[] memory data = _createConversionData(path, beneficiary);
        uint256 amount = _doConversion(data, sourceAmount, minReturn);

        // handle the conversion target tokens
        _handleTargetToken(data, amount, beneficiary);

        return amount;
    }

    /**
     * @dev converts any other token to BNT in the bancor network by following a predefined conversion path and
     * transfers the result to an account on a different blockchain
     *
     * note that the network should already have been given allowance of the source token (if not ETH)
     */
    function xConvert(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        bytes32 targetBlockchain,
        bytes32 targetAccount,
        uint256 conversionId
    ) public payable greaterThanZero(minReturn) returns (uint256) {
        IReserveToken targetToken = IReserveToken(path[path.length - 1]);
        IBancorX bancorX = IBancorX(_addressOf(BANCOR_X));

        // verify that the destination token is BNT
        require(targetToken == IReserveToken(_addressOf(BNT_TOKEN)), "ERR_INVALID_TARGET_TOKEN");

        // convert and get the resulting amount
        uint256 amount = convertByPath2(path, sourceAmount, minReturn, payable(address(this)));

        // grant BancorX allowance
        targetToken.ensureApprove(address(bancorX), amount);

        // transfer the resulting amount to BancorX
        bancorX.xTransfer(targetBlockchain, targetAccount, amount, conversionId);

        return amount;
    }

    /**
     * @dev allows a user to convert a token that was sent from another blockchain into any other token on the
     * BancorNetwork
     *
     * note that ideally this transaction should've been created before the previous conversion is even complete, so
     * so the input amount isn't known at that point - the amount is actually take from the
     * BancorX contract directly by specifying the conversion id
     */
    function completeXConversion(
        address[] memory path,
        IBancorX bancorX,
        uint256 conversionId,
        uint256 minReturn,
        address payable beneficiary
    ) public returns (uint256) {
        // verify that the source token is the BancorX token
        require(path[0] == address(bancorX.token()), "ERR_INVALID_SOURCE_TOKEN");

        // get conversion amount from BancorX contract
        uint256 amount = bancorX.getXTransferAmount(conversionId, msg.sender);

        // perform the conversion
        return convertByPath2(path, amount, minReturn, beneficiary);
    }

    /**
     * @dev executes the actual conversion by following the conversion path
     */
    function _doConversion(
        ConversionStep[] memory data,
        uint256 sourceAmount,
        uint256 minReturn
    ) private returns (uint256) {
        uint256 targetAmount;

        // iterate over the conversion data
        for (uint256 i = 0; i < data.length; i++) {
            ConversionStep memory stepData = data[i];

            // newer converter
            if (stepData.isV28OrHigherConverter) {
                // transfer the tokens to the converter only if the network contract currently holds the tokens
                // not needed with ETH or if it's the first conversion step
                if (i != 0 && data[i - 1].beneficiary == address(this) && !stepData.sourceToken.isNativeToken()) {
                    stepData.sourceToken.safeTransfer(address(stepData.converter), sourceAmount);
                }
            } else {
                assert(address(stepData.sourceToken) != address(stepData.anchor));
                // grant allowance for it to transfer the tokens from the network contract
                stepData.sourceToken.ensureApprove(address(stepData.converter), sourceAmount);
            }

            // do the conversion
            if (!stepData.isV28OrHigherConverter) {
                targetAmount = ILegacyConverter(address(stepData.converter)).change(
                    stepData.sourceToken,
                    stepData.targetToken,
                    sourceAmount,
                    1
                );
            } else if (stepData.sourceToken.isNativeToken()) {
                targetAmount = stepData.converter.convert{ value: msg.value }(
                    stepData.sourceToken,
                    stepData.targetToken,
                    sourceAmount,
                    msg.sender,
                    stepData.beneficiary
                );
            } else {
                targetAmount = stepData.converter.convert(
                    stepData.sourceToken,
                    stepData.targetToken,
                    sourceAmount,
                    msg.sender,
                    stepData.beneficiary
                );
            }

            emit Conversion(
                stepData.anchor,
                stepData.sourceToken,
                stepData.targetToken,
                sourceAmount,
                targetAmount,
                msg.sender
            );
            sourceAmount = targetAmount;
        }

        // ensure the trade meets the minimum requested amount
        require(targetAmount >= minReturn, "ERR_RETURN_TOO_LOW");

        return targetAmount;
    }

    /**
     * @dev validates msg.value and prepares the conversion source token for the conversion
     */
    function _handleSourceToken(
        IReserveToken sourceToken,
        IConverterAnchor anchor,
        uint256 sourceAmount
    ) private {
        IConverter firstConverter = IConverter(payable(anchor.owner()));
        bool isNewerConverter = _isV28OrHigherConverter(firstConverter);

        if (msg.value > 0) {
            require(msg.value == sourceAmount, "ERR_ETH_AMOUNT_MISMATCH");
            require(sourceToken.isNativeToken(), "ERR_INVALID_SOURCE_TOKEN");
            require(isNewerConverter, "ERR_CONVERTER_NOT_SUPPORTED");
        } else {
            require(!sourceToken.isNativeToken(), "ERR_INVALID_SOURCE_TOKEN");
            if (isNewerConverter) {
                // newer converter - transfer the tokens from the sender directly to the converter
                sourceToken.safeTransferFrom(msg.sender, address(firstConverter), sourceAmount);
            } else {
                // otherwise claim the tokens
                sourceToken.safeTransferFrom(msg.sender, address(this), sourceAmount);
            }
        }
    }

    /**
     * @dev handles the conversion target token if the network still holds it at the end of the conversion
     */
    function _handleTargetToken(
        ConversionStep[] memory data,
        uint256 targetAmount,
        address payable beneficiary
    ) private {
        ConversionStep memory stepData = data[data.length - 1];

        // network contract doesn't hold the tokens, do nothing
        if (stepData.beneficiary != address(this)) {
            return;
        }

        IReserveToken targetToken = stepData.targetToken;
        assert(!targetToken.isNativeToken());
        targetToken.safeTransfer(beneficiary, targetAmount);
    }

    /**
     * @dev creates a memory cache of all conversion steps data to minimize logic and external calls during conversions
     */
    function _createConversionData(address[] memory path, address payable beneficiary)
        private
        view
        returns (ConversionStep[] memory)
    {
        ConversionStep[] memory data = new ConversionStep[](path.length / 2);

        // iterate the conversion path and create the conversion data for each step
        uint256 i;
        for (i = 0; i < path.length - 1; i += 2) {
            IConverterAnchor anchor = IConverterAnchor(path[i + 1]);
            IConverter converter = IConverter(payable(anchor.owner()));
            IReserveToken targetToken = IReserveToken(path[i + 2]);

            data[i / 2] = ConversionStep({ // set the converter anchor
                anchor: anchor, // set the converter
                converter: converter, // set the source/target tokens
                sourceToken: IReserveToken(path[i]),
                targetToken: targetToken, // requires knowledge about the next step, so initialize in the next phase
                beneficiary: address(0), // set flags
                isV28OrHigherConverter: _isV28OrHigherConverter(converter)
            });
        }

        // set the beneficiary for each step
        for (i = 0; i < data.length; i++) {
            ConversionStep memory stepData = data[i];
            // check if the converter in this step is newer as older converters don't even support the beneficiary argument
            if (stepData.isV28OrHigherConverter) {
                if (i == data.length - 1) {
                    // converter in this step is newer, beneficiary is the user input address
                    stepData.beneficiary = beneficiary;
                } else if (data[i + 1].isV28OrHigherConverter) {
                    // the converter in the next step is newer, beneficiary is the next converter
                    stepData.beneficiary = address(data[i + 1].converter);
                } else {
                    // the converter in the next step is older, beneficiary is the network contract
                    stepData.beneficiary = payable(address(this));
                }
            } else {
                // converter in this step is older, beneficiary is the network contract
                stepData.beneficiary = payable(address(this));
            }
        }

        return data;
    }

    bytes4 private constant GET_RETURN_FUNC_SELECTOR = bytes4(keccak256("getReturn(address,address,uint256)"));

    // using a static call to get the return from older converters
    function _getReturn(
        IConverter dest,
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) internal view returns (uint256, uint256) {
        bytes memory data = abi.encodeWithSelector(GET_RETURN_FUNC_SELECTOR, sourceToken, targetToken, sourceAmount);
        (bool success, bytes memory returnData) = address(dest).staticcall(data);

        if (success) {
            if (returnData.length == 64) {
                return abi.decode(returnData, (uint256, uint256));
            }

            if (returnData.length == 32) {
                return (abi.decode(returnData, (uint256)), 0);
            }
        }

        return (0, 0);
    }

    bytes4 private constant IS_V28_OR_HIGHER_FUNC_SELECTOR = bytes4(keccak256("isV28OrHigher()"));

    // using a static call to identify converter version
    // can't rely on the version number since the function had a different signature in older converters
    function _isV28OrHigherConverter(IConverter converter) internal view returns (bool) {
        bytes memory data = abi.encodeWithSelector(IS_V28_OR_HIGHER_FUNC_SELECTOR);
        (bool success, bytes memory returnData) = address(converter).staticcall{ gas: 4000 }(data);

        if (success && returnData.length == 32) {
            return abi.decode(returnData, (bool));
        }

        return false;
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function getReturnByPath(address[] memory path, uint256 sourceAmount) public view returns (uint256, uint256) {
        return (rateByPath(path, sourceAmount), 0);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function convertByPath(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary,
        address, /* affiliateAccount */
        uint256 /* affiliateFee */
    ) public payable override returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, beneficiary);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function convert(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn
    ) public payable returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, address(0));
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function convert2(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address, /* affiliateAccount */
        uint256 /* affiliateFee */
    ) public payable returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, address(0));
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function convertFor(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary
    ) public payable returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, beneficiary);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function convertFor2(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary,
        address, /* affiliateAccount */
        uint256 /* affiliateFee */
    ) public payable greaterThanZero(minReturn) returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, beneficiary);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function claimAndConvert(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn
    ) public returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, address(0));
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function claimAndConvert2(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address, /* affiliateAccount */
        uint256 /* affiliateFee */
    ) public returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, address(0));
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function claimAndConvertFor(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary
    ) public returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, beneficiary);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function claimAndConvertFor2(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary,
        address, /* affiliateAccount */
        uint256 /* affiliateFee */
    ) public returns (uint256) {
        return convertByPath2(path, sourceAmount, minReturn, beneficiary);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

interface IBancorNetwork {
    function rateByPath(address[] memory path, uint256 sourceAmount) external view returns (uint256);

    function convertByPath(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary,
        address affiliateAccount,
        uint256 affiliateFee
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./token/interfaces/IReserveToken.sol";

/**
 * @dev Conversion Path Finder interface
 */
interface IConversionPathFinder {
    function findPath(IReserveToken sourceToken, IReserveToken targetToken) external view returns (address[] memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IConverterAnchor.sol";

import "../../utility/interfaces/IOwned.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Converter interface
 */
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) external view returns (uint256, uint256);

    function convert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IReserveToken reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 fee) external;

    function addReserve(IReserveToken token, uint32 weight) external;

    function transferReservesOnUpgrade(address newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address newOwner) external;

    function acceptTokenOwnership() external;

    function reserveTokenCount() external view returns (uint16);

    function reserveTokens() external view returns (IReserveToken[] memory);

    function connectors(IReserveToken reserveToken)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IReserveToken connectorToken) external view returns (uint256);

    function connectorTokens(uint256 index) external view returns (IReserveToken);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     */
    event Activation(uint16 indexed converterType, IConverterAnchor indexed anchor, bool indexed activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     */
    event Conversion(
        IReserveToken indexed sourceToken,
        IReserveToken indexed targetToken,
        address indexed trader,
        uint256 sourceAmount,
        uint256 targetAmount,
        int256 conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     *
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     */
    event TokenRateUpdate(address indexed token1, address indexed token2, uint256 rateN, uint256 rateD);

    /**
     * @dev triggered when the conversion fee is updated
     */
    event ConversionFeeUpdate(uint32 prevFee, uint32 newFee);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./Owned.sol";
import "./Utils.sol";
import "./interfaces/IContractRegistry.sol";

/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";
    bytes32 internal constant NETWORK_SETTINGS = "NetworkSettings";

    // address of the current contract registry
    IContractRegistry private _registry;

    // address of the previous contract registry
    IContractRegistry private _prevRegistry;

    // only the owner can update the contract registry
    bool private _onlyOwnerCanUpdateRegistry;

    /**
     * @dev verifies that the caller is mapped to the given contract name
     */
    modifier only(bytes32 contractName) {
        _only(contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 contractName) internal view {
        require(msg.sender == _addressOf(contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     */
    constructor(IContractRegistry initialRegistry) internal validAddress(address(initialRegistry)) {
        _registry = IContractRegistry(initialRegistry);
        _prevRegistry = IContractRegistry(initialRegistry);
    }

    /**
     * @dev updates to the new contract registry
     */
    function updateRegistry() external {
        // verify that this function is permitted
        require(msg.sender == owner() || !_onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract registry
        IContractRegistry newRegistry = IContractRegistry(_addressOf(CONTRACT_REGISTRY));

        // verify that the new contract registry is different and not zero
        require(newRegistry != _registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract registry is pointing to a non-zero contract registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract registry before replacing it
        _prevRegistry = _registry;

        // replace the current contract registry with the new contract registry
        _registry = newRegistry;
    }

    /**
     * @dev restores the previous contract registry
     */
    function restoreRegistry() external ownerOnly {
        // restore the previous contract registry
        _registry = _prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract registry
     */
    function restrictRegistryUpdate(bool restrictOwnerOnly) public ownerOnly {
        // change the permission to update the contract registry
        _onlyOwnerCanUpdateRegistry = restrictOwnerOnly;
    }

    /**
     * @dev returns the address of the current contract registry
     */
    function registry() public view returns (IContractRegistry) {
        return _registry;
    }

    /**
     * @dev returns the address of the previous contract registry
     */
    function prevRegistry() external view returns (IContractRegistry) {
        return _prevRegistry;
    }

    /**
     * @dev returns whether only the owner can update the contract registry
     */
    function onlyOwnerCanUpdateRegistry() external view returns (bool) {
        return _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     */
    function _addressOf(bytes32 contractName) internal view returns (address) {
        return _registry.addressOf(contractName);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/ITokenHolder.sol";

import "./Owned.sol";
import "./Utils.sol";

import "../token/ReserveToken.sol";

/**
 * @dev This contract provides a safety mechanism for allowing the owner to
 * send tokens that were sent to the contract by mistake back to the sender
 *
 * we consider every contract to be a 'token holder' since it's currently not possible
 * for a contract to deny receiving tokens
 */
contract TokenHolder is ITokenHolder, Owned, Utils {
    using ReserveToken for IReserveToken;

    // prettier-ignore
    receive() external payable override virtual {}

    /**
     * @dev withdraws funds held by the contract and sends them to an account
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) public virtual override ownerOnly validAddress(to) {
        reserveToken.safeTransfer(to, amount);
    }

    /**
     * @dev withdraws multiple funds held by the contract and sends them to an account
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) public virtual override ownerOnly validAddress(to) {
        uint256 length = reserveTokens.length;
        require(length == amounts.length, "ERR_INVALID_LENGTH");

        for (uint256 i = 0; i < length; ++i) {
            reserveTokens[i].safeTransfer(to, amounts[i]);
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/**
 * @dev DSToken interface
 */
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address recipient, uint256 amount) external;

    function destroy(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev Extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IReserveToken.sol";

import "./SafeERC20Ex.sol";

/**
 * @dev This library implements ERC20 and SafeERC20 utilities for reserve tokens, which can be either ERC20 tokens or ETH
 */
library ReserveToken {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the address that represents an ETH reserve
    IReserveToken public constant NATIVE_TOKEN_ADDRESS = IReserveToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev returns whether the provided token represents an ERC20 or ETH reserve
     */
    function isNativeToken(IReserveToken reserveToken) internal pure returns (bool) {
        return reserveToken == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the balance of the reserve token
     */
    function balanceOf(IReserveToken reserveToken, address account) internal view returns (uint256) {
        if (isNativeToken(reserveToken)) {
            return account.balance;
        }

        return toIERC20(reserveToken).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the reserve token
     */
    function safeTransfer(
        IReserveToken reserveToken,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNativeToken(reserveToken)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(reserveToken).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the reserve token from a specific holder using the allowance mechanism
     *
     * note that the function ignores a reserve token which represents an ETH reserve
     */
    function safeTransferFrom(
        IReserveToken reserveToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * note that this function ignores a reserve token which represents an ETH reserve
     */
    function ensureApprove(
        IReserveToken reserveToken,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).ensureApprove(spender, amount);
    }

    /**
     * @dev utility function that converts an IReserveToken to an IERC20
     */
    function toIERC20(IReserveToken reserveToken) private pure returns (IERC20) {
        return IERC20(address(reserveToken));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Bancor X interface
 */
interface IBancorX {
    function token() external view returns (IERC20);

    function xTransfer(
        bytes32 toBlockchain,
        bytes32 to,
        uint256 amount,
        uint256 id
    ) external;

    function getXTransferAmount(uint256 xTransferId, address receiver) external view returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly() {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Contract Registry interface
 */
interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IOwned.sol";

/**
 * @dev Token Holder interface
 */
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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