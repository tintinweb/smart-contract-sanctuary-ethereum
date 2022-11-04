//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/VestingEvents.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable, VestingEvents, ReentrancyGuard {
    uint32 public vestingStartDate;

    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
        Category choice;
    }

    mapping(address => UserData) public userMapping;
    mapping(uint8 => uint256[]) internal percentageArray;
    mapping(uint8 => uint32) internal timeMapping;

    IERC20 public token; //Meta-East token instance

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        vestingStartDate = uint32(block.timestamp);
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
        timeMapping[0] = uint32(1 minutes);
        timeMapping[1] = 0;
        timeMapping[2] = 0;
        timeMapping[3] = 0;
        timeMapping[4] = uint32(12 minutes);
        timeMapping[5] = 0;
        timeMapping[6] = 0;
        timeMapping[7] = uint32(5 minutes);
    }

    /* =============== Register The Address For Claiming ===============*/

    // @dev note choice are
    //     Strategic = 0
    //     Private = 1
    //     Staking_Rewards = 2
    //     Development = 3
    //     Team = 4
    //     Liquidity = 5
    //     Treasury = 6
    //     Advisors = 7
    function registerUser(
        uint256 _amount,
        Category _choice,
        address _to
    ) external onlyOwner returns (bool) {
        require(userMapping[_to].totalAmount == 0, "User is already register");

        UserData storage user = userMapping[_to];
        user.totalAmount = _amount;
        user.choice = _choice;

        emit RegisterUser(_amount, _to, _choice);

        return (true);
    }

    /* =============== Token Claiming Functions =============== */
    function claimTokens() external nonReentrant {
        require(
            userMapping[msg.sender].totalAmount > 0,
            "User is not register with any vesting"
        );

        (uint256 _amount, uint8 _claimCount) = tokensToBeClaimed(msg.sender);

        UserData storage user = userMapping[msg.sender];
        user.claimedAmount += _amount;
        user.claims = _claimCount;

        require(_amount > 0, "Amount should be greater then Zero");

        TransferHelper.safeTransfer(address(token), msg.sender, _amount);

        emit ClaimedToken(msg.sender, _amount, _claimCount, user.choice);
    }

    /* =============== Vesting Calculations =============== */
    function vestingCalulations(
        uint256 userTotalAmount,
        uint8 claimCount,
        uint8 userClaimCount,
        uint8 category
    ) internal view returns (uint256) {
        uint256 amount;

        for (uint8 i = userClaimCount; i < claimCount; i++) {
            amount += (userTotalAmount * percentageArray[category][i]) / 10000;
        }

        return amount;
    }

    /* =============== Tokens to be claimed =============== */

    function tokensToBeClaimed(address to)
        public
        view
        returns (uint256, uint8)
    {
        UserData memory user = userMapping[to];
        uint8 userCategory = uint8(user.choice);

        require(
            block.timestamp >= (vestingStartDate + timeMapping[userCategory]), //30days
            "You can't claim before Vesting start time"
        ); // take 2 minutes for testing

        uint8 monthsForPhase = uint8(percentageArray[userCategory].length);
        require(
            user.totalAmount > user.claimedAmount,
            "You already claimed all the tokens."
        );

        uint32 time = uint32(
            block.timestamp - (vestingStartDate + timeMapping[userCategory])
        ); // take 1 minutes for testing
        uint8 claimCount = uint8((time / 1 minutes) + 1); // 30 days take 1 minutes for testing

        if (claimCount > monthsForPhase) {
            claimCount = monthsForPhase;
        }

        require(
            claimCount > user.claims,
            "You already claimed for this month."
        );

        uint256 toBeTransfer;
        if (
            claimCount == monthsForPhase &&
            userCategory != 1 &&
            userCategory != 5 &&
            userCategory != 6
        ) {
            toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            toBeTransfer = vestingCalulations(
                user.totalAmount,
                claimCount,
                user.claims,
                userCategory
            );
        }
        return (toBeTransfer, claimCount);
    }
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

    event RegisterUser(uint256 totalTokens, address addr, Category _choice);
    
    event ClaimedToken(
        address addr,
        uint256 toBeTransfer,
        uint8 claimCount,
        Category _choice
    );
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