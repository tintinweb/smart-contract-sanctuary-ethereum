//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICOEvents.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ICOEvents, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalTokenClaimed;
    uint256 public totalAmountRaisedUSD;
    uint256 public maxBuyLimit = 2500 * 10**8;
    uint32 public constant price = 1500; //in 10**5
    uint32 public startTime;
    uint32 public expirationTime;
    uint32 public startVestingTime;
    address public receiverAddress = 0xE380a93Db38f46866fdf4Ca86005cb51CC259771;
    address public constant USDTOracleAddress =
        0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7;
    address public constant ETHOracleAddress =
        0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;

    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
    }

    // User data Mapping for maintain the users accounts
    mapping(address => UserData) public userMapping;
    uint256[] percentageArray;

    IERC20 public tokenInstance; //Meta-East token instance
    IERC20 public usdtInstance; //USDT token instance
    OracleWrapper public USDTOracle = OracleWrapper(USDTOracleAddress);
    OracleWrapper public ETHOracle = OracleWrapper(ETHOracleAddress);

    constructor(address _tokenAddress, address _usdtAddress) {
        tokenInstance = IERC20(_tokenAddress);
        usdtInstance = IERC20(_usdtAddress);
        startTime = uint32(block.timestamp);
        expirationTime = startTime + 2 minutes; // ICO For Two Months 60 days for main net and 2 minutes for the test
        percentageArray = [
            700,
            700,
            700,
            700,
            700,
            700,
            700,
            700,
            800,
            800,
            800,
            1000,
            1000
        ];
        startVestingTime = uint32(2 minutes); // Two Months After ICO Ends 60 days for main net and 2 minutes for the test
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
    function buyTokens(uint8 _type, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(block.timestamp < expirationTime, "ICO Ended");
        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = _amount;
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

        require(
            _amountInUSD <= maxBuyLimit,
            "You can't buy above the upper cap of USD"
        );

        require(
            (totalTokenSold + _tokenAmount) <=
                tokenInstance.balanceOf(address(this)),
            "ICO does't have enough tokens"
        );

        // updating the user account with the total amount that He/She purchases
        userMapping[msg.sender].totalAmount += (_tokenAmount);
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
            _tokenAmount,
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
            _amountToUsd = 400000000; //ETHOracle.latestAnswer();
            _typeDecimals = 10**18;
        } else if (_type == 2) {
            _amountToUsd = 100000000; //USDTOracle.latestAnswer();
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
    function claimTokens() public nonReentrant {
        require(
            block.timestamp >= (expirationTime + startVestingTime),
            "You can't claim before two months"
        ); // take 2 minutes for testing

        require(
            userMapping[msg.sender].totalAmount > 0,
            "User is not register with Seed vesting"
        );

        (uint256 amount, uint8 claimCount) = tokensToBeClaimed(msg.sender);

        require(amount > 0, "Amount should be greater then Zero");

        UserData storage user = userMapping[msg.sender];
        user.claimedAmount += amount;
        user.claims = claimCount;
        totalTokenClaimed += amount;

        TransferHelper.safeTransfer(address(tokenInstance), msg.sender, amount);

        emit ClaimedToken(user.claimedAmount, claimCount, msg.sender);
    }

    /* =============== Tokens to be claimed =============== */
    /**
     * tokensToBeClaimed function can be used for checking the claimable amount of the user.
     */
    function tokensToBeClaimed(address to)
        public
        view
        returns (uint256 _toBeTransfer, uint8 _claimCount)
    {
        UserData memory user = userMapping[to];
        if (
            (block.timestamp <= (expirationTime + startVestingTime)) ||
            (user.totalAmount == 0)
        ) {
            return (0, 0);
        }

        require(
            user.totalAmount > user.claimedAmount,
            "You already claimed all the tokens."
        );

        uint32 time = uint32(
            block.timestamp - (expirationTime + startVestingTime)
        );
        uint8 monthsForPhase = uint8(percentageArray.length);
        uint8 claimCount = ((uint8(time / 1 minutes)) + 1); // Claim in Ever Month 30 days for main net and 1 minutes for testing

        if (claimCount > monthsForPhase) {
            claimCount = monthsForPhase;
        }

        require(
            claimCount > user.claims,
            "You already claimed for this month."
        );

        uint256 toBeTransfer;

        if (claimCount == monthsForPhase) {
            toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            toBeTransfer = vestingCalulations(
                user.totalAmount,
                claimCount,
                user.claims
            );
        }
        return (toBeTransfer, claimCount);
    }

    /* =============== Vesting Calculations =============== */
    /**
     * vestingCalulations function is used for calculating the amount of token for claim
     */
    function vestingCalulations(
        uint256 userTotalAmount,
        uint8 claimCount,
        uint8 userClaimCount
    ) internal view returns (uint256 _amount) {
        for (uint8 i = userClaimCount; i < claimCount; i++) {
            _amount += (userTotalAmount * percentageArray[i]) / 10000;
        }
    }

    function changeVestingPercentagePerMonth(uint256[] memory array)
        external
        onlyOwner
    {
        require(
            block.timestamp < (expirationTime + startVestingTime),
            "You can't claim before two months"
        );
        uint256 currentPercentage = vestingPercentageCalulations(
            percentageArray
        );
        uint256 newPercentage = vestingPercentageCalulations(array);
        require(currentPercentage == newPercentage, "Percentage is not valid");
        percentageArray = array;
    }

    function vestingPercentageCalulations(uint256[] memory array)
        internal
        pure
        returns (uint256)
    {
        uint256 amount;
        for (uint8 i = 0; i < array.length; i++) {
            amount += array[i];
        }
        return amount;
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(block.timestamp > expirationTime, "ICO is not over yet");

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

    // Updates Upper Cap
    function updateMaxBuyLimit(uint256 _maxBuyLimit) external onlyOwner {
        maxBuyLimit = _maxBuyLimit;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface ICOEvents {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 amountInUSD,
        uint256 totalTokens,
        uint8 _type,
        address userAddress
    );
    event ClaimedToken(
        uint256 claimedAmount,
        uint8 claimCount,
        address userAddress
    );
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