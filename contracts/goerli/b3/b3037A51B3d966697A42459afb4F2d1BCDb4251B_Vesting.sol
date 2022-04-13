// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //@notice to set TEG for advisors and partners and mentors TEG
    uint256 public advisorsTGE;
    uint256 public partnersTGE;
    uint256 public mentorsTGE;

    //@notice variables to keep count of total tokens in the contract
    uint256 public totalTokenInContract;
    uint256 public totalWithdrawableAmount;

    //@notice tokens that can be withdrawn any time
    uint256 public advisersTGEPool;
    uint256 public partnersTGEPool;
    uint256 public mentorsTGEPool;

    // @notice tracking beneficiary count
    uint256 public advisersBeneficiariesCount = 0;
    uint256 public partnersBeneficiariesCount = 0;
    uint256 public mentorsBeneficiariesCount = 0;

    //@notice tokens that can be vested .
    uint256 public vestingPoolForAdvisors;
    uint256 public vestingPoolForPartners;
    uint256 public vestingPoolForMentors;

    //@notice total Token each division has for vesting
    uint256 public vestingSchedulesTotalAmountforAdvisors;
    uint256 public vestingSchedulesTotalAmountforPartners;
    uint256 public vestingSchedulesTotalAmountforMentors;

    //tracking TGE pool
    uint256 public advisersTGEBank;
    uint256 public partnersTGEBank;
    uint256 public mentorsTGEBank;

    /*
    @notice create vesting schedule for benificireis
    @param beneficiary of tokens after they are released
    @param cliff period in seconds
    @param start time of the vesting period
    @param duration for the vesting period in seconds
    @param  slicePeriodSeconds for the duration of slicePeriodSeconds in vesting Schedule
    @param revocable for weather or not the vesting is revokable
    @param amountTotal for total amount of the tokens that can be released  at the end of the vesting
    @param released for amount of token released
    @param tgeAmount for tge after vesting schedule created
    @param revoked for weather or not vesting schedule has been revoked

    */

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        bool revoked;
    }

    //@notice to check holders vesting count
    mapping(address => uint256) private holdersVestingCount;

    //@notice vesting Schedueles for different roles
    mapping(bytes32 => VestingSchedule) private vestingScheduleForAdvisors;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForPartners;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForMentors;

    //@notice keeping track of benificiries in different role
    mapping(address => bool) private advisorsBenificiaries;
    mapping(address => bool) private partnersBeneficiaries;
    mapping(address => bool) private mentorsBeneficiaries;

    //@notice vesting schedule ID to track vesting
    bytes32[] private vestingScheduleIds;

    //@notice all the roles
    enum Roles {
        Advisors,
        Partners,
        Mentors
    }

    //@param for storing the token address for ERC20 token
    IERC20 private token;

    /*
    @notice  Events for relased , revoke and createScheudle functions
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created;

    */

    event Released(
        bytes32 vestingScheduleId,
        Roles role,
        address beneficiary,
        uint256 amount
    );

    event Revoked(bytes32 vestingScheduleId, Roles role);
    event Schedule(
        Roles role,
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        bool revocable,
        uint256 amount
    );

    /*
    @dev revert if no vesting schedule matches the past identifier
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created;
    */
    modifier onlyIfVestingScheduleExists(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisors) {
            require(
                vestingScheduleForAdvisors[vestingScheduleId].initialized ==
                    true
            );
        } else if (role == Roles.Partners) {
            require(
                vestingScheduleForPartners[vestingScheduleId].initialized ==
                    true
            );
        } else if (role == Roles.Mentors) {
            require(
                vestingScheduleForMentors[vestingScheduleId].initialized == true
            );
        }
        _;
    }

    /*
    @dev revert if vesting schedule does not exists or  has been revoked
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created
     */
    modifier onlyIfVestingScheduleNotRevoked(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisors) {
            require(
                vestingScheduleForAdvisors[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForAdvisors[vestingScheduleId].revoked == false
            );
        } else if (role == Roles.Partners) {
            require(
                vestingScheduleForPartners[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForPartners[vestingScheduleId].revoked == false
            );
        } else if (role == Roles.Mentors) {
            require(
                vestingScheduleForMentors[vestingScheduleId].initialized == true
            );
            require(
                vestingScheduleForMentors[vestingScheduleId].revoked == false
            );
        }
        _;
    }

    //@param _token address of the ERC20 token contract
    constructor(address _token) {
        require(_token != address(0x0));
        token = IERC20(_token);
    }

    // @notice function to return current Time
    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function updateTotalSupply() internal onlyOwner {
        totalTokenInContract = token.balanceOf(address(this));
    }

    function updateTotalWithdrawableAmount() internal onlyOwner {
        uint256 reservedAmount = vestingSchedulesTotalAmountforAdvisors +
            vestingSchedulesTotalAmountforPartners +
            vestingSchedulesTotalAmountforMentors;
        totalWithdrawableAmount =
            token.balanceOf(address(this)) -
            reservedAmount;
    }

    /*
   @notice update the benificiary count
   @param _address that is address of the benificiary
   @param role  the role of the benificiaries
   */
    function addBenificiary(address _address, Roles role) internal onlyOwner {
        if (role == Roles.Advisors) {
            advisersBeneficiariesCount++;
            advisorsBenificiaries[_address] = true;
        } else if (role == Roles.Partners) {
            partnersBeneficiariesCount++;
            partnersBeneficiaries[_address] = true;
        } else if (role == Roles.Mentors) {
            mentorsBeneficiariesCount++;
            mentorsBeneficiaries[_address] = true;
        }
    }

    /*
    @notice to check the conditions while creating vesting schedule
    @dev timeInterval is used to divide the given time into equla distibution during vesting schedule
    @param vestingScheduleId for creating the perticular vesting Schedule
    @param _revocable to decide the if the benificiary vesting schedule can be revoked

    */
    function conditionForCreatingVestingSchedule(
        Roles role,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _intervalPeriod,
        bool _revocable,
        uint256 _amount,
        bytes32 vestingScheduleId
    ) internal {
        if (role == Roles.Advisors) {
            vestingScheduleForAdvisors[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                false
            );
            vestingSchedulesTotalAmountforAdvisors = vestingSchedulesTotalAmountforAdvisors;
        } else if (role == Roles.Partners) {
            uint256 tgeAmount = 0;
            _amount = _amount - (tgeAmount);
            uint256 extraTime = _intervalPeriod / 2;
            uint256 timeInterval = extraTime + _intervalPeriod;
            _duration = timeInterval;
            vestingScheduleForPartners[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                false
            );
            vestingSchedulesTotalAmountforPartners = vestingSchedulesTotalAmountforPartners;
        } else {
            vestingScheduleForMentors[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                false
            );
            vestingSchedulesTotalAmountforMentors = vestingSchedulesTotalAmountforMentors;
        }
    }

    /*
    @notice calculating the total release amount
     @param vestingSchedule is to send in the details of the vesting schedule created
     @return the calculated releaseable amount depending on the role
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if (
            currentTime < vestingSchedule.cliff ||
            vestingSchedule.revoked == true
        ) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.start + (vestingSchedule.duration)
        ) {
            return vestingSchedule.amountTotal - (vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime - (vestingSchedule.start);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / (secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods * (secondsPerSlice);
            uint256 vestedAmount = (vestingSchedule.amountTotal *
                (vestedSeconds)) / (vestingSchedule.duration);
            vestedAmount = vestedAmount - (vestingSchedule.released);
            return vestedAmount;
        }
    }

    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingCount[_beneficiary];
    }

    function getVestingIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(
            index < getVestingSchedulesCount(),
            "TokenVesting: index out of bounds"
        );
        return vestingScheduleIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index,
        Roles role
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(holder, index),
                role
            );
    }

    function getVestingSchedule(bytes32 vestingScheduleId, Roles role)
        public
        view
        returns (VestingSchedule memory)
    {
        if (role == Roles.Advisors) {
            return vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            return vestingScheduleForPartners[vestingScheduleId];
        } else {
            return vestingScheduleForMentors[vestingScheduleId];
        }
    }

    function getVestingSchedulesTotalAmount(Roles role)
        public
        view
        returns (uint256)
    {
        if (role == Roles.Advisors) {
            return vestingSchedulesTotalAmountforAdvisors;
        } else if (role == Roles.Partners) {
            return vestingSchedulesTotalAmountforPartners;
        } else {
            return vestingSchedulesTotalAmountforMentors;
        }
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    /*
    @notice  this function is used to create vesting Schedule
    @param role  to decide role of benificiary
    @param _beneficiary of tokens after they are released
    @param _cliff period in seconds
    @param _start time of the vesting period
    @param _duration for the vesting period in seconds
    @param  _slicePeriodSeconds for the duration of slicePeriodSeconds in vesting Schedule
    @param _revocable for weather or not the vesting is revokable
    @param _amount for total amount of the tokens given to the vesting schedule
    */
    function createVestingSchedule(
        Roles role,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= 0,
            "Token Vesting : cannot cretae vesting schedule because  not sufficent tokens "
        );
        require(
            _duration > 0,
            "Token Vesting: duration must be greater than 0"
        );
        require(
            _slicePeriodSeconds >= 1,
            "Token Vesting: slice PeriodsSeconds must be >=1 "
        );
        require(
            role == Roles.Advisors ||
                role == Roles.Partners ||
                role == Roles.Mentors,
            "Token vesting : roles must be 0 ,1 or 2"
        );
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        conditionForCreatingVestingSchedule(
            role,
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            vestingScheduleId
        );
        addBenificiary(_beneficiary, role);
        vestingScheduleIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount + 1;
        emit Schedule(
            role,
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount
        );
    }

    /*
    @param holder is the address of the holder of the account
     @param index is the index of the different vesting schdules held by the address
    @return vesting schedule ID for a particular index of an address
    */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /*
    @notice revoke the vesting schedule  of perticular holder
    @param vestingScheduleId the vesting schedular identifier
    @role  to find the role of holder
    */

    function revoke(bytes32 vestingScheduleId, Roles role)
        public
        onlyOwner
        onlyIfVestingScheduleNotRevoked(vestingScheduleId, role)
    {
        if (role == Roles.Advisors) {
            VestingSchedule
                storage vestingSchedule = vestingScheduleForAdvisors[
                    vestingScheduleId
                ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );

            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);

            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforAdvisors =
                vestingSchedulesTotalAmountforAdvisors -
                unreleased;
            vestingSchedule.revoked = true;
        } else if (role == Roles.Partners) {
            VestingSchedule
                storage vestingSchedule = vestingScheduleForPartners[
                    vestingScheduleId
                ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforPartners =
                vestingSchedulesTotalAmountforAdvisors -
                unreleased;
            vestingSchedule.revoked = true;
        }
        if (role == Roles.Mentors) {
            VestingSchedule storage vestingSchedule = vestingScheduleForMentors[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforAdvisors =
                vestingSchedulesTotalAmountforAdvisors -
                unreleased;
            vestingSchedule.revoked = true;
        }

        emit Revoked(vestingScheduleId, role);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= amount,
            "TokenVesting: not enough withdrawable funds"
        );
        totalWithdrawableAmount = totalWithdrawableAmount - (amount);
        token.safeTransfer(owner(), amount);
    }

    /*
     @param vestingScheduleId is used to get the details of the created vesting scheduel
     @param amount is used to get the total amount to be released
     @param role is used to know the role
    */
    function release(
        bytes32 vestingScheduleId,
        uint256 amount,
        Roles role
    ) public onlyIfVestingScheduleNotRevoked(vestingScheduleId, role) {
        VestingSchedule memory vestingSchedule;
        if (role == Roles.Advisors) {
            vestingSchedule = vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            vestingSchedule = vestingScheduleForPartners[vestingScheduleId];
        } else if (role == Roles.Mentors) {
            vestingSchedule = vestingScheduleForMentors[vestingScheduleId];
        }

        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;

        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "Token Vesting: only beneficiary and owner can release vested tokens"
        );

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(
            vestedAmount >= amount,
            "Token Vesting: cannot release tokens, not enough vested tokens"
        );
        vestingSchedule.released = vestingSchedule.released + (amount);
        address payable beneficiary = payable(vestingSchedule.beneficiary);
        if (role == Roles.Advisors) {
            vestingSchedulesTotalAmountforAdvisors =
                vestingSchedulesTotalAmountforAdvisors -
                amount;
        } else if (role == Roles.Partners) {
            vestingSchedulesTotalAmountforPartners =
                vestingSchedulesTotalAmountforPartners -
                amount;
        }
        if (role == Roles.Mentors) {
            vestingSchedulesTotalAmountforMentors =
                vestingSchedulesTotalAmountforMentors -
                amount;
        }

        token.safeTransfer(beneficiary, amount);
        emit Released(vestingScheduleId, role, beneficiary, amount);
    }

    //@return vesting ScheduleCount
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingScheduleIds.length;
    }

    function computeReleasableAmount(bytes32 vestingScheduleId, Roles role)
        public
        view
        onlyIfVestingScheduleNotRevoked(vestingScheduleId, role)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule;
        if (role == Roles.Advisors) {
            vestingSchedule = vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            vestingSchedule = vestingScheduleForPartners[vestingScheduleId];
        } else {
            vestingSchedule = vestingScheduleForMentors[vestingScheduleId];
        }
        return _computeReleasableAmount(vestingSchedule);
    }

    //@return to get the total withdrawable amount
    function getWithdrawableAmount() public view returns (uint256) {
        return totalWithdrawableAmount;
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(address holder, Roles role)
        public
        view
        returns (VestingSchedule memory)
    {
        if (role == Roles.Advisors) {
            return
                vestingScheduleForAdvisors[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        } else if (role == Roles.Partners) {
            return
                vestingScheduleForPartners[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        } else {
            return
                vestingScheduleForMentors[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        }
    }

    /*
    @devComputes the next vesting schedule identifier for a given holder address.
    @param holder is input address
    @return the next vesting schedule ID for  holder
    */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder]
            );
    }

    function withdrawFromTGEBank(Roles role, uint256 _amount) public {
        bool isOwner = msg.sender == owner();
        if (role == Roles.Advisors) {
            require(
                advisorsBenificiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= advisersTGEBank / (advisersBeneficiariesCount),
                "you can not withdraw"
            );
            advisersTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        } else if (role == Roles.Partners) {
            require(
                partnersBeneficiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= partnersTGEBank / (partnersBeneficiariesCount),
                "you can not withdraw"
            );
            partnersTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        } else if (role == Roles.Mentors) {
            require(
                mentorsBeneficiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= mentorsTGEBank / (mentorsBeneficiariesCount),
                "you can not withdraw"
            );
            mentorsTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        }
    }

    function setTGE(
        uint256 _TGEForAdvisors,
        uint256 _TGEForPartners,
        uint256 _TGEForMentors
    ) public onlyOwner {
        advisorsTGE = _TGEForAdvisors;
        partnersTGE = _TGEForPartners;
        mentorsTGE = _TGEForMentors;
    }

    // @notice updates the pool and total amount for each role
    /// @dev this function is to be called once the TGE is set and the contract is deployed
    function calculatePools() public onlyOwner {
        updateTotalSupply();
        vestingSchedulesTotalAmountforAdvisors =
            (totalTokenInContract * (20)) /
            (100);
        vestingSchedulesTotalAmountforPartners =
            (totalTokenInContract * (20)) /
            (10) /
            (100);
        vestingSchedulesTotalAmountforMentors =
            (totalTokenInContract * (30)) /
            (100);

        vestingPoolForAdvisors =
            (vestingSchedulesTotalAmountforAdvisors * (advisorsTGE)) /
            (100);
        vestingPoolForPartners =
            (vestingSchedulesTotalAmountforPartners * (partnersTGE)) /
            (100);
        vestingPoolForMentors =
            (vestingSchedulesTotalAmountforMentors * (mentorsTGE)) /
            (100);

        advisersTGEBank = vestingPoolForAdvisors;
        partnersTGEBank = vestingPoolForPartners;
        mentorsTGEBank = vestingPoolForMentors;

        vestingPoolForAdvisors =
            vestingSchedulesTotalAmountforAdvisors -
            advisersTGEPool;
        vestingPoolForPartners =
            vestingSchedulesTotalAmountforPartners -
            partnersTGEPool;
        vestingPoolForMentors =
            vestingSchedulesTotalAmountforMentors -
            mentorsTGEPool;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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