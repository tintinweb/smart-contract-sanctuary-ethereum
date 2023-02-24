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
pragma solidity ^0.8.14;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/UtilityHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICOEvents.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ICOEvents, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalTokenClaimed;
    uint256 public totalAmountRaisedUSD;
    uint256 public minBuyAmount = 350 * 10**8; //350USD
    uint256 public maxBuyAmount = 25000 * 10**8; //25000USD
    uint32 public constant price = 7700; //in 10**5
    uint32 public constant lockInTime = 270 days; //270 days for tresting 9 months
    address public receiverAddress = 0xFF83C32Aa753dc3C006744D5b451C9bD1fdaE201;
    address public constant USDTOracleAddress =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant ETHOracleAddress =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    bool public enable;

    struct VestingData {
        uint256 totalAmountBought;
        uint256 totalClaimedAmount;
        uint32 investmentCounter;
        bytes email;
    }

    struct UserData {
        uint256 amount;
        uint32 vestingStartTime;
        bool success;
    }

    // User data Mapping for maintain the users accounts
    mapping(bytes => bool) public isVerified;
    mapping(address => VestingData) public userBuyMapping;
    mapping(address => mapping(uint256 => UserData)) public userMapping;

    IERC20 public tokenInstance; //Ukiyo token instance
    IERC20 public usdtInstance; //USDT token instance
    OracleWrapper public USDTOracle = OracleWrapper(USDTOracleAddress);
    OracleWrapper public ETHOracle = OracleWrapper(ETHOracleAddress);

    constructor(address _tokenAddress, address _usdtAddress) {
        tokenInstance = IERC20(_tokenAddress);
        usdtInstance = IERC20(_usdtAddress);
    }

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /* =================== Buy Token Functions ==================== */
    /**
     * buyTokens function is used for buy the tokens
     * That User buy from USDT or ETH
     */
    function buyTokens(
        uint256 amount,
        uint8 _type,
        bytes memory _email
    ) external payable nonReentrant {
        require(enable, "ICO is Disable.");
        require(isVerified[_email], "Your KYC is not done yet.");

        VestingData storage user = userBuyMapping[msg.sender];
        ++user.investmentCounter;

        if (user.investmentCounter > 1) {
            require(
                keccak256(userBuyMapping[msg.sender].email) ==
                    keccak256(_email),
                "Invalid E-mail"
            );
        } else {
            user.email = _email;
        }

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = amount;
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
        (uint256 _tokenAmount, uint256 _amountInUSD) = calculateTokens(
            _type,
            _buyAmount
        );

        require(_amountInUSD >= minBuyAmount,"You can't purchase under minimum limit");
        require(_amountInUSD <= maxBuyAmount,"You can't purchase above maximum limit");

        require(
            (totalTokenSold + _tokenAmount) <=
                (tokenInstance.balanceOf(address(this)) + totalTokenClaimed),
            "ICO does't have enough tokens"
        );
        // updating the user account with the total amount that He/She purchases
        UserData storage userIDData = userMapping[msg.sender][
            user.investmentCounter
        ];
        userIDData.amount = (_tokenAmount);
        userIDData.vestingStartTime = uint32(block.timestamp);

        user.totalAmountBought += _tokenAmount;

        totalTokenSold += _tokenAmount;
        totalAmountRaisedUSD += _amountInUSD;

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

        emit BuyTokenDetail(
            _buyAmount,
            _amountInUSD,
            userIDData.amount,
            user.investmentCounter,
            userIDData.vestingStartTime,
            _email,
            _type,
            msg.sender
        );
    }

    /* =============== Token Calculations =============== */
    /**
     * calculateTokens function is used for calculating the amount of token
     * That User buy from USDT or ETH
     */
    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        returns (uint256 _totalTokens, uint256 _amountUsd)
    {
        //_type==1===> ETH, _type==2===> USDT
        uint256 _amountToUsd;
        uint256 _typeDecimals;

        if (_type == 1) {
            _amountToUsd = ETHOracle.latestAnswer();
            _typeDecimals = 10**18;
        } else if (_type == 2) {
            _amountToUsd = USDTOracle.latestAnswer();
            _typeDecimals = 10**(usdtInstance.decimals());
        }

        _totalTokens =
            (_amount *
                _amountToUsd *
                (10**tokenInstance.decimals()) *
                (10**5)) /
            (_typeDecimals * (10**8) * price);

        _amountUsd = (_amountToUsd * _amount) / _typeDecimals;
    }

    /* =============== Token Claiming Functions =============== */
    /**
     * User can claim the tokens with claimTokens function.
     * after start the vesting.
     */
    function claimTokens(uint32 _IDCounter) public nonReentrant {
        UserData storage user = userMapping[msg.sender][_IDCounter];

        require(
            block.timestamp >= (user.vestingStartTime + lockInTime),
            "You can't claim before nine months"
        );

        require(!user.success, "You already claimed all the tokens.");

        require(user.amount > 0, "User is not registered with vesting");

        uint256 amount = user.amount;

        require(amount > 0, "Amount should be greater then Zero");

        userBuyMapping[msg.sender].totalClaimedAmount += amount;
        user.success = true;
        totalTokenClaimed += amount;

        TransferHelper.safeTransfer(address(tokenInstance), msg.sender, amount);

        emit ClaimedToken(amount, _IDCounter, msg.sender);
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(!enable, "ICO is enabled yet");

        uint256 _balance = tokenInstance.balanceOf(address(this)) -
            (totalTokenSold - totalTokenClaimed);
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(
            address(tokenInstance),
            receiverAddress,
            _balance
        );
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    // Updates Receiver Address
    function updateReceiverAddress(address _receiverAddress)
        external
        onlyOwner
    {
        receiverAddress = _receiverAddress;
    }

    function updateEnableOrDisable() external onlyOwner {
        enable = !enable;
    }

    function updateUserKYC(bytes memory _email) external onlyOwner {
        isVerified[_email] = true;
        emit userKYC(_email);
    }

    function updateMinimumBuyAmount(uint256 _minBuyAmount) external onlyOwner {
        minBuyAmount = _minBuyAmount;
    }

    function updateMaximumBuyAmount(uint256 _maxBuyAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICOEvents {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 amountInUSD,
        uint256 totalTokens,
        uint32 IdCounter,
        uint32 vestingStartTime,
        bytes email,
        uint8 _type,
        address userAddress
    );
    event ClaimedToken(
        uint256 claimedAmount,
        uint256 IDCounter,
        address userAddress
    );

    event userKYC(bytes email);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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
pragma solidity ^0.8.7;

library UtilityHelper{
function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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