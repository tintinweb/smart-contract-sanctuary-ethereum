// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libs/CellData.sol";
import "./interfaces/IRandom.sol";
import "./interfaces/ISeed.sol";

contract Random is IRandom, ISeed, Ownable {
    using SafeMath for uint256;
    uint8 private constant MAX_LEVEL_OF_EVOLUTION = 100;
    uint256 private constant INVERSE_BASIS_POINT = 1000;
    uint256 private constant HUNDRED_PERCENT = 100;

    struct Group {
        uint256 startBlock;
        uint256 step;
        uint128 stages;
    }

    uint256 private mSeed;
    string private _baseURI;

    // Number of variants on each stage
    // 10 for each stage by default (set in constructor)
    mapping(uint256 => uint256) private _stageRange;

    // storage of links to metadata from S3; used in tokenURI() from ERC721
    // tokenURI(uint256 tokenId)  and returns string (full S3 link)
    // Let it be 1000 for now:
    //   0-9 = stage 1
    //  10-19 = stage 2
    //  20-29 = stage 3
    mapping(uint256 => string) private _tokenURIs;

    constructor(address owner) {
        require(owner != address(0), "Address should not be empty");

        transferOwnership(owner);
    }

    function getSeed() external view override onlyOwner returns (uint256) {
        return mSeed;
    }

    function setSeed(uint256 seed) external override onlyOwner {
        mSeed = seed;
    }

    function getRandomImageByRange(uint256 _stage)
        external
        view
        override
        returns (string memory)
    {
        // 10 == 1000 images / 100 stages
        uint256 left = _stage.mul(10);
        uint256 right = left.add(_stageRange[_stage]);
        uint256 imageId = (random() % (right.sub(left).add(1))).add(left);
        return _tokenURIs[imageId];
    }

    function getRandomClass() external view override returns (uint8) {
        uint256 number = random();
        return uint8(_getChosenClass(number %= INVERSE_BASIS_POINT));
    }

    function getSplittableWithIncreaseChance(uint16 probability)
        external
        view
        override
        returns (uint8)
    {
        uint256 number = random();
        number = number %= INVERSE_BASIS_POINT;
        // since in class 100%=1000 but probability calculates as 100% = 100
        probability = probability * 10; // 1000
        if (number.add(probability) > 999) {
            if (number < 600) {
                return uint8(CellData.Class.SPLITTABLE_NANO);
            }
            return uint8(CellData.Class.SPLITTABLE_MAD);
        }

        return uint8(_getChosenClass(number.add(probability)));
    }

    function getRandomStage(uint256 _stage, uint16 probabilityIncrease)
        external
        view
        override
        returns (uint256)
    {
        require(
            _stage >= 0 && _stage <= MAX_LEVEL_OF_EVOLUTION,
            "Invalid Stage"
        );
        uint256 number = random() % HUNDRED_PERCENT;
        number = number.add(probabilityIncrease * 10);

        if (number >= 0 && number <= 69) {
            _stage = _stage.add(1);
        } else if (number >= 70 && number <= 89) {
            _stage = _stage.add(2);
        } else if (number >= 90 && number <= 94) {
            _stage = _stage.add(3);
        } else if (number >= 95 && number <= 97) {
            _stage = _stage.add(4);
        } else if (number >= 98) {
            _stage = _stage.add(5);
        }

        // overflow case
        if (_stage > MAX_LEVEL_OF_EVOLUTION) {
            _stage = MAX_LEVEL_OF_EVOLUTION;
        }

        return _stage;
    }

    function getRandomVariant() external view override returns (uint256) {
        uint256 number = random() % (HUNDRED_PERCENT.div(2));
        if (number == 0) {
            number = 1;
        }
        return number;
    }

    function getEvolutionTime() external view override returns (uint256) {
        uint256 currentBlock = block.number;

        uint256 number = random() % HUNDRED_PERCENT;
        Group memory group = getGroup(number);
        uint256 stage = random() % HUNDRED_PERCENT.div(10);

        if (stage == 0) {
            stage = stage.add(1);
        }

        currentBlock = currentBlock.add(
            group.startBlock.add((group.step.mul(stage)))
        );
        return currentBlock;
    }

    function getGroup(uint256 number)
        private
        pure
        returns (Group memory group)
    {
        if (number >= 60 && number <= 89) {
            group.startBlock = 74000;
            group.step = 10000;
            group.stages = 9;
        } else if (number >= 90 && number <= 100) {
            group.startBlock = 24000;
            group.step = 5000;
            group.stages = 9;
        } else {
            group.startBlock = 174000;
            group.step = 10000;
            group.stages = 10;
        }
    }

    // Get randomly chosen image from stage range of images
    // Random is limited by two borders: left and right
    // Borders represent imageID in _tokenURIs mapping
    function _getChosenClass(uint256 number)
        private
        pure
        returns (CellData.Class)
    {
        if (number > 999 && number <= 1000) {
            return CellData.Class.FINISHED;
        } else if (number > 949 && number <= 979) {
            return CellData.Class.SPLITTABLE_NANO;
        } else if (number > 979 && number <= 999) {
            return CellData.Class.SPLITTABLE_MAD;
        }
        return CellData.Class.COMMON;
    }

    function tokenURI(uint256 tokenId) private view returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }

        return string(abi.encodePacked(_baseURI, ""));
    }

    function random() private view returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number.sub(1)),
                    msg.sender,
                    mSeed
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_MAD,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO || _class == Class.SPLITTABLE_MAD;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 variant;
        uint256 nextEvolutionBlock;
        string tokenUri;
        bool onSale;
        uint256 price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandom {
    /**
     * @dev Picks random image depends on the token stage
     */
    function getRandomImageByRange(uint256 _stage)
        external
        view
        returns (string memory);

    /**
     * @dev Picks random class for token during evolution from
     * [COMMON, SPLITTABLE_NANO, SPLITTABLE_MAD, FINISHED]
     */
    function getRandomClass() external view returns (uint8);

    /**
     * @dev Check whether token could be splittable
     */
    function getSplittableWithIncreaseChance(uint16 probability)
        external
        view
        returns (uint8);

    /**
     * @dev Generates next stage for token during evoution
     * in rage of [0;5]
     */
    function getRandomStage(uint256 _stage, uint16 probabilityIncrease)
        external
        view
        returns (uint256);

    function getRandomVariant() external view returns (uint256);

    /**
     * @dev Generates evolution time
     */
    function getEvolutionTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISeed {
    /**
     * @dev Returns seed
     */
    function getSeed() external view returns (uint256);

    /**
     * @dev Sets seed value
     */
    function setSeed(uint256 seed) external;
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