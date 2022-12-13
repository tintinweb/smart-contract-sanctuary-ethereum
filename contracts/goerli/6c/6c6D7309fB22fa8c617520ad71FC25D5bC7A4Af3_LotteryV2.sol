// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface StakedGLP {
  function balanceOf(address account) external returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);
}

interface RewardRouter {
  function mintAndStakeGlpETH(uint256 minUSDG, uint256 minGLP) external payable;
}

contract LotteryV2 {
  address public constant GMX_REWARD_ROUTER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
  address public constant STAKED_GLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
  address public immutable MULTISIG;
  uint256 public immutable entryPrice;
  uint256 public immutable interval;
  uint256 public immutable startDate;

  mapping(address => uint256) public balances;
  mapping(uint256 => address[]) public playersInRound;
  mapping(uint256 => uint256) public etherCollectedInRound;
  mapping(uint256 => uint256) public uniqueAccountsInRound;
  mapping(uint256 => mapping(address => uint256)) public numberOfEntriesInRoundPerAccount;

  mapping(uint256 => mapping(address => bool)) public hasClaimedRefund;
  mapping(uint256 => bool) public roundClosed;

  event RoundActivated(uint256 round);
  event Withdrawed(address indexed account, uint256 amount);
  event Refunded(address account, uint256 round, uint256 etherRefunded, uint256 entriesRefunded);
  event EntriesBought(
    address indexed account,
    uint256 indexed round,
    uint256 accountEntries,
    uint256 payment
  );
  event WinnerSelected(
    address indexed winner,
    address indexed serviceProvider,
    uint256 round,
    uint256 prize,
    uint256 fee,
    uint256 service
  );
  event GLPSent(address indexed sender, address indexed beneficiary, uint256 glpSent);
  event GLPBought(
    address indexed sender,
    address indexed beneficiary,
    uint256 glpBought,
    uint256 amountEthConverted,
    uint256 _timestamp
  );

  error Levi_Lottery_Insufficient_Ether();
  error Levi_Lottery_Invalid_Amount_Entries();
  error Levi_Lottery_Cannot_Process_Refund();
  error Levi_Lottery_Cant_Select_Winner();
  error Levi_Lottery_Cannot_Send_GLP();

  constructor(address _multisig) {
    MULTISIG = _multisig;
    entryPrice = 0.001 ether;
    interval = 3 days;
    startDate = block.timestamp;
  }

  /// Any user can convert collected fees in GLP and send them to multisig.
  function convertEthBalanceIntoGLP() external {
    uint256 ethBalance = balances[address(this)];
    balances[address(this)] = 0;
    uint256 glpBalanceBefore = StakedGLP(STAKED_GLP).balanceOf(address(this));
    RewardRouter(GMX_REWARD_ROUTER).mintAndStakeGlpETH{value: ethBalance}(0, 0);
    uint256 glpBalanceAfter = StakedGLP(STAKED_GLP).balanceOf(address(this));

    require(StakedGLP(STAKED_GLP).transfer(MULTISIG, glpBalanceAfter));

    emit GLPBought(
      msg.sender,
      MULTISIG,
      glpBalanceAfter - glpBalanceBefore,
      ethBalance,
      block.timestamp
    );
  }

  /// Function where any user can buy up to 5 entries to the lottery.
  function enterLottery(uint256 amountEntries) external payable {
    if (msg.value != (amountEntries * entryPrice)) revert Levi_Lottery_Insufficient_Ether();
    if (amountEntries > 5 || amountEntries == 0) revert Levi_Lottery_Invalid_Amount_Entries();

    uint256 round = getRound();

    // This means this account has never bought entries for this round.
    // Update the number of unique accounts on this round
    if (numberOfEntriesInRoundPerAccount[round][msg.sender] == 0) {
      uniqueAccountsInRound[round] += 1;

      // Emit an event of activation if the unique players are at least 5.
      if (uniqueAccountsInRound[round] > 4) {
        emit RoundActivated(round);
      }
    }

    /// More entries means more probability to win.
    for (uint256 i = 0; i < amountEntries; i++) {
      playersInRound[round].push(msg.sender);
    }

    etherCollectedInRound[round] += msg.value;
    numberOfEntriesInRoundPerAccount[round][msg.sender] += amountEntries;

    emit EntriesBought(msg.sender, round, amountEntries, msg.value);
  }

  /// Any user can call this function for any round that have not been closed
  /// The user who succesfully call this function gets 1% of the prize pot.
  function selectWinner(uint256 round) external {
    if (round >= getRound()) revert Levi_Lottery_Cant_Select_Winner();
    if (uniqueAccountsInRound[round] < 5) revert Levi_Lottery_Cant_Select_Winner();
    if (roundClosed[round]) revert Levi_Lottery_Cant_Select_Winner();

    uint256 etherInThisRound = etherCollectedInRound[round];

    uint256 prize = (etherInThisRound * 85) / 100; // 85%
    uint256 fee = (etherInThisRound * 14) / 100; // 14%
    uint256 service = etherInThisRound - prize - fee; // 1%

    uint256 index = _random() % playersInRound[round].length;
    address winner = playersInRound[round][index];

    playersInRound[round] = new address[](0);

    balances[winner] += prize;
    balances[address(this)] += fee;
    balances[msg.sender] += service;

    roundClosed[round] = true;

    emit WinnerSelected(winner, msg.sender, round, prize, fee, service);
  }

  function withdraw() external {
    uint256 balance = balances[msg.sender];

    balances[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success);

    emit Withdrawed(msg.sender, balance);
  }

  /// For invalid rounds it makes sense to the users to be avaiable to get a refund of their ether.
  function getRefund(uint256 round) external {
    if (round >= getRound()) revert Levi_Lottery_Cannot_Process_Refund();
    if (uniqueAccountsInRound[round] >= 5) revert Levi_Lottery_Cannot_Process_Refund();
    if (hasClaimedRefund[round][msg.sender]) revert Levi_Lottery_Cannot_Process_Refund();

    uint256 amountOfEntries = numberOfEntriesInRoundPerAccount[round][msg.sender];
    uint256 etherToRefund = entryPrice * amountOfEntries;

    hasClaimedRefund[round][msg.sender] = true;

    (bool success, ) = msg.sender.call{value: etherToRefund}("");
    require(success);

    emit Refunded(msg.sender, round, etherToRefund, amountOfEntries);
  }

  /// @notice Returns the current round of the lottery.
  function getRound() public view returns (uint256) {
    return ((block.timestamp - startDate) / interval) + 1;
  }

  function _random() internal view returns (uint256) {
    return
      uint256(
        keccak256(abi.encodePacked(msg.sender, block.timestamp, blockhash((block.number - 32))))
      );
  }
}