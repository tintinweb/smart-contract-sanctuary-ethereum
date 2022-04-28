/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  ebox - https://ebox.io
//
//  ebox Liquidity Locker
//
//  Purpose:
//  Enables users to lock LP tokens acquired by providing liquidity on DEXes (Uniswap, PancakeSwap etc), as well as any
//  other ERC-20 tokens.
//
//  Users can:
//  * lockCreate    Create a token lock that lasts until a user-defined release time
//  * lockAdd       Add tokens to an existing lock
//  * lockExtend    Extend an existing lock
//  * lockTransfer  Transfer ownership of an existing lock to another address
//  * lockRelease   Release tokens from an existing lock (partial amount, or all at once) that is past release time
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



contract eboxLiquidityLocker
{
    //------------------------------------------------------------------------------------------------------------------------
    //  Global variables
    //------------------------------------------------------------------------------------------------------------------------

    address                         contractOwner;
    bool                            contractPaused;
    uint                            contractReentrancyStatus;
    uint constant                   CONTRACT_REENTRANCY_NOT_ENTERED = 1;
    uint constant                   CONTRACT_REENTRANCY_ENTERED     = 2;

    mapping(uint => TokenLock)      allLocks;
    uint                            allLocksLength;

    ERC20Interface                  feeToken;
    FeeTier[]                       feeTiers;
    uint                            feeDivisor;

    mapping(address => bool)        hasSpecificFee;
    mapping(address => uint)        specificFee;

    mapping(ERC20Interface => uint) collectedFee;

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Data types
    //------------------------------------------------------------------------------------------------------------------------

    struct TokenLock {
        address                     owner;
        ERC20Interface              token;
        uint                        value;
        uint                        releaseTime;
    }

    struct FeeTier {
        uint                        minTokenAmount;
        uint                        fee;
    }

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Events
    //------------------------------------------------------------------------------------------------------------------------

    event LockCreate(uint indexed index, address indexed owner, ERC20Interface indexed token, uint value, uint releaseTime);
    event LockAdd(uint indexed index, uint value);
    event LockExtend(uint indexed index, uint newReleaseTime);
    event LockTransfer(uint indexed index, address indexed oldOwner, address indexed newOwner);
    event LockRelease(uint indexed index, uint value);

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Constructor, fallback, modifiers
    //------------------------------------------------------------------------------------------------------------------------

    constructor(ERC20Interface _feeToken, FeeTier[] memory _feeTiers, uint _feeDivisor)
    {
        contractOwner = msg.sender;
        contractReentrancyStatus = CONTRACT_REENTRANCY_NOT_ENTERED;

        ownerSetFeeTiers(_feeToken, _feeTiers, _feeDivisor);
    }

    fallback() external payable
    {
        revert("Do not send funds directly to contract");
    }

    modifier onlyOwner
    {
        require(msg.sender == contractOwner, "Only available for contract owner");
        _;
    }

    modifier nonReentrant
    {
        require(contractReentrancyStatus != CONTRACT_REENTRANCY_ENTERED, "Reentrant calling not allowed");

        contractReentrancyStatus = CONTRACT_REENTRANCY_ENTERED;
        _;
        contractReentrancyStatus = CONTRACT_REENTRANCY_NOT_ENTERED;
    }

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Functions: Getter
    //------------------------------------------------------------------------------------------------------------------------

    function getLock(uint _index) external view returns(TokenLock memory)
    {
        require(_index < allLocksLength, "Invalid index: Too high");

        return allLocks[_index];
    }

    function getFee() external view returns(uint, uint)
    {
        return (getFeeFor(msg.sender), feeDivisor);
    }

    function getFeeFor(address _addr) internal view returns(uint)
    {
        if(hasSpecificFee[_addr])
            return specificFee[_addr];

        for(uint i = feeTiers.length - 1; i > 0; i--)
            if(feeToken.balanceOf(_addr) >= feeTiers[i].minTokenAmount)
                return feeTiers[i].fee;

        return feeTiers[0].fee;
    }

    function getFeeTiers() external view returns(ERC20Interface, FeeTier[] memory, uint)
    {
        return (feeToken, feeTiers, feeDivisor);
    }

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Functions: User
    //------------------------------------------------------------------------------------------------------------------------

    function lockCreate(ERC20Interface _token, uint _value, uint _releaseTime) nonReentrant external
    {
        require(!contractPaused, "Contract is paused");
        require(_value != 0, "Invalid value: Must not be 0");
        require(_releaseTime > block.timestamp, "Invalid release time: Must be in the future");

        uint oldBalance = _token.balanceOf(address(this));
        _token.transferFrom(msg.sender, address(this), _value);
        _value = _token.balanceOf(address(this)) - oldBalance;

        uint fee = (_value * getFeeFor(msg.sender)) / feeDivisor;
        collectedFee[_token] += fee;

        allLocks[allLocksLength] = TokenLock(msg.sender, _token, _value - fee, _releaseTime);
        allLocksLength++;

        emit LockCreate(allLocksLength - 1, msg.sender, _token, _value - fee, _releaseTime);
    }

    function lockAdd(uint _index, uint _value) nonReentrant external
    {
        require(!contractPaused, "Contract is paused");
        require(allLocks[_index].owner == msg.sender, "Invalid index: Must be owner");
        require(allLocks[_index].value != 0, "Invalid index: Lock must not be empty");
        require(_value != 0, "Invalid value: Must not be 0");

        uint oldBalance = allLocks[_index].token.balanceOf(address(this));
        allLocks[_index].token.transferFrom(msg.sender, address(this), _value);
        _value = allLocks[_index].token.balanceOf(address(this)) - oldBalance;

        uint fee = (_value * getFeeFor(msg.sender)) / feeDivisor;
        collectedFee[allLocks[_index].token] += fee;

        allLocks[_index].value += _value - fee;

        emit LockAdd(_index, _value - fee);
    }

    function lockExtend(uint _index, uint _newReleaseTime) external
    {
        require(!contractPaused, "Contract is paused");
        require(allLocks[_index].owner == msg.sender, "Invalid index: Must be owner");
        require(allLocks[_index].value != 0, "Invalid index: Lock must not be empty");
        require(allLocks[_index].releaseTime < _newReleaseTime, "Invalid new release time: Must be greater than old release time");
        require(_newReleaseTime > block.timestamp, "Invalid new release time: Must be in the future");

        allLocks[_index].releaseTime = _newReleaseTime;

        emit LockExtend(_index, _newReleaseTime);
    }

    function lockTransfer(uint _index, address _newOwner) external
    {
//      require(!contractPaused, "Contract is paused");
        require(allLocks[_index].owner == msg.sender, "Invalid index: Must be owner");
        require(allLocks[_index].value != 0, "Invalid index: Lock must not be empty");
        require(_newOwner != address(0), "Invalid new owner: Must not be zero address");
        require(_newOwner != msg.sender, "Invalid new owner: Must not be old owner");

        address oldOwner = allLocks[_index].owner;
        allLocks[_index].owner = _newOwner;

        emit LockTransfer(_index, oldOwner, _newOwner);
    }

    function lockRelease(uint _index, uint _value) external
    {
//      require(!contractPaused, "Contract is paused");
        require(allLocks[_index].owner == msg.sender, "Invalid index: Must be owner");
        require(allLocks[_index].releaseTime <= block.timestamp, "Invalid index: Lock must be expired");
        require(allLocks[_index].value != 0, "Invalid index: Lock must not be empty");
        require(allLocks[_index].value >= _value, "Invalid value: Must be less than or equal to value stored in lock");
        
        if(_value == 0)
            _value = allLocks[_index].value;
        allLocks[_index].value -= _value;

        allLocks[_index].token.transfer(msg.sender, _value);

        emit LockRelease(_index, _value);
    }

    //------------------------------------------------------------------------------------------------------------------------


    //------------------------------------------------------------------------------------------------------------------------
    //  Functions: Owner / administrative
    //------------------------------------------------------------------------------------------------------------------------

    function ownerSetContractPaused(bool _paused) onlyOwner external
    {
        contractPaused = _paused;
    }

    function ownerSetNewOwner(address _newOwner) onlyOwner external
    {
        require(_newOwner != address(0), "Invalid new contract owner: Must not be zero address");

        contractOwner = _newOwner;
    }

    function ownerSetFeeTiers(ERC20Interface _feeToken, FeeTier[] memory _feeTiers, uint _feeDivisor) onlyOwner public
    {
        require(_feeTiers.length >= 1, "Fee tiers: Must pass at least 1 tier");
        require(_feeTiers[0].minTokenAmount == 0, "Fee tiers: Must include tier for 0 tokens");
        require(_feeDivisor != 0, "Fee divisor: Must not be 0");

        feeToken = _feeToken;
        feeDivisor = _feeDivisor;

        uint oldLength = feeTiers.length;
        for(uint i = 0; i < oldLength; i++)
            feeTiers.pop();
        
        for(uint i = 0; i < _feeTiers.length; i++) {
            if(i > 0)
                require(_feeTiers[i].minTokenAmount > _feeTiers[i - 1].minTokenAmount, "Fee tiers: Must be sorted by minTokenAmount in ascending order");

            feeTiers.push(_feeTiers[i]);
        }
    }

    function ownerSetSpecificFeeFor(address _addr, bool _hasSpecificFee, uint _fee) onlyOwner external
    {
        hasSpecificFee[_addr] = _hasSpecificFee;

        if(_hasSpecificFee)
            specificFee[_addr] = _fee;
    }

    function ownerGetSpecificFeeFor(address _addr) onlyOwner external view returns(bool, uint)
    {
        return (hasSpecificFee[_addr], specificFee[_addr]);
    }

    function ownerCollectFee(ERC20Interface[] memory _tokens) onlyOwner external
    {
        for(uint i = 0; i < _tokens.length; i++) {
            if(collectedFee[_tokens[i]] == 0)
                continue;
                
            uint value = collectedFee[_tokens[i]];
            collectedFee[_tokens[i]] = 0;

            _tokens[i].transfer(msg.sender, value);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------
}



interface ERC20Interface
{
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint);
    function allowance(address tokenOwner, address spender) external view returns(uint);
    function transfer(address to, uint tokens) external returns(bool);
    function approve(address spender, uint tokens) external returns(bool);
    function transferFrom(address from, address to, uint tokens) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}