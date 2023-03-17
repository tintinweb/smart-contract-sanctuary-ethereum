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

interface ITRC721 {
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

interface ITRC20 {
    function totalSupply() external returns (uint256);

    function balanceOf(address tokenOwner) external returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract Meow is Ownable {
    ITRC721 NFT;
    ITRC20 MEOW;
    uint256 seed;
    uint256 public gamePrice = 50000000;
    uint256 public waitingNumber = 0;
    uint256 public secondrandom = 0;
    address public teamAddress;
    uint256 public jackpotAmount = 0;
    // uint256 public stakeTotal;
    // address[] private stakers;

    mapping(address => uint256) public tokenOwnerLength;
    // mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public seeds;

    uint256 public prime = 432211379112113246928842014508850435796007;
    uint256 public iterations = 1000;
    uint256 private nonce;

    using SafeMath for uint256;

    constructor(
        address _nftAddress,
        address _meowAddress,
        address _teamAddress
    ) {
        NFT = ITRC721(_nftAddress);
        MEOW = ITRC20(_meowAddress);
        teamAddress = _teamAddress;
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
    }

    function deposit(uint256 amount) public onlyOwner {
        MEOW.transferFrom(msg.sender, address(this), amount);
    }

    function stake(uint256 amount) external {
        MEOW.transferFrom(msg.sender, address(this), amount);
        // if (stakeAmount[msg.sender] == 0) {
        //     stakers.push(msg.sender);
        // }
        // stakeAmount[msg.sender] += amount;
        // stakeTotal += amount;
    }

    function unStake(uint256 amount) external {
        MEOW.transfer(msg.sender, amount);
        // if (stakeAmount[msg.sender] == amount) {
        //     for (uint256 index = 0; index < stakers.length; index++) {
        //         if (stakers[index] == msg.sender) {
        //             stakers[index] = stakers[stakers.length - 1];
        //             break;
        //         }
        //     }
        //     stakers.pop();
        // }
        // stakeAmount[msg.sender] -= amount;
        // stakeTotal -= amount;
    }

    function enterRoom(uint256 tokenId) external payable returns (uint256) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(gamePrice == msg.value, "Amount doesn't equal msg.value");
        require(
            NFT.getApproved(tokenId) == address(this),
            "Token cannot be transfered"
        );
        NFT.transferFrom(msg.sender, address(this), tokenId);
        waitingNumber = (uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000) + 1;
        return waitingNumber;
    }

    function enterBigRoom(uint256 tokenId) external payable returns (uint256) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(
            gamePrice.mul(5) == msg.value,
            "Amount doesn't equal msg.value"
        );
        require(
            NFT.getApproved(tokenId) == address(this),
            "Token cannot be transfered"
        );
        NFT.transferFrom(msg.sender, address(this), tokenId);
        for (int256 i = 0; i < 5; i++) {
            uint256 tmp = (uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000) + 1;
            waitingNumber = waitingNumber > tmp ? waitingNumber : tmp;
        }
        return waitingNumber;
    }

    function claimFight(uint256 tokenId) external payable returns (uint256) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(
            gamePrice == msg.value,
            "Amount doesn't equal msg.value"
        );
        require(
            NFT.getApproved(tokenId) == address(this),
            "Token cannot be transfered"
        );
        NFT.transferFrom(msg.sender, address(this), tokenId);
        secondrandom = (uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000) + 1;
        return secondrandom;
    }

    function claimBigFight(uint256 tokenId) external payable returns (uint256) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(
            gamePrice.mul(5) == msg.value,
            "Amount doesn't equal msg.value"
        );
        require(
            NFT.getApproved(tokenId) == address(this),
            "Token cannot be transfered"
        );
        NFT.transferFrom(msg.sender, address(this), tokenId);
        for (int256 i = 0; i < 5; i++) {
            uint256 tmp = (uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000) + 1;
            secondrandom = secondrandom > tmp ? secondrandom : tmp;
        }
        return secondrandom;
    }

    // function startGame(uint256 roomnum, bool big) internal {
    //     // start game
    //     Room storage betRoom = room[roomnum];
    //     uint256 firstNumber = betRoom.random1;
    //     uint256 nextNumber = betRoom.random2;
    //     address waitingAddress = betRoom.fighter1;
    //     address oppositeAddress = betRoom.fighter2;
    //     uint256 tokenId1 = betRoom.tokenId1;
    //     uint256 tokenId2 = betRoom.tokenId2;
    //     MEOW.transfer(waitingAddress, 1);
    //     MEOW.transfer(oppositeAddress, 1);
    //     uint256 tmpgamePrice = 0;
    //     if (big) tmpgamePrice = gamePrice.mul(5);
    //     else tmpgamePrice = gamePrice;
    //     if (firstNumber == 77777)
    //         jackpot(waitingAddress, oppositeAddress, nextNumber);
    //     if (nextNumber == 77777)
    //         jackpot(oppositeAddress, waitingAddress, firstNumber);
    //     if (firstNumber == nextNumber) {
    //         claimAmount[waitingAddress] += tmpgamePrice;
    //         claimAmount[oppositeAddress] += tmpgamePrice;
    //         tokenOwner[waitingAddress].push(tokenId1);
    //         tokenOwnerLength[waitingAddress] = tokenOwner[waitingAddress].length;
    //         tokenOwner[oppositeAddress].push(tokenId2);
    //         tokenOwnerLength[oppositeAddress] = tokenOwner[oppositeAddress].length;
    //     } else {
    //         if (firstNumber > nextNumber) {
    //             claimAmount[waitingAddress] += tmpgamePrice.mul(12).div(10);
    //             tokenOwner[waitingAddress].push(tokenId1);
    //             tokenOwner[waitingAddress].push(tokenId2);
    //             tokenOwnerLength[waitingAddress] = tokenOwner[waitingAddress].length;
    //         } else {
    //             claimAmount[oppositeAddress] += tmpgamePrice.mul(12).div(10);
    //             tokenOwner[oppositeAddress].push(tokenId1);
    //             tokenOwner[oppositeAddress].push(tokenId2);
    //             tokenOwnerLength[oppositeAddress] = tokenOwner[oppositeAddress].length;
    //         }
    //         claimAmount[teamAddress] += tmpgamePrice.mul(2).div(10);
    //         jackpotAmount += tmpgamePrice.mul(6).div(10);
    //     }
    // }

    // function jackpot(
    //     address rolled,
    //     address other,
    //     uint256 otherNumber
    // ) internal {
    //     if (otherNumber == 77777) {
    //         claimAmount[rolled] += jackpotAmount.mul(5).div(20);
    //         claimAmount[other] += jackpotAmount.mul(5).div(20);
    //     } else {
    //         claimAmount[rolled] += jackpotAmount.mul(4).div(20);
    //         claimAmount[other] += jackpotAmount.mul(1).div(20);
    //     }
    //     distributeToStakers();
    // }

    function claimNFT(uint256 tokenId) external {
        NFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function claimMoney (uint256 amount) external {
        sendPrice(msg.sender, amount);
    }

    // function distributeToStakers() internal {
    //     for (uint256 index = 0; index < stakers.length; index++) {
    //         address stakerAddress = stakers[index];
    //         claimAmount[stakerAddress] += jackpotAmount.mul(4).div(10).mul(stakeAmount[stakerAddress]).div(stakeTotal);
    //     }
    //     jackpotAmount = jackpotAmount.div(10);
    // }

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
        NFT = ITRC721(newNftAddress);
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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