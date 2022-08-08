// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ISBCToken.sol";

interface IPresaleContract {
    function startTime() external view returns (uint256);

    function PERIOD() external view returns (uint256);
}

contract Vesting {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    address private owner;
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds

    IPresaleContract public presaleContract; // Presale contract interface
    ISBCToken public SBCToken; //SBC token interface

    mapping(address => VestingSchedule) public recipients;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint256 constant TOTAL_SUPPLY = 1e27; //total supply 1,000,000,000
    uint256 public TGE_UNLOCK = 10; // 10% : released percent at TGE stage
    uint256 public UNLOCK_UNIT = 30000; // 30% of the total allocation will be unlocked
    uint256 public CLIFF_PERIOD = 3 hours; // cliff period
    uint256 public VESTING_PERIOD;
    uint256 public MEASURE;
    //uint256 unlockParts;

    uint256 public vestingAllocation; // Max amount which will be locked in vesting contract
    uint256 private totalAllocated; // The amount of allocated tokens

    event VestingScheduleRegistered(
        address registeredAddress,
        uint256 totalAmount
    );
    event VestingSchedulesRegistered(
        address[] registeredAddresses,
        uint256[] totalAmounts
    );

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(
            msg.sender == multiSigAdmin ||
            address(presaleContract) == msg.sender,
            "Should be multiSig contract"
        );
        _;
    }

    constructor(
        address _SBCToken,
        address _presaleContract,
        address payable _multiSigAdmin,
        uint256 TGE_UNLOCK_,
        uint256 CLIFF_PERIOD_,
        uint256 VESTING_PERIOD_,
        uint256 MEASURE_
    ) {
        owner = msg.sender;

        SBCToken = ISBCToken(_SBCToken);
        presaleContract = IPresaleContract(_presaleContract);
        multiSigAdmin = _multiSigAdmin;
        vestingAllocation = TOTAL_SUPPLY;
        //-------------------------------------------------
        TGE_UNLOCK = TGE_UNLOCK_;
        CLIFF_PERIOD = CLIFF_PERIOD_ * MEASURE_;
        UNLOCK_UNIT = (100 - TGE_UNLOCK_) * 1000 / VESTING_PERIOD_;
        //unlockParts = CLIFF_PERIOD_;
        VESTING_PERIOD = VESTING_PERIOD_;
        MEASURE = MEASURE_;
        //-------------------------------------------------

        /// Allow presale contract to withdraw unsold SBC tokens to multiSig admin
        SBCToken.approve(address(presaleContract), MAX_UINT256);
    }

    /**
     * @dev Get TGE time (TGE_Time = PresaleEnd_Time + 1 hours)
     */
    function getTGETime() public view returns (uint256) {
        return
        presaleContract.startTime().add(presaleContract.PERIOD()).add(
            MEASURE
        );
    }

    /**
     * @dev external function to set vesting allocation
     * @param _newAlloc the new allocation amount to be setted
     */
    function setVestingAllocation(uint256 _newAlloc) external onlyOwner {
        require(
            _newAlloc <= TOTAL_SUPPLY,
            "setVestingAllocation: Exceeds total supply"
        );
        vestingAllocation = _newAlloc;
    }

    /**
     * @dev Private function to add a recipient to vesting schedule
     * @param _recipient the address to be added
     * @param _totalAmount integer variable to indicate SBC amount of the recipient
     */
    function addRecipient(
        address _recipient,
        uint256 _totalAmount,
        bool isPresaleBuyer
    ) private {
        require(
            _recipient != address(0x00),
            "addRecipient: Invalid recipient address"
        );
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(
            isPresaleBuyer ||
            (!isPresaleBuyer && recipients[_recipient].totalAmount == 0),
            "addRecipient: Already allocated"
        );
        require(
            totalAllocated.sub(recipients[_recipient].totalAmount).add(
                _totalAmount
            ) <= vestingAllocation,
            "addRecipient: Total Allocation Overflow"
        );

        totalAllocated = totalAllocated
        .sub(recipients[_recipient].totalAmount)
        .add(_totalAmount);

        recipients[_recipient] = VestingSchedule({
        totalAmount : _totalAmount,
        amountWithdrawn : recipients[_recipient].amountWithdrawn
        });
    }

    /**
     * @dev Add new recipient to vesting schedule
     * @param _newRecipient the address to be added
     * @param _totalAmount integer variable to indicate SBC amount of the recipient
     */
    function addNewRecipient(
        address _newRecipient,
        uint256 _totalAmount,
        bool isPresaleBuyer
    ) external onlyMultiSigAdmin {
        require(
            block.timestamp < getTGETime().add(CLIFF_PERIOD),
            "addNewRecipient: Cannot update the receipient after started"
        );

        addRecipient(_newRecipient, _totalAmount, isPresaleBuyer);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    /**
     * @dev Add new recipients to vesting schedule
     * @param _newRecipients the addresses to be added
     * @param _totalAmounts integer array to indicate SBC amount of recipients
     */
    function addNewRecipients(
        address[] memory _newRecipients,
        uint256[] memory _totalAmounts,
        bool isPresaleBuyer
    ) external onlyMultiSigAdmin {
        require(
            block.timestamp < getTGETime().add(CLIFF_PERIOD),
            "addNewRecipients: Cannot update the receipient after started"
        );

        for (uint256 i = 0; i < _newRecipients.length; i++) {
            addRecipient(_newRecipients[i], _totalAmounts[i], isPresaleBuyer);
        }

        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts);
    }

    /**
     * @dev Gets the locked SBC amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getLocked(address beneficiary) external view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    /**
     * @dev Gets the claimable SBC amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getWithdrawable(address beneficiary)
    public
    view
    returns (uint256)
    {
        return
        getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    /**
     * @dev Claim unlocked SBC tokens of a recipient
     */
    function withdrawToken() external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = _vested.sub(
            recipients[msg.sender].amountWithdrawn
        );
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(SBCToken.transfer(msg.sender, _withdrawable));

        return _withdrawable;
    }

    function changePeriods(
        uint256 TGE_UNLOCK_,
        uint256 CLIFF_PERIOD_,
        uint256 VESTING_PERIOD_,
        uint256 MEASURE_
    ) external onlyOwner {
        TGE_UNLOCK = TGE_UNLOCK_;
        CLIFF_PERIOD = CLIFF_PERIOD_ * MEASURE_;
        UNLOCK_UNIT = (100 - TGE_UNLOCK_) * 1000 / VESTING_PERIOD_;
        //unlockParts = CLIFF_PERIOD_;
        VESTING_PERIOD = VESTING_PERIOD_;
        MEASURE = MEASURE_;
    }

    /**
     * @dev Get claimable SBC token amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getVested(address beneficiary)
    public
    view
    virtual
    returns (uint256 _amountVested)
    {
        require(beneficiary != address(0x00), "getVested: Invalid address");
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];

        if (
            _vestingSchedule.totalAmount == 0 || block.timestamp < getTGETime()
        ) {
            return 0;
        } else if (
            block.timestamp <= getTGETime().add(CLIFF_PERIOD).add(MEASURE)
        ) {
            return (_vestingSchedule.totalAmount).mul(TGE_UNLOCK).div(100);
        }

        uint256 vestedPercent;
        uint256 firstVestingPoint = getTGETime().add(CLIFF_PERIOD).add(MEASURE);

        vestedPercent = ((block.timestamp - firstVestingPoint) / MEASURE + 1).mul(UNLOCK_UNIT).add(TGE_UNLOCK*1000);

        if (
            block.timestamp > firstVestingPoint.add((VESTING_PERIOD) * MEASURE)
        ) {
            vestedPercent = 100000;
        }

        uint256 vestedAmount = _vestingSchedule
        .totalAmount
        .mul(vestedPercent)
        .div(100000);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }

        return vestedAmount;
    }
}