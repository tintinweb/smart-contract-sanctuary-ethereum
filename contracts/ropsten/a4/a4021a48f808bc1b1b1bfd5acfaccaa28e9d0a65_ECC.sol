/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)


pragma solidity ^0.8.14;




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _blockTimestamp() internal view virtual returns (uint) {
        return block.timestamp;
    }
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }


}



contract ERC20 is Context, IERC20, IERC20Metadata ,Ownable, Pausable{
    struct lockInfo {
        bool lockStatus;
        uint32[] unlockTimeList;
    }     
    struct additionalUnlockInfo {
        uint32 additionalUnlockIndex;
        uint128 additionalUnlockAmount;
    }
    struct certainUnlockInfo {
        uint8 index;
        uint8 listIength;
        uint128 totalLockAmount; 
        uint128 totalAdditionalUnlockAmount;
        uint32[] additionalUnlockTimeList;
        mapping(uint32 => additionalUnlockInfo) additionalUnlock;
    }    
    mapping(address => lockInfo) private _lock;  
    mapping(address => mapping(uint32 => certainUnlockInfo)) private _certainUnlockTime;
    event lock(address account,uint32 lockTime,uint128 totalLockAmount);
    event unlock(address account,uint32 unlockTime,uint128 totalUnlockAmount);
    function unlockTimeList(address account)  external view returns (bool lockStatus, uint32[] memory lockTime) {
        lockStatus = _lock[account].lockStatus;
        lockTime = _lock[account].unlockTimeList;
    }  
    function additionalLockTimeInfo(address account, uint32 lockTime) external view returns(uint32[] memory additionalLockTime, uint128 unlockableAmount, uint availableAmount) {
        uint32[] memory _additionalLockTime = _certainUnlockTime[account][lockTime].additionalUnlockTimeList;
        uint128 amount;
        for (uint8 i=0; i<_additionalLockTime.length;){
            if (_additionalLockTime[i] < _blockTimestamp()) {
                unchecked{ amount += _certainUnlockTime[account][lockTime].additionalUnlock[_additionalLockTime[i]].additionalUnlockAmount; }
            }
            unchecked{ i++; }
        }
        additionalLockTime = _additionalLockTime;
        unlockableAmount = _certainUnlockTime[account][lockTime].totalLockAmount;
        availableAmount = amount;
    }
    function transferAndLock(address to, uint128 totalLockAmount, uint32 unlockTime) onlyOwner external  { 
        require(_certainUnlockTime[to][unlockTime].totalLockAmount == 0 && unlockTime > _blockTimestamp(),"abnormal UnlockTime");
        _lock[to].lockStatus = true;
        _lock[to].unlockTimeList.push(unlockTime);
        _certainUnlockTime[to][unlockTime].totalLockAmount = totalLockAmount; 
        _certainUnlockTime[to][unlockTime].index = _certainUnlockTime[to][unlockTime].index+1;
        _transfer(_msgSender(), to, totalLockAmount);
        emit lock(to,unlockTime,totalLockAmount);
    }
    function additionalLockTimeAdd(address account, uint32 unlockTime, uint32[] calldata additionalUnlockTime, uint128[] calldata additionalUnlockAmount) onlyOwner external {
        require(_certainUnlockTime[account][unlockTime].totalLockAmount != 0,"abnormal unlockTime");
        require(additionalUnlockTime.length == additionalUnlockAmount.length ,"data length is different");
        uint128 num;
        uint8 length = _certainUnlockTime[account][unlockTime].listIength ;
        for (uint32 i=0; i<additionalUnlockTime.length;){
            require(_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime[i]].additionalUnlockAmount == 0 || additionalUnlockTime[i] > unlockTime,"AdditionalUnlockTime is wrong");
            unchecked{ num += additionalUnlockAmount[i]; }
            _certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime[i]] = additionalUnlockInfo(length,additionalUnlockAmount[i]);
            _certainUnlockTime[account][unlockTime].additionalUnlockTimeList.push(additionalUnlockTime[i]);
            unchecked{ length++; }
            unchecked{ i++; }
        }
        require(_certainUnlockTime[account][unlockTime].totalLockAmount >= _certainUnlockTime[account][unlockTime].totalAdditionalUnlockAmount+num ,"totalLockAmount exceeded");
        _certainUnlockTime[account][unlockTime].totalAdditionalUnlockAmount = _certainUnlockTime[account][unlockTime].totalAdditionalUnlockAmount+num;
        _certainUnlockTime[account][unlockTime].listIength = length;
    }
    function additionalLockTimeChange(address account,uint32 unlockTime,uint32 additionalUnlockTime,uint32 changeAdditionalUnlockTime,uint128 changeAdditionalUnlockAmount) onlyOwner external{
        require(_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockAmount != 0,"additionalUnlockTime is wrong");
        require(_certainUnlockTime[account][unlockTime].additionalUnlock[changeAdditionalUnlockTime].additionalUnlockAmount == 0 && changeAdditionalUnlockTime > unlockTime,"changeAdditionalUnlockTime is wrong");
        uint128 changeTotalLockAmount = _certainUnlockTime[account][unlockTime].totalAdditionalUnlockAmount-_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockAmount+changeAdditionalUnlockAmount;
        require(_certainUnlockTime[account][unlockTime].totalLockAmount >= changeTotalLockAmount, "greater than Total LockAmount");
        _certainUnlockTime[account][unlockTime].totalAdditionalUnlockAmount = changeTotalLockAmount;
        _certainUnlockTime[account][unlockTime].additionalUnlockTimeList[_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockIndex] = changeAdditionalUnlockTime;
        _certainUnlockTime[account][unlockTime].additionalUnlock[changeAdditionalUnlockTime] = additionalUnlockInfo(_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockIndex,changeAdditionalUnlockAmount);
        delete _certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime];
    }
    function additionalLockTimeDelete(address account,uint32 unlockTime,uint32 additionalUnlockTime) onlyOwner external{
        require(_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockAmount != 0,"have no value for deletion");
        _certainUnlockTime[account][unlockTime].additionalUnlockTimeList[_certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime].additionalUnlockIndex] = 0;
        delete _certainUnlockTime[account][unlockTime].additionalUnlock[additionalUnlockTime];
    }
    function unlockTimeDelete(address account,uint32 unlockTime) onlyOwner external{
        uint128 totalLockAmount = _certainUnlockTime[account][unlockTime].totalLockAmount;
        require(totalLockAmount != 0,"There's no unlocktime");
        delete _lock[account].unlockTimeList[_certainUnlockTime[account][unlockTime].index-1];
        delete _certainUnlockTime[account][unlockTime];
        emit unlock(account,unlockTime,totalLockAmount);
    }
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _freeze;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0),_msgSender(), _totalSupply);
    }
    modifier frozen(address from,address fo){
        require(!_freeze[from], "It's a frozen address");
        require(!_freeze[fo], "It's a frozen address");
        _;
    }
    function addressFreeze(address account) external onlyOwner {
        require(!_freeze[account], "freeze : freeze");
        _freeze[account] = true;
    }
    function addressUnfreeze(address account) external onlyOwner {
        require(_freeze[account], "freeze : not freeze");
        _freeze[account] = false;
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
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) whenNotPaused public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) whenNotPaused public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) whenNotPaused public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) whenNotPaused public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) whenNotPaused public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function burn(uint256 amount) whenNotPaused public {
      _burn(_msgSender(), amount);
      _totalSupply -= amount;
    }
    function _transfer(address from, address to, uint256 amount) frozen(from,to) internal virtual {
       if (_lock[from].lockStatus == true) {
            uint128 allLockAmount; 
            uint128 allUnlockAmount;
            for (uint8 i=0; i<_lock[from].unlockTimeList.length;){ 
                unchecked { allLockAmount += _certainUnlockTime[from][_lock[from].unlockTimeList[i]].totalLockAmount;}
                uint128 UnlockAmount ;
                if (_lock[from].unlockTimeList[i] < _blockTimestamp() && _certainUnlockTime[from][_lock[from].unlockTimeList[i]].additionalUnlockTimeList.length == 0) {
                    UnlockAmount = _certainUnlockTime[from][_lock[from].unlockTimeList[i]].totalLockAmount;
                }
                for (uint8 j=0; j< _certainUnlockTime[from][_lock[from].unlockTimeList[i]].additionalUnlockTimeList.length;){
                    if (_certainUnlockTime[from][_lock[from].unlockTimeList[i]].additionalUnlockTimeList[j] < _blockTimestamp()) {
                        unchecked { UnlockAmount += _certainUnlockTime[from][_lock[from].unlockTimeList[i]].additionalUnlock[_certainUnlockTime[from][_lock[from].unlockTimeList[i]].additionalUnlockTimeList[j]].additionalUnlockAmount;}
                    }
                    unchecked {j ++;}
                }
                if (UnlockAmount == _certainUnlockTime[from][_lock[from].unlockTimeList[i]].totalLockAmount) {
                    emit unlock(from,_lock[from].unlockTimeList[i],UnlockAmount);
                    delete _lock[from].unlockTimeList[i]; 
                }
                unchecked {allUnlockAmount += UnlockAmount;}
                unchecked {i ++;}
            }
            if (allLockAmount == allUnlockAmount) {
                _lock[from].lockStatus = false;
                delete _lock[from].unlockTimeList;
            }
            require(_balances[from]+allUnlockAmount-allLockAmount >= amount,"Transmittable amount exceeded");  
        }

        uint256 fromBalance = _balances[from];
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }




    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) frozen(owner,spender) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(_balances[owner] >= amount, "ERC20: transfer amount exceeds balance");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


contract ECC is ERC20 {
    constructor() ERC20("OOOO1", "OOOO1",18,20000000000000000000000000000) {
    }
}