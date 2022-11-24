/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

88888888ba,                                    88                            
88      `"8b                            ,d     ""                            
88        `8b                           88                                   
88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                    d8'      
                                                                   d8'       
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>If ask the past life,<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*
________               _____ _____                  ________                           ______      
___  __ \_____ __________  /____(_)_______ _____  _____  __/_____ _______ ___ ________ ___  /_____ 
__  / / /_  _ \__  ___/_  __/__  / __  __ \__  / / /__  /   _  _ \__  __ `__ \___  __ \__  / _  _ \
_  /_/ / /  __/_(__  ) / /_  _  /  _  / / /_  /_/ / _  /    /  __/_  / / / / /__  /_/ /_  /  /  __/
/_____/  \___/ /____/  \__/  /_/   /_/ /_/ _\__, /  /_/     \___/ /_/ /_/ /_/ _  .___/ /_/   \___/ 
                                           /____/                             /_/                  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*
* SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.17;
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
contract Destiny is IERC20 {
    event Deposit(address indexed sender, uint amount, uint balance);

    address public owner;

    string public _name;

    string public _symbol;

    uint8 public _decimals;

    uint256 public _totalSupply;

    uint256 constant private MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) public _allowances;


    modifier msgSenderNotZero(){
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        _;
    }
    modifier verifyBalance(address sender,uint256 _value){
        require(_balances[sender] >= _value,"ERC20: transfer amount exceeds balance");
        _;
    }


    constructor(){
            owner=address(0);

            _name="Destiny";

            _symbol="DIY";

            _decimals=2;

            _totalSupply=21000000000;
            
            _balances[msg.sender] = _totalSupply;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    function getOwner() external view returns (address) {
        return owner;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }


    function transfer(address recipient, uint256 _value) public msgSenderNotZero verifyBalance(msg.sender,_value)  returns (bool) {

        _balances[msg.sender] -= _value;
        _balances[recipient] += _value;
        emit Transfer(msg.sender, recipient, _value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 _value)public msgSenderNotZero verifyBalance(sender,_value) returns (bool) {
        uint256 _allowance = _allowances[sender][msg.sender];
        require(_allowance >= _value,"ERC20: transfer amount exceeds allowance");
        
        _balances[sender] -= _value;
        _balances[recipient] += _value;
        if (_allowance < MAX_UINT256) {
            _allowances[sender][msg.sender] -= _value;
        }
        emit Transfer(sender, recipient, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public msgSenderNotZero returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

88888888ba,                                    88                            
88      `"8b                            ,d     ""                            
88        `8b                           88                                   
88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                    d8'      
                                                                   d8'       
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>All in the wind.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*
________               _____ _____                  ________                           ______      
___  __ \_____ __________  /____(_)_______ _____  _____  __/_____ _______ ___ ________ ___  /_____ 
__  / / /_  _ \__  ___/_  __/__  / __  __ \__  / / /__  /   _  _ \__  __ `__ \___  __ \__  / _  _ \
_  /_/ / /  __/_(__  ) / /_  _  /  _  / / /_  /_/ / _  /    /  __/_  / / / / /__  /_/ /_  /  /  __/
/_____/  \___/ /____/  \__/  /_/   /_/ /_/ _\__, /  /_/     \___/ /_/ /_/ /_/ _  .___/ /_/   \___/ 
                                           /____/                             /_/                  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/