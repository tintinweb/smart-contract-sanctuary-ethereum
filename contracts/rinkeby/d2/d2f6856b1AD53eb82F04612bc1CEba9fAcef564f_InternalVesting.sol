// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title A Vesting contract
/// @notice You can use this contract for multiple roles as specified

contract InternalVesting is Ownable {
    /// @notice All available roles present in the contract
    /// @dev Declaring roles as mentioned an store it in the role variable
    enum allRoles {
        CompanyReserve,
        equityInvestors,
        team,
        exchangeListingsAndLiquidity,
        Ecosystem,
        stakingAndRewards,
        AIRAndBURN,
        partnershipsAndAdvisors
    }
    allRoles private role;

    /// @dev Stores, Each role to the Total tokens available for the Role
    /// @dev takes Role id as input (For Ex, totalTokensForRole[0] returns token available for role 0)
    /// @dev this totalTokensForRole gets assigned in "allocateTokensForRoles" function and updated in "addBeneficiary" function
    mapping(uint256 => uint256) public totalTokensForRole;

    /// @dev To store the data and returns, how many participants are present in a particular role
    /// @dev This gets updated in "addBeneficiary" func.
    mapping(uint256 => uint256) private totalBeneficiariesInRole;

   

    /// @dev Amount a  beneficiary can withdraw at the current time
    mapping(bytes32 => uint256) private tokenWithdrawable;

    /// @dev address of the ERC20 token
    IERC20 public token;

    /// @dev Defining the structure of a beneficiary
    struct Beneficiary {
        address beneficiary;
        allRoles role;
        uint256 amount;
        uint256 tokenReceivedTillNow;
        uint256 vestingStartTime;
        uint256 cliff;
        uint256 duration;
        uint256 interval;
        bool isRevokable;
        bool isRevoked;
    }

    /// @dev Map the ID with the Beneficiary .Stores all the Beneficiaries
    /// @dev ID = Keccak256 hash of the beneficiary address and roleId
    mapping(bytes32 => Beneficiary) public beneficiaries;

    /// @dev All TGE percentages for Each role
    /// @dev For Ex, TGE 0% for 0th role,TGE 5% for 1st role etc.
    uint256[8] private TGEPercentages = [0, 5, 0, 25, 0, 14, 50, 0];

    /// @param _token ERC20 token address.
    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice Assigns tokens amount for every roles
    /// @notice calculates the token left for ICO
    /// @dev Cannot execute this function, if the token balance of this contract is 0
    /// @dev only owner can execute this function
    function allocateTokensForRoles() external onlyOwner {
        /// @dev Token balance of this contract
        // uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 TotalTokenSupply = 1000000000000000000000;

        require(
            IERC20(token).balanceOf(address(this)) > 0,
            "No tokens allocated to the contract"
        );

        /// @dev Assign all the tokens to each role with specified percentage
        totalTokensForRole[uint256(allRoles.CompanyReserve)] =
            (TotalTokenSupply * 15) /
            100;
        totalTokensForRole[uint256(allRoles.equityInvestors)] =
            (TotalTokenSupply * 3) /
            100;
        totalTokensForRole[uint256(allRoles.team)] =
            (TotalTokenSupply * 10) /
            100;
        totalTokensForRole[uint256(allRoles.exchangeListingsAndLiquidity)] =
            (TotalTokenSupply * 25) /
            100;
        totalTokensForRole[uint256(allRoles.Ecosystem)] =
            (TotalTokenSupply * 10) /
            100;
        totalTokensForRole[uint256(allRoles.stakingAndRewards)] =
            (TotalTokenSupply * 15) /
            100;
        totalTokensForRole[uint256(allRoles.AIRAndBURN)] =
            (TotalTokenSupply * 2) /
            100;
        totalTokensForRole[uint256(allRoles.partnershipsAndAdvisors)] =
            (TotalTokenSupply * 10) /
            100;

    }

    /// @notice This function helps to add beneficiary
    /// @dev only owner can call this function
    /// @param _Beneficiary The address of the beneficiary
    /// @param _role Role of the beneficiary
    /// @param _amount Token amount for Vesting
    /// @param _cliff Cliff time period for this beneficiary
    /// @param _duration duration for this beneficiary
    /// @param _interval interval for this beneficiary
    /// @param _isRevokable Is the beneficiary's vesting revokable (if yes, pass true,else pass false)
    function addBeneficiary(
        address _Beneficiary,
        allRoles _role,
        uint256 _amount,
        uint256 _cliff,
        uint256 _duration,
        uint256 _interval,
        bool _isRevokable
    ) external onlyOwner {
        require(_Beneficiary != owner(), "Owner cannot be a beneficiary");
        require(
            _Beneficiary != address(0),
            "Cannot add a Beneficiary of 0 address"
        );
        require(_amount != 0, "amount should be greater than 0");

        /// @dev Generate the unique id
        bytes32 id = keccak256(abi.encodePacked(_Beneficiary, _role));

        /// @dev Check beneficiary already exists or not
        require(
            validateBeneficiary(id),
            "Beneficiary already exist in the role"
        );

        ///@dev If token is available for this role
        require(
            totalTokensForRole[uint256(_role)] >= _amount,
            "Not enough Tokens for this role"
        );

        /// @dev Update the total tokens for this role
        totalTokensForRole[uint256(_role)] -= _amount;

        /// @dev Get the TGE amount
        uint256 tgeAmount = (_amount * TGEPercentages[uint256(_role)]) / 100;

        /// @dev build the beneficiary structure
        Beneficiary memory beneficiary = Beneficiary(
            _Beneficiary,
            _role,
            _amount - tgeAmount, // subtract the TGE amount , and save the rest amount for vesting
            0, // Token Received till Now
            block.timestamp, // vesting start time
            _cliff,
            _duration,
            _interval,
            _isRevokable,
            false // Marking Revoked as false initially
        );

        /// @dev update the count of beneficiary in this role
        totalBeneficiariesInRole[uint256(_role)] += 1;

        /// @dev add the beneficiary to the collection
        beneficiaries[id] = beneficiary;

        /// @dev Save the TGE amount to beneficiary withadrawable

        tokenWithdrawable[id] = tgeAmount;

        emit AddedBeneficiary(_Beneficiary, _role, id);
    }

    function validateBeneficiary(bytes32 _id)
        internal
        view
        returns (bool exists)
    {
        return beneficiaries[_id].beneficiary == address(0);
    }

    /// @notice This function helps to revoke a beneficiary
    /// @dev Only Admin can call this function
    /// @param _beneficiary Address of the beneficiary
    /// @param _role Role of the beneficiary
    function revokeBeneficiary(address _beneficiary, allRoles _role)
        external
        onlyOwner
    {
        /// @dev Generate the Hash Id
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        /// @dev check beneficiary should exist in the collection
        require(
            !validateBeneficiary(id),
            "Beneficiary is not exist in the role"
        );

        /// @dev Get the beneficiary
        Beneficiary storage beneficiary = beneficiaries[id];
        require(beneficiary.isRevokable, "beneficiary is not revokable");

        /// @dev Revoke beneficiary . update the isRevoked to true.
        beneficiary.isRevoked = true;
    }

    /// @notice Admin or a beneficiary can call this func to withdraw tokens
    /// @dev Admin should release Tokens for the beneficiary ,after that a beneficiary will get his tokens
    /// @param  _beneficiary Address of the beneficiary
    /// @param _role Role of the _beneficiary
    /// @param _withdrawAmount Amount A beneficiary wants to withdraw
    function withdraw(
        address _beneficiary,
        allRoles _role,
        uint256 _withdrawAmount
    ) external {
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        /// @dev check beneficiary should  exists
        require(
            !validateBeneficiary(id),
            "Beneficiary is not exist in the role"
        );

        require(
            msg.sender == owner() ||
                keccak256(abi.encodePacked(msg.sender, _role)) == id,
            "Admin or beneficiary required"
        );

        require(_withdrawAmount > 0, "Withdrawable should be greater than 0");

        ///@dev withDraw amount should not greater than total releasable
        require(
            tokenWithdrawable[id] >= _withdrawAmount,
            "Token released amount is less"
        );

        /// @dev update the total withdrawable tokens
        tokenWithdrawable[id] -= _withdrawAmount;

        /// @dev Transfer the tokens
        IERC20(token).transfer(_beneficiary, _withdrawAmount);

        emit TokenWithdraw(
            _beneficiary,
            _withdrawAmount,
            tokenWithdrawable[id]
        );
    }

    /// @notice This function release the vested tokens for a beneficiary , stores it in "tokenWithdrawable" so that beneficiary can withdraw tokens.
    /// @dev Admin can call this function
    /// @param _beneficiary Address of the _beneficiary
    /// @param _role Role of the _beneficiary
    function release(address _beneficiary, allRoles _role) external onlyOwner {
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        /// @dev  beneficiary should  exists
        require(
            !validateBeneficiary(id),
            "Beneficiary is not exist in the role"
        );

        Beneficiary storage beneficiary = beneficiaries[id];
        require(!beneficiary.isRevoked, "beneficiary is revoked");

        /// @dev all vested tokens for this _beneficiary Till Now
        uint256 totalVestedTokens = vestedTokenForRole(id);

        /// @dev Subtract the totalVestedTokens from tokenReceivedTillNow ,we will get amount that is going to release Now
        uint256 releaseTokens = totalVestedTokens -
            beneficiary.tokenReceivedTillNow;

        require(
            releaseTokens > 0,
            "No Tokens released yet,try after some time"
        );
        /// @dev update the amount of user Received till now
        beneficiary.tokenReceivedTillNow += releaseTokens;

        /// @dev Update the tokenWithdrawable for this _beneficiary
        tokenWithdrawable[id] += releaseTokens;

        emit TokenReleased(_beneficiary, releaseTokens, tokenWithdrawable[id]);
    }

    /// @dev Calculates the Token amount vested till Now for a specific _beneficiary
    /// @dev this is Internal function
    /// @param _id Id of the _beneficiary ,
    function vestedTokenForRole(bytes32 _id)
        internal
        view
        returns (uint256 TokenVested)
    {
        Beneficiary memory beneficiary = beneficiaries[_id];
        /// @dev Amount vested for this _beneficiary
        uint256 totalTokenAmount = beneficiary.amount;

        /// @dev cliff time of the _beneficiary
        /// @dev Adding the start time of the vesting with the cliff time
        uint256 cliff = beneficiary.cliff + beneficiary.vestingStartTime;

        ///@dev duration of the vesting for this _beneficiary
        uint256 duration = beneficiary.duration;

        /// @dev If cliff time is not finished
        if (block.timestamp < cliff) {
            return 0;
            /// @dev if duration is over
        } else if (block.timestamp >= beneficiary.vestingStartTime + duration) {
            return totalTokenAmount;
        } else {
            ///@dev round of How many Interval passed
            uint256 vestedInterval = (block.timestamp - cliff) /
                beneficiary.interval;
            /// @dev calculate the vested time
            
            uint256 vestedTime = vestedInterval * beneficiary.interval;
            ///@dev return the vested token amount
            return
                (totalTokenAmount * vestedTime) /
                (duration - beneficiary.cliff);
        }
    }

    /// @dev get Releasable Token amount
    function getReleasableAmount(address _beneficiary, allRoles _role)
        external
        view
        returns (uint256)
    {
        ///@dev get the ID
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        Beneficiary memory beneficiary = beneficiaries[id];
        uint256 totalVestedTokens = vestedTokenForRole(id);

        uint256 releaseTokens = totalVestedTokens -
            beneficiary.tokenReceivedTillNow;

        return releaseTokens;
    }

    /// @dev return the token amount user can withdraw
    function getTokenWithdrawable(address _beneficiary, allRoles _role)
        external
        view
        returns (uint256)
    {
        //get the ID
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        return tokenWithdrawable[id];
    }

    /// @dev Get next vesting schedule
    function getNextVestingSchedule(address _beneficiary, allRoles _role)
        external
        view
        returns (uint256)
    {
        //get the ID
        bytes32 id = keccak256(abi.encodePacked(_beneficiary, _role));

        /// @dev check beneficiary should  exists
        require(
            !validateBeneficiary(id),
            "Beneficiary is not exist in the role"
        );

        ///@dev get the beneficiary
        Beneficiary memory beneficiary = beneficiaries[id];

        uint256 totalIntervalPresent = (beneficiary.duration -
            beneficiary.cliff) / beneficiary.interval;

        uint256 cliff = beneficiary.cliff + beneficiary.vestingStartTime;

        ///@dev If cliff time is not finished
        if (block.timestamp <= cliff) {
            return cliff + beneficiary.interval;
        }
        /// @dev if duration of vesting is over
        else if (
            block.timestamp >=
            beneficiary.vestingStartTime + beneficiary.duration
        ) {
            return 0;
        }
        /// @dev if beneficiary crossed all the intervals but duration is not completed
        else if (
            totalIntervalPresent ==
            (block.timestamp - cliff) / beneficiary.interval
        ) {
            return beneficiary.vestingStartTime + beneficiary.duration;
        }
        ///@dev if beneficiary not crossed duration and not all interval is completed
        else {
            /// @dev Calculate the Interval passed till Now
            uint256 vestedInterval = (block.timestamp - cliff) /
                beneficiary.interval;

            //start = 50
            //dur = 400
            //inter = 200
            //cliff = 100 + 50 =150
            // cuur = 200
            // 50 / 200 = 0.25 ->0
            //vested interval = 0
            //vesting time = (0 +1) * 200 = 200

            ///  @dev Time for next Interval
            uint256 vestedTime = (vestedInterval + 1) * beneficiary.interval;
            /// @dev return the timeStamp
            return cliff + vestedTime;
        }
    }

    ///@dev get the Id of a _beneficiary
    function getId(address _beneficiary, allRoles _role)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_beneficiary, _role));
    }

    /* All Events */
    event startedVesting(uint256 cliff, uint256 duration);
    event AddedBeneficiary(address Beneficiary, allRoles role, bytes32 id);
    event TokenReleased(
        address Beneficiary,
        uint256 tokenReleased,
        uint256 totalTokenWithdrawable
    );
    event TokenWithdraw(
        address Beneficiary,
        uint256 withdrawAmount,
        uint256 totalTokenWithdrawable
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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