/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

pragma solidity =0.7.6;
// Developed by Orcania (https://orcania.io/)

interface IOCA{
         
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    function multipleTransfer(address[] calldata recipients, uint256[] calldata amount) external;
    function multipleTransfer(address[] calldata recipients, uint256 amount) external;

    function approve(address spender, uint256 amount) external;  
    function clearAllowance(address[] calldata users) external;

    function burnAddressZero() external;
    function burn(uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value); 
  
}

abstract contract OrcaniaMath {

    function mul(uint256 num1, uint256 num2) internal view returns(uint256 out) {
        out = num1 * num2;
        require(out / num1 == num2, "OVERFLOW");
    }

}

contract OCA is IOCA, OrcaniaMath {

    mapping (address => uint256) private _balances;
    mapping (address/*owner*/ => mapping(address/*spender*/ => uint256/*amount*/)) private _allowances;
    
    uint256 private _totalSupply = 250000000 * 10**18;

    constructor() {
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //Read functions=========================================================================================================================
    function name() external view override returns (string memory) {
        return "Orcania";
    }
    function symbol() external view override returns (string memory) {
        return "OCA";
    }
    function decimals() external view override returns (uint8) {
        return 18;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    //User write functions=========================================================================================================================
    function transfer(address recipient, uint256 amount) external override returns(bool){
       require((_balances[msg.sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
        
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
            
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool){
        require((_allowances[sender][msg.sender] -= amount) <= (uint256(-1) - amount), "INSUFFICIENT_ALLOWANCE");
        require((_balances[sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
            
        _balances[recipient] += amount; 
            
        emit Transfer(sender, recipient, amount);
            
        return true;
    }

    function multipleTransfer(address[] calldata recipient, uint256[] calldata amount) external override {
        uint256 length = amount.length;

        require(recipient.length == length, "MISMATCH_BETWEEN_RECIPIENT_AND_AMOUNT");

        uint256 total;
            
        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            uint256 amt = amount[t];

            total += amt;
            require(total >= amt, "OVERFLOW");
            
            _balances[rec] += amt;
            emit Transfer(msg.sender, rec, amt);
        }
        
        require((_balances[msg.sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");
    }

    function multipleTransfer(address[] calldata recipient, uint256 amount) external override{

        uint256 length = recipient.length;
        uint256 total = mul(length, amount);

        require((_balances[msg.sender] -= total) < (uint256(-1) - total), "INSUFFICIENT_BALANCE");

        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            
            _balances[rec] += amount;
            emit Transfer(msg.sender, rec, amount);
        }
        
    }

    function approve(address spender, uint256 amount) external override {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
    }
    function clearAllowance(address[] calldata users) external override{
        uint256 length = users.length;

        for(uint256 t; t < length; ++t) {_allowances[msg.sender][users[t]] = 0;}
    }

    function burnAddressZero() external override {
        _totalSupply -= _balances[address(0)];
        _balances[address(0)] = 0;
    }

    function burn(uint256 amount) external override {
        require((_balances[msg.sender] -= amount) < (uint256(-1) - amount), "INSUFFICIENT_BALANCE");
        
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }

}