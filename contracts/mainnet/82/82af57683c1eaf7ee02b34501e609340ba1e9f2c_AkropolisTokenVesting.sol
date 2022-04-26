pragma solidity ^0.5.9;

import '../openzeppelin/TokenVesting.sol';

//Beneficieries template
import "../helpers/BeneficiaryOperations.sol";

contract AkropolisTokenVesting is TokenVesting, BeneficiaryOperations {

    IERC20 private token;

    address private _pendingBeneficiary;

    event LogBeneficiaryTransferProposed(address _beneficiary);
    event LogBeneficiaryTransfered(address _beneficiary);

    constructor (IERC20 _token, uint256 _start, uint256 _cliffDuration, uint256 _duration) public 
        TokenVesting(msg.sender, _start, _cliffDuration, _duration, false) {
            token = _token;
        }

     /**
     * @notice Transfers vested tokens to beneficiary.
     */

    function release() public {
        super.release(token);
    }


     /**
     * @return the token being held.
     */
    function tokenAddress() public view returns (IERC20) {
        return token;
    }

    // MODIFIERS
    /**
    * @dev Allows to perform method by existing beneficiary
    */
    modifier onlyExistingBeneficiary(address _beneficiary) {
        require(isExistBeneficiary(_beneficiary), "address is not in beneficiary array");
        _;
    }

    /**
    * @dev Allows to perform method by pending beneficiary
    */

    modifier onlyPendingBeneficiary {
        require(msg.sender  == _pendingBeneficiary, "Unpermitted operation.");
        _;
    }

    function pendingBeneficiary() public view returns (address) {
        return _pendingBeneficiary;
    }

     /**
        * @dev Allows beneficiaries to change beneficiaryShip and set first beneficiary as default
        * @param _newBeneficiaries defines array of addresses of new beneficiaries
    */
    function transferBeneficiaryShip(address[] memory _newBeneficiaries) public {
        super.transferBeneficiaryShip(_newBeneficiaries);
        _setPendingBeneficiary(beneficiaries[0]);
    }

     /**
        * @dev Allows beneficiaries to change beneficiaryShip and set first beneficiary as default
        * @param _newBeneficiaries defines array of addresses of new beneficiaries
        * @param _newHowManyBeneficiariesDecide defines how many beneficiaries can decide
    */
    
    function transferBeneficiaryShipWithHowMany(address[] memory _newBeneficiaries, uint256 _newHowManyBeneficiariesDecide) public  {
        super.transferBeneficiaryShipWithHowMany(_newBeneficiaries, _newHowManyBeneficiariesDecide);
        _setPendingBeneficiary(beneficiaries[0]);
    }

    /**
        * @dev Allows beneficiaries to change beneficiary as default
         * @param _newBeneficiary defines address of new beneficiary
    */
    function changeBeneficiary(address _newBeneficiary) public onlyManyBeneficiaries {
        _setPendingBeneficiary(_newBeneficiary);
    }

    /**
        * @dev Claim Beneficiary
    */
    function claimBeneficiary() public onlyPendingBeneficiary {
        _changeBeneficiary(_pendingBeneficiary);
        emit LogBeneficiaryTransfered(_pendingBeneficiary);
        _pendingBeneficiary = address(0);
    }

    /*
     * Internal Functions
     *
     */
    /**
        * @dev Set pending Beneficiary address
        * @param _newBeneficiary defines address of new beneficiary
    */
    function _setPendingBeneficiary(address _newBeneficiary) internal onlyExistingBeneficiary(_newBeneficiary) {
        _pendingBeneficiary = _newBeneficiary;
        emit LogBeneficiaryTransferProposed(_newBeneficiary);
    }
}

