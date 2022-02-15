pragma solidity 0.7.6;

/*
  The nefarious Pixel Pavel has struck again! This time exploiting a DeFi
  protocol and draining 298 Wei. Interpol does not know his whereabouts but
  they have identified this contract as where he is keeping his funds.
  
  After scouring StackOverflow and many Discord channels, they were still
  unable to crack the code and retrieve the funds. So, now they have
  reached out to you, Esther Von Munchen, as their last hope to retrieve
  the funds.
  
  Be sharp, be patient, and those 298 Wei will return to their rightful owner.

  Good luck!
*/

contract PixelPavel {
  uint8 constant public smallPrizeAnswer = 42;
  uint256 constant public bigPrizeWinningAnswer = 298;

  constructor() payable {
    require(msg.value == bigPrizeWinningAnswer, "Gotta pay to play, 298 Wei.");
  }
  
  function crackCode(uint8 _smallAnswer) external {
    require(_smallAnswer == smallPrizeAnswer, "Answer must equal 42.");

    // Well done! You won the small prize. Now let's try for the big kahuna.
    (bytes32 sig, bytes32 data) = abi.decode(
      abi.encodePacked(bytes28(0), msg.data),
      (bytes32,bytes32)
    );

    if (keccak256(abi.encode(bigPrizeWinningAnswer)) == keccak256(abi.encode(data))) {
      uint amount = address(this).balance;
      (bool success, ) = payable(tx.origin).call{value: amount}("");
      require(success, "Failed to send Ether");
    }
  }
}