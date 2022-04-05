/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// File: contracts/Token.sol

pragma solidity ^0.5.0;

contract Token {
    string  public name = "DApp Token";
    string  public symbol = "DAPP";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

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

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) payable public returns (bool success) {
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
// File: contracts/Transfer.sol

pragma solidity ^0.5.0;

 
contract Transfer { 
  Token public token;

  constructor(Token _token) public {
    token = _token;
  }

    // Called transferTest to avoid naming issues with token.transfer
    // FeeAmount would get hard coded as a constant in JS code by dev, not a dynamic parameter for user..
  function transferTest(uint256 _amount, address payable _receiver, uint _feeAmount, address payable _bank) payable public {
    // Sub feeAmount from receivers amount
    _amount = _amount - _feeAmount;

    // Transfer funds to this contract before this is possible, with token contract
    token.transfer(_receiver, _amount);
    token.transfer(_bank, _feeAmount);
  }

}