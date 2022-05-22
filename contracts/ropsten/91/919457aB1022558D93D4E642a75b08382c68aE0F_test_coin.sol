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
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                컨트랙트의 소유자에 대한 권한
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*/
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
/*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                기능 일시중지/일시중지 해제
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*/
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
    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    특정지갑의 LOCK 에 대한 설명 
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    */
    struct lockedInfo {
        uint32 lockupTime;
        uint128 totalTransferAmount; 
        bool lockWhether;
    } 
    mapping(address => lockedInfo) private _lockedWalletInfo;
    mapping(address => uint32[]) private _lockedTime;
    mapping(address => mapping(uint32 => uint8)) private _transferAllowedPercent;
    event Locked(address indexed to, uint32 indexed lockingTime, uint128 totalTransferAmount, uint8 transferAllowedPercent);
    event LockedChange(address indexed to, uint32 indexed changeLockingTime, uint32 previousLockingTime, uint128 totalTransferAmount, uint8 transferAllowedPercent);
    event Unlocked(address indexed to, uint32 indexed lockingTime, uint128 totalTransferAmount, uint8 percentageAvailable);




    modifier LockCleanup(address account) {
        if (_lockedWalletInfo[account].lockWhether == true){
            uint _lockedTimeLength = _lockedTime[account].length;
            for (uint32 i=0; i<_lockedTimeLength; i++){
                if (_lockedTime[account][0] <= _blockTimestamp()){
                    emit Unlocked(account,_lockedTime[account][0],_lockedWalletInfo[account].totalTransferAmount,_transferAllowedPercent[account][_lockedTime[account][0]]);
                    for (uint32 j=0; j<_lockedTime[account].length-1; j++){
                        _lockedTime[account][j] = _lockedTime[account][j+1];
                    }
                    _lockedTime[account].pop();
                }
            }
            if (_lockedTime[account].length == 0){
                _lockedWalletInfo[account].lockWhether = false;
            }
        }
        _;
    }
    function lockBalanceOf(address account) external view returns (bool lockWhether,uint32[] memory LockTimeList,uint32 currentLockTime,uint128 currentLockAmount,uint256 availableBalanceOf){
        uint _blockTimestamp = _blockTimestamp();
        uint32[] memory _lockedTimeList = _lockedTime[account];
        uint _lockedTimeListLength = _lockedTimeList.length;
        for (uint32 i=0; i<_lockedTimeListLength; i++){
            if (_lockedTimeList[0] <= _blockTimestamp){
                for (uint32 j = 0; j<_lockedTimeList.length-1; j++){
                    _lockedTimeList[j] = _lockedTimeList[j+1];
                }
                assembly { mstore(_lockedTimeList, sub(mload(_lockedTimeList), 1)) }
            }
        }
        if (_lockedTimeList.length == 0 || _lockedWalletInfo[account].lockWhether == false){
            lockWhether = false;
            LockTimeList = _lockedTimeList;
            currentLockTime = 0;
            currentLockAmount = 0;
            availableBalanceOf = _balances[account];
        } else {
            lockWhether = true;
            LockTimeList = _lockedTimeList;
            currentLockTime = _lockedTimeList[0];
            currentLockAmount = _lockedWalletInfo[account].totalTransferAmount*(100-_transferAllowedPercent[account][currentLockTime])/100;
            // currentLockAmount = _lockedWalletInfo[account].totalTransferAmount-((_lockedWalletInfo[account].totalTransferAmount*_transferAllowedPercent[account][currentLockTime])/100);
            availableBalanceOf = _balances[account]-currentLockAmount;
        }
    }
    // function specificLockSearch(address account, uint32 searchLockingTime) external view returns (bool lockWhether,uint32 searchLockTime,uint128 lockCriteriaAmount,uint8 lockRatio,uint128 lockAmount){
    //     uint8 _index;
    //     uint8 _Whether = 111;
    //     for (uint8 i=0; i< _lockedTime[account].length; i++){
    //         if (_lockedTime[account][i] == searchLockingTime && _lockedTime[account][i] > _blockTimestamp()){
    //             _index = i;
    //             _Whether = 222;
    //         }
    //     }
    //     if (_Whether == 111 ){
    //         lockWhether = false;
    //         searchLockTime = searchLockingTime;
    //         lockCriteriaAmount = 0;
    //         lockRatio = 0;
    //         lockAmount = 0;
    //     } else{
    //         lockWhether = true;
    //         searchLockTime = searchLockingTime;
    //         lockCriteriaAmount = _lockedWalletInfo[account].totalTransferAmount;
    //         lockRatio = 100-_transferAllowedPercent[account][_lockedTime[account][_index]];
    //         lockAmount = _lockedWalletInfo[account].totalTransferAmount-((_lockedWalletInfo[account].totalTransferAmount*_transferAllowedPercent[account][_lockedTime[account][_index]])/100);
    //     }
    // }
    function transferAndLock(address to, uint128 amount, uint32 lockingTime) whenNotPaused onlyOwner external {
        /*지갑주소의 전송기능을 잠그는 시간 > 블록 타임스탬프  / 맞지않으면 에러표시*/
        require(lockingTime > _blockTimestamp(), "lockingTime: 'lockingTime' must be greater than 'blockTimestamp'");
        if (_lockedWalletInfo[to].lockWhether == false){
            emit Locked(to,lockingTime,_lockedWalletInfo[to].totalTransferAmount,0);
            _lockedWalletInfo[to].lockWhether = true;
            _lockedTime[to].push(lockingTime);
        } else {
            if (_lockedTime[to].length > 1){
                /*추가잠금시간[index_1] > 지갑주소의 전송기능을 잠그는 시간   / 맞지않으면 에러표시*/
                require(_lockedTime[to][1] > lockingTime , "lockingTime: 'lockingTime' must be greater than 'blockTimestamp'");
            }
            /*전송불가능한 잠금시간(_lockedTime[to][첫번째]) == 전송불가능한 잠금시간  / 맞지않으면 에러표시*/
            require(_lockedTime[to][0] == _lockedWalletInfo[to].lockupTime, "lockingTime: 'lockingTime' is not on the 'lockingTimeList'");
            emit LockedChange(to,lockingTime,_lockedTime[to][0],_lockedWalletInfo[to].totalTransferAmount,0);
            _lockedTime[to][0] = lockingTime;
        }
        if (_transferAllowedPercent[to][lockingTime] != 0){
            _transferAllowedPercent[to][lockingTime] = 0;
        }
        _transfer(_msgSender(), to, amount);
        _lockedWalletInfo[to].totalTransferAmount = _lockedWalletInfo[to].totalTransferAmount+amount;
        _lockedWalletInfo[to].lockupTime = lockingTime;
    }
    function additionalLock(address account, uint32 lockingTime, uint8 transferAllowedPercent) whenNotPaused onlyOwner external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedWalletInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        /*지갑주소의 추가잠금 시간 > 가장 마지막 잠금시간 / 맞지않으면 에러표시*/
        require(lockingTime > _lockedTime[account][_lockedTime[account].length-1], "lockingTime: 'lockingTime' should be bigger"); 
        /*설정할 전송가능한 퍼센트(%) <= 100  && 설정할 전송가능한 퍼센트(%) >= 이전 전송가능한 퍼센트(%)   / 맞지않으면 에러표시*/
        require(transferAllowedPercent <= 100  && transferAllowedPercent > _transferAllowedPercent[account][_lockedTime[account][_lockedTime[account].length-1]], "transferAllowedPercent: 'transferAllowedPercent' should be bigger"); 
        _lockedTime[account].push(lockingTime);
        _transferAllowedPercent[account][lockingTime] = transferAllowedPercent;
        emit Locked(account,lockingTime,_lockedWalletInfo[account].totalTransferAmount,transferAllowedPercent);
    }
    function everyLockDelete(address account) whenNotPaused onlyOwner external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedWalletInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        for (uint i=0; i<_lockedTime[account].length; i++){
            emit Unlocked(account,_lockedTime[account][i],_lockedWalletInfo[account].totalTransferAmount,_transferAllowedPercent[account][_lockedTime[account][i]]);
        }
        delete _lockedTime[account];
        _lockedWalletInfo[account].lockWhether = false;
    }
    function specificLockDelete(address account, uint32 lockingTime) whenNotPaused onlyOwner external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedWalletInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        uint8 Whether;
        for (uint i=0; i<_lockedTime[account].length; i++){
            if(_lockedTime[account][i] == lockingTime){
                Whether = 1;
                for (uint j = i; j<_lockedTime[account].length-1; j++){
                    _lockedTime[account][j] = _lockedTime[account][j+1];
                }
                emit Unlocked(account,lockingTime,_lockedWalletInfo[account].totalTransferAmount,_transferAllowedPercent[account][lockingTime]);
                _lockedTime[account].pop();
            }
        }
        /* 추가잠금을 해제할 시간의 비교값이 != 0  / 맞지않으면 에러표시*/
        require(Whether != 0, "Whether: There is no 'locking Time'");
        if (_lockedTime[account].length == 0) {
            _lockedWalletInfo[account].lockWhether = false;
        }
    }
    function lastLockCleanup(address account) whenNotPaused onlyOwner LockCleanup(account) external {
        /*잠금여부 == true  / 맞지않으면 에러표시*/
        require(_lockedWalletInfo[account].lockWhether == true, "lockWhether: 'lockWhether' is 'false'");
        require(_lockedTime[account][0] < _blockTimestamp(), "lastLockCleanup: 'There's nothing to organize");
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
    function _transfer(address from, address to, uint256 amount) LockCleanup(from) internal virtual {
        if (_lockedWalletInfo[from].lockWhether == true){
            require(_balances[from]-(_lockedWalletInfo[from].totalTransferAmount*(100-_transferAllowedPercent[from][_lockedTime[from][0]])/100) >= amount,"ERC20: transfer lock amount exceeds balance");
            // require(_balances[from]-(_lockedWalletInfo[from].totalTransferAmount-((_lockedWalletInfo[from].totalTransferAmount*_transferAllowedPercent[from][_lockedTime[from][0]])/100)) >= amount,"ERC20: transfer lock amount exceeds balance");
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