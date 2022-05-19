/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.4.26; // solhint-disable-line

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract RainbowDAOToken{
    using SafeMath for uint256;
    string public name = "Rainbow DAO Token";
    string public symbol = "Rainbow";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000 * 10 ** 18;
    uint256 public inittotalSupply = 10000 * 10 ** 18;
    address public CEO;
    uint256 public initAdvance = 2500 * 10 ** 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(address _CEO)public{
        balanceOf[_CEO] = inittotalSupply - initAdvance;
        balanceOf[this] = initAdvance;
        emit Transfer(address(0), _CEO, inittotalSupply - initAdvance);
        emit Transfer(address(0), this, initAdvance);
    }
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
    function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != address(0x0));
		require(_value > 0);
        require(balanceOf[_from]>= _value);  
        require(balanceOf[_to].add(_value)  > balanceOf[_to]); 

        balanceOf[_from] = balanceOf[_from].sub( _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
     }
    
    
    function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]); 
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public returns (bool success) {
        _approve(address(msg.sender),_spender,_value);
        return true;
    }
    
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function()external payable {
        
    }
    
    event ActiveBurn(address indexed,uint256,uint256);
    
    function activeBurn(uint256 _value)external returns(bool){
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        uint256 ContractBNBBalance = address(this).balance;
        uint256 BNB_amount = _value.mul(ContractBNBBalance).div(totalSupply);
        balanceOf[msg.sender]=balanceOf[msg.sender].sub(_value);
        totalSupply=totalSupply.sub(_value);
        msg.sender.transfer(BNB_amount);
        emit ActiveBurn(msg.sender,_value,BNB_amount);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
    
    function getUnderpinningPrice()public view returns(uint256){
        uint256 ContractBNBBalance = address(this).balance;
        return ContractBNBBalance.mul(10 ** uint256(decimals)).div(totalSupply);
    }
    
    function BurnAmount()external view returns(uint256){
        return inittotalSupply.sub(totalSupply);
    }

    event Destroy(address,uint256);

    function destroy(uint256 _value)external returns(bool){
        require(_value >0 && balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Destroy(msg.sender,_value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    uint256 public minAdvance = 10 ** 17;
    event Advance(address,address,uint256);

    function advance()public payable{
        require(msg.value >= minAdvance);
        require(msg.value % minAdvance == 0);
        uint256 _value = msg.value / minAdvance;
        CEO.transfer(msg.value);
        _transfer(address(this),msg.sender,_value * 10 ** uint256(decimals));
        emit Advance(address(this),msg.sender,_value * 10 ** uint256(decimals));
    }

}