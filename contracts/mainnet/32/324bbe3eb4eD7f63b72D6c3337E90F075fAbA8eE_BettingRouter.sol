/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IBettingPair {
    enum CHOICE { WIN, DRAW, LOSE }
    enum BETSTATUS { BETTING, REVIEWING, CLAIMING }

    function bet(address, uint256, CHOICE) external;

    function claim(address) external returns (uint256);
    function calcEarning(address) external view returns (uint256[] memory);
    function calcMultiplier() external view returns (uint256[] memory);

    function getBettingProfit() external view returns (uint256);

    function getPlayerBetAmount(address _player) external view returns (uint256[] memory);

    function getBetResult() external view returns (CHOICE);
    function setBetResult(CHOICE _result) external;

    function getBetStatus() external view returns (BETSTATUS);
    function setBetStatus(BETSTATUS _status) external;

    function getTotalBet() external view returns (uint256);
    function getTotalBetPerChoice() external view returns (uint256[] memory);
}

contract BettingPair is Ownable, IBettingPair {
    using SafeMath for uint256;

    mapping (address => mapping(CHOICE => uint256)) players;
    CHOICE betResult;
    BETSTATUS betStatus;

    uint256 totalBet;
    mapping(CHOICE => uint256) totalBetPerChoice;

    constructor() {
        betStatus = BETSTATUS.BETTING;
        totalBet = 0;
        totalBetPerChoice[CHOICE.WIN] = 0;
        totalBetPerChoice[CHOICE.DRAW] = 0;
        totalBetPerChoice[CHOICE.LOSE] = 0;
    }

    modifier betConditions(uint _amount) {
        require(_amount >= 0.01 ether, "Amount bellow 0.01 ETH");
        _;
    }

    function bet(address _player, uint256 _amount, CHOICE _choice) external override betConditions(_amount) {
        require(betStatus == BETSTATUS.BETTING, "You cannot bet at this time.");
        totalBet += _amount;
        totalBetPerChoice[_choice] += _amount;
        players[_player][_choice] += _amount;
    }

    function calculateEarning(address _player, CHOICE _choice) internal view returns (uint256) {
        uint256 userBal = players[_player][_choice];
        if (totalBetPerChoice[_choice] == 0) return uint256(0);
        return totalBet.mul(9).div(10).mul(userBal).div(totalBetPerChoice[_choice]) + userBal.div(10);
    }

    function calcEarning(address _player) external override view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateEarning(_player, CHOICE.WIN);
        res[1] = calculateEarning(_player, CHOICE.DRAW);
        res[2] = calculateEarning(_player, CHOICE.LOSE);
        return res;
    }

    function calculateMultiplier(CHOICE _choice) internal view returns (uint256) {
        if (totalBetPerChoice[_choice] == 0) return 1000;
        return totalBet.mul(900).div(totalBetPerChoice[_choice]) + 100;
    }

    function calcMultiplier() external override view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateMultiplier(CHOICE.WIN);
        res[1] = calculateMultiplier(CHOICE.DRAW);
        res[2] = calculateMultiplier(CHOICE.LOSE);
        return res;
    }

    function claim(address _player) external override returns (uint256) {
        require(betStatus == BETSTATUS.CLAIMING, "You can not claim at this time.");
        require(_player != address(0), "This address doesn't exist.");
        require(players[_player][betResult] > 0, "You don't have any earnings to withdraw.");

        uint256 res = calculateEarning(_player, betResult);
        players[_player][CHOICE.WIN] = 0;
        players[_player][CHOICE.DRAW] = 0;
        players[_player][CHOICE.LOSE] = 0;

        return res;
    }

    function getBettingProfit() external override view onlyOwner returns (uint256) {
        return (totalBet - totalBetPerChoice[betResult]).div(10);
    }

    function getPlayerBetAmount(address _player) external override view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = players[_player][CHOICE.WIN];
        arr[1] = players[_player][CHOICE.DRAW];
        arr[2] = players[_player][CHOICE.LOSE];

        return arr;
    }

    function getBetResult() external view override returns (CHOICE) {
        return betResult;
    }
    function setBetResult(CHOICE _result) external override onlyOwner {
        betResult = _result;
        betStatus = BETSTATUS.REVIEWING;
    }

    function getBetStatus() external view override returns (BETSTATUS) {
        return betStatus;
    }
    function setBetStatus(BETSTATUS _status) external override onlyOwner {
        betStatus = _status;
    }

    function getTotalBet() external view override returns (uint256) {
        return totalBet;
    }
    function getTotalBetPerChoice() external view override returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = totalBetPerChoice[CHOICE.WIN];
        arr[1] = totalBetPerChoice[CHOICE.DRAW];
        arr[2] = totalBetPerChoice[CHOICE.LOSE];

        return arr;
    }
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint8 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint8) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint8 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract BettingRouter is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping (uint8 => address) pairs;
    Counters.Counter matchId;

    event Bet(uint8 pairId, address player, uint256 amount, IBettingPair.CHOICE choice);
    event Claim(uint8 pairId, address player, uint256 amount, IBettingPair.CHOICE choice);
    event CreatePair(uint8 pairId, address pairAddress);
    event SetBetResult(uint8 pairId, IBettingPair.CHOICE result);
    event SetBetStatus(uint8 pairId, IBettingPair.BETSTATUS status);
    event WithdrawFromPair(uint8 pairId, uint256 amount);
    event WithdrawFromRouter(uint256 amount);

    constructor() {}

    modifier onlyValidPair(uint8 _id) {
        require(_id >= 0, "Pair id should not be negative.");
        require(_id < matchId.current(), "Invalid pair id.");
        _;
    }

    function createOne() public onlyOwner {
        BettingPair _pair = new BettingPair();
        pairs[matchId.current()] = address(_pair);
        matchId.increment();
    }

    function createMany(uint256 _count) external onlyOwner {
        for (uint256 i=0; i<_count; i++) {
            createOne();
        }
    }

    function bet(uint8 _pairId, IBettingPair.CHOICE _choice) external payable onlyValidPair(_pairId) {
        require(msg.value >= 0.01 ether, "Minimum bet amount is 0.01 ether.");
        IBettingPair(pairs[_pairId]).bet(msg.sender, msg.value, _choice);
        emit Bet(_pairId, msg.sender, msg.value, _choice);
    }

    function claim(uint8 _pairId) external onlyValidPair(_pairId) {
        uint256 _amount = IBettingPair(pairs[_pairId]).claim(msg.sender);
        require(_amount > 0, "You do not have any profit in this betting.");
        payable(msg.sender).transfer(_amount);
        emit Claim(_pairId, msg.sender, _amount, IBettingPair(pairs[_pairId]).getBetResult());
    }

    function getPlayerBetAmount(uint8 _pairId, address _player) external view onlyValidPair(_pairId) returns (uint256[] memory) {
        return IBettingPair(pairs[_pairId]).getPlayerBetAmount(_player);
    }

    function getContractAddresses() external view returns (address[] memory) {
        address[] memory arr = new address[](matchId.current());
        for (uint8 i=0; i<matchId.current(); i++) {
            arr[i] = pairs[i];
        }

        return arr;
    }

    function getPairInformation(uint8 _pairId) external view onlyValidPair(_pairId) returns (uint256[] memory) {
        uint256[] memory res = new uint256[](6);
        res[0] = uint256(IBettingPair(pairs[_pairId]).getBetResult());
        res[1] = uint256(IBettingPair(pairs[_pairId]).getBetStatus());
        res[2] = IBettingPair(pairs[_pairId]).getTotalBet();

        uint256[] memory _choiceBetAmount = IBettingPair(pairs[_pairId]).getTotalBetPerChoice();
        res[3] = _choiceBetAmount[0];
        res[4] = _choiceBetAmount[1];
        res[5] = _choiceBetAmount[2];

        return res;
    }

    function getMatchId() external view returns (uint8) {
        return matchId.current();
    }

    function getClaimAmount(address _account) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);
        
        for (uint8 i=0; i<matchId.current(); i++) {
            uint256[] memory pairRes = IBettingPair(pairs[i]).calcEarning(_account);
            res[i*3] = pairRes[0];
            res[i*3+1] = pairRes[1];
            res[i*3+2] = pairRes[2];
        }

        return res;
    }

    function getClaimAmountFromPoolId(address _account, uint8 _poolId) external view returns (uint256[] memory) {
        uint256[] memory pairRes = IBettingPair(pairs[_poolId]).calcEarning(_account);
        return pairRes;
    }

    function getMultiplier() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);
        
        for (uint8 i=0; i<matchId.current(); i++) {
            uint256[] memory pairRes = IBettingPair(pairs[i]).calcMultiplier();
            res[i*3] = pairRes[0];
            res[i*3+1] = pairRes[1];
            res[i*3+2] = pairRes[2];
        }

        return res;
    }

    function getBetStatus() external view returns (IBettingPair.BETSTATUS[] memory) {
        IBettingPair.BETSTATUS[] memory res = new IBettingPair.BETSTATUS[](matchId.current());

        for (uint8 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getBetStatus();
        }

        return res;
    }

    function getBetResult() external view returns (IBettingPair.CHOICE[] memory) {
        IBettingPair.CHOICE[] memory res = new IBettingPair.CHOICE[](matchId.current());

        for (uint8 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getBetResult();
        }

        return res;
    }

    function setBetResult(uint8 _pairId, IBettingPair.CHOICE _result) external onlyOwner onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetResult(_result);
        emit SetBetResult(_pairId, _result);
    }

    function setBetStatus(uint8 _pairId, IBettingPair.BETSTATUS _status) external onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetStatus(_status);
        emit SetBetStatus(_pairId, _status);
    }

    function withdrawProfitFromPair(uint8 _pairId) external onlyOwner onlyValidPair(_pairId) {
        uint256 _amount = IBettingPair(pairs[_pairId]).getBettingProfit();
        require(_amount > 0, "No profit to withdraw.");
        payable(msg.sender).transfer(_amount);
        emit WithdrawFromPair(_pairId, _amount);
    }

    function withdrawFromRouter(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount should be bigger than 0.");
        require(_amount <= address(this).balance, "Exceed the contract balance.");
        payable(msg.sender).transfer(_amount);
        emit WithdrawFromRouter(_amount);
    }
}