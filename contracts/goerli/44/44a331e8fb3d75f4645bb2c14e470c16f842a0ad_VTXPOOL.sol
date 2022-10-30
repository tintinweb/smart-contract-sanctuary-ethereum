/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// File: contracts\libraries\SafeMath.sol

pragma solidity >=0.5.0 <0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/utils/ERC20.sol

pragma solidity >=0.5.0;

contract ERC20 is IERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces; //Check functionality of nonces

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {        
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }
    //Change back to private visibility after testing
    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: contracts\utils\Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts/interfaces/IVTXERC20.sol

pragma solidity ^0.5.0;

interface IVTXERC20 {

    event PairAdded(address indexed account);
    event VTXMinted(address indexed to, uint value);
    event VTXBurned(address indexed from, uint value);

    function isFactory (address[] calldata input) external view returns (bool);

    function isPair (address[] calldata input) external view returns (bool);

    function addPair (address account) external returns (bool);

    function VTXMint(address to, uint value) external returns (bool);
    
    function VTXBurn(address from, uint value) external returns (bool);
}

// File: contracts/utils/VTXERC20.sol

pragma solidity >=0.5.0;

contract VTXERC20 is ERC20, IVTXERC20 {
    using SafeMath for uint;
    using Roles for Roles.Role;

    address[] public factory = [0x2b1d23EecDC3Db27C2f79aBAd852aC741ffB5326];
    address[] public pair;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _factory.add(factory[0]);
    }

    Roles.Role private _factory;
    Roles.Role private _pair;

    event PairAdded(address indexed account);
    event VTXMinted(address indexed to, uint value);
    event VTXBurned(address indexed from, uint value);

    modifier onlyFactory() {
        require(_factory.has(msg.sender), "ACCESS RESTRICTED TO FACTORY");
        _;
    }

    modifier onlyPair() {
        require(_pair.has(msg.sender), "ACCESS RESTRICTED TO PAIR");
        _;
    }

    //Use an allowance that is updated to be equal to the required amount for each transaction and requires transaction success otherwise the allowance is revoked

    function isFactory (address[] calldata input) external view returns (bool) {
        for (uint256 i; i < input.length;) {
                return _factory.has(input[i]);
            }
    }

    function isPair (address[] calldata input) external view returns (bool) {
        for (uint256 i; i < input.length;) {
                return _pair.has(input[i]);
            }
    }

    function addPair (address account) external onlyFactory returns (bool) {
            _pair.add(account);
            pair.push(account);
            emit PairAdded(account);
            return true;
    }

    function _VTXMint(address to, uint value) internal {
        totalSupply = totalSupply.add(value.div(2));
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _VTXBurn(address from, uint value) internal {
        totalSupply = totalSupply.sub(value.div(2));
        balanceOf[from] = balanceOf[from].sub(value);
        emit Transfer (from, address(0), value);
    }

    function VTXMint(address to, uint value) external onlyPair returns (bool) {
        //Only the pair address can mint tokens using this function
        _VTXMint(to, value);
        return true;
    }

    function VTXBurn(address from, uint value) external onlyPair returns (bool) {
        //Only the pair address can burn tokens using this function
        _VTXBurn(from, value);
        return true;
    }
}

// File: contracts/utils/VTXPOOL.sol

pragma solidity ^0.5.0;

contract VTXPOOL is VTXERC20 {

    constructor(uint _totalSupply) 
        VTXERC20("VTXPOOL", "VTXPOOL", 18) public {
        _mint(msg.sender, _totalSupply);
    }

    function receive() external payable {}
    function fallback() external payable {}

    function mint(address to, uint value) public {
        _mint(to, value);
    }

    function burn(address from, uint value) public {
        _burn(from, value);
    }
}