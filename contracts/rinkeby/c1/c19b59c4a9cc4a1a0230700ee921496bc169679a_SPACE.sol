/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// File: contracts/Interfaces/ISpace.sol



pragma solidity >=0.8.4;

interface ISpace {

    event mintedToken(address target, uint256 mintedAmount);

    function mintToken(address target, uint256 mintedAmount)  external ;

}
// File: contracts/Interfaces/ITokenERC20.sol



pragma solidity >=0.8.4;

interface ITokenERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);

    event FrozenFunds(address target, bool frozen);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) external returns (bool success);

    function burn(uint256 _value) external returns (bool success);

    function burnFrom(address _from, uint256 _value) external returns (bool success);

    function freezeAccount(address target, bool freeze) external;

    function isBlacklisted(address _addr) external  returns (bool);

    function isCallerFrozen() external returns (bool);
    
}
// File: contracts/Owned.sol


pragma solidity ^0.8.4;


contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller should be Owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// File: contracts/TokenERC20.sol


pragma solidity ^0.8.4;



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 is ITokenERC20, owned{
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;


    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;            
        name = tokenName;                        
        symbol = tokenSymbol;           
    }

    function freezeAccount(address target, bool freeze) onlyOwner public override {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function _transferAllowed(address _addr) internal view {
        require(frozenAccount[_addr] == false, "Address is Frozen");
    }

    function isBlacklisted(address _addr) public view override returns (bool) {
        return frozenAccount[_addr];
    }

    function isCallerFrozen() public view override returns (bool) {
        return frozenAccount[msg.sender];
    }

    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != address(0x0), "should Transfer to correct address");

        require(balanceOf[_from] >= _value, "Not enough balance from the sender");

        require(balanceOf[_to] + _value > balanceOf[_to], "overflows");

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    function transfer(address _to, uint256 _value) public override returns (bool success) {
        _transferAllowed(_to);
        _transferAllowed(msg.sender);
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        _transferAllowed(_from);
        _transferAllowed(_to);
        _transferAllowed(msg.sender);
        require(_value <= allowance[_from][msg.sender], "You are not allowed to transfer passed amount");    
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public override
        returns (bool success) {
        _transferAllowed(_spender);
        _transferAllowed(msg.sender);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public override
        returns (bool success) {
        _transferAllowed(_spender);
        _transferAllowed(msg.sender);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public override returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance of tokens to burn");  
        _transferAllowed(msg.sender);
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;               
        emit Burn(msg.sender, _value);
        return true;
    }

   
    function burnFrom(address _from, uint256 _value) public override returns (bool success) {
        _transferAllowed(_from);
        _transferAllowed(msg.sender);
        require(balanceOf[_from] >= _value, "Not enough balance of tokens to burn");               
        require(_value <= allowance[_from][msg.sender], "Not allowed to burn such amount of tokens");
        balanceOf[_from] -= _value;                     
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;         
        emit Burn(_from, _value);
        return true;
    }
}
// File: contracts/Space.sol


pragma solidity ^0.8.4;




contract SPACE is owned, TokenERC20, ISpace {

    uint256 internal initialSupply = 5000000000;
    string internal tokenName = "Space Token";
    string internal tokenSymbol = "SPACE";

    constructor() TokenERC20(initialSupply, tokenName, tokenSymbol)  {}

    function mintToken(address target, uint256 mintedAmount) onlyOwner public override {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        emit mintedToken(target, mintedAmount);
    }


}