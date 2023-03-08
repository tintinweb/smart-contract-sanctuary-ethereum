/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IWithdrawalUtilsV0.sol


pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/ITemplateUtilsV0.sol


pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAuthorizationUtilsV0.sol


pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol


pragma solidity ^0.8.0;




interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File: @api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol


pragma solidity ^0.8.0;


/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// File: contracts/WarGame.sol

// test: 0xcC9De99b32750a0550380cb8495588ca2f48d533
// previous: 0x37Ae76D5c3AdB25790F64215062E512a9d2262b7
// latest: 0xB383940282D6624b9e7F8e4e1AEFD78e27A987F6
pragma solidity ^0.8.9;





interface WarToken {
    function gameMint(address _to, uint256 _amount) external;

    function gameBurn(address _to, uint256 _amount) external;
}

contract WARGAME is Ownable, ReentrancyGuard, RrpRequesterV0 {
    using SafeMath for uint256;

    uint256 public totalPlays;

    /******************/

    mapping(address => bytes32) public userId;
    mapping(bytes32 => address) public requestUser;
    mapping(bytes32 => uint256) public randomNumber;
    mapping(address => uint256) public betsize;
    mapping(address => uint256) public userHighscore;

    mapping(address => bool) public userPool;
    mapping(uint256 => address) public userIndex;
    mapping(address => address) public userToOpponent;
    mapping(address => address) public opponentToUser;
    mapping(address => uint256) public card;

    mapping(address => bool) public inGame;

    mapping(address => uint256) public drawTime;

    uint256 public poolIndex;

    uint256 public highscore;
    address public highscoreHolder;

    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;

    uint256 public qfee = 50000000000000;
    uint256 waitTime = 600; //1800;
    WarToken warToken;

    event bet(address indexed from, uint256 amount);
    event win(
        address indexed player,
        address indexed opponent,
        uint256 myCard,
        uint256 theirCard,
        bool won,
        uint256 winAmount,
        uint256 oppWinAmount
    );

    event EnteredPool(address indexed player);

    event RequestedUint256(bytes32 indexed requestId);
    event ReceivedUint256(
        address indexed requestAddress,
        bytes32 indexed requestId,
        uint256 response
    );

    bool gameActive;

    address botContract;

    constructor(address _airnodeRrp, address _warTokenAddress)
        RrpRequesterV0(_airnodeRrp)
    {
        warToken = WarToken(_warTokenAddress);
    }

    modifier onlyOwnerBot() {
        require(
            (msg.sender ==owner()) || (msg.sender == botContract),
            "Only Owner or Bot"
        );
        _;
    }

    function setBot(address _botContract) public onlyOwner {
        botContract = _botContract;
    }

    function setQfee(uint256 _qfee) public onlyOwner {
        require(_qfee <= 150000000000000, "Dont set fee too high");
        require(_qfee >= 50000000000000, "Dont set fee too low");
        qfee = _qfee;
    }

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function makeRequestUint256(address userAddress) internal {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        );
        userId[userAddress] = requestId;
        requestUser[requestId] = userAddress;
        emit RequestedUint256(requestId);
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(requestUser[requestId] != address(0), "Request ID not known");
        uint256 qrngUint256 = abi.decode(data, (uint256));
        // Do what you want with `qrngUint256` here...
        randomNumber[requestId] = qrngUint256;

        emit ReceivedUint256(requestUser[requestId], requestId, qrngUint256);
    }

    function enterPool(uint256 _amount) public payable {
        require(!inGame[msg.sender], "Can only enter one pool at a time");
        require(_amount > 0, "Must include a bet amount");
        require(
            msg.value >= qfee,
            "Must small gas fee for the random number generator"
        );
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        //address payable sendAddress = payable(sponsorWallet);        
        payable(sponsorWallet).transfer(qfee);
        userPool[msg.sender] = true;
        inGame[msg.sender] = true;
        userIndex[poolIndex+1] = msg.sender;
        makeRequestUint256(msg.sender);
        betsize[msg.sender] = _amount;

        warToken.gameBurn(msg.sender, _amount);        
        emit bet(msg.sender, _amount);
        emit EnteredPool(msg.sender);
        ++poolIndex;
    }

    function leavePool(address user) internal {
        require(userPool[user], "Not in any pool");
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        // Find the index of the user in userIndex and delete it
        uint256 userIndexToDelete;
        for (uint256 i = 1; i <= poolIndex; i++) {
            if (userIndex[i] == user) {
                userIndexToDelete = i;
                delete userIndex[i];
                break;
            }
        }

        // Shift all the elements after the deleted index to the left by one position
        for (uint256 i = userIndexToDelete; i <= poolIndex; i++) {
            userIndex[i] = userIndex[i + 1];
        }

        // Delete the last element of userIndex
        delete userIndex[poolIndex];
        // Delete the user from userPool
        delete userPool[user];
        // Decrement the pool index
        --poolIndex;
    }

    function ForceLeavePool() public {
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        if (!userPool[msg.sender]) {
            revert("Cannot leave Pool if you arent in the pool");
        }
        if (userToOpponent[msg.sender] == address(0)) {
            warToken.gameMint(msg.sender, betsize[msg.sender]);
        }
        delete randomNumber[userId[msg.sender]];
        delete requestUser[userId[msg.sender]];
        delete betsize[msg.sender];
        delete userId[msg.sender];
        delete inGame[msg.sender];
        leavePool(msg.sender);
    }

    function OpponentIssue() public {
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        if (card[msg.sender] != 0 && userToOpponent[msg.sender] != address(0)) {
            revert("Opponent is selected. wait for reveal");
        }
        if (!inGame[msg.sender]) {
            revert("Must be in game");
        }
        warToken.gameMint(msg.sender, betsize[msg.sender]);
        delete randomNumber[userId[msg.sender]];
        delete requestUser[userId[msg.sender]];
        delete betsize[msg.sender];
        delete userId[msg.sender];
        delete card[msg.sender];
        delete drawTime[msg.sender];
        delete inGame[msg.sender];
    }

    function Draw() public nonReentrant {
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        require(
            poolIndex >= 2 || opponentToUser[msg.sender] != address(0),
            "Pool is low. wait for more players to enter"
        );
        require(userId[msg.sender] != 0, "User has no unrevealed numbers.");
        require(
            (randomNumber[userId[msg.sender]] != uint256(0)),
            "Random number not ready, try again."
        );
        require(
            card[msg.sender] == 0,
            "Card has been assigned, reveal to view results"
        );

        bytes32 requestId = userId[msg.sender];
        uint256 secretnum = (randomNumber[requestId] % 12) + 1;
        uint256 opponentNum;
        address opponent;
        if (opponentToUser[msg.sender] == address(0)) {
            opponentNum = (randomNumber[requestId] % (poolIndex-1)+1);
            opponent = userIndex[opponentNum];            
            if (userIndex[opponentNum] == msg.sender) {
                if (opponentNum >= (poolIndex)) {
                    --opponentNum;
                    if (opponentNum == 0) {
                        revert(
                            "Pool has emptied while you were drawing. please try to draw again"
                        );
                    }
                } else {
                    ++opponentNum;
                }
            }
            opponent = userIndex[opponentNum];            
            userToOpponent[msg.sender] = opponent;
            opponentToUser[opponent] = msg.sender;
            userToOpponent[opponent] = msg.sender;
            opponentToUser[msg.sender] = opponent;
        }
        else
        {
            opponent = opponentToUser[msg.sender];
        }

        card[msg.sender] = secretnum;
        drawTime[msg.sender] = block.timestamp;
        delete randomNumber[requestId];
        delete requestUser[requestId];
        delete userId[msg.sender];
        if (userPool[msg.sender]) {            
            leavePool(msg.sender);            
        }
        if (userPool[userToOpponent[msg.sender]]) {
            leavePool(userToOpponent[msg.sender]);
        }
    }

    function Reveal() public nonReentrant {
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        require(
            card[msg.sender] != 0,
            "Card has not been assigned, draw your card."
        );
        address opponent = userToOpponent[msg.sender];
        require(card[opponent] != 0, "Opponent has not drawn a card");
        uint256 myCard = card[msg.sender];
        uint256 theirCard = card[opponent];
        uint256 userBet = betsize[msg.sender];
        uint256 opponentBet = betsize[opponent];

        uint256 payoutWin;
        uint256 loseDelta;
        uint256 winDelta;        
        uint256 emitWin;
        uint256 emitLose;
        if (userBet >= opponentBet) {
            payoutWin = userBet + opponentBet;
            loseDelta = userBet - opponentBet;  
            emitLose = opponentBet;          
        } else {
            payoutWin = userBet + userBet;
            winDelta = opponentBet - userBet;
            emitLose = userBet;
        }
        if (myCard > theirCard) {            
            if (payoutWin > highscore) {
                highscore = payoutWin;
                highscoreHolder = msg.sender;
            }
            if (payoutWin > userHighscore[msg.sender]) {
                userHighscore[msg.sender] = payoutWin;
            }
            emitWin = (payoutWin - userBet);
            
            emit win(msg.sender, opponent, myCard, theirCard, true, emitWin, emitLose);
            warToken.gameMint(msg.sender, payoutWin);
            warToken.gameMint(opponent, winDelta);
        } else if (myCard == theirCard) {
            emit win(
                msg.sender,
                opponent,
                myCard,
                theirCard,
                false,
                0,
                0
            );
            warToken.gameMint(msg.sender, userBet);
            warToken.gameMint(opponent, opponentBet);
        } else {
            warToken.gameMint(msg.sender, loseDelta);
            uint256 payopponent = (opponentBet + userBet) - loseDelta;
            warToken.gameMint(opponent, payopponent);
            emitWin = (payopponent - opponentBet);
            emit win(
                msg.sender,
                opponent,
                myCard,
                theirCard,
                false,
                emitLose,
                emitWin
            );
            if (payopponent > highscore) {
                highscore = payopponent;
                highscoreHolder = opponent;
            }
            if (payopponent > userHighscore[opponent]) {
                userHighscore[opponent] = payopponent;
            }
        }
        ++totalPlays;
        delete userToOpponent[msg.sender];
        delete opponentToUser[msg.sender];
        delete userToOpponent[opponent];
        delete opponentToUser[opponent];
        delete card[msg.sender];
        delete card[opponent];
        delete betsize[msg.sender];
        delete betsize[opponent];
        delete drawTime[msg.sender];
        delete drawTime[opponent];
        delete inGame[msg.sender];
        delete inGame[opponent];
    }

    function ForceWin() public {
        if (!gameActive) {
            revert("Game has been temporarily Paused");
        }
        if (waitTime==0) {
            revert("Ask Dev to Set a Wait Time");
        }
        if (card[msg.sender] == 0 && !inGame[msg.sender]) {
            revert("Must have selected a card");
        }
        uint256 lastCallTime = drawTime[msg.sender];
        if (lastCallTime == 0 || block.timestamp < (lastCallTime + waitTime)) {
            revert("Opponent has 30 minutes to draw a card");
        }
        address opponent = userToOpponent[msg.sender];
        if (card[opponent] != 0) {
            revert("Opponent has drawn a card");
        }
        uint256 totalBet = betsize[msg.sender] + betsize[opponent];
        bytes32 oppRequestId = userId[opponent];

        warToken.gameMint(msg.sender, totalBet);
        delete randomNumber[oppRequestId];
        delete requestUser[oppRequestId];
        delete userId[msg.sender];
        delete userId[opponent];
        delete userPool[opponent];
        delete userPool[msg.sender];
        delete userToOpponent[msg.sender];
        delete opponentToUser[msg.sender];
        delete userToOpponent[opponent];
        delete opponentToUser[opponent];
        delete card[msg.sender];
        delete card[opponent];
        delete betsize[msg.sender];
        delete betsize[opponent];
        delete drawTime[msg.sender];
        delete drawTime[opponent];
        delete inGame[msg.sender];
        delete inGame[opponent];
    }

    function ChangeStatus(bool _newStatus) public onlyOwnerBot {
        gameActive = _newStatus;
    }

    function ChangeWinTime(uint256 _waitTime) public onlyOwner {
        waitTime = _waitTime;
    }

    function fixGameIndex() external onlyOwnerBot {
        address[] memory nonZeroIndices = new address[](poolIndex + 1);
        uint256 count = 0;
        uint256 userIndexToDelete;

        // Collect all the non-zero indices from userIndex
        for (uint256 i = 1; i <= poolIndex; i++) {
            if (userIndex[i] != address(0)) {
                nonZeroIndices[count] = userIndex[i];
                count++;
            }
        }

        // Update userIndex with the non-zero indices and adjust poolIndex accordingly
        if (count > 0) {
            for (uint256 i = 0; i < count; i++) {
                userIndex[i + 1] = nonZeroIndices[i];
            }
            poolIndex = count;
        } else {
            poolIndex = 0;
        }

        // Delete any remaining elements in userIndex
        for (uint256 i = count + 1; i <= poolIndex; i++) {
            delete userIndex[i];
        }
    }
}