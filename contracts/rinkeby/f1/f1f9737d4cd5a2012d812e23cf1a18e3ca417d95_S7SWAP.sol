/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// File: ERC20.sol

pragma solidity ^0.4.18;

contract ERC20 {
  uint public totalSupply;

  event Transfer(address indexed from, address indexed to, uint value);  
  event Approval(address indexed owner, address indexed spender, uint value);

  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);  
}

// File: s7swap.sol

pragma solidity ^0.4.18;


contract S7SWAP {

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

  function exchange (address _openTrader, address _openContractAddress, address _closeTrader, address _closeContractAddress) public {
      ERC20 openERC20Contract = ERC20(_openContractAddress);
      ERC20 closeERC20Contract = ERC20(_closeContractAddress);
      uint256 openTotal = openERC20Contract.totalSupply();
      uint256 closeTotal = closeERC20Contract.totalSupply();
      
      require(openERC20Contract.approve(_closeTrader, openTotal));
      // require(openERC20Contract.transferFrom(_openTrader, _closeTrader, openTotal));

      // require(closeERC20Contract.approve(_openTrader, closeTotal));
      // require(openERC20Contract.transferFrom(_closeTrader, _openTrader, closeTotal));
  }

  function open(uint256 _swapID, uint256 _openValue, address _openTrader, address _openContractAddress, uint256 _closeValue, address _closeTrader, address _closeContractAddress) public onlyInvalidSwaps(_swapID) {
    // Transfer value from the opening trader to this contract.
    ERC20 openERC20Contract = ERC20(_openContractAddress);
    require(_openValue <= openERC20Contract.allowance(_openTrader, address(this)));
    require(openERC20Contract.transferFrom(_openTrader, address(this), _openValue));

    // Store the details of the swap.
    Swap memory swap = Swap({
      openValue: _openValue,
      openTrader: _openTrader,
      openContractAddress: _openContractAddress,
      closeValue: _closeValue,
      closeTrader: _closeTrader,
      closeContractAddress: _closeContractAddress
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.OPEN;

     Open(_swapID, _closeTrader);
     Log (_openTrader);
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

  // function buyRequest (address _openContractAddress, uint256 numTokens, uint256 _closeValue, address )

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
  function thisContractAddress(address _openTrader, address _openContractAddress) public view returns (uint256 openValue) {
    ERC20 openERC20Contract = ERC20(_openContractAddress);
    return openERC20Contract.allowance(_openTrader, address(this));
  }
}