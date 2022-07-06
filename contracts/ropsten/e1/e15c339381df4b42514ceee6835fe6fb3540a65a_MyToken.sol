/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;


/*
openzeppelin 계약생성기 ) https://wizard.openzeppelin.com/
설정값 : Burnable,Pausable,Ownable,Transparent
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddressUpgradeable ) 주소 유형과 관련된 함수 모음
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/utils/AddressUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Initializable ) 업그레이드 가능한 계약 또는 프록시 뒤에 배치될 모든 종류의 계약을 작성하는 데 도움이 되는 기본 계약
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/proxy/utils/Initializable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ContextUpgradeable ) 트랜잭션의 보낸 사람 및 해당 데이터를 포함하여 현재 실행 컨텍스트에 대한 정보를 제공  
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/utils/ContextUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OwnableUpgradeable ) 특정 기능에 대한 독점적 액세스 권한을 부여할 수 있는 계정(소유자)이 있는 경우 기본 액세스 제어 메커니즘을 제공하는 계약 모듈
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/access/OwnableUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IERC20Upgradeable ) EIP에 정의된 ERC20 표준의 인터페이스
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/IERC20Upgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IERC20MetadataUpgradeable ) ERC20 표준의 선택적 메타데이터 기능을 위한 인터페이스
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ERC20Upgradeable ) {IERC20} 인터페이스 구현
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/ERC20Upgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ERC20BurnableUpgradeable ) 토큰 소유자가 (이벤트 분석을 통해) 오프 체인(off-chain)으로 인식할 수 있는 방식으로 토큰 소유자가 자신의 토큰과 허용 가능한 토큰을 모두 폐기할 수 있는 {ERC20}의 확장
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PausableUpgradeable ) 인증된 계정에 의해 트리거될 수 있는 비상 중지 메커니즘을 구현할 수 있는 계약 모듈
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/security/PausableUpgradeable.sol
*/



