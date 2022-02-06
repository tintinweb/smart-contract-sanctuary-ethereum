/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

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
 * @title Bloklistable Token
 * @dev Allows accounts to be Bloklisted by a "Bloklister" role
 */
contract Bloklistable is Ownable {
    address public Bloklister;
    mapping(address => bool) internal bloklisted;

    event Bloklisted(address indexed _account);
    event UnBloklisted(address indexed _account);
    event BloklisterChanged(address indexed newBloklister);

    /**
     * @dev Throws if called by any account other than the Bloklister
     */
    modifier onlyBloklister() {
        require(
            msg.sender == Bloklister,
            "Bloklistable: caller is not the Bloklister"
        );
        _;
    }

    /**
     * @dev Throws if argument account is Bloklisted
     * @param _account The address to check
     */
    modifier notBloklisted(address _account) {
        require(
            !bloklisted[_account],
            "Bloklistable: account is Bloklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is Bloklisted
     * @param _account The address to check
     */
    function isBloklisted(address _account) external view returns (bool) {
        return bloklisted[_account];
    }

    /**
     * @dev Adds account to Bloklist
     * @param _account The address to Bloklist
     */
    function Bloklist(address _account) external onlyBloklister {
        bloklisted[_account] = true;
        emit Bloklisted(_account);
    }

    /**
     * @dev Removes account from Bloklist
     * @param _account The address to remove from the Bloklist
     */
    function unBloklist(address _account) external onlyBloklister {
        bloklisted[_account] = false;
        emit UnBloklisted(_account);
    }

    function updateBloklister(address _newBloklister) external onlyOwner {
        require(
            _newBloklister != address(0),
            "Bloklistable: new Bloklister is the zero address"
        );
        Bloklister = _newBloklister;
        emit BloklisterChanged(Bloklister);
    }
}
contract Whitelisted is Context {
    struct WhitelistRound {
        uint256 duration;
        uint256 amountMax;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }

    WhitelistRound[] public _WhitelistRounds;

    uint256 public _Timestamp;
    address public _PairAddress;

    address public _whitelister;

    event WhitelisterTransferred(address indexed previousWhitelister, address indexed newWhitelister);

    constructor() {
        _whitelister = _msgSender();
    }

    modifier onlyWhitelister() {
        require(_whitelister == _msgSender(), "Caller is not the whitelister");
        _;
    }

    function renounceWhitelister() external onlyWhitelister {
        emit WhitelisterTransferred(_whitelister, address(0));
        _whitelister = address(0);
    }

    function transferWhitelister(address newWhitelister) external onlyWhitelister {
        _transferWhitelister(newWhitelister);
    }

    function _transferWhitelister(address newWhitelister) internal {
        require(newWhitelister != address(0), "New whitelister is the zero address");
        emit WhitelisterTransferred(_whitelister, newWhitelister);
        _whitelister = newWhitelister;
    }
    function createLGEWhitelist(
        address pairAddress,
        uint256[] calldata durations,
        uint256[] calldata amountsMax
    ) external onlyWhitelister() {
        require(durations.length == amountsMax.length, "Invalid whitelist(s)");

        _PairAddress = pairAddress;

        if (durations.length > 0) {
            delete _WhitelistRounds;

            for (uint256 i = 0; i < durations.length; i++) {
                WhitelistRound storage whitelistRound = _WhitelistRounds.push();
                whitelistRound.duration = durations[i];
                whitelistRound.amountMax = amountsMax[i];
            }
        }
    }

    function modifyLGEWhitelist(
        uint256 index,
        uint256 duration,
        uint256 amountMax,
        address[] calldata addresses,
        bool enabled
    ) external onlyWhitelister() {
        require(index < _WhitelistRounds.length, "Invalid index");
        require(amountMax > 0, "Invalid amountMax");

        if (duration != _WhitelistRounds[index].duration) _WhitelistRounds[index].duration = duration;

        if (amountMax != _WhitelistRounds[index].amountMax) _WhitelistRounds[index].amountMax = amountMax;

        for (uint256 i = 0; i < addresses.length; i++) {
            _WhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }
    function getLGEWhitelistRound()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        if (_Timestamp > 0) {
            uint256 wlCloseTimestampLast = _Timestamp;

            for (uint256 i = 0; i < _WhitelistRounds.length; i++) {
                WhitelistRound storage wlRound = _WhitelistRounds[i];

                wlCloseTimestampLast = wlCloseTimestampLast + wlRound.duration;
                if (block.timestamp <= wlCloseTimestampLast)
                    return (
                        i + 1,
                        wlRound.duration,
                        wlCloseTimestampLast,
                        wlRound.amountMax,
                        wlRound.addresses[_msgSender()],
                        wlRound.purchased[_msgSender()]
                    );
            }
        }

        return (0, 0, 0, 0, false, 0);
    }

   

    function _applyLGEWhitelist(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (_PairAddress == address(0) || _WhitelistRounds.length == 0) return;

        if (_Timestamp == 0 && sender != _PairAddress && recipient == _PairAddress && amount > 0)
            _Timestamp = block.timestamp;

        if (sender == _PairAddress && recipient != _PairAddress) {
            //buying

            (uint256 wlRoundNumber, , , , , ) = getLGEWhitelistRound();

            if (wlRoundNumber > 0) {
                WhitelistRound storage wlRound = _WhitelistRounds[wlRoundNumber - 1];

                require(wlRound.addresses[recipient], "LGE - Buyer is not whitelisted");

                uint256 amountRemaining = 0;

                if (wlRound.purchased[recipient] < wlRound.amountMax)
                    amountRemaining = wlRound.amountMax - wlRound.purchased[recipient];

                require(amount <= amountRemaining, "LGE - Amount exceeds whitelist maximum");
                wlRound.purchased[recipient] = wlRound.purchased[recipient] + amount;
            }
        }
    }
}

contract QMALL is  Ownable , IERC20 , Whitelisted {
 
    
    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
  
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 internal _totalSupply = 0;
    uint256 public constant INITIAL_SUPPLY = 1_00_000_000e18;
    
    constructor() {
        _name = " Qmall Token";
        _symbol = "QMALL";
        _decimals = 18;
        _mint (msg.sender, INITIAL_SUPPLY);

    }

     function mint(address _to, uint256 _amount) external onlyOwner{
        _mint(_to, _amount);
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
        public      
        
    {
        _burn(msg.sender, amount);
    }

  function _mint (address _to, uint256 _amount) internal
        returns (bool)
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_amount > 0, "ERC20: mint amount not greater than 0");
    

        _totalSupply = _totalSupply + _amount;
        _balances[_to] = _balances[_to] + _amount;
       
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function _burn(address from, uint value) internal {
        _balances[from] = _balances[from] - value;
        _totalSupply = _totalSupply - value;
        emit Transfer(from, address(0), value);
    }
    

   
    function transfer(address recipient, uint256 amount) public  override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
 
    function approve(address spender, uint256 amount) public 
        override  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public  virtual  override  returns (bool) {
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
        public
        
        returns (bool)
    {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        
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

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenContract);
        
       
        token.transfer(msg.sender, _amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}