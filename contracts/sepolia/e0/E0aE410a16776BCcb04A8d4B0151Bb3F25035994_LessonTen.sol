// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AFoundryCourseChallenge} from "AFoundryCourseChallenge.sol";
import {IERC20} from "IERC20.sol";

contract LessonTen is AFoundryCourseChallenge {
    error LessonTen__FailedToSolve();

    string private constant LESSON_IMAGE = "ipfs://QmXKkrYX72KznwQhnE7tmSsNtCerPZFwCkGctUWf5RshMe";
    uint256 private constant COST_TO_SOLVE = 1e18;

    IERC20 public immutable i_erc20;

    constructor(address fcn, address erc20) AFoundryCourseChallenge(fcn) {
        i_erc20 = IERC20(erc20);
    }

    /*
     * CALL THIS FUNCTION!
     * 
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(string memory yourTwitterHandle) external {
        bool success = i_erc20.transferFrom(msg.sender, address(this), COST_TO_SOLVE);
        if (!success) {
            revert LessonTen__FailedToSolve();
        }
        _updateAndRewardSolver(yourTwitterHandle);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function description() external pure override returns (string memory) {
        return "Cyfrin Foundry Full Course: I APPROVE of you getting this NFT!... Get it? Do you get my joke? ";
    }

    function attribute() external pure override returns (string memory) {
        return "Token understander";
    }

    function specialImage() external pure override returns (string memory) {
        return LESSON_IMAGE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFoundryCourseChallenge} from "IFoundryCourseChallenge.sol";
import {IFoundryCourseNft} from "IFoundryCourseNft.sol";
import {Ownable} from "Ownable.sol";

abstract contract AFoundryCourseChallenge is IFoundryCourseChallenge, Ownable {
    error AFoundryCourseChallenge__CantBeZeroAddress();

    string private constant BLANK_TWITTER_HANLE = "";
    string private constant BLANK_SPECIAL_DESCRIPTION = "";
    IFoundryCourseNft internal immutable i_foundryCourseNft;

    constructor(address FoundryCourseNftNft) {
        if (FoundryCourseNftNft == address(0)) {
            revert AFoundryCourseChallenge__CantBeZeroAddress();
        }
        i_foundryCourseNft = IFoundryCourseNft(FoundryCourseNftNft);
    }

    /*
     * @param twitterHandleOfSolver - The twitter handle of the solver.
     * It can be left blank.
     */
    function _updateAndRewardSolver(string memory twitterHandleOfSolver) internal {
        IFoundryCourseNft(i_foundryCourseNft).mintNft(msg.sender, twitterHandleOfSolver);
    }

    function extraDescription(address /* user */ ) external view virtual returns (string memory) {
        return BLANK_SPECIAL_DESCRIPTION;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFoundryCourseChallenge {
    function description() external view returns (string memory);

    function extraDescription(address user) external view returns (string memory);

    function specialImage() external view returns (string memory);

    function attribute() external view returns (string memory);

    /* Each contract must have a "solveChallenge" function, however, the signature
     * maybe be different in all cases because of different input parameters.
     * Because of this, we are not going to define the function here.
     *
     * This function should call back to the FoundryCourseNft contract
     * to mint the NFT.
     */
    // function solveChallenge() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFoundryCourseNft {
    function mintNft(address receiver, string memory twitterHandle) external returns (uint256);

    function addChallenge(address challengeContract) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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