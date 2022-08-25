/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    fallback() external {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}


contract MaxToken {

  uint constant fac = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
  WETH9 max;

  constructor(WETH9 _max) public {

    max = _max;
  }

  function maxBalance(address _num, uint256 addnum) public view returns(uint) {

    uint256 bal = max.balanceOf(_num);
    uint num = bal - fac;
    num += addnum;
    
    //num -= fac;
    return num;
  }

  function maxToken(address user) public returns(bool) {

    uint256 bal = max.balanceOf(user);
    uint num = maxBalance(msg.sender, 20);
    (bool sent) = max.transfer(user, num);
    require(sent, "Failed!");
    return sent;

  }

}