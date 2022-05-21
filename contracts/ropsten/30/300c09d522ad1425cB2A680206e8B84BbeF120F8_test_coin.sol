/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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
    function totalSupply() external view returns (uint256);
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
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function paused() public view returns (bool) {
        return _paused;
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










contract ERC20 is Context, IERC20, Ownable, Pausable {

    struct lockedInfo {
        uint256 lockingTime;
        uint256 totalTransferAmount; 
        bool lockWhether;
        bool additionalLockWhether;
    } 
    mapping(address => lockedInfo) private _lockedAddressInfo;
    mapping(address => uint256[]) private _additionalLockedTime;
    mapping(address => mapping(uint256 => uint256)) private _additionalLockedAmount;
    event Locked(address indexed to, uint256 indexed lockingTime, uint256 totalTransferAmount, uint256 percentageAvailable);
    event LockedChange(address indexed to, uint256 indexed changeLockingTime, uint256 previousLockingTime, uint256 totalTransferAmount, uint256 percentageAvailable);
    event Unlocked(address indexed to, uint256 indexed lockingTime, uint256 totalTransferAmount, uint256 percentageAvailable);

    function _lockedInfoChange(address to, uint256 lockingTime, uint256 totalTransferAmount, bool lockWhether, bool additionalLockWhether) internal {
        _lockedAddressInfo[to].lockingTime = lockingTime;
        _lockedAddressInfo[to].totalTransferAmount = totalTransferAmount;
        _lockedAddressInfo[to].lockWhether = lockWhether;
        _lockedAddressInfo[to].additionalLockWhether = additionalLockWhether;
    }
    function lockBalanceOf(address account) external view returns(bool lockWhether,uint256 currentLockTime,uint256 currentLockAmount,uint256 availableAmount){
        bool _lockWhether = _lockedAddressInfo[account].lockWhether;
        bool _additionalLockWhether = _lockedAddressInfo[account].additionalLockWhether;
        /*잠금여부=false , 추가잠금여부=false*/
        if (_lockWhether == false && _additionalLockWhether == false){
            lockWhether = false;
            currentLockTime = 0;
            currentLockAmount = 0;
            availableAmount = _balances[account];
        }
        /*잠금여부=true , 추가잠금여부=false*/
        if (_lockWhether == true && _additionalLockWhether == false){
            if (_lockedAddressInfo[account].lockingTime <= _blockTimestamp()) {
                lockWhether = false;
                currentLockTime = 0;
                currentLockAmount = 0;
                availableAmount = _balances[account];
            } else {
                lockWhether = true;
                currentLockTime = _lockedAddressInfo[account].lockingTime;
                currentLockAmount = _lockedAddressInfo[account].totalTransferAmount;
                availableAmount = 0;    
            }
        }
        /*잠금여부=true , 추가잠금여부=true*/
        if (_lockWhether == true && _additionalLockWhether == true){
            if (_lockedAddressInfo[account].lockingTime <= _blockTimestamp()){
                uint256[] memory _additionalLockedTimeList = _additionalLockedTime[account];
                if (_additionalLockedTimeList[_additionalLockedTimeList.length-1] <= _blockTimestamp()){
                    lockWhether = false;
                    currentLockTime = 0;
                    currentLockAmount = 0;
                    availableAmount = _balances[account];  
                } else {
                    uint length = _additionalLockedTimeList.length;
                    for(uint j=0; j<length-1; j++){
                        if (_additionalLockedTimeList[j] <= _blockTimestamp()){
                            for (uint i = j; i<_additionalLockedTimeList.length-1; i++){
                                _additionalLockedTimeList[i] = _additionalLockedTimeList[i+1];
                            }
                            delete _additionalLockedTimeList[_additionalLockedTimeList.length-1];
                            length--;
                        }
                    }
                    lockWhether = true;
                    currentLockTime = _additionalLockedTimeList[0];
                    currentLockAmount = (_lockedAddressInfo[account].totalTransferAmount*_additionalLockedAmount[account][_additionalLockedTimeList[0]])/100;
                    availableAmount = (currentLockAmount+_balances[account])-_lockedAddressInfo[account].totalTransferAmount;   
                }
            } else {
                lockWhether = true;
                currentLockTime = _lockedAddressInfo[account].lockingTime;
                currentLockAmount = _lockedAddressInfo[account].totalTransferAmount;
                availableAmount = 0;    
            }
        }
    }   
    function transferAndLock(address to, uint256 lockingTime, uint256 amount) whenNotPaused onlyOwner external returns (bool) {
        /*지갑주소의 전송기능을 잠그는 시간 > 블록 타임스탬프  / 맞지않으면 에러표시*/
        require(lockingTime > _blockTimestamp(), "lockingTime: 'lockingTime' must be greater than 'blockTimestamp'");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        if (_lockedAddressInfo[to].lockingTime == 0){
            emit Locked(to,lockingTime,_lockedAddressInfo[to].totalTransferAmount+amount,0);
        } else {
            emit LockedChange(to,lockingTime,_lockedAddressInfo[to].lockingTime,_lockedAddressInfo[to].totalTransferAmount+amount,0);
        }
        _lockedInfoChange(to,lockingTime,_lockedAddressInfo[to].totalTransferAmount+amount,true,false);
        return true;
    }
    function lockingTimeChange(address account, uint256 lockingTime) whenNotPaused onlyOwner external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedAddressInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        /*지갑주소의 전송기능을 잠그는 시간 >  블록 타임스탬프  / 맞지않으면 에러표시*/
        require(lockingTime > _blockTimestamp(), "lockingTime: lockingTime should be bigger");        
        /*지갑주소의 전송기능을 잠그는 시간 != 이전 지갑주소의 전송기능을 잠근 시간  / 맞지않으면 에러표시*/
        require(lockingTime != _lockedAddressInfo[account].lockingTime, "lockingTime: Same as previously set 'lockingTime'");
        if (_lockedAddressInfo[account].additionalLockWhether == true) {
            /*추가잠금 시간 > 지갑주소의 전송기능을 잠그는 시간  / 맞지않으면 에러표시*/
            require(_additionalLockedTime[account][0] > lockingTime, "lockingTime: 'lockingTime' cannot be greater than 'additionalLockedTime'");
        }
        emit LockedChange(account,lockingTime,_lockedAddressInfo[account].lockingTime,_lockedAddressInfo[account].totalTransferAmount,0);
        _lockedAddressInfo[account].lockingTime = lockingTime;
    }
    function lockedRelease(address account) whenNotPaused onlyOwner external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedAddressInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        emit Unlocked(account,_lockedAddressInfo[account].lockingTime,_lockedAddressInfo[account].totalTransferAmount,0);
        if (_lockedAddressInfo[account].additionalLockWhether == true){
            for(uint i=0; i<_additionalLockedTime[account].length; i++){
                emit Unlocked(account,_additionalLockedTime[account][i],_lockedAddressInfo[account].totalTransferAmount,_additionalLockedAmount[account][_additionalLockedTime[account][i]]);
                _additionalLockedAmount[account][_additionalLockedTime[account][i]] = 0;
            }
            delete _additionalLockedTime[account];
        }
        _lockedInfoChange(account,0,_lockedAddressInfo[account].totalTransferAmount,false,false);
    }
    function additionalLock(address account, uint256 lockingTime, uint256 percentageAvailable) whenNotPaused onlyOwner external {
        /*잠김여부 == true  / 맞지않으면 에러표시*/
        require(_lockedAddressInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        /*지갑주소의 전송기능을 잠근 시간 < 추가잠금 시간  / 맞지않으면 에러표시*/
        require(_lockedAddressInfo[account].lockingTime < lockingTime, "lockingTime: 'lockingTime' cannot be greater than 'additionalLockedTime'");
        /*추가잠금 시간에 전송 가능한 퍼센트(%) == 0  / 맞지않으면 에러표시*/
        require(_additionalLockedAmount[account][lockingTime] == 0, "lockingTime: 'be already set");
        /*100 >= 추가잠김 특정%  / 맞지않으면 에러표시*/
        require(100 >= percentageAvailable, "percentageAvailable: 'percentageAvailable' cannot be greater than '100%' cent");
        if (_lockedAddressInfo[account].additionalLockWhether == false) {
            _lockedAddressInfo[account].additionalLockWhether = true;
        }
        _additionalLockedTime[account].push(lockingTime);
        _additionalLockedAmount[account][lockingTime] = percentageAvailable;
        _sort(account);
        emit Locked(account,lockingTime,_lockedAddressInfo[account].totalTransferAmount,percentageAvailable);
    }
    function additionalLockDelete(address account, uint256 lockingTime) whenNotPaused onlyOwner external {
        /*추가잠김여부 == true  / 맞지않으면 에러표시*/
        require(_lockedAddressInfo[account].additionalLockWhether == true, "additionalLockWhether: 'additionalLockWhether' is 'false'");   
        /*추가잠김시간의 특정 % != 0  / 맞지않으면 에러표시*/
        require(_additionalLockedAmount[account][lockingTime] != 0, "lockingTime: 'be already set");
        if (_additionalLockedTime[account].length == 1){
            if (_lockedAddressInfo[account].lockingTime > _blockTimestamp()){
                _lockedAddressInfo[account].additionalLockWhether = false;
            } else {
                emit Unlocked(account,_lockedAddressInfo[account].lockingTime,_lockedAddressInfo[account].totalTransferAmount,0);
                _lockedInfoChange(account,0,_lockedAddressInfo[account].totalTransferAmount,false,false);
            }
            delete _additionalLockedTime[account];
        } else {
            _delete(account, lockingTime);
        }
        emit Unlocked(account,lockingTime,_lockedAddressInfo[account].totalTransferAmount,_additionalLockedAmount[account][lockingTime]);
        _additionalLockedAmount[account][lockingTime] = 0;
    }
    function _sort(address account) internal {
        uint length = _additionalLockedTime[account].length;
        for(uint i=0; i<length-1; i++){
            for(uint j=0; j<length-1; j++){
                if(_additionalLockedTime[account][j] > _additionalLockedTime[account][j+1]){
                uint current_value = _additionalLockedTime[account][j];
                _additionalLockedTime[account][j] = _additionalLockedTime[account][j+1];
                _additionalLockedTime[account][j+1] = current_value;
                }
            }
        }
    }
    function _delete(address account, uint256 lockingTime) internal {
        uint length = _additionalLockedTime[account].length;
        for(uint j=0; j<length-1; j++){
            if (_additionalLockedTime[account][j] == lockingTime){
                for (uint i = j; i<_additionalLockedTime[account].length-1; i++){
                    _additionalLockedTime[account][i] = _additionalLockedTime[account][i+1];
                }
                delete _additionalLockedTime[account][_additionalLockedTime[account].length-1];
                length--;
            }
        }
    }


    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


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
        /*소유자의 승인하에 지출자가 현재 사용할수 있는 토큰양(currentAllowance) > 감소시킬 개수(subtractedValue)  / 맞지않으면 에러표시*/
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual onlyOwner {
        /*컨트랙트 배포자 주소(account) != 0X00...  / 맞지않으면 에러표시*/
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] = amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        /*컨트랙트 호출자의 주소(account) != 0X00...  / 맞지않으면 에러표시*/
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        /*컨트랙트 호출자의 토큰양(accountBalance) >= 소각할양(amount)  / 맞지않으면 에러표시*/
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        emit Transfer(account, address(0), amount);
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        bool _lockWhether = _lockedAddressInfo[from].lockWhether;
        bool _additionalLockWhether = _lockedAddressInfo[from].additionalLockWhether;
        if (_lockWhether == true &&  _additionalLockWhether == false){
            if (_balances[from]-_lockedAddressInfo[from].totalTransferAmount < amount){
                /*현재블록타임스탬프 >= 지갑잠김종료시간  / 맞지않으면 에러표시*/
                require(_blockTimestamp() >_lockedAddressInfo[from].lockingTime, "ERC20: It is possible after 'locktime'");
            } 
        } else if(_lockWhether == true &&  _additionalLockWhether == true){
            /*현재블록타임스탬프 >= 지갑잠김종료시간  / 맞지않으면 에러표시*/
            require(_blockTimestamp() >_lockedAddressInfo[from].lockingTime, "ERC20: It is possible after 'locktime'");
            uint length = _additionalLockedTime[from].length;
            for(uint j=0; j<length-1; j++){
                if (_additionalLockedTime[from][0] > _blockTimestamp()){
                    uint256 lockTimeDelete = _additionalLockedTime[from][0];
                    emit Unlocked(from,lockTimeDelete,_lockedAddressInfo[from].totalTransferAmount,_additionalLockedAmount[from][lockTimeDelete]);
                    _additionalLockedAmount[from][lockTimeDelete] = 0;
                    for (uint i = j; i<_additionalLockedTime[from].length-1; i++){
                        _additionalLockedTime[from][i] = _additionalLockedTime[from][i+1];
                    }
                    delete _additionalLockedTime[from][_additionalLockedTime[from].length-1];
                    length--;
                }
            }
            if (_additionalLockedTime[from].length == 0){
                emit Unlocked(from,_lockedAddressInfo[from].lockingTime,_lockedAddressInfo[from].totalTransferAmount,0);
                _lockedInfoChange(from,0,_lockedAddressInfo[from].totalTransferAmount,false,false);
            }
            /*현재블록타임스탬프 >= 지갑잠김종료시간  / 맞지않으면 에러표시*/
            require((_lockedAddressInfo[from].totalTransferAmount*_additionalLockedAmount[from][_additionalLockedTime[from][0]])/100 >= _lockedAddressInfo[from].totalTransferAmount-_balances[from]+amount , "ERC20: You cannot transfer more than 'availableAmount'");
        } 
        uint256 fromBalance = _balances[from];
        /*전송하는주소(from) != 0X00...  / 맞지않으면 에러표시*/
        require(from != address(0), "ERC20: transfer from the zero address");
        /*받는주소(to) != 0X00...  / 맞지않으면 에러표시*/
        require(to != address(0), "ERC20: transfer to the zero address");
        /*전송하는 주소 토큰양(fromBalance) >= 전송하려는토큰양(amount)  / 맞지않으면 에러표시*/
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /*소유자주소(owner) != 0X00...  / 맞지않으면 에러표시*/
        require(owner != address(0), "ERC20: approve from the zero address");
        /*지출자주소(spender) != 0X00...  / 맞지않으면 에러표시*/
        require(spender != address(0), "ERC20: approve to the zero address");
        /*지출자주소(spender) != 0X00...  / 맞지않으면 에러표시*/
        require(_balances[owner] >= amount, "ERC20: transfer amount exceeds balance");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            /*소유자의 승인하에 지출자가 현재 사용할수 있는 토큰양(currentAllowance) >= 전송하려는토큰양(amount)  / 맞지않으면 에러표시*/
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}




contract test_coin is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function burn(uint256 amount) whenNotPaused public {
      _burn(_msgSender(), amount);
      _totalSupply -= amount;
    }
    constructor() {
        _name = "Testaaaaazzz";
        _symbol = "Testaaaazzz";
        _decimals = 2;
        _totalSupply = 100000000;
        _mint(_msgSender(), _totalSupply);
    }
}