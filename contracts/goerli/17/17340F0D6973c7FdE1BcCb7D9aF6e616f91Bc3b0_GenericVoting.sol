// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VotingFactory} from "./VotingFactory.sol";
import {VotingLibrary} from "./libs/VotingLibrary.sol";

contract GenericVoting is VotingFactory {
    event GenericVotingCreated(
        uint256 indexed id,
        address indexed addr,
        VotingResultType resultType
    );

    uint256 public genericVotingCount = 0;
    mapping(uint256 => GenericVotingConfig) public genericVotings;

    function createGenericIntTypeVoting(
        VotingLibrary.BaseVotingState calldata votingConfig,
        uint256[] calldata options
    ) external {
        address addr = createIntTypeVoting(votingConfig, options);
        genericVotings[genericVotingCount] = GenericVotingConfig(
            addr,
            VotingResultType.IntType
        );
        genericVotingCount++;
        emit GenericVotingCreated(
            genericVotingCount - 1,
            addr,
            VotingResultType.IntType
        );
    }

    function createGenericStrTypeVoting(
        VotingLibrary.BaseVotingState calldata votingConfig,
        string[] calldata options
    ) external {
        address addr = createStrTypeVoting(votingConfig, options);
        genericVotings[genericVotingCount] = GenericVotingConfig(
            addr,
            VotingResultType.StrType
        );
        genericVotingCount++;
        emit GenericVotingCreated(
            genericVotingCount - 1,
            addr,
            VotingResultType.StrType
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VotingLibrary} from "./libs/VotingLibrary.sol";
import {IBaseVoting} from "./interfaces/IBaseVoting.sol";

contract BaseVoting is IBaseVoting, Initializable {
    event VoteCasted(address indexed voter, uint256 indexed voteOptionNo);
    event BaseVotingInitialized(
        address indexed creator,
        address indexed tokenAddress,
        uint256 optionCount,
        uint256 minTokensRequired,
        uint256 startTime,
        uint256 endTime
    );

    VotingLibrary.BaseVotingState private state;

    mapping(uint256 => uint256) public voteCounts;
    mapping(address => uint256) public votedOptionByUser;

    function initializeVoting(
        VotingLibrary.BaseVotingState calldata args
    ) internal initializer {
        require(args.endTime > args.startTime, "Invalid end time");
        require(args.tokenAddress != address(0), "Invalid token address");
        require(args.optionCount > 0, "Invalid option count");
        state = args;
        emit BaseVotingInitialized(
            msg.sender,
            args.tokenAddress,
            args.optionCount,
            args.minTokensRequired,
            args.startTime,
            args.endTime
        );
    }

    function vote(uint256 voteOptionNo) external override returns (uint256) {
        require(
            voteOptionNo != 0 && voteOptionNo <= state.optionCount,
            "Invalid vote option index"
        );
        require(block.timestamp >= state.startTime, "Voting not started");
        require(block.timestamp <= state.endTime, "Voting ended");
        require(
            IERC20(state.tokenAddress).balanceOf(msg.sender) >=
                state.minTokensRequired,
            "Not enough tokens"
        );
        require(votedOptionByUser[msg.sender] == 0, "Already voted");

        votedOptionByUser[msg.sender] = voteOptionNo;
        voteCounts[voteOptionNo] += 1;
        emit VoteCasted(msg.sender, voteOptionNo);
        return voteCounts[voteOptionNo];
    }

    function getState()
        external
        view
        override
        returns (VotingLibrary.BaseVotingState memory)
    {
        return state;
    }

    function isInitializedAndFinished() external view override returns (bool) {
        return
            getMostVotedVoteOptionIndex() != 0 &&
            state.endTime != 0 &&
            block.timestamp > state.endTime;
    }

    function getMostVotedVoteOptionIndex()
        public
        view
        override
        returns (uint256)
    {
        uint256 mostVotedOptionIndex = 0;
        uint256 mostVotedOptionCount = 0;
        for (uint256 i = 1; i <= state.optionCount; i++) {
            if (voteCounts[i] > mostVotedOptionCount) {
                mostVotedOptionCount = voteCounts[i];
                mostVotedOptionIndex = i;
            }
        }
        return mostVotedOptionIndex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool private initialized;

    modifier initializer() {
        require(!initialized, "Initializable: contract is already initialized");
        initialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VotingLibrary} from "../libs/VotingLibrary.sol";

interface IBaseVoting {
    function getState()
        external
        view
        returns (VotingLibrary.BaseVotingState memory);

    function getMostVotedVoteOptionIndex() external view returns (uint256);

    function isInitializedAndFinished() external view returns (bool);

    function vote(uint256 voteOptionNo) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VotingLibrary} from "../libs/VotingLibrary.sol";
import {IBaseVoting} from "./IBaseVoting.sol";

interface IVotingIntType is IBaseVoting {
    function initialize(
        VotingLibrary.BaseVotingState calldata args,
        uint256[] calldata initOptions
    ) external;

    function getVoteOptionContent(
        uint256 optionNo
    ) external view returns (uint256 res);

    function getMostVotedVoteOptionContent()
        external
        view
        returns (uint256 res);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VotingLibrary} from "../libs/VotingLibrary.sol";
import {IBaseVoting} from "./IBaseVoting.sol";

interface IVotingStrType is IBaseVoting {
    function initialize(
        VotingLibrary.BaseVotingState calldata args,
        string[] calldata initOptions
    ) external;

    function getVoteOptionContent(
        uint256 optionNo
    ) external view returns (string memory res);

    function getMostVotedVoteOptionContent()
        external
        view
        returns (string memory res);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library VotingLibrary {
    struct BaseVotingState {
        address tokenAddress;
        string question;
        string descriptionHash;
        uint256 startTime;
        uint256 endTime;
        uint256 minTokensRequired;
        uint256 optionCount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {VotingIntType} from "./VotingIntType.sol";
import {VotingStrType} from "./VotingStrType.sol";
import {VotingLibrary} from "./libs/VotingLibrary.sol";
import {IBaseVoting} from "./interfaces/IBaseVoting.sol";
import {IVotingIntType} from "./interfaces/IVotingIntType.sol";
import {IVotingStrType} from "./interfaces/IVotingStrType.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VotingFactory is Ownable {
    enum VotingResultType {
        IntType,
        StrType
    }

    struct PredefinedVoting {
        address current;
        address previous;
        VotingResultType resultType;
    }

    struct GenericVotingConfig {
        address votingAddress;
        VotingResultType resultType;
    }

    function createVoting(
        bytes memory bytecode,
        VotingLibrary.BaseVotingState calldata args
    ) internal onlyOwner returns (address addr) {
        bytes32 salt = keccak256(
            abi.encodePacked(
                args.question,
                args.optionCount,
                args.descriptionHash,
                args.startTime,
                block.number,
                args.endTime,
                block.timestamp,
                args.minTokensRequired
            )
        );
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function getCurrentValidVotingAddress(
        PredefinedVoting storage addresses
    ) internal view returns (address) {
        require(addresses.current != address(0), "No voting created");
        IBaseVoting current = IBaseVoting(addresses.current);
        if (current.isInitializedAndFinished()) {
            return addresses.current;
        }
        require(
            addresses.previous != address(0),
            "Current not finished, No previous voting found"
        );
        IBaseVoting previous = IBaseVoting(addresses.previous);
        require(
            previous.isInitializedAndFinished(),
            "Current not finished, Previous not finished"
        );
        return addresses.previous;
    }

    function createIntTypeVoting(
        VotingLibrary.BaseVotingState calldata args,
        uint256[] calldata initOptions
    ) internal returns (address addr) {
        bytes memory bytecode = type(VotingIntType).creationCode;
        addr = createVoting(bytecode, args);
        IVotingIntType(addr).initialize(args, initOptions);
    }

    function createStrTypeVoting(
        VotingLibrary.BaseVotingState calldata args,
        string[] calldata initOptions
    ) internal returns (address addr) {
        bytes memory bytecode = type(VotingStrType).creationCode;
        addr = createVoting(bytecode, args);
        IVotingStrType(addr).initialize(args, initOptions);
    }

    function getIntTypeResult(
        address votingAddress
    ) public view returns (uint256) {
        return IVotingIntType(votingAddress).getMostVotedVoteOptionContent();
    }

    function getStrTypeResult(
        address votingAddress
    ) public view returns (string memory) {
        return IVotingStrType(votingAddress).getMostVotedVoteOptionContent();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";
import {BaseVoting} from "./BaseVoting.sol";
import {VotingLibrary} from "./libs/VotingLibrary.sol";
import {IVotingIntType} from "./interfaces/IVotingIntType.sol";

contract VotingIntType is BaseVoting, IVotingIntType {
    mapping(uint256 => uint256) private options;

    function initialize(
        VotingLibrary.BaseVotingState calldata args,
        uint256[] calldata initOptions
    ) external override {
        require(args.optionCount == initOptions.length, "Invalid option count");
        initializeVoting(args);
        for (uint256 i = 1; i <= args.optionCount; i++) {
            options[i] = initOptions[i - 1];
        }
    }

    function getVoteOptionContent(
        uint256 optionNo
    ) external view override returns (uint256 res) {
        res = options[optionNo];
    }

    function getMostVotedVoteOptionContent()
        external
        view
        override
        returns (uint256 res)
    {
        res = options[getMostVotedVoteOptionIndex()];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";
import {BaseVoting} from "./BaseVoting.sol";
import {VotingLibrary} from "./libs/VotingLibrary.sol";
import {IVotingStrType} from "./interfaces/IVotingStrType.sol";

contract VotingStrType is BaseVoting, IVotingStrType {
    mapping(uint256 => string) private options;

    function initialize(
        VotingLibrary.BaseVotingState calldata args,
        string[] calldata initOptions
    ) external override {
        require(args.optionCount == initOptions.length, "Invalid option count");
        initializeVoting(args);
        for (uint256 i = 1; i <= args.optionCount; i++) {
            options[i] = initOptions[i - 1];
        }
    }

    function getVoteOptionContent(
        uint256 optionNo
    ) external view override returns (string memory res) {
        res = options[optionNo];
    }

    function getMostVotedVoteOptionContent()
        external
        view
        override
        returns (string memory res)
    {
        res = options[getMostVotedVoteOptionIndex()];
    }
}