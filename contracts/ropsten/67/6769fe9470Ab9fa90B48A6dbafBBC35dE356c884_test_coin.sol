/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)


pragma solidity ^0.8.0;




/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    실행 내부 정보
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _blockTimestamp() internal view virtual returns (uint) {
        return block.timestamp;
    }
}
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    ERC20 기능
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    ERC20 토큰설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
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
        _owner = _msgSender();
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function owner() external view returns (address) {
        return _owner;
    }
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    function paused() external view returns (bool) {
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
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                스마트 컨트랙트 기능
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
contract ERC20 is Context, IERC20, Ownable, Pausable {


    mapping(address => uint128) private _totalTransferAmount;
    mapping(address => uint64[]) private _lockedTime;
    mapping(address => mapping(uint64 => uint8)) private _transferAllowedPercent;
    event Locked(address indexed to, uint64 indexed lockingTime, uint128 totalTransferAmount, uint8 transferAllowedPercent);
    event LockedChange(address indexed to, uint64 indexed changeLockingTime, uint64 previousLockingTime, uint128 totalTransferAmount, uint8 transferAllowedPercent);
    event Unlocked(address indexed to, uint64 indexed lockingTime, uint128 totalTransferAmount, uint8 percentageAvailable);
    event everyUnlocked(address indexed to);




    modifier lastLockCleanup(address account) {
        /*만약 지갑잠금 목록이 1개 이상이고 지갑잠금목록[가장 마지막 잠금시간]보다 현재시간이 더 크면 */
        if (_lockedTime[account].length > 0 && _lockedTime[account][_lockedTime[account].length-1] < _blockTimestamp()) {
            delete _lockedTime[account];
            emit everyUnlocked(account);
        }
        _;
    }
    function lockBalanceOf(address account) external view returns (bool lockWhether,uint64[] memory LockTimeList,uint64[] memory percentageAvailableList,uint128 lockCriteriaAmount,uint64 currentLockTime,uint128 currentLockAmount,uint256 availableBalanceOf){
        uint _blockTimestamp = _blockTimestamp();
        uint64[] memory _lockedTimeList = _lockedTime[account];
        uint64[] memory _percentageAvailableList = _lockedTime[account];
        uint _lockedTimeListLength = _lockedTimeList.length;
        uint num;
        for (uint32 i=0; i<_lockedTimeListLength; i++){
            if (_lockedTimeList[0] <= _blockTimestamp){
                for (uint32 j = 0; j<_lockedTimeList.length-1; j++){
                    _lockedTimeList[j] = _lockedTimeList[j+1];
                    _percentageAvailableList[j] = _percentageAvailableList[j+1];
                }
                assembly { mstore(_lockedTimeList, sub(mload(_lockedTimeList), 1)) }
                assembly { mstore(_percentageAvailableList, sub(mload(_percentageAvailableList), 1)) }
            } else {
                _percentageAvailableList[num] = _transferAllowedPercent[account][_percentageAvailableList[num]];
                num ++;
            }
        }
        if (_lockedTimeList.length == 0){
            lockWhether = false;
            LockTimeList = _lockedTimeList;
            percentageAvailableList = _percentageAvailableList;
            lockCriteriaAmount = 0;
            currentLockTime = 0;
            currentLockAmount = 0;
            availableBalanceOf = _balances[account];
        } else {
            lockWhether = true;
            LockTimeList = _lockedTimeList;
            percentageAvailableList = _percentageAvailableList;
            lockCriteriaAmount = _totalTransferAmount[account];
            currentLockTime = _lockedTimeList[0];
            currentLockAmount = lockCriteriaAmount*(100-_transferAllowedPercent[account][currentLockTime])/100;
            availableBalanceOf = _balances[account]-currentLockAmount;
        }
    }



    function transferAndLock(uint32 transferLockingTime, address to, uint128 amount) whenNotPaused onlyOwner external {
        /*지갑잠글 시간 > 현재시간  / 맞지않으면 에러표시*/
        require(transferLockingTime > _blockTimestamp(), "transferLockingTime:'transfer locking Time' must be greater than 'current time'");
        /*만약 지갑잠금 목록이 2개 이상이고 현재시간이 지갑잠금목록[가장 마지막 잠금시간]보다 더 크면 */
        if (_lockedTime[to].length > 1 && _blockTimestamp() > _lockedTime[to][_lockedTime[to].length-1]) {
            delete _lockedTime[to];
            emit everyUnlocked(to);
        } else if (_lockedTime[to].length > 1) {
            /*지갑잠금목록[1번째] > 지갑잠글 시간  / 맞지않으면 에러표시*/
            require(_lockedTime[to][1] > transferLockingTime , "transferLockingTime:'transfer locking Time' must be less than 'additiona locking time'");  
        }
        /*만약 지갑잠금이 되어있지 않으면*/
        if (_lockedTime[to].length == 0){
            emit Locked(to,transferLockingTime,_totalTransferAmount[to],0);
            _lockedTime[to].push(transferLockingTime);
        } else {
            /*지갑잠금목록[0번째 잠금시간의 전송가능한 퍼센트(%)] == 0 / 맞지않으면 에러표시*/
            require(_transferAllowedPercent[to][_lockedTime[to][0]] == 0 , "LockingTime:'Add locking time' is specified and 'transfer locking time' is not specified");
            emit LockedChange(to,transferLockingTime,_lockedTime[to][0],_totalTransferAmount[to],0);
            _lockedTime[to][0] = transferLockingTime;
        }
        if (_transferAllowedPercent[to][transferLockingTime] != 0){
            _transferAllowedPercent[to][transferLockingTime] = 0;
        }
        _transfer(_msgSender(), to, amount);
        _totalTransferAmount[to] = _totalTransferAmount[to]+amount;
    } 
    function addLock(uint32 addLockingTime, address account, uint8 transferAllowedPercent) whenNotPaused onlyOwner lastLockCleanup(account) external {
        /*지갑잠금목록 길이 > 0  / 맞지않으면 에러표시*/
        require(_lockedTime[account].length > 0, "lockingTime:'locking time' is not set");
        /*추가잠금시간 > 지갑잠금목록[가장 마지막 잠금시간]  / 맞지않으면 에러표시*/
        require(addLockingTime > _lockedTime[account][_lockedTime[account].length-1], "addLockingTime:Must be greater than the previous lockout time"); 
        /*100 >= 설정할 전송가능한 퍼센트(%)  &&  설정할 전송가능한 퍼센트(%) >= 가장 마지막에 설정한 전송가능한 퍼센트(%)  / 맞지않으면 에러표시*/
        require(100 >= transferAllowedPercent && transferAllowedPercent > _transferAllowedPercent[account][_lockedTime[account][_lockedTime[account].length-1]], "transferAllowedPercent:It must be less than 'Previous transfer Allowed Percent'"); 
        _lockedTime[account].push(addLockingTime);
        _transferAllowedPercent[account][addLockingTime] = transferAllowedPercent;
        emit Locked(account,addLockingTime,_totalTransferAmount[account],transferAllowedPercent);
    }
    function everyLockDelete(address account) whenNotPaused onlyOwner external {
        /*지갑잠금목록 길이 > 0  / 맞지않으면 에러표시*/
        require(_lockedTime[account].length > 0, "lockingTime:'locking time' is not set");
        delete _lockedTime[account];
        emit everyUnlocked(account);
    }
    function specificLockDelete(uint32 lockingTime, address account) whenNotPaused onlyOwner lastLockCleanup(account) external {
        /*지갑잠금목록 길이 > 0  / 맞지않으면 에러표시*/
        require(_lockedTime[account].length > 0, "lockingTime:'locking time' is not set");
        uint8 Whether;
        uint _lockedTimeLength = _lockedTime[account].length;
        for (uint32 i=0; i<_lockedTimeLength; i++){
            if (_lockedTime[account][0] == lockingTime || _lockedTime[account][0] <= _blockTimestamp()){
                Whether = 1;
                emit Unlocked(account,_lockedTime[account][0],_totalTransferAmount[account],_transferAllowedPercent[account][_lockedTime[account][0]]);
                for (uint32 j=0; j<_lockedTime[account].length-1; j++){
                    _lockedTime[account][j] = _lockedTime[account][j+1];
                }
                _lockedTime[account].pop();
            }
        }
        /* 추가잠금을 해제할 시간의 비교값이 != 0  / 맞지않으면 에러표시*/
        require(Whether != 0, "Whether: There is no 'locking Time'"); 
    }
    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                        ERC20 기능
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
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
        /*만약 지갑잠금이 되어있으면*/
        if (_lockedTime[from].length > 0){
            /*만약 마지막에 설정된 지갑잠금 시간보다 현재시간이 더 지났으면*/
            if (_lockedTime[from][_lockedTime[from].length-1] <_blockTimestamp()){
                delete _lockedTime[from];
                emit everyUnlocked(from);
            } else {
                uint _lockedTimeLength = _lockedTime[from].length;
                for (uint32 i=0; i<_lockedTimeLength; i++){
                    if (_lockedTime[from][0] <= _blockTimestamp()){
                        emit Unlocked(from,_lockedTime[from][0],_totalTransferAmount[from],_transferAllowedPercent[from][_lockedTime[from][0]]);
                        for (uint32 j=0; j<_lockedTime[from].length-1; j++){
                            _lockedTime[from][j] = _lockedTime[from][j+1];
                        }
                        _lockedTime[from].pop();
                    }
                } 
                /*현재 사용가능한 토큰양 >= 전송하는 토큰양  / 맞지않으면 에러표시*/
                require(_balances[from]-(_totalTransferAmount[from]*(100-_transferAllowedPercent[from][_lockedTime[from][0]])/100) >= amount,"ERC20: transfer lock amount exceeds balance");
            }
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
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                스마트 컨트랙트 배포
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/
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
        _name = "Test";
        _symbol = "Test";
        _decimals = 2;
        _totalSupply = 100000000;
        _mint(_msgSender(), _totalSupply);
    }
}