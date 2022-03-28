/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.4.24;

/**
 * @dev SafeMath
 * Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) return 0;
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC20 is IERC165 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function decimals() public view returns (uint8);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    function safeTransfer(address recipient, uint256 amount, bytes memory data) public;
    function safeTransfer(address recipient, uint256 amount) public;
    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public;
    function safeTransferFrom(address sender, address recipient, uint256 amount) public;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IERC20Receiver {
    function onERC20Received(address _operator, address _from, uint256 _amount, bytes memory _data) public returns (bytes4);
}
// ----------------------------------------------------------------------------
// @title Ownable
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;

    event SetOwner(address owner);
    event SetMinter(address minter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner    = msg.sender;

        emit SetOwner(msg.sender);
        emit SetMinter(msg.sender);
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
// ----------------------------------------------------------------------------
// @title ERC20
// ----------------------------------------------------------------------------
contract ERC20 is ERC165, IERC20, Ownable {
    using SafeMath for uint256;
    
    event LockedInfo(address indexed from, address indexed to, uint256 value, uint8 tokenType, uint256 distributedTime, uint256 lockUpPeriodMonth, uint256 unlockAmountPerCount, uint256 remainUnLockCount, uint256 CONST_UNLOCKCOUNT);
    event ChangeListingTime(uint256 oldTime, uint256 newTime);
    event FinshedSetExchangeListingTime();

    struct LockInfo {
        bool isLocked;
        uint8 tokenType;
        uint256 amount;
        uint256 distributedTime;
        uint256 lockUpPeriodMonth;
        uint256 lastUnlockTimestamp;
        uint256 unlockAmountPerCount;
        uint256 remainUnLockCount;
        uint256 CONST_UNLOCKCOUNT;
        uint256 CONST_AMOUNT;
    }
    
    uint256 internal _totalSupply;
    uint8 private _decimals = 18;

    uint256 internal _tokenCreatedTime;
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping (address => uint256)) internal _allowances;

    mapping(address => uint8) internal _cardioWallet;
    mapping(address => mapping (uint8 => LockInfo)) internal _lockedInfo;

    bytes4 private constant _ERC20_RECEIVED = 0x9d188c22;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x65787371;

    constructor() public {
        _tokenCreatedTime = now;
        // Crowd Sale Wallet
        _cardioWallet[0x93f53B4C8ED2C0Cc84BdE1166B290998bAA0d005] = 1;
        // Team & Advisors
        _cardioWallet[0x0787bb893334FE0E6254a575B7D11E1009CBD2a3] = 2;
        // Ecosystem Activation
        _cardioWallet[0x3E5553619440A990f9227AB4557433e6AFCb1267] = 3;
        // Business Development
        _cardioWallet[0x0f1b039128d04891BC15137271F61c259B4f239D] = 4;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 totalBalances = _balances[account];
        uint8 tokenType;

        for (tokenType = 1; tokenType <= 4; tokenType++) {
            LockInfo memory lockInfo = _lockedInfo[account][tokenType];
            totalBalances = totalBalances.add(lockInfo.amount);
        }
        
        return totalBalances;
    }

    function unLockBalanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lockUpInfo(address account, uint8 tokenType) public view returns (bool, uint8, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        LockInfo memory lockInfo = _lockedInfo[account][tokenType];
        return (lockInfo.isLocked, lockInfo.tokenType, lockInfo.amount, lockInfo.distributedTime, lockInfo.lockUpPeriodMonth, lockInfo.lastUnlockTimestamp, lockInfo.unlockAmountPerCount, lockInfo.remainUnLockCount, lockInfo.CONST_UNLOCKCOUNT, lockInfo.CONST_AMOUNT);
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseApproval(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(amount));
        return true;
    }

    function decreaseApproval(address spender, uint256 amount) public returns (bool) {
        if (amount >= _allowances[msg.sender][spender]) {
            amount = 0;
        } else {
            amount = _allowances[msg.sender][spender].sub(amount);
        }

        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function safeTransfer(address recipient, uint256 amount) public {
        safeTransfer(recipient, amount, "");
    }

    function safeTransfer(address recipient, uint256 amount, bytes memory data) public {
        transfer(recipient, amount);
        require(_checkOnERC20Received(msg.sender, recipient, amount, data), "ERC20: transfer to non ERC20Receiver implementer");
    }
    
    function safeTransferFrom(address sender, address recipient, uint256 amount) public {
        safeTransferFrom(sender, recipient, amount, "");
    }

    function safeTransferFrom(address sender, address recipient, uint256 amount, bytes memory data) public {
        transferFrom(sender, recipient, amount);
        require(_checkOnERC20Received(sender, recipient, amount, data), "ERC20: transfer to non ERC20Receiver implementer");
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint8 adminAccountType = _cardioWallet[sender];
        // Crowd Sale Wallet, Team & Advisors from admin wallet Type 1, 2
        if(adminAccountType >= 1 && adminAccountType <= 2) {
            _addLocker(sender, recipient, adminAccountType, amount);
        } else {
            // Check "From" LockUp Balance
            uint8 tokenType;
            for (tokenType = 1; tokenType <= 4; tokenType++) {
                LockInfo storage lockInfo = _lockedInfo[sender][tokenType];
                if (lockInfo.isLocked) {
                    _unLock(sender, tokenType);
                }
            }
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _addLocker(address sender, address recipient, uint8 adminAcountType, uint256 amount) internal {
        require(_lockedInfo[recipient][adminAcountType].isLocked == false, "Already Locked User");
        
        uint256 distributedTime;
        uint256 lockUpPeriodMonth;
        uint256 unlockAmountPerCount;
        uint256 remainUnLockCount;
        uint256 CONST_UNLOCKCOUNT;
        uint256 CONST_AMOUNT;
        
        if(adminAcountType == 1) { // Crowd Sale
            distributedTime = now;
            lockUpPeriodMonth = 12;
            unlockAmountPerCount = amount.div(100);
            remainUnLockCount = 6;
            CONST_UNLOCKCOUNT = 5;
            CONST_AMOUNT = amount;
        } else { // Team & Advisors
            distributedTime = now;
            lockUpPeriodMonth = 20;
            unlockAmountPerCount = amount.div(40);
            remainUnLockCount = 40;
            CONST_UNLOCKCOUNT = 40;
            CONST_AMOUNT = amount;
        }
        
        LockInfo memory newLockInfo = LockInfo({
            isLocked: true,
            tokenType : adminAcountType,
            amount: amount,
            distributedTime: distributedTime,
            lockUpPeriodMonth: lockUpPeriodMonth,
            lastUnlockTimestamp: 0,
            unlockAmountPerCount: unlockAmountPerCount,
            remainUnLockCount: remainUnLockCount,
            CONST_UNLOCKCOUNT: CONST_UNLOCKCOUNT,
            CONST_AMOUNT: CONST_AMOUNT
        });
        
        _balances[sender] = _balances[sender].sub(amount);
        _lockedInfo[recipient][adminAcountType] = newLockInfo;
    }
    
    function _unLock(address sender, uint8 tokenType) internal {
        LockInfo storage lockInfo = _lockedInfo[sender][tokenType];

        // Only Crowd Sale Type
        // 518400 = 6 Days
        if(tokenType == 1 && lockInfo.remainUnLockCount == 6 && lockInfo.distributedTime.add(518400) <= now) {
            // lockInfo update
            lockInfo.remainUnLockCount = 5;

            // Fisrt Distribute 5%
            uint256 distributeAmount = lockInfo.unlockAmountPerCount.mul(50);
            lockInfo.amount = lockInfo.amount.sub(distributeAmount);
            _balances[sender] = _balances[sender].add(distributeAmount);
        }

        if(_isOverLockUpPeriodMonth((now.safeSub(lockInfo.distributedTime)), lockInfo.lockUpPeriodMonth) == false) {
            return;
        }

        uint256 blockTime = now;
        uint256 count = _getUnLockCount(blockTime, lockInfo);

        // None
        if(count == 0) return;
        uint256 unlockAmount;
        if(tokenType == 1) {
            unlockAmount = count.mul(lockInfo.unlockAmountPerCount.mul(10));
        } else {
            unlockAmount = count.mul(lockInfo.unlockAmountPerCount);
        }

        // Shortage due to burn token
        // or the last distribution
        uint256 remainUnLockCount = lockInfo.remainUnLockCount.safeSub(count);
        if (lockInfo.amount.safeSub(unlockAmount) == 0 || remainUnLockCount == 0) {
            unlockAmount = lockInfo.amount;
            lockInfo.isLocked = false;
        }
        
        // lockInfo update
        lockInfo.lastUnlockTimestamp = now;
        lockInfo.remainUnLockCount = remainUnLockCount;
        lockInfo.amount = lockInfo.amount.sub(unlockAmount);
        
        _balances[sender] = _balances[sender].add(unlockAmount);
    }
    
    function _getUnLockCount(uint256 curBlockTime, LockInfo lockInfo) internal pure returns (uint256) {
        // 1 Month = 30 Days 
        uint256 lockUpTime = lockInfo.lockUpPeriodMonth * 30 * 24 * 60 * 60;

        uint256 startTime = lockInfo.distributedTime.add(lockUpTime);
        uint256 count = 0;

        if (lockInfo.lastUnlockTimestamp == 0) {
            count = _convertMSToMonth(curBlockTime - startTime);
        } else {
            uint256 unLockedCount = _convertMSToMonth(curBlockTime - startTime);
            uint256 alreadyUnLockCount = lockInfo.CONST_UNLOCKCOUNT - lockInfo.remainUnLockCount;
            
            count = unLockedCount.safeSub(alreadyUnLockCount);
        }
        return count;
    }
    
    function _isOverLockUpPeriodMonth(uint256 time, uint256 period) internal pure returns (bool) {
        return _convertMSToMonth(time) > period;
    }
    
    function _convertMSToMonth(uint256 time) internal pure returns (uint256) {
        return time.div(60).div(60).div(24).div(30);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _checkOnERC20Received(address sender, address recipient, uint256 amount, bytes memory _data) internal returns (bool) {
        if (!isContract(recipient)) {
            return true;
        }
        bytes4 retval = IERC20Receiver(recipient).onERC20Received(msg.sender, sender, amount, _data);
        return (retval == _ERC20_RECEIVED);
    }
}
// ----------------------------------------------------------------------------
// @title Burnable Token
// @dev Token that can be irreversibly burned (destroyed).
// ----------------------------------------------------------------------------
contract BurnableToken is ERC20 {
    event BurnAdminAmount(address indexed burner, uint256 value);
    event BurnLockedToken(address indexed burner, uint256 value, uint8 tokenType);

    function burnAdminAmount(uint256 _value) onlyOwner public {
        require(_value <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
    
        emit BurnAdminAmount(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}
// ----------------------------------------------------------------------------
// @title Mintable token
// @dev Simple ERC20 Token example, with mintable token creation
// Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
// ----------------------------------------------------------------------------
contract MintableToken is ERC20 {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    uint256 ECOSYSTEM_AMOUNT = 5400000000 * (10**18);
    uint256 BUSINESSDEVELOPMENT_AMOUNT = 3000000000 * (10**18);
    bool private _mintingFinished = false;

    modifier canMint() { require(!_mintingFinished); _; }

    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    // Token Type - 1 : Crowd Sale
    // Token Type - 2 : Team & Advisors
    // Token Type - 3 : Ecosystem Activation
    // Token Type - 4 : Business Development
    function mint(address _to, uint256 _amount, uint8 _tokenType) onlyOwner canMint public returns (bool) {
        require(_tokenType < 5, "Token Type NULL");
        _totalSupply = _totalSupply.add(_amount);

        uint256 lockUpPeriodMonth;
        uint256 unlockAmountPerCount;
        uint256 remainUnLockCount;
        uint256 CONST_UNLOCKCOUNT;
        uint256 CONST_AMOUNT;

        // Ecosystem Activation
        if(_tokenType == 3) {
            lockUpPeriodMonth = 12;
            unlockAmountPerCount = ECOSYSTEM_AMOUNT.div(50);
            remainUnLockCount = 50;
            CONST_UNLOCKCOUNT = 50;
            CONST_AMOUNT = ECOSYSTEM_AMOUNT;
            
            LockInfo memory newLockInfoEA = LockInfo({
                isLocked: true,
                tokenType : _tokenType,
                amount: _amount,
                distributedTime: _tokenCreatedTime,
                lockUpPeriodMonth: lockUpPeriodMonth,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: unlockAmountPerCount,
                remainUnLockCount: remainUnLockCount,
                CONST_UNLOCKCOUNT: CONST_UNLOCKCOUNT,
                CONST_AMOUNT: CONST_AMOUNT
            });
            
            _lockedInfo[_to][_tokenType] = newLockInfoEA;
            
            emit LockedInfo(address(0), _to, _amount, _tokenType, _tokenCreatedTime, lockUpPeriodMonth, unlockAmountPerCount, remainUnLockCount, CONST_UNLOCKCOUNT);
        } else if(_tokenType == 4) {
            // Business Development
            lockUpPeriodMonth = 24;
            unlockAmountPerCount = BUSINESSDEVELOPMENT_AMOUNT.div(40);
            remainUnLockCount = 36;
            CONST_UNLOCKCOUNT = 36;
            CONST_AMOUNT = BUSINESSDEVELOPMENT_AMOUNT;
            
            LockInfo memory newLockInfoBD = LockInfo({
                isLocked: true,
                tokenType : _tokenType,
                amount: _amount,
                distributedTime: _tokenCreatedTime,
                lockUpPeriodMonth: lockUpPeriodMonth,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: unlockAmountPerCount,
                remainUnLockCount: remainUnLockCount,
                CONST_UNLOCKCOUNT: CONST_UNLOCKCOUNT,
                CONST_AMOUNT: CONST_AMOUNT
            });
            
            _lockedInfo[_to][_tokenType] = newLockInfoBD;
            
            emit LockedInfo(address(0), _to, _amount, _tokenType, _tokenCreatedTime, lockUpPeriodMonth, unlockAmountPerCount, remainUnLockCount, CONST_UNLOCKCOUNT);
        } else {
            _balances[_to] = _balances[_to].add(_amount);
        }

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }
}
// ----------------------------------------------------------------------------
// @Project CardioCoin
// ----------------------------------------------------------------------------
contract CardioCoin is MintableToken, BurnableToken {
    event SetTokenInfo(string name, string symbol);
    string private _name = "";
    string private _symbol = "";

    constructor() public {
        _name = "CardioCoin";
        _symbol = "CRDC";

        emit SetTokenInfo(_name, _symbol);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}