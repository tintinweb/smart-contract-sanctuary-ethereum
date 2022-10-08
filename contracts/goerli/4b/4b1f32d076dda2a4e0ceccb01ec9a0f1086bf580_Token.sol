/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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

contract Token is ERC20 {
    address internal admin; // Mandatory
    address internal vault; // Mandatory
    bool public paused; // Mandatory
    constructor() ERC20("Joomjoo","Joo") {
        admin = msg.sender;
        vault = msg.sender;
    }

    uint public tokensToReceive; // Mandatory
    uint public oneTokenPriceInWei = 1; // Mandatory
    mapping(address => AllUserContributionsTimestamp) public allPossibleContributions;
    mapping(address => AllClaimable) public hasClaimableTokens;
    mapping(address => AllUserTokensReceived) public allUserTokens;

    struct AllUserContributionsTimestamp {
        uint totalAmountPurchased;
        uint indexPurchaseNo;
        uint[] amountPurchased;
        uint[] timeOfPurchase;
    }
    struct AllClaimable {
        bool hasClaimable ;
        uint numberClaimableTokens;
    }
    struct AllUserTokensReceived {
        uint totalTokens;
        uint indexTokensReceived;
        uint[] tokensSuccesfullyClaimed;
        uint[] timeOfClaims;
    }

    function convertWeiSpentToTokenNo(uint _spent) internal returns(uint) {
        unchecked{tokensToReceive = (_spent / oneTokenPriceInWei)*(10**decimals());} 
        return(tokensToReceive);
    }

    function buy() public payable returns(bool){
        require(paused == false, "pausd");
        payable(vault).transfer(msg.value);
        unchecked{allPossibleContributions[msg.sender].totalAmountPurchased += msg.value;}
        unchecked{allPossibleContributions[msg.sender].indexPurchaseNo += 1;}
        allPossibleContributions[msg.sender].amountPurchased.push(msg.value);
        allPossibleContributions[msg.sender].timeOfPurchase.push(block.timestamp);
        hasClaimableTokens[msg.sender].hasClaimable = true;
        unchecked{hasClaimableTokens[msg.sender].numberClaimableTokens += convertWeiSpentToTokenNo(msg.value);}
        return true;
    }
    
    function claim() public returns(bool){
        require(paused == false, "paused");
        require(hasClaimableTokens[msg.sender].hasClaimable == true, "No claimables");
        _mint(msg.sender, hasClaimableTokens[msg.sender].numberClaimableTokens);    
        unchecked{allUserTokens[msg.sender].totalTokens += hasClaimableTokens[msg.sender].numberClaimableTokens;}
        unchecked{allUserTokens[msg.sender].indexTokensReceived += 1;}
        allUserTokens[msg.sender].tokensSuccesfullyClaimed.push(hasClaimableTokens[msg.sender].numberClaimableTokens);
        hasClaimableTokens[msg.sender].hasClaimable = false;
        hasClaimableTokens[msg.sender].numberClaimableTokens = 0;
        allUserTokens[msg.sender].timeOfClaims.push(block.timestamp);
        return true;
    }

    uint public stakeFeePriceInWei = 10;
    uint public unstakeFeePriceInWei = 10;
    uint256 public constant BASE_EPOCH_DURATION = 30;
    uint256 public constant BASE_FINAL_REWARD = 5;

    mapping(address => AllUserStakedTimestamp) internal allUserStakes;

    struct AllUserStakedTimestamp {
        uint _numberOfStakes;
        bool[] _wasUnstaked;
        bool[] _autoRenewal;
        uint[] _amountStaked;
        uint[] _timeOfStake;
        uint[] _timesOfRelease;
        uint[] _optionReleaseSelected; // 0-1-2
        uint[] _epochDuration;
        uint[] _rewardPerCycle;
        uint[] _finalStakeReward;
    }

    modifier allowedUserReleaseTimeSelectionRange(uint _userReleaseTimeSelection) {
        require(
        _userReleaseTimeSelection == 0 ||
        _userReleaseTimeSelection == 1 ||
        _userReleaseTimeSelection == 2, "only 0|1|2");
        _;
    }

    modifier ableToStake(uint256 _tokens) {
        require(paused == false, "paused");
        require(balanceOf(msg.sender) > 0, "no stakebles");
        require(_tokens <= balanceOf(msg.sender));
        _;
    }
    
    function giveMeNewTime(uint secondsAfter) public view returns(uint) {
        uint timeStampWanted = block.timestamp + (secondsAfter * 1 seconds);
        return(timeStampWanted);        
    }
    
    function stake(uint _tokens, uint _userReleaseTimeSelection, bool _autoRenewal)
        public
        payable
        allowedUserReleaseTimeSelectionRange(_userReleaseTimeSelection)
        ableToStake(_tokens)
        returns(bool) {
        payable(vault).transfer(stakeFeePriceInWei);
        uint256 epochDuration = BASE_EPOCH_DURATION * (_userReleaseTimeSelection + 1);
        uint256 finalChoice = giveMeNewTime(epochDuration);
        uint256 finalReward = BASE_FINAL_REWARD * (_userReleaseTimeSelection + 1);
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        allUserStakedTimestamp._wasUnstaked.push(false);
        allUserStakedTimestamp._autoRenewal.push(_autoRenewal);
        allUserStakedTimestamp._amountStaked.push(_tokens);
        allUserStakedTimestamp._timeOfStake.push(block.timestamp);
        allUserStakedTimestamp._timesOfRelease.push(finalChoice);
        allUserStakedTimestamp._optionReleaseSelected.push(_userReleaseTimeSelection);
        allUserStakedTimestamp._epochDuration.push(epochDuration);
        allUserStakedTimestamp._rewardPerCycle.push(finalReward);
        allUserStakedTimestamp._finalStakeReward.push(finalReward);
        allUserStakedTimestamp._numberOfStakes +=1;
        _burn(msg.sender, _tokens);
        return true;
    }
    
    function checkHowManyStakes(address _addr) public view returns(uint) {
        return allUserStakes[_addr]._numberOfStakes;
    }
    
    function requestUnstake(uint _stakeIndexNo) internal returns(bool, uint) {
        require(paused == false, "paused"); 
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        uint[4] memory prm = [
            allUserStakedTimestamp._epochDuration[_stakeIndexNo], 
            allUserStakedTimestamp._timeOfStake[_stakeIndexNo],  
            allUserStakedTimestamp._timesOfRelease[_stakeIndexNo],
            allUserStakedTimestamp._rewardPerCycle[_stakeIndexNo] 
        ];
        bool autoReNew = allUserStakedTimestamp._autoRenewal[_stakeIndexNo]; 
        uint timeAtRequest = block.timestamp; 
        uint timeElapsed = timeAtRequest - prm[1]; 
        uint rewardCycles = timeElapsed / prm[0]; 
        uint currentCycleTimeElapsed = timeElapsed - (rewardCycles * prm[0]); 
        uint timeTillNextCycle = prm[0] - currentCycleTimeElapsed; 

        if(((autoReNew == false) && (prm[2] <= timeAtRequest))){
            return (true, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]) ;} 

        else if(((timeAtRequest - prm[2]) == (((timeAtRequest - prm[2]) / prm[0]) * prm[0])))
        {allUserStakedTimestamp._finalStakeReward[_stakeIndexNo] = rewardCycles * prm[3]; 
        return (true, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]);} 
        
        else {uint newTimeOfRelease = giveMeNewTime(timeTillNextCycle);
        allUserStakedTimestamp._timesOfRelease[_stakeIndexNo] = newTimeOfRelease;
        allUserStakedTimestamp._autoRenewal[_stakeIndexNo] = false;
        allUserStakedTimestamp._finalStakeReward[_stakeIndexNo] = (rewardCycles + 1) * prm[3]; 
        return (false, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]);} 
    }

    modifier ableToUnstake(uint256 _stakeIndexNo) {
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        require(paused == false, "paused");
        require(_stakeIndexNo <= allUserStakedTimestamp._wasUnstaked.length, "out of range");
        require(allUserStakedTimestamp._wasUnstaked[_stakeIndexNo] == false, "already unstaked");
        require(allUserStakedTimestamp._timesOfRelease[_stakeIndexNo] <= block.timestamp, "not yet");
        require(allUserStakedTimestamp._amountStaked[_stakeIndexNo] > 0, "no unstkables");
        _;
    }

    function unstake(uint _stakeIndexNo) public payable ableToUnstake(_stakeIndexNo) returns(bool _unstaked, string memory _msg, uint _time){
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        (bool b,) = requestUnstake(_stakeIndexNo);
        
        if(b == true){
            uint _tokens = allUserStakedTimestamp._amountStaked[_stakeIndexNo];
            uint reward = allUserStakedTimestamp._finalStakeReward[_stakeIndexNo];
            uint initialTokensPlusRewardOwed = _tokens + reward;
            _mint(msg.sender, initialTokensPlusRewardOwed);
            payable(vault).transfer(unstakeFeePriceInWei);
            allUserStakedTimestamp._wasUnstaked[_stakeIndexNo] = true;
            return (true, "unstkd at:", block.timestamp);
            }

        else if (b == false){
            return (false,"Req-Submted, come back at:", allUserStakedTimestamp._timesOfRelease[_stakeIndexNo]) ;
        }
    }

    event gCreated(uint gIdx, string _gName, uint gTime);  
    uint public gCount;     
    mapping(uint => g) public _gByIdx;
    
    struct g {
        uint gIdx;
        string gName;
        bool gActive;
        bool gStarted;
        bool gClose;
        bool postable;
        bool _resA;
        bool _resB;
        bool _resC;
        uint gTime;
    }

    modifier admAct() {
        require(paused == false, "paused");
        require(admin == msg.sender, "u not adm!");
        _;
    }
 
    function creatG(string memory _gName) public admAct() returns(uint, string memory, bool, uint){
        _gByIdx[gCount].gIdx = gCount;
        _gByIdx[gCount].gName = _gName;
        _gByIdx[gCount].gTime = block.timestamp;
        gCount++;
        uint gIdx = gCount - 1;
        uint gTime = block.timestamp;
        emit gCreated(gIdx, _gName, gTime );
        return((gCount-1), _gName, _gByIdx[gCount].gActive, block.timestamp);
    }

    function checkRes(uint _gIdx) public view returns(uint, string memory, bool, bool, bool, bool, uint) {
        require(_gIdx <= gCount -1, "out-range");
        return (_gIdx, _gByIdx[_gIdx].gName, _gByIdx[_gIdx].gActive, _gByIdx[_gIdx]._resA,
        _gByIdx[_gIdx]._resB, _gByIdx[_gIdx]._resC, block.timestamp);
    }

    function startG(uint _gIdx) public admAct() returns(bool) {
        require(_gByIdx[_gIdx].gStarted == false, "G alrdy startd");
        _gByIdx[_gIdx].gActive = true;
        _gByIdx[_gIdx].gStarted = true;
        return true;
    }

    function closeG(uint _gIdx) public admAct() returns(bool) {
        _gByIdx[_gIdx].gActive = false;
        _gByIdx[_gIdx].postable = true;
        return true;
    }

    function postRes(uint _gIdx, uint _res) public admAct() returns(uint, string memory, bool, bool, bool, bool,uint) { 
        require(_gByIdx[_gIdx].postable == true, "still-active or not-startd");
        require(_res == 1 || _res == 2 || _res == 3,"only 1,2 or 3");
        if (_res == 1) {_gByIdx[_gIdx]._resA = true;}
        else if (_res == 2) {_gByIdx[_gIdx]._resB = true;}
        else if (_res == 3) {_gByIdx[_gIdx]._resC = true;}
        else {revert("only1,2,3");}
        _gByIdx[_gIdx].gActive = false;
        _gByIdx[_gIdx].gClose = true;
        return (
            _gIdx,
            _gByIdx[_gIdx].gName, 
            _gByIdx[_gIdx].gActive, 
            _gByIdx[_gIdx]._resA,
            _gByIdx[_gIdx]._resB, 
            _gByIdx[_gIdx]._resC, 
            block.timestamp
            );
    }

    mapping (address => mapping(uint => bet)) internal bets;
    mapping (uint => totWaged) internal waged;

    struct bet {
        uint _bet;
        uint _gIdx;
        bool _winA;
        bool _winB;
        bool _winC;
        bool _cashedOut;
    }

    struct totWaged {
        uint _totWaged;
        uint _totA;
        uint _totB;
        uint _totC;
        uint _toDistrib;
    }

    function betOn(uint _bet, uint _gIdx, uint _win) public returns (bool) { 
        bets[msg.sender][_gIdx]._bet += _bet;
        bets[msg.sender][_gIdx]._gIdx = _gIdx;
        _burn(msg.sender, _bet);
        if (_win == 1) {bets[msg.sender][_gIdx]._winA = true;}
        else if (_win == 2) {bets[msg.sender][_gIdx]._winB = true;}
        else if (_win == 3) {bets[msg.sender][_gIdx]._winC = true;}
        else {revert("only1,2,3");}
        waged[_gIdx]._totWaged += _bet;
        if (_win == 1) {waged[_gIdx]._totA += _bet;}
        else if (_win == 2) {waged[_gIdx]._totB += _bet;}
        else if (_win == 3) {waged[_gIdx]._totC += _bet;}
        return true;    
    }

    function checkIfWon(uint _gIdx, address _addr) public view returns(bool){
        require(_gByIdx[_gIdx].postable == true, "still-active or not-startd");
        if (bets[_addr][_gIdx]._winA == _gByIdx[_gIdx]._resA &&
        bets[_addr][_gIdx]._winB == _gByIdx[_gIdx]._resB &&
        bets[_addr][_gIdx]._winC == _gByIdx[_gIdx]._resC) 
        {return true;}
        else {return false;}
    }

    function gStats(uint _gIdx) public view returns(uint){
        uint _losTotAmt;
        uint _winTotAmt;
        uint _distrLos;
        if (_gByIdx[_gIdx]._resA == true) {_winTotAmt += waged[_gIdx]._totA;}           
        else if (_gByIdx[_gIdx]._resB == true) {_winTotAmt += waged[_gIdx]._totB;}      
        else if (_gByIdx[_gIdx]._resC == true) {_winTotAmt += waged[_gIdx]._totC;}      
        else {revert("No valide results found!!!");}                                        
        _losTotAmt = waged[_gIdx]._totWaged - _winTotAmt;
        if (_losTotAmt == 0 || _winTotAmt == 0) {
            _distrLos = 0;
            return _distrLos;}
        else {
            _distrLos = (_losTotAmt*10**decimals()) / _winTotAmt;
            return _distrLos;} 
    }

    function cashOut(uint _gIdx) public returns (bool) {
        require(bets[msg.sender][_gIdx]._bet > 0 ,"u-no-bet");
        require(bets[msg.sender][_gIdx]._cashedOut == false ,"u-cash-out");
        require(checkIfWon(_gIdx, msg.sender) == true, "u-lost");
        // require(if laready chased false)
        uint winnings = (gStats(_gIdx) * bets[msg.sender][_gIdx]._bet) / (10**decimals());
        uint toCashOut = winnings +  bets[msg.sender][_gIdx]._bet;
        _mint(msg.sender, toCashOut);
        bets[msg.sender][_gIdx]._cashedOut = true;
        // Missing our fee as the house
        return true;
    }
}