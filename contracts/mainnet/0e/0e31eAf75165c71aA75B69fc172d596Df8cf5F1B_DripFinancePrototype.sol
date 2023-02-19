/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
//     ___      _          _____                         //
//    / _ \____(_)__      / __(_)__  ___ ____  _______   //
//   / // / __/ / _ \    / _// / _ \/ _ `/ _ \/ __/ -_)  //
//  /____/_/ /_/ .__/(_)/_/ /_/_//_/\_,_/_//_/\__/\__/   //
//            /_/                                        //
//                                                       //
//  by: 0xInuarashi.eth @ CypherLabz                     //
//  https://twitter.com/0xInuarashi                      //
//  https://twitter.com/CypherLabz                       //
//                                                       //
///////////////////////////////////////////////////////////

// Feature Upgrade: Reduce Deposit While Retaining EndTime (Penalties) [x]

/////////////////
//  Libraries  //
/////////////////

library SafeCall {
    /** 
     * @title SafeCall 
     * @dev SafeCall allows _safeFunctionCall which is a .call method that disallows
     * initiating .call to EOAs which cause success with no return data
     * whilst not actually supporting the function.
     */

    /** @dev safeFunctionCall calls the target and does a call result verification.
     *  we mimic OpenZeppelin _verifyCallResultFromTarget in a different way by
     *  disallowing this call to EOAs. Contracts only, thus we can eliminate the
     *  (success, emptydata) return of EOAs which leads to unintended behavior.
     */
    function _safeFunctionCall(address target_, bytes memory data_,
    string memory errorMessage_) internal returns (bytes memory) {
        require(target_.code.length > 0, "_safeFunctionCall target not contract");
        (bool _success, bytes memory _returndata) = target_.call(data_);
        if (_success) return _returndata;
        _verboseRevert(_returndata, errorMessage_);
    }

    /** @dev _verboseRevert reverts verbosely either with returnData or errorMessage */
    function _verboseRevert(bytes memory returndata_, string memory errorMessage_) 
    private pure {
        if (returndata_.length > 0) { assembly { 
            let returndata_size := mload(returndata_)
            revert(add(32, returndata_), returndata_size)
        }} else { revert (errorMessage_); }
    }
}

