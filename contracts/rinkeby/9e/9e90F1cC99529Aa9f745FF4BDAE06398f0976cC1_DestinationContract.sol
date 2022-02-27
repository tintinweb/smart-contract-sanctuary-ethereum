// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Data.sol";

interface IDestinationContract{
    
    struct HashOnionFork{
        bytes32 onionHead;
        bytes32 destOnionHead;
        uint256 allAmount;
        uint256 length;  // !!! change to byte https://jeancvllr.medium.com/solidity-tutorial-all-about-bytes-9d88fdb22676
        address lastCommiterAddress;
        bool needBond; // true is need to settle 
    }
    
    struct MForkData{
        bytes32 forkKey;
        uint256 forkIndex;
        bytes32[] wrongtxHash;
    }

    event newClaim(address dest, uint256 amount, uint256 fee, uint256 txindex, bytes32 hashOnion);
    event newBond(uint256 txIndex,uint256 amount,bytes32 hashOnion);

    function claim(uint256 chainId,bytes32 _forkKey,uint256 _forkIndex, uint256 _workIndex, Data.TransferData[] calldata _transferDatas,bool[] calldata _isResponds) external;
    function zbond(bytes32 _forkKey,bytes32 _preForkKey, uint256 _preForkIndex, Data.TransferData[] calldata _transferDatas, address[] calldata _commiters) external;
    
    function mbond(
        MForkData[] calldata _mForkDatas,
        bytes32 _preForkKey, uint256 _preForkIndex, 
        Data.TransferData[] calldata _transferDatas, address[] calldata _commiters
        ) external; 

    // function getHashOnion(address[] calldata _bonderList,bytes32 _sourceHashOnion, bytes32 _bonderListHash) external;
}

