/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

pragma solidity ^0.5.0;

contract Reentrancy {

    // Vulnerable smart contract by Dridri for root-me
    // DO NOT PUBLISH THIS ON MAINNET FOR REAL PURPOSES

    string public name     = "Custom Wrapped Ether";
    string public symbol   = "CWETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    bool public locked = true;

    constructor() public payable {
        require(msg.value > 0);
        deposit();
    }

    function() external payable {
        deposit();
    }

    function claim() external {
      if(address(this).balance == 0 ) {
        locked = false;
      }
    }


    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        assert(balanceOf[msg.sender] - wad < balanceOf[msg.sender]);
        msg.sender.call.value(wad)("");
        balanceOf[msg.sender] -= wad;
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