library SafeERC20 {
    /** 
     * @title SafeERC20 (CypherMate version)
     * @dev Basically there are two conditions that need to be met:
     *  - If the transferFrom function does not return anything, throw.
     *  - If the transferFrom function returns false, throw.
     * @dev These two conditions above are created to prevent unintended function flow
     * that assumes a failed transfer will throw (which is not always the case). 
     * note: a lot of this code was influenced by OpenZeppelin's SafeERC20
     * note: we also added some functions from OpenZeppelin's Address
     */

    using SafeCall for address;

    /** @dev _safeERC20Call allows our contract to call other ERC20 contracts.
     *  it uses _safeFunctionCall from SafeCall to prevent non-contract calling
     *  additionally, we check for optional returndata to account for different weird
     *  ERC20 behavior. 
     *  The condition is, IF there is returned data, it must be bool TRUE.
     *  otherwise, revert it due to strange behavior.
     *  This also allows ERC20 functions to NOT return anything, as some tokens do so.
     *  Most notably: BNB (Binance), OMG (Omisego)
     */
    function _safeERC20Call(IERC20 token_, bytes memory data_)
    private {
        bytes memory _returndata = address(token_)._safeFunctionCall(data_,
            "SafeERC20: low-level call failed");
        if (_returndata.length > 0) {
            require(abi.decode(_returndata, (bool)), 
                "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function safeTransfer(IERC20 token_, address to_, uint256 value_)
    internal {
        _safeERC20Call(token_, 
            abi.encodeWithSelector(token_.transfer.selector, to_, value_));
    }
    function safeTransferFrom(IERC20 token_, address from_, address to_, uint256 value_) 
    internal {
        _safeERC20Call(token_, 
            abi.encodeWithSelector(token_.transferFrom.selector, from_, to_, value_));
    }
}

library MiniSafeERC20 {

    function safeTransfer(IERC20 token_, address to_, uint256 value_)
    internal {
        // 1. Calling transfer of an ERC20 token must be to a contract
        address _tokenAddr = address(token_);
        require(_tokenAddr.code.length > 0, "not contract");
        
        bytes memory _transferData = 
            abi.encodeWithSelector(token_.transfer.selector, to_, value_);
        
        (bool _success, bytes memory _returndata) = 
            _tokenAddr.call(_transferData);

        // .call method success 
        require(_success, "call failed");

        // 2. If there is return data, that data must equate to bool true
        // 3. However, if there is no return data, allow it to succeed (bnb, omg)
        if (_returndata.length > 0) {
            require(abi.decode(_returndata, (bool)), "returndata != true");
        }
    }

    function safeTransferFrom(IERC20 token_, address from_, address to_, 
    uint256 value_) internal { 
        // 1. Calling transferFrom of an ERC20 token must be to a contract
        address _tokenAddr = address(token_);
        require(_tokenAddr.code.length > 0, "not contract");

        bytes memory _transferFromData = 
            abi.encodeWithSelector(token_.transferFrom.selector, from_, to_, value_);
        
        (bool _success, bytes memory _returndata) = 
            _tokenAddr.call(_transferFromData);
        
        // .call method success
        require(_success, "call failed");

        // 2. If there is return data, that data must equate to bool true
        // 3. However, if there is no return data, allow it to succeed (bnb, omg)
        if (_returndata.length > 0) {
            require(abi.decode(_returndata, (bool)), "returndata != true");
        }
    }
}

//////////////////
// Inheritances //
//////////////////
abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;

    constructor() { 
        owner = msg.sender; 
    }
    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}


/** Controllerable: Dynamic Controller System

    string controllerType is a string version of controllerSlot
    bytes32 controllerSlot is a keccak256(abi.encodePacked("ControllerName"<string>))
        used to store the type of controller type
    address controller is the address of the controller
    bool status is the status of controller (true = is controller, false = is not)

    usage: call isController with string type_ and address of user to receive a boolean
*/

abstract contract Controllerable is Ownable {

    event ControllerSet(string indexed controllerType, bytes32 indexed controllerSlot, 
        address indexed controller, bool status);

    mapping(bytes32 => mapping(address => bool)) internal __controllers;

    function isController(string memory type_, address controller_) public 
    view returns (bool) {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        return __controllers[_slot][controller_];
    }

    modifier onlyController(string memory type_) {
        require(isController(type_, msg.sender), "Controllerable: Not Controller!");
        _;
    }

    function setController(string calldata type_, address controller_, bool bool_) 
    external onlyOwner {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        __controllers[_slot][controller_] = bool_;
        emit ControllerSet(type_, _slot, controller_, bool_);
    }
}

/////////////////
// Interfaces  //
/////////////////

interface IERC20 {
    // transfer() is used to transfer contract's balance to users
    function transfer(address to_, uint256 amount_) external returns (bool);
    // transferFrom() is used to do an approval-based transfer from users to the protocol
    function transferFrom(address from_, address to_, uint256 amount_) external 
    returns (bool);
    // balanceOf() is used to check the balance of each affected address to confirm 
    // the result of transfer and transferFrom 
    function balanceOf(address owner_) external view returns (uint256);
}

/////////////////
//  Protocol   //
/////////////////

// Fully On-Chain and Trustless Employment!

// For this version, we use a data structure that stores all stream data
// Based on stream ID

contract DripFinance is Controllerable {
    
    // Library Hooks
    using SafeERC20 for IERC20;

    /** 
    * Indexes: 
    *   token <address> - used to get all events for a specific token
    *   streamId <uint32> - used to get all events for a specific stream
    */

    // Events
    event DripCreated(address sender, address receiver, 
        address indexed token, uint32 indexed streamId, uint256 deposit, 
        uint48 startTimestamp, uint48 endTimestamp);

    event DripAdded(address sender, address receiver,
        address indexed token, uint32 indexed streamId, uint256 oldDeposit, uint256 newDeposit,
        uint48 startTimestamp, uint48 previousEndTimestamp, uint48 newEndTimestamp);

    event DripAddedVariableRate(address sender, address receiver,
        address indexed token, uint32 indexed streamId, uint256 oldDeposit, uint256 newDeposit,
        uint48 startTimestamp, uint48 previousEndTimestamp, uint48 newEndTimestamp);

    event DripClaimed(address sender, address receiver,
        address indexed token, uint32 indexed streamId, uint256 deposit,
        uint256 amountSentToReceiver, uint256 amountRemaining,
        uint48 startTimestamp, uint48 endTimestamp, uint48 lastClaimTimestamp, 
        uint48 currentClaimTimestamp);
    
    event DripDeductedPenalty(address sender, address receiver,
        address indexed token, uint32 indexed streamId, uint256 depositBefore,
        uint256 depositAfter, uint256 penaltyAmount, string reason);
    
    event DripEnded(address sender, address receiver,
        address indexed token, uint32 indexed streamId, uint256 deposit,
        uint256 finalClaimed, uint256 amountSentToReceiver,
        uint48 startTimestamp, uint48 endTimestamp, uint48 dripEndTimestamp);

    event DrippableTokenSet(address indexed operator, address indexed token, 
        bool indexed drippable);

    // Structs 
    struct Stream {
        // First, we store the start and end timestamps of the stream
        // We use UINT48 which gives us sufficient time-storage as well as
        // the ability to pack the data within the first address-word for free
        uint48 startTimestamp;
        uint48 endTimestamp;

        // We also need to store the sender, receiver, and token address
        // Each uses 20-byte words
        address sender;
        address receiver;

        // We pack another variable lastClaimedTimestamp to be able to support
        // Variable Rate Change. We pack it within the tokenAddress 32-byte word
        address tokenAddress;
        uint48 lastClaimedTimestamp;

        // Next, we store the deposit (initial deposit) 
        // and balance (remaining balance)
        uint256 deposit;
        uint256 claimed;
    }

    // Mappings
    // Two mappings are used. 
    // streamIdToStream stores the streamId to Stream data
    // addressToStreams stores an array of streamIds associated with the address
    // We use uint32 so that we can compress a total of 8 streams into a single SSTORE 
    // That way the data is cheaper to store for addressToStream
    // With this data structure, we are able to store 4,294,967,295 streams
    // We think that that is enough for a long time.

    uint32 public currentStreamId = 1;
    mapping(uint32 => Stream) public streamIdToStream;
    mapping(address => uint32[]) public addressToOutStreams;
    mapping(address => uint32[]) public addressToInStreams;

    // Allowed Token List
    mapping(address => bool) public tokenIsDrippable;
    
    // Drippable Tokens Enumerable
    address[] public drippableTokens;
    mapping(address => uint256) public drippableTokenIndex;

    function _addTokenToDrippableEnumeration(address token_) internal {
        require(!tokenIsDrippable[token_], "Token already added!");
        uint256 _indexToPush = drippableTokens.length;

        // Add token to list
        tokenIsDrippable[token_] = true;

        // Add token to enumeration
        drippableTokenIndex[token_] = _indexToPush;
        drippableTokens.push(token_);
    }

    function _removeTokenFromDrippableEnumeration(address token_) internal {
        require(tokenIsDrippable[token_], "Token is not drippable!");
        uint256 _maxIndex = drippableTokens.length - 1;
        uint256 _indexToReplace = drippableTokenIndex[token_];

        // Remove token from list
        tokenIsDrippable[token_] = false;

        // Remove token from enumeration
        if (_indexToReplace == _maxIndex) {
            delete drippableTokenIndex[token_];
        }
        else {
            // Replace the index to remove with the last index
            drippableTokens[_indexToReplace] = drippableTokens[_maxIndex];
            delete drippableTokenIndex[token_];
            // Change the location of the index removed
            address _newTokenAtIndex = drippableTokens[_indexToReplace];
            drippableTokenIndex[_newTokenAtIndex] = _indexToReplace;
        }

        drippableTokens.pop();
    }

    function setTokenIsDrippable(address[] calldata tokenAddresses_, bool isDrippable_) 
    external onlyController("SETTER") {
        uint256 l = tokenAddresses_.length;
        uint256 i; unchecked { do { 
            address _tokenAddress = tokenAddresses_[i];
            
            if (isDrippable_) { _addTokenToDrippableEnumeration(_tokenAddress); }
            else { _removeTokenFromDrippableEnumeration(_tokenAddress); }

            emit DrippableTokenSet(msg.sender, _tokenAddress, isDrippable_);
            
        } while (++i < l); }
    }

    function getAllDrippableTokens() external view returns (address[] memory) {
        return drippableTokens;
    }

    function getDrippableTokensPaginated(uint256 startIndex_, uint256 endIndex_)
    external view returns (address[] memory) {
        uint256 _lastIndex = drippableTokens.length - 1;
        require(_lastIndex >= endIndex_, 
                "Index out of bounds!");

        uint256 l = endIndex_ - startIndex_ + 1;
        address[] memory a = new address[](l);

        uint256 i; unchecked { do {
            a[i++] = drippableTokens[startIndex_++];
        } while (startIndex_ <= endIndex_); }
        
        return a;
    }

    // Create a Stream
    function createDrip(address receiver_, address token_, uint256 deposit_, 
    uint48 startTimestamp_, uint48 endTimestamp_) public returns (uint32) {
        // First, we define the behaviors of the function
        // createDrip() should:
        //  - Create a {Stream} assigned by StreamId
        //  - Add StreamId to addressToStreams
        require(endTimestamp_ > startTimestamp_,
                "End Timestamp is below Start Timestamp!");
        
        require(deposit_ > 0,
                "Deposit must be over 0!");
        
        require(receiver_ != address(0) &&
                receiver_ != address(this) &&
                receiver_ != msg.sender,
                "Receiver cannot be 0x0, this contract, or yourself!");

        require(tokenIsDrippable[token_],
                "Token is not Drippable!");

        // First, we transfer the token to the contract 
        // A necessary ~5000 gas call
        uint256 _thisBalanceBefore = IERC20(token_).balanceOf(address(this));

        // @audit done - changed transferFrom to safeTransferFrom
        IERC20(token_).safeTransferFrom(msg.sender, address(this), deposit_);

        // A necessary ~5000 gas call
        uint256 _thisBalanceAfter = IERC20(token_).balanceOf(address(this));

        // After the transferFrom has been called, we make sure that our balance has 
        // increased as intended.
        require(_thisBalanceAfter == (_thisBalanceBefore + deposit_), 
                "Balance behavior exception!");
        
        // Once we've received the tokens, we will create a stream for them
        // We initialize a uint256 _stream to save on SLOAD costs as we reuse the uint256
        // Once we load the streamId, we increment it.
        uint32 _currentStreamId = currentStreamId++;

        streamIdToStream[_currentStreamId] = Stream(
            startTimestamp_,        // Stream.startTimestamp
            endTimestamp_,          // Stream.endTimestamp
            msg.sender,             // Stream.sender
            receiver_,              // Stream.receiver
            token_,                 // Stream.tokenAddress
            0,                      // Stream.lastClaimedTimestamp
            deposit_,               // Stream.deposit
            0                       // Stream.claimed
        );
        
        // After creating the stream, we will add the stream to the correspondents
        addressToOutStreams[msg.sender].push(_currentStreamId);
        addressToInStreams[receiver_].push(_currentStreamId);

        // Then, we emit an Event to broadcast the datas
        emit DripCreated(msg.sender, receiver_, token_, _currentStreamId, deposit_,
            startTimestamp_, endTimestamp_);

        // Return the _currentStreamId for further usage
        return _currentStreamId; 
    }

    function _getLastTimestamp(uint48 startTimestamp_, uint48 lastClaimedTimestamp_) 
    internal pure returns (uint48) {
        return lastClaimedTimestamp_ > startTimestamp_ ?
            lastClaimedTimestamp_ : startTimestamp_;
    }

    function getDripClaimableAmount(uint32 streamId_) public view returns (uint256) {
        // First, we read the startTimestamp and endTimestamp
        // In such way, we will calculate the total time of the drip
        // Then, we will divide the deposit by the drip duration
        // In such way, we will calculate the drip-per-second
        // Then, we calculate the block.timestamp with the startTimestamp
        // This will calculate the time elapsed
        // Then, we do time_elapsed * drip_per_second to get the total claimable
        // amount.
        // Then, we minus it from claimed to return the current-claimable-amount

        // Issue: with calculation of so, if the token is below the divisible amount, 
        // it will return 0. To prevent this, we can use total-calculation based on a
        // different math-logic instead.

        // Grab the Stream and do a MSTORE
        Stream memory _Stream = streamIdToStream[streamId_];

        // If the stream hasn't started yet, return 0 instead. Otherwise, the flow
        // below results in an underflow error.
        if (uint48(block.timestamp) < _Stream.startTimestamp) return 0;

        // Grab the calculation base balance.
        // This value is the total deposit (.deposit) 
        // minus total amount claimed (.claimed)
        uint256 _remainingBalance = _Stream.deposit - _Stream.claimed;

        // If the stream has already ended, return the _remainingBalance.
        if (uint48(block.timestamp) >= _Stream.endTimestamp) return _remainingBalance;

        // Grab the calculation base timestamp. 
        // If stream has never been claimed before, it is startTimestamp.
        // If stream has been claimed before, it is lastClaimedTimestamp.
        uint48 _lastTimestamp = 
            _getLastTimestamp(_Stream.startTimestamp, _Stream.lastClaimedTimestamp);

        // Grab the time elapsed from last claim
        uint48 _timeElapsedFromLastClaim = uint48(block.timestamp) - _lastTimestamp;
        uint48 _totalTimeRemaining = _Stream.endTimestamp - _lastTimestamp;

        uint256 _totalClaimableTokens = 
            ((_remainingBalance * uint256(_timeElapsedFromLastClaim)) / 
            uint256(_totalTimeRemaining));

        return _totalClaimableTokens;
    }

    function getDripRemaining(uint32 streamId_) public view returns (uint256) {
        return streamIdToStream[streamId_].deposit - streamIdToStream[streamId_].claimed;
    }
    function getUndrippedRemaining(uint32 streamId_) public view returns (uint256) {
        return getDripRemaining(streamId_) - getDripClaimableAmount(streamId_);
    }

    // Note: This can result in a slight variance in the total money streamed due to 
    // intiger maths
    function addDrip(uint32 streamId_, uint48 additionalTime_) public {
        // This should calculate the current rate-per-second
        // additionalTime_ will multiple with rate-per-second to result in
        // the required tokens. Then, require a transfer of the total
        // tokens calculated by the functions.
        // Add the timestamp and add the deposit and balance.

        // Grab the Stream and do a MSTORE
        Stream memory _Stream = streamIdToStream[streamId_];

        // Require that the Stream exists, and there is still remaining time. 
        // Drips that have ended must be newly created and cannot be continued.
        require(_Stream.deposit > 0 && 
                _Stream.endTimestamp > uint48(block.timestamp) &&
                _Stream.deposit > _Stream.claimed,
                "Drip has ended or does not exist!");

        // Require that the adder must be the stream creator only
        require(msg.sender == _Stream.sender,
                "Drip not owned by address!");

        require(tokenIsDrippable[_Stream.tokenAddress],
                "Token no longer Drippable!");

        // Calculate the current total time of drip
        uint48 _totalDripTime = _Stream.endTimestamp - _Stream.startTimestamp;

        // Get the current deposit amount
        uint256 _oldDeposit = _Stream.deposit;

        // Get the Tokens Required for Additional Time
        uint256 _requiredTokens = 
            (_oldDeposit * uint256(additionalTime_)) / uint256(_totalDripTime);

        // Transfer the Tokens required for the Additional Time

        // @audit This is vulnerable to re-entrancy! You can steal other user funds with this even if it returns true or n
        // @audit response - unchanged I don't get this

        // 5000 gas balance check
        uint256 _thisBalanceBefore = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        // @audit done - changed transferFrom to safeTransferFrom
        IERC20(_Stream.tokenAddress)
        .safeTransferFrom(msg.sender, address(this), _requiredTokens);

        // 5000 gas balance check
        uint256 _thisBalanceAfter = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        require(_thisBalanceAfter == _thisBalanceBefore + _requiredTokens,
                "Balance exception!");

        // Add the deposit and additional time to the stream (reverts on arithmetic err)
        // @audit gas wastages, just use the _newDeposit you use earlier
        streamIdToStream[streamId_].deposit += _requiredTokens;
        streamIdToStream[streamId_].endTimestamp += additionalTime_;

        // Get the new deposit and end timestamp for event emittance
        // @audit why not juse your old deposit you just made
        uint256 _newDeposit = _oldDeposit + _requiredTokens;
        // @audit Why not just use your endTimestamp you just made?
        uint48 _newEndTimestamp = _Stream.endTimestamp + additionalTime_;

        // Emit Event DripAdded
        emit DripAdded(_Stream.sender, _Stream.receiver, _Stream.tokenAddress,
            streamId_, _oldDeposit, _newDeposit, _Stream.startTimestamp,
            _Stream.endTimestamp, _newEndTimestamp);
    }    
    function getAddDripRequiredAmount(uint32 streamId_, uint48 additionalTime_) 
    external view returns (uint256) {
        Stream memory _Stream = streamIdToStream[streamId_];

        uint48 _totalDripTime = _Stream.endTimestamp - _Stream.startTimestamp;
        uint256 _oldDeposit = _Stream.deposit;
        uint256 _requiredTokens = 
            (_oldDeposit * uint256(additionalTime_)) / uint256(_totalDripTime);

        return _requiredTokens;
    }

    /** @dev addDripVariableRate is the variable rate counterpart of addDrip.
     *  this function allows users to modify streams at currentTime forwards
     *  to yield a different amount of drip-per-second.
     *  By using addDripVariableRate, a claimDrip is initiated first to preserve
     *  any gained tokens to the counterparty before altering the rate afterwards.
     */
    function addDripVariableRate(uint32 streamId_, uint48 additionalTime_,
    uint256 addAmount_) public {

        // First, check if the adder is the stream sender.
        // We read SLOAD here because we will need to reload it afterwards.
        require(msg.sender == streamIdToStream[streamId_].sender,
                "Drip not owned by address!");
            
        // Claim the drip and recalculate the balances.
        claimDrip(streamId_);

        // Now, load the Stream object and MSTORE it
        Stream memory _Stream = streamIdToStream[streamId_];

        // Require that the Stream exists, and there is still remaining time. 
        // Drips that have ended must be newly created and cannot be continued.
        require(_Stream.deposit > 0 && 
                _Stream.endTimestamp > uint48(block.timestamp) &&
                _Stream.deposit > _Stream.claimed,
                "Drip has ended or does not exist!");

        require(tokenIsDrippable[_Stream.tokenAddress],
                "Token no longer Drippable!");

        // 5000 gas balance check
        uint256 _thisBalanceBefore = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        // Transfer the Tokens required for the Additional Time
        IERC20(_Stream.tokenAddress)
        .safeTransferFrom(msg.sender, address(this), addAmount_);

        // 5000 gas balance check
        uint256 _thisBalanceAfter = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        require(_thisBalanceAfter == _thisBalanceBefore + addAmount_,
                "Balance exception!");

        // Now, add the addAmount_ to the total deposit, and add the additionalTime_
        // Note: rate is calculated from remaining balance and remaining time, thus
        // these two SSTORE writes actually adjust the rate of drip.
        streamIdToStream[streamId_].deposit += addAmount_;
        streamIdToStream[streamId_].endTimestamp += additionalTime_;

        // Note: these two in-memory arithmetic is cheaper than SLOAD of streamIdToStream
        uint256 _newDeposit = _Stream.deposit + addAmount_;
        uint48 _newEndTimestamp = _Stream.endTimestamp + additionalTime_; 

        emit DripAddedVariableRate(_Stream.sender, _Stream.receiver, 
            _Stream.tokenAddress, streamId_, _Stream.deposit, _newDeposit, 
            _Stream.startTimestamp, _Stream.endTimestamp, _newEndTimestamp);
    }

    function getDripRate(uint32 streamId_) external view returns (uint256) {
        Stream memory _Stream = streamIdToStream[streamId_];
        
        uint256 _totalClaimableTokens = 
            getDripClaimableAmount(streamId_);

        // The stream does not exist or has ended
        if (_totalClaimableTokens == 0) return 0;
        
        uint48 _lastTimestamp = 
            _getLastTimestamp(_Stream.startTimestamp, _Stream.lastClaimedTimestamp);
        
        uint48 _timeElapsedFromLastClaim = uint48(block.timestamp) - _lastTimestamp;

        return _totalClaimableTokens / uint256(_timeElapsedFromLastClaim);
    }
    function getDripRateIfAdjusted(uint32 streamId_, uint48 additionalTime_, 
    uint256 addAmount_) external view returns (uint256) {
        Stream memory _Stream = streamIdToStream[streamId_];

        uint256 _remainingTokens = 
            getDripRemaining(streamId_);

        // The stream does not exist or has ended
        if (_remainingTokens == 0) return 0;
                
        uint48 _lastTimestamp = 
            _getLastTimestamp(_Stream.startTimestamp, _Stream.lastClaimedTimestamp);

        uint48 _remainingTime = _Stream.endTimestamp - _lastTimestamp;

        _remainingTokens += addAmount_;
        _remainingTime += additionalTime_;

        return _remainingTokens / uint256(_remainingTime);
    }

    /** @dev this function will reduce the deposit of the stream while
     *  maintaining the same endTime, which results in a reduced stream rate
     *  it does a claim first so that the sender cannot penalize funds
     *  that is claimable. Only unclaimable balance is affected. 
     *  Note: this function hasn't been tested extensively */
    function deductDripPenalty(uint32 streamId_, uint256 amount_, 
    string calldata reason_) public {

        // First, we check if the addr is the stream sender.
        // We read SLOAD here because we will need to reload it afterwards.
        require(msg.sender == streamIdToStream[streamId_].sender,
                "Drip not owned by address!");
                
        // Claim the drip and recalculate the balances.
        claimDrip(streamId_);

        // Now, load the Stream object and MSTORE it
        Stream memory _Stream = streamIdToStream[streamId_];

        // Require that the Stream exists, and there is still remaining time. 
        // Drips that have ended must be newly created and cannot be continued.
        require(_Stream.deposit > 0 && 
                _Stream.endTimestamp > uint48(block.timestamp) &&
                _Stream.deposit > _Stream.claimed,
                "Drip has ended or does not exist!");
        
        // We calculate local variable here because we already loaded the 
        // struct into memory. This saves gas as opposed to using getDripRemaining()
        uint256 _remainingBalance = _Stream.deposit - _Stream.claimed;

        // Require that the amount of penalization is below the remaining balance
        require(_remainingBalance >= amount_, 
                "Penalty amount is below remaining balance!");
        
        // Deduct the deposit amount
        streamIdToStream[streamId_].deposit -= amount_;

        uint256 _streamDepositAfter = streamIdToStream[streamId_].deposit;

        // Sanity check that should never happen
        require(_streamDepositAfter >= 
                _Stream.claimed,
                "Drip penalty caused deposit below claimed!");

        // 5000 gas balance check
        uint256 _thisBalanceBefore = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));
        
        // Transfer the tokens to the sender
        IERC20(_Stream.tokenAddress)
        .safeTransfer(msg.sender, amount_);

        // 5000 gas balance check
        uint256 _thisBalanceAfter = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));
        
        require(_thisBalanceAfter == _thisBalanceBefore - amount_,
                "Balance exception!");
        
        emit DripDeductedPenalty(_Stream.sender, _Stream.receiver,
            _Stream.tokenAddress, streamId_, _Stream.deposit, _streamDepositAfter,
            amount_, reason_);
    }

    // This function lets the receiver claim their claimable tokens
    function claimDrip(uint32 streamId_) public {
        
        // Grab the Stream and do a MSTORE
        Stream memory _Stream = streamIdToStream[streamId_];

        // Require that the claimer must be the stream creator OR stream receiver
        // This is so that senders can claim for the receiver and cover the gas costs
        require(msg.sender == _Stream.sender ||
                msg.sender == _Stream.receiver ||
                isController("RELAYER", msg.sender),
                "Drip not authorized!");
        
        // Require that the stream still has balance
        require(_Stream.deposit > _Stream.claimed,
                "Drip fully claimed or does not exist!");
        
        // Get the Claimable Amount for the Receiver
        uint256 _receiverClaimableAmount = getDripClaimableAmount(streamId_);

        // Add the claimable amount to the stream claimed tracker
        streamIdToStream[streamId_].claimed += _receiverClaimableAmount;

        // Add the last claimed timestamp to the stream
        streamIdToStream[streamId_].lastClaimedTimestamp = uint48(block.timestamp);

        // 5000 gas balance check
        uint256 _thisBalanceBefore = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        // Transfer the tokens to the claimer
        // @audit todo - convert transfer to SafeERC20 safeTransfer
        // @audit done - changed transfer to safeTransfer
        IERC20(_Stream.tokenAddress)
        .safeTransfer(_Stream.receiver, _receiverClaimableAmount);

        // 5000 gas balance check
        uint256 _thisBalanceAfter = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        require(_thisBalanceAfter == (_thisBalanceBefore - _receiverClaimableAmount),
                "Balance exception!");

        // Remaining Amount Calculation for Event
        uint256 _amountRemaining = getDripRemaining(streamId_);

        // Emit Event
        emit DripClaimed(_Stream.sender, _Stream.receiver, _Stream.tokenAddress,
            streamId_, _Stream.deposit, _receiverClaimableAmount, _amountRemaining,
            _Stream.startTimestamp, _Stream.endTimestamp, _Stream.lastClaimedTimestamp,
            uint48(block.timestamp));
    }

    // Note: This ends the drip and pays out the remaining balance to both
    // the sender and the receiver
    function endDrip(uint32 streamId_) public {

        // First, we check if the addr is the stream sender.
        // We read SLOAD here because we will need to reload it afterwards.
        require(msg.sender == streamIdToStream[streamId_].sender,
                "Drip not owned by address!");

        // Claim the drip and recalculate the balances.
        claimDrip(streamId_);

        // Now, load the Stream object and MSTORE it
        Stream memory _Stream = streamIdToStream[streamId_];

        // We calculate local variable here because we already loaded the 
        // struct into memory. This saves gas as opposed to using getDripRemaining()
        uint256 _remainingBalance = _Stream.deposit - _Stream.claimed;

        // Require that remaining balance is over 0, otherwise, claim it to end it
        require(_remainingBalance > 0, 
                "No more remaining balance!");
        
        // Deduct the remaining balance from the deposit amount 
        streamIdToStream[streamId_].deposit -= _remainingBalance;

        // Set the new ending time to the time now, since it has ended
        streamIdToStream[streamId_].endTimestamp = uint48(block.timestamp);

        // Store the new deposit value as _depositAfter for compare and event
        uint256 _depositAfter = streamIdToStream[streamId_].deposit;

        // Sanity check that should never happen
        require(_depositAfter == _Stream.claimed,
                "Balance rebalance exception!");
        
        // 5000 gas balance check
        uint256 _thisBalanceBefore = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        // Returning the remaining tokens to the sender
        IERC20(_Stream.tokenAddress)
        .safeTransfer(_Stream.sender, _remainingBalance);

        // 5000 gas balance check
        uint256 _thisBalanceAfter = 
            IERC20(_Stream.tokenAddress).balanceOf(address(this));

        require(_thisBalanceAfter == (_thisBalanceBefore - _remainingBalance),
                "Balance exception after transfer!");
        
        // Finally, emit and event with the data accordingly
        emit DripEnded(_Stream.sender, _Stream.receiver, _Stream.tokenAddress,
        streamId_, _Stream.deposit, _depositAfter, _remainingBalance,
        _Stream.startTimestamp, _Stream.endTimestamp, uint48(block.timestamp));
    }

    // Data Query Helpers
    function addressToOutStreamsLength(address address_) external view 
    returns (uint256) {
        return addressToOutStreams[address_].length;
    }
    function addressToInStreamsLength(address address_) external view
    returns (uint256) {
        return addressToInStreams[address_].length;
    }
    function addressToOutStreamsAll(address address_) external view
    returns (uint32[] memory) {
        return addressToOutStreams[address_];
    }
    function addressToInStreamsAll(address address_) external view
    returns (uint32[] memory) {
        return addressToInStreams[address_];
    }

    function getDripTotalDeposit(uint32 streamId_) external view returns (uint256) {
        return streamIdToStream[streamId_].deposit;
    }
    function getDripTotalClaimed(uint32 streamId_) external view returns (uint256) {
        return streamIdToStream[streamId_].claimed;
    }

    function isDripActive(uint32 streamId_) external view returns (bool) {
        return  streamIdToStream[streamId_].deposit != 
                streamIdToStream[streamId_].claimed;
    }
}

