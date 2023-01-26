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
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./SlothVDF.sol";

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Meow is Ownable {
    IERC721 NFT;
    IERC20 MEOW;
    uint256 seed;
    uint256 public gamePrice = 5000000000000000;
    uint256 public waitingId = 0;
    uint256 public waitingNumber = 0;
    uint256 public secondrandom = 0;
    address public teamAddress;
    uint256 public jackpotAmount = 0;
    uint256 public stakeTotal;
    address[] private stakers;
    bool public big;

    struct Room {
        address[] fighters;
        uint256 random1;
        uint256 random2;
        uint256 tokenid1;
        uint256 tokenid2;
        bool big;
    }

    mapping(uint256 => Room) public room;
    mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public seeds;
    mapping(uint256 => bool) public gameStatu;

    uint256 public prime = 432211379112113246928842014508850435796007;
    uint256 public iterations = 1000;
    uint256 private nonce; 

    using SafeMath for uint256;

    event GameStarted(uint256 tokenId1, uint256 tokenId2);

    constructor(address _nftAddress, address _meowAddress, address _teamAddress)
    {
        NFT = IERC721(_nftAddress);
        MEOW = IERC20(_meowAddress);
        teamAddress = _teamAddress;
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
    }

    function deposit(uint256 amount) public onlyOwner {
        MEOW.transferFrom(msg.sender, address(this), amount);
        MEOW.approve(address(this), amount);
    }

    function stake(uint256 amount) external {
        MEOW.transferFrom(msg.sender, address(this), amount);
        if (stakeAmount[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        stakeAmount[msg.sender] += amount;
        stakeTotal += amount;
    }

    function unStake(uint256 amount) external {
        require(
            amount < stakeAmount[msg.sender],
            "Try to unstake more than staked amount"
        );
        MEOW.transfer(msg.sender, amount);
        if (stakeAmount[msg.sender] == amount) {
            for (uint256 index = 0; index < stakers.length; index++) {
                if (stakers[index] == msg.sender) {
                    stakers[index] = stakers[stakers.length - 1];
                    break;
                }
            }
            stakers.pop();
        }
        stakeAmount[msg.sender] -= amount;
        stakeTotal -= amount;
    }

    function joinBigLobby(
        uint256 tokenId,
        uint256 roomnum
    ) external payable {
        require(waitingId != tokenId, "ALEADY_IN_LOBBY");
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(
            gamePrice == msg.value || gamePrice.mul(5) == msg.value,
            "Amount doesn't equal msg.value"
        );
        require(gameStatu[roomnum] == false, "Finished");
        big = true;
        if (room[roomnum].tokenid1 == 0) {
            room[roomnum].tokenid1 = tokenId;
            waitingId = tokenId;
            if (msg.value == gamePrice.mul(5)) {
                big = false;
                for (int i = 0; i < 5; i++) {
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
                    waitingNumber = waitingNumber > tmp ? waitingNumber : tmp;
                }
            } else {
                waitingNumber = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
            }
            room[roomnum].big = big;
            room[roomnum].random1 = waitingNumber;
            room[roomnum].fighters.push(msg.sender);
        } else {
            room[roomnum].tokenid2 = tokenId;
            if (msg.value == gamePrice.mul(5)) {
                big = false;
                for (int i = 0; i < 5; i++) {
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
                    secondrandom = secondrandom > tmp ? secondrandom : tmp;
                }
            } else {
                secondrandom = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
            }
            room[roomnum].random2 = secondrandom;
            room[roomnum].fighters.push(msg.sender);
            startGame(tokenId);
            emit GameStarted(waitingId, tokenId);
            gameStatu[roomnum] = true;
        }
    }

    function leaveLobby(uint256 tokenId) external {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(waitingId == tokenId, "NOT_IN_LOBBY");
        waitingId = 0;
        NFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function startGame(uint256 tokenId) internal {
        // start game
        uint256 nextNumber = secondrandom;
        address waitingAddress = NFT.ownerOf(waitingId);
        address oppositeAddress = NFT.ownerOf(tokenId);
        MEOW.transfer(waitingAddress, 1);
        MEOW.transfer(oppositeAddress, 1);
        uint256 tmpgamePrice = 0;
        if(!big) tmpgamePrice = gamePrice.mul(5);
        else tmpgamePrice = gamePrice;
        
        if (waitingNumber == 3)
            jackpot(waitingAddress, oppositeAddress, nextNumber);
        if (nextNumber == 3)
            jackpot(oppositeAddress, waitingAddress, waitingNumber);

        if (waitingNumber == nextNumber) {
            sendPrice(waitingAddress, tmpgamePrice);
            sendPrice(oppositeAddress, tmpgamePrice);
        } else {
            if (waitingNumber > nextNumber) {
                sendPrice(waitingAddress, tmpgamePrice.mul(12).div(20));
                NFT.transferFrom(oppositeAddress, waitingAddress, tokenId);
            } else {
                sendPrice(oppositeAddress, tmpgamePrice.mul(12).div(10));
                NFT.transferFrom(waitingAddress, oppositeAddress, tokenId);
            }
            sendPrice(teamAddress, tmpgamePrice.mul(2).div(10));
            jackpotAmount += tmpgamePrice.mul(6).div(10);
        }
    }

    function jackpot(
        address rolled,
        address other,
        uint256 otherNumber
    ) internal {
        if (otherNumber == 3) {
            sendPrice(rolled, jackpotAmount.mul(5).div(20));
            sendPrice(other, jackpotAmount.mul(5).div(20));
        } else {
            sendPrice(rolled, jackpotAmount.mul(4).div(10));
            sendPrice(other, jackpotAmount.mul(1).div(10));
        }
        distributeToStakers();
    }

    function distributeToStakers() internal {
        for (uint256 index = 0; index < stakers.length; index++) {
            address stakerAddress = stakers[index];
            sendPrice(
                stakerAddress,
                jackpotAmount
                    .mul(4)
                    .div(10)
                    .mul(stakeAmount[stakerAddress])
                    .div(stakeTotal)
            );
        }
    }

    function setTeamAddress(address newTeamAddress) external onlyOwner {
        teamAddress = newTeamAddress;
    }

    function sendPrice(address receiver, uint256 amount) internal {
        (bool os, ) = payable(receiver).call{value: amount}("");
        require(os);
    }

    function setGamePrice(uint256 newGamePrice) external onlyOwner {
        gamePrice = newGamePrice;
    }

    function setNftAddress(address newNftAddress) external onlyOwner {
        NFT = IERC721(newNftAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

library SlothVDF {
    function bexmod(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 _result = 1;
        uint256 _base = base;
        for (; exponent > 0; exponent >>= 1) {
            if (exponent & 1 == 1) {
                _result = mulmod(_result, _base, modulus);
            }
 
            _base = mulmod(_base, _base, modulus);
        }
        return _result;
    }

    function compute(
        uint256 _seed,
        uint256 _prime,
        uint256 _iterations
    ) internal pure returns (uint256) {
        uint256 _exponent = (_prime + 1) >> 2;
        _seed %= _prime;
        for (uint256 i; i < _iterations; ++i) {
            _seed = bexmod(_seed, _exponent, _prime);
        }
        return _seed;
    }

    function verify(
        uint256 _proof,
        uint256 _seed,
        uint256 _prime,
        uint256 _iterations
    ) internal pure returns (bool) {
        for (uint256 i; i < _iterations; ++i) {
            _proof = mulmod(_proof, _proof, _prime);
        }
        _seed %= _prime;
        if (_seed == _proof) return true;
        if (_prime - _seed == _proof) return true;
        return false;
    }
}