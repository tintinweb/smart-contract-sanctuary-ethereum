// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBATCoin.sol";
import "./BATCoin.sol";

contract BATCoinDEX {
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    IBATCoin public token;

    constructor() {
        token = new BATCoin();
    }

    function buy() public payable {
        // amount to buy (value of ether specific when sending trx)
        uint256 _amount = msg.value;

        // the total token in the current address
        uint256 _token_bal = token.balanceOf(address(this));

        // you need some ether
        require(_amount > 0, "you need to send some ether");

        require(_amount <= _token_bal, "not enough tokens in the reserve");

        token.transfer(msg.sender, _amount);

        emit Bought(_amount);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");

        uint256 allowance = token.allowance(msg.sender, address(this));

        require(allowance >= amount, "Check the token allowance");

        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);

        emit Sold(amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IBATCoin {
    /// @dev Tranfer and Approval events

    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// @dev another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by
    /// @dev a call to {approve}. `value` is the new allowance.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev get the name of the token
    function name() external view returns (string memory);

    /// @dev get the symbol of the token
    function symbol() external view returns (string memory);

    /// @dev get the decimals of the token
    function decimals() external view returns (uint8);

    /// @dev get the total tokens in supply
    function totalSupply() external view returns (uint256);

    /// @dev get balance of an account
    function balanceOf(address account) external view returns (uint256);

    /// @dev approve address/contract to spend a specific amount of BAT token
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev get the remaining amount approved for address/contract
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @dev send BAT token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev automate sending of BAT token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBATCoin.sol";

contract BATCoin is IBATCoin {
    /// @dev name of the token
    string public constant _name = "BATCoin";

    /// @dev symbol of the token
    string public constant _symbol = "BAT";

    /// @dev decimal place the amount of the BAT token will be calculated
    uint8 public constant _decimals = 18;

    /// @dev total supply
    uint256 private _totalSupply = 1000000000000;

    /// @dev create a table so that we can map addresses to the balances associated with them
    mapping(address => uint256) balances;

    /// @dev create a table so that we can map the addresses of contract owners to those
    /// @dev who are allowed to utilize the owner's contract
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev run during the deployment of BATCoin smart contract
    constructor() {
        balances[msg.sender] = _totalSupply;
    }

    /// @dev returns the name of the token
    function name() public pure override returns (string memory) {
        return _name;
    }

    /// @dev returns the symbol of the token, usually a shorter version of the name
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /// @dev returns the number of decimals used to get its user representation.
    /// @dev for example, if `decimals` equals `2`, a balance of `505` tokens should
    /// @dev be displayed to a user as `5.05` (`505 / 10 ** 2`)
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /// @dev get the total tokens in supply
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev get balance of an account
    function balanceOf(address account) public view override returns (uint256) {
        // return the balance for the specific address
        return balances[account];
    }

    /// @dev approve address/contract to spend a specific amount of BAT token
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;

        // fire the event "Approval" to execute any logic
        // that was listening to it
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @dev get the remaining amount approved for address/contract
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    /// @dev send BAT token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        // if the sender has sufficient funds to send
        // and the amount is not zero, then send to
        // the given address
        if (
            balances[msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(msg.sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /// @dev automate sending of BAT token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (
            balances[sender] >= amount &&
            allowed[sender][msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }
}