// SPDX-License-Identifier: MIT
import "GatekeeperOne.sol";
pragma solidity ^0.8.0;



contract Entry {
    uint counter;
    bytes8 gateKey;
    address gatekeeperAddress;
    event Log(bool result);
    event Log2(string message);
    constructor(address _gatekeeper)public {
       gatekeeperAddress = _gatekeeper;
    }


    GatekeeperOne gatekeeper = GatekeeperOne(gatekeeperAddress);

    receive() external payable {
        if (counter < 1) {
            counter++;
        }
        
    }
    function convertor() public returns (bytes8){
        gateKey=bytes8(uint64(uint16(uint160(tx.origin))));
        return gateKey;
    }
    function enter() public returns(bool){
        bytes8 key = convertor();

        try gatekeeper.enter(key) returns (bool result) {
            emit Log(result);
            return result;
        } catch Error(string memory reason) {
            emit Log2(reason);
        }        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin,"test");
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0,"test2");
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}