/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
// This is a ERC-20 token that is ONLY meant to be used as a extension for the Mysterious World NFT Project
// The only use case for this token is to be used to interact with The Mysterious World.
// This token has no monetary value associated to it.
// Read more at https://www.themysterious.world/utility

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// The interface is used so we can get the balance of each holder
interface TheMysteriousWorld {
    function balanceOf(address inhabitant) external view returns(uint256);
    function ritualWallet() external view returns(address);
}

/*
 * 888d888888  88888888b.  .d88b. .d8888b  
 * 888P"  888  888888 "88bd8P  Y8b88K      
 * 888    888  888888  88888888888"Y8888b. 
 * 888    Y88b 888888  888Y8b.         X88 
 * 888     "Y88888888  888 "Y8888  88888P' 
 */
contract Runes is ERC20, Ownable {
    TheMysteriousWorld public mysteriousworld;

    uint256 public deployedStamp       = 0; // this is used to calculate the amount of $RUNES a user has from the current block.timestamp
    uint256 public runesPerDay         = 10 ether; // this ends up being 25 $RUNES per day. this might change in the future depending on how the collection grows overtime.
    bool    public allowRuneCollecting = false; // this lets you claim your $RUNES from the contract to the wallet

    mapping(address => uint256) public runesObtained; // this tracks how much $RUNES each address earned
    mapping(address => uint256) public lastTimeCollectedRunes; // this sets the block.timestamp to the address so it subtracts the timestamp from the pending rewards
    mapping(address => bool)    public contractWallets; // these are used to interact with the burning mechanisms of the contract - these will only be set to contracts related to The Mysterious World

    constructor() ERC20("Runes", "Runes") {}

    /*
     * # onlyContractWallets
     * blocks anyone from accessing it but contract wallets
     */
    modifier onlyContractWallets() {
        require(contractWallets[msg.sender], "You angered the gods!");
        _;
    }

    /*
     * # onlyWhenCollectingIsEnabled
     * blocks anyone from accessing functions that require allowRuneCollecting
     */
    modifier onlyWhenCollectingIsEnabled() {
        require(allowRuneCollecting, "You angered the gods!");
        _;
    }

    /*
     * # setRuneCollecting
     * enables or disables users to withdraw their runes - should only be called once unless the gods intended otherwise
     */
    function setRuneCollecting(bool newState) public payable onlyOwner {
        allowRuneCollecting = newState;
    }

    /*
     * # setDeployedStamp
     * sets the timestamp for when the $RUNES should start being generated
     */
    function setDeployedStamp(bool forced, uint256 stamp) public payable onlyOwner {
        if (forced) {
            deployedStamp = stamp;
        } else {
            deployedStamp = block.timestamp;
        }
    }

    /*
     * # setRunesPerDay
     * incase we want to change the amount gained per day, the gods can set it here
     */
    function setRunesPerDay(uint256 newRunesPerDay) public payable onlyOwner {
        runesPerDay = newRunesPerDay;
    }

    /*
     * # setMysteriousWorldContract
     * sets the address to the deployed Mysterious World contract
     */
    function setMysteriousWorldContract(address contractAddress) public payable onlyOwner {
        mysteriousworld = TheMysteriousWorld(contractAddress);
    }

    /*
     * # setContractWallets
     * enables or disables a contract wallet from interacting with the burn mechanics of the contract
     */
    function setContractWallets(address contractAddress, bool newState) public payable onlyOwner {
        contractWallets[contractAddress] = newState;
    }

    /*
     * # getPendingRunes
     * calculates the runes a inhabitant has from the last time they claimed and the deployedStamp time
     */
    function getPendingRunes(address inhabitant) internal view returns(uint256) {
        uint256 sumOfRunes = mysteriousworld.balanceOf(inhabitant) * runesPerDay;

        if (lastTimeCollectedRunes[inhabitant] >= deployedStamp) {
            return sumOfRunes * ((block.timestamp - lastTimeCollectedRunes[inhabitant])) / 86400;
        } else {
            return sumOfRunes * ((block.timestamp - deployedStamp)) / 86400;
        }
    }

    /*
     * # getUnclaimedRunes
     * returns the total amount of unclaimed runes a wallet has
     */
    function getUnclaimedRunes(address inhabitant) external view returns(uint256) {
        return getPendingRunes(inhabitant);
    }

    /*
     * # getTotalRunes
     * returns the runesObtained and getPendingRunes for the inhabitant passed
     */
    function getTotalRunes(address inhabitant) external view returns(uint256) {
        return runesObtained[inhabitant] + getPendingRunes(inhabitant);
    }

    /*
     * # burn
     * removes the withdrawn $RUNES from the wallet provided for the amount provided
     */
    function burn(address inhabitant, uint256 cost) external payable onlyContractWallets {
        _burn(inhabitant, cost);
    }

    /*
     * # claimRunes
     * adds the $RUNES to your wallet
     */
    function claimRunes() external payable {
        _mint(msg.sender, runesObtained[msg.sender] + getPendingRunes(msg.sender));

        runesObtained[msg.sender] = 0;
        lastTimeCollectedRunes[msg.sender] = block.timestamp;
    }

    /*
     * # updateRunes
     * updates the pending balance for both of the wallets associated to the transfer so they don't lose the $RUNES generated
     */
    function updateRunes(address from, address to) external onlyContractWallets {
        if (from != address(0) && from != mysteriousworld.ritualWallet()) {
            runesObtained[from]          += getPendingRunes(from);
            lastTimeCollectedRunes[from] = block.timestamp;
        }

        if (to != address(0) && to != mysteriousworld.ritualWallet()) {
            runesObtained[to]          += getPendingRunes(to);
            lastTimeCollectedRunes[to] = block.timestamp;
        }
    }
}