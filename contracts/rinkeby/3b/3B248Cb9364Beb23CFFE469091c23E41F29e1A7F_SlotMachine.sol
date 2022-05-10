/**
 *Submitted for verification at Etherscan.io on 2022-05-10
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/SlotMachinePseudoRandom.sol

pragma solidity ^0.8.0;




contract SlotMachine is Ownable
{
    uint private Checkpot;
    event GameResult(
        address indexed player,
        bool won,
        uint amount,
        string reel1,
        string reel2,
        string reel3,
        bool canPlayAdditionalGame,
        bool wonAdditionalGame,
        uint number);

    enum Symbols {Seven, Bar, Melon, Bell, Peach, Orange, Cherry, Lemon}

    Symbols[21] private reel1 = [
        Symbols.Seven,
        Symbols.Bar, Symbols.Bar, Symbols.Bar,
        Symbols.Melon, Symbols.Melon,
        Symbols.Bell,
        Symbols.Peach, Symbols.Peach, Symbols.Peach, Symbols.Peach, Symbols.Peach, Symbols.Peach, Symbols.Peach,
        Symbols.Orange, Symbols.Orange, Symbols.Orange, Symbols.Orange, Symbols.Orange,
        Symbols.Cherry, Symbols.Cherry
        ];

    Symbols[24] private reel2 = [
        Symbols.Seven,
        Symbols.Bar, Symbols.Bar,
        Symbols.Melon, Symbols.Melon,
        Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell,
        Symbols.Peach, Symbols.Peach, Symbols.Peach,
        Symbols.Orange, Symbols.Orange, Symbols.Orange, Symbols.Orange, Symbols.Orange,
        Symbols.Cherry, Symbols.Cherry, Symbols.Cherry, Symbols.Cherry, Symbols.Cherry, Symbols.Cherry
        ];
    
    Symbols[23] private reel3 = [
        Symbols.Seven,
        Symbols.Bar,
        Symbols.Melon, Symbols.Melon,
        Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell, Symbols.Bell,
        Symbols.Peach, Symbols.Peach, Symbols.Peach,
        Symbols.Orange, Symbols.Orange, Symbols.Orange, Symbols.Orange,
        Symbols.Lemon, Symbols.Lemon, Symbols.Lemon, Symbols.Lemon
        ];

    uint[10] private AdditionalGame = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    function GetCheckpot() public view returns (uint) {
        return Checkpot;
    }

    function PlaySlotMachine() public payable {
        require(msg.value > 0, "Bet size to small");
        

        (uint reel1Index, uint reel2Index, uint reel3Index) = GetRandomIndices();
        Symbols symbol1 = reel1[reel1Index];
        Symbols symbol2 = reel2[reel2Index];
        Symbols symbol3 = reel3[reel3Index];

        uint multiplicator = CheckIfDrawIsWinner(symbol1, symbol2, symbol3);
        bool winner = multiplicator != 0;
        uint winningAmount = 0;
        bool hasAdditionalGame = multiplicator == 200; // case: 777
        bool wonAdditionalGame = false;
        uint additionalGameNumber = 0;

        if (winner) {
            winningAmount = msg.value * multiplicator;

            // check if additonal game can be played
            if (hasAdditionalGame) {
                // if random number is equal to 0 --> win
                additionalGameNumber = GetRandomNumber(10,"0");
                if (additionalGameNumber == 0) {
                    uint currentCheckpot = Checkpot;
                    Checkpot = 0;
                    wonAdditionalGame = true;
                    winningAmount += currentCheckpot;
                }
            }
        } else {
            // add 10% of the input to the checkpot
            Checkpot += msg.value / 10; // TODO is this a correct division
        }
        
        if (winningAmount > 0) {
          payable(msg.sender).transfer(winningAmount);
        }

        emit GameResult(
            msg.sender,
            winner,
            winningAmount,
            MapEnumString(symbol1),
            MapEnumString(symbol2),
            MapEnumString(symbol3),
            hasAdditionalGame,
            wonAdditionalGame,
            additionalGameNumber
            );
    }
    
    fallback() external payable {}
    receive() external payable {}

    function CheckIfDrawIsWinner(Symbols symbol1, Symbols symbol2, Symbols symbol3) private pure returns (uint multiplicator) {
        // 777
        if (symbol1 == Symbols.Seven && symbol2 == symbol1 && symbol3 == symbol1) {
            return 200;
        }
        // Bar Bar Bar
        if (symbol1 == Symbols.Bar && symbol2 == symbol1 && symbol3 == symbol1) {
            return 100;
        }
        // Melon Melon Melon
        if (symbol1 == Symbols.Melon && symbol2 == symbol1 && symbol3 == symbol1) {
            return 100;
        }
        // Bell Bell Bell
        if (symbol1 == Symbols.Bell && symbol2 == symbol1 && symbol3 == symbol1) {
            return 18;
        }
        // Peach Peach Peach
        if (symbol1 == Symbols.Peach && symbol2 == symbol1 && symbol3 == symbol1) {
            return 14;
        }
        // Orange Orange Orange
        if (symbol1 == Symbols.Orange && symbol2 == symbol1 && symbol3 == symbol1) {
            return 10;
        }

        // Melon Melon Bar
        if (symbol1 == Symbols.Melon && symbol2 == Symbols.Melon && symbol3 == Symbols.Bar) {
            return 100;
        }
        // Bell Bell Bar
        if (symbol1 == Symbols.Bell && symbol2 == Symbols.Bell && symbol3 == Symbols.Bar) {
            return 18;
        }
        // Peach Peach Bar
        if (symbol1 == Symbols.Peach && symbol2 == Symbols.Peach && symbol3 == Symbols.Bar) {
            return 14;
        }
        // Orange Orange Bar
        if (symbol1 == Symbols.Orange && symbol2 == Symbols.Orange && symbol3 == Symbols.Bar) {
            return 10;
        }

        // Cherries
        if (symbol1 == Symbols.Cherry) {
            // Cherry Cherry Anything
            if (symbol2 == Symbols.Cherry) {
                return 5;
            }
            // Cherry Anything Anything
            return 2;
        }

        // nothing
        return 0;
    }

    function GetRandomIndices() private view returns (uint, uint, uint) {
        uint indexReel1 = GetRandomNumber(reel1.length - 1, "1");
        uint indexReel2 = GetRandomNumber(reel2.length - 1, "2");
        uint indexReel3 = GetRandomNumber(reel3.length - 1, "3");

        require(indexReel1 >= 0 && indexReel1 < reel1.length, "Reel1 random index out of range");
        require(indexReel2 >= 0 && indexReel2 < reel2.length, "Reel2 random index out of range");
        require(indexReel3 >= 0 && indexReel3 < reel3.length, "Reel3 random index out of range");
        return (indexReel1, indexReel2, indexReel3);
    }

    function GetRandomNumber(uint max, bytes32 salt) private view returns (uint) {
        uint randomNumber = uint256(keccak256(abi.encode(block.timestamp, salt))) % (max + 1);
        require(randomNumber <= max, "random number out of range");
        return randomNumber;
    }

    function MapEnumString(Symbols input) private pure returns (string memory) {
        if (input == Symbols.Seven) {
            return "7";
        } else if (input == Symbols.Bar) {
            return "bar";
        } else if (input == Symbols.Melon) {
            return "melon";
        } else if (input == Symbols.Bell) {
            return "bell";
        } else if (input == Symbols.Peach) {
            return "peach";
        } else if (input == Symbols.Orange) {
            return "orange";
        } else if (input == Symbols.Cherry) {
            return "cherry";
        } else {
            return "lemon";
        }
    }

}