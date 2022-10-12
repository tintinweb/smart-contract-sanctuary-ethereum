/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: RandomnessProvider/SampleDiceGame.sol


pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


interface IRCCoordinator {
    function requestRandomValue(uint randomId, uint randomValueCount)
        external
        returns (
            address,
            uint,
            uint
        );
}

contract SampleDiceGame is Ownable {
    mapping(uint => uint[]) public randomValue;
    mapping(uint => uint[]) public predictions;
    mapping(uint => uint8) public predictionResult;
    uint public randomId;
    event RequestRandomness(address, uint, uint);
    event GameResult(uint, uint[], bool);
    address public rfCoordinator;

    constructor(address _rfCoordinator) {
        rfCoordinator = _rfCoordinator;
    }

    function setRFCoordinator(address _rfCoordinator) external onlyOwner {
        rfCoordinator = _rfCoordinator;
    }

    function playDice(uint[] calldata dicePredictions, uint randomValueCount)
        external
    {
        require(
            1 < randomValueCount && randomValueCount < 5,
            "Min 1, Max 4 dices can be played at the same time"
        );
        require(
            dicePredictions.length == randomValueCount,
            "Predicted more than requested"
        );
        for (uint i; i < dicePredictions.length; i++) {
            require(
                0 < dicePredictions[i] && dicePredictions[i] < 7,
                "Dice Predictions should be between 1 and 6"
            );
        }
        IRCCoordinator(rfCoordinator).requestRandomValue(
            randomId,
            randomValueCount
        );
        predictions[randomId] = dicePredictions;
        randomId++;
    }

    function fulfillRandomness(uint _randomId, uint[] calldata _randomValue)
        external
    {
        require(msg.sender == rfCoordinator);
        randomValue[_randomId] = _randomValue;
        uint[] memory tempArray = predictions[_randomId];
        for (uint i = 0; i < _randomValue.length; i++) {
            for (uint j = 0; j < tempArray.length; j++) {
                if (((_randomValue[i] % 6) + 1) == tempArray[j]) {
                    tempArray[j] = tempArray[tempArray.length - 1];
                    delete tempArray[tempArray.length - 1];
                    break;
                }
            }
        }
        bool gameResult;
        if (tempArray.length == 0) {
            predictionResult[_randomId] = 1;
            gameResult = true;
        } else {
            predictionResult[_randomId] = 2;
        }
        emit GameResult(_randomId, _randomValue, gameResult);
    }

    function readRandomValues(uint index)
        external
        view
        returns (uint[] memory)
    {
        return randomValue[index];
    }

    function getPredictionResult(uint _randomId)
        external
        view
        returns (uint8 result)
    {
        result = predictionResult[_randomId];
    }
}