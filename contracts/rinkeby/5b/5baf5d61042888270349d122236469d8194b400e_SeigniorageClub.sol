/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.8.0;

contract SeigniorageClub  {
    uint256 public fee = 5; // 5% fee for 2% burning, 1% gas(0.1 % for odd one), 2% team
    uint256 public poolSize;
    uint256 public period = 1 hours;
    uint256 public houseEdge = 1;
    uint256 public burnRate = 0;
    address public owner;
    address public teamWallet = 0x473A838fefc899f548c91bFfCFb35602060cf767;
    address public treasuryWallet = 0x09c312b1B1565bEa9e8D7ac80Dc8cAAD07F4f74f;
    address public devWallet = 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D;
    address public virtualFTMAddress = 0x0000000000000000000000000000000000000000;

    struct Pool {
        address tokenAddress;
        uint256 minBet;
        uint256 maxBet;
        uint256 createdIndex;
        bool burning;
        mapping(address => uint256[]) rounds;
        mapping(uint256 => address[]) players;
    }

    struct Burn {
        uint256 lastBurnt;
        uint256 totalBurnt;
    }

    struct Random {
        bytes32 value;
        uint256 timestamp;
    }

    struct Balance {
        uint256 lastUpdatedRound;
        uint256 depositAmount;
        uint256 withdrawAmount;
    }

    mapping(uint256 => Pool) public pools;
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(address => mapping(address => Balance)) private userBalance;
    mapping(address => Burn) public burns;
    mapping(address => uint256) private devClaimed;
    mapping(address => uint256) private teamClaimed;
    mapping(address => uint256) private treasuryClaimed;

    Random[] public randoms;

    constructor(){
        owner = msg.sender;
        randoms.push(
            Random(
                keccak256(abi.encodePacked(block.timestamp)),
                block.timestamp
            )
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "Only Team");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasuryWallet, "Only Treasury");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == devWallet, "Only dev");
        _;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 5, "exceed limit");
        require(_fee > 2, "minimum fee");
        fee = _fee;
    }

    function transferOwnership(address _new) external onlyOwner {
        owner = _new;
    }

    function setTeamWallet(address _new) external onlyTeam {
        teamWallet = _new;
    }

    function setTreasuryWallet(address _new) external onlyTreasury {
        treasuryWallet = _new;
    }

    function setDevWallet(address _new) external onlyDev {
        devWallet = _new;
    }

    // This function can only be called by the current owner. This function creates a pool where users can bet their tokens.
    // (Example: Tomb Token, Min Bet 10,000000000000000000, Max Bet 100,000000000000000000, Burn[True])
    // This means users will be able to play with Tomb, min bet 10, max bet 100, burning mechanism on in this pool. Each pool will have its own index number.
    function addPool(
        address _tokenAddress,
        uint256 _minBet,
        uint256 _maxBet,
        bool _burning
    ) external onlyOwner {
        poolSize++;
        pools[poolSize].createdIndex = randoms.length;
        pools[poolSize].tokenAddress = _tokenAddress;
        pools[poolSize].minBet = _minBet;
        pools[poolSize].maxBet = _maxBet;
        pools[poolSize].burning = _burning;
    }

    // This function can be called by only owner. The function changes the Min Max Bet & Burn (True or False) of the existing pool.
    // ChangeMinMax($Tomb, 15,150,False) will make it min bet 15, max bet 150, and burn mechanism False
    function editPool(
        address _tokenAddress,
        uint256 _minBet,
        uint256 _maxBet,
        bool _burning
    ) external onlyOwner {
        for (uint256 i = 1; i <= poolSize; i++) {
            Pool storage currentPool = pools[i];
            if (currentPool.tokenAddress == _tokenAddress) {
                currentPool.minBet = _minBet;
                currentPool.maxBet = _maxBet;
                currentPool.burning = _burning;
                break;
            }
        }
    }

    // This function can be called by only owner, changes the house edge.
    // If input is 2 5000 0000 0000000000 (2.5), it means house edge is 2.5%
    // This creates TWO bet types like this. Let’s call the Input NUMBER
    // BetType A. is determined like this
    // (50 – (NUMBER / 2)) Chance to win / 2.00x = 48.75% Chance / 2x Win
    // BetType B. is determined like this
    // 50% Chance to Win / (2 – (Number / 100 * 2))x = 50% chance / 1.95x Win
    function setHouseEdge(uint256 _houseEdge) external onlyOwner {
        houseEdge = _houseEdge;
    }

    // This function can only be called by the owner address. It determines the Burn Rate. If 0.5 is entered, it means burn rate is 0.5%.
    function setBurnRate(uint256 _burnRate) external onlyOwner {
        burnRate = _burnRate;
    }
}