//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/VestingEvents.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable, VestingEvents, ReentrancyGuard {
    uint32 public vestingStartDate; // Vesting Start Time
    uint32 public tgeStartDate; // TGE Start time

    /**
     * User Data Structure for users info like:-
     * Users total amount for claim.
     * Users claimed amount that is till claimed.
     * Users claim for how many times user claims the amount.
     * Users category for identify the user vesting category.
     * The Categories are:-
     *      Strategic = 0
     *      Private = 1
     *      Staking_Rewards = 2
     *      Development = 3
     *      Team = 4
     *      Liquidity = 5
     *      Treasury = 6
     *      Advisors = 7
     */
    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
        Category choice;
    }

    struct VestingPhase {
        uint256 totalAmount;
        uint256 tokenAllot;
        uint32 time;
    }

    mapping(address => UserData) public userMapping; // Users Mapping for Users Info.
    mapping(uint8 => uint256[]) internal percentageArray; // Percentage Array for Different Vesting Categories.
    mapping(uint8 => VestingPhase) internal vestingPhaseMapping; // Time Mapping for Vesting Category to Start.
    mapping(address => bool) internal userTGEClaimed; // user TGE claimed or not.

    IERC20 public token; //Meta-East token instance

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        vestingStartDate = uint32(block.timestamp + 60 days); // Vesting Starts After ICO Ends
        tgeStartDate = vestingStartDate + 60 days; // TGE Start Date is Changable
        percentageArray[0] = [
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
        percentageArray[1] = [
            700,
            700,
            700,
            700,
            700,
            1000,
            1000,
            1000,
            1000,
            1000,
            1000
        ];
        percentageArray[2] = [
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500
        ];
        percentageArray[3] = [
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500
        ];
        percentageArray[4] = [
            1100,
            800,
            800,
            800,
            800,
            800,
            1000,
            800,
            800,
            800,
            800,
            100,
            100,
            100,
            100,
            100,
            100,
            100
        ];
        percentageArray[5] = [2000];
        percentageArray[6] = [
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            700,
            500,
            1000,
            1000,
            1000,
            1000,
            1000
        ];
        percentageArray[7] = [
            100,
            200,
            100,
            200,
            100,
            200,
            100,
            1000,
            800,
            800,
            1000,
            800,
            800,
            800,
            1000,
            1000,
            1000
        ];

        // Setting the Vesting Total Amount and Time of Categories
        setVestingCategory(
            (65_000_000 * (10**token.decimals())),
            uint32(30 days),
            0
        );
        setVestingCategory((90_000_000 * (10**token.decimals())), 0, 1);
        setVestingCategory((160_000_000 * (10**token.decimals())), 0, 2);
        setVestingCategory((85_000_000 * (10**token.decimals())), 0, 3);
        setVestingCategory(
            (65_000_000 * (10**token.decimals())),
            uint32(365 days),
            4
        );
        setVestingCategory((45_000_000 * (10**token.decimals())), 0, 5);
        setVestingCategory((250_000_000 * (10**token.decimals())), 0, 6);
        setVestingCategory(
            30_000_000 * (10**token.decimals()),
            uint32(150 days),
            7
        );
    }

    /* =============== Register The Address For Claiming ===============*/
    function setVestingCategory(
        uint256 _amount,
        uint32 _time,
        uint8 _choice
    ) internal {
        VestingPhase storage phase = vestingPhaseMapping[_choice];
        phase.totalAmount = _amount;
        phase.time = _time;
    }

    /* =============== Register The Address For Claiming ===============*/

    /**
     * Register User for Vesting
     * _amount for Total Claimable Amount
     * _choice for Vesting Category
     * _to for User's Address
     */
    function registerUser(
        uint256 _amount,
        Category _choice,
        address _to
    ) external onlyOwner returns (bool) {
        require(userMapping[_to].totalAmount == 0, "User is already register");

        VestingPhase storage phase = vestingPhaseMapping[uint8(_choice)];
        require(
            phase.totalAmount >= (phase.tokenAllot + _amount),
            "Vesting category doesn't have enough token "
        );
        phase.tokenAllot += _amount;

        UserData storage user = userMapping[_to];
        user.totalAmount = _amount;
        user.choice = _choice;

        emit RegisterUser(_amount, _to, _choice);

        return (true);
    }

    /* =============== Token Claiming Functions =============== */
    /**
     * User can claim the tokens with claimTokens function.
     * after start the vesting for that ws-stage.metaniam.comparticular vesting category.
     */
    function claimTokens() external nonReentrant {
        require(
            userMapping[msg.sender].totalAmount > 0,
            "User is not register with any vesting"
        );

        (uint256 _amount, uint8 _claimCount) = tokensToBeClaimed(msg.sender);

        require(_amount > 0, "Amount should be greater then Zero");

        UserData storage user = userMapping[msg.sender];
        user.claimedAmount += _amount;
        user.claims = _claimCount;

        TransferHelper.safeTransfer(address(token), msg.sender, _amount);

        emit ClaimedToken(
            msg.sender,
            user.claimedAmount,
            _claimCount,
            user.choice
        );
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
        uint8 userCategory = uint8(user.choice);
        if (
            (block.timestamp <=
                (vestingStartDate + vestingPhaseMapping[userCategory].time)) ||
            (user.totalAmount == 0)
        ) {
            return (0, 0);
        }

        require(
            user.totalAmount > user.claimedAmount,
            "You already claimed all the tokens."
        );

        uint32 _time = uint32(
            block.timestamp -
                (vestingStartDate + vestingPhaseMapping[userCategory].time)
        ); // take 1 minutes for testing
        _claimCount = uint8((_time / 30 days) + 1); // Claim in Ever Month

        uint8 monthsForPhase = uint8(percentageArray[userCategory].length);
        if (_claimCount > monthsForPhase) {
            _claimCount = monthsForPhase;
        }

        require(
            _claimCount > user.claims,
            "You already claimed for this month."
        );

        if (
            _claimCount == monthsForPhase &&
            userCategory != 1 &&
            userCategory != 5 &&
            userCategory != 6
        ) {
            _toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            _toBeTransfer = vestingCalulations(
                user.totalAmount,
                _claimCount,
                user.claims,
                userCategory
            );
        }
        return (_toBeTransfer, _claimCount);
    }

    /* =============== Vesting Calculations =============== */
    /**
     * vestingCalulations function is used for calculating the amount of token for claim
     */
    function vestingCalulations(
        uint256 userTotalAmount,
        uint8 claimCount,
        uint8 userClaimCount,
        uint8 category
    ) internal view returns (uint256) {
        uint256 amount;

        /**
         * The for loop is running from the count that user claimed
         * till the count that is claimCount.
         * Then Calculate the amount with userTotalAmount and percentage of that category
         */
        for (uint8 i = userClaimCount; i < claimCount; i++) {
            amount += (userTotalAmount * percentageArray[category][i]) / 10000;
        }

        return amount;
    }

    /* ======================== TGE Round ====================== */
    /**
     * tgeAfterVesting function is used for the claim the TGE Round tokens
     */
    function tgeAfterVesting() external nonReentrant {
        UserData storage user = userMapping[msg.sender];
        uint8 userCategory = uint8(user.choice);

        require(!userTGEClaimed[msg.sender], "You already claimed TGE tokens.");

        require(
            userCategory == 1 || userCategory == 5 || userCategory == 6,
            "You are not eligible for TGE round"
        );

        require(
            block.timestamp > tgeStartDate,
            "You can't claim before end of the Vesting."
        );

        require(
            user.totalAmount > user.claimedAmount,
            "You already Claimed all your tokens."
        );

        uint256 _toBeTransfer;

        _toBeTransfer = tgeTokensToBeClaimed(msg.sender);

        require(_toBeTransfer > 0, "Amount should be greater then Zero.");

        user.claimedAmount += _toBeTransfer;

        userTGEClaimed[msg.sender] = true;

        TransferHelper.safeTransfer(address(token), msg.sender, _toBeTransfer);

        emit TGEClaimedToken(msg.sender, user.claimedAmount, user.choice);
    }

    /* =============== Tokens to be claimed in TGE Round =============== */

    function tgeTokensToBeClaimed(address _to)
        public
        view
        returns (uint256 _amount)
    {
        UserData memory user = userMapping[_to];
        uint8 _userCategory = uint8(user.choice);
        uint16 _percentage;
        if (block.timestamp < tgeStartDate) {
            _percentage = 0;
        } else if (userTGEClaimed[_to]) {
            _percentage = 0;
        } else if (_userCategory == 1) {
            _percentage = 500;
        } else if (_userCategory == 5) {
            _percentage = 8000;
        } else if (_userCategory == 6) {
            _percentage = 300;
        } else {
            _percentage = 0;
        }
        _amount = ((user.totalAmount * _percentage) / 10000);
    }

    /* ============== Updates TGE Vesting Start Date ============= */
    function updatetgeStartDate(uint32 _tgeStartDate) external onlyOwner {
        tgeStartDate = _tgeStartDate;
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

interface VestingEvents {
    enum Category {
        Strategic,
        Private,
        StakingRewards,
        Development,
        Team,
        Liquidity,
        Treasury,
        Advisors
    }

    event RegisterUser(uint256 totalTokens, address userAddress, Category choice);
    
    event ClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        uint8 claimCount,
        Category choice
    );

    event TGEClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        Category choice
    );
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