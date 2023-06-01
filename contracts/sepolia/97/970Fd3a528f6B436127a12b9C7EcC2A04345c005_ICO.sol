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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IICO.sol";
import "./interfaces/IVesting.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ReentrancyGuard, IICO {
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint256 public tokenDecimal;
    uint8 public defaultPhase = 1;
    uint8 public totalPhases;

    address public receiverAddress = 0x3D0f5CB4Cd496F8F41a2cCd44ffa2545377E6793;

    //ETH
    address public constant USDTORACLEADRESS =
        0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7; //0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant ETHORACLEADRESS =
        0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; //0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

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
    mapping(bytes => bool) public isVerified;

    IERC20Metadata public tokenInstance; //SDG token instance
    IERC20Metadata public usdtInstance; //USDT token instance
    IVesting public vestingInstance; //vesting contract address

    OracleWrapper public USDTOracle = OracleWrapper(USDTORACLEADRESS);
    OracleWrapper public ETHOracle = OracleWrapper(ETHORACLEADRESS);

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _vestingContract
    ) {
        tokenInstance = IERC20Metadata(_tokenAddress);
        usdtInstance = IERC20Metadata(_usdtAddress);
        vestingInstance = IVesting(_vestingContract);

        totalPhases = 4;
        tokenDecimal = uint256(10 ** tokenInstance.decimals());

        phaseInfo[1] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: uint32(block.timestamp), //1687737600,
            expirationTimestamp: uint32(block.timestamp + 1 days), //1688947199, //26th June 2023 to 9th July 2023
            price: 10000000, //0.1
            isComplete: false
        });
        phaseInfo[2] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: uint32(block.timestamp + 1 days), //1688947200,
            expirationTimestamp: uint32(block.timestamp + 2 days), //1690156799, //10th July 2023 to 23rd July 2023
            isComplete: false,
            price: 15000000 //0.15
        });
        phaseInfo[3] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: uint32(block.timestamp + 2 days), //1690156800,
            expirationTimestamp: uint32(block.timestamp + 3 days), //1691366399, //24th July 2023 to 6th August 2023
            isComplete: false,
            price: 20000000 //0.2
        });
        phaseInfo[4] = Phases({
            tokenLimit: 10_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: uint32(block.timestamp + 3 days), //1691366400,
            expirationTimestamp: uint32(block.timestamp + 4 days), //1692575999, //7th August 2023 to 20th August 2023
            isComplete: false,
            price: 25000000 //0.25
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    // Function lets user buy SDG tokens || Type 1 = BNB or ETH, Type = 2 for USDT
    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount,
        bytes memory _email
    ) external payable override nonReentrant {
        require(isVerified[_email], "Your KYC is not done yet.");
        require(
            block.timestamp < phaseInfo[(totalPhases)].expirationTimestamp,
            "Buying Phases are over"
        );

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = _usdtAmount;
            // Balance Check
            require(
                usdtInstance.balanceOf(msg.sender) >= _buyAmount,
                "User doesn't have enough balance"
            );

            // Allowance Check
            require(
                usdtInstance.allowance(msg.sender, address(this)) >= _buyAmount,
                "Allowance provided is low"
            );
        }
        require(_buyAmount > 0, "Please enter value more than 0");

        // Token calculation
        (
            uint256 _tokenAmount,
            uint8 _phaseNo,
            uint256 _amountToUSD
        ) = calculateTokens(_buyAmount, 0, defaultPhase, _type);

        // Phase info setting
        setPhaseInfo(_tokenAmount, defaultPhase);

        // Setup for vesting in vesting contract
        require(_tokenAmount > 0, "Token Amount should be more then zero");
        vestingInstance.registerUserByICO(_tokenAmount, _phaseNo, msg.sender);

        // Update Phase number and add token amount
        if (phaseInfo[_phaseNo].tokenLimit == phaseInfo[_phaseNo].tokenSold) {
            defaultPhase = _phaseNo + 1;
        } else {
            defaultPhase = _phaseNo;
        }

        totalTokenSold += _tokenAmount;
        totalUSDRaised += _amountToUSD;

        if (_type == 1) {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount);
        } else {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferFrom(
                address(usdtInstance),
                msg.sender,
                receiverAddress,
                _buyAmount
            );
        }
        // Emits event
        emit BuyTokenDetail(
            _buyAmount,
            _tokenAmount,
            _type,
            msg.sender,
            _email
        );
    }

    function getCurrentPhase() public view returns (uint8) {
        uint32 _time = uint32(block.timestamp);

        Phases memory pInfoFirst = phaseInfo[1];
        Phases memory pInfoSecond = phaseInfo[2];
        Phases memory pInfoThird = phaseInfo[3];
        Phases memory pInfoLast = phaseInfo[4];

        if (pInfoLast.expirationTimestamp >= _time) {
            if (pInfoThird.expirationTimestamp >= _time) {
                if (pInfoSecond.expirationTimestamp >= _time) {
                    if (pInfoFirst.expirationTimestamp >= _time) {
                        return 1;
                    } else {
                        return 2;
                    }
                } else {
                    return 3;
                }
            } else {
                return 4;
            }
        } else {
            return 0;
        }
    }

    // Function calculates ETH, USDT according to user's given amount
    function calculateETHorUSDT(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256) {
        // Phases cannot exceed totalPhases
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or Phase expired"
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        // If phase is still going on
        if (block.timestamp < pInfo.expirationTimestamp) {

            uint256 _amountToUSD = ((_amount * pInfo.price) / tokenDecimal);
            (uint256 _cryptoUSDAmount, uint256 _decimals) = cryptoValues(_type);
            return ((_amountToUSD * _decimals) / _cryptoUSDAmount);
        }
        // In case the phase is expired. New will begin after sending the left tokens to the next phase
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateETHorUSDT(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    // Internal function to calculate tokens
    function calculateTokens(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256, uint8, uint256) {
        // Phases cannot exceed totalPhases
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or Phase expired"
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        // If phase is still going on
        if (block.timestamp < pInfo.expirationTimestamp) {

            (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
            uint256 _amountGivenInUsd = ((_amount * _amountToUSD) /
                _typeDecimal);

            // If phase is still going on
            uint256 _tokensAmount = tokensUserWillGet(
                _amountGivenInUsd,
                pInfo.price
            );
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _tokensAmount,
                "Insufficient tokens available in phase"
            );
            return (_tokensAmount, _phaseNo, _amountGivenInUsd);
        }
        // In case the phase is expired. New will begin after sending the left tokens to the next phase
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokens(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    // Tokens user will get according to the price
    function tokensUserWillGet(
        uint256 _amount,
        uint32 _price
    ) internal view returns (uint256) {
        return ((_amount * tokenDecimal * (10 ** 8)) /
            ((10 ** 8) * uint256(_price)));
    }

    // Returns the crypto values used
    function cryptoValues(
        uint8 _type
    ) internal view returns (uint256, uint256) {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = 400000000; //ETHOracle.latestAnswer();
            _typeDecimal = 10 ** 18;
        } else {
            _amountToUSD = 100000000; //USDTOracle.latestAnswer();
            _typeDecimal = uint256(10 ** usdtInstance.decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    // Sets phase info according to the tokens bought
    function setPhaseInfo(uint256 _tokensUserWillGet, uint8 _phaseNo) internal {
        require(_phaseNo <= totalPhases, "All tokens have been exhausted");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            //  when phase has more tokens than reuired
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            //  when  phase has equal tokens as reuired
            else if (
                (pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet
            ) {
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
        require(
            block.timestamp > phaseInfo[(totalPhases)].expirationTimestamp,
            "Phases are not over yet"
        );

        uint256 _balance = tokenInstance.balanceOf(address(this));
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(
            address(tokenInstance),
            receiverAddress,
            _balance
        );
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    // Updates Receiver Address
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        receiverAddress = _receiverAddress;
    }

    function updateUserKYC(bytes memory _email) external onlyOwner {
        isVerified[_email] = true;
        emit userKYC(_email);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IICO {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 tokenAmount,
        uint8 _type,
        address addr,
        bytes email
    );

    event userKYC(bytes email);

    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount,
        bytes memory _email
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IVesting {

    event RegisterUser(uint256 totalTokens, address userAddress, uint8 choice);
    
    event ClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        uint8 claimCount,
        uint8 choice
    );

    function registerUserByICO(
        uint256 _amount,
        uint8 _choice,
        address _to
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

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