pragma solidity ^0.5.9;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     */
    constructor (address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(duration > 0, "TokenVesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require(start.add(duration) > block.timestamp, "TokenVesting: final time is before current time");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }

     /**
     * @return change the beneficiary of tokens
     */

    function _changeBeneficiary(address _newBeneficiary) internal {
        _beneficiary = _newBeneficiary;
    }
}

/*
  License: MIT
  Copyright Bitclave, 2018
  It's modified contract BeneficiaryOperations from https://github.com/bitclave/BeneficiaryOperations
*/

pragma solidity ^0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract BeneficiaryOperations {

    using SafeMath for uint256;

    using SafeMath for uint8;
    // VARIABLES

    uint256 public beneficiariesGeneration;
    uint256 public howManyBeneficiariesDecide;
    address[] public beneficiaries;
    bytes32[] public allOperations;
    address internal insideCallSender;
    uint256 internal insideCallCount;
    

    // Reverse lookup tables for beneficiaries and allOperations
    mapping(address => uint8) public beneficiariesIndices; // Starts from 1, size 255
    mapping(bytes32 => uint) public allOperationsIndicies;
    

    // beneficiaries voting mask per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

    //operation -> beneficiaryIndex
    mapping(bytes32 => uint8) internal  operationsByBeneficiaryIndex;
    mapping(uint8 => uint8) internal operationsCountByBeneficiaryIndex;
    // EVENTS

    event BeneficiaryshipTransferred(address[] previousbeneficiaries, uint howManyBeneficiariesDecide, address[] newBeneficiaries, uint newHowManybeneficiarysDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint beneficiariesCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint beneficiariesCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint beneficiariesCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint beneficiariesCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
    
    // ACCESSORS

    function isExistBeneficiary(address wallet) public view returns(bool) {
        return beneficiariesIndices[wallet] > 0;
    }


    function beneficiariesCount() public view returns(uint) {
        return beneficiaries.length;
    }

    function allOperationsCount() public view returns(uint) {
        return allOperations.length;
    }

    /*
      Internal functions
    */

    function _operationLimitByBeneficiaryIndex(uint8 beneficiaryIndex) internal view returns(bool) {
        return (operationsCountByBeneficiaryIndex[beneficiaryIndex] <= 3);
    }
    
    function _cancelAllPending() internal {
        for (uint i = 0; i < allOperations.length; i++) {
            delete(allOperationsIndicies[allOperations[i]]);
            delete(votesMaskByOperation[allOperations[i]]);
            delete(votesCountByOperation[allOperations[i]]);
            //delete operation->beneficiaryIndex
            delete(operationsByBeneficiaryIndex[allOperations[i]]);
        }

        allOperations.length = 0;
        //delete operations count for beneficiary
        for (uint8 j = 0; j < beneficiaries.length; j++) {
            operationsCountByBeneficiaryIndex[j] = 0;
        }
    }


    // MODIFIERS

    /**
    * @dev Allows to perform method by any of the beneficiaries
    */
    modifier onlyAnyBeneficiary {
        if (checkHowManyBeneficiaries(1)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = 1;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after many beneficiaries call it with the same arguments
    */
    modifier onlyManyBeneficiaries {
        if (checkHowManyBeneficiaries(howManyBeneficiariesDecide)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howManyBeneficiariesDecide;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after all beneficiaries call it with the same arguments
    */
    modifier onlyAllBeneficiaries {
        if (checkHowManyBeneficiaries(beneficiaries.length)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = beneficiaries.length;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after some beneficiaries call it with the same arguments
    */
    modifier onlySomeBeneficiaries(uint howMany) {
        require(howMany > 0, "onlySomeBeneficiaries: howMany argument is zero");
        require(howMany <= beneficiaries.length, "onlySomeBeneficiaries: howMany argument exceeds the number of Beneficiaries");
        
        if (checkHowManyBeneficiaries(howMany)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howMany;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    // CONSTRUCTOR

    constructor() public {
        beneficiaries.push(msg.sender);
        beneficiariesIndices[msg.sender] = 1;
        howManyBeneficiariesDecide = 1;
    }

    // INTERNAL METHODS

    /**
     * @dev onlyManybeneficiaries modifier helper
     */
    function checkHowManyBeneficiaries(uint howMany) internal returns(bool) {
        if (insideCallSender == msg.sender) {
            require(howMany <= insideCallCount, "checkHowManyBeneficiaries: nested beneficiaries modifier check require more beneficiarys");
            return true;
        }
        
        
        require((isExistBeneficiary(msg.sender) && (beneficiariesIndices[msg.sender] <= beneficiaries.length)), "checkHowManyBeneficiaries: msg.sender is not an beneficiary");

        uint beneficiaryIndex = beneficiariesIndices[msg.sender].sub(1);
        
        bytes32 operation = keccak256(abi.encodePacked(msg.data, beneficiariesGeneration));

        require((votesMaskByOperation[operation] & (2 ** beneficiaryIndex)) == 0, "checkHowManyBeneficiaries: beneficiary already voted for the operation");
        //check limit for operation
        require(_operationLimitByBeneficiaryIndex(uint8(beneficiaryIndex)), "checkHowManyBeneficiaries: operation limit is reached for this beneficiary");

        votesMaskByOperation[operation] |= (2 ** beneficiaryIndex);
        uint operationVotesCount = votesCountByOperation[operation].add(1);
        votesCountByOperation[operation] = operationVotesCount;

        if (operationVotesCount == 1) {
            allOperationsIndicies[operation] = allOperations.length;
            
            operationsByBeneficiaryIndex[operation] = uint8(beneficiaryIndex);
            
            operationsCountByBeneficiaryIndex[uint8(beneficiaryIndex)] = uint8(operationsCountByBeneficiaryIndex[uint8(beneficiaryIndex)].add(1));
            
            allOperations.push(operation);
            
            
            emit OperationCreated(operation, howMany, beneficiaries.length, msg.sender);
        }
        emit OperationUpvoted(operation, operationVotesCount, howMany, beneficiaries.length, msg.sender);

        // If enough beneficiaries confirmed the same operation
        if (votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, beneficiaries.length, msg.sender);
            return true;
        }

        return false;
    }

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) { // Not last
            allOperations[index] = allOperations[allOperations.length.sub(1)];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length = allOperations.length.sub(1);

        uint8 beneficiaryIndex = uint8(operationsByBeneficiaryIndex[operation]);
        operationsCountByBeneficiaryIndex[beneficiaryIndex] = uint8(operationsCountByBeneficiaryIndex[beneficiaryIndex].sub(1));

        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
        delete operationsByBeneficiaryIndex[operation];
    }

    // PUBLIC METHODS

    /**
    * @dev Allows beneficiaries to change their mind by cancelling votesMaskByOperation operations
    * @param operation defines which operation to delete
    */
    function cancelPending(bytes32 operation) public onlyAnyBeneficiary {

        require((isExistBeneficiary(msg.sender) && (beneficiariesIndices[msg.sender] <= beneficiaries.length)), "checkHowManyBeneficiaries: msg.sender is not an beneficiary");

        uint beneficiaryIndex = beneficiariesIndices[msg.sender].sub(1);
        require((votesMaskByOperation[operation] & (2 ** beneficiaryIndex)) != 0, "cancelPending: operation not found for this user");
        votesMaskByOperation[operation] &= ~(2 ** beneficiaryIndex);
        uint operationVotesCount = votesCountByOperation[operation].sub(1);
        votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, beneficiaries.length, msg.sender);
        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

    /**
    * @dev Allows beneficiaries to change their mind by cancelling all operations
    */

    function cancelAllPending() public onlyManyBeneficiaries {
       _cancelAllPending();
    }



    /**Переписать*/

    /**
    * @dev Allows beneficiaries to change beneficiariesship
    * @param newBeneficiaries defines array of addresses of new beneficiaries
    */
    function transferBeneficiaryShip(address[] memory newBeneficiaries) public {
        transferBeneficiaryShipWithHowMany(newBeneficiaries, newBeneficiaries.length);
    }

    /**
    * @dev Allows beneficiaries to change beneficiaryShip
    * @param newBeneficiaries defines array of addresses of new beneficiaries
    * @param newHowManyBeneficiariesDecide defines how many beneficiaries can decide
    */
    function transferBeneficiaryShipWithHowMany(address[] memory newBeneficiaries, uint256 newHowManyBeneficiariesDecide) public onlyManyBeneficiaries {
        require(newBeneficiaries.length > 0, "transferBeneficiaryShipWithHowMany: beneficiaries array is empty");
        require(newBeneficiaries.length < 256, "transferBeneficiaryshipWithHowMany: beneficiaries count is greater then 255");
        require(newHowManyBeneficiariesDecide > 0, "transferBeneficiaryshipWithHowMany: newHowManybeneficiarysDecide equal to 0");
        require(newHowManyBeneficiariesDecide <= newBeneficiaries.length, "transferBeneficiaryShipWithHowMany: newHowManybeneficiarysDecide exceeds the number of beneficiarys");

        // Reset beneficiaries reverse lookup table
        for (uint j = 0; j < beneficiaries.length; j++) {
            delete beneficiariesIndices[beneficiaries[j]];
        }
        for (uint i = 0; i < newBeneficiaries.length; i++) {
            require(newBeneficiaries[i] != address(0), "transferBeneficiaryShipWithHowMany: beneficiaries array contains zero");
            require(beneficiariesIndices[newBeneficiaries[i]] == 0, "transferBeneficiaryShipWithHowMany: beneficiaries array contains duplicates");
            beneficiariesIndices[newBeneficiaries[i]] = uint8(i.add(1));
        }
        
        emit BeneficiaryshipTransferred(beneficiaries, howManyBeneficiariesDecide, newBeneficiaries, newHowManyBeneficiariesDecide);
        beneficiaries = newBeneficiaries;
        howManyBeneficiariesDecide = newHowManyBeneficiariesDecide;

        _cancelAllPending();
       
        beneficiariesGeneration++;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}