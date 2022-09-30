// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract VictusCronusPotion {
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    uint public totalSupply;
    // Guarded launch
    bool public transferable;
    // operator assign-accept model
    address public operator;
    address public pendingOperator;
    address public ERC20Minter;

    mapping(address => bool) public recipientWhitelist;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    // delegation
    mapping(address => uint) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        operator = msg.sender;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function setPendingOperator(address newOperator_) public onlyOperator {
        pendingOperator = newOperator_;
    }

    function claimOperator() public {
        require(msg.sender == pendingOperator, "ONLY PENDING OPERATOR");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit ChangeOperator(operator);
    }

    function changeMinter(address minter_) public onlyOperator {
        ERC20Minter = minter_;
        emit ChangeMinter(minter_);
    }

    function mint(address to, uint amount) public {
        require(msg.sender == ERC20Minter, "ONLY MINTER");
        _mint(to, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(transferable || recipientWhitelist[to], "Token is not transferrable and the recipient is not whitelisted!");
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
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
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
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

    function whitelist(address _recipient, bool _isWhitelisted) public onlyOperator {
        recipientWhitelist[_recipient] = _isWhitelisted;
        emit WhiteList(_recipient, _isWhitelisted);
    }

    function openTheGates() public onlyOperator {
        transferable = true;
    }

    // operator can seize tokens during the guarded launch only while tokens are non-transferable
    function seize(address _user, uint _amount) public onlyOperator {
        require(!transferable, "Cannot seize while token is transferable");
        _transfer(_user, address(0), _amount);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event ChangeMinter(address indexed minter);
    event ChangeOperator(address indexed newOperator);
    event WhiteList(address indexed _recipient, bool _isWhitelisted);
}