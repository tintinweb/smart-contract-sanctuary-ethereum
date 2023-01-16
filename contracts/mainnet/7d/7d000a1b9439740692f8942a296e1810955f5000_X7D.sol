/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: ERC-20 Token X7 Deposit (X7D)

NOTE: DO NOT SEND FUNDS DIRECTLY TO THIS CONTRACT! THEY WILL BE CLAIMED BY THE ECOSYSTEM!

X7D is the ETH backed token of the X7 ecosystem. X7D can be minted from ETH by authorizedMinters and burned to ETH by authorizedRedeemers.
All ETH underpinning X7D will be custodied by smart contracts.

Unlike a strictly wrapped token like WETH, the X7D token contract does not custody any ETH itself. It instead defers this job to authorizedMinters and authorizedRedeemers. This provides flexibility to deploy multiple mechanisms for minting X7D and redeeming X7D into ETH at various timescales, with various associated caveats, and with various multipliers or percentage returns.

The X7D Lending Pool Reserve smart contract will be the first authorizedMinter and authorizedRedeemer.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setAuthorizedMinter(address minterAddress, bool isAuthorized) external onlyOwner {
        require(authorizedMinter[minterAddress] != isAuthorized, "Minter already has specified authorization");
        authorizedMinter[minterAddress] = isAuthorized;

        if (isAuthorized) {
            authorizedMintersIndex[minterAddress] = authorizedMinters.length;
            authorizedMinters.push(minterAddress);
        } else {
            uint256 lastMinterIndex = authorizedMinters.length - 1;
            address lastMinter = authorizedMinters[lastMinterIndex];
            uint256 minterIndex = authorizedMintersIndex[minterAddress];
            authorizedMinters[minterIndex] = lastMinter;
            authorizedMintersIndex[lastMinter] = minterIndex;
            delete authorizedMintersIndex[minterAddress];
            authorizedMinters.pop();
        }

        emit AuthorizedMinterSet(minterAddress, isAuthorized);
    }

    function setAuthorizedRedeemer(address redeemerAddress, bool isAuthorized) external onlyOwner {
        require(authorizedRedeemer[redeemerAddress] != isAuthorized, "Redeemer already has specified authorization");
        authorizedRedeemer[redeemerAddress] = isAuthorized;

        if (isAuthorized) {
            authorizedRedeemersIndex[redeemerAddress] = authorizedRedeemers.length;
            authorizedRedeemers.push(redeemerAddress);
        } else {
            uint256 lastRedeemerIndex = authorizedRedeemers.length - 1;
            address lastRedeemer = authorizedRedeemers[lastRedeemerIndex];
            uint256 redeemerIndex = authorizedRedeemersIndex[redeemerAddress];
            authorizedRedeemers[redeemerIndex] = lastRedeemer;
            authorizedRedeemersIndex[lastRedeemer] = redeemerIndex;
            delete authorizedRedeemersIndex[redeemerAddress];
            authorizedRedeemers.pop();
        }

        emit AuthorizedRedeemerSet(redeemerAddress, isAuthorized);
    }

    function setRecoveredTokenRecipient(address tokenRecipient_) external onlyOwner {
        require(recoveredTokenRecipient != tokenRecipient_);
        address oldRecipient = recoveredTokenRecipient;
        recoveredTokenRecipient = tokenRecipient_;
        emit RecoveredTokenRecipientSet(oldRecipient, tokenRecipient_);
    }

    function setRecoveredETHRecipient(address ETHRecipient_) external onlyOwner {
        require(recoveredETHRecipient != ETHRecipient_);
        address oldRecipient = recoveredETHRecipient;
        recoveredETHRecipient = ETHRecipient_;
        emit RecoveredETHRecipientSet(oldRecipient, ETHRecipient_);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

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

contract ERC20 is IERC20, IERC20Metadata {
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// The primary X7D interface for minting and burning from authorized Minters and Burners.
interface IX7D {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}


interface X7DMinter {
// A minter should implement the following two functions.

    // Call this function to explicitly mint X7D
    function depositETH() external payable;

    // Call this function to return ETH to this contract without minting X7D
    //
    //  This is important as a valid mechanism for a minter to mint from ETH
    //  would be to implement a receive function to automatically mint X7D.
    function returnETH() external payable;
}


interface X7DBurner {
// A burner/redeemer should implement the following two functions.

    // Call this function to redeem (burn) X7D for ETH
    function withdrawETH(uint256 amount) external;
}

abstract contract TokensCanBeRecovered is Ownable {
    bytes4 private constant TRANSFERSELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    address public recoveredTokenRecipient;

    event RecoveredTokenRecipientSet(address oldRecipient, address newRecipient);

    function setRecoveredTokenRecipient(address tokenRecipient_) external onlyOwner {
        require(recoveredTokenRecipient != tokenRecipient_);
        address oldRecipient = recoveredTokenRecipient;
        recoveredTokenRecipient = tokenRecipient_;
        emit RecoveredTokenRecipientSet(oldRecipient, tokenRecipient_);
    }

    function recoverTokens(address tokenAddress) external {
        require(recoveredTokenRecipient != address(0));
        _safeTransfer(tokenAddress, recoveredTokenRecipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERSELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
}

abstract contract ETHCanBeRecovered is Ownable {

    address public recoveredETHRecipient;

    event RecoveredETHRecipientSet(address oldRecipient, address newRecipient);

    function setRecoveredETHRecipient(address ETHRecipient_) external onlyOwner {
        require(recoveredETHRecipient != ETHRecipient_);
        address oldRecipient = recoveredETHRecipient;
        recoveredETHRecipient = ETHRecipient_;
        emit RecoveredETHRecipientSet(oldRecipient, ETHRecipient_);
    }

    function recoverETH() external {
        require(recoveredETHRecipient != address(0));
        (bool success,) = recoveredETHRecipient.call{value: address(this).balance}("");
        require(success);
    }
}

contract X7D is ERC20, Ownable, TokensCanBeRecovered, ETHCanBeRecovered, IX7D {

    mapping(address => bool) public authorizedMinter;
    mapping(address => bool) public authorizedRedeemer;

    address[] public authorizedMinters;
    address[] public authorizedRedeemers;

    // Internal index mapping for array maintenance
    mapping(address => uint256) authorizedMintersIndex;
    mapping(address => uint256) authorizedRedeemersIndex;

    event AuthorizedMinterSet(address indexed minterAddress, bool isAuthorized);
    event AuthorizedRedeemerSet(address indexed redeemerAddress, bool isAuthorized);

    constructor() ERC20("X7 Deposit", "X7D") Ownable(msg.sender) {}

    receive() external payable {}

    function authorizedMintersCount() external view returns (uint256) {
        return authorizedMinters.length;
    }

    function authorizedRedeemersCount() external view returns (uint256) {
        return authorizedRedeemers.length;
    }

    function setAuthorizedMinter(address minterAddress, bool isAuthorized) external onlyOwner {
        require(authorizedMinter[minterAddress] != isAuthorized, "Minter already has specified authorization");
        authorizedMinter[minterAddress] = isAuthorized;

        if (isAuthorized) {
            authorizedMintersIndex[minterAddress] = authorizedMinters.length;
            authorizedMinters.push(minterAddress);
        } else {
            uint256 lastMinterIndex = authorizedMinters.length - 1;
            address lastMinter = authorizedMinters[lastMinterIndex];
            uint256 minterIndex = authorizedMintersIndex[minterAddress];
            authorizedMinters[minterIndex] = lastMinter;
            authorizedMintersIndex[lastMinter] = minterIndex;
            delete authorizedMintersIndex[minterAddress];
            authorizedMinters.pop();
        }

        emit AuthorizedMinterSet(minterAddress, isAuthorized);
    }

    function setAuthorizedRedeemer(address redeemerAddress, bool isAuthorized) external onlyOwner {
        require(authorizedRedeemer[redeemerAddress] != isAuthorized, "Redeemer already has specified authorization");
        authorizedRedeemer[redeemerAddress] = isAuthorized;

        if (isAuthorized) {
            authorizedRedeemersIndex[redeemerAddress] = authorizedRedeemers.length;
            authorizedRedeemers.push(redeemerAddress);
        } else {
            uint256 lastRedeemerIndex = authorizedRedeemers.length - 1;
            address lastRedeemer = authorizedRedeemers[lastRedeemerIndex];
            uint256 redeemerIndex = authorizedRedeemersIndex[redeemerAddress];
            authorizedRedeemers[redeemerIndex] = lastRedeemer;
            authorizedRedeemersIndex[lastRedeemer] = redeemerIndex;
            delete authorizedRedeemersIndex[redeemerAddress];
            authorizedRedeemers.pop();
        }

        emit AuthorizedRedeemerSet(redeemerAddress, isAuthorized);
    }

    function mint(address to, uint256 amount) external {
        require(authorizedMinter[msg.sender], "Not authorized to mint X7D");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(authorizedRedeemer[msg.sender], "Not authorized to burn X7D");
        _burn(from, amount);
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(address(0xdEaD));
    }
}