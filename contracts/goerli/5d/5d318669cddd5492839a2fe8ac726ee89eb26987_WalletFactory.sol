/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
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
            _totalSupply -= amount;
        }

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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function drainERC20(address tracker) public onlyOwner returns (bool) {
        return
            ERC20(tracker).transfer(
                owner,
                ERC20(tracker).balanceOf(address(this))
            );
    }

    function drainETH() public onlyOwner returns (bool) {
        return payable(address(owner)).send(address(this).balance);
    }
}

contract WalletFactory {
    mapping(address => bool) private permittedAddresses;

    mapping(bytes => address) private createdWallets;

    bytes1 private constant CREATE2_CONSTANT = bytes1(0x9f);

    modifier senderIsPermitted() {
        require(permittedAddresses[msg.sender], "You are not permitted");
        _;
    }

    modifier walletIsCreated(bytes memory salt) {
        require(isCreated(salt), "Wallet is not yet created");
        _;
    }

    constructor() {
        permittedAddresses[msg.sender] = true;
    }

    function isContract(address account) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        return (size > 0);
    }

    function getCreate2Params()
        private
        view
        returns (
            bytes1,
            address,
            bytes32
        )
    {
        bytes memory bytecode = type(Wallet).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode());
        return (CREATE2_CONSTANT, address(this), keccak256(bytecode));
    }

    function isPermitted(address account) private view returns (bool) {
        return permittedAddresses[account];
    }

    function grantPermission(address account) public senderIsPermitted {
        require(!isContract(account), "Account is a smart contract");
        require(!permittedAddresses[account], "Account is already permitted");
        permittedAddresses[account] = true;
    }

    function revokePermission(address account) public senderIsPermitted {
        require(permittedAddresses[account], "Account is not permitted");
        permittedAddresses[account] = false;
    }

    function isCreated(bytes memory salt) public view returns (bool) {
        return
            createdWallets[salt] != 0x0000000000000000000000000000000000000000;
    }

    function getWalletAddress(bytes memory salt) public view returns (address) {
        (bytes1 c2c, address sender, bytes32 bytecode) = getCreate2Params();

        bytes32 addressHash = keccak256(
            abi.encodePacked(c2c, sender, salt, bytecode)
        );
        return address(uint160(uint256(addressHash)));
    }

    function createWallet(bytes memory salt) public payable senderIsPermitted {
        require(!isCreated(salt), "Wallet is already created");

        address walletAddress;
        (bytes1 c2c, address sender, bytes32 bytecode) = getCreate2Params();

        assembly {
            walletAddress := create2(c2c, sender, salt, bytecode)

            if iszero(extcodesize(walletAddress)) {
                revert(0, 0)
            }
        }

        createdWallets[salt] = walletAddress;
    }

    function drainWalletERC20(bytes memory salt, address erc20)
        public
        senderIsPermitted
        walletIsCreated(salt)
        returns (bool)
    {
        return Wallet(createdWallets[salt]).drainERC20(erc20);
    }

    function drainWalletEth(bytes memory salt)
        public
        senderIsPermitted
        walletIsCreated(salt)
        returns (bool)
    {
        return Wallet(createdWallets[salt]).drainETH();
    }

    function transferERC20(
        address tracker,
        uint256 amount,
        address to
    ) public senderIsPermitted returns (bool) {
        return ERC20(tracker).transfer(to, amount);
    }

    function transfer(uint256 amount, address payable to)
        public
        senderIsPermitted
        returns (bool)
    {
        return to.send(amount);
    }
}