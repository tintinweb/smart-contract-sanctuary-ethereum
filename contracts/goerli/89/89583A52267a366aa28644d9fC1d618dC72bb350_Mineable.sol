/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-03
*/

// SPDX-License-Identifier: MIT


/*

      $$\      $$\ $$\                               $$\       $$\           
      $$$\    $$$ |\__|                              $$ |      $$ |          
      $$$$\  $$$$ |$$\ $$$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\  $$ | $$$$$$\  
      $$\$$\$$ $$ |$$ |$$  __$$\ $$  __$$\  \____$$\ $$  __$$\ $$ |$$  __$$\ 
      $$ \$$$  $$ |$$ |$$ |  $$ |$$$$$$$$ | $$$$$$$ |$$ |  $$ |$$ |$$$$$$$$ |
      $$ |\$  /$$ |$$ |$$ |  $$ |$$   ____|$$  __$$ |$$ |  $$ |$$ |$$   ____|
      $$ | \_/ $$ |$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$ |$$$$$$$  |$$ |\$$$$$$$\ 
      \__|     \__|\__|\__|  \__| \_______| \_______|\_______/ \__| \_______|
                                                                             
                                                                             
                                                                            
*/

pragma solidity ^0.8.0;

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


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IAccessControl {

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
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

contract Mineable is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name = "Mineable";
    string private _symbol = "$MNB";
    uint8 private _decimals = 18;

    uint public Mined;
    uint public miningStartAt;

    uint private frequency = 10 minutes;
    uint private fd = 52560;
    uint private sr = 10000 * 10 ** _decimals; 
    uint private ddr = 210082;  
    uint private elreward = 10 * 10 ** _decimals;
    uint private deflationRate = 75;  
    uint private denominator = 100;

    uint public startSupply = 250_000_000 * 10 ** _decimals;
    uint public maxMineableSupply = 1_250_000_000 * 10 ** _decimals;

    uint private _totalSupply;

    address public minterController = address(0x0E0754c25261BB320Dd27835b703b73ED2a53c59);

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(){

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minterController);

        _totalSupply = startSupply;
        _balances[msg.sender] = _totalSupply; //starting token
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

     function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
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
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;        
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalCirculationSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD] - _balances[ZERO];
    }

    // ------------    Deflation -------------------

    function startMining() external onlyRole(MINTER_ROLE) {
        require(miningStartAt == 0,"Error: Already Started!");
        miningStartAt = block.timestamp;
    }

    function setManualTime(uint _time) external onlyRole(MINTER_ROLE) {
        miningStartAt = _time;
    }

    function triggerMint() external onlyRole(MINTER_ROLE) {
        require(minterController != address(0),"Please set Controller Address!!");
        uint mintable = getTriggerInfo();
        if(mintable == 0) {
            revert("Error: Mintable not available!");
        }
        Mined += mintable;
        _totalSupply += mintable;
        _balances[minterController] += mintable;
        emit Transfer(address(0), minterController, mintable);
    }

    function getTriggerInfo() public view returns (uint mintable) {  
        uint getBlock = getBlocks();
        uint adder = fd;
        uint subber = 0;
        uint blockdelta = fd;
        uint rewarddelta = sr;
        uint lemda = 0;
        if(getBlock > fd) {
            lemda = fd * sr;
            for(uint i = 0; i < 25; i++) {
                uint tblock = blockdelta*deflationRate/denominator;
                uint tReward = rewarddelta*deflationRate/denominator;
                adder = adder + tblock;
                subber = subber + blockdelta;
                // Eve = i + 1; 
                if(getBlock > adder) {
                    lemda += tblock*tReward;
                    blockdelta = tblock;
                    rewarddelta = tReward;
                }
                else {
                    uint wr = getBlock - subber;
                    lemda += wr * tReward;
                    break;
                }
            }
        }
        else {
            lemda = getBlock * sr;
        }

        if(getBlock > ddr) {
            uint elst = getBlock - ddr;
            uint tobe = elst * elreward;
            lemda += tobe;
        }

       return lemda > maxMineableSupply ? maxMineableSupply - Mined : lemda - Mined;  //limit max supply

    }

    function elapsedTime() public view returns (uint) {
        return miningStartAt > 0 ? block.timestamp - miningStartAt : 0;
    }

    function getBlocks() public view returns (uint) {
        uint getSec = elapsedTime();
        uint getBlock = getSec / frequency;
        return getBlock;
    }

    function getTime() public view returns (uint) {
        return block.timestamp;
    }

    function setController(address _newAdr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minterController = _newAdr;
    }

    function rescueFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function rescueTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender,balance);
    }

    receive() payable external {}

}