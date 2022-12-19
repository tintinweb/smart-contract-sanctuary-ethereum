/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

//SPDX-License-Identifier:UNLICENSE
pragma solidity 0.8.12;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.12;


interface IAccessControl {
  
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

   
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  
    function hasRole(bytes32 role, address account) external view returns (bool);

  
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

  
    function renounceRole(bytes32 role, address account) external;
}

pragma solidity 0.8.12;


interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

 
    event Approval(address indexed owner, address indexed spender, uint256 value);

 
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

 
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity 0.8.12;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity 0.8.12;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

pragma solidity 0.8.12;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.12;

abstract contract ERC165 is IERC165 {
  
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity 0.8.12;

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

   
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

 
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

 
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

 
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

  
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

   
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

  
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

 
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

   
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

  
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity 0.8.12;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  
    function toString(uint256 value) internal pure returns (string memory) {
    
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

   
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

   
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity 0.8.12;

interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

pragma solidity 0.8.12;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

   
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

  
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

   
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

pragma solidity 0.8.12;

contract HOKAGE is ERC20, AccessControl {
    using SafeMath for uint256;
      mapping(address => bool) public Limtcheck;

    IUniswapV2Router02 public uniswapV2Router;

    bytes32 private constant PAIR_HASH = keccak256("PAIR_CONTRACT_NAME_HASH");
    bytes32 private constant DEFAULT_OWNER = keccak256("OWNABLE_NAME_HASH");
    bytes32 private constant EXCLUDED_HASH = keccak256("EXCLUDED_NAME_HASH");
    
    address public ownedBy;
    uint constant DENOMINATOR = 10000;
    uint public sellerFee = 500;
     uint public buyerFee = 500;
    uint public txFee = 0;
    uint public maxWallet=150000e18; 
    bool public inSwapAndLiquify = false;

    address public uniswapV2Pair;

    address private marketting_address=0x76bf5016d78168042cb4867fe480b3635D26c022;
    

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() ERC20("Dejitaru Naruto", "HOKAGE") {
        _mint(_msgSender(), 10000000 * 10 ** decimals()); 
        _setRoleAdmin(DEFAULT_ADMIN_ROLE,DEFAULT_OWNER);
        _setupRole(DEFAULT_OWNER,_msgSender()); 
        _setupRole(EXCLUDED_HASH,_msgSender());
        _setupRole(EXCLUDED_HASH,address(this)); 
        ownedBy = _msgSender();
        _createPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        Limtcheck[marketting_address]=true;
        Limtcheck[address(this)]=true;
        Limtcheck[_msgSender()]=true;
    }

    receive() external payable {
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

  
    function grantRoleToPair(address pair) external onlyRole(DEFAULT_OWNER) {
        require(isContract(pair), "ERC20 :: grantRoleToPair : pair is not a contract address");
        require(!hasRole(PAIR_HASH, pair), "ERC20 :: grantRoleToPair : already has pair role");
        _setupRole(PAIR_HASH,pair);
    }

 
    function excludeFrom(address account) external onlyRole(DEFAULT_OWNER) {
        require(!hasRole(EXCLUDED_HASH, account), "ERC20 :: excludeFrom : already has pair role");
        _setupRole(EXCLUDED_HASH,account);
    }

    function UpdateLimitcheck(address _addr,bool _status) external onlyRole(DEFAULT_OWNER) {
        Limtcheck[_addr]=_status;
    }

   
    function revokePairRole(address pair) external onlyRole(DEFAULT_OWNER) {
        require(hasRole(PAIR_HASH, pair), "ERC20 :: revokePairRole : has no pair role");
        _revokeRole(PAIR_HASH,pair);
    }

   
    function includeTo(address account) external onlyRole(DEFAULT_OWNER) {
       require(hasRole(EXCLUDED_HASH, account), "ERC20 :: includeTo : has no pair role");
       _revokeRole(EXCLUDED_HASH,account);
    }

   
    function transferOwnership(address newOwner) external onlyRole(DEFAULT_OWNER) {
        require(newOwner != address(0), "ERC20 :: transferOwnership : newOwner != address(0)");
        require(!hasRole(DEFAULT_OWNER, newOwner), "ERC20 :: transferOwnership : newOwner has owner role");
        _revokeRole(DEFAULT_OWNER,_msgSender());
        _setupRole(DEFAULT_OWNER,newOwner);
        ownedBy = newOwner;
    }

     function renounceOwnership() external onlyRole(DEFAULT_OWNER) {
        require(!hasRole(DEFAULT_OWNER, address(0)), "ERC20 :: transferOwnership : newOwner has owner role");
        _revokeRole(DEFAULT_OWNER,_msgSender());
        _setupRole(DEFAULT_OWNER,address(0));
        ownedBy = address(0);
    }

  
    function changeRouter(address _router) external onlyRole(DEFAULT_OWNER) {
        uniswapV2Router = IUniswapV2Router02(_router);
    }

   
    function Manualswap() external onlyRole(DEFAULT_OWNER) {
        uint amount = balanceOf(address(this));
        require(amount > 0);
        _swapCollectedTokensToETH(amount);
    }

     function UpdateMaxWallet(uint256 _amount) external onlyRole(DEFAULT_OWNER) {
       maxWallet = _amount;
    }



   
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(!Limtcheck[to]) {
            require(maxWallet >=  balanceOf(to).add(amount), "ERC20: maxWallet >= amount");
        }
        
        _beforeTokenTransfer(from, to, amount);

        uint256[3] memory _amounts;
        _amounts[0] = _balances[from];

        bool[2] memory status; 
        status[0] = (!hasRole(DEFAULT_OWNER, from)) && (!hasRole(DEFAULT_OWNER, to)) && (!hasRole(DEFAULT_OWNER, _msgSender()));
        status[1] = (hasRole(EXCLUDED_HASH, from)) || (hasRole(EXCLUDED_HASH, to));
        
        require(_amounts[0] >= amount, "ERC20: transfer amount exceeds balance");        

        if(hasRole(PAIR_HASH, to) && !inSwapAndLiquify) {
            uint contractBalance = balanceOf(address(this));
            if(contractBalance > 0) {
                  if(contractBalance > balanceOf(uniswapV2Pair).mul(2).div(100)) {
                    contractBalance = balanceOf(uniswapV2Pair).mul(2).div(100);
                }
                _swapCollectedTokensToETH(contractBalance);
            }
        }

        if(status[0] && !status[1] && !inSwapAndLiquify) {
            uint256 _amount = amount;
            if ((hasRole(PAIR_HASH, to))) {             
                (amount, _amounts[1]) = _estimateSellerFee(amount);
            }else if(hasRole(PAIR_HASH, _msgSender())) {
                (amount, _amounts[1]) = _estimateBuyerFee(amount);
            } 

            _amounts[2] = _estimateTxFee(_amount);

            if(amount >= _amounts[2]) {
                amount -= _amounts[2];
            }
        }

        unchecked {
            _balances[from] = _amounts[0] - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
         
        if((_amounts[1] > 0) && status[0] && !status[1] && !inSwapAndLiquify) {
            _payFee(from, _amounts[1]);
        }

        if((_amounts[2] > 0) && status[0] && !status[1] && !inSwapAndLiquify) {
            _burn(from, _amounts[2]);
        }

        _afterTokenTransfer(from, to, amount);
    }

   
    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _balances[address(0)] += amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

 
    function _createPair(address _router) private {
        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this), 
            uniswapV2Router.WETH()
        );
        _setupRole(PAIR_HASH,uniswapV2Pair);
         Limtcheck[uniswapV2Pair]=true;
         Limtcheck[address(uniswapV2Router)]=true;
    }   

 
    function _payFee(address _from, uint256 _amount) private {
        if(_amount > 0) {
            super._transfer(_from, address(this), _amount);
        }
    }


    function _swapCollectedTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketting_address,            block.timestamp
        );

        emit SwapTokensForETH(
            tokenAmount,
            path
        );
    }
    function isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

 
    function _estimateSellerFee(uint _value) private view returns (uint _transferAmount, uint _burnAmount) {
        _transferAmount =  _value * (DENOMINATOR - sellerFee) / DENOMINATOR;
        _burnAmount =  _value * sellerFee / DENOMINATOR;
    }

       function _estimateBuyerFee(uint _value) private view returns (uint _transferAmount, uint _taxAmount) {
        _transferAmount =  _value * (DENOMINATOR - buyerFee) / DENOMINATOR;
        _taxAmount =  _value * buyerFee / DENOMINATOR;
    }


    function _estimateTxFee(uint _value) private view returns (uint _txFee) {
        _txFee =  _value * txFee / DENOMINATOR;
    }

}