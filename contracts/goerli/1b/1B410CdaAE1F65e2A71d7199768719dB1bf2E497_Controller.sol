/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// File: contracts/library/Owned.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

contract Owned {
  address private owner;
  address private newOwner;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function Owned() {
    owner = msg.sender;
  }

  function changeOwner(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

// File: contracts/library/Finalizable.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

contract Finalizable is Owned {
  bool public finalized;

  modifier notFinalized() {
    require(!finalized);
    _;
  }

  function Finalizable() {
    finalized = false;
  }

  function finalize() public onlyOwner {
    finalized = true;
  }
}

// File: contracts/library/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

// File: contracts/ledger/Ledger.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;



contract Ledger is Owned, SafeMath, Finalizable {
    address public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;

    function setController(address _controller) onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        if (msg.sender != controller) throw;
        _;
    }

    function transfer(address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value)
    onlyController
    returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    event LogMint(address indexed owner, uint amount);
    event LogMintingStopped();

    function mint(address _a, uint _amount) onlyOwner mintingActive {
        balanceOf[_a] += _amount;
        totalSupply += _amount;
        LogMint(_a, _amount);
    }

    function multiMint(uint[] bits) onlyOwner mintingActive {
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint amount = bits[i]&((1<<96) - 1);
            mint(a, amount);
        }
    }

    bool public mintingStopped;

    function stopMinting() onlyOwner {
        mintingStopped = true;
        LogMintingStopped();
    }

    modifier mintingActive() {
        if (mintingStopped) throw;
        _;
    }

    function burn(address _owner, uint _amount) onlyController {
        balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}

// File: contracts/controller/Controller.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.4.11;



contract Controller is Owned, Finalizable {
    Ledger public ledger;
    address public token;

    function setToken(address _token) onlyOwner notFinalized {
        token = _token;
    }

    function setLedger(address _ledger) onlyOwner notFinalized {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        if (msg.sender != token) throw;
        _;
    }

    function totalSupply() constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) onlyToken constant returns (uint) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender)
    onlyToken constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyToken
    returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyToken
    returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }


    function burn(address _owner, uint _amount) onlyToken {
        ledger.burn(_owner, _amount);
    }
}