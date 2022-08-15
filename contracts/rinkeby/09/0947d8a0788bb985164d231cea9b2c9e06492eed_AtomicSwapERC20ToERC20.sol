/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/AtomicSwapERC20ToERC20.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;


contract AtomicSwapERC20ToERC20 {

  struct Swap {
    uint256 openValue;
    uint256 openCost;
    address openTrader;
    address openContractAddress;
    // uint256 closeValue;
    // address closeTrader;
    // address closeContractAddress;
  }

  struct FailedBuyOrder {
    address openContractAddress;
    uint256 closeValue;
    uint256 closeCost;
    address closeTrader;
    address closeContractAddress;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    EXPIRED
  }

  mapping (uint256 => Swap) private swaps;
  mapping (uint256 => FailedBuyOrder) private failedBuyOrders;
  mapping (uint256 => States) private swapStates;

  uint256 nSwaps;
  uint256 nFailedBuyOrders;

  event Open(uint256 _swapID, address _closeTrader);
  event Expire(uint256 _swapID);
  event Close(uint256 _swapID);
  event Log (address _messageSender);

  modifier onlyInvalidSwaps(uint256 _swapID) {
    require (swapStates[_swapID] == States.INVALID);
    _;
  }

  modifier onlyOpenSwaps(uint256 _swapID) {
    require (swapStates[_swapID] == States.OPEN);
    _;
  }

  // function open(uint256 _swapID, uint256 _openValue, address _openTrader, address _openContractAddress, uint256 _closeValue, address _closeTrader, address _closeContractAddress) public onlyInvalidSwaps(_swapID) {
  //   // Transfer value from the opening trader to this contract.
  //   IERC20 openERC20Contract = IERC20(_openContractAddress);
  //   require(_openValue <= openERC20Contract.allowance(_openTrader, address(this)));
  //   require(openERC20Contract.transferFrom(_openTrader, address(this), _openValue));

  //   // Store the details of the swap.
  //   Swap memory swap = Swap({
  //     openValue: _openValue,
  //     openTrader: _openTrader,
  //     openContractAddress: _openContractAddress,
  //     closeValue: _closeValue,
  //     closeTrader: _closeTrader,
  //     closeContractAddress: _closeContractAddress
  //   });
  //   swaps[_swapID] = swap;
  //   swapStates[_swapID] = States.OPEN;

  //   nSwaps++;

  //   emit Open(_swapID, _closeTrader);
  //   emit Log (_openTrader);
  // }

  function listToken(uint256 _openValue, uint256 _openCost, address _openTrader, address _openContractAddress) public {
    // Transfer value from the opening trader to this contract.
    IERC20 openERC20Contract = IERC20(_openContractAddress);
    require(_openValue <= openERC20Contract.allowance(_openTrader, address(this)));
    require(openERC20Contract.transferFrom(_openTrader, address(this), _openValue));

    // Store the details of the swap.
    Swap memory swap = Swap({
      openValue: _openValue,
      openCost: _openCost,
      openTrader: _openTrader,
      openContractAddress: _openContractAddress
    });
    swaps[nSwaps] = swap;
    swapStates[nSwaps] = States.OPEN;

    nSwaps++;

    // emit Open(_swapID, _closeTrader);
    // emit Log (_openTrader);
  }

  function getList (address _openContractAddress) public view returns (uint256[] memory openValues, uint256[] memory openCosts, uint256[] memory closeValues, uint256[] memory closeCosts) {
    uint256 count = 0;
    uint256 failedCount = 0;
     openValues = new uint256[](nSwaps);
     openCosts = new uint256[](nSwaps);
     closeValues = new uint256[](nFailedBuyOrders);
     closeCosts = new uint256[](nFailedBuyOrders);
    
    for (uint256 i = 0; i < nSwaps; i++) {
      if (swaps[i].openContractAddress == _openContractAddress && swaps[i].openValue != 0) {
        openValues[count] = swaps[i].openValue;
        openCosts[count] = swaps[i].openCost;
        count++;
      }
    }
    for (uint256 i = 0; i < nFailedBuyOrders; i++) {
      if (failedBuyOrders[i].openContractAddress == _openContractAddress) {
        closeValues[failedCount] = failedBuyOrders[i].closeValue;
        closeCosts[failedCount] = failedBuyOrders[i].closeCost;
        failedCount++;
      }
      
    }
    return (openValues, openCosts, closeValues, closeCosts);
  }

  function buyToken (address _openContractAddress, address _closeTrader, address _closeContractAddress, uint256 _closeValue, uint256 _closeCost) public returns (bool success) {
      
      for (uint256 i = 0; i < nSwaps; i++) {
        if (swaps[i].openContractAddress == _openContractAddress && 
            swaps[i].openValue >= _closeValue && 
            swaps[i].openCost <= _closeCost) {
          IERC20 closeERC20Contract = IERC20(_closeContractAddress);
          require(_closeValue * _closeCost <= closeERC20Contract.allowance(_closeTrader, address(this)));
          require(closeERC20Contract.transferFrom(_closeTrader, swaps[i].openTrader, _closeCost * _closeValue));

          IERC20 openERC20Contract = IERC20(swaps[i].openContractAddress);
          require(openERC20Contract.transfer(_closeTrader, swaps[i].openValue));

          swaps[i].openValue -= _closeValue;
          nSwaps--;

          return true;
        }
      }

      // buy order failed
      FailedBuyOrder memory failedOrder = FailedBuyOrder({
        openContractAddress: _openContractAddress,
        closeValue: _closeValue,
        closeCost: _closeCost,
        closeTrader: _closeTrader,
        closeContractAddress: _closeContractAddress
      });
      failedBuyOrders[nFailedBuyOrders] = failedOrder;
      nFailedBuyOrders++;

      return false;
    }

  // function close(uint256 _swapID) public onlyOpenSwaps(_swapID) {
  //   // Close the swap.
  //   Swap memory swap = swaps[_swapID];
  //   swapStates[_swapID] = States.CLOSED;

  //   // Transfer the closing funds from the closing trader to the opening trader.
  //   IERC20 closeERC20Contract = IERC20(swap.closeContractAddress);
  //   require(swap.closeValue <= closeERC20Contract.allowance(swap.closeTrader, address(this)));
  //   require(closeERC20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

  //   // Transfer the opening funds from this contract to the closing trader.
  //   IERC20 openERC20Contract = IERC20(swap.openContractAddress);
  //   require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

  //   emit Close(_swapID);
  // }

  function expire(uint256 _swapID) public onlyOpenSwaps(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer opening value from this contract back to the opening trader.
    IERC20 openERC20Contract = IERC20(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.openTrader, swap.openValue));

    emit Expire(_swapID);
  }

  // function check(uint256 _swapID) public view returns (uint256 openValue, address openContractAddress, uint256 closeValue, address closeTrader, address closeContractAddress) {
  //   Swap memory swap = swaps[_swapID];
  //   return (swap.openValue, swap.openContractAddress, swap.closeValue, swap.closeTrader, swap.closeContractAddress);
  // }
  function thisContractAddress(address _openTrader, address _openContractAddress) public view returns (uint256 openValue) {
    IERC20 openERC20Contract = IERC20(_openContractAddress);
    return openERC20Contract.allowance(_openTrader, address(this));
  }
}