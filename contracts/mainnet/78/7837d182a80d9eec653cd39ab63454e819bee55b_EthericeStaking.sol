/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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


// File contracts/EthericeStaking.sol
pragma solidity 0.8.16;



interface TokenContractInterface {
    function calcDay() external view returns (uint256);

    function lobbyEntry(uint256 _day) external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function dev_addr() external view returns (address);
}

contract EthericeStaking is Ownable, ReentrancyGuard {
    event NewStake(
        address indexed addr,
        uint256 timestamp,
        uint256 indexed stakeId,
        uint256 stakeAmount,
        uint256 stakeDuration
    );
    event StakeCollected(
        address indexed addr,
        uint256 timestamp,
        uint256 indexed stakeId,
        uint256 stakeAmount,
        uint256 divsReceived
    );
    event SellStakeRequest(
        address indexed addr,
        uint256 timestamp,
        uint256 indexed stakeId,
        uint256 price
    );
    event CancelStakeSellRequest(
        address indexed addr,
        uint256 timestamp,
        uint256 indexed stakeId
    );
    event StakeSold(
        address indexed from,
        address indexed to,
        uint256 timestamp,
        uint256 sellAmount,
        uint256 indexed stakeId
    );
    event NewLoanRequest(
        address indexed addr,
        uint256 timestamp,
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 duration,
        uint256 indexed stakeId
    );
    event LoanRequestFilled(
        address indexed filledBy,
        uint256 timestamp,
        address indexed receivedBy,
        uint256 loanamount,
        uint256 indexed stakeId
    );
    event LoanRepaid(
        address indexed paidTo,
        uint256 timestamp,
        uint256 interestAmount,
        uint256 loanamount,
        uint256 indexed stakeId
    );
    event CancelLoanRequest(
        address indexed addr,
        uint256 timestamp,
        uint256 indexed stakeId
    );

    struct stake {
        address owner;
        uint256 tokensStaked;
        uint256 startDay;
        uint256 endDay;
        uint256 forSalePrice;
        uint256 loanRepayments; // loan repayments made on this stake (deduct from divs on withdrawal)
        bool hasCollected;
    }

    /* A map for each  stakeId => struct stake */
    mapping(uint256 => stake) public mapStakes;
    uint256 public lastStakeIndex;
    /* Address => stakeId for a users stakes */
    mapping(address => uint256[]) internal _userStakes;

    struct loan {
        address requestedBy;
        address filledBy;
        uint256 loanAmount;
        uint256 loanInterest;
        uint256 loanDuration;
        uint256 startDay;
        uint256 endDay;
    }
    /* A map for each loan loanId => struct loan */
    mapping(uint256 => loan) public mapLoans;
    /* Address => stakeId for a users loans (address is the person filling the loan not receiving it) */
    mapping(address => uint256[]) internal _userLends;

    /** Hold amount of eth owed to dev fees */
    uint256 public devFees;

    /** Total ETH in the dividend pool for each day */
    mapping(uint256 => uint256) public dayDividendPool;

    /** Total tokens that have been staked each day */
    mapping(uint256 => uint256) public tokensInActiveStake;

    /** TokenContract object  */
    TokenContractInterface public _tokenContract;

    /** Ensures that token contract can't be changed for securiy */
    bool public tokenContractAddressSet = false;

    /** The amount of days each days divs would be spread over */
    uint256 public maxDividendRewardDays = 30;

    /** The max amount of days user can stake */
    uint256 public maxStakeDays = 60;

    uint256 constant public devSellStakeFee = 10;
    uint256 constant public devLoanFeePercent = 2;

    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    receive() external payable {}

    /**
        @dev Set the contract address, must be run before any eth is posted
        to the contract
        @param _address the token contract address
    */
    function setTokenContractAddress(address _address) external {
        require(_address != address(0), "Address cannot be zero");
        require(tokenContractAddressSet == false, "Token contract address already set");
        require(msg.sender==deployer, "Only deployer can set this value");
        require(owner() != deployer, "Ownership must be transferred before contract start");
        tokenContractAddressSet = true;
        _tokenContract = TokenContractInterface(_address);
    }

    /**
        @dev runs when and eth is sent to the divs contract and distros
        it out across the total div days
    */
    function receiveDivs() external payable {
        // calcDay will return 2 when we're processing the divs from day 1
        uint256 _day =  _tokenContract.calcDay();
        require(_day > 1, "receive divs not yet enabled");
        // We process divs for previous day;
        _day--;

        require(msg.sender == address(_tokenContract), "Unauthorized");
        uint256 _daysToSplitRewardsOver = _day < maxDividendRewardDays
            ? _day
            : maxDividendRewardDays;

        if(_day == 1) {
            _daysToSplitRewardsOver = 2 ;
        }
        
        uint256 _totalDivsPerDay = msg.value / _daysToSplitRewardsOver ;
        
        for (uint256 i = 1; i <= _daysToSplitRewardsOver; ) {
            dayDividendPool[_day + i] += _totalDivsPerDay;
            unchecked {
                i++;
            }
        }
    }

    /**
        @dev update the max days dividends are spread over
        @param _newMaxRewardDays the max days
    */
    function updateMaxDividendRewardDays(uint256 _newMaxRewardDays) external onlyOwner {
        require((_newMaxRewardDays <= 60 && _newMaxRewardDays >= 10), "New value must be <= 60 & >= 10");
        maxDividendRewardDays = _newMaxRewardDays;
    }

    /**
     * @dev set the max staking days
     * @param _amount the number of days
     */
    function updateMaxStakeDays(uint256 _amount) external onlyOwner {
        require((_amount <= 300 && _amount > 30), "New value must be <= 300 and > 30");
        maxStakeDays = _amount;
    }

    /**
     * @dev User creates a new stake 
     * @param _amount total tokens to stake
     * @param _days must be less than max stake days. 
     * the more days the higher the gas fee
     */
    function newStake(uint256 _amount, uint256 _days) external nonReentrant {
        require(_days > 1, "Staking: Staking days < 1");
        require(
            _days <= maxStakeDays,
            "Staking: Staking days > max_stake_days"
        );

        uint256 _currentDay = _tokenContract.calcDay();
        require(_currentDay > 0, "Staking not enabled");

        bool success = _tokenContract.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");


        uint256 _stakeId = _getNextStakeId();

        uint256 _endDay =_currentDay + 1 + _days;
        uint256 _startDay = _currentDay + 1;
        mapStakes[_stakeId] = stake({
            owner: msg.sender,
            tokensStaked: _amount,
            startDay: _startDay,
            endDay: _endDay,
            forSalePrice: 0,
            hasCollected: false,
            loanRepayments: 0
        });

        for (uint256 i = _startDay; i < _endDay ;) {
            tokensInActiveStake[i] += _amount;

            unchecked{ i++; }
        }

        _userStakes[msg.sender].push(_stakeId);

        emit NewStake(msg.sender, block.timestamp, _stakeId, _amount, _days);
    }

    /** 
     * @dev Get the next stake id index 
     */
    function _getNextStakeId() internal returns (uint256) {
        lastStakeIndex++;
        return lastStakeIndex;
    }

    /**
     * @dev called by user to collect an outstading stake
     */
    function collectStake(uint256 _stakeId) external nonReentrant {
        stake storage _stake = mapStakes[_stakeId];
        uint256 currentDay = _tokenContract.calcDay();
        
        require(_stake.owner == msg.sender, "Unauthorised");
        require(_stake.hasCollected == false, "Already Collected");
        require( currentDay > _stake.endDay , "Stake hasn't ended");

        // Check for outstanding loans
        loan storage _loan = mapLoans[_stakeId];
        if(_loan.filledBy != address(0)){
            // Outstanding loan has not been paid off 
            // so do that now
            repayLoan(_stakeId);
        } else if (_loan.requestedBy != address(0)) {
            _clearLoan(_stakeId);   
        }

        // Get new instance of loan after potential updates
        _loan = mapLoans[_stakeId];

         // Get the loan from storage again 
         // and check its cleard before we move on
        require(_loan.filledBy == address(0), "Stake has unpaid loan");
        require(_loan.requestedBy == address(0), "Stake has outstanding loan request");
            
        uint256 profit = calcStakeCollecting(_stakeId);
        mapStakes[_stakeId].hasCollected = true;

        // Send user the stake back
        bool success = _tokenContract.transfer(
            msg.sender,
            _stake.tokensStaked
        );
        require(success, "Transfer failed");

        // Send the user divs
        Address.sendValue( payable(_stake.owner) , profit);

        emit StakeCollected(
            _stake.owner,
            block.timestamp,
            _stakeId,
            _stake.tokensStaked,
            profit
        );
    }

    /** 
     * Added an auth wrapper to the cancel loan request
     * so it cant be canceled by just anyone externally
     */
    function cancelLoanRequest(uint256 _stakeId) external {
        stake storage _stake = mapStakes[_stakeId];
        require(msg.sender == _stake.owner, "Unauthorised");
        _cancelLoanRequest(_stakeId);
    }

    function _cancelLoanRequest(uint256 _stakeId) internal {
        mapLoans[_stakeId] = loan({
            requestedBy: address(0),
            filledBy: address(0),
            loanAmount: 0,
            loanInterest: 0,
            loanDuration: 0,
            startDay: 0,
            endDay: 0
        });

        emit CancelLoanRequest(
            msg.sender,
            block.timestamp,
            _stakeId
        );
    }

    function _clearLoan(uint256 _stakeId) internal {
        loan storage _loan = mapLoans[_stakeId];
         if(_loan.filledBy == address(0)) {
                // Just an unfilled loan request so we can cancel it off
                _cancelLoanRequest(_stakeId);
            } else  {
                // Loan was filled so if its not been claimed yet we need to 
                // send the repayment back to the loaner
                repayLoan(_stakeId);
            }
    }

    /**
     * @dev Calculating a stakes ETH divs payout value by looping through each day of it
     * @param _stakeId Id of the target stake
     */
    function calcStakeCollecting(uint256 _stakeId)
        public
        view
        returns (uint256)
    {
        uint256 currentDay = _tokenContract.calcDay();
        uint256 userDivs;
        stake memory _stake = mapStakes[_stakeId];

        for (
            uint256 _day = _stake.startDay;
            _day < _stake.endDay && _day < currentDay;
        ) {
            userDivs +=
                (dayDividendPool[_day] * _stake.tokensStaked) /
                tokensInActiveStake[_day];

                unchecked {
                    _day++;
                }
        }

        delete currentDay;
        delete _stake;

        // remove any loans returned amount from the total
        return (userDivs - _stake.loanRepayments);
    }

    function listStakeForSale(uint256 _stakeId, uint256 _price) external {
        stake memory _stake = mapStakes[_stakeId];
        require(_stake.owner == msg.sender, "Unauthorised");
        require(_stake.hasCollected == false, "Already Collected");

        uint256 _currentDay = _tokenContract.calcDay();
        require(_stake.endDay >= _currentDay, "Stake has ended");

         // can't list a stake for sale whilst we have an outstanding loan against it
        loan storage _loan = mapLoans[_stakeId];
        require(_loan.requestedBy == address(0), "Stake has an outstanding loan request");

        mapStakes[_stakeId].forSalePrice = _price;

        emit SellStakeRequest(msg.sender, block.timestamp, _stakeId, _price);

        delete _currentDay;
        delete _stake;
    }

    function cancelStakeSellRequest(uint256 _stakeId) external {
        require(mapStakes[_stakeId].owner == msg.sender, "Unauthorised");
        require(mapStakes[_stakeId].forSalePrice > 0, "Stake is not for sale");
        mapStakes[_stakeId].forSalePrice = 0;

        emit CancelStakeSellRequest(
            msg.sender,
            block.timestamp,
            _stakeId
        );
    }

    function buyStake(uint256 _stakeId) external payable nonReentrant {
        stake memory _stake = mapStakes[_stakeId];
        require(_stake.forSalePrice > 0, "Stake not for sale");
        require(_stake.owner != msg.sender, "Can't buy own stakes");

        loan storage _loan = mapLoans[_stakeId];
        require(_loan.filledBy == address(0), "Can't buy stake with unpaid loan");

        uint256 _currentDay = _tokenContract.calcDay();
        require(
            _stake.endDay > _currentDay,
            "stake can't be brought after it has ended"
        );
        require(_stake.hasCollected == false, "Stake already collected");
        require(msg.value >= _stake.forSalePrice, "msg.value is < stake price");

        uint256 _devShare = (_stake.forSalePrice * devSellStakeFee) / 100;
        uint256 _sellAmount =  _stake.forSalePrice - _devShare;

        dayDividendPool[_currentDay] += _devShare / 2;
        devFees += _devShare / 2;

        _userStakes[msg.sender].push(_stakeId);

        mapStakes[_stakeId].owner = msg.sender;
        mapStakes[_stakeId].forSalePrice = 0;

        Address.sendValue(payable(_stake.owner), _sellAmount);

        emit StakeSold(
            _stake.owner,
            msg.sender,
            block.timestamp,
            _sellAmount,
            _stakeId
        );

        delete _stake;
    }

    /**
     * @dev send the devFees to the dev wallet
     */
    function flushDevTaxes() external nonReentrant{
        address _devWallet = _tokenContract.dev_addr();
        uint256 _devFees = devFees;
        devFees = 0;
        Address.sendValue(payable(_devWallet), _devFees);
    }

    function requestLoanOnStake(
        uint256 _stakeId,
        uint256 _loanAmount,
        uint256 _interestAmount,
        uint256 _duration
    ) external {

        stake storage _stake = mapStakes[_stakeId];
        require(_stake.owner == msg.sender, "Unauthorised");
        require(_stake.hasCollected == false, "Already Collected");

        uint256 _currentDay = _tokenContract.calcDay();
        require(_stake.endDay > (_currentDay + _duration), "Loan must expire before stake end day");

        loan storage _loan = mapLoans[_stakeId];
        require(_loan.filledBy == address(0), "Stake already has outstanding loan");

        uint256 userDivs = calcStakeCollecting(_stakeId);
        require(userDivs > ( _stake.loanRepayments + _loanAmount + _interestAmount), "Loan amount is > divs earned so far");


        mapLoans[_stakeId] = loan({
            requestedBy: msg.sender,
            filledBy: address(0),
            loanAmount: _loanAmount,
            loanInterest: _interestAmount,
            loanDuration: _duration,
            startDay: 0,
            endDay: 0
        });

        emit NewLoanRequest(
            msg.sender,
            block.timestamp,
            _loanAmount,
            _interestAmount,
            _duration,
            _stakeId
        );
    }

    function fillLoan(uint256 _stakeId) external payable nonReentrant {
        stake storage _stake = mapStakes[_stakeId];
        loan storage _loan = mapLoans[_stakeId];
        
        require(_loan.requestedBy != address(0), "No active loan on this stake");
        require(_stake.hasCollected == false, "Stake Collected");

        uint256 _currentDay = _tokenContract.calcDay();
        require(_stake.endDay > _currentDay, "Stake ended");

        require(_stake.endDay > (_currentDay + _loan.loanDuration), "Loan must expire before stake end day");
        
        require(_loan.filledBy == address(0), "Already filled");
        require(_loan.loanAmount <= msg.value, "Not enough eth");

        require(msg.sender != _stake.owner, "No lend on own stakes");

        if (_stake.forSalePrice > 0) {
            // Can't sell a stake with an outstanding loan so we remove from sale
            mapStakes[_stakeId].forSalePrice = 0;
        }

        mapLoans[_stakeId] = loan({
            requestedBy: _loan.requestedBy,
            filledBy: msg.sender,
            loanAmount: _loan.loanAmount,
            loanInterest: _loan.loanInterest,
            loanDuration: _loan.loanDuration,
            startDay: _currentDay + 1,
            endDay: _currentDay + 1 + _loan.loanDuration
        });

        // Deduct fees
        uint256 _devShare = (_loan.loanAmount * devLoanFeePercent) / 100;
        uint256 _loanAmount = _loan.loanAmount - _devShare; 

        dayDividendPool[_currentDay] += _devShare / 2;
        devFees += _devShare / 2;

        // Send the loan to the requester
        Address.sendValue(payable(_loan.requestedBy), _loanAmount);

        _userLends[msg.sender].push(_stakeId);

        emit LoanRequestFilled(
            msg.sender,
            block.timestamp,
            _stake.owner,
            _loanAmount,
            _stakeId
        );
    }

    /**
     * This function is public so any can call and it
     * will repay the loan to the loaner. Stakes can only
     * have 1 active loan at a time so if the staker wants
     * to take out a new loan they will have to call the 
     * repayLoan function first to pay the outstanding 
     * loan.
     * This avoids us having to use an array and loop
     * through loans to see which ones need paying back
     * @param _stakeId the stake to repay the loan from 
     */
    function repayLoan(uint256 _stakeId) public {
        loan memory _loan = mapLoans[_stakeId];
        require(_loan.requestedBy != address(0), "No loan on stake");
        require(_loan.filledBy != address(0), "Loan not filled");

        uint256 _currentDay = _tokenContract.calcDay();
        require(_loan.endDay <= _currentDay, "Loan duration not met");

        // Save the payment here so its deducted from the divs 
        // on withdrawal
        mapStakes[_stakeId].loanRepayments += (  _loan.loanAmount + _loan.loanInterest );

        _cancelLoanRequest(_stakeId);
        
        Address.sendValue(payable(_loan.filledBy), _loan.loanAmount + _loan.loanInterest);

        // address indexed paidTo,
        // uint256 timestamp,
        // address interestAmount,
        // uint256 loanamount,
        // uint256 stakeId
        emit LoanRepaid(
            _loan.filledBy,
            block.timestamp,
            _loan.loanInterest,
            _loan.loanAmount,
            _stakeId
        );
    }

    function totalDividendPool() external view returns (uint256) {
        uint256 _day = _tokenContract.calcDay();
        // Prevent start day going to -1 on day 0
        if(_day <= 0) {
            return 0;
        }
        uint256 _startDay = _day;
        uint256 _total;
        for (uint256 i = 0; i <= (_startDay +  maxDividendRewardDays) ; ) {
            _total += dayDividendPool[_startDay + i];
            unchecked {
                 i++;
            }
        }
    
        return _total;
    }

    function userStakes(address _address) external view returns(uint256[] memory){
        return _userStakes[_address];
    }

    function userLends(address _address) external view returns (uint256[] memory) {
        return _userLends[_address];
    }
}