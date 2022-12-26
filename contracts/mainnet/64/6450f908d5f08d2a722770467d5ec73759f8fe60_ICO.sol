/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/interfaces/OracleWrapper.sol


pragma solidity ^0.8.6;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}
// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.6;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/libraries/TransferHelper.sol


pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}
// File: contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.8.6;

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
// File: contracts/ICO.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;







/**
* @title ICO
* @dev smart contract ICO
* @custom:dev-run-script file_path
*/

contract ICO is Ownable, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint256 public tokenDecimal;
    uint8 public defaultPhase;
    uint8 public totalPhases;
    using SafeMath for uint256;

    address public receiverAddress = 0x3D0f5CB4Cd496F8F41a2cCd44ffa2545377E6793;
    // 2nd receiver address for receive 30 percent;
    address public receiverAddress_2 = 0xE90e6435536A722A75506c111F804cEcD358cFdb;

    uint8 public SharedPercentage;

    // ETH
    address public USDTOracleAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public ETHOracleAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /* ================ STRUCT SECTION ================ */
    // Stores phases
    struct Phases {
        uint256 tokenSold;
        uint256 tokenLimit;
        uint32 startTime;
        uint32 expirationTimestamp;
        uint32 price; // 10 ** 8
        bool isComplete;
    }
    mapping(uint256 => Phases) public phaseInfo;

    IERC20 public tokenInstance; //SDG token instance
    IERC20 public usdtInstance; //USDT token instance
    IERC20 public usdtInstance_2; //USDT token instance for 2nd Sahres
    OracleWrapper public USDTOracle = OracleWrapper(USDTOracleAddress);
    OracleWrapper public ETHOracle = OracleWrapper(ETHOracleAddress);

    /* ================ EVENT SECTION ================ */
    // Emits when tokens are bought
    event TokensBought(address buyerAddress, uint256 buyAmount, uint256 tokenAmount, uint32 buyTime, uint8 buyType );
    event Deposite(address payee, uint256 Amount);

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(address _tokenAddress, address _usdtAddress, address _usdtAddress_2) {
        tokenInstance = IERC20(_tokenAddress);
        usdtInstance = IERC20(_usdtAddress);
        usdtInstance_2 = IERC20(_usdtAddress_2);

        totalPhases = 5;

        // _1stShares = 70;
        SharedPercentage = 30;

        tokenDecimal = uint256(10**tokenInstance.decimals());

        phaseInfo[0] = Phases({
            tokenLimit: 121_200_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1670630400,
            expirationTimestamp: 1673395199,
            price: 49500, //0.00049500
            isComplete: false
        });
        phaseInfo[1] = Phases({
            tokenLimit: 646_400_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1682121600,
            expirationTimestamp: 1684799999,
            isComplete: false,
            price: 74300 //0.00074300
        });
        phaseInfo[2] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1695859200,
            expirationTimestamp: 1696809599,
            isComplete: false,
            price: 104000 //0.00104000
        });
        phaseInfo[3] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1697414400,
            expirationTimestamp: 1700179199,
            isComplete: false,
            price: 145500 //0.00145500
        });
        phaseInfo[4] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1729123200,
            expirationTimestamp: 1731887999,
            isComplete: false,
            price: 174700 //0.00174700
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    // Function lets user buy SDG tokens || Type 1 = BNB or ETH, Type = 2 for USDT
    function buyTokens(uint8 _type, uint256 _usdtAmount) external payable nonReentrant
    {
        require(block.timestamp < phaseInfo[(totalPhases - 1)].expirationTimestamp, "Buying Phases are over" );

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) { _buyAmount = msg.value; }
        // If type == 2
        else { _buyAmount = _usdtAmount;
            // Balance Check
            require( usdtInstance.balanceOf(msg.sender) >= _buyAmount, "User doesn't have enough balance" );
            // Allowance Check
            require( usdtInstance.allowance(msg.sender, address(this)) >= _buyAmount, "Allowance provided is low" );
        }
        require(_buyAmount > 0, "Please enter value more than 0");

        // Token calculation
        (
            uint256 _tokenAmount,
            uint8 _phaseNo,
            uint256 _amountToUSD
        ) = calculateTokens(_type, _buyAmount);

        // Phase info setting
        setPhaseInfo(_tokenAmount, defaultPhase);

        // Update Phase number and add token amount
        if (phaseInfo[_phaseNo].tokenLimit == phaseInfo[_phaseNo].tokenSold) {
            defaultPhase = _phaseNo + 1;
        } else {
            defaultPhase = _phaseNo;
        }

        totalTokenSold += _tokenAmount;
        totalUSDRaised += _amountToUSD;

        // Transfers SDG to user
        TransferHelper.safeTransfer(address(tokenInstance), msg.sender, _tokenAmount );

        // ???????????????????

        uint256 num = calculateRecieverShares(_buyAmount, SharedPercentage);
        if (_type == 1) {
            // Sending deposited currency to the receiver address
            // depositETH(receiverAddress_2, _buyAmount);

            TransferHelper.safeTransferETH(receiverAddress_2, num);
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount.sub(num));
        } else {
            // Sending deposited currency to the receiver address

            // depositUsdt(address(usdtInstance), receiverAddress, _buyAmount);
            TransferHelper.safeTransferFrom(address(usdtInstance_2), msg.sender, receiverAddress_2, num );
            TransferHelper.safeTransferFrom(address(usdtInstance), msg.sender, receiverAddress, _buyAmount.sub(num));
        }
        // Emits event
        emit TokensBought(msg.sender, _buyAmount, _tokenAmount, uint32(block.timestamp), _type);
    }

    // *************************__************************* // 
    // ***** New functions for calculation sold tokens or stakes between holders *****

    // calculate usdt or ether between holders and then transfer to each holder's wallet
    function calculateRecieverShares(uint256 buyAmount, uint8 _percent) internal pure returns(uint256)
    {
        // uint256 EthAmount = (buyAmount % uint256(100)) * uint256(30);
        uint256 _share = buyAmount.div(100);
        _share = _share.mul(_percent);
        return _share;
    }


    // functions to deposit Ether or USDT
    // function depositETH(address receiverAddress, uint256 ETHamount) public returns(bool) {
    //     TransferHelper.safeTransferETH(receiverAddress, ETHamount);
    //     emit Deposite(receiverAddress, ETHamount);
    //     return true;
    // }

    // function depositUsdt(address usdt, address receiverAddress, uint256 Usdtamount) public returns(bool) {
    //     TransferHelper.safeTransferFrom(address(usdt), msg.sender, receiverAddress, Usdtamount ); 
    //     emit Deposite(receiverAddress, Usdtamount);
    //     return true;
    // }


    // *************************__************************* // 

    // Function calculates tokens according to user's given amount
    function calculateTokens(uint8 _type, uint256 _amount) public view returns (uint256, uint8, uint256 )
    {
        (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
        uint256 _amountGivenInUsd = ((_amount * _amountToUSD) / _typeDecimal);

        return calculateTokensInternal(_amountGivenInUsd, defaultPhase, 0);
    }

    // Internal function to calculate tokens
    function calculateTokensInternal(uint256 _amount, uint8 _phaseNo, uint256 _previousTokens ) internal view returns (uint256, uint8, uint256)
    {
        // Phases cannot exceed totalPhases
        require(_phaseNo < totalPhases, "Not enough tokens in the contract or Phase expired" );
        Phases memory pInfo = phaseInfo[_phaseNo];

        // If phase is still going on
        if (block.timestamp < pInfo.expirationTimestamp) {
            require(uint32(block.timestamp) > pInfo.startTime, "Phase has not started yet");
            // If phase is still going on
            uint256 _tokensAmount = tokensUserWillGet(_amount, pInfo.price);
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) - pInfo.tokenSold;
            require(_tokensLeftToSell >= _tokensAmount, "Insufficient tokens available in phase");
            return (_tokensAmount, _phaseNo, _amount);
        }
        // In case the phase is expired. New will begin after sending the left tokens to the next phase
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokensInternal(_amount, _phaseNo + 1, _remainingTokens + _previousTokens);
        }
    }

    // Tokens user will get according to the price
    function tokensUserWillGet(uint256 _amount, uint32 _price) internal view returns (uint256)
    {
        return ((_amount * tokenDecimal * (10**8)) / ((10**8) * uint256(_price)));
    }

    // Returns the crypto values used
    function cryptoValues(uint8 _type) internal view returns (uint256, uint256) {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = ETHOracle.latestAnswer();
            _typeDecimal = 10**18;
        } else {
            _amountToUSD = USDTOracle.latestAnswer();
            _typeDecimal = uint256(10**usdtInstance.decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    // Sets phase info according to the tokens bought
    function setPhaseInfo(uint256 _tokensUserWillGet, uint8 _phaseNo) internal {
        require(_phaseNo < totalPhases, "All tokens have been exhausted");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            //  when phase has more tokens than reuired
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            //  when  phase has equal tokens as reuired
            else if ((pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet) {
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;
            }
            // when tokens required are more than left tokens in phase
            else {
                revert("Phase doesn't enough tokens");
            }
        }
        // if tokens left in phase afterb completion of expiration time
        else {
            uint256 remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;
            pInfo.tokenLimit = pInfo.tokenSold;
            pInfo.isComplete = true;

            phaseInfo[_phaseNo + 1].tokenLimit += remainingTokens;
            setPhaseInfo(_tokensUserWillGet, _phaseNo + 1);
        }
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(block.timestamp > phaseInfo[(totalPhases - 1)].expirationTimestamp, "Phases are not over yet" );

        uint256 _balance = tokenInstance.balanceOf(address(this));
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(address(tokenInstance),receiverAddress,_balance);
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    // Updates Receiver Address
    function updateReceiverAddress(address _receiverAddress) external onlyOwner
    {
        receiverAddress = _receiverAddress;
    }

}