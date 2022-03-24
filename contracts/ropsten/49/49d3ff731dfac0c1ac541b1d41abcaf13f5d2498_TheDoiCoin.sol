/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = msg.sender;//0x0d663C4A95d48fa35d2CAe762d1Bf629aB289eD4;//_msgSender();
        _owner =  msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract  TheDoiCoin is IERC20, Ownable, IERC20Metadata {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;



  address treasuryWallet = 0x0d663C4A95d48fa35d2CAe762d1Bf629aB289eD4;
  address founder1 = 0x9fc9C2b3F036686a289631BffD80FC925A46bb5B;
  address founder2 = 0xF1a8813249532f6A506dC7CB6f82943250AfADF3;
  address founder3 = 0xF9168482564e30628d49cE9B09A8d2019B6db354;

  bool public started = false;
  uint256 public maxUnlockIterationCount = 240;    //  cycle limit for unlockExpired()
    

  mapping (address => uint256) public lockedBalances;   //  (address => amount).
  mapping (address => uint256[]) public releaseTimestamps; //  release timestamps for locked transfers, (address => timestamp[]).
  mapping (address => mapping(uint256 => uint256)) public lockedTokensForReleaseTime; //  address => (releaseTimestamp => releaseAmount)


    
    constructor() {
        _name = "  The DOI Coin  ";
        _symbol = "DOIC";
        _supply(treasuryWallet, 19340000000 *10 **9);
        _supply(founder1, 220000000 * 10 ** 9);
        _supply(founder2, 220000000 * 10 ** 9);
        _supply(founder3, 220000000 * 10 ** 9);

        //vesting in tokens in wallets
        lockedBalances[treasuryWallet] = lockedBalances[treasuryWallet].add(17340000000 * 10 ** 9);    
        lockedBalances[founder1] = lockedBalances[founder1].add(220000000 * 10 ** 9);
        lockedBalances[founder2] = lockedBalances[founder2].add(220000000 * 10 ** 9);
        lockedBalances[founder3] = lockedBalances[founder3].add(220000000 * 10 ** 9);
        
    }

    function startFirst() public onlyOwner{
        require(started == false,"contract already started!");
        uint256 time = block.timestamp + 30 days;
        for(uint256 i=0;i<240;i ++){
            releaseTimestamps[treasuryWallet].push(time);
            lockedTokensForReleaseTime[treasuryWallet][time] = 72250000000000000;               
            time += 30 days;
        }
    }

    function startSecond() public onlyOwner{
        require(started == false,"contract already started!");
        started = true;  
        uint256 time = block.timestamp + 30 days;
            for(uint256 i=0;i<110;i ++){      
                    releaseTimestamps[founder1].push(time);
                    lockedTokensForReleaseTime[founder1][time] = 2000000000000000;

                    releaseTimestamps[founder2].push(time);
                    lockedTokensForReleaseTime[founder2][time] = 2000000000000000;     

                    releaseTimestamps[founder3].push(time);
                    lockedTokensForReleaseTime[founder3][time] = 2000000000000000;

                time += 30 days;
        }   
    }


    function getReleaseTimestamps(address _address) public view returns(uint256[] memory) {
        return releaseTimestamps[_address];
    }
  
    function getMyReleaseTimestamps() public view returns(uint256[] memory) {
        return releaseTimestamps[msg.sender];
    }
  
  
    function updateMaxUnlockIterationCount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Wrong amount");
        maxUnlockIterationCount = _amount;
    }
  
  
    function lockedTransferAmount(address _address) public view returns(uint256) {
      return releaseTimestamps[_address].length;
    }
  
    function myLockedTransferAmount() public view returns(uint256) {
      return releaseTimestamps[msg.sender].length;
    }

    function unlockExpired(uint256 _amount) public {
        require(_amount <= maxUnlockIterationCount, "Wrong amount");
        uint256 length = releaseTimestamps[msg.sender].length;
        for(uint256 i = 0; i < length; i ++) {
          if(i > maxUnlockIterationCount) {
              return;
            }
        if(releaseTimestamps[msg.sender][i] <= block.timestamp) {
          uint256 tokens = lockedTokensForReleaseTime[msg.sender][releaseTimestamps[msg.sender][i]];
          lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(tokens);
          delete lockedTokensForReleaseTime[msg.sender][releaseTimestamps[msg.sender][i]];
    
          length = length.sub(1);
          if(length > 0) {
           releaseTimestamps[msg.sender][i] = releaseTimestamps[msg.sender][length];
           delete releaseTimestamps[msg.sender][length];
           releaseTimestamps[msg.sender].pop();
           i --;
            }
            else {
           delete releaseTimestamps[msg.sender];
                }
            }
        }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


/**
    @dev Disable transfer functional.
   */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(started == true,"contract not started!");
        unlockExpired(240);
        require(balanceOf(msg.sender).sub(lockedBalances[msg.sender]) >= amount, "Not enough tokens.");
        _transfer(_msgSender(), recipient, amount);
        return true;
  }

  /**
    @dev Disable transferFrom functional.
   */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(started == true,"contract not started!");
        unlockExpired(240);
        require(balanceOf(sender).sub(lockedBalances[sender]) >= amount, "Not enough tokens.");
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    
  }
    
      
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    
    
    function _supply(address account, uint256 amount) internal virtual  {
        require(account != address(0) );

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
  

   
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}