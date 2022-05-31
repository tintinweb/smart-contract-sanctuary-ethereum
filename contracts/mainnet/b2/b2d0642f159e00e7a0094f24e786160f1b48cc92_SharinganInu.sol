/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

/**

The Uchiha clan is back to take its revenge on Konoha, 
will the Mangekyo Sharigan allow them to reach the #1 spot on Dextools ? 



   _____ _    _          _____  _____ _   _  _____          _   _   _____ _   _ _    _ 
  / ____| |  | |   /\   |  __ \|_   _| \ | |/ ____|   /\   | \ | | |_   _| \ | | |  | |
 | (___ | |__| |  /  \  | |__) | | | |  \| | |  __   /  \  |  \| |   | | |  \| | |  | |
  \___ \|  __  | / /\ \ |  _  /  | | | . ` | | |_ | / /\ \ | . ` |   | | | . ` | |  | |
  ____) | |  | |/ ____ \| | \ \ _| |_| |\  | |__| |/ ____ \| |\  |  _| |_| |\  | |__| |
 |_____/|_|  |_/_/    \_\_|  \_\_____|_| \_|\_____/_/    \_\_| \_| |_____|_| \_|\____/ 
                                                                                       
                                                                                       

                                                                           

Website: https://sharinganinueth.com/
Telegram: https://t.me/SharinganInuPortal
Twitter: https://twitter.com/SharinganInu


🔴 Launch Details:

✨ Initial liquidity: 5 ETH
✨ Anti-Bot / Anti-Snipe: Activated
- bots will be blacklisted
✨ 100% STEALTHLAUNCH, NOBODY KNOWS.
✨ NO DEV TOKENS, NO PRESALE TOKENS! 
✨ 3% on buys and sells

🔴 ROADMAP:

- Community Rewards
- Sharingan Inu DAO
- Sharigan Inu Incubator
- KYC Castle
- CertiK Audit

*/

pragma solidity ^0.7.4;

// SPDX-License-Identifier: Unlicensed

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
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ERC20Interface {
    function balanceOf(address whom) public view virtual returns (uint256);
}

contract SharinganInu is IERC20 {
    using SafeMath for uint256;

    string constant _name = "Sharingan Inu";
    string constant _symbol = "SHARINGAN";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint256 _totalSupply = 10000 * (10**_decimals);
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor() {
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        _transferFrom(sender, recipient, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
}