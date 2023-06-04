// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AFoundryCourseChallenge} from "AFoundryCourseChallenge.sol";
import {LessonThirteenHelper} from "13-LessonHelper.sol";

interface YourContract {
    function owner() external view returns (address);
    function getNumber() external view returns (int256);
}

contract LessonThirteen is AFoundryCourseChallenge {
    error LessonThirteen__NotSolved();

    string private constant LESSON_IMAGE = "ipfs://QmdHgyTYLg3hpjMdf6D9nE7Udwubxk2WvmJtv2KewCd6KM"; // TODO
    uint256 private constant TARGET_NUMBER = 1337;
    uint256 private LESSON_VERSION = 2;
    uint256 private COURSE_VERSION = 3;

    LessonThirteenHelper private immutable i_helperContract;

    constructor(address fcn) AFoundryCourseChallenge(fcn) {
        i_helperContract = new LessonThirteenHelper();
    }

    /*
     * CALL THIS FUNCTION!
     * 
     * @param yourContract = the contract you're using to solve this
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(address yourContract, string memory yourTwitterHandle) external {
        YourContract yc = YourContract(yourContract);
        int256 number = yc.getNumber();
        address yourOwner = yc.owner();

        if (yourOwner != msg.sender) {
            revert LessonThirteen__NotSolved();
        }
        (bool success, bytes memory data) =
            address(i_helperContract).delegatecall(abi.encodeWithSignature("addTen(int256)", number));

        if (!success) {
            revert LessonThirteen__NotSolved();
        }
        uint256 result = abi.decode(data, (uint256));

        if (result != TARGET_NUMBER) {
            revert LessonThirteen__NotSolved();
        }
        _updateAndRewardSolver(yourTwitterHandle);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function description() external pure override returns (string memory) {
        return "Cyfrin Foundry Full Course: I'd delegate call you to write me some contracts. ";
    }

    function attribute() external pure override returns (string memory) {
        return "Proxy Foxy";
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
pragma solidity ^0.8.18;

contract LessonThirteenHelper {
    int256 myValue = 100;

    function addTen(int256 number) public view returns (int256) {
        unchecked {
            return number + myValue + int256(10);
        }
    }
}