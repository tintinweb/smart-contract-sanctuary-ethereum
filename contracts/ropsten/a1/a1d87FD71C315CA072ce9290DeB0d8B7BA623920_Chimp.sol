// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "./IAuthority.sol";

contract AuthorityControlled {
    
    event AuthorityUpdated(address indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAuthority public authority;

    constructor(address _authority) {
        _setAuthority(_authority);
    }

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        (bool isManager, uint256 idx) = authority.checkIsManager(msg.sender);
        require(isManager, UNAUTHORIZED);
        _;
    }

    function setAuthority(address _newAuthority) external onlyManager {
        _setAuthority(_newAuthority);
    }

    function _setAuthority(address _newAuthority) private {
        authority = IAuthority(_newAuthority);
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

interface IAuthority {
    /* ========== EVENTS ========== */
    event OwnerPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event OwnerPulled(address indexed from, address indexed to);
    event AddManager(address[] addrs);
    event DeleteManager(address[] addrs);

    /* ========== VIEW ========== */
    function owner() external view returns (address);

    function managers() external view returns (address[] memory);

    function addManager(address[] memory addrs) external;

    function deleteManager(address[] memory addrs) external;

    function checkIsManager(address addr) external view returns (bool, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./IERCExtend.sol";
import "../AuthorityControlled.sol";

contract Chimp is ERC20, IERCExtend, AuthorityControlled {
    using SafeMath for uint256;

   constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address authority_
    ) AuthorityControlled(authority_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function mint(address account_, uint256 amount_)
        public
        virtual
        override
        onlyManager
    {
        require(account_ != address(0), "Chimp: mint to the zero address");
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(0), account_, amount_);
    }

    function burn(uint256 amount_) public virtual override {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount_,
            "Chimp: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(msg.sender, address(0), amount_);
    }

    function burnFrom(address account_, uint256 amount_)
        public
        virtual
        override
    {
        require(account_ != address(0), "Chimp: burn from the zero address");
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "Chimp: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function _burn(address account_, uint256 amount_) internal virtual {
        _balances[account_] = _balances[account_].sub(
            amount_,
            "Chimp: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount_);
        emit Transfer(account_, address(0), amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "../IERC20.sol";
import "../SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    // constructor(
    //     string memory name_,
    //     string memory symbol_,
    //     uint8 decimals_,
    //     IAuthority authority_
    // ) AuthorityControlled(authority_) {
    //     _name = name_;
    //     _symbol = symbol_;
    //     _decimals = decimals_;
    // }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(spender != address(0), "ERC20: approve to the zero address");
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

interface IERCExtend {
    function mint(address account_, uint256 amount_) external;
    function burn(uint256 amount_) external;
    function burnFrom(address account_, uint256 amount_) external;
}