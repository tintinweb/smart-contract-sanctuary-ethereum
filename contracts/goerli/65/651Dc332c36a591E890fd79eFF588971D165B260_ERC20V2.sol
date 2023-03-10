//SPDX-License-Identifier:MIT

pragma solidity ^0.8.6;

contract ERC20V2 {
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
    uint256 tokenInCirculation;
    address owner;
    string version;
    string _name;
    string _symbol;
    string _version;

    modifier OnlyOwner() {
        if (owner != address(0x00)) {
            require(owner == msg.sender, "Invalid Onwer");
            _;
        } else {
            _;
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function setOwner(address _owner) public OnlyOwner {
        owner = _owner;
    }

    function setVersion(string memory version) public OnlyOwner {
        _version = version;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= amount, "Insufficient Balance");
        unchecked {
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;
        }

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

    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");

        tokenInCirculation += amount;
        unchecked {
            balanceOf[account] += amount;
        }
    }

    function burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
            tokenInCirculation -= amount;
        }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
    }

    function allowances(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowance[_owner][spender];
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowances(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address _owner = msg.sender;
        uint256 currentAllowance = allowances(_owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address _owner = msg.sender;
        _approve(_owner, spender, allowances(_owner, spender) + addedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            balanceOf[from] = fromBalance - amount;
            balanceOf[to] += amount;
        }
    }

    function getTotalSupply() public view returns (uint256) {
        return tokenInCirculation;
    }

    function getBalanceOf(address user) public view returns (uint256) {
        return balanceOf[user];
    }

    function getVersion() public view returns (string memory) {
        return _version;
    }
}