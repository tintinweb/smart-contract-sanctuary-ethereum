// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20Detailed.sol";

contract WBT is ERC20Detailed {
    constructor() ERC20Detailed("WBT", "WBT", 8, 300_000_000_00000000) {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20.sol";

contract ERC20Detailed is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply
    )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./BlackList.sol";

contract ERC20 is IERC20, BlackList, Pausable {
    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 internal _totalSupply;

    function totalSupply() external view override virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) external view override returns (uint256) {
        return _balances[user];
    }

    function allowance(address user, address spender) external view returns (uint256) {
        return _allowed[user][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }
    
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= _allowed[from][msg.sender], 'Not allowed to spend');
        _transfer(from, to, value);
        _allowed[from][msg.sender] -= value;

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function _transfer(address from, address to, uint256 value) internal whenNotPaused {
        require(!isBlacklisted(from), 'Sender address in blacklist');
        require(!isBlacklisted(to), 'Receiver address in blacklist');
        require(to != address(0), 'Zero address can not be receiver');

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    function burn(uint256 amount) external onlyOwner() virtual {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }

    function destroyBlackFunds (address _blackListedUser) external onlyOwner  {
        require(isBlacklisted(_blackListedUser), 'Address is not in blacklist');
        uint dirtyFunds = _balances[_blackListedUser];
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Ownable.sol";

contract BlackList is Ownable {

    mapping(address => bool) _blacklist;

    function isBlacklisted(address _maker) public view returns (bool) {
        return _blacklist[_maker];
    }

    function blacklistAccount(address account, bool sign) external onlyOwner {
        _blacklist[account] = sign;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Ownable.sol";

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), 'Available only for owner');
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function isOwner(address userAddress) public view returns (bool) {
        return userAddress == _owner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256) ;

    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender,uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender,uint256 addedValue) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event DestroyedBlackFunds(
        address indexed blackListedUser,
        uint balance
    );
}