contract DestinationContract is IDestinationContract{
    using SafeERC20 for IERC20;

    mapping(address => bool) public commiterDeposit;   // Submitter's bond record
    mapping(bytes32 => mapping(uint256 => HashOnionFork)) public hashOnionForks; // Submitter's bond record

    mapping(bytes32 => bool) isRespondOnions;   // Whether it is a Onion that is not responded to
    mapping(bytes32 => address) onionsAddress;  // !!! Conflict with using zk scheme, new scheme needs to be considered when using zk

    bytes32 public sourceHashOnion;   // Used to store the sent hash
    bytes32 public onWorkHashOnion;   // Used to store settlement hash

    address tokenAddress;

    uint256 public ONEFORK_MAX_LENGTH = 5;  // !!! The final value is 50 , the higher the value, the longer the wait time and the less storage consumption
    uint256 DEPOSIT_AMOUNT = 1 * 10**18;  // !!! The final value is 2 * 10**17

    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
        hashOnionForks[0x0000000000000000000000000000000000000000000000000000000000000000][0] = HashOnionFork(
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0,
                ONEFORK_MAX_LENGTH,
                address(0),
                false
            );
    }

    /* 
        A. Ensure that a single correct fork link is present:
        There are three behaviors of commiters related to fork:
        1. Create a 0-bit fork
        2. Create a non-zero fork
        3. Add OnionHead to any Fork

        The rules are as follows:
        1. Accept any submission, zero-bit Fork needs to pass in PreForkkey
        2. Fork starting with non-zero bits, length == ONEFORK_MAX_LENGTH - index (value range 1-49)

        B. Ensure that only the only correct fork link will be settled:
        1. onWorkHashOnion's index % ONEFORK_MAX_LENGTH == ONEFORK_MAX_LENGTH
        2. When bonding, the bond is the bond from the back to the front. If the fork being bonded is a non-zero fork, you need to provide preForkKey, onions1, onions2, and the parameters must meet the following conditions:
           2.1 f(onions) == preFork.onionHead
           2.2 onions[0] != fork.key //If there is an equal situation, then give the allAmount of the fork to onions[0].address . The bonder gets a deposit to compensate the gas fee.
           2.3 fork.onionHead == onWorkHashOnion

        C. Guarantee that bad commits will be penalized:
        1. CommiterA deposits the deposit, initiates a commit or fork, and the deposit is locked
        2. The margin can only be unlocked by the addition of another Committer  
    */

    // if fork index % ONEFORK_MAX_LENGTH == 0 
    // !!! Can be used without getting the previous fork
    function zFork(uint256 chainId,bytes32 _forkKey, uint8 _index, address dest, uint256 amount, uint256 fee, bool _isRespond) external{
        // Determine whether msg.sender is eligible to submit
        // require(commiterDeposit[msg.sender] == true, "a1");

        // Take out the Fork
        HashOnionFork storage workFork = hashOnionForks[_forkKey][_index];
        
        // Determine if the previous fork is full
        // !!! use length use length is missing to consider that the last fork is from forkFromInput, you need to modify the usage of length to index
        // require(workFork.length == ONEFORK_MAX_LENGTH,"fork is null"); 

        // !!! Deposit is only required for additional, and a new fork does not require deposit, but how to ensure that the correct sourceOnionHead is occupied by the next submitter, but the wrong destOnionHead is submitted
        // Determine the eligibility of the submitter
        if (commiterDeposit[msg.sender] == false){
            // If same commiter, don't need deposit
            require(msg.sender == workFork.lastCommiterAddress, "a2");
        }

        // Create a new Fork
        HashOnionFork memory newFork;

        // set newFork
        newFork.onionHead = keccak256(abi.encode(workFork.onionHead,keccak256(abi.encode(dest,amount,fee))));
        // Determine whether there is a fork with newFork.destOnionHead as the key
        require(hashOnionForks[newFork.onionHead][0].length == 0, "c1");

        newFork.destOnionHead = keccak256(abi.encode(workFork.destOnionHead, newFork.onionHead , msg.sender));
        
        // Determine whether the maker only submits or submits and responds
        if(_isRespond){
            IERC20(tokenAddress).safeTransferFrom(msg.sender,dest,amount);
        }else{
            // !!! Whether to add the identification position of the index
            isRespondOnions[newFork.onionHead] = true; 
        }
        
        newFork.allAmount += amount + fee;
        newFork.length = 1;
        newFork.lastCommiterAddress = msg.sender;
        newFork.needBond = true;

        // storage
        hashOnionForks[newFork.onionHead][0] = newFork;

        // Locks the new committer's bond, unlocks the previous committer's bond state
        if (workFork.lastCommiterAddress != msg.sender){
            (commiterDeposit[workFork.lastCommiterAddress], commiterDeposit[msg.sender]) = (commiterDeposit[msg.sender], commiterDeposit[workFork.lastCommiterAddress]);
        }

        emit newClaim(dest,amount,fee,0,newFork.onionHead); 
    }

    // if fork index % ONEFORK_MAX_LENGTH != 0
    function mFork(bytes32 _lastOnionHead, bytes32 _lastDestOnionHead, uint8 _index , Data.TransferData calldata _transferData, bool _isRespond) external{
        // Determine whether msg.sender is eligible to submit
        require(commiterDeposit[msg.sender] == true, "a3");

        // Create a new Fork
        HashOnionFork memory newFork;

        // set newFork
        newFork.onionHead = keccak256(abi.encode(_lastOnionHead,keccak256(abi.encode(_transferData))));
        // Determine whether there is a fork with newFork.destOnionHead as the key
        require(hashOnionForks[newFork.onionHead][_index].length == 0, "c1");

        newFork.destOnionHead = keccak256(abi.encode(_lastDestOnionHead, newFork.onionHead , msg.sender));

        // Determine whether the maker only submits or submits and also responds, so as to avoid the large amount of unresponsiveness of the maker and block subsequent commints
        if(_isRespond){
            IERC20(tokenAddress).safeTransferFrom(msg.sender,_transferData.destination,_transferData.amount);
        }else{
            isRespondOnions[newFork.onionHead] = true;
        }
        
        newFork.allAmount += _transferData.amount + _transferData.fee;
        newFork.length = _index;
        newFork.lastCommiterAddress = msg.sender;

        // storage
        hashOnionForks[newFork.onionHead][_index] = newFork;

        // Freeze Margin
        commiterDeposit[msg.sender] = false;
    }

    /* 
        !!! fork from input， Because there is a deposit, I am not afraid of witch attack. Do I need to design a mechanism that the deposit cannot be retrieved?
        Can the deposit mechanism be made more concise?
    */

    // !!! depend  should be split and _forkKey should use destOnionHead
    function claim(uint256 chainId,bytes32 _forkKey, uint256 _forkIndex, uint256 _workIndex, Data.TransferData[] calldata _transferDatas,bool[] calldata _isResponds) external override{
        
        // incoming data length is correct
        require(_transferDatas.length > 0, "a1");

        // positioning fork
        HashOnionFork memory workFork = hashOnionForks[_forkKey][_forkIndex];
        
        // Determine whether this fork exists
        require(workFork.length > 0,"fork is null"); //use length

        // Determine the eligibility of the submitter
        if (commiterDeposit[msg.sender] == false){
            require(msg.sender == workFork.lastCommiterAddress, "a3");
        }
        
        // Determine whether someone has submitted it before. If it has been submitted by the predecessor, msg.sender thinks that the submission is incorrect and can be forked and resubmitted through forkFromInput
        // !!! Avoid duplicate submissions
        require(_workIndex == workFork.length, "b2");
        
        // Judge _transferDatas not to exceed the limit
        require(_workIndex + _transferDatas.length <= ONEFORK_MAX_LENGTH, "a2");
        
        bytes32 onionHead = workFork.onionHead;
        bytes32 destOnionHead = workFork.destOnionHead;
        uint256 allAmount = 0;
        // just append
        for (uint256 i; i < _transferDatas.length; i++){
            onionHead = keccak256(abi.encode(onionHead,keccak256(abi.encode(_transferDatas[i]))));
            if(_isResponds[i]){
                IERC20(tokenAddress).safeTransferFrom(msg.sender,_transferDatas[i].destination,_transferDatas[i].amount);
            }else{
                isRespondOnions[onionHead] = true;
            }
            destOnionHead = keccak256(abi.encode(destOnionHead,onionHead,msg.sender));
            allAmount += _transferDatas[i].amount + _transferDatas[i].fee;

            emit newClaim(_transferDatas[i].destination,_transferDatas[i].amount,_transferDatas[i].fee,_workIndex+i,onionHead); 
        }

        // change deposit , deposit token is ETH , need a function to deposit and with draw
        if (workFork.lastCommiterAddress != msg.sender){
            (commiterDeposit[workFork.lastCommiterAddress], commiterDeposit[msg.sender]) = (commiterDeposit[msg.sender], commiterDeposit[workFork.lastCommiterAddress]);
        }

        workFork = HashOnionFork({
            onionHead: onionHead, 
            destOnionHead: destOnionHead,
            allAmount: allAmount + workFork.allAmount,
            length: _workIndex + _transferDatas.length,
            lastCommiterAddress: msg.sender,
            needBond: workFork.needBond
        });
        
        hashOnionForks[_forkKey][_forkIndex] = workFork;
    }

    // clearing zfork
    // !!! how to clearing the first zfork that have no preFork
    function zbond(
        bytes32 _forkKey,
        bytes32 _preForkKey, uint256 _preForkIndex, 
        Data.TransferData[] calldata _transferDatas, address[] calldata _commiters
        ) external override{

        // incoming data length is correct
        require(_transferDatas.length > 0, "a1");
        require(_commiters.length == _transferDatas.length, "a2");

        HashOnionFork memory workFork = hashOnionForks[_forkKey][0];
        
        // Judging whether this fork exists && Judging that the fork needs to be settled
        require(workFork.needBond, "a3"); 
        workFork.needBond = false;

        // Determine whether the onion of the fork has been recognized
        require(workFork.onionHead == onWorkHashOnion,"a4"); //use length

        HashOnionFork memory preWorkFork = hashOnionForks[_preForkKey][_preForkIndex];
        // Determine whether this fork exists
        require(preWorkFork.length > 0,"fork is null"); //use length

        bytes32 onionHead = preWorkFork.onionHead;
        bytes32 destOnionHead = preWorkFork.destOnionHead;
        // repeat
        for (uint256 i; i < _transferDatas.length; i++){
            onionHead = keccak256(abi.encode(onionHead,keccak256(abi.encode(_transferDatas[i]))));
            if (isRespondOnions[onionHead]){
                if (onionsAddress[onionHead] != address(0)){
                    IERC20(tokenAddress).safeTransfer(onionsAddress[onionHead],_transferDatas[i].amount + _transferDatas[i].fee);
                }else{
                    IERC20(tokenAddress).safeTransfer(_transferDatas[i].destination,_transferDatas[i].amount + _transferDatas[i].fee);
                }
            }else{
                IERC20(tokenAddress).safeTransfer(_commiters[i],_transferDatas[i].amount + _transferDatas[i].fee);
            }
            destOnionHead = keccak256(abi.encode(destOnionHead,onionHead,_commiters[i]));
        }
        
        // Assert that the replay result is equal to the stored value of the fork, which means that the incoming _transferdatas are valid
        require(destOnionHead == workFork.destOnionHead,"a5");

        // If the prefork also needs to be settled, push the onWorkHashOnion forward a fork
        if (preWorkFork.needBond){
            onWorkHashOnion = preWorkFork.onionHead;
        }else{ 
            // If no settlement is required, it means that the previous round of settlement is completed, and a new value is set
            onWorkHashOnion = sourceHashOnion;
        }

        // !!! Reward bonder
    }
    

    // Settlement non-zero fork
    function mbond(
        MForkData[] calldata _mForkDatas,
        bytes32 _preForkKey, uint256 _preForkIndex, 
        Data.TransferData[] calldata _transferDatas, address[] calldata _commiters
        ) external override{
        
        require( _mForkDatas.length > 1, "a1");
        
        // incoming data length is correct
        require(_transferDatas.length == ONEFORK_MAX_LENGTH, "a1");
        require(_transferDatas.length == _commiters.length, "a2");

        HashOnionFork memory preWorkFork = hashOnionForks[_preForkKey][_preForkIndex];
        // Determine whether this fork exists
        require(preWorkFork.length > 0,"fork is null"); //use length

        bytes32 onionHead = preWorkFork.onionHead;
        bytes32 destOnionHead = preWorkFork.destOnionHead;
        uint256 y = 0;

        // repeat
        for (uint256 i; i < _transferDatas.length; i++){
            bytes32 preForkOnionHead = onionHead;
            onionHead = keccak256(abi.encode(onionHead,keccak256(abi.encode(_transferDatas[i]))));
            
            /* 
                If this is a fork point, make two judgments
                1. Whether the parallel fork points of the fork point are the same, if they are the same, it means that the fork point is invalid, that is, the bond is invalid. And submissions at invalid fork points will not be compensated
                2. Whether the headOnion of the parallel fork point can be calculated by the submission of the bond, if so, the incoming parameters of the bond are considered valid
            */
            if(_mForkDatas[y].forkIndex == i){
                // Determine whether the fork needs to be settled, and also determine whether the fork exists
                checkForkData(_mForkDatas[y-1],_mForkDatas[y],preForkOnionHead,onionHead,i);
                y += 1;
                // !!! Calculate the reward, and reward the bond at the end, the reward fee is the number of forks * margin < margin equal to the wrongtx gaslimit overhead brought by 50 Wrongtx in this method * common gasPrice>
            }

            if (isRespondOnions[onionHead]){
                if (onionsAddress[onionHead] != address(0)){
                    IERC20(tokenAddress).safeTransfer(onionsAddress[onionHead],_transferDatas[i].amount + _transferDatas[i].fee);
                }else{
                    IERC20(tokenAddress).safeTransfer(_transferDatas[i].destination,_transferDatas[i].amount + _transferDatas[i].fee);
                }
            }else{
                IERC20(tokenAddress).safeTransfer(_commiters[i],_transferDatas[i].amount + _transferDatas[i].fee);
            }
            destOnionHead = keccak256(abi.encode(destOnionHead,onionHead,_commiters[i]));
        }
        
        // Assert the replay result, indicating that the fork is legal
        require(onionHead == onWorkHashOnion,"a2");
        // Assert that the replay result is equal to the stored value of the fork, which means that the incoming _transferdatas are valid
        require(destOnionHead == hashOnionForks[_mForkDatas[y].forkKey][_mForkDatas[y].forkIndex].destOnionHead,"a4");

        // If the prefork also needs to be settled, push the onWorkHashOnion forward a fork
        if (preWorkFork.needBond){
            onWorkHashOnion = preWorkFork.onionHead;
        }else{ 
            // If no settlement is required, it means that the previous round of settlement is completed, and a new value is set
            onWorkHashOnion = sourceHashOnion;
        }
    }

    function checkForkData (MForkData calldata preForkData, MForkData calldata forkData, bytes32 preForkOnionHead, bytes32 onionHead,uint256 i) internal {
        require(hashOnionForks[forkData.forkKey][forkData.forkIndex].needBond == true, "b1");
        if(i != 0 ){
            // Calculate the onionHead of the parallel fork based on the preonion and the tx of the original path
            preForkOnionHead = keccak256(abi.encode(preForkOnionHead, forkData.wrongtxHash[0]));
            // If the parallel Onion is equal to the key of forkOnion, it means that forkOnion is illegal
            require(preForkOnionHead != onionHead,"a2");
            // After passing, continue to calculate AFok
            uint256 x = 1;
            while (x < forkData.wrongtxHash.length) {
                preForkOnionHead = keccak256(abi.encode(preForkOnionHead,forkData.wrongtxHash[x]));
                x++;
            }
            // Judging that the incoming _wrongTxHash is in line with the facts, avoid bond forgery AFork.nextOnion == BFork.nextOnion
            require(preForkOnionHead == hashOnionForks[preForkData.forkKey][preForkData.forkIndex].onionHead);
        }
        hashOnionForks[forkData.forkKey][forkData.forkIndex].needBond = false;
    }
    
    // !!!
    function setHashOnion(bytes32 _sourceHashOnion) external{
        // judging only trust a target source

        // save sourceHashOnion
        sourceHashOnion = _sourceHashOnion;
        if (onWorkHashOnion == "") {
            onWorkHashOnion = _sourceHashOnion;
        }

        // Settlement for bond
    }

    function buyOneFork(uint256 _forkKey, uint256 _forkId) external{
        // Unfinished hashOnions can be purchased
    }

    function becomeCommiter() external{
        // !!! need deposit
        commiterDeposit[msg.sender] = true;
    }

    function buyOneOnion(bytes32 preHashOnion,Data.TransferData calldata _transferData) external{
        bytes32 key = keccak256(abi.encode(preHashOnion,keccak256(abi.encode(_transferData))));
        require( isRespondOnions[key], "a1");
        require( onionsAddress[key] == address(0), "a1");

        IERC20(tokenAddress).safeTransferFrom(msg.sender,_transferData.destination,_transferData.amount);
        onionsAddress[key] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

library Data {
    struct TransferData{
        address destination;
        uint256 amount;
        uint256 fee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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