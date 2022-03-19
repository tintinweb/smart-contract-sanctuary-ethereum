/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
 
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SPORT is IERC20, Auth {
    using SafeMath for uint256;

    address public MATIC = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "SPROT";
    string constant _symbol = "SPORT";
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply = 500000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    address public distributor;

    uint256 public distributionFee = 1000;
    uint256 public feeDenominator = 10000;

    IDEXRouter public router;
    address public pair;
    ESkillzStraightBet public ESkillzBet;
    constructor (
        address _dexRouter
    ) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(MATIC, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        MATIC = router.WETH();
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(sender==address(pair)) {
            uint256 distributionAmount = amount.mul(distributionFee).div(feeDenominator);
            _balances[distributor] = _balances[distributor].add(distributionAmount);
            emit Transfer(address(0), distributor, distributionAmount);    
        }
        return _basicTransfer(sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setFees(uint256 _distributionFee, uint256 _feeDenominator) external authorized {
        distributionFee = _distributionFee;
        feeDenominator = _feeDenominator;
        require(distributionFee <= feeDenominator/4, "Fee cannot exceed 25%");
    }

    function setDistributorAddr(address _address) external authorized {
        distributor = _address;
    }

    function mintMore(uint256 amount) external authorized {
        require(amount>0, "Amount should be bigger than zero");
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function setEskillzBet(ESkillzStraightBet _ESkillzBet) external authorized{
        ESkillzBet = _ESkillzBet;
    }

    function approveAndCreateSPGame(address spender, uint256 amount) external {
        require(amount>0, "Amount should be bigger than zero");
        approve(spender, amount);
        ESkillzBet.CreateSPGame(msg.sender, amount);
    }

    function approveAndCreateMPGame(address spender, uint256 amount) external {
        require(amount>0, "Amount should be bigger than zero");
        approve(spender, amount);
        ESkillzBet.CreateMPGame(msg.sender, amount);
    }

    function approveAndJoinMPGame(address spender, uint256 amount,  uint256 gameID) external {
        require(amount>0, "Amount should be bigger than zero");
        approve(spender, amount);
        ESkillzBet.JoinMPGame(msg.sender, gameID, amount);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.0;

library SafeMath1 {
    
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

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
pragma solidity ^0.8.0;
contract ESkillzStraightBet is Ownable {
    using SafeMath1 for uint256;
    //using Counters for Counters.Counter;
    uint256 public gameIds;
    SPORT public sport;
    uint256[] public gamelist = [0,1,2,3,4,5,6,7, 8, 9,10];
    struct Bet {
        address player;
        uint256 amount;
    }
    mapping(uint256 => Bet[]) public gamebetting;
    uint256 public eskillz_fee;
    address public feeReceiver;
    event BetEvent(uint256 _game, uint256 _amount);
    constructor (SPORT _sport) { 
        sport = _sport;  
        eskillz_fee = 5; 
        feeReceiver = 0x099b7b28AC913efbb3236946769AC6D3819329ab;
        sport.approve(feeReceiver, 1000000000000000000);    
    }

    
    function  CreateSPGame(address _sender, uint256 amount) external {
      require(amount>0, "You can not bet 0");
      if(gameIds>100000000){
        gameIds = 0;
      }
      gameIds++;
      sport.transferFrom(_sender, address(this), amount);
      sport.mintMore(amount);
      delete(gamebetting[gameIds]);
      gamebetting[gameIds].push(Bet(_sender, amount));
      gamebetting[gameIds].push(Bet(feeReceiver, amount));
      emit BetEvent(gameIds, amount);
    }
    
    function SetSPGameResult(uint256 GameID, bool result) external {
        
        (uint256 amountToWinner,uint256 amountToESkillz) = getAmountsToDistribute(GameID);
        require(gamebetting[GameID][0].player == msg.sender, "Other Players can not access.");
        if(result) {
            sport.transfer(gamebetting[GameID][0].player, amountToWinner);
            sport.transfer(feeReceiver, amountToESkillz);
        } else {
            sport.transfer(feeReceiver, amountToWinner + amountToESkillz);
        }
        delete(gamebetting[GameID]);
    }

    function  CreateMPGame(address _sender, uint256 amount) external {
      require(amount>0, "You can not bet 0");
      if(gameIds>100000000){
        gameIds = 0;
      }
      gameIds++;
      sport.transferFrom(_sender, address(this), amount);
      delete(gamebetting[gameIds]);
      gamebetting[gameIds].push(Bet(_sender, amount));
      emit BetEvent(gameIds, amount);
    }

    function  CancelMPGame(uint256 gameID) external {
      require(gamebetting[gameID].length == 1, "Players can not cancel.");
      require(gamebetting[gameID][0].player == msg.sender, "create Player can cancel only");
          
      sport.transfer(msg.sender, gamebetting[gameID][0].amount);
      delete(gamebetting[gameID]); 

    }

    function  JoinMPGame(address _sender, uint256 gameID, uint256 amount) external {
      require(gamebetting[gameID].length == 1, "Players can not join.");
      require(gamebetting[gameID][0].player != _sender, "Same Players can not join.");
      require(amount== gamebetting[gameID][0].amount, "Your bet amount must equals create amount");
     
      sport.transferFrom(_sender, address(this), amount);
      gamebetting[gameID].push(Bet(_sender, amount));
      emit BetEvent(gameID, amount);
    }

    function SetMPGameResult(uint256 GameID, address winnerAddress) external {
        (uint256 amountToWinner,uint256 amountToESkillz) = getAmountsToDistribute(GameID);
        require(winnerAddress == gamebetting[GameID][0].player || winnerAddress == gamebetting[GameID][1].player, "Winning player must includes in this game");
        require(msg.sender == gamebetting[GameID][0].player || msg.sender == gamebetting[GameID][1].player, "msg sender must includes in this game");

        if(winnerAddress == gamebetting[GameID][0].player) {
            sport.transfer(gamebetting[GameID][0].player, amountToWinner);
           
        } else {
            sport.transfer(gamebetting[GameID][1].player, amountToWinner);
            
        }  
        sport.transfer(feeReceiver, amountToESkillz);    
        delete(gamebetting[GameID]);
    }

    function genRand(uint256 maxNum) private view returns (uint256) {
        require(maxNum>0, "maxNum should be bigger than zero");
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty))) % maxNum);
    }

    function getPlayerLength(uint256 game) external view returns (uint256) {
        return gamebetting[game].length;
    }

    function getAmountsToDistribute(uint256 game) private view returns (uint256, uint256) {
        uint256 amountToWinner = (gamebetting[game][0].amount+gamebetting[game][1].amount).mul(100-eskillz_fee).div(100);
        uint256 amountToESkillz = (gamebetting[game][0].amount+gamebetting[game][1].amount).mul(eskillz_fee).div(100);
        return(amountToWinner, amountToESkillz);
    }

    function setFeeReceiver(address _address) external onlyOwner {
        feeReceiver = _address;
    }

    function setFee(uint256 _fee) external onlyOwner {
        eskillz_fee = _fee;
    }

   function withdraw(uint256 _amount) external {
        uint256 balance = sport.balanceOf(address(this));
        require(balance >= _amount, "Balance must be bigger than amount");
        require(feeReceiver == msg.sender || owner() == msg.sender, "msg sender must be feeReceiver or contract owner");
        sport.transfer(feeReceiver, _amount);         
    }	

    function withdrawAll() external onlyOwner{
        uint256 balance = sport.balanceOf(address(this));
        require(balance > 0, "Balance must be bigger than zero");
        sport.transfer(feeReceiver, balance);         
    }
	
}