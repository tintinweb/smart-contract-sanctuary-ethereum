/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

/*
;llllllllllll,     .':ldkOOOOkdl,.           .,coxkOOOkxo:.
.kMMMMMMMMMMMMx. .;d0NMMMMMMMMMMMW0l.      .:xKWMMMMMMMMMMMNk;
.xNXXNXNMMMMMM0cdKWMMMMWNNNNWMMMMMMW0x; .;xXWMMMMWNNNWMMMMMMMWx.
 ......lXMMMMMWWMMMN0dc,'..';l0WMMMMMMXxOWMMMNOdc,'..':xXMMMMMWx.
      ,KMMMMMMMWKo,          .dWMMMMMMMMMNkc'          :KMMMMMX;
      ,KMMMMMWO:.             '0MMMMMMMNx,              oWMMMMWl
      ,KMMMMMO'               .kMMMMMMWl                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
      ,KMMMMMO.               .xMMMMMMN:                :NMMMMMo
.'''''lXMMMMM0:''''.      .''';OMMMMMMWd''''.      .''''oNMMMMMk,'''''.
,KWNWWWWMMMMMMMWWNNWd.    'OWNWWWMMMMMMMWWWNWK,     oNWWNWMMMMMMWWNWWWX:
;XMMMMMMMMMMMMMMMMMMx.    '0MMMMMMMMMMMMMMMMMX;     oMMMMMMMMMMMMMMMMMN:
.;::::::::::::::::::'      ,:::::::::::::::::;.     .:::::::::::::::::;.
*/

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Who the fuck are you?");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract M is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) callCount;
    mapping (address => bool) private presalelock;
    uint256 private _totalSupply;
    uint256 private constant _totalTokens = 100000000 * 10**18;
    uint256 constant maxCall = 1;
    uint256 public locktime;
    uint256 public unlocktime;
    uint256 public LPLocktime;
    uint256 public exchangesLockTime;


    string private constant _name = "M";
    string private constant _symbol = "M";
    uint8 private constant _decimals = 18;

    modifier limit {
        require(callCount[msg.sender] < maxCall, "Baby can't hit me one more time");
        callCount[msg.sender]++;
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    constructor() {
        _mint(_msgSender(), _totalTokens);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function airdropAndLock(uint256 presaleAmount, address[] memory presalers, uint256[] memory airdropAmounts) external limit onlyOwner {
        require(presalers.length == airdropAmounts.length, "You idiot, double check your excel sheet");
        uint256 totalPresale;
        for (uint256 i; i < presalers.length; i++) {
            uint256 amount = airdropAmounts[i] * 1e18;
            address to = presalers[i];

            totalPresale += amount;
            _transfer(address (_msgSender()), to, amount);

            presalelock[presalers[i]] = true;
            locktime = block.timestamp;
            unlocktime = locktime + 17 days;
        }
        require(totalPresale == presaleAmount * 1e18, "It's just a copy and paste, how stupid can you be?");
    }

    function unlockPresalers(address [] memory _unlock) public onlyOwner {
        require(block.timestamp >= unlocktime, "The presale unlock isn't like you, it doesn't finish quick");

        for (uint i = 0; i < _unlock.length; i++) {
            presalelock[_unlock[i]] = false;
        }
    }

    function manualLiqLock(uint256 timelock) public onlyOwner {
        //Send LP tokens to contract first
        require(block.timestamp >= LPLocktime, "Wait for the previous LP lock to expire first you impatient slut");
        require(timelock <= 2592000, "Why do you want to lock it til we're all ded ser");
        
        LPLocktime = block.timestamp + timelock;
    }

    function exchangeTokensLock(uint256 exchLock) public onlyOwner{
        //Send exchange tokens to contract first
        require(block.timestamp >= exchLock, "Wait for the previous lock to end first bitch");
        require(exchLock <= 864000, "How are you going to send tokens to exchanges if you're going to lock it for eternity you cunt");

        exchangesLockTime = block.timestamp + exchLock;
    }

    function theTimeHasCome(address moonTime) public onlyOwner {
        IERC20 token = IERC20(moonTime);
        uint256 xch = token.balanceOf(address(this));

        require(block.timestamp >= exchangesLockTime, "It's moon time and you can't even get this right?");
        require(xch > 0, "WTF HAPPENED TO THE EXCHANGE TOKENS??");

        token.transfer(msg.sender, xch);
    }

    function thisBetterBeAnEmergency(address theAddress) public onlyOwner {
        IERC20 token = IERC20(theAddress);
        uint256 LP = token.balanceOf(address(this));

        require(block.timestamp >= LPLocktime, "Are you trying to rug u jeet?");
        require(LP > 0, "WTF HAPPENED TO THE LP??");

        token.transfer(msg.sender, LP);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!presalelock[sender] && !presalelock[recipient]);

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
}