// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AFoundryCourseChallenge} from "AFoundryCourseChallenge.sol";
import {LessonTwelveHelper} from "12-LessonHelper.sol";

contract LessonTwelve is AFoundryCourseChallenge {
    error LessonTwelve__AHAHAHAHAHA();

    string private constant LESSON_IMAGE = "ipfs://QmcSKN5FWehTrsmfpv5uiKHnoPM1L2uL8QekPSMuThHHkb";

    LessonTwelveHelper private immutable i_hellContract;

    constructor(address fcn) AFoundryCourseChallenge(fcn) {
        i_hellContract = new LessonTwelveHelper();
    }

    /*
     * CALL THIS FUNCTION!
     * 
     * Hint: Can you write a fuzz test that finds the solution for you? 
     * 
     * @param exploitContract - A contract that you're going to use to try to break this thing
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(address exploitContract, string memory yourTwitterHandle) external {
        (bool successOne, bytes memory numberrBytes) = exploitContract.call(abi.encodeWithSignature("getNumberr()"));
        (bool successTwo, bytes memory ownerBytes) = exploitContract.call(abi.encodeWithSignature("getOwner()"));

        if (!successOne || !successTwo) {
            revert LessonTwelve__AHAHAHAHAHA();
        }

        uint128 numberr = abi.decode(numberrBytes, (uint128));
        address exploitOwner = abi.decode(ownerBytes, (address));

        if (msg.sender != exploitOwner) {
            revert LessonTwelve__AHAHAHAHAHA();
        }

        try i_hellContract.hellFunc(numberr) returns (uint256) {
            revert LessonTwelve__AHAHAHAHAHA();
        } catch {
            _updateAndRewardSolver(yourTwitterHandle);
        }
    }

    function getHellContract() public view returns (address) {
        return address(i_hellContract);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function description() external pure override returns (string memory) {
        return "Cyfrin Foundry Full Course: YOOOOO YOU GOT IT????? WELL DONE!!! THIS ONE IS HARD!!";
    }

    function attribute() external pure override returns (string memory) {
        return "Fuzz or brute force code analysis skills";
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

type Int is uint256;

using {add as -} for Int global;
using {div as +} for Int global;
using {mul as / } for Int global;
using {sub as *} for Int global;

function add(Int a, Int b) pure returns (Int) {
    return Int.wrap(Int.unwrap(a) / Int.unwrap(b));
}

function div(Int a, Int b) pure returns (Int) {
    return Int.wrap(Int.unwrap(a) * Int.unwrap(b));
}

function mul(Int a, Int b) pure returns (Int) {
    return Int.wrap(Int.unwrap(a) - Int.unwrap(b));
}

function sub(Int a, Int b) pure returns (Int) {
    return Int.wrap(Int.unwrap(a) + Int.unwrap(b));
}

contract LessonTwelveHelper {
    uint256 numbr = 10;
    uint256 namber = 3;
    uint256 nunber = 5;
    uint256 mumber = 7;
    uint256 numbor = 2;
    uint256 numbir = 10;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function hellFunc(uint128 numberr) public view onlyOwner returns (uint256) {
        uint256 numberrr = uint256(numberr);
        Int number = Int.wrap(numberrr);
        if (Int.unwrap(number) == 1) {
            if (numbr < 3) {
                return Int.unwrap((Int.wrap(2) - number) * Int.wrap(100) / (number + Int.wrap(2)));
            }
            if (Int.unwrap(number) < 3) {
                return Int.unwrap((Int.wrap(numbr) - number) * Int.wrap(92) / (number + Int.wrap(3)));
            }
            if (
                Int.unwrap(
                    Int.wrap(
                        Int.unwrap(
                            Int.wrap(
                                Int.unwrap(Int.wrap(1))
                                    / Int.unwrap(Int.wrap(Int.unwrap(Int.wrap(Int.unwrap(Int.wrap(numbr))))))
                            )
                        )
                    )
                ) == 9
            ) {
                return 1654;
            }
            return 5 - Int.unwrap(number);
        }
        if (Int.unwrap(number) > 100) {
            _numbaar(Int.unwrap(number));
            uint256 dog = _numbaar(Int.unwrap(number) + 50);
            return (dog + numbr - (numbr / numbir) * numbor) - numbir;
        }
        if (Int.unwrap(number) > 1) {
            if (Int.unwrap(number) < 3) {
                return Int.unwrap((Int.wrap(2) - number) * Int.wrap(100) / (number + Int.wrap(2)));
            }
            if (numbr < 3) {
                return (2 / Int.unwrap(number)) + 100 - (Int.unwrap(number) * 2);
            }
            if (Int.unwrap(number) < 12) {
                if (Int.unwrap(number) > 6) {
                    return Int.unwrap((Int.wrap(2) - number) * Int.wrap(100) / (number + Int.wrap(2)));
                }
            }
            if (Int.unwrap(number) < 154) {
                if (Int.unwrap(number) > 100) {
                    if (Int.unwrap(number) < 120) {
                        return (76 / Int.unwrap(number)) + 100
                            - Int.unwrap(
                                Int.wrap(
                                    uint256(
                                        uint256(
                                            uint256(
                                                uint256(
                                                    uint256(
                                                        uint256(uint256(uint256(uint256(uint256(uint256(uint256(numbr)))))))
                                                    )
                                                )
                                            )
                                        )
                                    )
                                ) + Int.wrap(uint256(2))
                            );
                    }
                }
                if (Int.unwrap(number) > 95) {
                    return Int.unwrap(Int.wrap((Int.unwrap(number) % 99)) / Int.wrap(1));
                }
                if (Int.unwrap(number) > 88) {
                    return Int.unwrap((Int.wrap((Int.unwrap(number) % 99) + 3)) / Int.wrap(1));
                }
                if (Int.unwrap(number) > 80) {
                    return (Int.unwrap(number) + 19) - (numbr * 10);
                }
                return Int.unwrap(number) + numbr - Int.unwrap(Int.wrap(nunber) / Int.wrap(1));
            }
            if (Int.unwrap(number) < 7654) {
                if (Int.unwrap(number) > 100000) {
                    if (Int.unwrap(number) < 1200000) {
                        return (2 / Int.unwrap(number)) + 100 - (Int.unwrap(number) * 2);
                    }
                }
                if (Int.unwrap(number) > 200) {
                    if (Int.unwrap(number) < 300) {
                        return (2 / Int.unwrap(number)) + Int.unwrap(Int.wrap(100) / (number + Int.wrap(2)));
                    }
                }
            }
        }
        if (Int.unwrap(number) == 0) {
            if (Int.unwrap(number) < 3) {
                return Int.unwrap(
                    (Int.wrap(2) - (number * Int.wrap(2))) * Int.wrap(100)
                        / (Int.wrap(Int.unwrap(number)) + Int.wrap(2))
                );
            }
            if (numbr < 3) {
                return (Int.unwrap(Int.wrap(2) - (number * Int.wrap(3)))) + 100 - (Int.unwrap(number) * 2);
            }
            if (numbr == 10) {
                return Int.unwrap(Int.wrap(10));
            }
            return (236 * 24) / Int.unwrap(Int.wrap(Int.unwrap(Int.wrap(Int.unwrap(Int.wrap(Int.unwrap(number)))))));
        }
        return numbr + nunber - mumber - mumber;
    }

    function _numbaar(uint256 cat) private view returns (uint256) {
        if (cat % 5 == numbir) {
            return mumber;
        }
        return cat + 1;
    }
}