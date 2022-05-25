/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// File: node_modules/@openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: node_modules/@openzeppelin/contracts/utils/Context.sol


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

// File: node_modules/@openzeppelin/contracts/access/Ownable.sol


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

// File: LotteryContracts.sol


pragma solidity ^0.8.14;



contract LotteryContracts is Ownable {
    uint256 private randomSeed = 0;
    mapping(uint256 => mapping(address => uint256[])) bettingList;
    mapping(uint256 => uint256[]) bettingCount;

    mapping(uint256 => mapping(address => uint256)) claimBonusHistory;
    mapping(uint256 => uint16) lotteryNumber;
    mapping(uint256 => uint256) lotteryBonusPreBetting;

    uint256 feePool = 0;
    uint256 waitingClaimBonusPool = 0;
    uint256 public bonusPool = 0;
    uint256 public bettingPool = 0;

    uint16 public MAX_NUMBER = 12;
    uint256 public NUMBER_PRICE = 1 ether / 1000;

    uint8 public DRAW_TIME_MIN_HOUR = 15;
    uint8 public DRAW_TIME_MIN_MINUTE = 20;

    uint8 public DRAW_TIME_MAX_HOUR = 15;
    uint8 public DRAW_TIME_MAX_MINUTE = 30;

    uint8 public FEE_PROPORTION = 1;

    event Lottery(uint256 indexed no, uint16 number, uint256 bounsPool);
    event Betting(address indexed _from, uint16 number, uint256 count);
    event ClaimBonus(address indexed _from, uint256 bouns);

    constructor() {
        randomSeed = block.number;
    }

    function bet(uint16 number, uint256 count) public payable {
        require(msg.sender != owner());
        require(
            number >= 1 && number <= MAX_NUMBER,
            string(
                abi.encodePacked(
                    "Number range is 1 to ",
                    Strings.toString(MAX_NUMBER)
                )
            )
        );
        require(count > 0, "Count must be greater than zero");
        require(
            msg.value >= NUMBER_PRICE * count,
            string(
                abi.encodePacked(
                    "The price of each number is ",
                    Strings.toString(NUMBER_PRICE)
                )
            )
        );
        uint256 no = getNo();

        require(lotteryNumber[no] == 0, "Today's lottery draw");
        require(isBettingTime(), "Betting time has elapsed");

        if (bettingList[no][msg.sender].length == 0) {
            bettingList[no][msg.sender] = new uint256[](MAX_NUMBER);
        }
        bettingList[no][msg.sender][number - 1] += count;
        if (bettingCount[no].length == 0) {
            bettingCount[no] = new uint256[](MAX_NUMBER);
        }
        bettingCount[no][number - 1] += count;

        bettingPool += msg.value;

        addRandomSeed(feePool);
        emit Betting(msg.sender, number, count);
    }

    function getSelfBonus() public view returns (uint256) {
        if (getNo() == 0) {
            return 0;
        }
        if (!isBettingTime()) {
            return 0;
        }
        uint256 lastNO = getNo() - 1;
        if (claimBonusHistory[lastNO][msg.sender] > 0) {
            return 0;
        }
        uint256[] storage numbers = bettingList[lastNO][msg.sender];
        if (numbers.length == 0) {
            return 0;
        }
        uint16 number = lotteryNumber[lastNO];
        uint256 lotteryCount = numbers[number - 1];
        if (lotteryCount == 0) {
            return 0;
        }
        return lotteryCount * lotteryBonusPreBetting[lastNO];
    }

    function getFeePool() public view onlyOwner returns (uint256) {
        return feePool;
    }

    function claimFeePool() public payable onlyOwner {
        address payable sender = payable(msg.sender);
        sender.transfer(feePool);
        feePool = 0;
    }

    function claimBonus() public payable {
        uint256 value = getSelfBonus();
        require(value > 0, "No bonus to claim");
        require(
            waitingClaimBonusPool >= value,
            "Insufficient smart contract balance"
        );
        require(
            address(this).balance >= value,
            "Insufficient smart contract balance"
        );
        require(isBettingTime(), "Tidying up the table");

        address payable sender = payable(msg.sender);
        sender.transfer(value);

        uint256 lastNO = getNo() - 1;
        claimBonusHistory[lastNO][msg.sender] = value;
        waitingClaimBonusPool -= value;
        addRandomSeed(1);
        emit ClaimBonus(msg.sender, value);
    }

    function isBettingTime() public view returns (bool) {
        uint256 hour = (block.timestamp % 1 days) / 1 hours;
        uint256 minute = ((block.timestamp % 1 days) % 1 hours) / 1 minutes;
        return
            !(hour >= DRAW_TIME_MIN_HOUR &&
                hour <= DRAW_TIME_MAX_HOUR &&
                minute >= DRAW_TIME_MIN_MINUTE &&
                minute <= DRAW_TIME_MAX_MINUTE);
    }

    function getBettingNumber() public view returns (uint256[] memory) {
        return bettingCount[getNo()];
    }

    function getSelfBettingNumber() public view returns (uint256[] memory) {
        return bettingList[getNo()][msg.sender];
    }

    uint256 lotteryNo = 0;
    uint256 lastDrawLotteryDayNo = 0;

    function drawLottery(uint256 seed) public onlyOwner {
        uint256 no = getNo();
        uint256 dayNo = getDayNo();
        require(lastDrawLotteryDayNo < dayNo, "Today's lottery draw (1)");
        require(lotteryNumber[no] == 0, "Today's lottery draw (2)");
        require(bettingPool >= 16 ether, "Today's lottery draw (2)");
        require(!isBettingTime(), "The draw time has not arrived");
        addRandomSeed(seed);
        addRandomSeed(block.number);
        uint16 number = uint16(random(1, MAX_NUMBER));
        lotteryNumber[no] = number;

        uint256 _waitingClaimBonusPool = waitingClaimBonusPool;
        uint256 _bonusPool = bonusPool;
        uint256 _bettingPool = bettingPool;
        waitingClaimBonusPool = 0;
        bonusPool = 0;
        bettingPool = 0;

        bonusPool += _waitingClaimBonusPool;

        uint256 totalBonus = _bonusPool + _bettingPool;
        uint256 totalWinnerBetting = bettingCount[no][number - 1];
        uint256 bounsPreBetting = 0;

        uint256 fee = (totalBonus / 100) * FEE_PROPORTION;
        feePool += fee;
        totalBonus -= fee;

        delete _waitingClaimBonusPool;
        delete _bonusPool;
        delete _bettingPool;

        if (totalWinnerBetting > 0) {
            bounsPreBetting = totalBonus / totalWinnerBetting;
        }

        uint256 d = totalBonus - (bounsPreBetting * totalWinnerBetting);
        if (d > 0) {
            bonusPool += d;
        }
        waitingClaimBonusPool = bounsPreBetting * totalWinnerBetting;

        lotteryBonusPreBetting[no] = bounsPreBetting;

        emit Lottery(no, lotteryNumber[no], totalBonus);
        lastDrawLotteryDayNo = dayNo;
        lotteryNo += 1;
    }

    function getNo() public view returns (uint256) {
        return lotteryNo;
    }

    function getDayNo() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function addRandomSeed(uint256 value) private {
        unchecked {
            randomSeed += value + block.timestamp;
        }
    }

    function random(uint256 minValue, uint256 maxValue)
        private
        returns (uint256)
    {
        require(minValue < maxValue);
        uint256 d = maxValue - minValue + 1;

        uint256 value = uint256(
            keccak256(
                abi.encodePacked(
                    randomSeed,
                    block.number,
                    block.timestamp,
                    gasleft() + getNo()
                )
            )
        );
        addRandomSeed(value);
        return (minValue % d) + minValue;
    }
}