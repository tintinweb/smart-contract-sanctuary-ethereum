/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

contract Context {
    
    constructor () internal {}
    function _msgSender() internal view returns (address) {return msg.sender;}
    function _msgData() internal view returns (bytes memory) {this;return msg.data;}
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
        
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;} uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c;
        
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b; return c;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage); return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool)
        {uint256 size;assembly {size := extcodesize(account)}return size > 0;}
}

contract Ownable is Context {
    
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {return _owner;}
    function isOwner() public view returns (bool) {return _msgSender() == _owner;}
    function transferOwnership(address newOwner) public onlyOwner {_transferOwnership(newOwner);}

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract ERC20 is Context, Ownable, IERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private allowances;

    uint256 private _totalSupply;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is ERC20 {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    
    }

contract ERC20Capped is ERC20 {
    
    using SafeMath for uint256;
    uint256 public MaxSupply;

    constructor (uint256) internal {
        require(MaxSupply <= 500000000e18, "cannot be exceeded");
        MaxSupply = MaxSupply;

    }
}

contract PoSTokenStandard {
    
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    
    function mint() public returns (bool);
    function coinAge(address staker) public view returns (uint256);
    function annualInterest() public view returns (uint256);
    
    event Mint(address indexed _address, uint _reward);
    
}

contract BitCore is Context, Ownable, ERC20, ERC20Detailed, PoSTokenStandard {

    using SafeMath for uint256;
    using Address for address;
    
    uint256 public totalSupply;
    uint256 public constant MaxSupply = 500000000e18;
    uint256 public constant presaleSupply = 330000e18;
    

//----------------------------------------------------------------------------------------------------
//Constructor
//----------------------------------------------------------------------------------------------------
    
    constructor() public ERC20Detailed ("BitCore", "BTCR", 18) {
        
        balances[address(this)] = 330000e18;
        emit Transfer(address(0), address(this), 330000e18);
        
        mint(msg.sender, 670000e18);
        
        chainStartTime = now;
        stakeStartTime = now + 5 days;
        chainStartBlockNumber = block.number;
        
    }
    
//----------------------------------------------------------------------------------------------------
//Presale
//----------------------------------------------------------------------------------------------------
    
    /**
    * @param _rate Number of token units a buyer gets per Eth
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
   
    function Presale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0xF1481DFC0937eEC053809Ad8007D695F917851b6));
        require(_token != address(this));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }
  
    ERC20 public token;
    address public wallet = 0xF1481DFC0937eEC053809Ad8007D695F917851b6;
    uint256 public rate = 100; // 1 ETH = 100 BTCR
    
    uint public constant EthCapMin = 0.005 ether;
    uint public constant EthCapMax = 50 ether;
    uint public startDate = now;
    bool public closed;

    event Purchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event ChangeRate(uint256 value);
    
    function TokenWithdraw(uint value) public onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[msg.sender] += value;
        emit Transfer(address(this), msg.sender, value);

    }
  
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        emit ChangeRate(rate);

    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
        
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        uint256 amount = msg.value * rate;
        uint256 tokens = amount;
        forwardFunds();
        
        if (msg.value == 0) {revert();}
        if (tokens == 0) {revert();}
        if (tokens > presaleSupply) {revert();} // too much ETH sent
        
        require(now >= startDate);
        require(msg.value >= EthCapMin, "Sender cannot sent less than minimum");
        require(msg.value <= EthCapMax, "Sender cannot sent exceed than maximum");
        require(tokens <= presaleSupply, "Presale supply cannot be exceeded");
        require(tokens <= balanceOf(address(this)), "Not have enough available tokens");
        require(!closed);
        
        processPurchase(beneficiary, tokens);
        emit Purchase(msg.sender, beneficiary, tokens);
        
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply + balances[msg.sender];
    }

    function deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token.transfer(beneficiary, tokenAmount);
    }

    function processPurchase(address beneficiary, uint256 tokenAmount) internal {
        deliverTokens(beneficiary, tokenAmount);
     
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
        
    }
    
//----------------------------------------------------------------------------------------------------
//PoS Implementation
//----------------------------------------------------------------------------------------------------
    
    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3D
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90D
    uint public MintRate = 10e17; // default 10% annual interest
        
    event ChangeMintRate(uint value);
        
    struct transferInStruct{uint128 amount; uint64 time;
        
    }
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) private _allowed;
    mapping(address => transferInStruct[]) transferIns;
    modifier ProofOfStake() {require(totalSupply <= MaxSupply);
        _;
        
    }
    
    function mint() public ProofOfStake returns (bool) {
        require(totalSupply <= MaxSupply, "cannot mint after reached MaxSupply");
        uint reward = getProofOfStakeReward(msg.sender);
        
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        if(reward <= 0) return false;
        
        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        emit Mint(msg.sender, reward);
        return true;
        
    }
    
    function changeMintRate(uint _MintRate) public onlyOwner {
        MintRate = _MintRate;
        emit ChangeMintRate(MintRate);
        
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
        
    }

    function coinAge(address staker) public view returns (uint256) {
        return getCoinAge(staker, now);
        
    }

    function annualInterest() public view returns(uint interest) {
        uint _now = now;
        interest = MintRate;
        
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (770 * MintRate).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            interest = (435 * MintRate).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        uint interest = MintRate;
        uint offset = 10e18;
        if(_coinAge <= 0) return 0;
        
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        
        if((_now.sub(stakeStartTime)).div(365 days) == 0){
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * MintRate).div(100);
            
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (435 * MintRate).div(100);
        }
        
        return (_coinAge * interest).div(365 * offset);
        
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }
}