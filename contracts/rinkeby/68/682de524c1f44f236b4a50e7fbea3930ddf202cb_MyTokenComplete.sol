/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.5.16;

contract MyTokenComplete {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint public totalSupply = 100000e8;
    address payable public owner;

    mapping(address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) public allowence;

    event   Transfer(address indexed _from, address indexed _to, uint tokens);
    event   Approval(address indexed _tokenOwner, address indexed _spender, uint tokens);
    event   Burn(address indexed _from, uint value);

    constructor(string memory tokenName, string memory tokenSymbol) public {
        _balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_balanceOf[msg.sender]>=_value);
        require(_balanceOf[_to] + _value >= _balanceOf[_to]);
        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
       
    }

    function transfer(address _to, uint256 _value) public returns(bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowence[_from][msg.sender]);
        allowence[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address account) external view returns (uint){
       return _balanceOf[account];
    }

    function approval(address _spender, uint256 _value) public returns (bool success){
        allowence[msg.sender][_spender] =_value;
        emit Approval (msg.sender, _spender, _value);
        return true;
    }

   

    function mintToken(address target, uint256 mintedAmount)  public{
        require(msg.sender == owner);
        _balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), target, mintedAmount);
       
    }


    function burn(uint256 _value)  public returns(bool success){
        require(msg.sender == owner);
        require(_balanceOf[msg.sender] >= _value);
        _balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function swap() payable public {
        require(msg.value >= 0.1 ether, "not enough eth");
        uint swapTokenAmount = msg.value * 1000 * 10e8 / 1 ether;
        require(_balanceOf[owner] >= swapTokenAmount, "not enough token");
        owner.transfer(msg.value);
        
        _balanceOf[owner] -= swapTokenAmount;
        _balanceOf[msg.sender] += swapTokenAmount;
        emit Transfer(owner, msg.sender, swapTokenAmount);
    }

}