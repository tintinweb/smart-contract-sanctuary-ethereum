/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

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

pragma solidity ^0.8.7;

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract SafeSharp is Ownable {

    /*****------- CONSTANTS -------******/
	bool public weeklyBettingOn = false;
    bool public survivorBettingOn = false;
    uint256 public HOUSE_PAY_BIP = 1000;
    uint256 public REFERRAL_PAY_BIP = 250;
    uint256 public smallBet = 0.03 ether;
    uint256 public mediumBet = 0.06 ether;
    uint256 public largeBet = 0.1 ether;

    address public HOUSE_ADDRESS = 0xcE6377f66982d3C9dc83f1d7E08D29839296e2F5;
    
    /*****------- DATATYPES -------******/
    struct WeeklyBet {
        uint256 week;
        uint256[] picks;
        address picker;
        address referral;
        bool paidOut;
    }

    struct SurvivorBet {
        uint256[] picks;
        address picker;
        address referral;
        bool paidOut;
    }

    // map week to an array of bets. e.g. weeklyBets[1] = array of week 1 bets 
    SurvivorBet[] public survivorBetSmall;
    SurvivorBet[] public survivorBetMedium;
    SurvivorBet[] public survivorBetLarge;

    // map week to the pool amount for that week. e.g. weeklyPoolSmall[4] = 50 which means 50 ETH
    uint256 public survivorPoolSmall;
    uint256 public survivorPoolMedium;
    uint256 public survivorPoolLarge;

    // map week to an array of bets. e.g. weeklyBets[1] = array of week 1 bets 
    mapping (uint256 => WeeklyBet[]) public weeklyBetSmall;
    mapping (uint256 => WeeklyBet[]) public weeklyBetMedium;
    mapping (uint256 => WeeklyBet[]) public weeklyBetLarge;

    // map week to the pool amount for that week. e.g. weeklyPoolSmall[4] = 50 which means 50 ETH
    mapping (uint256 => uint256) public weeklyPoolSmall;
    mapping (uint256 => uint256) public weeklyPoolMedium;
    mapping (uint256 => uint256) public weeklyPoolLarge;
    
    /*****------- CONSTRUCTOR -------******/
    constructor() public {}

    /*****------- PUBLIC FUNCTIONS -------******/
    function getWeeklyPicksByAddress(address _address) public view returns (uint256[][][][] memory) {
        uint256[][][][] memory addressPicks; 

        for (uint256 i=1; i<19; i++) {
            for (uint256 x; x<weeklyBetSmall[i].length; x++) {
                if (weeklyBetSmall[i][x].picker == _address) {
                    uint256 userPickLength = addressPicks[0][i].length;
                    addressPicks[0][i][userPickLength] = weeklyBetSmall[i][x].picks;
                }
            }

            for (uint256 x; x<weeklyBetMedium[i].length; x++) {
                if (weeklyBetMedium[i][x].picker == _address) {
                    uint256 userPickLength = addressPicks[1][i].length;
                    addressPicks[1][i][userPickLength] = weeklyBetSmall[i][x].picks;
                } 
            }

            for (uint256 x; x<weeklyBetLarge[i].length; x++) {
                if (weeklyBetLarge[i][x].picker == _address) {
                    uint256 userPickLength = addressPicks[2][i].length;
                    addressPicks[2][i][userPickLength] = weeklyBetLarge[i][x].picks;
                }
            }
        }
        return addressPicks;
    }

    function getSurvivorPicksByAddress(address _address) public view returns (uint256[][][] memory) {
        uint256[][][] memory addressPicks; 

            for (uint256 x; x<survivorBetSmall.length; x++) {
                if (survivorBetSmall[x].picker == _address) {
                    uint256 userPickLength = addressPicks[0].length;
                    addressPicks[0][userPickLength] = survivorBetSmall[x].picks;
                }
            }

            for (uint256 x; x<survivorBetMedium.length; x++) {
                if (survivorBetMedium[x].picker == _address) {
                    uint256 userPickLength = addressPicks[1].length;
                    addressPicks[0][userPickLength] = survivorBetMedium[x].picks;
                }
            }

            for (uint256 x; x<survivorBetSmall.length; x++) {
                if (survivorBetLarge[x].picker == _address) {
                    uint256 userPickLength = addressPicks[2].length;
                    addressPicks[0][userPickLength] = survivorBetLarge[x].picks;
                }
            }
        return addressPicks;
    }

    function getSurvivorBetsSmall() public view returns (address) {
        return survivorBetSmall[1].picker;
    }

    function setSurvivorSmall(uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value >= smallBet, "Not enough for a small bet");
        SurvivorBet memory _survivorBet = SurvivorBet(_picks, _picker, _referral, false);
        survivorBetSmall.push(_survivorBet);
        survivorPoolSmall += msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }

    function setSurvivorMedium(uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value == mediumBet, "Not enough for a small bet");
        SurvivorBet memory _survivorBet = SurvivorBet(_picks, _picker, _referral, false);
        survivorBetSmall.push(_survivorBet);
        survivorPoolSmall += msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }

    function setSurvivorLarge(uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value == largeBet, "Not enough for a small bet");
        SurvivorBet memory _survivorBet = SurvivorBet(_picks, _picker, _referral, false);
        survivorBetSmall.push(_survivorBet);
        survivorPoolSmall += msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }


    /// Bet size should be "smallBet", "mediumBet", or "largeBet"
    function setWeeklyPickSmall(uint256 _week, uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value == smallBet, "Not enough for a small bet");
        WeeklyBet memory _weeklyBet = WeeklyBet(_week, _picks, _picker, _referral, false);
        weeklyBetSmall[_week].push(_weeklyBet);
        weeklyPoolSmall[_week]+= msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }

    function setWeeklyPickMedium(uint256 _week, uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value == mediumBet, "Not enough for a medium bet");
        WeeklyBet memory _weeklyBet = WeeklyBet(_week, _picks, _picker, _referral, false);
        weeklyBetMedium[_week].push(_weeklyBet);
        weeklyPoolMedium[_week]+= msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }

    function setWeeklyPickLarge(uint256 _week, uint256[] memory _picks, address _picker, address _referral) external payable { 
        require(msg.value == largeBet, "Not enough for a large bet");
        WeeklyBet memory _weeklyBet = WeeklyBet(_week, _picks, _picker, _referral, false);
        weeklyBetLarge[_week].push(_weeklyBet);
        weeklyPoolLarge[_week]+= msg.value - (msg.value * HOUSE_PAY_BIP/10000);
        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        if (_referral != address(0)) {
            payable(_referral).transfer(msg.value * REFERRAL_PAY_BIP/10000);
            HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
        }
        payable(HOUSE_ADDRESS).transfer(msg.value * HOUSE_PAY_NET_BIP/10000);
    }

    /*****------- OWNER FUNCTIONS -------******/
    function setHouseAddress(address _address) external onlyOwner {
        HOUSE_ADDRESS = _address;
    }

    function setHouseAmount(uint256 _percentage) external onlyOwner {
        HOUSE_PAY_BIP = _percentage;
    }

    function setReferralAmount(uint256 _referral) external onlyOwner {
        REFERRAL_PAY_BIP = _referral;
    }

    /**** PICK AND PAY OUT SMALL SIZE WEEKLY  ****/
    function pickSurvivorWinnerSmall(uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<survivorBetSmall.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetSmall[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetSmall[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<survivorBetSmall.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetSmall[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetSmall[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = survivorBetSmall[i].picker;
            }
        }

        uint256 payoutPool = survivorPoolSmall;
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }

    function pickSurvivorWinnerMedium(uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<survivorBetMedium.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetMedium[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetMedium[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<survivorBetMedium.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetMedium[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetMedium[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = survivorBetMedium[i].picker;
            }
        }

        uint256 payoutPool = survivorPoolMedium;
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }

    function pickSurvivorWinnerLarge(uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<survivorBetLarge.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetLarge[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetLarge[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<survivorBetLarge.length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<survivorBetLarge[i].picks.length; x++) {
                if (correctPicks[x] == survivorBetLarge[i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = survivorBetLarge[i].picker;
            }
        }

        uint256 payoutPool = survivorPoolLarge;
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }


    /**** PICK AND PAY OUT SMALL SIZE WEEKLY  ****/
    function pickWeeklyWinnerSmall(uint256 week, uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<weeklyBetSmall[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetSmall[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetSmall[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<weeklyBetSmall[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetSmall[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetSmall[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = weeklyBetSmall[week][i].picker;
            }
        }

        uint256 payoutPool = weeklyPoolSmall[week];
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }

    /**** PICK AND PAY OUT MEDIUM SIZE WEEKLY  ****/
    function pickWeeklyWinnerMedium(uint256 week, uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<weeklyBetMedium[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetMedium[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetMedium[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<weeklyBetMedium[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetMedium[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetMedium[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = weeklyBetMedium[week][i].picker;
            }
        }

        uint256 payoutPool = weeklyPoolMedium[week];
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }

    /**** PICK AND PAY OUT LARGE SIZE WEEKLY  ****/
    function pickWeeklyWinnerLarge(uint256 week, uint256[] memory correctPicks) external onlyOwner {
        uint256 highestRightCount = 0; 
        for (uint256 i; i<weeklyBetLarge[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetLarge[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetLarge[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount >= highestRightCount) {
                highestRightCount = thisPickersCount;
            }
        }

        address[] memory winners;
        for (uint256 i; i<weeklyBetLarge[week].length; i++) {
            uint256 thisPickersCount = 0;
            for (uint256 x; x<weeklyBetLarge[week][i].picks.length; x++) {
                if (correctPicks[x] == weeklyBetLarge[week][i].picks[x]) {
                    thisPickersCount++;
                }
            }
            if (thisPickersCount == highestRightCount) {
                uint256 lengthWinners = winners.length;
                winners[lengthWinners] = weeklyBetLarge[week][i].picker;
            }
        }

        uint256 payoutPool = weeklyPoolLarge[week];
        for (uint256 i; i<winners.length; i++) {
            payable(winners[i]).transfer(payoutPool / winners.length);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}