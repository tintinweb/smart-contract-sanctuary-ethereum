// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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





interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Blocklistable Token
 * @dev Allows accounts to be Blocklisted by a "Blocklister" role
 */
contract Blocklistable is Ownable {
    address public Blocklister;
    mapping(address => bool) private blocklisted;

    event Blocklisted(address indexed _account);
    event UnBlocklisted(address indexed _account);
    event BlocklisterChanged(address indexed newBlocklister);

    /**
     * @dev Throws if called by any account other than the Blocklister
     */
    modifier onlyBlocklister() {
        require(
            msg.sender == Blocklister,
            "Blocklistable: caller is not the Blocklister"
        );
        _;
    }

    /**
     * @dev Throws if argument account is Blocklisted
     * @param _account The address to check
     */
    modifier notBlocklisted(address _account) {
        require(
            !blocklisted[_account],
            "Blocklistable: account is Blocklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is Blocklisted
     * @param _account The address to check
     */
    function isBlocklisted(address _account) external view returns (bool) {
        return blocklisted[_account];
    }

    /**
     * @dev Adds account to Blocklist
     * @param _account The address to Blocklist
     */
    function Blocklist(address _account) external onlyBlocklister {
        require(!blocklisted[_account] ,"Already BlockListed");
        blocklisted[_account] = true;
        emit Blocklisted(_account);
    }

    /**
     * @dev Removes account from Blocklist
     * @param _account The address to remove from the Blocklist
     */
    function unBlocklist(address _account) external onlyBlocklister {
        blocklisted[_account] = false;
        emit UnBlocklisted(_account);
    }

    function updateBlocklister(address _newBlocklister) external onlyOwner {
        require(
            _newBlocklister != address(0),
            "Blocklistable: new Blocklister is the zero address"
        );
        Blocklister = _newBlocklister;
        emit BlocklisterChanged(Blocklister);
    }
}

contract QMALL is  IERC20 , Blocklistable {
 
    
    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
  
    uint8 private immutable _decimals;
    string private _symbol;
    string private _name;
    uint256 private _totalSupply;
    uint256 public constant INITIAL_SUPPLY = 100_000_000e18;
    
    constructor() {
        _name = "Qmall Token";
        _symbol = "QMALL";
        _decimals = 18;
        _mint (_msgSender(), INITIAL_SUPPLY);

    }
    
    function decimals() external view  returns (uint8) {
        return _decimals;
    }
    
   
    function symbol() external view  returns (string memory) {
        return _symbol;
    }
   
    function name() external view  returns (string memory) {
        return _name;
    }
    
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
   
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    
    function burn(uint256 amount) 
        external notBlocklisted(_msgSender())       
        
    {
        _burn(_msgSender(), amount);
    }


  function _mint (address _to, uint256 _amount) internal
        
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_amount > 0, "ERC20: mint amount not greater than 0");
    

        _totalSupply = _totalSupply + _amount;
        _balances[_to] = _balances[_to] + _amount;
       
        emit Transfer(address(0), _to, _amount);
        
    }

    function _burn(address from, uint value) internal {
        _balances[from] = _balances[from] - value;
        _totalSupply = _totalSupply - value;
        emit Transfer(from, address(0), value);
    }
    

   
    function transfer(address recipient, uint256 amount) external notBlocklisted(_msgSender())
        notBlocklisted(recipient) override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
 
    function approve(address spender, uint256 amount) external  notBlocklisted(_msgSender())
        notBlocklisted(spender) override  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public notBlocklisted(_msgSender()) notBlocklisted(sender) notBlocklisted(recipient) virtual  override  returns (bool) {
       uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);
        return true;
    }
    
   
    function increaseAllowance(address spender, uint256 addedValue)
        external
        notBlocklisted(_msgSender()) notBlocklisted(spender) 
        returns (bool)
    {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        notBlocklisted(_msgSender()) notBlocklisted(spender) 
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

       
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenContract);
        
       
        token.transfer(_msgSender(), _amount);
    }
  
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}