/**
 *  @title DripFinanceBatchable
 *  @dev DripFinanceBatchable is an extension of DripFinance which allows
 *  the core functionality of DripFinance to be able to be batch processed.
 */
contract DripFinanceBatchable is DripFinance {

    /** @dev this function batch-creates drip streams. It also returns an array 
     *  of streamIds as a response, for interfacing purposes. */
    function createDripBatch(address[] calldata receivers_, address[] calldata tokens_,
    uint256[] calldata deposits_, uint48[] calldata startTimestamps_,
    uint48[] calldata endTimestamps_) external returns (uint32[] memory) {

        require(receivers_.length == tokens_.length &&
                receivers_.length == deposits_.length &&
                receivers_.length == startTimestamps_.length &&
                receivers_.length == endTimestamps_.length, 
                "Array lengths mismatch!");

        uint256 l = receivers_.length;
        uint32[] memory _streamIds = new uint32[] (l);

        uint256 i; unchecked { do { 
            
            uint32 _currentStreamId = createDrip(
                receivers_[i], 
                tokens_[i], 
                deposits_[i], 
                startTimestamps_[i], 
                endTimestamps_[i]
            );

            _streamIds[i] = _currentStreamId;

        } while (++i < l); }

        return _streamIds;
    }

    function addDripBatch(uint32[] calldata streamIds_, 
    uint48[] calldata additionalTimes_) external {

        require(streamIds_.length == additionalTimes_.length,
                "Array lengths mismatch!");

        uint256 l = streamIds_.length;
        uint256 i; unchecked { do {
            addDrip(
                streamIds_[i], 
                additionalTimes_[i]
            );
        } while (++i < l); }
    }

    function addDripVariableRateBatch(uint32[] calldata streamIds_, 
    uint48[] calldata additionalTimes_, uint256[] calldata addAmounts_) external {

        require(streamIds_.length == additionalTimes_.length &&
                streamIds_.length == addAmounts_.length,
                "Array lengths mismatch!");

        uint256 l = streamIds_.length;
        uint256 i; unchecked { do {
            addDripVariableRate(
                streamIds_[i], 
                additionalTimes_[i], 
                addAmounts_[i]
            );
        } while (++i < l); }
    }

    function deductDripPenaltyBatch(uint32[] calldata streamIds_,
    uint256[] calldata amounts_, string[] calldata reasons_) external {

        require(streamIds_.length == amounts_.length &&
                streamIds_.length == reasons_.length,
                "Array lengths mismatch!");
                
        uint256 l = streamIds_.length;
        uint256 i; unchecked { do {
            deductDripPenalty(
                streamIds_[i], 
                amounts_[i], 
                reasons_[i]
            );
        } while (++i < l); }
    }

    function claimDripBatch(uint32[] calldata streamIds_) external {
        uint256 l = streamIds_.length;
        uint256 i; unchecked { do {
            claimDrip(
                streamIds_[i]
            );
        } while (++i < l); }
    }

    function endDripBatch(uint32[] calldata streamIds_) external {
        uint256 l = streamIds_.length;
        uint256 i; unchecked { do {
            endDrip(
                streamIds_[i]
            );
        } while (++i < l); }
    }
}

/** 
 *  @title  DripFinancePrototype
 *  @dev DripFinancePrototype is the prototype version of DripFinanceQueryable.
 *  It includes ERC20 rescue functions in order to rescue the funds in case
 *  of contract errors. 
 *
 *  I don't predict any errors to be occuring, but it's always good to have a
 *  degree of additional safety while we wait for official audits to come out.
 *
 *  ~ 0xInuarashi 2022-12-19
 */
contract DripFinancePrototype is DripFinanceBatchable { 

    // Library Hooks
    using SafeERC20 for IERC20;

    /** @dev this function will break streams. please, please use with caution. */
    function ownerRescueFunds(address erc20_, address to_, uint256 amount_) external
    onlyOwner {
        IERC20(erc20_).safeTransfer(to_, amount_);
    }

    /** @dev a wildcard call to do anything. please, please use with caution. */
    function ownerCallWildcard(address to_, bytes calldata data_) external onlyOwner 
    returns (bool, bytes memory) {
        require(to_ != address(0), "to_ == 0x0");
        (bool success, bytes memory returndata) = to_.call(data_);
        return (success, returndata);
    }
}