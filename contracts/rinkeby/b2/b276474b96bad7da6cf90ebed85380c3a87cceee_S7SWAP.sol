/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

contract SLCToken {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "SLC Token";
    string public constant symbol = "SLC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowedOwner;

    uint256 _totalSupply;

    constructor(uint256 total) {
      _totalSupply = total;
      balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowedOwner[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowedOwner[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowedOwner[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowedOwner[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}



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
      SLCToken openERC20Contract = SLCToken(_openContractAddress);
      SLCToken closeERC20Contract = SLCToken(_closeContractAddress);
      uint256 openTotal = openERC20Contract.totalSupply();
      uint256 closeTotal = closeERC20Contract.totalSupply();
      
      require(openERC20Contract.approve(address(this), openTotal));
      require(openERC20Contract.transferFrom(_openTrader, address(this), openTotal));

      // require(closeERC20Contract.approve(address(this), closeTotal));
      // require(closeERC20Contract.transferFrom(_closeTrader, address(this), closeTotal));

      // require(closeERC20Contract.transfer(_openTrader, closeTotal));
      // require(openERC20Contract.transfer(_closeTrader, openTotal));
  }

  function open(uint256 _swapID, uint256 _openValue, address _openTrader, address _openContractAddress, uint256 _closeValue, address _closeTrader, address _closeContractAddress) public onlyInvalidSwaps(_swapID) {
    // Transfer value from the opening trader to this contract.
    SLCToken openERC20Contract = SLCToken(_openContractAddress);
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

    //  Open(_swapID, _closeTrader);
    //  Log (_openTrader);
  }

  function close(uint256 _swapID) public onlyOpenSwaps(_swapID) {
    // Close the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.CLOSED;

    // Transfer the closing funds from the closing trader to the opening trader.
    SLCToken closeERC20Contract = SLCToken(swap.closeContractAddress);
    require(swap.closeValue <= closeERC20Contract.allowance(swap.closeTrader, address(this)));
    require(closeERC20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

    // Transfer the opening funds from this contract to the closing trader.
    SLCToken openERC20Contract = SLCToken(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

    //  Close(_swapID);
  }

  // function buyRequest (address _openContractAddress, uint256 numTokens, uint256 _closeValue, address )

  function expire(uint256 _swapID) public onlyOpenSwaps(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer opening value from this contract back to the opening trader.
    SLCToken openERC20Contract = SLCToken(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.openTrader, swap.openValue));

    //  Expire(_swapID);
  }

  function check(address  deployedCoin) public view returns (uint256 totalSupply) {
    SLCToken openERC20Contract = SLCToken(deployedCoin);
      uint256 openTotal = openERC20Contract.totalSupply();
    return openTotal;
  }
  function thisContractAddress(address _openTrader, address _openContractAddress) public view returns (uint256 openValue) {
    SLCToken openERC20Contract = SLCToken(_openContractAddress);
    return openERC20Contract.allowance(_openTrader, address(this));
  }
}