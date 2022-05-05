// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The Button
contract TheButton {
  // Constants
  uint256 public constant BUTTON_COST = 0.01 ether;

  // State variables
  uint256 public treasureBalance = 0;
  uint256 public blockLastPressed;
  address public claimer;

  constructor() {}

  /**
   * @param msgValue Total amount of ether provided by caller.
   * @dev Reverts if incorrect ether amount provided.
   */
  modifier correctEtherAmount(uint256 msgValue) {
    require(
      BUTTON_COST == msgValue,
      'TheButton: Incorrect ether amount provided.'
    );
    _;
  }

  /**
   * @dev Reverts if 3 or more blocks have not passed since last press.
   */
  modifier enoughBlocksPassed() {
    require(
      block.number - blockLastPressed > 2,
      'TheButton: Not enough blocks have passed.'
    );
    _;
  }

  /**
   * @dev Reverts if caller is not the current claimer.
   */
  modifier onlyClaimer() {
    require(
      claimer == msg.sender,
      'TheButton: Only the claimer can claim treasure.'
    );
    _;
  }

  /**
   * @notice A button, go on, press it.
   * @dev Increases treasure balance, sets block last pressed, and sets claimer.
   * @dev Reverts if correct ether amount has not been provided.
   */
  function pressButton() external payable correctEtherAmount(msg.value) {
    // Increase the balance of the treasure.
    treasureBalance += msg.value;

    // Set the new claimer.
    claimer = msg.sender;

    // Set the block number of the last button press.
    blockLastPressed = block.number;
  }

  /**
   * @notice Claim your treasure if 'tis yours to claim.
   * @dev Claims treasure if enough blocks have passed.
   * @dev Only current claimer address can claim the treasure.
   * @dev Transaction reverts if less than 3 blocks have passed since last press.
   */
  function claimTreasure() external onlyClaimer enoughBlocksPassed {
    // Remove the claimer.
    claimer = address(0);

    // Transfer the treasure to the claimer.
    payable(msg.sender).transfer(treasureBalance);

    // Set treasure balance to 0.
    treasureBalance = 0;
  }
}