/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract ERC20 is IERC20 {

    constructor (string memory _name, string memory _symbol, uint8 _decimal) {
        
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        owner = msg.sender;
    }
    address owner;
    string name_;
    string symbol_;
    uint8 decimal_;
    uint256 tSupply;

    mapping (address => uint256) balances;

    function name() public view returns (string memory ){
        return name_;
    }
    function symbol() public view returns (string memory){
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    function totalSupply() public view returns (uint256){
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    uint8 tax = 10; // 10 percent    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value; // a + a+b ; a+=b
        balances[_to] += _value*(100-tax)/100;
        balances[owner] += _value*tax/100;
        emit Transfer(msg.sender,_to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Insufficient balance with owner");
        require(approved[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value; // a + a+b ; a+=b
        balances[_to] += _value;
        approved[_from][msg.sender] -= _value;
        emit Transfer(_from,_to, _value);
        return true;
    }   
    
    mapping(address => mapping(address => uint256)) approved;

    function approve(address _spender, uint256 _value) public returns (bool success){
        approved[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    // Increase or Decrease allowance.
    function increaseAllowance(address _spender, uint256 _value) public returns(bool success){
        approved[msg.sender][_spender] += _value;
     
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _value) public returns(bool success){
        require(approved[msg.sender][_spender]>= _value, "Not enough allowance to decrease");
        approved[msg.sender][_spender] -= _value;
    
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
       return approved[_owner][_spender]; 
    }
    // Mint & Burn
    function mint(address _to, uint _value) public {
        tSupply += _value;
        balances[_to] += _value;
    }
    function burn(address _from, uint _value) public {
        require(balances[_from]>= _value, "Not enough tokens to burn");
        tSupply -= _value;
        balances[_from] -= _value;

    }


}

contract JioToken is ERC20 {
    
    constructor (uint256 _tSupply) ERC20("JioToken2","JIO2",2){
       
        mint(owner, _tSupply);
    }

}



// contract TokenSwap {
//     // swap Jio Token for Ether.

//     IERC20 token;

//     constructor (IERC20 _token) {
//         token = _token;
//     }   

//     function swap(uint _value) public payable {
//         // swap 100 token for 1 ether.
//         token.transfer(address(this), _value);
//         payable(msg.sender).transfer(1 ether);

//     }






// }