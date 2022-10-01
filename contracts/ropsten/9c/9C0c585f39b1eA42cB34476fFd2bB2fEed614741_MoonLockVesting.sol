// SPDX-License-Identifier: MIT


// ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
// ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
// ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
// ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
// ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
// ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
// © 2022 Moon Labs LLC
// Moon Labs LLC reserves all rights on this code.
// You may not, except otherwise with prior permission and express written consent by Moon Labs LLC, copy, download, print, extract, exploit, 
// adapt, edit, modify, republish, reproduce, rebroadcast, duplicate, distribute, or publicly display any of the content, information, or material 
// on this smart contract for non-personal or commercial purposes, except for any other use as permitted by the applicable copyright law.
//
// Website: https://www.moonlabs.site/


pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./FullMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IDEXRouter.sol";
import "./SafeERC20.sol";

contract MoonLockVesting is ReentrancyGuard, Ownable{    

    using SafeERC20 for IERC20;

    constructor(address _tokenToBurn, uint _burnPercent, uint _lockPrice, address _routerAddress, uint _timeBuffer) {
        require(_burnPercent <= 100, "Burn percent cannot be over 100");
        tokenToBurn = IERC20(_tokenToBurn);
        burnPercent = _burnPercent;
        lockPrice = _lockPrice;
        iDEXRouter = IDEXRouter(_routerAddress);
        timeBuffer = _timeBuffer;
    }


    /*|| === STATE VARIABLES === ||*/
    IERC20 public tokenToBurn;
    uint public burnPercent;
    uint public index;
    uint public lockPrice;
    uint private timeBuffer;
    IDEXRouter private iDEXRouter;


    /*|| === STRUCTS VARIABLES === ||*/
    struct VestingInstance {
        address tokenAddress; // Address of locked token
        address creatorAddress; // Lock creator
        address withdrawAddress; // Withdraw address
        uint depositAmount; // Initial deposit amount
        uint totalAmount; // Current tokens in lock
        uint endDate; // Date when tokens are fully unlocked
        uint startDate;// Linear lock if !=0. Date when tokens start to unlock
    }


    /*|| === MAPPING === ||*/
    mapping (address => uint[]) private creatorAddressToLock;
    mapping (address => uint[]) private withdrawAddressToLock;
    mapping (address => uint[]) private tokenAddressToLock;
    mapping (uint => VestingInstance) private vestingInstance;


    /*|| === MODIFIERS === ||*/
    modifier withdrawOwner(uint _index){
        require(msg.sender == vestingInstance[_index].withdrawAddress, "You do not own this lock");
        _;
    }

    /*|| === EVENTS === ||*/
    event LockCreated(address indexed _creator, address indexed _token, uint _index);
    event TokensWithdrawn(address indexed _from, address indexed _token, uint _index);
    event LockTransfered(address indexed _from, address indexed _to, uint _index);
    event Test(uint value);


    /*|| === CORE FUNCTIONS === ||*/
    //Create lock or vesting instance
    function createLock(address _tokenAddress, address[] calldata _withdrawAddress, uint[] calldata _depositAmount, uint[] calldata _endDate,  uint[] calldata _startDate) external payable returns(bool){
        // Check if all arrays are same the size
        require(_withdrawAddress.length == _depositAmount.length && _depositAmount.length == _endDate.length && _endDate.length == _startDate.length, "Unequal array sizes");
        require(msg.value == lockPrice * _withdrawAddress.length, "Incorrect Price");

        uint _totalDepositAmount;

        for(uint i; i < _withdrawAddress.length; i++){
            createVestingInstance(_tokenAddress, _withdrawAddress[i], _depositAmount[i], _endDate[i], _startDate[i]);
            _totalDepositAmount += _depositAmount[i];
        }

        IERC20(_tokenAddress).safeTransferFrom( msg.sender, address(this), _totalDepositAmount);

        // Buy tokenToBurn via uniswap router and send to dead address
        address[] memory path = new address[](2);
        path[0] = iDEXRouter.WETH();
        path[1] = address(tokenToBurn);

        iDEXRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: (msg.value * burnPercent)/100}(
            0,
            path,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp + timeBuffer
        );
        return true;
    }

    // Create vesting instance
    function createVestingInstance(address _tokenAddress, address _withdrawAddress, uint _depositAmount, uint _endDate, uint _startDate) private{
        require(_depositAmount > 0, "Deposit amount must be greater than 0");
        require(_startDate < _endDate, "Start date must come before end date");
        require(_endDate >= block.timestamp - timeBuffer && _endDate < 10000000000, "Invalid end date");




        // Increment index
        index++;

        vestingInstance[index].tokenAddress = _tokenAddress;
        vestingInstance[index].creatorAddress = msg.sender;
        vestingInstance[index].withdrawAddress = _withdrawAddress;
        vestingInstance[index].depositAmount = _depositAmount;
        vestingInstance[index].totalAmount = _depositAmount;
        vestingInstance[index].endDate = _endDate;
        vestingInstance[index].startDate = _startDate;

        // Create map to withdraw address
        withdrawAddressToLock[_withdrawAddress].push(index);

        // Create map to token address
        tokenAddressToLock[_tokenAddress].push(index);

        // Create map to creator address
        creatorAddressToLock[msg.sender].push(index);

        // Emit lock created event
        emit LockCreated(msg.sender, _tokenAddress, index);
    }



    /*|| === VIEW FUNCTIONS === ||*/
    // Return vesting index from owner address
    function getVestingIndexFromCreatorAddress(address _creatorAddress) external view returns(uint[] memory){
        return creatorAddressToLock[_creatorAddress];
    }

    // Return vesting index from withdraw address
    function getVestingIndexFromWithdrawAddress(address _withdrawAddress) external view returns(uint[] memory){
        return withdrawAddressToLock[_withdrawAddress];
    }

    // Return vest index from token address
    function getVestingIndexFromTokenAddress(address _tokenAddress) external view returns(uint[] memory){
        return tokenAddressToLock[_tokenAddress];
    }
    
    // Return vesting instance from index
    function getVestingInstance(uint _index) external view returns(VestingInstance memory){
        return vestingInstance[_index];
    }

    // Return claimable tokens
    function getClaimableTokens(uint _index) public view returns(uint tokens){
        uint _tokensRemaining = vestingInstance[_index].totalAmount;
        uint _endDate = vestingInstance[_index].endDate;
        uint _startDate = vestingInstance[_index].startDate;

        // Check if the token balance is 0
        if(_tokensRemaining == 0){
            return 0;
        }

        // Check if lock is not linear
        if(_startDate == 0){
            return _endDate <= block.timestamp ? _tokensRemaining : 0;
        }

        // If none of the above then the token is a linear lock
        return calculateLinearWithdraw(_index, _tokensRemaining);
    }

    // Get the current amount of unlocked tokens
    function calculateLinearWithdraw(uint _index, uint _tokensRemaining) private view returns(uint unlockedTokens){
        uint _endDate = vestingInstance[_index].endDate;
        uint _startDate = vestingInstance[_index].startDate;
        uint _timeBlock = _endDate - _startDate;
        uint _timeElapsed;

        if(_endDate <= block.timestamp){ 
            _timeElapsed = _timeBlock;
        }else if(_startDate >= block.timestamp){
            _timeElapsed = 0;
        }else{
            _timeElapsed  = block.timestamp - _startDate;
        }
        // Math to calculate linear unlock
        return  FullMath.mulDiv(_tokensRemaining, _timeElapsed, _timeBlock);
    }


    /*|| === MUTATIVE FUNCTIONS === ||*/
    // Transfer withdraw address
    function transferVestingOwnership(uint _index, address _newOwner) public withdrawOwner(_index) returns(bool){
        //Change withdraw owner in vesting isntance to new owner
        vestingInstance[_index].withdrawAddress = _newOwner;

        // Delete mapping from old owner to index of vesting instance and pop
        uint[] storage withdrawArray = withdrawAddressToLock[msg.sender];
        for(uint i = 0; i < withdrawArray.length; i++){
            if(withdrawArray[i] == _index){
                delete withdrawArray[i];
                for(uint j = i; j < withdrawArray.length-1; j++){
                    withdrawArray[j] = withdrawArray[j+1];
                }
                withdrawArray.pop();
            }
        }
        // Map index of transfered lock to new owner
        withdrawAddressToLock[_newOwner].push(_index);
        // Emit transfer event on competion
        emit LockTransfered(msg.sender, _newOwner, _index);
        return true;
    }

    // Claim unlocked tokens
    function withdrawUnlockedTokens(uint _index, uint _amount) external nonReentrant withdrawOwner(_index) returns(bool){
        require(_amount <= getClaimableTokens(_index) , "Exceeds withdraw balance");
        require(_amount > 0, "Cannot withdraw 0 tokens");
        // Add claim amount to total withdraw amount
        vestingInstance[_index].totalAmount -= _amount;
        // Transfer tokens from contract to recipient
        IERC20(vestingInstance[_index].tokenAddress).safeTransfer(msg.sender,  _amount);

        // Delete vesting instance if no tokens are left
        if(vestingInstance[_index].totalAmount == 0){
            deleteVestingInstance(_index);
        }

        // Emits TokensWithdrawn event
        emit TokensWithdrawn(msg.sender, vestingInstance[_index].tokenAddress, _index);
        return true;
    }


    /*|| === OWNER FUNCTIONS === ||*/
    // Claim bnb in contract
    function claimETH() external onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    // Set router address
    function setRouter(address _routerAddress) external onlyOwner{
        iDEXRouter = IDEXRouter(_routerAddress);
    }

    // Set time buffer
    function setTimeBuffer(uint _timeBuffer) external onlyOwner{
        timeBuffer = _timeBuffer;
    }
    
    // Change lock price in wei
    function setLockPrice(uint _lockPrice) external onlyOwner{
        lockPrice = _lockPrice;
    }

    // Change token to auto burn
    function setTokenToBurn(address _tokenToBurn) external onlyOwner{
        tokenToBurn = IERC20(_tokenToBurn);
    }

    // Change amount of tokens to auto burn
    function setBurnPercent(uint _burnPercent) external onlyOwner{
        require( _burnPercent <= 100, "Burn percent cannot exceed 100");
        burnPercent = _burnPercent;
    }

    // Delete vesting instance 
    function deleteVestingInstance(uint _index) private{
        // Delete mapping from withdraw owner to index
        uint[] storage withdrawArray = withdrawAddressToLock[vestingInstance[_index].withdrawAddress];
        for(uint i = 0; i < withdrawArray.length; i++){
            if(withdrawArray[i] == _index){
                delete withdrawArray[i];
                for(uint j = i; j < withdrawArray.length-1; j++){
                    withdrawArray[j] = withdrawArray[j+1];
                }
                withdrawArray.pop();
            }
        }
        // Delete mapping from creator address to index
        uint[] storage creatorArray = creatorAddressToLock[vestingInstance[_index].creatorAddress];
        for(uint i = 0; i < creatorArray.length; i++){
            if(creatorArray[i] == _index){
                delete creatorArray[i];
                for(uint j = i; j < creatorArray.length-1; j++){
                    creatorArray[j] = creatorArray[j+1];
                }
                creatorArray.pop();
            }
        }
        // Delete mapping from token address to index
        uint[] storage tokenArray = tokenAddressToLock[vestingInstance[_index].tokenAddress];
        for(uint i = 0; i < tokenArray.length; i++){
            if(tokenArray[i] == _index){
                delete tokenArray[i];
                for(uint j = i; j < tokenArray.length-1; j++){
                    tokenArray[j] = tokenArray[j+1];
                }
                tokenArray.pop();
            }
        }
        //Delete vesting instance map
        delete vestingInstance[_index];
    }
}