/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity 0.8.7;

// https://github.com/AmbireTech/wallet/blob/main/contracts/WALLET.sol

contract SUPERWALLETToken {

    // Token information
    string public constant name = "SUPERWALLET";
    string public constant symbol = "SUPERWALLET";
    uint8 public  constant decimals = 18;
    uint256 public constant  MAX_SUPPLY  = 1000000000000000000000000000;
    
    

    	// Mutable variables

        uint public totalSupply;
        uint public totalBurned;
        mapping(address => uint) public balances;
       mapping(address => mapping(address => uint)) allowed;
        mapping(address => uint) public burns;

     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);
        event Burn(address indexed burner, uint256 value);

        event SupplyController(address indexed previousController, address indexed newController);

        address public supplyController;
        address public burnController;

        constructor (address _supplyController)  {
           supplyController = _supplyController;
            emit SupplyController(address(0), _supplyController);

        }

        function balanceOf(address _owner) public view returns (uint balance) {
            return balances[_owner];
        }

        function transfer(address _to, uint256 _value) public returns (bool success) {
            require(balances[msg.sender] >= _value);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        function transferFrom(address from, address to, uint amount) external returns (bool success) {
		balances[from] = balances[from] - amount;
		allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
		balances[to] = balances[to] + amount;
		emit Transfer(from, to, amount);
		return true;
	}

       function approve(address spender,uint amount) external returns (bool success) {
		allowed[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}
            

        function allowance(address owner, address spender) external view returns (uint remaining) {
            return allowed[owner][spender];
        }

        function burn(uint256 _value) public returns (bool success) {
            require(balances[msg.sender] >= _value);
            balances[msg.sender] -= _value;
            totalBurned += _value;
            burns[msg.sender] += _value;
            emit Burn(msg.sender, _value);
            return true;
        }

        function burnFrom(address _burner, uint256 _value) public returns (bool success) {
            require(balances[_burner] >= _value);
            require(burns[_burner] >= _value);
            balances[_burner] -= _value;
            totalBurned += _value;
            burns[_burner] += _value;
            emit Burn(_burner, _value);
            return true;
        }

        function innerMint ( address _owner, uint _amount) internal {
            totalSupply = totalSupply + _amount;
            require(balances[_owner] + _amount <= totalSupply);
            balances[_owner] = balances[_owner] + _amount;

            emit Transfer(address(0), _owner, _amount);


        }

        function mint(address _owner, uint _amount) public {
            require(supplyController == msg.sender);
            innerMint(_owner, _amount);
        }

        function changeSupplyController(address _newController) public {
            require(supplyController == msg.sender);
            supplyController = _newController;
            emit SupplyController(msg.sender, _newController);
        }


}