library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}
interface IERC20Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, OwnableUpgradeable {
    /*=================================================================
    ERC20 표준 인터페이스(_transfer,_approve에 ECC에 필요한 기능 추가)
    =================================================================*/
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(!_freezingStatus[from], "It's a frozen from address");
        require(!_freezingStatus[to], "It's a frozen to Address");
        if (_lock[from].initialLockList.length != 0) {
            uint128 initialAmount; 
            uint128 additionalAmount; 
            for (uint8 i=0; i<_lock[from].initialLockList.length;){ 
                uint32 idx_initialLock = _lock[from].initialLockList[i];
                uint128 initialLockAmount = _initialLock[from][idx_initialLock].initialLockAmount;
                uint128 idx_unlockAmount ;
                uint128 comparisonAmount;
                unchecked { initialAmount += initialLockAmount;}
                for (uint8 j=0; j< _initialLock[from][idx_initialLock].additionalLockList.length;){
                    uint128 lockTime = _initialLock[from][idx_initialLock].additionalLockList[j];
                    if (lockTime < block.timestamp) {
                        unchecked { idx_unlockAmount += _initialLock[from][idx_initialLock]._additionalLock[lockTime].additionalLockAmount;}
                    }
                    unchecked{ comparisonAmount += _initialLock[from][idx_initialLock]._additionalLock[lockTime].additionalLockAmount;}
                    unchecked {j ++;}
                }
                if (idx_unlockAmount == initialLockAmount || comparisonAmount == 0 && idx_initialLock < block.timestamp) {
                    emit unlock(from,idx_initialLock,initialLockAmount);
                    idx_unlockAmount = initialLockAmount;
                    delete _lock[from].initialLockList[i]; 
                }
                unchecked {additionalAmount += idx_unlockAmount;}
                unchecked {i ++;}
            }
            if (initialAmount == additionalAmount) {
                delete _lock[from].initialLockList;
            }
            require(_balances[from]-(initialAmount-additionalAmount) >= amount,"Transmittable amount exceeded");  
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
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
    function _approve( address owner, address spender, uint256 amount) internal virtual {
        require(!_freezingStatus[owner], "It's a frozen owner address");
        require(!_freezingStatus[spender], "It's a frozen spender Address");
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
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
    /*=================================================================
    ECC에 필요한 기능
    ===================================================================
    //////////////////////////////struct//////////////////////////////
    @ dev additionalLockInfo : 추가잠금정보
    _initialLock[특정지갑주소][최초잠금시간]._additionalLock[추가잠금시간].additionalLockIndex : 리스트에 저장되어있는 추가잠금 위치
    _initialLock[특정지갑주소][최초잠금시간]._additionalLock[추가잠금시간].additionalLockAmount : 추가잠금 금액
    @ dev initialLockInfo : 최초잠금정보
    _initialLock[특정지갑주소][최초잠금시간].initialLockIndex = 리스트에 저장되어있는 최초잠금 위치
    _initialLock[특정지갑주소][최초잠금시간].initialLockAmount = 최초잠금금액
    _initialLock[특정지갑주소][최초잠금시간].additionalLockTotalAmount = 추가잠금 총금액
    _initialLock[특정지갑주소][최초잠금시간].additionalLockList[] = 추가잠금리스트
    _initialLock[특정지갑주소][최초잠금시간]._additionalLock[추가잠금시간] = 추가잠금정보
    @ dev lockInfo : 기본잠금정보
    _lock[특정지갑주소].whiteListWhether = 화이트리스트여부
    _lock[특정지갑주소].initialLockList[] = 최초잠금리스트

    //////////////////////////////mapping//////////////////////////////
    @ dev _initialLock : 최초잠금정보
    @ dev _lock : 기본잠금정보
    @ dev _freezingStatus : 지갑동결여부

    //////////////////////////////address[]//////////////////////////////
    @ dev _whitelist : 화이트리스트

    //////////////////////////////function//////////////////////////////
    @ dev whiteList : 화이트리스트목록
    @ dev InitialLockedList : 최초잠금목록
    @ dev additionalLockedList : 추가잠금목록
    @ dev initialLock_Addition : 최초잠금
    @ dev initialLock_Delete : 최초잠금 삭제
    @ dev additionalLock_Addition : 추가잠금
    @ dev additionalLock_Change : 추가잠금 변경
    @ dev additionalLock_Delete : 추가잠금 삭제
    @ dev addressFreeze : 특정지갑동결
    @ dev addressUnfreeze : 특정지갑동결해제
    */
    struct additionalLockInfo {
        uint32 additionalLockIndex;
        uint128 additionalLockAmount;
    }
    struct initialLockInfo {
        uint8 initialLockIndex;
        uint128 initialLockAmount; 
        uint128 additionalLockTotalAmount;
        uint128[] additionalLockList;
        mapping(uint128 => additionalLockInfo) _additionalLock;
    }    
    struct lockInfo {
        bool whiteListWhether;
        uint32[] initialLockList;
    }
    mapping(address => mapping(uint32 => initialLockInfo)) private _initialLock;
    mapping(address => lockInfo) private _lock;
    mapping(address => bool) private _freezingStatus;
    address[] _whitelist;
    event lock(address account,uint32 initialLockTime,uint128 lockedAmount);
    event unlock(address account,uint32 initialLockTime,uint128 releaseAmount);
    event freeze(address account);
    event unfreeze(address account);

    function whiteList() external view returns (address[] memory) {
        return _whitelist;
    }
    function InitialLockedList(address account) external view returns (uint32[] memory lockTime) {
        lockTime = _lock[account].initialLockList;
    }  
    function additionalLockedList(address account, uint32 initialLockedTime) external view returns (uint128[] memory additionalLockedTime, uint128[] memory additionalLockedAmount, uint128 initialLockedAmount,uint128 additionalLockedTotalAmount, uint128 availableAmount) {
        uint128[] memory add_Lock = _initialLock[account][initialLockedTime].additionalLockList;
        uint128[] memory add_LockedAmount = _initialLock[account][initialLockedTime].additionalLockList;
        uint128 amount;
        uint128 comparisonAmount;
        for (uint8 i=0; i<add_Lock.length;){
            uint128 addLockAmount = _initialLock[account][initialLockedTime]._additionalLock[add_Lock[i]].additionalLockAmount;
            if (add_Lock[i] < block.timestamp) {
                unchecked{ amount += addLockAmount; }
            }  
            unchecked{ comparisonAmount += addLockAmount; }
            add_LockedAmount[i] = addLockAmount;
            unchecked{ i++; }
        }
        additionalLockedTime = add_Lock;
        additionalLockedAmount = add_LockedAmount;
        initialLockedAmount = _initialLock[account][initialLockedTime].initialLockAmount;
        additionalLockedTotalAmount = _initialLock[account][initialLockedTime].additionalLockTotalAmount;
        if (comparisonAmount == 0 && initialLockedTime < block.timestamp) {
            amount = initialLockedAmount;
        }
        availableAmount = amount;
    } 
    function initialLock_Addition(address to, uint32 initialLockedTime, uint128 initialLockedAmount) onlyOwner external returns (bool) { 
        require(_initialLock[to][initialLockedTime].initialLockAmount == 0 && initialLockedTime > block.timestamp,"Initial Locked Time is not correct");
        /*화이트리스트여부가 fasle라면 true로 바꾸고 화이트리스트에 추가*/
        if (!_lock[to].whiteListWhether){
            _lock[to].whiteListWhether = true;
            _whitelist.push(to);
        }
        /*최초잠금시간 위치를 입력한다*/
        _initialLock[to][initialLockedTime].initialLockIndex = uint8(_lock[to].initialLockList.length); 
        /*최초잠금리스트에 "최초잠금"을 추가한다*/
        _lock[to].initialLockList.push(initialLockedTime);
        /*최초잠금금액을 입력한다*/
        _initialLock[to][initialLockedTime].initialLockAmount = initialLockedAmount; 
        _transfer(_msgSender(), to, initialLockedAmount);
        emit lock(to,initialLockedTime,initialLockedAmount);
        return true;
    }  
    function initialLock_Delete(address account,uint32 initialLockedTime) onlyOwner external returns (bool)  { 
        uint128 initialLockAmount = _initialLock[account][initialLockedTime].initialLockAmount;
        require(initialLockAmount != 0,"initialLockedTime is not set");
        /*최초잠금리스트에 값 삭제*/
        delete _lock[account].initialLockList[_initialLock[account][initialLockedTime].initialLockIndex];
        /*추가잠금정보삭제*/
        for (uint32 i=0; i<_initialLock[account][initialLockedTime].additionalLockList.length;){
            delete _initialLock[account][initialLockedTime]._additionalLock[_initialLock[account][initialLockedTime].additionalLockList[i]];
            unchecked{ i++; }
        }
        /*최초잠금정보삭제*/
        delete _initialLock[account][initialLockedTime];
        emit unlock(account,initialLockedTime,initialLockAmount);
        return true;
    }
    function additionalLock_Addition(address account, uint32 initialLockedTime, uint128[] calldata additionalLockedTime, uint128[] calldata additionalLockedAmount) onlyOwner external returns (bool)  { 
        require(_initialLock[account][initialLockedTime].initialLockAmount != 0,"initialLockedTime is not set");
        require(additionalLockedTime.length == additionalLockedAmount.length ,"The length of the array is different");
        uint128 lockTotalAmount = _initialLock[account][initialLockedTime].additionalLockTotalAmount;
        uint128 addAmount;
        for (uint32 i=0; i<additionalLockedTime.length;){
            require(_initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime[i]].additionalLockAmount == 0 && additionalLockedTime[i] > initialLockedTime,"'initialLockedTime' is not correct");
            /*추가할 추가잠금금액 합*/
            unchecked{addAmount += additionalLockedAmount[i];}
            /*추가잠금정보를 입력한다(추가잠금리스트에 저장된 인덱스,추가잠금금액)*/
            _initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime[i]] = additionalLockInfo(uint32(_initialLock[account][initialLockedTime].additionalLockList.length),additionalLockedAmount[i]);
            /*추가잠금리스트에 "추가잠금"을 추가한다*/
            _initialLock[account][initialLockedTime].additionalLockList.push(additionalLockedTime[i]);
            unchecked{ i++; }
        }
        require(_initialLock[account][initialLockedTime].initialLockAmount >= lockTotalAmount+addAmount ,"AdditionalLockTotalAmount exceeded");
        /*추가잠금 총금액에 "기존 추가잠금 총금액"+"추가할 추가잠금금액 합"으로 값을 바꾼다*/
        _initialLock[account][initialLockedTime].additionalLockTotalAmount = lockTotalAmount+addAmount;
        return true;
    }
    // function additionalLock_Change(address account,uint32 initialLockedTime,uint32 additionalLockedTime,uint32 change_additionalLockedTime,uint128 change_additionalLockedAmount) onlyOwner external returns (bool)  { 
    //     uint128 initialLock_Amount = _initialLock[account][initialLockedTime].initialLockAmount;
    //     uint128 additionalLock_Amount = _initialLock[account][initialLockedTime].additionalLockTotalAmount;
    //     uint128 additionalLockTime_Amount = _initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime].additionalLockAmount;
    //     uint128 changeAmount = change_additionalLockedAmount+additionalLock_Amount-additionalLockTime_Amount;
    //     require(initialLock_Amount != 0,"initialLockedTime is not set");  
    //     require(additionalLockTime_Amount != 0,"additionalLockedTime is not set"); 
    //     require(initialLock_Amount >= changeAmount, "AdditionalLockTotalAmount exceeded");
    //     require(additionalLockedTime > block.timestamp || change_additionalLockedTime > block.timestamp, "blockTimestamp is smaller");
    //     /*추가잠금 총금액을 변경한다*/
    //     _initialLock[account][initialLockedTime].additionalLockTotalAmount = changeAmount;
    //     if (additionalLockedTime != change_additionalLockedTime) {
    //         require(_initialLock[account][initialLockedTime]._additionalLock[change_additionalLockedTime].additionalLockAmount == 0 ,"change_additionalLockedAmount is wrong");
    //         /*추가잠금시간리스트에서 추가잠금변경전시간을 추가잠금변경후시간으로 바꾼다*/
    //         _initialLock[account][initialLockedTime].additionalLockList[_initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime].additionalLockIndex] = change_additionalLockedTime;
    //         /*추가잠금시간변경후 추가잠금정보를 입력한다*/
    //         _initialLock[account][initialLockedTime]._additionalLock[change_additionalLockedTime] = additionalLockInfo(_initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime].additionalLockIndex,change_additionalLockedAmount);
    //         /*추가잠금시간변경전 추가잠금정보를 삭제한다*/
    //         delete _initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime];
    //     } else {
    //         /*추가잠금금액을 변경한다*/
    //         _initialLock[account][initialLockedTime]._additionalLock[change_additionalLockedTime].additionalLockAmount = change_additionalLockedAmount;
    //     }
    //     return true;
    // }
    function additionalLock_Delete(address account,uint32 initialLockedTime,uint32 additionalLockedTime) onlyOwner external returns (bool)  { 
        uint128 addLockAmount = _initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime].additionalLockAmount;
        require(_initialLock[account][initialLockedTime].initialLockAmount != 0 && addLockAmount != 0,"additionalLockedTime is not correct");
        /*추가잠금 총금액을 변경한다*/
        _initialLock[account][initialLockedTime].additionalLockTotalAmount = _initialLock[account][initialLockedTime].additionalLockTotalAmount-addLockAmount;
        /*추가잠금리스트에서 추가잠금시간을 삭제한다*/
        delete _initialLock[account][initialLockedTime].additionalLockList[_initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime].additionalLockIndex];
        /*추가잠금정보를 삭제한다*/
        delete _initialLock[account][initialLockedTime]._additionalLock[additionalLockedTime];
        return true;
    }
    function addressFreeze(address account) onlyOwner external {
        require(!_freezingStatus[account], "be already frozen");
        _freezingStatus[account] = true;
        emit freeze(account);
    }
    function addressUnfreeze(address account) onlyOwner external {
        require(_freezingStatus[account], "be already unfrozen");
        _freezingStatus[account] = false;
        emit unfreeze(account);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from,address to, uint256 amount) internal virtual {}
    uint256[31] private __gap;
}
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }
    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }
    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}
contract MyToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable {
    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        _mint(msg.sender, 20000000000 * 10 ** decimals());
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
}