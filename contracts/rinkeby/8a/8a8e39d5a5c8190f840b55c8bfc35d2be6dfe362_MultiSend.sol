/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MultiSend {
    string  public name = "Multi Send";
    string  public symbol = "MSC";
    string  public standard = "MSC";
    uint256 public totalSupply;
    // to save the amount of ethers in the smart-contract
    uint total_value;    
    address private owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply)  {
      balanceOf[msg.sender] = _initialSupply;
      totalSupply = _initialSupply;
      owner = msg.sender;
    }

    // modifier to check if the caller is a owner or not 
    modifier isOwner() {
        require(msg.sender == owner, "Your Not a Owner, Only Owner can access");
        _;
    }

    function sendBatch(address[] memory addrs, uint256[] memory balances) public {
      for(uint i = 0; i < addrs.length; i++) {
          require(balanceOf[msg.sender] >= balances[i]);

          balanceOf[msg.sender] -=balances[i];
          balanceOf[addrs[i]] += balances[i]; 

          emit Transfer(msg.sender,addrs[i],balances[i]);
      }
    }

    // multipleSending enable to send ether to different accounts
    function sendMultipleEther(address payable[] memory addresses , uint[] memory amounts) public payable isOwner {
        total_value = msg.value;
        // the addresses and amounts should be same in length
        require(addresses.length == amounts.length, "The length of two array should be the same");

        // the value of the message should be exact of total amounts
        uint totalAmnt = 0; // uint totalAmnts = sum(accounts);

        for (uint j=0; j < amounts.length; j++) {
            totalAmnt +=  amounts[j];
        }
        
        // converting  WEI value to ethers value for checking (when we are giving eth value it is converting to Wei so we are again converting it to Eth)
        total_value = (total_value/(10**18)); 
        require(total_value == totalAmnt, "The value is not sufficient or exceed");
        // require(msg.value == totalAmnt, "The value is not sufficient or exceed");

        for (uint i=0; i < addresses.length; i++) {
            address payable receiverAddr = addresses[i];
            uint receiverAmnt = (amounts[i]*(10**18));
            receiverAddr.transfer(receiverAmnt);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}