// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IRandomizer.sol";
import "../interfaces/ITOPIA.sol";
import "../interfaces/IHUB.sol";


contract ClawMachineGame is Ownable, ReentrancyGuard {

    IRandomizer public randomizer;
    IHUB private HUB;
    address payable vrf;
    address payable dev;

    ITopia private TopiaInterface = ITopia(0x649E1135b1232b68468A354f36DBfcE32813D49a);

    uint256 public SEED_COST = .0008 ether;
    uint256 public DEV_FEE = .001 ether;
    uint256 public COST_TO_PLAY = 20 * 10**18;
    uint256 public totalPayouts; // lifetime total of TOPIA paid out to winners
    uint256 public totalAmountBet; // lifetime total of TOPIA bet
    uint16 public numLosses; // lifetime total losses
    uint16 public numBets; // lifetime total plays
    uint16 public numFishBones; // lifetime total fish bones won
    uint16 public numMice; // lifetime total mice won
    uint16 public numTennisBalls; // lifetime total tennis balls won
    uint16 public numGoldenBones; // lifetime total golden bones won
    uint16 public numTopiaStones; // lifetime total topia stones won

    constructor(address _rand, address _HUB) { 
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = payable(_rand);
        dev = payable(msg.sender);
    }

    receive() external payable {}

    event ClawMachineBetPlaced(address indexed player, uint256 bet);
    event NoPrize(address indexed loser, uint256 timeStamp);
    event WonFishBone(address indexed winner, uint256 timeStamp);
    event WonMouse(address indexed winner, uint256 timeStamp);
    event WonTennisBall(address indexed winner, uint256 timeStamp);
    event WonGoldenBone(address indexed winner, uint256 timeStamp);
    event WonTopiaStone(address indexed winner, uint256 timeStamp);
    event WinnerPaid(address indexed winner, uint256 payout);

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function setCostToPlay(uint256 _cost) external onlyOwner {
        COST_TO_PLAY = _cost;
    }

    function setHub(IHUB _hub) external onlyOwner {
        HUB = _hub;
    }

    function play() external payable nonReentrant notContract() returns (uint256 payout) {
        require(msg.value == SEED_COST + DEV_FEE, "invalid eth amount");
        require(randomizer.getRemainingWords() >= 1, "Not enough random numbers. Please try again soon.");
        HUB.burnFrom(msg.sender, COST_TO_PLAY);
        vrf.transfer(SEED_COST);
        dev.transfer(DEV_FEE);
        numBets++;
        totalAmountBet += COST_TO_PLAY;
        emit ClawMachineBetPlaced(msg.sender, COST_TO_PLAY);

        uint256[] memory seed = randomizer.getRandomWords(1);
        uint8 randNum = uint8(seed[0] % 100);

        if (randNum >= 0 && randNum < 15) {
            payout = 0;
            numLosses++;
            emit NoPrize(msg.sender, block.timestamp);
        } else if (randNum >= 15 && randNum < 25) {
            payout = 10 * 10**18;
            numFishBones++;
            emit WonFishBone(msg.sender, block.timestamp);
        } else if (randNum >= 25 && randNum < 60) {
            payout = 20 * 10**18;
            numMice++;
            emit WonMouse(msg.sender, block.timestamp);
        } else if (randNum >= 60 && randNum < 80) {
            payout = 40 * 10**18;
            numTennisBalls++;
            emit WonTennisBall(msg.sender, block.timestamp);
        } else if (randNum >= 80 && randNum < 95) {
            payout = 80 * 10**18;
            numGoldenBones++;
            emit WonGoldenBone(msg.sender, block.timestamp);
        } else if (randNum >= 95 && randNum <= 100) {
            payout = 250 * 10**18;
            numTopiaStones++;
            emit WonTopiaStone(msg.sender, block.timestamp);
        }
        if (payout > 0) {
            HUB.pay(msg.sender, payout);
            totalPayouts += payout;
            emit WinnerPaid(msg.sender, payout);
        } 
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHUB {
    function balanceOf(address owner) external view returns (uint256);
    function pay(address _to, uint256 _amount) external;
    function burnFrom(address _to, uint256 _amount) external;
    // *** STEAL
    function stealGenesis(uint16 _id, uint256 seed, uint8 _gameId, uint8 identifier, address _victim) external returns (address thief);
    function stealMigratingGenesis(uint16 _id, uint256 seed, uint8 _gameId, address _victim, bool returningFromWastelands) external returns (address thief);
    function migrate(uint16 _id, address _originalOwner, uint8 _gameId,  bool returningFromWastelands) external;
    // *** RETURN AND RECEIVE
    function returnGenesisToOwner(address _returnee, uint16 _id, uint8 identifier, uint8 _gameIdentifier) external;
    function receieveManyGenesis(address _originalOwner, uint16[] memory _ids, uint8[] memory identifiers, uint8 _gameIdentifier) external;
    function returnAlphaToOwner(address _returnee, uint16 _id, uint8 _gameIdentifier) external;
    function receiveAlpha(address _originalOwner, uint16 _id, uint8 _gameIdentifier) external;
    function returnRatToOwner(address _returnee, uint16 _id) external;
    function receiveRat(address _originalOwner, uint16 _id) external;
    // *** BULLRUN
    function getRunnerOwner(uint16 _id) external view returns (address);
    function getMatadorOwner(uint16 _id) external view returns (address);
    function getBullOwner(uint16 _id) external view returns (address);
    function bullCount() external view returns (uint16);
    function matadorCount() external view returns (uint16);
    function runnerCount() external view returns (uint16);
    // *** MOONFORCE
    function getCadetOwner(uint16 _id) external view returns (address); 
    function getAlienOwner(uint16 _id) external view returns (address);
    function getGeneralOwner(uint16 _id) external view returns (address);
    function cadetCount() external view returns (uint16); 
    function alienCount() external view returns (uint16); 
    function generalCount() external view returns (uint16);
    // *** DOGE WORLD
    function getCatOwner(uint16 _id) external view returns (address);
    function getDogOwner(uint16 _id) external view returns (address);
    function getVetOwner(uint16 _id) external view returns (address);
    function catCount() external view returns (uint16);
    function dogCount() external view returns (uint16);
    function vetCount() external view returns (uint16);
    // *** PYE MARKET
    function getBakerOwner(uint16 _id) external view returns (address);
    function getFoodieOwner(uint16 _id) external view returns (address);
    function getShopOwnerOwner(uint16 _id) external view returns (address);
    function bakerCount() external view returns (uint16);
    function foodieCount() external view returns (uint16);
    function shopOwnerCount() external view returns (uint16);
    // *** ALPHAS AND RATS
    function alphaCount(uint8 _gameIdentifier) external view returns (uint16);
    function ratCount() external view returns (uint16);
    // *** NFT GROUP FUNCTION
    function createGroup(uint16[] calldata _ids, address _creator, uint8 _gameIdentifier) external;
    function addToGroup(uint16 _id, address _creator, uint8 _gameIdentifier) external;
    function unstakeGroup(address _creator, uint8 _gameIdentifier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITopia {

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;  
    function burnFrom(address _from, uint256 _amount) external;
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function requestRandomWords() external returns (uint256);
    function requestManyRandomWords(uint256 numWords) external returns (uint256);
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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