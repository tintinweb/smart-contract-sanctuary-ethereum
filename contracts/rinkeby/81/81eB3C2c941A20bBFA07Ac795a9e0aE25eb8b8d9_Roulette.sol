//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "VRFConsumerBase.sol";
import "GambleToken.sol";

contract Roulette is Ownable, VRFConsumerBase{

  GambleToken internal gambleToken;
  address internal cage;
  address[] internal players;
  uint8 internal winningNumber;
  uint256 internal fee;
  bytes32 internal keyHash;

  enum BET {
    Red,
    Black,
    Even,
    Odd,
    High,
    Low,
    Column1_34,
    Column2_35,
    Column3_36,
    FirstDozen,
    SecondDozen,
    ThirdDozen,
    Zero,
    DoubleZero,
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Eleven,
    Twelve,
    Thirteen,
    Fourteen,
    Fifteen,
    Sixteen,
    Seventeen,
    Eighteen,
    Nineteen,
    Twenty,
    Twentyone,
    Twentytwo,
    Twentythree,
    Twentyfour,
    Twentyfive,
    Twentysix,
    Twentyseven,
    Twentyeight,
    Twentynine,
    Thirty,
    Thirtyone,
    Thirtytwo,
    Thirtythree,
    Thirtyfour,
    Thirtyfive,
    Thirtysix,
    Split_1_4,
    Split_1_2,
    Split_2_3,
    Split_2_5,
    Split_3_6,
    Split_4_5,
    Split_4_7,
    Split_5_6,
    Split_5_8,
    Split_6_9,
    Split_7_8,
    Split_7_10,
    Split_8_9,
    Split_8_11,
    Split_9_12,
    Split_10_11,
    Split_10_13,
    Split_11_12,
    Split_11_14,
    Split_12_15,
    Split_13_14,
    Split_13_16,
    Split_14_15,
    Split_14_17,
    Split_15_18,
    Split_16_17,
    Split_16_19,
    Split_17_18,
    Split_17_20,
    Split_18_21,
    Split_19_20,
    Split_19_22,
    Split_20_21,
    Split_20_23,
    Split_21_24,
    Split_22_23,
    Split_22_25,
    Split_23_24,
    Split_23_26,
    Split_24_27,
    Split_25_26,
    Split_25_28,
    Split_26_27,
    Split_26_29,
    Split_27_30,
    Split_28_29,
    Split_28_31,
    Split_29_30,
    Split_29_32,
    Split_30_33,
    Split_31_32,
    Split_31_34,
    Split_32_33,
    Split_32_35,
    Split_33_36,
    Split_34_35,
    Split_35_36,
    Square_1245,
    Square_2356,
    Square_4578,
    Square_5689,
    Square_781011,
    Square_891112,
    Square_10111314,
    Square_11121415,
    Square_13141617,
    Square_14151718,
    Square_16171920,
    Square_17182021,
    Square_19202223,
    Square_20212324,
    Square_22232526,
    Square_23242627,
    Square_25262829,
    Square_26272930,
    Square_28293132,
    Square_29303233,
    Square_31323435,
    Square_32333536
  }

  mapping (address => bool) atTable;
  mapping (address => Bet[]) playerToBets;
  mapping (address => uint256) playerToWinnings;
  mapping (address => uint256) playerToLifetimeWinnings;

  event PlayerSatDown(address player);
  event BetsPlaced(address player, uint256 totalBet);
  event RequestedRandomness(bytes32 requestId);
  event BallStopped(uint256 winningNumber);
  event WinningsPaidOut(address player, uint256 payout);
  event LeftTable(address player);


  constructor (
    address _gambleTokenAddress,
    address _cageAddress,
    address _vrfCoordinator,
    address _link,
    uint256 _fee,
    bytes32 _keyHash
  ) public  VRFConsumerBase(_vrfCoordinator, _link){
    gambleToken = GambleToken(_gambleTokenAddress);
    cage = _cageAddress;
    fee = _fee;
    keyHash = _keyHash;
  }

  struct Bet {
    uint256 amount;
    BET betType;
  }


 //player functions
  function joinTable() public {
    require(gambleToken.balanceOf(msg.sender) > 0, "You need GMBL to sit down at the table.");
    atTable[msg.sender] = true;
    players.push(msg.sender);
    emit PlayerSatDown(msg.sender);
  }

  function placeBet(uint256[] memory _amounts, uint256[] memory _types) public qualified{
    require(_amounts.length == _types.length);
    for (uint i = 0; i < _amounts.length; i++) {
      playerToBets[msg.sender].push(Bet(_amounts[i],BET(_types[i])));
    }
    uint256 totalBet = _calculateTotalBet(_amounts);
    gambleToken.burn(msg.sender, totalBet);

    emit BetsPlaced(msg.sender, totalBet);
  }

  function leaveTable() public qualified{
    atTable[msg.sender] = false;
    emit LeftTable(msg.sender);
  }

  //owner functions
  function spinWheel() public onlyOwner {
    bytes32 requestId = requestRandomness(keyHash, fee);
    //emit event
    emit RequestedRandomness(requestId);
  }

  function settleAllBets() public onlyOwner {
    for(uint i = 0; i < players.length; i++){
      if (!atTable[players[i]]) {
      }  else {
        _settlePlayerBets(players[i]);
      }
    }
  }


  //viewer functions
  function isAtTable(address _player) public view returns(bool) {
    return atTable[_player];
  }
  function getPlayers() public view returns(address[] memory) {
    return players;
  }
  function getBets(address _player) public view returns(Bet[] memory) {
    return playerToBets[_player];
  }
  function getWinnings(address _player) public view returns(uint256) {
    return playerToWinnings[_player];
  }
  function getLifetimeWinnings(address _player) public view returns(uint256) {
    return playerToLifetimeWinnings[_player];
  }

  //internal functions
  function _calculateTotalBet(uint256[] memory _amounts) internal returns(uint256){
    uint256 totalBet = 0;
    for(uint i = 0; i < _amounts.length; i++) {
        totalBet += _amounts[i];
    }
    return totalBet;
  }
  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    require(_randomness > 0, "random-not-found");
    winningNumber = uint8(_randomness % 38);
    emit BallStopped(winningNumber);
  }
  function _settlePlayerBets(address _player) internal {
    Bet[] memory playerBets = playerToBets[_player];
    uint256 payout = 0;
    for (uint i = 0; i < playerBets.length; i++){
      uint256 multiplier = _winOrLoss(playerBets[i].betType);
      payout += ((playerBets[i].amount * multiplier) + playerBets[i].amount);
    }
    gambleToken.mint(_player, payout);
    playerToWinnings[_player] = payout;
    playerToLifetimeWinnings[_player] += payout;
    emit WinningsPaidOut(_player, payout);

  }
  function _winOrLoss(BET _betType) internal view returns(uint256){
    BET betType = _betType;
    uint256 multiplier = 0;
    //check for win or loss
    //most likely going to use if statements
    //one for each number (1-36)
    //inside of each branch need to describe winning bets based on number
    //ie: 1 means red, firstdozen,low,odd,column1,split12,split14,square1245
    if (winningNumber == 1) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_1245) {
        multiplier = 8;
      }
      else if (betType == BET.Split_1_2 ||
               betType == BET.Split_1_4) {
        multiplier = 17;
      }
      else if (betType == BET.One) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 2) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_1245 ||
               betType == BET.Square_2356) {
        multiplier = 8;
      }
      else if (betType == BET.Split_1_2 ||
               betType == BET.Split_2_3 ||
               betType == BET.Split_2_5) {
        multiplier = 17;
      }
      else if (betType == BET.Two) {
        multiplier = 35;
      }

    }
    else if (winningNumber == 3) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_2356) {
        multiplier = 8;
      }
      else if (betType == BET.Split_2_3 ||
               betType == BET.Split_3_6) {
        multiplier = 17;
      }
      else if (betType == BET.Three) {
        multiplier = 35;
      }

    }
    else if (winningNumber == 4) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_1245 ||
               betType == BET.Square_4578) {
        multiplier = 8;
      }
      else if (betType == BET.Split_1_4 ||
               betType == BET.Split_4_5 ||
               betType == BET.Split_4_7) {
        multiplier = 17;
      }
      else if (betType == BET.Four) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 5) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_2356 ||
               betType == BET.Square_1245 ||
               betType == BET.Square_4578 ||
               betType == BET.Square_5689) {
        multiplier = 8;
      }
      else if (betType == BET.Split_2_5 ||
               betType == BET.Split_4_5 ||
               betType == BET.Split_5_6 ||
               betType == BET.Split_5_8) {
        multiplier = 17;
      }
      else if (betType == BET.Five) {
        multiplier = 35;
      }

    }
    else if (winningNumber == 6) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_2356 ||
               betType == BET.Square_5689) {
        multiplier = 8;
      }
      else if (betType == BET.Split_3_6 ||
               betType == BET.Split_5_6 ||
               betType == BET.Split_6_9) {
        multiplier = 17;
      }
      else if (betType == BET.Six) {
        multiplier = 35;
      }

    }
    else if (winningNumber == 7) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_4578 ||
               betType == BET.Square_781011) {
        multiplier = 8;
      }
      else if (betType == BET.Split_4_7 ||
               betType == BET.Split_7_8 ||
               betType == BET.Split_7_10) {
        multiplier = 17;
      }
      else if (betType == BET.Seven) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 8) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_4578 ||
               betType == BET.Square_5689 ||
               betType == BET.Square_781011 ||
               betType == BET.Square_891112) {
        multiplier = 8;
      }
      else if (betType == BET.Split_5_8 ||
               betType == BET.Split_7_8 ||
               betType == BET.Split_8_9 ||
               betType == BET.Split_8_11) {
        multiplier = 17;
      }
      else if (betType == BET.Eight) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 9) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_5689 ||
               betType == BET.Square_891112) {
        multiplier = 8;
      }
      else if (betType == BET.Split_6_9 ||
               betType == BET.Split_8_9 ||
               betType == BET.Split_9_12) {
        multiplier = 17;
      }
      else if (betType == BET.Nine) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 10) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_781011 ||
               betType == BET.Square_10111314) {
        multiplier = 8;
      }
      else if (betType == BET.Split_7_10 ||
               betType == BET.Split_10_11 ||
               betType == BET.Split_10_13) {
        multiplier = 17;
      }
      else if (betType == BET.Ten) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 11) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_781011 ||
               betType == BET.Square_891112 ||
               betType == BET.Square_10111314 ||
               betType == BET.Square_11121415) {
        multiplier = 8;
      }
      else if (betType == BET.Split_8_11 ||
               betType == BET.Split_10_11 ||
               betType == BET.Split_11_12 ||
               betType == BET.Split_11_14) {
        multiplier = 17;
      }
      else if (betType == BET.Eleven) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 12) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.FirstDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_891112 ||
               betType == BET.Square_11121415) {
        multiplier = 8;
      }
      else if (betType == BET.Split_9_12 ||
               betType == BET.Split_11_12 ||
               betType == BET.Split_12_15) {
        multiplier = 17;
      }
      else if (betType == BET.Twelve) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 13) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_10111314 ||
               betType == BET.Square_13141617) {
        multiplier = 8;
      }
      else if (betType == BET.Split_10_13 ||
               betType == BET.Split_13_14 ||
               betType == BET.Split_13_16) {
        multiplier = 17;
      }
      else if (betType == BET.Thirteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 14) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_10111314 ||
               betType == BET.Square_11121415 ||
               betType == BET.Square_13141617 ||
               betType == BET.Square_14151718) {
        multiplier = 8;
      }
      else if (betType == BET.Split_11_14 ||
               betType == BET.Split_13_14 ||
               betType == BET.Split_14_15 ||
               betType == BET.Split_14_17) {
        multiplier = 17;
      }
      else if (betType == BET.Fourteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 15) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_11121415 ||
               betType == BET.Square_14151718) {
        multiplier = 8;
      }
      else if (betType == BET.Split_12_15 ||
               betType == BET.Split_14_15 ||
               betType == BET.Split_15_18) {
        multiplier = 17;
      }
      else if (betType == BET.Fifteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 16) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_13141617 ||
               betType == BET.Square_16171920) {
        multiplier = 8;
      }
      else if (betType == BET.Split_13_16 ||
               betType == BET.Split_16_17 ||
               betType == BET.Split_16_19) {
        multiplier = 17;
      }
      else if (betType == BET.Sixteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 17) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_13141617 ||
               betType == BET.Square_14151718 ||
               betType == BET.Square_16171920 ||
               betType == BET.Square_17182021) {
        multiplier = 8;
      }
      else if (betType == BET.Split_14_17||
               betType == BET.Split_16_17 ||
               betType == BET.Split_17_18 ||
               betType == BET.Split_17_20) {
        multiplier = 17;
      }
      else if (betType == BET.Seventeen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 18) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.Low){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_14151718 ||
               betType == BET.Square_17182021) {
        multiplier = 8;
      }
      else if (betType == BET.Split_15_18 ||
               betType == BET.Split_17_18 ||
               betType == BET.Split_18_21) {
        multiplier = 17;
      }
      else if (betType == BET.Eighteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 19) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_16171920 ||
               betType == BET.Square_19202223) {
        multiplier = 8;
      }
      else if (betType == BET.Split_13_16 ||
               betType == BET.Split_16_17 ||
               betType == BET.Split_16_19) {
        multiplier = 17;
      }
      else if (betType == BET.Nineteen) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 20) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_16171920 ||
               betType == BET.Square_17182021 ||
               betType == BET.Square_19202223 ||
               betType == BET.Square_20212324) {
        multiplier = 8;
      }
      else if (betType == BET.Split_17_20 ||
               betType == BET.Split_19_20 ||
               betType == BET.Split_20_21 ||
               betType == BET.Split_20_23) {
        multiplier = 17;
      }
      else if (betType == BET.Twenty) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 21) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_17182021 ||
               betType == BET.Square_20212324) {
        multiplier = 8;
      }
      else if (betType == BET.Split_18_21 ||
               betType == BET.Split_20_21 ||
               betType == BET.Split_21_24) {
        multiplier = 17;
      }
      else if (betType == BET.Twentyone) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 22) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_19202223 ||
               betType == BET.Square_22232526) {
        multiplier = 8;
      }
      else if (betType == BET.Split_19_22 ||
               betType == BET.Split_22_23 ||
               betType == BET.Split_22_25) {
        multiplier = 17;
      }
      else if (betType == BET.Twentytwo) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 23) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_19202223 ||
               betType == BET.Square_20212324 ||
               betType == BET.Square_22232526 ||
               betType == BET.Square_23242627) {
        multiplier = 8;
      }
      else if (betType == BET.Split_20_23 ||
               betType == BET.Split_22_23 ||
               betType == BET.Split_23_24 ||
               betType == BET.Split_23_26) {
        multiplier = 17;
      }
      else if (betType == BET.Twentythree) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 24) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.SecondDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_20212324 ||
               betType == BET.Square_23242627) {
        multiplier = 8;
      }
      else if (betType == BET.Split_21_24 ||
               betType == BET.Split_23_24 ||
               betType == BET.Split_24_27) {
        multiplier = 17;
      }
      else if (betType == BET.Twentyfour) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 25) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_22232526 ||
               betType == BET.Square_25262829) {
        multiplier = 8;
      }
      else if (betType == BET.Split_22_25 ||
               betType == BET.Split_25_26 ||
               betType == BET.Split_25_28) {
        multiplier = 17;
      }
      else if (betType == BET.Twentyfive) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 26) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_22232526 ||
               betType == BET.Square_23242627 ||
               betType == BET.Square_25262829 ||
               betType == BET.Square_26272930) {
        multiplier = 8;
      }
      else if (betType == BET.Split_23_26 ||
               betType == BET.Split_25_26 ||
               betType == BET.Split_26_27 ||
               betType == BET.Split_26_29) {
        multiplier = 17;
      }
      else if (betType == BET.Twentysix) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 27) {
      if (betType == BET.Red ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_23242627 ||
               betType == BET.Square_26272930) {
        multiplier = 8;
      }
      else if (betType == BET.Split_24_27||
               betType == BET.Split_26_27 ||
               betType == BET.Split_27_30) {
        multiplier = 17;
      }
      else if (betType == BET.Twentyseven) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 28) {
      if (betType == BET.Black ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_25262829 ||
               betType == BET.Square_28293132) {
        multiplier = 8;
      }
      else if (betType == BET.Split_25_28 ||
               betType == BET.Split_28_29 ||
               betType == BET.Split_28_31) {
        multiplier = 17;
      }
      else if (betType == BET.Twentyeight) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 29) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_25262829 ||
               betType == BET.Square_26272930 ||
               betType == BET.Square_28293132 ||
               betType == BET.Square_29303233) {
        multiplier = 8;
      }
      else if (betType == BET.Split_26_29 ||
               betType == BET.Split_28_29 ||
               betType == BET.Split_29_30 ||
               betType == BET.Split_29_32) {
        multiplier = 17;
      }
      else if (betType == BET.Twentynine) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 30) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_26272930 ||
               betType == BET.Square_29303233) {
        multiplier = 8;
      }
      else if (betType == BET.Split_27_30 ||
               betType == BET.Split_29_30 ||
               betType == BET.Split_30_33) {
        multiplier = 17;
      }
      else if (betType == BET.Thirty) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 31) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_28293132 ||
               betType == BET.Square_31323435) {
        multiplier = 8;
      }
      else if (betType == BET.Split_28_31 ||
               betType == BET.Split_31_32 ||
               betType == BET.Split_31_34) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtyone) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 32) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_28293132 ||
               betType == BET.Square_29303233 ||
               betType == BET.Square_31323435 ||
               betType == BET.Square_32333536) {
        multiplier = 8;
      }
      else if (betType == BET.Split_29_32 ||
               betType == BET.Split_31_32 ||
               betType == BET.Split_32_33 ||
               betType == BET.Split_32_35) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtytwo) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 33) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_29303233 ||
               betType == BET.Square_32333536) {
        multiplier = 8;
      }
      else if (betType == BET.Split_30_33 ||
               betType == BET.Split_32_33 ||
               betType == BET.Split_33_36) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtythree) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 34) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column1_34) {
        multiplier = 2;
      }
      else if (betType == BET.Square_31323435) {
        multiplier = 8;
      }
      else if (betType == BET.Split_31_34 ||
               betType == BET.Split_34_35) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtyfour) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 35) {
      if (betType == BET.Black ||
          betType == BET.Odd ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column2_35) {
        multiplier = 2;
      }
      else if (betType == BET.Square_31323435 ||
               betType == BET.Square_32333536) {
        multiplier = 8;
      }
      else if (betType == BET.Split_32_35 ||
               betType == BET.Split_34_35 ||
               betType == BET.Split_35_36) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtyfive) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 36) {
      if (betType == BET.Red ||
          betType == BET.Even ||
          betType == BET.High){
        multiplier = 1;
      }
      else if (betType == BET.ThirdDozen ||
               betType == BET.Column3_36) {
        multiplier = 2;
      }
      else if (betType == BET.Square_32333536) {
        multiplier = 8;
      }
      else if (betType == BET.Split_33_36 ||
               betType == BET.Split_35_36) {
        multiplier = 17;
      }
      else if (betType == BET.Thirtysix) {
        multiplier = 35;
      }
    }
    else if (winningNumber == 37) {
      if (betType == BET.Zero) {
        multiplier = 35;
      }

    }
    else if (winningNumber == 0) {
      if (betType == BET.DoubleZero) {
        multiplier = 35;
      }
    }
    return multiplier;
    }

    modifier qualified() {
      require(atTable[msg.sender], "Must be sitting at table to place bet.");
      _;
    }
  }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract GambleToken is ERC20 {

    constructor() ERC20("Gamble", "GMBL") public {
    }

    function mint(address _to, uint256 _amount) external {
      _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) external {
      _burn(_account, _amount);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}