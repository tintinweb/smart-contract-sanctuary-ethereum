// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./ERC20.sol";

contract USDC is ERC20 {
    constructor(uint8 tokenDecimals) ERC20("USDC token", "USDC", tokenDecimals) {}

    /**
    deposit _value of balance to _to
     */
    function mint(uint256 value) public returns (bool success) {
        require(
            value + _totalSupply <= type(uint256).max,
            "Value to mint not valid"
        );

        _totalSupply += value;
        _balances[msg.sender] += value;
        emit Transfer(address(0), msg.sender, value);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./IERC20.sol";

/**
Basic ERC20 implementation
 */
contract ERC20 is IERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _approvedList;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    /**
    name of the token, ex: Dai
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
    symbol of the token, ex: DAI
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
    will used to round the balance of address
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
    total supply of token, will reduce when transfer or burn
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
    balance of special address
     */
    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    /**
    transfer _value of token from current sender to _to
     */
    function transfer(address to, uint256 value)
        public
        override
        returns (bool success)
    {
        return _transfer(msg.sender, to, value);
    }

    /**
    transfer _value of token from _from to _to and the sender will have approved by _from to using _from balance before
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool success) {
        require(_approvedList[from][msg.sender] >= value, "Allowance limit");

        bool result = _transfer(from, to, value);
        _approvedList[from][msg.sender] -= value;
        return result;
    }

    /**
    sender will give acception to spender to using _value of balance of sender
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool success)
    {
        _approvedList[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    return remanning of approved balance which owner approved for spender used before
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _approvedList[owner][spender];
    }

    /**
    Transfer _value of balance from _from to _to and emit the Transfer event
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool success) {
        require(_balances[from] >= value, "Insufficient balance");

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}