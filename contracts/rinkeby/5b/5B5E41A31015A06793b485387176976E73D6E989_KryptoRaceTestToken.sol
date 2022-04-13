/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            uint256 c = a + b; 
            if (c < a) return (false, 0);
            return (true, c); 
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (a == 0) return (true, 0); 
            uint256 c = a * b;
            if (c / a != b) return (false, 0); 
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 
            return (true, a % b); 
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 
            return a / b; 
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) { return _owner; }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract KryptoRaceTestToken is IBEP20, Context, Ownable {
    using SafeMath for uint256;

    string private constant _name         = "KryptoRace Test";
    string private constant _symbol       = "KRC";
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 100 * 10**6 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(uint256 => address[]) gameRecords;

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }

    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

    function getOwner() external view override returns (address) { return owner(); }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function gamePlay(uint256 _sessionId) public {
        address  _player = msg.sender;
        // require(msg.value >= 0.0001 * 10**18, "you can't have enough balance");
        _transfer(_player, address(this), 0.0001 * 10**9);

        require(gameRecords[_sessionId].length < 2 , "only two player can play with this _sessionId");

        if(gameRecords[_sessionId].length >= 1){
                    require(gameRecords[_sessionId][0] != _player , "Player already added");
                }       

        addPlayer(_sessionId,_player);

    }
    function addPlayer(uint256 id, address addressToAdd) internal {
        gameRecords[id].push(addressToAdd);
    }

    function checkPaid(address player, uint256 id) public view returns(bool) {
        bool result = false;
        for (uint i = 0; i<gameRecords[id].length; i++){
            if(gameRecords[id][i] == player){
               result = true;
                }            
            }
            return result;
    }

     function claimReward(uint256 _sessionId) public {
        address winnerAddress = msg.sender;
        for (uint i = 0; i<=gameRecords[_sessionId].length; i++){
            if(gameRecords[_sessionId][i] == winnerAddress){
               
                if(gameRecords[_sessionId].length > 1){
                _transfer(address(this), winnerAddress, 0.0002 * 10**9);

                }else{
                _transfer(address(this), winnerAddress, 0.0001 * 10**9);

                }
                delete gameRecords[_sessionId];
            }
        }
    }
}