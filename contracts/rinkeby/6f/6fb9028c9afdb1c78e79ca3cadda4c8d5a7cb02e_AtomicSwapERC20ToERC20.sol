pragma solidity ^0.4.18;

import "./ERC20.sol";

contract AtomicSwapERC20ToERC20 {

  struct Swap {
    uint256 openValue;
    address openTrader;
    address openContractAddress;
    uint256 closeValue;
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
  mapping (uint256 => States) private swapStates;

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

  function open(uint256 _swapID, uint256 _openValue, address _openContractAddress, uint256 _closeValue, address _closeTrader, address _closeContractAddress) public onlyInvalidSwaps(_swapID) {
    // Transfer value from the opening trader to this contract.
    ERC20 openERC20Contract = ERC20(_openContractAddress);
    require(_openValue <= openERC20Contract.allowance(msg.sender, address(this)));
    require(openERC20Contract.transferFrom(msg.sender, address(this), _openValue));

    // Store the details of the swap.
    Swap memory swap = Swap({
      openValue: _openValue,
      openTrader: msg.sender,
      openContractAddress: _openContractAddress,
      closeValue: _closeValue,
      closeTrader: _closeTrader,
      closeContractAddress: _closeContractAddress
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.OPEN;

     Open(_swapID, _closeTrader);
     Log (msg.sender);
  }

  function close(uint256 _swapID) public onlyOpenSwaps(_swapID) {
    // Close the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.CLOSED;

    // Transfer the closing funds from the closing trader to the opening trader.
    ERC20 closeERC20Contract = ERC20(swap.closeContractAddress);
    require(swap.closeValue <= closeERC20Contract.allowance(swap.closeTrader, address(this)));
    require(closeERC20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

    // Transfer the opening funds from this contract to the closing trader.
    ERC20 openERC20Contract = ERC20(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

     Close(_swapID);
  }

  function expire(uint256 _swapID) public onlyOpenSwaps(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer opening value from this contract back to the opening trader.
    ERC20 openERC20Contract = ERC20(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.openTrader, swap.openValue));

     Expire(_swapID);
  }

  function check(uint256 _swapID) public view returns (uint256 openValue, address openContractAddress, uint256 closeValue, address closeTrader, address closeContractAddress) {
    Swap memory swap = swaps[_swapID];
    return (swap.openValue, swap.openContractAddress, swap.closeValue, swap.closeTrader, swap.closeContractAddress);
  }
}