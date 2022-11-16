/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract VestingNoFly is Context, ReentrancyGuard {
    IERC20 public immutable tokenAddress;
    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        uint256 amountTotal;
        uint256 released;
    }

    bytes32[] private _vestingSchedulesIds;
    uint256 private _vestingSchedulesTotalAmount;
    mapping(address => uint256) private _holdersVestingCount;
    mapping(bytes32 => VestingSchedule) private _vestingSchedules;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event TokensReleased(address beneficiary, uint256 amount);
    event VestingScheduleCreated(
        address beneficiary,
        uint256 cliff,
        uint256 start,
        uint256 duration,
        uint256 slicePeriodSeconds,
        uint256 amount
    );

    modifier onlyIfBeneficiaryExists(address beneficiary) {
        require(
            _holdersVestingCount[beneficiary] > 0,
            "TokenVestingFLYY: INVALID beneficiary Address! no vesting schedule exists for that beneficiary"
        );
        _;
    }

    constructor() {
        tokenAddress = IERC20(0x89b7D46C7C9a0D3bE2e1421700e10b496DD5c12f);
    }

    function name() external pure returns (string memory) {
        return "Vested FLYY";
    }

    function symbol() external pure returns (string memory) {
        return "VFLYY";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _vestingSchedulesTotalAmount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getVestingIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(
            index < getVestingSchedulesCount(),
            "TokenVestingFLYY: index out of bounds"
        );

        return _vestingSchedulesIds[index];
    }

    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return _holdersVestingCount[_beneficiary];
    }

    function getVestingScheduleByBeneficiaryAndIndex(
        address beneficiary,
        uint256 index
    )
        external
        view
        onlyIfBeneficiaryExists(beneficiary)
        returns (VestingSchedule memory)
    {
        require(
            index < _holdersVestingCount[beneficiary],
            "TokenVestingFLYY: INVALID Vesting Schedule Index! no vesting schedule exists at this index for that beneficiary"
        );

        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(beneficiary, index)
            );
    }

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    function getVestingSchedule(bytes32 vestingScheduleId)
        public
        view
        returns (VestingSchedule memory)
    {
        VestingSchedule storage vestingSchedule = _vestingSchedules[
            vestingScheduleId
        ];
        require(
            vestingSchedule.initialized == true,
            "TokenVestingFLYY: INVALID Vesting Schedule ID! no vesting schedule exists for that id"
        );

        return vestingSchedule;
    }

    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external returns (bool) {
        require(
            tokenAddress.transferFrom(_msgSender(), address(this), _amount),
            "TokenVestingFLYY: token FLYY transferFrom not succeeded"
        );
        _createVestingSchedule(
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _amount
        );

        return true;
    }

    function _createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) private {
        require(_duration > 0, "TokenVestingFLYY: duration must be > 0");
        require(_amount > 0, "TokenVestingFLYY: amount must be > 0");
        require(
            _slicePeriodSeconds >= 1,
            "TokenVestingFLYY: slicePeriodSeconds must be >= 1"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        uint256 cliff = _start + _cliff;
        _vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _amount,
            0
        );
        _balances[_beneficiary] += _amount;
        _vestingSchedulesTotalAmount += _amount;
        _vestingSchedulesIds.push(vestingScheduleId);
        _holdersVestingCount[_beneficiary]++;
    }

    function computeNextVestingScheduleIdForHolder(address holder)
        private
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                _holdersVestingCount[holder]
            );
    }

    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        private
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (currentTime < vestingSchedule.cliff) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.cliff + vestingSchedule.duration
        ) {
            return (vestingSchedule.amountTotal - vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.cliff;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 releaseableSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 releaseableSeconds = releaseableSlicePeriods *
                secondsPerSlice;
            uint256 releaseableAmount = (vestingSchedule.amountTotal *
                releaseableSeconds) / vestingSchedule.duration;
            releaseableAmount -= vestingSchedule.released;

            return releaseableAmount;
        }
    }

    function claimFromAllVestings()
        external
        nonReentrant
        onlyIfBeneficiaryExists(_msgSender())
        returns (bool)
    {
        address beneficiary = _msgSender();
        uint256 vestingSchedulesCountByBeneficiary = getVestingSchedulesCountByBeneficiary(
                beneficiary
            );

        VestingSchedule storage vestingSchedule;
        uint256 totalReleaseableAmount = 0;
        uint256 i = 0;
        do {
            vestingSchedule = _vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(beneficiary, i)
            ];
            uint256 releaseableAmount = _computeReleasableAmount(
                vestingSchedule
            );
            vestingSchedule.released += releaseableAmount;

            totalReleaseableAmount += releaseableAmount;
            i++;
        } while (i < vestingSchedulesCountByBeneficiary);

        _vestingSchedulesTotalAmount -= totalReleaseableAmount;
        _balances[beneficiary] -= totalReleaseableAmount;
        require(
            tokenAddress.transfer(beneficiary, totalReleaseableAmount),
            "TokenVestingFLYY: token FLYY rewards transfer to beneficiary not succeeded"
        );

        emit TokensReleased(beneficiary, totalReleaseableAmount);
        return true;
    }

    function getLastVestingScheduleForBeneficiary(address beneficiary)
        external
        view
        onlyIfBeneficiaryExists(beneficiary)
        returns (VestingSchedule memory)
    {
        return
            _vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(
                    beneficiary,
                    _holdersVestingCount[beneficiary] - 1
                )
            ];
    }

    function getVestingSchedulesCount() public view returns (uint256) {
        return _vestingSchedulesIds.length;
    }

    function computeAllReleasableAmountForBeneficiary(address beneficiary)
        external
        view
        onlyIfBeneficiaryExists(beneficiary)
        returns (uint256)
    {
        uint256 vestingSchedulesCountByBeneficiary = getVestingSchedulesCountByBeneficiary(
                beneficiary
            );

        VestingSchedule memory vestingSchedule;
        uint256 totalReleaseableAmount = 0;
        uint256 i = 0;
        do {
            vestingSchedule = _vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(beneficiary, i)
            ];
            uint256 releaseableAmount = _computeReleasableAmount(
                vestingSchedule
            );

            totalReleaseableAmount += releaseableAmount;
            i++;
        } while (i < vestingSchedulesCountByBeneficiary);

        return totalReleaseableAmount;
    }
}