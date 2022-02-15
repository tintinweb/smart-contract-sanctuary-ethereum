// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libraries/FullMath.sol";
import "./SetParams.sol";

contract Staking is SetParams {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    /// Array of addresses that we use to fund requests
    EnumerableSet.AddressSet internal requestArray;
    /// Constant address of BRBC, which is forbidden to owner for withdraw
    address constant internal BRBC_ADDRESS = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    IERC20 public USDC;
    IERC20 public BRBC;

    struct TokenLP {
        // USDC amount in
        uint USDCAmount;
        // BRBC amount in
        uint BRBCAmount;
        // End period of stake
        uint32 deadline;
        // Parameter that represesnts our rewards
        uint lastRewardGrowth;
        // true -> recieving rewards, false -> doesn't recieve
        bool isStaked; // uint 8
    }

    TokenLP[] public tokensLP;

    // Mapping that stores all token ids of an owner (owner => tokenIds[])
    mapping(address => EnumerableSet.UintSet) internal ownerToTokens;
    // tokenId => spender
    mapping(uint => address) public tokenApprovals;
    // owner => tokenId => boolean
    mapping(address => mapping(uint => bool)) public withdrawRequest;
    // withdrawAdress => tokenId => boolean
    mapping(address => mapping(uint => bool)) public approvedWithdrawToken;
    // tokenId => amount total collected
    mapping(uint => uint) public collectedRewardsForToken;

    // Total amount of USDC stacked in pool
    uint public poolUSDC;
    // Total amount of BRBC stacked in pool
    uint public poolBRBC;
    // Parameter that represesnts our rewards
    uint public rewardGrowth = 1;
    uint8 constant internal decimals = 18;

    /// List of events
    event Burn(address from, address to, uint tokenId);
    event Stake(address from, address to, uint amountUsdc, uint amountBrbc, uint period, uint tokenId);
    event Approve(address from, address to, uint tokenId);
    event Transfer(address from, address to, uint tokenId);
    event AddRewards(address from, address to, uint amount);
    event ClaimRewards(address from, address to, uint tokenId, uint userReward);
    event RequestWithdraw(address requestAddress, uint tokenId, uint amountUSDC, uint amountBRBC);
    event FromClaimRewards(address from, address to, uint tokenId, uint userReward);
    event Withdraw(address from, address to, uint tokenId, uint amountUSDC, uint amountBRBC);


    // TokenAddr will be hardcoded
    constructor(address _tokenAddrUSDC, address _tokenAddrBRBC) {
        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER, msg.sender);
        // Rates for USDC/BRBC
        rate[30 seconds] = 100;
        rate[90 seconds] = 85;
        rate[180 seconds] = 70;
        // Set up penalty amount
        penalty = 10;
        // Initial start and end time
        startTime = block.timestamp; // + 5 seconds;
        endTime = startTime + 500 seconds;
        // set up pool size
        minUSDCAmount = 10000 * 10 ** decimals;
        maxUSDCAmount = 100000 * 10 ** decimals;
        maxPoolUSDC = 3000000 * 10 ** decimals;
        maxPoolBRBC = 3000000 * 10 ** decimals;
        // Set up tokens, might be hardcoded?
        USDC = IERC20(_tokenAddrUSDC);
        BRBC = IERC20(_tokenAddrBRBC);
        // Initial token id = 0 TODO: test is it nedeed?
        tokensLP.push(TokenLP(0, 0, 0, 0, false));
        penaltyReciver = msg.sender;
    }

    /// @dev Prevents calling a function from anyone except the owner,
    /// list all tokens of a user to find a match
    /// @param _tokenId the id of a token
    modifier OwnerOf(uint _tokenId) {
        require(
            ownerToTokens[msg.sender].contains(_tokenId) == true,
            "You need to be an owner"
        );
        _;
    }

    /// @dev Prevents using unstaked tokens
    /// @param _tokenId the id of a token
    modifier IsInStake(uint _tokenId) {
        require(
            tokensLP[_tokenId].isStaked == true,
            "Stake requested for withdraw"
        );
        _;
    }

    /// @dev Prevents calling a function from anyone except the approved person
    /// @param _tokenId the global token id of a token
    modifier ApprovedOf(uint _tokenId) {
        require(
            tokenApprovals[_tokenId] == msg.sender,
            "You must have approval to move your stake"
        );
        _;
    }

    /// @dev Prevents calling a function with two arrays of different length
    /// @param _array1 is the array of addreses with tokens or contracts
    /// @param _array2 is the array of amounts, which macthes addresses or contracts
    modifier ArrayLengthEquals(address[] calldata _array1, uint[] calldata _array2) {
        require(
            _array1.length == _array2.length,
            "Arrays length mismath"
        );
        _;
    }

    /// @dev Prevents withdrawing rewards with zero reward
    /// @param _tokenId global token id
    modifier PositiveRewards(uint _tokenId){
        require(
            viewRewards(_tokenId) > 0,
            "You have 0 rewards"
        );
        _;
    }

    /// @dev This modifier prevents one person to own more than 100k USDC for this address
    /// @param _stakeOwner the address of owner
    /// @param _amount the USDC amount to stake
    modifier MaxStakeAmount(address _stakeOwner, uint _amount) {
        uint[] memory ownerTokenList = getTokensByOwner(_stakeOwner);
        uint _usdcAmount = _amount;
        for (uint i = 0; i < ownerTokenList.length; i++) {
            _usdcAmount += tokensLP[ownerTokenList[i]].USDCAmount;
            require(
                _usdcAmount <= maxUSDCAmount,
                "Maximum amount for stake for one user is 100000 USDC"
            );
        }
        _;
    }

    /// @dev This modifier prevents transfer of tokens to self and null addresses
    /// @param _to the token reciever
    modifier TransferCheck (address _to) {
        require(
            _to != msg.sender && _to != address(0),
            "You can't transfer to yourself or to null address"
        );
        _;
    }

    /// @dev Main function, which recieves deposit, calls _mint LP function, freeze funds
    /// @param _amountUSDC the amount in of USDC
    /// @param _period the time while tokens will be freezed
    function stake(
        uint _amountUSDC,
        uint32 _period
    ) public MaxStakeAmount(msg.sender, _amountUSDC) {
        /// Prevent user enter stake before the start of staking
        require(
            block.timestamp >= startTime,
            "Staking period hasn't started"
        );
        /// Prevent user enter stake afer the end of staking
        require(
            block.timestamp <= endTime,
            "Staking period has ended"
        );
        /// Checks the validity of time input, prevents a user to enter for a long period if stake is already started
        require(
            _period == 30 seconds || _period == 90 seconds || _period == 180 seconds && block.timestamp + _period <= endTime,
            "Invalid period"
        );
        /// Minimal amount of USDC to stake at once
        require(
            _amountUSDC >= minUSDCAmount,
            "Minimum amount for stake is 10000 USDC"
        );
        /// Maximum amount of tokens freezed in pool
        require(
            poolUSDC + _amountUSDC <= maxPoolUSDC && poolBRBC + (_amountUSDC * rate[_period] / 100) <= maxPoolBRBC,
            "Max pool size exceeded"
        );
        /// Transfer USDC from user to the cross chain, BRBC to this contract, mints LP
        USDC.transferFrom(msg.sender, crossChain, _amountUSDC);
        BRBC.transferFrom(msg.sender, address(this), _amountUSDC * rate[_period] / 100);
        _mint(_amountUSDC, _amountUSDC * rate[_period] / 100, _period);
    }

    /// @dev list of all tokens that an address owns
    /// @param _tokenOwner the owner address
    /// returns uint array of token ids
    function getTokensByOwner(address _tokenOwner) public view returns(uint[] memory) {
        uint[] memory _result = new uint[](ownerToTokens[_tokenOwner].length());
        for (uint i = 0; i < ownerToTokens[_tokenOwner].length(); i++) {
            _result[i] = (ownerToTokens[_tokenOwner].at(i));
        }
        return _result;
    }

    /// @dev parsed array with all data from token ids
    /// @param _tokenOwner the owner address
    /// returns parsed array with all data from token ids
    function getTokensByOwnerParsed(address _tokenOwner) public view returns(TokenLP[] memory) {
        uint[] memory _tokens = new uint[](ownerToTokens[_tokenOwner].length());
        _tokens = getTokensByOwner(_tokenOwner);
        TokenLP[] memory _parsedArrayOfTokens = new TokenLP[](ownerToTokens[_tokenOwner].length());
        for (uint i = 0; i < _tokens.length; i++) {
            _parsedArrayOfTokens[i] = tokensLP[_tokens[i]];
        }
        return _parsedArrayOfTokens;
    }

    /// @dev Internal function that mints LP
    /// @param _USDCAmount the amount of USDT in
    /// @param _BRBCAmount the amount of BRBC in
    /// @param _timeBeforeUnlock the period of time, while which tokens are freezed
    function _mint(
        uint _USDCAmount,
        uint _BRBCAmount,
        uint32 _timeBeforeUnlock
    ) internal {
        tokensLP.push(TokenLP(_USDCAmount, _BRBCAmount, uint32(block.timestamp + _timeBeforeUnlock), rewardGrowth, true));
        uint _tokenId = tokensLP.length - 1;
        poolUSDC = poolUSDC + _USDCAmount;
        poolBRBC = poolBRBC + _BRBCAmount;
        ownerToTokens[msg.sender].add(_tokenId);
        emit Stake(address(0), msg.sender, _USDCAmount, _BRBCAmount, _timeBeforeUnlock, _tokenId);
    }

    /// @dev OnlyManager function, withdraws any erc20 tokens on this address except BRBC
    /// @param _tokenAddresses the array of contract addresses
    /// @param _tokenAmounts the array of amounts, which macthes contracts
    /// @param _to token reciever
    function withdrawToOwner(
        address[] calldata _tokenAddresses,
        uint[] calldata _tokenAmounts,
        address _to
    ) external OnlyManager ArrayLengthEquals(_tokenAddresses, _tokenAmounts) {
        if (_tokenAddresses.length > 0) {
            for (uint i = 0; i < _tokenAddresses.length; i++) {
                require(
                    _tokenAddresses[i] != BRBC_ADDRESS,
                    "You can't withdraw user's BRBC"
                );
                IERC20(_tokenAddresses[i]).transferFrom(address(this), _to, _tokenAmounts[i]);
            }
        }
    }

    /// @dev Internal function which burns LP tokens, clears data from mappings, arrays
    /// @param _tokenId the global token id that will be burnt
    function _burn(uint _tokenId) internal {
        poolUSDC = poolUSDC - tokensLP[_tokenId].USDCAmount;
        poolBRBC = poolBRBC - tokensLP[_tokenId].BRBCAmount;
        delete tokensLP[_tokenId];
        ownerToTokens[msg.sender].remove(_tokenId);
        tokenApprovals[_tokenId] = address(0);
        emit Burn(msg.sender, address(0), _tokenId);
    }

    /// @dev Approves _spender to move his stake, can be called only by an owner
    /// @param _spender the address which recieves permission to move the stake
    /// @param _tokenId the token id
    function approve(
        address _spender, uint _tokenId
    ) external
    OwnerOf(_tokenId)
    IsInStake(_tokenId) {
        tokenApprovals[_tokenId] = _spender;
        emit Approve(msg.sender, _spender, _tokenId);
    }

    /// @dev private function which is used to transfer stakes
    /// @param _from the sender address
    /// @param _to the recipient
    /// @param _tokenId global token id
    function _transfer(
        address _from,
        address _to,
        uint _tokenId
    ) private
    IsInStake(_tokenId) {
        ownerToTokens[_from].remove(_tokenId);
        ownerToTokens[_to].add(_tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Transfer function, check for validity address to, ownership of the token, the USDT amount of recipient
    /// @param _to the recipient
    /// @param _tokenId the token id
    function transfer(
        address _to,
        uint _tokenId
    ) external
    TransferCheck(_to)
    OwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Transfer function, check for validity address to, allowance of the token, the USDT amount of recipient
    /// @param _from the sender address
    /// @param _to the recipient
    /// @param _tokenId the token id
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) external
    TransferCheck(_to)
    ApprovedOf(_tokenId) {
        _transfer(_from, _to, _tokenId);
    }

    /// @dev OnlyManager function, adds rewards for users
    /// @param _amount the USDC amount of comission to the pool
    function addRewards(uint _amount) external OnlyManager {
        USDC.transferFrom(msg.sender, address(this), _amount);
        rewardGrowth = rewardGrowth + FullMath.mulDiv(_amount, 10 ** 29, poolUSDC);
        emit AddRewards(msg.sender, address(this), _amount);
    }

    /// @dev Shows the amount of rewards that wasn't for a token, doesn't give permission to see null token
    /// @param _tokenId the token id
    /// returns reward in USDC
    function viewRewards(uint _tokenId) public view IsInStake(_tokenId) returns (uint) {
        return tokensLP[_tokenId].USDCAmount * (rewardGrowth - tokensLP[_tokenId].lastRewardGrowth) / (10 ** 29);
    }

    /// @dev Shows the amount of rewards that wasn claimed for a token, doesn't give permission to see null token
    /// @param _tokenId the token id
    /// returns reward in USDC
    function viewCollectedRewards(uint _tokenId) public view returns (uint) {
        return collectedRewardsForToken[_tokenId];
    }

    /// @dev Withdraw reward USDT from the contract, checks if the reward is positive,
    /// @dev doesn't give permission to use null token
    /// @param _tokenId the global token id
    /// Added param rewardAmount for reentrancy protection
    function claimRewards(uint _tokenId)
    public
    OwnerOf(_tokenId)
    IsInStake(_tokenId)
    PositiveRewards(_tokenId) {
        uint _rewardAmount = viewRewards(_tokenId);
        tokensLP[_tokenId].lastRewardGrowth = rewardGrowth;
        collectedRewardsForToken[_tokenId] += _rewardAmount;
        USDC.transfer(msg.sender, _rewardAmount);
        emit ClaimRewards(address(this), msg.sender, _tokenId, _rewardAmount);
    }

    /// @dev Same as claimRewards function but can be called from approved user
    /// @param _tokenId the token id
    /// Added param rewardAmount for reentrancy protection
    function fromClaimRewards(uint _tokenId)
    external
    IsInStake(_tokenId)
    ApprovedOf(_tokenId)
    PositiveRewards(_tokenId) {
        uint rewardAmount = viewRewards(_tokenId);
        tokensLP[_tokenId].lastRewardGrowth = rewardGrowth;
        USDC.transfer(msg.sender, rewardAmount);
        emit FromClaimRewards(address(this), msg.sender, _tokenId, rewardAmount);
    }

    /// @dev Send a request for withdraw, claims reward, stops staking
    /// @param _tokenId the token id
    function requestWithdraw(uint _tokenId) external OwnerOf(_tokenId) IsInStake(_tokenId) {
        require(
            withdrawRequest[msg.sender][_tokenId] == false,
            "You request is already sent"
        );
        withdrawRequest[msg.sender][_tokenId] = true;
        requestArray.add(msg.sender);

        claimRewards(_tokenId);
        tokensLP[_tokenId].isStaked = false;

        /// TODO: is it reentrancy protected?
        if (tokensLP[_tokenId].deadline < block.timestamp - 1 seconds) {
            poolUSDC -= tokensLP[_tokenId].USDCAmount * penalty / 100;
            tokensLP[_tokenId].USDCAmount = tokensLP[_tokenId].USDCAmount * (100 - penalty) / 100;
            poolBRBC -= tokensLP[_tokenId].BRBCAmount * penalty / 100;
            uint beforePenaltyBRBC = tokensLP[_tokenId].BRBCAmount;
            tokensLP[_tokenId].BRBCAmount = tokensLP[_tokenId].BRBCAmount * (100 - penalty) / 100;
            BRBC.transfer(penaltyReciver, beforePenaltyBRBC * penalty / 100);
        }
        emit RequestWithdraw(msg.sender, _tokenId, tokensLP[_tokenId].USDCAmount, tokensLP[_tokenId].BRBCAmount);
    }

    /// @dev Shows the status of the user's token id for withdraw
    /// @param _from token owner
    /// @param _tokenId the token id
    function viewRequests(address _from, uint _tokenId) public view returns(bool) {
        return withdrawRequest[_from][_tokenId];
    }

    /// @dev Shows the array of addresses, which made a request
    function getRequestArray() public view returns (address[] memory) {
        address[] memory _result = new address[](requestArray.length());
        for (uint i = 0; i < requestArray.length(); i++) {
            _result[i] = requestArray.at(i);
        }
        return _result;
    }

    /// @dev Send USDC to contract, after this address can withdraw funds back
    /// @param _withdrawAddress the array of addresses reciving withdraw
    /// @param _tokenIds the array of token ids, which macthes addresses
    function fundRequestsForWithdraw(
        address[] calldata _withdrawAddress,
        uint[] calldata _tokenIds
        ) external OnlyManager ArrayLengthEquals(_withdrawAddress, _tokenIds) {
        uint _fundAmount;
        for (uint i = 0; i < _withdrawAddress.length; i++) {
            require(
                withdrawRequest[_withdrawAddress[i]][_tokenIds[i]] == true,
                "Address doesn't make request to withdraw"
            );
            _fundAmount += tokensLP[_tokenIds[i]].USDCAmount;

            approvedWithdrawToken[_withdrawAddress[i]][_tokenIds[i]] = true;
            requestArray.remove(_withdrawAddress[i]); /// TODO: TEST
            delete(withdrawRequest[_withdrawAddress[i]][_tokenIds[i]]);
        }
        USDC.transferFrom(msg.sender, address(this), _fundAmount);
    }

    /// @dev User withdraw his freezed USDC and BRBC after stake
    /// @param _tokenId the token id
    function withdraw(uint _tokenId) external OwnerOf(_tokenId) {
        require(
            approvedWithdrawToken[msg.sender][_tokenId] == true,
            "Your must send withdraw request first, or your request hasn't been approved"
        );
        delete(approvedWithdrawToken[msg.sender][_tokenId]);
        USDC.transfer(msg.sender, tokensLP[_tokenId].USDCAmount);
        BRBC.transfer(msg.sender, tokensLP[_tokenId].BRBCAmount);
        _burn(_tokenId);
        emit Withdraw(address(this), msg.sender, _tokenId, tokensLP[_tokenId].USDCAmount, tokensLP[_tokenId].BRBCAmount);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity  ^0.8.0;

import "./AcessControl.sol";

contract SetParams is AccessControl {
    /// Cross chain address where USDC goes
    /// Todo: change to internal where possible for gas savings
    address public crossChain = 0xA4EED63db85311E22dF4473f87CcfC3DaDCFA3E3;
    /// Changeable address of BRBC reciver
    address public penaltyReciver;

    // Start time of staking
    uint public startTime;
    // End time of stacking
    uint public endTime;
    // Minimal amount of USDC to stake at once
    uint public minUSDCAmount;
    // Maximum amount of USDC freezed in pool
    uint public maxPoolUSDC;
    // Maximum amount of BRBC freezed in pool
    uint public maxPoolBRBC;
    // Maximum amount for one user to stake
    uint public maxUSDCAmount;
    // Penalty in percents which we will take for early unstake
    uint public penalty;

    // Rate of USDC/BRBC depending on a period of a stake (peroid => rate)
    mapping(uint => uint) public rate;

    // Role of the manager
    bytes32 public constant MANAGER = keccak256("MANAGER");

    /// @dev This modifier prevents using manager functions
    modifier OnlyManager {
        require(
            hasRole(MANAGER, msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    /// @dev OnlyManager function that sets time, during which user can start staking his LP
    /// @param _startTime the start time of the staking, greater then now
    /// @param _endTime the end time of the staking, greater then _startTime
    function setTime(uint _startTime, uint _endTime) external OnlyManager {
        require(
            _startTime >= block.timestamp && _endTime >= _startTime,
            "Incorrect time"
        );
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @dev OnlyManager function that sets Cross Chain address, where USDC goes
    /// @param _crossChain address of new deployed cross chain pool
    function setCrossChainAddress(address _crossChain) external OnlyManager {
        require(
            crossChain != _crossChain,
            "Address already set"
        );
        crossChain = _crossChain;
    }

    /// @dev OnlyManager function that sets penalty address, where BRBC goes
    /// @param _penaltyAddress address of new BRBC reciver
    function setPenaltyAddress(address _penaltyAddress) external OnlyManager {
        require(
            penaltyReciver != _penaltyAddress,
            "Address already set"
        );
        penaltyReciver = _penaltyAddress;
    }

    /// @dev OnlyManager function, sets maximum USDC amount which one address can hold
    /// @param _maxUSDCAmount the maximum USDC amount, must be greater then minUSDCAmount
    function setMaxUSDCAmount(uint _maxUSDCAmount) external OnlyManager {
        require(
            _maxUSDCAmount > minUSDCAmount,
            "Max USDC amount must be greater than min USDC amount"
        );
        maxUSDCAmount = _maxUSDCAmount;
    }

    /// @dev OnlyManager function, sets penalty that will be taken for early unstake
    /// @param _penalty amount in percent, sets from 1% to 50% of users stake
    function setPenalty(uint _penalty) external OnlyManager {
        require(
            _penalty >= 1 && _penalty <= 50,
            "Incorrect penalty"
        );
        penalty = _penalty;
    }

    /// @dev OnlyManager function, sets rates for different periods, buisness logic suppose rate1Month to be the greatest
    /// @param _rate1Month the rate for one month, represented in uint / 100
    /// @param _rate3Month the rate for three month, to recieve multiplayer equals 1 you should input 100
    /// @param _rate6Month the rate for six month, buisness logic suppose rate6Month to be the lowest
    function setRates(uint _rate1Month, uint _rate3Month, uint _rate6Month) external OnlyManager {
        rate[30 seconds] = _rate1Month;
        rate[90 seconds] = _rate3Month;
        rate[180 seconds] = _rate6Month;
    }

    /// @dev OnlyManager function, sets minimum USDC amount which one address can stake
    /// @param _minUSDCAmount the minimum USDC amount, must be lower then maxUSDCAmount
    function setMinUSDCAmount(uint _minUSDCAmount) external OnlyManager {
        require(
            _minUSDCAmount < maxUSDCAmount,
            "Min USDC amount must be lower than max USDC amount"
        );
        minUSDCAmount = _minUSDCAmount;
    }

    /// @dev OnlyManager function, sets maximum USDC pool size amount
    /// @param _maxPoolUSDC the maximum USDC amount
    function setMaxPoolUSDC(uint _maxPoolUSDC) external OnlyManager {
        maxPoolUSDC = _maxPoolUSDC;
    }

    /// @dev OnlyManager function, sets maximum BRBC pool size amount
    /// @param _maxPoolBRBC the maximum BRBC amount
    function setMaxPoolBRBC(uint _maxPoolBRBC) external OnlyManager {
        maxPoolBRBC = _maxPoolBRBC;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}