// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./TAVA.sol";
import "./Ownable.sol";

contract Vesting is Ownable{

    // address of tava token
    Tava public TavaToken;

    struct VestingStage {
        uint256 time;
        bool exists;
    }

    struct VestingforAddress {
        address receiver; 
        uint256 initialbalance;
        uint256 startTime;
        uint256 duration;   
        uint256 stageNum;

        uint256 stagesUnlockAmount;
        uint256 tokensSent;
        uint256 tokensToSend;

        bool valid;

        VestingStage[] stages;
    }

    VestingforAddress[] vestingforaddress; 

    uint256 vestingID;

    // event raised on each successful vesting transfer
    event successfulVesting(address indexed __receiver, uint256 indexed amount, uint256 indexed timestamp);

    // Mapping
    mapping(address => VestingforAddress) public vestingMap;

    //Constructor
    constructor (Tava token){
        TavaToken = token;
    }


    //Function    
    function getStageAttributes (address receiving, uint8 index) external view returns ( uint256 time, uint256 amount) {
        if(vestingMap[receiving].stages[index].exists == true) return ( vestingMap[receiving].stages[index].time, vestingMap[receiving].stagesUnlockAmount);
    }

    function initVesting(
        address _receiver, 
        uint256 _initialbalance, 
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _stageNum
        ) external onlyOwner {
        
       vestingforaddress.push();
       vestingID = vestingforaddress.length -1;
       vestingforaddress[vestingID].receiver=_receiver;
       vestingforaddress[vestingID].initialbalance=_initialbalance;
       vestingforaddress[vestingID].startTime=_startTime;
       vestingforaddress[vestingID].duration=_duration;
       vestingforaddress[vestingID].stageNum=_stageNum;
       vestingforaddress[vestingID].stagesUnlockAmount=_initialbalance/_stageNum;
       vestingforaddress[vestingID].tokensSent=0;
       vestingforaddress[vestingID].tokensToSend=0;
       vestingforaddress[vestingID].valid = true;

       uint256 __time=_startTime;

       vestingforaddress[vestingID].stages.push();
       vestingforaddress[vestingID].stages[0].time=__time;
       vestingforaddress[vestingID].stages[0].exists=true;

       for(uint8 i=1; i<_stageNum ;i++){
           vestingforaddress[vestingID].stages.push();
           __time+=_duration;
           vestingforaddress[vestingID].stages[i].time=__time;
           vestingforaddress[vestingID].stages[i].exists=true;
       }

       vestingMap [_receiver] = vestingforaddress[vestingID]; // mapping address with struct 
    }

    //edit vesting 
    function editVesting(
        address _receiver, 
        uint256 _initialbalance, 
        uint256 _startTime, 
        uint256 _duration, 
        uint256 _stageNum,
        bool _valid
        ) external onlyOwner{
        
        for(uint8 i=0 ; i<=vestingID ; i++){
            if(vestingforaddress[i].receiver == _receiver){
                require(vestingforaddress[i].tokensSent==0, "The vesting is already started");
                vestingMap[_receiver].initialbalance=_initialbalance;
                vestingMap[_receiver].startTime=_startTime;
                vestingMap[_receiver].duration=_duration;
                vestingMap[_receiver].stageNum=_stageNum;
                vestingMap[_receiver].stagesUnlockAmount=_initialbalance/_stageNum;
                vestingMap[_receiver].tokensToSend=0;
                vestingMap[_receiver].valid = _valid;

                uint256 __time=_startTime;

                vestingMap[_receiver].stages[0].time=_startTime;
                vestingMap[_receiver].stages[0].exists=true;
                
                for(uint8 j=1; j<_stageNum ;j++){
                    __time+=_duration;
                    vestingMap[_receiver].stages[j].time=__time;
                    vestingMap[_receiver].stages[j].exists=true;
            }
        }
        }
    }

    //cancel vesting 

    function cancelVesting(address _addr) external onlyOwner{
        for(uint8 i=0 ; i<=vestingID ; i++){
            if(vestingforaddress[i].receiver == _addr){
                vestingMap[_addr].valid=false;
            }
        }
    }

    // claim tokens 

    function addressExist(address _addr) internal view returns (bool){
        if(msg.sender == vestingMap[_addr].receiver) return true;
        else return false; 
    }

    function claimTokens(address receiving) external {
        require (addressExist(receiving)==true, "msg.sender is not receiver");
        require(vestingMap[receiving].valid==true, "the receiver's vesting has been canceled.");
        
        vestingMap[receiving].tokensToSend=getAvailableTokensToTransfer(receiving);
        require(vestingMap[receiving].tokensToSend>0, "nothing to claim");

        TavaToken.transfer(receiving, vestingMap[receiving].tokensToSend);
        emit successfulVesting(receiving,vestingMap[receiving].tokensToSend, block.timestamp);
        vestingMap[receiving].tokensSent = vestingMap[receiving].tokensSent+vestingMap[receiving].tokensToSend;
    } 


/* 기획서 5 - total allocation */
    function getinitialbalance(address receiving) external view returns(uint256){
        return vestingMap[receiving].initialbalance;
    }

/* 기획서 6 - total claimed to date */
    function getTotalclaimedtodate(address receiving) external view returns(uint256){
    return vestingMap[receiving].tokensSent;
    }

/* 기획서 7 - claimable now */
    function getAvailableTokensToTransfer(address receiving) public view returns (uint256){
         uint256 a=0;
         for (uint256 i = 0; i < vestingMap[receiving].stageNum ; i++) {
            if(block.timestamp >= vestingMap[receiving].stages[i].time) {
                a+=vestingMap[receiving].stagesUnlockAmount;
            }
            else break;
        }
        a-=vestingMap[receiving].tokensSent;
        return a;
    }

/* 기획서 8 - unvested -> getinitialbalance - totalclaimedtodate로 구하기 */

/* 기획서 10-1) next claim - next unlock date */
    function getnextunlockdate (address receiving) external view returns(uint256 nextunlockdate){
        for (uint8 i = 0; i < vestingMap[receiving].stages.length ; i++) {
            if(block.timestamp < vestingMap[receiving].stages[i].time){
                nextunlockdate = vestingMap[receiving].stages[i].time;
                break;
            }
        }
        return  nextunlockdate;
    }

/* 기획서 10-2) next claim - next unlock amount */
    function getnextunlockamount(address receiving) external view returns(uint256 nextunlockamount){
            for(uint8 i=0 ; i < vestingMap[receiving].stages.length ; i++){
              if(block.timestamp <  vestingMap[receiving].stages[i].time) {
                  nextunlockamount =  vestingMap[receiving].stagesUnlockAmount;
                  break;
              }
            }
        return  nextunlockamount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20Interface.sol";
import "./Pausable.sol";

contract Tava is ERC20Interface, Pausable{
    string private _name = "TAVA";
    string private _symbol = "TAVA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply; 

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /* ERC20Interface Implements */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

     function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused virtual {
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

    function allowance(address owner, address spender) public view override returns (uint256) {
         return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

// mint하고 timelock contract에 토큰 입금 (transferfrom 사용) 
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused override returns (bool) {
         _transfer(sender, recipient, amount);
         uint256 currentAllowance = _allowances[sender][msg.sender];
         require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
         unchecked {
         _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _mint(address account, uint256 amount) internal whenNotPaused virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /*added mint function*/
    function mint (address account, uint256 amount) external whenNotPaused onlyOwner{
        require(msg.sender == account);
        
        _mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused virtual {
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

    /*added burn function*/
    function burn (address account, uint256 amount) public whenNotPaused onlyOwner{
        require (msg.sender == account );
        _burn(account, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";

contract Ownable is Context{
   
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ERC20Interface {

    /* IERC20 Metadata */

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /* IERC20 */

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Pausable is Ownable {

    //Emitted when the pause is triggered by 'account'
    event Paused(address account);
    // Emitted when the pause is lifted by 'account'
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Context{
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

     function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}